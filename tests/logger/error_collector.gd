extends Logger
## Collects engine and script errors so that a test that crashes can't pass silently.
## Needs Godot 4.5 or later: the runner loads it only where [code]Logger[/code] exists, and its
## folder has a [code].gdignore[/code] so that older editors don't parse it.

var errors := PackedStringArray()


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	errors.append("%s (%s:%d in %s)" % [rationale if rationale else code, file, line, function])


func _log_message(_message: String, _error: bool) -> void:
	pass
