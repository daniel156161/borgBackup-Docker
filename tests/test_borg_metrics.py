"""Regression tests for Borg units and current-state dashboard panels."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXPORTER = ROOT / "prometheus-borg-exporter/borg_exporter.sh"
DASHBOARD = ROOT / "prometheus-borg-exporter/updated_borg_backup_status_dashboard.json"

class SizeConversionTests(unittest.TestCase):
  def convert(self, number, unit):
    return subprocess.run(
      ["bash", "-c", 'source "$1"; calc_bytes "$2" "$3"',
       "test", str(EXPORTER), str(number), unit],
      capture_output=True, text=True,
    )

  def test_decimal_and_binary_units(self):
    cases = [
      (123, "B", 123), (1.23, "kB", 1230),
      (1.23, "MB", 1230000), (1.23, "GB", 1230000000),
      (8.63, "TB", 8630000000000),
      (6.96, "TB", 6960000000000),
      (1.02, "TB", 1020000000000),
      (1, "PB", 10**15),
      (1, "KiB", 1024), (1, "MiB", 1024**2),
      (1, "GiB", 1024**3), (1, "TiB", 1024**4),
      (1, "PiB", 1024**5),
    ]
    for number, unit, expected in cases:
      with self.subTest(number=number, unit=unit):
        result = self.convert(number, unit)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(expected))

  def test_unknown_unit_fails(self):
    result = self.convert(1, "unknown")
    self.assertNotEqual(result.returncode, 0)
    self.assertEqual(result.stdout, "")

  def test_repository_and_archive_metrics(self):
    # Exercise the real text parsing and metric emission with deterministic
    # Borg output, including the user's reported repository statistics.
    with tempfile.TemporaryDirectory() as directory:
      output = Path(directory) / "metrics.prom"
      script = r'''
source "$1"
TMP_FILE="$2"
HOSTNAME=backup.example
BORG_PASSPHRASE=""
# Use the actual current date so the archive is included in today's metrics.
borg() {
  if [[ "$1" == list ]]; then
    echo "archive Thu, $(date +%Y-%m-%d) 00:00:00 [id]"
  else
    printf '%s\n' \
      'All archives: 8.63 TB 6.96 TB 1.02 TB' \
      'Chunk index: 1896063 16538670' \
      'This archive: 1.23 GB 4.56 MB 7.89 kB' \
      'Number of files: 42'
  fi
}
writeDefinitionsToMetrics
getBorgDataForRepository /backups/example host.example
'''
      result = subprocess.run(
        ["bash", "-c", script, "test", str(EXPORTER), str(output)],
        capture_output=True, text=True,
      )
      self.assertEqual(result.returncode, 0, result.stderr)
      metrics = {}
      for line in output.read_text().splitlines():
        if not line.startswith("#"):
          name, value = line.rsplit(" ", 1)
          metrics[name.split("{", 1)[0]] = float(value)
      expected = {
        "borg_total_size": 8630000000000,
        "borg_total_size_compressed": 6960000000000,
        "borg_total_size_dedup": 1020000000000,
        "borg_chunks_unique": 1896063,
        "borg_chunks_total": 16538670,
        "borg_last_size": 1230000000,
        "borg_last_size_compressed": 4560000,
        "borg_last_size_dedup": 7890,
      }
      for name, value in expected.items():
        self.assertEqual(metrics[name], value, name)

class DashboardTests(unittest.TestCase):
  def test_current_state_panels_use_instant_values(self):
    dashboard = json.loads(DASHBOARD.read_text())
    for panel in dashboard["panels"]:
      if panel["type"] == "row":
        continue
      with self.subTest(panel=panel["id"]):
        self.assertEqual(
          panel["options"]["reduceOptions"]["calcs"], ["lastNotNull"]
        )
        for target in panel["targets"]:
          self.assertTrue(target["instant"])
          self.assertFalse(target["range"])
        if "size" in panel["title"].lower():
          self.assertEqual(
            panel["fieldConfig"]["defaults"]["unit"], "decbytes"
          )

if __name__ == "__main__":
  unittest.main()
