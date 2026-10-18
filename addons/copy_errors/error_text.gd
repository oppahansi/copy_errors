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

## Which top-level items to copy. Items the editor marks as neither are copied only with [constant ALL].
enum Filter { ALL, ERRORS, WARNINGS }


## Returns the text of every item under [param root] (the tree's hidden root) that [param filter]
## keeps, in tree order. Reads [param columns] cells per item. Returns an empty string if
## [param root] is null or nothing is kept.
static func from_tree(root: TreeItem, columns: int, filter := Filter.ALL) -> String:
	var lines := PackedStringArray()
	for item in _kept(root, filter):
		_append(item, columns, 0, lines)
	return "\n".join(lines)


## How many top-level items under [param root] [param filter] keeps.
static func count(root: TreeItem, filter := Filter.ALL) -> int:
	return _kept(root, filter).size()


static func _kept(root: TreeItem, filter: Filter) -> Array[TreeItem]:
	var kept: Array[TreeItem] = []
	var item := root.get_first_child() if root else null
	while item:
		if filter == Filter.ALL \
				or filter == Filter.ERRORS and item.has_meta(ERROR_META) \
				or filter == Filter.WARNINGS and item.has_meta(WARNING_META):
			kept.append(item)
		item = item.get_next()
	return kept


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
