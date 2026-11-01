extends "res://addons/_lib/editor_node_ref/src/editor_node_ref_versions/get_ed_node_ref_base.gd"

func get_bottom_panel() -> Control:
	return get_node_from_dict("EditorBottomPanel")

func get_editor_log():
	return get_node_from_dict("EditorLog")

## The hidden plain Control that EditorDockManager parks closed docks in.
func get_closed_docks_node():
	for c in EditorInterface.get_base_control().get_children():
		if c.get_class() == "Control" and not c.visible:
			return c


## No longer a valid thing, this is a tab bar now. Returns the editor version area now.
func get_bottom_panel_buttons():
	var bp = get_bottom_panel()
	return bp.get_child(0).get_child(1, true)
