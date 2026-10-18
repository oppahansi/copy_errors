extends RefCounted
## Turns the debugger's error tree into plain text.
##
## Each error or warning becomes one line, prefixed with [code]E[/code] or [code]W[/code] like the
## editor's own "Copy Error" menu entry. Its details (the source, the C++ or script error, the stack
## frames) follow on the lines below it, indented by two spaces per level. Empty cells are skipped.

## Metadata the editor sets on a top-level item that is a warning.
const WARNING_META := &"_is_warning"
## Metadata the editor sets on a top-level item that is an error.
const ERROR_META := &"_is_error"
const INDENT := "  "


## Returns the text of every item under [param root] (the tree's hidden root), in tree order.
## Reads [param columns] cells per item. Returns an empty string if [param root] is null or empty.
static func from_tree(root: TreeItem, columns: int) -> String:
	var lines := PackedStringArray()
	var item := root.get_first_child() if root else null
	while item:
		_append(item, columns, 0, lines)
		item = item.get_next()
	return "\n".join(lines)


static func _append(item: TreeItem, columns: int, depth: int, lines: PackedStringArray) -> void:
	var cells := PackedStringArray()
	for column in range(columns):
		var text := item.get_text(column).strip_edges()
		if not text.is_empty():
			cells.append(text)
	if not cells.is_empty():
		var kind := _kind(item) if depth == 0 else ""
		if not kind.is_empty():
			cells.insert(0, kind)
		lines.append(INDENT.repeat(depth) + " ".join(cells))
	var child := item.get_first_child()
	while child:
		_append(child, columns, depth + 1, lines)
		child = child.get_next()


## [code]"W"[/code] for a warning, [code]"E"[/code] for an error, empty if the item has neither mark.
static func _kind(item: TreeItem) -> String:
	if item.has_meta(WARNING_META):
		return "W"
	if item.has_meta(ERROR_META):
		return "E"
	return ""
