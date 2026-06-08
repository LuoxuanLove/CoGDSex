# Provider Presets

Godex stores provider presets as auditable local data under `addons/godex/core/provider_catalog.gd`. API keys should prefer environment variables over raw persisted secrets.

Provider presets are not defaults unless the state layer explicitly chooses them. The Yuren preset is available for development and debugging, but users must select it or load existing Yuren settings before Godex switches away from the default OpenAI configuration.

## Yuren OpenAI

- Provider id: `yurenapi`
- Display name: `Yuren OpenAI`
- SDK style: `@ai-sdk/openai-compatible`
- Recommended Base URL: `https://yurenapi.cn/v1`
- Alternate valid Base URL: `https://yurenapi.com/v1`
- Default API mode: `chat_completions`
- API key environment variable: `YUREN_API_KEY`

### Models

- `gpt-5.4-mini`
  - Display name: `GPT-5.4 Mini`
  - Attachments: enabled
  - Reasoning: enabled
  - Limits: context `400000`, input `272000`, output `128000`
  - Input modalities: `text`, `image`, `pdf`
  - Output modalities: `text`
  - Options: `store=false`
  - Reasoning variants: `low`, `medium`, `high`, `xhigh`
- `gpt-5.4`
  - Display name: `GPT-5.4`
  - Attachments: enabled
  - Reasoning: enabled
  - Limits: context `400000`, input `272000`, output `128000`
  - Input modalities: `text`, `image`, `pdf`
  - Output modalities: `text`
  - Options: `store=false`
  - Reasoning variants: `low`, `medium`, `high`, `xhigh`
- `gpt-5.5`
  - Display name: `GPT-5.5`
  - Attachments: enabled
  - Reasoning: enabled
  - Limits: context `400000`, input `272000`, output `128000`
  - Input modalities: `text`, `image`, `pdf`
  - Output modalities: `text`
  - Options: `store=false`
  - Reasoning variants: `low`, `medium`, `high`, `xhigh`

## Runtime Reasoning Mapping

The composer reasoning menu stores one of `low`, `medium`, `high`, or `xhigh` in `GodexState.reasoning_effort`.

- Responses API payloads receive `reasoning.effort`.
- Chat Completions-compatible payloads receive `reasoning_effort`; OpenAI-compatible presets such as Yuren default to this mode and resolve to `/v1/chat/completions`.
- Tool-result continuation payloads retain the same effort as the original state.
- Request snapshots and model events expose the selected effort for audit without exposing raw API keys.
