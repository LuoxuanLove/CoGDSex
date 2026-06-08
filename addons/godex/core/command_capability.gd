@tool
class_name GodexCommandCapability
extends RefCounted

var enabled := false
var shell := "PowerShell"
var working_directory := ""
var timeout_sec := 30
var allowed_shells: Array[String] = ["PowerShell", "pwsh", "cmd"]
var trusted_prefixes: Array[String] = []
var blocked_patterns: Array[String] = [
	"Remove-Item -Recurse",
	"Remove-Item -Force",
	"rm -rf",
	"rmdir /s",
	"del /f",
	"git reset --hard",
	"git clean -fd",
	"format",
	"shutdown",
	"-encodedcommand",
	"encodedcommand",
	"invoke-expression",
	"iex ",
	"cmd /c",
	"powershell -command",
	"pwsh -command",
	"curl ",
	"wget ",
	"irm ",
	"iwr ",
	"|",
	">",
	"<",
]


func build_request(command: String) -> Dictionary:
	var normalized_shell := normalize_shell(shell)
	var command_blocked := _is_blocked(command)
	var cwd_blocked := is_working_directory_blocked(working_directory)
	var shell_blocked := normalized_shell.is_empty()
	var normalized_timeout := normalize_timeout(timeout_sec)
	return {
		"enabled": enabled,
		"shell": normalized_shell if not normalized_shell.is_empty() else shell,
		"working_directory": working_directory,
		"timeout_sec": normalized_timeout,
		"command": command,
		"requires_approval": true,
		"blocked": command_blocked or cwd_blocked or shell_blocked,
		"blocked_reason": _blocked_reason(command_blocked, cwd_blocked, shell_blocked),
	}


func normalize_shell(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	match normalized:
		"powershell", "windows powershell":
			return "PowerShell"
		"pwsh", "powershell 7", "powershell core":
			return "pwsh"
		"cmd", "cmd.exe":
			return "cmd"
		_:
			return ""


func is_working_directory_blocked(value: String) -> bool:
	var normalized := value.strip_edges()
	if normalized.is_empty() or normalized == "res://" or normalized.begins_with("res://"):
		return false
	var lower := normalized.to_lower()
	if lower.contains("..") or lower.begins_with("\\\\") or lower.begins_with("//"):
		return true
	if lower.begins_with("c:\\windows") or lower.begins_with("c:/windows"):
		return true
	if lower.begins_with("c:\\users") or lower.begins_with("c:/users"):
		return true
	return true


func normalize_timeout(value: int) -> int:
	return clampi(value, 1, 300)


func _is_blocked(command: String) -> bool:
	var normalized := command.to_lower()
	for pattern in blocked_patterns:
		if normalized.contains(pattern.to_lower()):
			return true
	return false


func _blocked_reason(command_blocked: bool, cwd_blocked: bool, shell_blocked: bool) -> String:
	if shell_blocked:
		return "unsupported_shell"
	if cwd_blocked:
		return "unsafe_working_directory"
	if command_blocked:
		return "blocked_command"
	return ""
