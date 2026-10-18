@tool
extends EditorPlugin
## Adds a "Copy All" button to the toolbar of the debugger's Errors tab. It copies every error and
## warning in the tab, with its source and stack frames, to the clipboard as plain text.
##
## Godot has no API for the Errors tab, so the plugin finds it in the editor's UI by its layout:
## in each debugger session, the Errors tab is a [VBoxContainer] page of a [TabContainer] whose
## first child is the toolbar row ([HBoxContainer]: Expand All, Collapse All, Clear) and which holds
## the two-column error [Tree]. It doesn't rely on the tab's name, which is translated and gets an
## error count appended. If the layout isn't found, the plugin warns once and does nothing.

const ErrorText := preload("error_text.gd")

const BUTTON_NAME := &"CopyAllErrors"
const BUTTON_TEXT := "Copy All"
const BUTTON_TOOLTIP := "Copy every error and warning in this tab, with sources and stack traces, to the clipboard."
const LOG_PREFIX := "Copy Errors: "
## The editor's error tree has a time column and a message column.
const ERROR_TREE_COLUMNS := 2

var _buttons: Array[Button] = []


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)
	if _add_buttons() == 0:
		push_warning(LOG_PREFIX + "couldn't find the debugger's Errors tab in this editor version, "
				+ "so no Copy All button was added.")


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


## Adds a button to every Errors tab that lacks one. Returns the number of Errors tabs found.
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
		if toolbar.has_node(NodePath(BUTTON_NAME)):
			continue
		var button := Button.new()
		button.name = BUTTON_NAME
		button.text = BUTTON_TEXT
		button.tooltip_text = BUTTON_TOOLTIP
		button.pressed.connect(_copy.bind(_error_tree_in(tab)))
		toolbar.add_child(button)
		_buttons.append(button)
	return tabs.size()


func _copy(tree: Tree) -> void:
	if not is_instance_valid(tree):
		return
	var root := tree.get_root()
	var text := ErrorText.from_tree(root, tree.columns)
	if text.is_empty():
		print(LOG_PREFIX + "the Errors tab is empty, nothing was copied.")
		return
	DisplayServer.clipboard_set(text)
	print(LOG_PREFIX + "copied %d error(s) and warning(s) to the clipboard." % root.get_child_count())


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
