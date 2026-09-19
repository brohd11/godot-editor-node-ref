extends "res://addons/addon_lib/editor_node_ref/src/editor_node_ref_versions/get_ed_node_ref_base.gd"

func get_scene_tree_popup():
	var scene_tree_dock = get_node_from_dict("SceneTreeDock")
	for c:Node in scene_tree_dock.get_children():
		if not c is PopupMenu:
			continue
		var sig_callable = UNode.get_signal_callable(c, "id_pressed", "SceneTreeDock::_tool_selected")
		if sig_callable != null:
			return c

func get_file_system_tree():
	var nodes = EditorInterface.get_file_system_dock().get_child(0).find_children("*", "Tree", true, false)
	return nodes[0] # this has a check in the original if popup menu has moved

func get_bottom_panel() -> Control:
	return get_node_from_dict("EditorBottomPanel")

func get_editor_log():
	return get_node_from_dict("EditorLog")
##
func get_editor_log_filter_line_edit():
	var editor_log = get_editor_log()
	var vbox = editor_log.get_child(1, true).get_child(0)
	var line = vbox.find_children("*", "LineEdit", true, false)
	return line[0]
	#for n in vbox.get_children():
		#if n is LineEdit:
			#return n

func get_editor_log_button_container():
	return get_editor_log().get_child(1).get_child(1)

func get_editor_log_rich_text_label():
	var editor_log = get_editor_log()
	var text_box = editor_log.get_child(1).get_child(0).get_child(0)
	return text_box


func get_closed_docks_node():
	return EditorInterface.get_base_control().get_child(1)


## No longer a valid thing, this is a tab bar now. Returns the editor version area now.
func get_bottom_panel_buttons():
	var bp = get_bottom_panel()
	return bp.get_child(0).get_child(1, true)
