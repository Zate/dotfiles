# PATH setup

# Add ~/bin to PATH
if [[ -d "${HOME}/bin" ]] && [[ ":${PATH}:" != *":${HOME}/bin:"* ]]; then
    export PATH="${HOME}/bin:${PATH}"
fi

# Add ~/.local/bin to PATH
if [[ -d "${HOME}/.local/bin" ]] && [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi
