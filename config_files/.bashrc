# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto -T'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lsd="ls -ad */"
alias du="du --apparent-size"

################################################################################

### function to upload files via transfer.sh
transfer() {
    curl --progress-bar --upload-file "$1" https://transfer.sh/$(basename "$1") | tee /dev/null;
    #wget -t 1 -qO - --method=PUT --body-file="$1" --header="Content-Type: $(file -b --mime-type "$1")" https://transfer.sh/$(basename "$1");
    echo
}

#### custom settings
export HISTTIMEFORMAT='%F %T '
export PAGER=less
export QT_QPA_PLATFORMTHEME=gtk2

#### custom aliases
alias dmesg="dmesg --color"
alias bd=". bd -si"
alias vi="nvim"
alias vim="nvim"
alias lx="exa -bghHaliS"
alias date="date +'%a %d %h %Y %T'"
alias transfer=transfer

### custom FireFox profiles
alias firefox_burpsuite="firefox -P 'BurpSuite'"
alias firefox_tor="firefox -P 'Tor'"

### custom library paths
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/oracle/instantclient

### custom binary paths
export GOPATH=~/go
export CARGOPATH=~/.cargo
export ORACLEPATH=$LD_LIBRARY_PATH:/opt/mssql-tools/bin
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:${ORACLEPATH}:${GOPATH}/bin:${CARGOPATH}/bin:

### only load LiquidPrompt in interactive shells, not from a script or from scp
echo $- | grep -q i 2>/dev/null && . /usr/share/liquidprompt/liquidprompt
