DOCKER_IMAGE_VERSION="3.1.0"
BORG_VERSION=$(borg -V)
SSH_FOLDERS=( "/sshkeys/clients" "/sshkeys/host" )
NODE_EXPORTER_DIR="/var/log"
DEFAULT_COLUMNS="86"
###############################################################################
# Funktionen
###############################################################################
function sepurator {
  if [ -n "${2:-}" ]; then
    local end="$2"
  else
    local end
    end=$(tput cols 2>/dev/null || echo "${COLUMNS:-${DEFAULT_COLUMNS:-80}}")
  fi

  local start=1
	local str="${1:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
  echo;
}
