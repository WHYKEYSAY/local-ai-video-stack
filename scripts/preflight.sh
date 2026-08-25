#!/usr/bin/env bash
set -euo pipefail

comfy_root="${COMFY_ROOT:-/mnt/c/Users/whyke/Documents/comfy/ComfyUI}"
python_exe="$comfy_root/.venv/Scripts/python.exe"

test -f "$comfy_root/main.py"
test -x "$python_exe"

printf 'ComfyUI: %s\n' "$comfy_root"
git -C "$comfy_root" log -1 --format='commit: %H (%cs) %s'
"$python_exe" -c 'import sys, torch; print("python:", sys.version.split()[0]); print("torch:", torch.__version__, "cuda:", torch.version.cuda); [print("gpu", i, torch.cuda.get_device_name(i), torch.cuda.get_device_properties(i).total_memory) for i in range(torch.cuda.device_count())]'

printf 'custom nodes:\n'
find "$comfy_root/custom_nodes" -maxdepth 1 -mindepth 1 -type d -printf '  %f\n' | sort

printf 'ports:\n'
for port in 8001 8188; do
  if curl -fsS --max-time 2 "http://127.0.0.1:${port}/health" >/dev/null 2>&1 || curl -fsS --max-time 2 "http://127.0.0.1:${port}/system_stats" >/dev/null 2>&1; then
    printf '  %s reachable\n' "$port"
  else
    printf '  %s not running\n' "$port"
  fi
done

nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader

