terragrunt () {
        local action=$1
        shift 1
        command terragrunt $action "$@" 2>&1 | sed -E "s|$(dirname $(pwd))/||g;s|^\[terragrunt\]( [0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})* ||g;s|(\[.*\]) [0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}|\1|g"
}
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
export GOPATH=$HOME/go