#!/usr/bin/env bash
set -euo pipefail

comfy_root="${COMFY_ROOT:-/mnt/c/Users/whyke/Documents/comfy/ComfyUI}"
python_exe="$comfy_root/.venv/Scripts/python.exe"
main_win="$(wslpath -w "$comfy_root/main.py")"
restore_122b=0

restore_service() {
  if (( restore_122b )); then
    printf 'Restoring keying-122b.service...\n'
    systemctl --user start keying-122b.service
    for _ in $(seq 1 180); do
      if curl -fsS --max-time 2 http://127.0.0.1:8001/health >/dev/null 2>&1; then
        printf 'keying-deep is healthy on :8001\n'
        return
      fi
      sleep 5
    done
    printf 'WARNING: keying-122b.service was started but did not become healthy within 15 minutes.\n' >&2
  fi
}
trap restore_service EXIT

if systemctl --user is-active --quiet keying-122b.service; then
  restore_122b=1
  printf 'Stopping keying-122b.service to free both GPUs...\n'
  systemctl --user stop keying-122b.service
fi

for _ in $(seq 1 60); do
  if ! pgrep -f '/llama-server .*--port 8001' >/dev/null; then
    break
  fi
  sleep 2
done

printf 'Starting ComfyUI on Windows GPU 0 (RTX 5090): http://127.0.0.1:8188\n'
"$python_exe" "$main_win" \
  --listen 127.0.0.1 \
  --port 8188 \
  --cuda-device 0 \
  --reserve-vram 1.5 \
  --preview-method none

