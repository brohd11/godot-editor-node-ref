
const BottomPanel = preload("res://addons/addon_lib/editor_node_ref/src/nodes/bottom_panel.gd")
const Docks = preload("res://addons/addon_lib/editor_node_ref/src/nodes/docks.gd")
const FileSystem = preload("res://addons/addon_lib/editor_node_ref/src/nodes/filesystem.gd")


class MainScreen:
	static func get_main_screen():
		return EditorInterface.get_editor_main_screen()

	static func get_title_bar():
		return EditorNodeRef.get_registered(EditorNodeRef.Nodes.TITLE_BAR)
		
	static func get_button_container():
		return EditorNodeRef.get_registered(EditorNodeRef.Nodes.TITLE_BUTTONS)
