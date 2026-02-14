#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/tmp"
CMD=(npm run dev)

mkdir -p "$LOG_DIR"

while true; do
  ts=$(date +"%Y-%m-%d_%H-%M-%S")
  log_file="$LOG_DIR/aider-desk_${ts}.log"

  echo "Starting session at $ts"
  echo "Logging to $log_file"
  echo "Command: ${CMD[*]}"
  echo "Press Ctrl+C to stop this session."

  "${CMD[@]}" 2>&1 | tee "$log_file"

  echo "Session ended. Log saved to $log_file"
  read -r -p "Start another session? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    break
  fi
  echo ""
done
