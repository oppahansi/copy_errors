extends "res://tests/test_case.gd"
## The text the Copy All button puts on the clipboard.

const ErrorText := preload("res://addons/copy_errors/error_text.gd")


func test_items_and_their_details_in_order() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	var warning := _item(tree, root, "0:00:01:250", "The variable \"range\" has the same name as a built-in function.")
	warning.set_meta(ErrorText.WARNING_META, true)
	_item(tree, warning, "<GDScript Source>", "game_data.gd:111")
	var error := _item(tree, root, "0:00:02:000", "_ready: Invalid access to property 'x'.")
	error.set_meta(ErrorText.ERROR_META, true)
	_item(tree, error, "<GDScript Source>", "main.gd:7 @ _ready()")
	_item(tree, error, "<Stack Trace>", "main.gd:7 @ _ready()")
	_item(tree, error, "", "level.gd:21 @ start()")
	assert_eq(ErrorText.from_tree(root, tree.columns), "\n".join([
		"W 0:00:01:250 The variable \"range\" has the same name as a built-in function.",
		"  <GDScript Source> game_data.gd:111",
		"E 0:00:02:000 _ready: Invalid access to property 'x'.",
		"  <GDScript Source> main.gd:7 @ _ready()",
		"  <Stack Trace> main.gd:7 @ _ready()",
		"  level.gd:21 @ start()",
	]))
	tree.free()


func test_item_without_kind_has_no_marker() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	_item(tree, root, "0:00:01:000", "Something happened.")
	assert_eq(ErrorText.from_tree(root, tree.columns), "0:00:01:000 Something happened.")
	tree.free()


func test_empty_cells_and_items_are_skipped() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	var error := _item(tree, root, "  ", "")
	error.set_meta(ErrorText.ERROR_META, true)
	_item(tree, error, "", "  only the second cell  ")
	assert_eq(ErrorText.from_tree(root, tree.columns), "  only the second cell")
	tree.free()


func test_reads_only_the_given_columns() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	_item(tree, root, "first", "second")
	assert_eq(ErrorText.from_tree(root, 1), "first")
	tree.free()


func test_deeper_levels_are_indented_further() -> void:
	var tree := Tree.new()
	tree.columns = 1
	var root := tree.create_item()
	var top := tree.create_item(root)
	top.set_text(0, "top")
	var child := tree.create_item(top)
	child.set_text(0, "child")
	var grandchild := tree.create_item(child)
	grandchild.set_text(0, "grandchild")
	grandchild.set_meta(ErrorText.ERROR_META, true)
	assert_eq(ErrorText.from_tree(root, 1), "top\n  child\n    grandchild")
	tree.free()


func test_empty_tree() -> void:
	var tree := Tree.new()
	tree.columns = 2
	assert_eq(ErrorText.from_tree(tree.create_item(), 2), "")
	assert_eq(ErrorText.from_tree(null, 2), "")
	tree.free()


func _item(tree: Tree, parent: TreeItem, first: String, second: String) -> TreeItem:
	var item := tree.create_item(parent)
	item.set_text(0, first)
	item.set_text(1, second)
	return item


func test_filters_keep_only_errors_or_only_warnings() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	var warning := _item(tree, root, "0:00:01:000", "Unused variable.")
	warning.set_meta(ErrorText.WARNING_META, true)
	_item(tree, warning, "<GDScript Source>", "a.gd:3")
	var error := _item(tree, root, "0:00:02:000", "Invalid call.")
	error.set_meta(ErrorText.ERROR_META, true)
	_item(tree, error, "<Stack Trace>", "b.gd:9 @ run()")
	_item(tree, root, "0:00:03:000", "Unmarked.")
	assert_eq(ErrorText.from_tree(root, tree.columns, ErrorText.Filter.ERRORS),
			"E 0:00:02:000 Invalid call.\n  <Stack Trace> b.gd:9 @ run()")
	assert_eq(ErrorText.from_tree(root, tree.columns, ErrorText.Filter.WARNINGS),
			"W 0:00:01:000 Unused variable.\n  <GDScript Source> a.gd:3")
	assert_eq(ErrorText.count(root, ErrorText.Filter.ERRORS), 1)
	assert_eq(ErrorText.count(root, ErrorText.Filter.WARNINGS), 1)
	assert_eq(ErrorText.count(root), 3, "an unmarked item is copied only with all")
	tree.free()


func test_a_filter_with_nothing_to_keep_gives_empty_text() -> void:
	var tree := Tree.new()
	tree.columns = 2
	var root := tree.create_item()
	_item(tree, root, "0:00:01:000", "An error.").set_meta(ErrorText.ERROR_META, true)
	assert_eq(ErrorText.from_tree(root, tree.columns, ErrorText.Filter.WARNINGS), "")
	assert_eq(ErrorText.count(null, ErrorText.Filter.ERRORS), 0)
	tree.free()
