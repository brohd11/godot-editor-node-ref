
const PopupID = preload("res://addons/addon_lib/editor_node_ref/src/nodes/filesystem/popup_id.gd")
const UTree = preload("uid://1gwputufojp6") #! resolve UtilR.Nodes.Trees.UTree

static func get_tree():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)

static func get_tree_line_edit():
	var tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	return UTree.get_line_edit(tree)

static func populate_popup(calling_node:Node):
	var popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)
	if calling_node.get_window() != popup.get_window():
		popup.reparent(calling_node.get_window().get_child(0))
	var tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	popup.hide()
	popup.reparent(EditorInterface.get_file_system_dock())

static func populate_bottom_popup(calling_node:Control):
	var popup = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_BOTTOM_POPUP)
	if calling_node.get_window() != popup.get_window():
		popup.reparent(calling_node.get_window().get_child(0))
	var tree = EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_TREE)
	
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	popup.hide()
	popup.reparent(EditorInterface.get_file_system_dock())

static func get_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_POPUP)

static func get_create_popup():
	return EditorNodeRef.get_registered(EditorNodeRef.Nodes.FILESYSTEM_CREATE_POPUP)
