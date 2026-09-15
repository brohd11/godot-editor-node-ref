
# This is the 4.4 functionality, change what must be in other versions

const UNode = preload("uid://bnf4h0107r8b4") #! resolve UtilR.URNode

var node_types_dict = {}
##
func get_all_nodes_of_types(types:Array) -> Dictionary: # possibly pass 2 arrays, single instance will be removed when found
	var root = Engine.get_main_loop().root # vs something like TabContainer
	var dict = {}
	for type in types:
		dict[type] = []
	var nodes = _get_all_nodes_of_types_recursive(root, types, dict)
	node_types_dict = nodes
	return nodes
#private
func _get_all_nodes_of_types_recursive(node:Node, type_array:Array, node_dict:Dictionary) -> Dictionary:
	for n in node.get_children(true):
		var type = n.get_class()
		if type in type_array:
			node_dict[type].append(n)
		_get_all_nodes_of_types_recursive(n, type_array, node_dict)
	return node_dict

func get_node_from_dict(node_class:String, idx:=0):
	var ref = node_types_dict.get(node_class)
	if ref is Array and idx > -1:
		return ref[idx]
	return ref




##
func get_script_editor_code_popup(): # Dynamic
	var current = EditorInterface.get_script_editor().get_current_editor()
	if current == null:
		return null
	for c in current.get_children():
		if c is PopupMenu:
			return c
	
	var code_edit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var script_tab_dummy = code_edit.get_parent().get_parent().get_parent()
	if script_tab_dummy.get_script() != null: # maybe give it a path
		for c in script_tab_dummy.find_children("*", "PopupMenu", true, false):
			if c is PopupMenu:
				return c
	
	if current.get_child_count() > 1 and current.get_child(1) is PopupMenu:
		return current.get_child(1)
	
	printerr("EditorNodeRef-Could not get ScriptEditor code popup.")
	return null
##
func get_script_editor_popup(): # Dynamic
	return EditorInterface.get_script_editor().get_child(1)
##
func get_script_editor_menu_bar(): # Dynamic
	var menu_bars_hbox = EditorInterface.get_script_editor().get_child(0).get_child(0)
	var menu_hboxes = menu_bars_hbox.get_children()
	var menu_hbox:HBoxContainer
	for child in menu_hboxes:
		if child.visible and child is HBoxContainer:
			menu_hbox = child
			break
	if not is_instance_valid(menu_hbox):
		#print("Could not get current script editor menu bar.")
		pass
	return menu_hbox
##
func get_script_editor_syntax_popup(): # Dynamic
	var menu_hbox:HBoxContainer = get_script_editor_menu_bar()
	if not is_instance_valid(menu_hbox):
		return
	var menu_popup:PopupMenu
	var menu_buttons = menu_hbox.get_children()
	for button:MenuButton in menu_buttons:
		if button.text == "Edit":
			menu_popup = button.get_popup()
			break
	if not is_instance_valid(menu_popup):
		#print("Could not find edit menu popup.")
		return
	var syntax_popup = menu_popup.get_child(menu_popup.get_child_count() - 1)
	return syntax_popup

##
func get_script_editor_h_split():
	var script_editor = EditorInterface.get_script_editor()
	var h_split = script_editor.get_child(0).get_child(1)
	return h_split

##
func get_script_editor_sidebar_v_split():
	var script_editor = EditorInterface.get_script_editor()
	var h_split = script_editor.get_child(0).get_child(1)
	var v_split = h_split.get_child(0)
	return v_split

##
func get_script_editor_tab_container():
	var script_editor = EditorInterface.get_script_editor()
	var h_split = script_editor.get_child(0).get_child(1)
	var tab = h_split.get_child(1).get_child(0)
	return tab


##
func get_file_system_popup():
	var fs_popup = EditorInterface.get_file_system_dock().get_child(2)
	node_types_dict["FileSystemPopup"] = fs_popup
	return fs_popup
# private
func _get_file_system_popup():
	return get_node_from_dict("FileSystemPopup")
##
func get_file_system_create_popup():
	var fs_popup = _get_file_system_popup()
	if fs_popup.get_child_count() > 0:
		var popup = fs_popup.get_child(0)
		return popup

func get_file_system_folder_color_popup():
	var fs_popup = _get_file_system_popup()
	if fs_popup.get_child_count() > 1:
		var popup = fs_popup.get_child(1)
		return popup

#private func
func _populate_filesystem_popup():
	var fs_popup = _get_file_system_popup()
	var tree = get_file_system_tree() as Tree
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	fs_popup.hide()
##
func get_file_system_tree():
	var nodes = EditorInterface.get_file_system_dock().get_child(3).find_children("*", "Tree", true, false)
	return nodes[0] # this has a check in the original if popup menu has moved

##
func get_file_system_bottom_popup():
	var fs_popup = EditorInterface.get_file_system_dock().get_child(1)
	node_types_dict["FileSystemBottomPopup"] = fs_popup
	return fs_popup
# private
func _get_file_system_bottom_popup():
	return get_node_from_dict("FileSystemBottomPopup")
##
func get_file_system_bottom_folder_color_popup():
	var fs_popup = _get_file_system_bottom_popup()
	if fs_popup.get_child_count() > 1:
		var popup = fs_popup.get_child(1)
		return popup

func get_file_system_bottom_create_popup():
	var fs_popup = _get_file_system_bottom_popup()
	if fs_popup.get_child_count() > 0:
		var popup = fs_popup.get_child(0)
		return popup
#private func
func _populate_filesystem_bottom_popup():
	var fs_popup = _get_file_system_bottom_popup()
	var tree = get_file_system_tree() as Tree
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	fs_popup.hide()
##



##
func get_scene_tabs_popup():
	var scene_tabs = get_scene_tabs()
	var popup = scene_tabs.get_child(0).get_child(0).get_child(1)
	return popup
##
func get_scene_tree_popup():
	return get_node_from_dict("SceneTreeDock").get_child(15)
##
func get_scene_tabs():
	return get_node_from_dict("EditorSceneTabs")
##
func get_scene_tree_dock():
	return get_node_from_dict("SceneTreeDock")
##





func get_docks():
	var tab_containers = node_types_dict.get("TabContainer", [])
	var docks = []
	for tab in tab_containers:
		if tab.name.begins_with("DockSlot"):
			docks.append(tab)
	return docks
##

func get_editor_dock(class_or_name:String):
	var editor_docks = node_types_dict.get(&"EditorDock", [])
	for node in editor_docks:
		if node.get_class() == class_or_name or node.name == class_or_name:
			return node




##
func get_title_bar():
	return EditorInterface.get_base_control().get_child(0).get_child(0)
##
func get_title_buttons():
	var system = OS.get_name()
	if system == "macOS":
		return get_title_bar().get_child(3)
	else:
		return get_title_bar().get_child(2)
##



##
func get_bottom_panel() -> Control:
	return get_node_from_dict("EditorBottomPanel").get_child(0)
##
func get_bottom_panel_buttons():
	var bp = get_bottom_panel()
	var bp_children = bp.get_children()
	bp_children.reverse()
	var hbox = null
	for control in bp_children:
		var nested_children = control.get_children()
		for nc in nested_children:
			if nc.get_class() == "EditorToaster":
				hbox = control
				break
		if is_instance_valid(hbox):
			break
	var buttons_hbox = hbox.get_child(1).get_child(0, true)
	return buttons_hbox
##
func _bottom_panel_get_panel(_class_name):
	var bottom_panel = get_bottom_panel()
	for p in bottom_panel.get_children():
		if p.get_class() == _class_name:
			return p
	push_error("Could not find %s" % _class_name)

##
func get_editor_log():
	return get_node_from_dict("EditorLog")
##
func get_editor_log_filter_line_edit():
	var editor_log = get_editor_log()
	var vbox = editor_log.get_child(1)
	for n in vbox.get_children():
		if n is LineEdit:
			return n
##
func get_editor_log_button_container():
	return get_editor_log().get_child(2)

func get_editor_log_rich_text_label():
	var editor_log = get_editor_log()
	var text_box = editor_log.get_child(1).get_child(0)
	return text_box

##
func get_title_menu_bar():
	var title_bar = get_title_bar()
	for c in title_bar.get_children():
		if c.get_class() == "MenuBar":
			return c




func get_2d_editor_popup():
	var main_screen = EditorInterface.get_editor_main_screen()
	var canvas_item_editor
	for c in main_screen.get_children():
		if c.get_class() == "CanvasItemEditor":
			canvas_item_editor = c
			break
	var popup = canvas_item_editor.get_child(canvas_item_editor.get_child_count() - 1)
	return popup
