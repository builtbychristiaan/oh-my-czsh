kill-cursor-process() {
  local port="${1:-5432}"
  local pids
  pids=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -c Cursor -t)
  [ -n "$pids" ] && kill $pids
}
