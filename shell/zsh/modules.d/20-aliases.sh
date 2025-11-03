# Common aliases

# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Human-readable sizes
alias df='df -h'
alias du='du -h'

# Dotfiles management
alias dotfiles='${DOTFILES_DIR}/bin/dotfiles'
