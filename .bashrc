alias update='apk update && apk upgrade'

export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'

source /etc/profile.d/bash_completion.sh

export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\\$ "
##############################################################################################################################
# Borg Repo finder
##############################################################################################################################
source "/variables.sh"

function sepurator {
  echo "=============================================================================================="
}

function find_borg_repo {
  repo_list=( $(find "$1" -name "index.*" -type f | rev | cut -d '/' -f "2-" | rev) )

  if [ -z "$repo_list" ]; then
    sepurator
    echo "* Can not find borg repository"
  else
    sepurator
    echo "* Select borg repository"
    sepurator
    select_borg_repo
  fi
}

function select_borg_repo {
  if [ "${#repo_list[@]}" -eq 1 ]; then
    echo "* Only one item"
    sepurator
    selected_repo="0"
  else
    for key in "${!repo_list[@]}" ; do
      echo "$key: ${repo_list[key]}"
    done

    echo ""

    selected_repo=asfd
    while ! [[ $selected_repo -lt ${#repo_list[@]} && $selected_repo =~ ^[+]?[0-9]+$ ]]; do
      read -p "Please select a Repo: " selected_repo

      if [[ $selected_repo -gt $((${#repo_list[@]} -1)) ]]; then
        sepurator
        echo "* Oops! User input was out of range!"
        sepurator
      fi

      if ! [[ $selected_repo =~ ^[+]?[0-9]+$ ]]; then
        sepurator
        echo "* Oops! User input was not a positive integer!"
        sepurator
      fi
    done
  fi
  sepurator
}

function ask_for_repo_password {
  if grep -q 'key' "$BORG_REPO/config"; then
    echo "* BORG REPO has a password"
    sepurator
    echo "(you can leave it empty if you not like to export BORG_PASSPHRASE)"
    read -s -p "Please enter password: " BORG_REPO_PASSWORD
    echo ""
    if [ "$BORG_REPO_PASSWORD" != "" ]; then
      export BORG_PASSPHRASE="$BORG_REPO_PASSWORD"
    fi
  else
    echo "* BORG REPO has no password"
  fi
  sepurator
}

function print_container_info {
  sepurator
  echo "BorgServer powered by $BORG_VERSION - Image Hostname: $HOSTNAME | Image Version: $DOCKER_IMAGE_VERSION"
  sepurator
}
##############################################################################################################################
# Run Code
##############################################################################################################################
if [ "$INTERACTIVE_MODE" != "false" ]; then
  find_borg_repo backups/
  export BORG_REPO="${repo_list[selected_repo]}"
  if [ ! -z "$BORG_REPO" ]; then
    ask_for_repo_password
    clear
  fi
fi

print_container_info
neofetch
