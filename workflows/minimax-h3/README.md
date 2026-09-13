# MiniMax H3 local image-to-video

This directory contains the ComfyUI frontend-format I2V workflow used for the
local MiniMax H3 validation. It is derived from the Comfy-Org workflow template
and intentionally contains no private input image, generated video, model
weight, credential, or machine-specific absolute path.

## Requirements

- ComfyUI 0.33.1 or newer with MiniMax H3 nodes
- NVIDIA GPU with enough VRAM for the chosen resolution; the verified machine
  used an RTX 5090 32 GB with DynamicVRAM enabled
- `comfy-mcp` / comfy-cli for agent-driven runs, or the normal ComfyUI browser
  interface

Place the weights in the corresponding ComfyUI model categories (the physical
directories may instead be redirected with `extra_model_paths.yaml`):

```text
models/
├── diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors
├── text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors
├── vae/minimax_h3_video_vae_fp16.safetensors
├── vae/minimax_h3_audio_vae_fp32.safetensors
└── loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors
```

The committed workflow is local-only and contains no partner/API nodes, so a
normal run does not spend Comfy Cloud credits.

## Browser workflow

1. Import `minimax-h3-i2v.json` into ComfyUI.
2. In `Load Image`, select or upload the first frame.
3. Set `Resolution Selector` to `16:9 (Widescreen)`. A 0.9 MP target resolves
   to 1280 × 736 because H3 dimensions are rounded to a multiple of 32.
4. Edit the prompt inside `Image to Video (MiniMax H3)`.
5. Keep the template's video VAE, audio VAE, `minimax` CLIP type,
   `res_multistep` sampler, and `simple` scheduler.
6. Run the workflow and inspect several frames before increasing duration.

Start with 73 frames (about 3.04 seconds at 24 fps). Short clips are easier to
review for identity drift and can be chained by using the last clean frame as
the next clip's first frame.

## Local MCP workflow

The robust agent loop is:

1. `server_info` and `system_stats`
2. `validate_workflow`
3. `upload_file` for the first frame
4. `list_workflow_slots`
5. `vary_workflow` or `set_workflow_slot`
6. `run_workflow(wait=false)`
7. `job(action="wait")`
8. `fetch_outputs`

Useful slot addresses in this template:

| Address | Purpose | Recommended test value |
|---|---|---|
| `114.image` | uploaded first-frame filename | your PNG/WebP filename |
| `115.aspect_ratio` | output shape | `16:9 (Widescreen)` |
| `115.megapixels` | output area | `0.9` |
| `105/104.prompt` | motion and native-audio prompt | one continuous shot |
| `105/104.length` | frame count | `73` |
| `105/15.noise_seed` | reproducibility | fixed integer |
| `92.filename_prefix` | saved-video prefix | project/scene name |

Before a heavy run, free stale ComfyUI model caches if `system_stats` reports
very little available VRAM. This does not release VRAM owned by another
process.

## Prompting for fewer ghosts

Describe one subject, one continuous action, and a stable camera. Explicitly
preserve identity, markings, anatomy, composition, and background. Forbid
duplicate poses, double exposure, ghosting, extra limbs, duplicated heads or
tails, cuts, and uncontrolled morphing.

Avoid asking one short clip to contain several shots. Generate separate clips
and join them later. A useful structure is:

```text
Continue exactly from <Picture 1>. One subject only. In one continuous stable
shot, [single physical action]. Preserve exact identity, anatomy, composition,
lighting and material throughout. Subtle natural motion; minimal camera move.
No cuts, morphing, ghosting, double exposure, duplicate subject, extra limbs,
duplicated head or tail. Audio: [brief ambience/SFX description].
```

## KSampler failure diagnosis

If the error ends with:

```text
IndexError: list index out of range
audio_src = x[1]
```

the model received only one ordinary image latent. Load this complete workflow
instead of repairing a generic still-image graph. H3 requires both video and
audio latent branches, the H3 video/audio VAEs, and its dedicated
`MiniMaxH3ImageToVideo` conditioning.

## Provenance

Base workflow: Comfy-Org's MiniMax H3 Image-to-Video workflow template. Model
links and explanatory notes remain embedded in the JSON. Verify the model
licenses before redistribution or commercial use.
