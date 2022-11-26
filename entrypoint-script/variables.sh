DOCKER_IMAGE_VERSION="2.0.0"
BORG_VERSION=$(borg -V)
SSH_FOLDERS=( "/sshkeys/clients" "/sshkeys/host" )
NODE_EXPORTER_DIR="/var/log"
COLUMNS="86"
##############################################################################################################################
# Funktionen
##############################################################################################################################
function sepurator {
  if [ ! -z "$2" ]; then
    local end="$2"
  else
    local end="$COLUMNS"
  fi

  local start=1
	local str="${1:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
  echo;
}
