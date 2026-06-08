@tool
class_name GodexContextCompressor
extends RefCounted

const DEFAULT_LIMIT := 24


func should_compress(context_used: int, context_budget: int, threshold_ratio: float = 0.72) -> bool:
	if context_budget <= 0:
		return false
	return float(context_used) / float(context_budget) >= threshold_ratio


func compress_messages(messages: Array, limit: int = DEFAULT_LIMIT) -> Dictionary:
	if messages.size() <= limit:
		return {"compressed": false, "messages": messages, "summary": ""}
	var keep_count := maxi(6, int(limit / 2))
	var removed := messages.slice(0, messages.size() - keep_count)
	var kept := messages.slice(messages.size() - keep_count)
	var summary_lines: Array[String] = []
	for item in removed:
		var role := str(item.get("role", "user"))
		var content := str(item.get("content", "")).strip_edges()
		if content.length() > 120:
			content = content.substr(0, 120) + "..."
		summary_lines.append("%s: %s" % [role, content])
	return {
		"compressed": true,
		"messages": kept,
		"summary": "\n".join(summary_lines),
	}
