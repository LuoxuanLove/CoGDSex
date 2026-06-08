@tool
class_name GodexApprovalPolicy
extends RefCounted

const RISK_LOW := "low"
const RISK_MEDIUM := "medium"
const RISK_HIGH := "high"

var default_mode := "review"


func classify_action(action: String) -> Dictionary:
	var normalized := action.to_lower()
	if normalized.contains("delete") or normalized.contains("remove") or normalized.contains("command") or normalized.contains("network"):
		return {"requires_approval": true, "risk": RISK_HIGH}
	if normalized.contains("write") or normalized.contains("patch") or normalized.contains("run"):
		return {"requires_approval": true, "risk": RISK_MEDIUM}
	return {"requires_approval": default_mode != "auto", "risk": RISK_LOW}


func build_checkpoint(action: String, summary: String) -> Dictionary:
	var classification := classify_action(action)
	return {
		"action": action,
		"summary": summary,
		"risk": classification.get("risk", RISK_LOW),
		"requires_approval": classification.get("requires_approval", true),
		"created_at": Time.get_datetime_string_from_system(),
	}
