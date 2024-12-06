if [ ! -z $(cat /etc/environment | grep "USE_TMUX_SHELL") ] && [[ -t 0 ]] && [ -z "$TMUX"  ]; then 
  tmux attach || tmux new-session 
  exit
fi

alias update='sudo pacman -Syu --noconfirm'

export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'

export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\\$ "
##############################################################################################################################
# Functions
##############################################################################################################################
source "/variables.sh"
COLUMNS=$(/usr/bin/tput cols)

function print_container_info {
  sepurator
  echo "BorgServer powered by $BORG_VERSION - Image Hostname: $HOSTNAME | Image Version: $DOCKER_IMAGE_VERSION"
  sepurator
}
##############################################################################################################################
# Run Code
##############################################################################################################################
print_container_info
neofetch
