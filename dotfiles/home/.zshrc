export ZSH="$HOME/.oh-my-zsh"
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /opt/homebrew/share/zsh-you-should-use/you-should-use.plugin.zsh

MAGIC_ENTER_GIT_COMMAND='gss'
MAGIC_ENTER_OTHER_COMMAND='ls'

# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

plugins=(
  aliases
  autoenv
  aws
  colored-man-pages
  docker
  docker-compose
  encode64
  extract
  gh
  git-commit
  git-extras
  git
  gitignore
  helm
  httpie
  kubectl
  macos
  magic-enter
  minikube
  starship
  terraform
  tig
  vscode
  z
  history-substring-search
)

# Brew completions
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# OMZ
source $ZSH/oh-my-zsh.sh

# Exports
export LANG=en_US.UTF-8
export EDITOR='nvim'
export KUBECONFIG=$KUBECONFIG:$(ls ~/.kube | grep conf | awk -v d="$HOME/.kube/" '{ printf "%s%s:", d,$0}')
export WORKON_HOME=$HOME/.virtualenvs
export PIP_REQUIRE_VIRTUALENV=true
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export VIRTUALENVWRAPPER_PYTHON='/opt/homebrew/bin/python3'
export VIRTUALENVWRAPPER_VIRTUALENV='/opt/homebrew/bin/virtualenv'
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export PAGER="bat -p"
export XDG_CONFIG_HOME=$HOME/.config
export YSU_MESSAGE_POSITION="after"

export PATH=$PATH:$HOME/.dotfiles
export PATH=$PATH:$HOME/.dotfiles/scripts
export PATH=$PATH:$HOME/.local/bin
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.krew/bin"
export PATH="$PATH:$HOME/.dotfiles"
export PATH="$PATH:$HOME/.dotfiles/scripts"
export PATH="$PATH:$(npm get prefix -g)/bin"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"


#Alias
alias ggr="git graph"
alias ggra="git graph --all"
alias gua="git unadd"
alias gcm="git commit -m"
alias yolo='git commit -m "$(curl -s http://whatthecommit.com/index.txt)"'
alias gcf='git commit --amend --reuse-message=HEAD'
alias al="alias | grep"
alias alf="alias | fzf"
alias k=kubectl
alias kb=kubectl
alias kcuc="kubectl config use-context"
alias kcn="kubectl config set-context --current --namespace"
alias ldk="lazydocker"
alias sl="ls"
alias cat=bat
alias addr="http -b https://ifconfig.co/json"
alias rnt='airnity'
alias vim="nvim"
alias vi="nvim"

# GPG
gpgconf --launch gpg-agent

# Virtualenvwrapper
source /opt/homebrew/bin/virtualenvwrapper_lazy.sh

# Nodenv
eval "$(nodenv init -)"

# Airnity cli
source <(airnity completion zsh); compdef _airnity airnity

# History substring
bindkey '^p' history-substring-search-up

# Autoenv
AUTOENV_ENABLE_LEAVE="true"
AUTOENV_ASSUME_YES="true"
source $(brew --prefix autoenv)/activate.sh

source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
