# Local AI video stack — RTX 5090 + RTX 5080

Reproducible configuration and research for this machine's local ComfyUI, AI-video models, MCP agent, and GPU arbitration.

## Recommended layout

| Lane | GPU | Workload |
|---|---|---|
| Render | RTX 5090 32 GB (`--cuda-device 0` in Windows ComfyUI) | LTX-2.5 NVFP4, then MiniMax H3 only as a later offload experiment |
| Agent | RTX 5080 16 GB | `artokun/gemma4-comfyui-mcp:e4b` or `:12b`; compact MCP tools |
| Deep planner | exclusive GPU window | Qwen3.8-27B Q5 + vision, or the existing Qwen3.5-122B; unload before rendering |

The standing 122B server occupies both GPUs. `scripts/start-comfyui-wsl.sh` stops it, starts ComfyUI on the 5090, and restores the server on exit.

## What is configured

- Real ComfyUI root: `C:\Users\whyke\Documents\comfy\ComfyUI`
- ComfyUI v0.33.1, Windows PyTorch 2.13.0 + CUDA 13.0
- Agent Panel installed at `custom_nodes/comfyui-agent-panel`
- Codex MCP pinned to `comfyui-mcp@0.52.100`, explicit path/URL, compact mode
- Agent Panel defaults separately to `http://127.0.0.1:8001/v1`, model `keying-deep`
- Qwen3.8-27B Q5 + vision independently verified on the 5090 at a 100.9 tok/s five-test mean with MTP2; see the [experiment repo](https://github.com/WHYKEYSAY/serve-qwen3.8-27b)

## Verified MiniMax H3 image-to-video workflow

The repository now includes a local, credit-free MiniMax H3 I2V workflow at
[`workflows/minimax-h3/minimax-h3-i2v.json`](workflows/minimax-h3/minimax-h3-i2v.json).
It was validated on the Windows ComfyUI instance above and produced a 73-frame,
24 fps test clip at 1280 × 736 without the generic-KSampler latent error.

Use the workflow as a complete graph. Do not connect the H3 diffusion model to
`EmptySD3LatentImage -> KSampler`: H3 is a joint audio/video model and expects
paired video and audio latents. That incorrect graph fails in
`comfy/ldm/minimax/model.py` at `audio_src = x[1]`.

See [`workflows/minimax-h3/README.md`](workflows/minimax-h3/README.md) for model
placement, local MCP operation, reproducible settings, and anti-ghosting prompt
guidance.

## Run

```bash
./scripts/preflight.sh
./scripts/start-comfyui-wsl.sh
```

Then open <http://127.0.0.1:8188>. Stop with Ctrl-C; the script restores `keying-122b.service` and waits for `/health`.

The panel is already seeded to **Custom endpoint → keying-deep**. This is intentionally separate from Codex's own MCP/provider settings.

LTX-2.5 is gated. First accept its license on Hugging Face and log in with the ComfyUI venv's `hf.exe`, then run:

```bash
./scripts/download-ltx25.sh
```

Use the built-in LTX-2.5 distilled workflow, the NVFP4 transformer, INT8 text encoder, lighter convolutional video VAE, and native dynamic offload. Do not enable `--highvram` for this pack.

See [report-source.md](report-source.md) for the evidence, model queue, caveats, and decision rationale.
