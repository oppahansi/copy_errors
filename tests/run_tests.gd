extends SceneTree
## Headless test runner: godot --headless --path . --script tests/run_tests.gd
##
## Runs every [code]test_*[/code] method of every [code]tests/test_*.gd[/code] script, prints each
## failure and a summary, and exits with code 1 if anything failed. On Godot 4.5 and later, a script
## error raised while a test runs also fails it.

const TEST_DIR := "res://tests/"
const COLLECTOR_PATH := "res://tests/logger/error_collector.gd"


func _init() -> void:
	var collector: Object = _add_collector()
	var passed := 0
	var failed := 0
	for file in _test_files():
		var script := load(TEST_DIR + file) as Script
		if script == null or not script.can_instantiate():
			failed += 1
			_report(file, "<load>", PackedStringArray(["could not load the test script"]))
			continue
		var case: Object = script.new()
		for method in case.get_method_list():
			var test: String = method["name"]
			if not test.begins_with("test_"):
				continue
			var failures: PackedStringArray = case.get("failures")
			failures.clear()
			if collector:
				collector.get("errors").clear()
			case.call(test)
			var problems: PackedStringArray = case.get("failures")
			if collector:
				problems.append_array(collector.get("errors"))
			if problems.is_empty():
				passed += 1
			else:
				failed += 1
				_report(file, test, problems)
	if collector:
		OS.call("remove_logger", collector)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Returns a logger that collects script errors, or null on Godot versions without [code]Logger[/code].
func _add_collector() -> Object:
	if not ClassDB.class_exists(&"Logger"):
		return null
	var collector: Object = (load(COLLECTOR_PATH) as Script).new()
	OS.call("add_logger", collector)
	return collector


func _report(file: String, test: String, problems: PackedStringArray) -> void:
	print("FAIL %s::%s\n  %s" % [file, test, "\n  ".join(problems)])


func _test_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			files.append(file)
	files.sort()
	return files
