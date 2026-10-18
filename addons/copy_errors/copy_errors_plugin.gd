@tool
extends EditorPlugin
## Adds "Copy Errors", "Copy Warnings" and "Copy All" buttons to the toolbar of the debugger's Errors
## tab. They copy the tab's errors, its warnings, or both, each with its source and stack frames, to
## the clipboard as plain text.
##
## Godot has no API for the Errors tab, so the plugin finds it in the editor's UI by its layout:
## in each debugger session, the Errors tab is a [VBoxContainer] page of a [TabContainer] whose
## first child is the toolbar row ([HBoxContainer]: Expand All, Collapse All, Clear) and which holds
## the two-column error [Tree]. It doesn't rely on the tab's name, which is translated and gets an
## error count appended. If the layout isn't found, the plugin warns once and does nothing.

const ErrorText := preload("error_text.gd")

## The buttons, in toolbar order: node name, text, tooltip, filter and what the log calls the copied items.
const BUTTONS: Array[Dictionary] = [
	{"name": &"CopyErrorsOnly", "text": "Copy Errors", "filter": ErrorText.Filter.ERRORS, "items": "error(s)",
		"tooltip": "Copy the errors in this tab, with sources and stack traces, to the clipboard."},
	{"name": &"CopyWarningsOnly", "text": "Copy Warnings", "filter": ErrorText.Filter.WARNINGS, "items": "warning(s)",
		"tooltip": "Copy the warnings in this tab, with sources and stack traces, to the clipboard."},
	{"name": &"CopyAllErrors", "text": "Copy All", "filter": ErrorText.Filter.ALL, "items": "error(s) and warning(s)",
		"tooltip": "Copy every error and warning in this tab, with sources and stack traces, to the clipboard."},
]
const LOG_PREFIX := "Copy Errors: "
## The editor's error tree has a time column and a message column.
const ERROR_TREE_COLUMNS := 2

var _buttons: Array[Button] = []


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)
	if _add_buttons() == 0:
		push_warning(LOG_PREFIX + "couldn't find the debugger's Errors tab in this editor version, "
				+ "so no copy buttons were added.")


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	for button in _buttons:
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


## Debugger sessions can be added later, e.g. when running several instances at once.
func _on_node_added(node: Node) -> void:
	if node.is_class("ScriptEditorDebugger"):
		_add_buttons.call_deferred()


## Adds the buttons to every Errors tab that lacks them. Returns the number of Errors tabs found.
func _add_buttons() -> int:
	# Forget the buttons of debugger sessions that were removed.
	var alive: Array[Button] = []
	for button in _buttons:
		if is_instance_valid(button):
			alive.append(button)
	_buttons = alive
	var tabs := _find_error_tabs()
	for tab in tabs:
		var toolbar := tab.get_child(0) as HBoxContainer
		for spec in BUTTONS:
			if toolbar.has_node(NodePath(spec["name"])):
				continue
			var button := Button.new()
			button.name = spec["name"]
			button.text = spec["text"]
			button.tooltip_text = spec["tooltip"]
			button.pressed.connect(_copy.bind(_error_tree_in(tab), spec))
			toolbar.add_child(button)
			_buttons.append(button)
	return tabs.size()


func _copy(tree: Tree, spec: Dictionary) -> void:
	if not is_instance_valid(tree):
		return
	var root := tree.get_root()
	var filter: ErrorText.Filter = spec["filter"]
	var text := ErrorText.from_tree(root, tree.columns, filter)
	if text.is_empty():
		print(LOG_PREFIX + "no %s in the Errors tab, nothing was copied." % spec["items"])
		return
	DisplayServer.clipboard_set(text)
	print(LOG_PREFIX + "copied %d %s to the clipboard." % [ErrorText.count(root, filter), spec["items"]])


func _find_error_tabs() -> Array[VBoxContainer]:
	var tabs: Array[VBoxContainer] = []
	var base := EditorInterface.get_base_control()
	for debugger in base.find_children("*", "ScriptEditorDebugger", true, false):
		for container in debugger.find_children("*", "TabContainer", true, false):
			for page in container.get_children():
				if _is_error_tab(page):
					tabs.append(page as VBoxContainer)
	return tabs


static func _is_error_tab(node: Node) -> bool:
	return node is VBoxContainer and node.get_child_count() > 1 \
			and node.get_child(0) is HBoxContainer and _error_tree_in(node) != null


static func _error_tree_in(tab: Node) -> Tree:
	for child in tab.get_children():
		if child is Tree and (child as Tree).columns == ERROR_TREE_COLUMNS:
			return child as Tree
	return null
