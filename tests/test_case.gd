extends RefCounted
## Base class of a test script: every method whose name starts with [code]test_[/code] is a test.

## Messages of the assertions that failed in the current test.
var failures := PackedStringArray()


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		_fail("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		_fail("expected true", message)


func _fail(reason: String, message: String) -> void:
	failures.append(reason if message.is_empty() else "%s: %s" % [message, reason])
