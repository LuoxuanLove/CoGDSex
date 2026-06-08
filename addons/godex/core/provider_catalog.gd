@tool
class_name GodexProviderCatalog
extends RefCounted

const PROVIDERS := {
	"openai": {
		"name": "OpenAI",
		"base_url": "https://api.openai.com",
		"api_key_env": "OPENAI_API_KEY",
		"api_mode": "responses",
		"models": ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini", "gpt-5.3-codex", "gpt-5.2"],
	},
	"azure_openai": {
		"name": "Azure OpenAI",
		"base_url": "",
		"api_key_env": "AZURE_OPENAI_API_KEY",
		"api_mode": "chat_completions",
		"models": ["gpt-5.5", "gpt-5.4"],
	},
	"openai_compatible": {
		"name": "OpenAI Compatible",
		"base_url": "",
		"api_key_env": "OPENAI_API_KEY",
		"api_mode": "chat_completions",
		"models": ["gpt-5.5", "gpt-5.4-mini"],
	},
	"yurenapi": {
		"name": "Yuren OpenAI",
		"npm": "@ai-sdk/openai-compatible",
		"options": {
			"apiKey": "{env:YUREN_API_KEY}",
			"baseURL": "https://yurenapi.cn/v1",
		},
		"base_url": "https://yurenapi.cn/v1",
		"alternate_base_urls": ["https://yurenapi.com/v1"],
		"api_key_env": "YUREN_API_KEY",
		"api_mode": "chat_completions",
		"models": ["gpt-5.4-mini", "gpt-5.4", "gpt-5.5"],
		"model_details": {
			"gpt-5.4-mini": {
				"name": "GPT-5.4 Mini",
				"attachment": true,
				"reasoning": true,
				"limit": {"context": 400000, "input": 272000, "output": 128000},
				"modalities": {"input": ["text", "image", "pdf"], "output": ["text"]},
				"options": {"store": false},
				"variants": {
					"low": {"reasoningEffort": "low"},
					"medium": {"reasoningEffort": "medium"},
					"high": {"reasoningEffort": "high"},
					"xhigh": {"reasoningEffort": "xhigh"},
				},
			},
			"gpt-5.4": {
				"name": "GPT-5.4",
				"attachment": true,
				"reasoning": true,
				"limit": {"context": 400000, "input": 272000, "output": 128000},
				"modalities": {"input": ["text", "image", "pdf"], "output": ["text"]},
				"options": {"store": false},
				"variants": {
					"low": {"reasoningEffort": "low"},
					"medium": {"reasoningEffort": "medium"},
					"high": {"reasoningEffort": "high"},
					"xhigh": {"reasoningEffort": "xhigh"},
				},
			},
			"gpt-5.5": {
				"name": "GPT-5.5",
				"attachment": true,
				"reasoning": true,
				"limit": {"context": 400000, "input": 272000, "output": 128000},
				"modalities": {"input": ["text", "image", "pdf"], "output": ["text"]},
				"options": {"store": false},
				"variants": {
					"low": {"reasoningEffort": "low"},
					"medium": {"reasoningEffort": "medium"},
					"high": {"reasoningEffort": "high"},
					"xhigh": {"reasoningEffort": "xhigh"},
				},
			},
		},
	},
}


static func provider_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in PROVIDERS.keys():
		ids.append(str(key))
	return ids


static func get_provider(provider_id: String) -> Dictionary:
	return PROVIDERS.get(provider_id, PROVIDERS["openai"])


static func models_for(provider_id: String) -> Array:
	return get_provider(provider_id).get("models", [])


static func default_model_for(provider_id: String) -> String:
	var models := models_for(provider_id)
	return str(models[0]) if not models.is_empty() else "gpt-5.5"
