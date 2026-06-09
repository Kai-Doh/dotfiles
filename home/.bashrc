#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias update-dot='~/dotfiles/update.sh'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

tmux() {
  if [[ -n "$TMUX" ]]; then
    command tmux "$@"
    return
  fi
  local sessions
  sessions=$(command tmux ls 2>/dev/null | sed 's/:.*$//')
  if [[ -z "$sessions" ]]; then
    command tmux
    return
  fi
  local choice
  choice=$(printf 'New session\n%s' "$sessions" | fzf --prompt=" tmux  " --height=~10 --border)
  [[ -z "$choice" ]] && return
  if [[ "$choice" == "New session" ]]; then
    local name
    read -rp "Session name: " name
    command tmux new-session ${name:+-s "$name"}
  else
    command tmux attach -t "$choice"
  fi
}
