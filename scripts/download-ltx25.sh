#!/usr/bin/env bash
set -euo pipefail

comfy_root="${COMFY_ROOT:-/mnt/c/Users/whyke/Documents/comfy/ComfyUI}"
hf_exe="$comfy_root/.venv/Scripts/hf.exe"
models_win="$(wslpath -w "$comfy_root/models")"

if ! "$hf_exe" auth whoami >/dev/null 2>&1; then
  printf 'Hugging Face login is required. First accept the LTX-2.5 license at:\n'
  printf '  https://huggingface.co/Lightricks/LTX-2.5\n'
  printf 'Then run: %s auth login\n' "$hf_exe"
  exit 2
fi

"$hf_exe" download Lightricks/LTX-2.5 \
  diffusion_models/ltx-2.5-22b-distilled-transformer-nvfp4.safetensors \
  text_encoders/gemma4-12b-with-proj-ltx-2.5-comfy-int8-convrot.safetensors \
  vae/ltx-2.5-video-vae-conv-bf16.safetensors \
  vae/ltx-2.5-audio-vae-bf16.safetensors \
  model_patches/ltx-2.5-duration-head-bf16.safetensors \
  latent_upscale_models/ltx-2.5-latent-spatial-upscaler-x2-bf16-1.0.safetensors \
  --local-dir "$models_win"

