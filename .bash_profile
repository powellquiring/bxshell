reset=$(tput sgr0)
bold=$(tput bold)

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

export PS1="\[$reset\]\
bxshell[\
$bold\
(\$BXSHELL_TARGET) \
g:\$(cat ~/.bluemix/config.json | jq .ResourceGroup.Name -r) > \
r:\$(cat ~/.bluemix/config.json | jq .Region -r) > \
o:\$(cat ~/.bluemix/.cf/config.json | jq .OrganizationFields.Name -r) > \
s:\$(cat ~/.bluemix/.cf/config.json | jq .SpaceFields.Name -r)\
$reset\
]\
\n\
\w> "

# Bluemix CLI
bx plugin repo-add Bluemix https://plugins.ng.bluemix.net

# Auto completion
. /usr/local/ibmcloud/autocomplete/bash_autocomplete
source <(kubectl completion bash)
source <(helm completion bash)

# Useful aliases
alias bxlogin='bx login --apikey "$BLUEMIX_API_KEY" -o "$BLUEMIX_ORG" -s "$BLUEMIX_SPACE"'
alias kubeconsole='echo Open your browser at http://$(docker port $CONTAINER_NAME 8001)/ui && kubectl proxy --accept-hosts='.*' --address='0.0.0.0''
alias freeconsole='echo Only do this on environment you trust && kubectl create -f /opt/support/kubernetes-dashboard-unlock.yaml'
alias cf='bx cf'
alias wsk='bx wsk'
# split window with activation poll on top
alias tmuxwsk="tmux new-session \; send-keys 'wsk activation poll' C-m \; split-window -v \;"

# Istio
export PATH="$PATH:/usr/local/istio/bin"

# disable Terraform calling home
# https://www.terraform.io/docs/commands/index.html#disable_checkpoint
export CHECKPOINT_DISABLE=true

# History
export HISTFILE=$HOME/mnt/config/.bash_history
export PROMPT_COMMAND='history -a'

# Additional customization per env
if [ -f ~/mnt/config/.env_profile ]; then
  echo Loading custom environment profile
  . ~/mnt/config/.env_profile
fi

# Powerline
if [[ $BXSHELL_ENABLE_POWERLINE ]]; then
  mkdir -p /root/.config/powerline-shell
  # link the user configuration
  if [ -f ~/mnt/config/powerline-shell-config.json ]; then
    ln -s ~/mnt/config/powerline-shell-config.json ~/.config/powerline-shell/config.json
  # or the default if no custom config
  else
    ln -s /opt/support/powerline-shell/config.json ~/.config/powerline-shell/config.json
  fi

  function _update_ps1() {
    PS1=$(powerline-shell $?)
  }

  if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi

  # this helps with long command lines and going up in the history
  stty columns 3000
fi

# Done only on the login shell
if [ "$SHLVL" == "1" ]; then
  if [ -d "$HOME/mnt/home/.ssh" ]; then
    ln -s $HOME/mnt/home/.ssh/ $HOME/.ssh
  fi

  cat $HOME/.motd.txt

  echo Port mapping at your convenience:
  docker port $CONTAINER_NAME | awk '{print $1 " -> " $3 " -> http://" $3}'
fi

# change directory to a directory under the user home dir
cd "$CONTAINER_STARTUP_DIR"
