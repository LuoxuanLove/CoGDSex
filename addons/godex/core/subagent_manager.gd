@tool
class_name GodexSubagentManager
extends RefCounted

var agents: Array[Dictionary] = []


func create_agent(name: String, role: String, branch_name: String, readonly: bool = true, prompt: String = "", model: String = "", reasoning_effort: String = "") -> Dictionary:
	var item := {
		"id": _new_agent_id(),
		"name": name,
		"role": role,
		"branch": branch_name,
		"readonly": readonly,
		"status": "queued",
		"prompt": prompt,
		"model": model,
		"reasoning_effort": reasoning_effort,
		"summary": "",
		"result": "",
		"error": "",
		"created_at": Time.get_datetime_string_from_system(),
		"updated_at": Time.get_datetime_string_from_system(),
		"started_at": "",
		"finished_at": "",
	}
	agents.append(item)
	return item


func mark_running(agent_id: String) -> void:
	_set_status(agent_id, "running")


func mark_done(agent_id: String) -> void:
	_set_status(agent_id, "done")


func mark_failed(agent_id: String, error: String = "") -> void:
	_set_status(agent_id, "failed", {"error": error})


func cancel(agent_id: String, source: String = "automation") -> void:
	_set_status(agent_id, "cancelled", {"cancelled_by": source, "cancelled_at": Time.get_datetime_string_from_system()})


func handoff(agent_id: String, summary: String = "", source: String = "automation") -> void:
	_set_status(agent_id, str(_find_agent(agent_id).get("status", "done")), {
		"handoff_status": "handed_off",
		"handoff_summary": summary,
		"handoff_source": source,
		"handoff_at": Time.get_datetime_string_from_system(),
	})


func list_agents() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for agent in agents:
		copy.append(agent.duplicate(true))
	return copy


func _set_status(agent_id: String, status: String, patch: Dictionary = {}) -> void:
	for agent in agents:
		if str(agent.get("id", "")) == agent_id:
			agent["status"] = status
			for key in patch.keys():
				agent[str(key)] = patch[key]
			agent["updated_at"] = Time.get_datetime_string_from_system()
			if status == "running" and str(agent.get("started_at", "")).is_empty():
				agent["started_at"] = str(agent.get("updated_at", ""))
			if status in ["done", "failed", "cancelled"] and str(agent.get("finished_at", "")).is_empty():
				agent["finished_at"] = str(agent.get("updated_at", ""))
			return


func _find_agent(agent_id: String) -> Dictionary:
	for agent in agents:
		if str(agent.get("id", "")) == agent_id:
			return agent
	return {}


func _new_agent_id() -> String:
	var base := "agent_%d" % Time.get_ticks_msec()
	var candidate := base
	var suffix := 2
	while not _find_agent(candidate).is_empty():
		candidate = "%s_%d" % [base, suffix]
		suffix += 1
	return candidate
