# Deep research source report

Date: 2026-08-25 (America/Toronto)

## Executive decision

Start with **LTX-2.5 distilled NVFP4 on the RTX 5090**, with ComfyUI's default dynamic model unloading. It is the newest practical open-weight audio-video model for this exact Blackwell card: native ComfyUI support, an 18.72 GB NVFP4 transformer, an INT8 Gemma 4 text encoder, an 8-step distilled schedule, synchronized audio, and multi-shot generation. The full working pack is about 37.0 GB on disk, but components need not be resident simultaneously.

Use the RTX 5080 for a small, tool-trained panel agent. The best first agent is `artokun/gemma4-comfyui-mcp:e4b` (about 3.5 GB VRAM; 14/20 in the project's local arena) or `:12b` (about 8 GB). These models know the exact ComfyUI MCP tool surface but are text-only; use Qwen3.8-27B or the existing 122B in a separate planning/review window when vision or deeper reasoning matters.

Do not try to keep the current 122B server and a serious video render resident together. It already uses roughly 31.9 GB on the 5090 and 15.0 GB on the 5080. GPU ownership must be explicit.

## Machine evidence

- Windows ComfyUI root: `C:\Users\whyke\Documents\comfy\ComfyUI`
- Core commit: `72865f4f27eaf5396f8f36370e0a2be3a9a090ee`, ComfyUI v0.33.1 (2026-08-13)
- Python 3.11.9; PyTorch 2.13.0+cu130; CUDA available
- Windows device 0: RTX 5090, 34,190,458,880 bytes; device 1: RTX 5080, 17,094,475,776 bytes
- The source tree contains native local LTX-2.5 and MiniMax H3 model/node implementations.
- No video checkpoint was installed at audit time. The only pre-existing custom pack was frame interpolation.
- Agent Panel installed at commit `ef45e976dc63d1b9c3baf53fcbe18c4ba1f328dd`.
- Live MCP negotiation succeeded with protocol `2025-06-18`; pinned server 0.52.100 exposed exactly the three compact meta-tools and reported 38 catalog tools behind them.
- The guarded launcher was tested end to end: stop 122B, start ComfyUI on the 5090, query native nodes, stop ComfyUI, restore `keying-deep` healthy on port 8001.

## Current open-weight landscape

Artificial Analysis' 2026-08 open-weight video arena puts MiniMax H3 first for text-to-video with audio (Elo 1,228), followed by LTX-2.5 Fast and Pro. That is a preference leaderboard, not a local-hardware fit test. [AA text-to-video open-weight leaderboard](https://artificialanalysis.ai/video/leaderboard/text-to-video/open-weights)

### 1. LTX-2.5 — first install

The official model card documents native multi-shot generation, diffusion-fidelity rendering, a new video decoder, a custom Gemma 4 12B encoder, a prompt enhancer, and a distilled model. Official ComfyUI-aligned components include NVFP4 and INT8 variants. [Lightricks LTX-2.5 model card](https://huggingface.co/Lightricks/LTX-2.5)

Measured from the Hugging Face repository tree:

| Component | Bytes | Role |
|---|---:|---|
| distilled transformer NVFP4 | 18,721,548,408 | Blackwell-optimized 8-step DiT |
| Gemma4 encoder INT8 | 15,372,969,374 | prompt encoder + projections |
| convolutional video VAE BF16 | 1,452,269,922 | lighter decode path |
| audio VAE BF16 | 364,866,540 | synchronized audio |
| spatial upscaler | 995,778,752 | second-stage 2x latent upscale |
| duration head | 3,843,690 | optional frame-count prediction |

This is a gated download. The user must accept the LTX community license and authenticate; automation must not pretend that this consent happened. The model card states free commercial/production use for entities under US$10M annual revenue, with paid terms above that and conditions on transferring fine-tunes. Read the binding license before commercial use.

### 2. MiniMax H3 — quality benchmark, later experiment

H3 is a 33B omni-transformer generating 768p video with stereo audio. It also uses a truncated Qwen3-VL-32B encoder. The official deployment example uses four GPUs and explicitly says sparse-attention inference is not in the initial release. [MiniMax H3 official model card](https://huggingface.co/MiniMaxAI/MiniMax-H3)

The official FL2VA files total roughly 145 GB: about 66 GB transformer, 67 GB text encoder, 10.4 GB video VAE, plus audio VAE and metadata. ComfyUI can offload or use community quants, but this is a slower and more fragile first setup on 32 GB VRAM. Its community license also requires region/commercial review. Queue it after LTX-2.5 is stable.

### 3. Wan2.2 TI2V 5B — reliable low-memory baseline

ComfyUI's official guide says the 5B hybrid fits well in 8 GB VRAM with native offloading. It is a strong diagnostic baseline and can run on the 5080 while a planner occupies the 5090. It does not match the newer native-audio/multi-shot feature set. [Official Wan2.2 ComfyUI workflow](https://docs.comfy.org/tutorials/video/wan/wan2_2)

### 4. HunyuanVideo-1.5 — middleweight alternative

Tencent documents an 8.3B model, a 14 GB minimum with offloading, T2V/I2V, and accelerated distilled paths. It is useful when LTX prompt/identity behavior is unsuitable, but it is no longer the first generic install. [Tencent HunyuanVideo-1.5](https://github.com/Tencent-Hunyuan/HunyuanVideo-1.5)

## Agent model queue

Artificial Analysis currently ranks Qwen3.8-27B at 52 in its xhigh setting, far ahead of other locally sized open models on that page. It is dense, 256K context, multimodal, Apache-2.0, and is therefore the new deep planner/visual reviewer candidate. [AA small open-model table](https://artificialanalysis.ai/models/open-source/small), [official Qwen3.8 repository](https://github.com/QwenLM/Qwen3.8), [official model card](https://huggingface.co/Qwen/Qwen3.8-27B)

| Priority | Candidate | Decision |
|---:|---|---|
| 1 | Gemma4 ComfyUI MCP e4b/12b | Dedicated 5080 tool agent; exact-tool fine-tune; no vision |
| 2 | Qwen3.8-27B Q5 + mmproj | Deep planning and visual QA in an exclusive window; benchmark repo created |
| 3 | Ling-3.0-flash Q4 | Interesting sparse 124B/5.1B-active model; official llama.cpp recipe exists, but total weights still exceed one card and it is not video-specific |
| skip local | Kimi K3, Qwen3.8 2.4T, DeepSeek V4 Pro | Top leaderboard entries, but 1.6–2.8T total weights are physically inappropriate here |

Qwen3.8-27B was then tested, not merely shortlisted. With a 19.68 GB Q5_K_S GGUF and 0.93 GB BF16 vision projector on the RTX 5090, llama.cpp b9733 recorded 21,161 MiB used after load and 63.24 tok/s on a 256-token native completion. Constrained Chinese, constrained Python, native OpenAI tool calling, and vision all passed at roughly 64–65 tok/s. Cold loading from D: through WSL 9p took about 12 minutes, so it is a strong exclusive-window planner/reviewer rather than a model to reload between every video shot. Raw evidence and the reproducible launcher are in the [Qwen3.8 experiment repository](https://github.com/WHYKEYSAY/serve-qwen3.8-27b).

The ComfyUI MCP project states tool calling is mandatory and recommends thinking and vision. Compact mode exposes only `list_tools`, `describe_tool`, and `call_tool`, which is the correct schema budget for local models. Its own Gemma4 fine-tune was trained on 1,055 server-verified trajectories, but current published rungs are text-only. [comfyui-mcp](https://github.com/artokun/comfyui-mcp), [local fine-tune guidance](https://github.com/artokun/comfyui-mcp/blob/main/plugin/skills/local-llm-free/SKILL.md)

## Two different integrations

1. **Codex → comfyui-mcp → ComfyUI** is configured in `~/.codex/config.toml`. It lets this coding agent operate the graph.
2. **ComfyUI Agent Panel → local OpenAI/Ollama backend** is configured inside the panel. For llama.cpp choose Custom endpoint/llama.cpp, base URL `http://127.0.0.1:8001/v1`, model `keying-deep`, no key. For the small dedicated agent, use the panel's Ollama provider and the Gemma4 fine-tune.

Changing the Codex model provider does not automatically configure the panel backend.

The installed default-user settings were seeded with backend `custom`, base URL `http://127.0.0.1:8001/v1`, and model `keying-deep`. No API key is stored because the loopback server does not require one.

A direct OpenAI-compatible acceptance call against that exact endpoint returned `finish_reason=tool_calls` and a valid `get_weather({"city":"Toronto"})` invocation. This verifies the hard tool-calling prerequisite before the panel is asked to drive the catalog.

## Operating policy

- Render lane: 5090 only, `--cuda-device 0`, reserve 1.5 GB, default dynamic VRAM, no previews.
- Agent lane: 5080 only when using a dedicated small model.
- Never use `--highvram` for the split LTX-2.5 pack.
- Start with distilled NVFP4 + INT8 text encoder + convolutional VAE. Add DiffVAE/full dev transformer only after a quality comparison.
- Keep workflow JSON and seeds with every result. Record model hashes, ComfyUI commit, node commits, dimensions, frames, sampler, steps, peak VRAM, wall time, and output path.
- Bind ComfyUI to `127.0.0.1` unless LAN access is explicitly secured.

## Test matrix

1. MCP health: system stats, node catalog, queue, one empty workflow edit.
2. Wan2.2 5B baseline: 512–720p, 81 frames, T2V then I2V.
3. LTX-2.5 distilled: 960×544×121 at 24 fps, fixed seed, T2V and I2V, audio on.
4. LTX-2.5 multi-shot: identity continuity across two cuts.
5. Compare conv VAE vs DiffVAE and one-stage vs upscaled two-stage.
6. Only then test quantized/offloaded MiniMax H3 FL2VA.

## Known blockers

- LTX-2.5 access is gated and this machine is not logged into Hugging Face.
- The current 122B endpoint consumes both GPUs; it must be swapped out during render.
- ComfyUI core has an existing dirty working tree (predominantly line-ending changes). This work intentionally did not alter or reset those files.
- No output-quality claim is made until the gated checkpoint is downloaded and the fixed-seed matrix is run.
