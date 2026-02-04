# Project Requirements Appendix (Models & Providers)

## Planning (Architecture & Design)
- Primary: Claude 3.5 Sonnet (API)
- Fallback: Claude 3 Opus
- Local: Llama 3.1 70B (Ollama/MLX)
- Env: ANTHROPIC_API_KEY, OPENAI_API_KEY (optional), OLLAMA_HOST, MLX_* (tensor_parallel/max_gpus/vram_limit/batch_plan)

## Build (Implementation)
- Primary: DeepSeek Coder V2 16B-instruct (Ollama)
- Fallback: Llama 3.1 70B
- Local small edits: LM Studio Phi-4-mini
- Env: OLLAMA_MODEL_BUILD, LMSTUDIO_MODEL_BUILD, MLX_BATCH_BUILD, MLX_TEMP_BUILD

## Review (Quality)
- Primary: Claude 3.5 Sonnet
- Fallback: Claude 3 Opus
- Local: Llama 3.1 70B
- Env: ANTHROPIC_API_KEY, OLLAMA_MODEL_REVIEW, MLX_BATCH_REVIEW, MLX_TEMP_REVIEW

## Notes
- Use OpenCode Zen as curated API provider when available.
- Keep appendix out of main prompt unless tuning models.
