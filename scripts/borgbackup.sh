##############################################################################################################################
# Borg Backup Funktionen
##############################################################################################################################
function create_borg_backup {
  # $1 = ARCHIVE NAME
  # $2 = FOLDER TO BACKUP
  local ARCHIVE_NAME="$1"
  local FOLDER_TO_BACKUP="$2"

  if [ -z "$ARCHIVE_NAME" ]; then
    echo "No archive name provided"
    return 1
  fi
  if [ -z "$FOLDER_TO_BACKUP" ]; then
    echo "No folder to backup provided"
    return 1
  fi
  if [ -z "$BORG_CREATE_PARAMS" ]; then
    echo "No borg create params provided"
    return 1
  fi

  echo "Creating Borg Backup from $FOLDER_TO_BACKUP into the Archive: $ARCHIVE_NAME"
  borg create "${BORG_CREATE_PARAMS[@]}" "$BORG_REPO"::"$ARCHIVE_NAME-{now:%d.%m.%Y_%H:%M}" "$FOLDER_TO_BACKUP"
  backup_exit=$?
}

function purge_borg_backup {
  # $1 = ARCHIVE NAME
  local ARCHIVE_NAME="$1"

  if [ -z "$ARCHIVE_NAME" ]; then
    echo "No archive name provided"
    return 1
  fi
  if [ -z "$BORG_PRUNE_PARAMS" ]; then
    echo "No borg purge params provided"
    return 1
  fi

  echo "Purging Borg Backup Archive: $ARCHIVE_NAME"
  borg prune -a "$ARCHIVE_NAME-*" "${BORG_PRUNE_PARAMS[@]}"
  prune_exit=$?
}

function compact_borg_backup {
  borg compact --progress ::
  compact_exit=$?
}
