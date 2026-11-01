
# This is the 4.4 functionality, change what must be in other versions

const UNode = preload("uid://bnf4h0107r8b4") #! resolve UtilR.UNode
const CheckInstance = preload("uid://cnx1roduh82r") #! resolve Singletons.CheckInstance

var node_types_dict = {}

## First `cls` under `parent` with `signal_name` connected to `method`: identifies a node by what
## the editor wired it to, which survives index shifts. A method starting with "::" matches by
## suffix, since handlers move between classes (ScriptTextEditor -> TextEditorBase in 4.7).
func find_by_signal(parent:Node, cls:String, signal_name:String, method:String, recursive:=false) -> Node:
	if not is_instance_valid(parent):
		return null
	var nodes = parent.find_children("*", cls, true, false) if recursive else parent.get_children()
	for n:Node in nodes:
		if n.is_class(cls) and n.has_signal(signal_name) and _is_connected_to(n, signal_name, method):
			return n
	return null

func _is_connected_to(node:Node, signal_name:String, method:String) -> bool:
	if not method.begins_with("::"):
		return UNode.get_signal_callable(node, signal_name, method) != null
	for data in node.get_signal_connection_list(signal_name):
		if String((data.callable as Callable).get_method()).ends_with(method):
			return true
	return false
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
	var popup = find_by_signal(current, "PopupMenu", "id_pressed", "::_edit_option")
	if popup != null:
		return popup
	# script_tabs moves an active editor's children into its DummyEditor.
	var script_tabs = CheckInstance.get_instance("ScriptTabSingleton")
	if is_instance_valid(script_tabs) and script_tabs.has_method("get_dummy_editor_from_editor"):
		popup = find_by_signal(script_tabs.get_dummy_editor_from_editor(current), "PopupMenu", "id_pressed", "::_edit_option")
		if popup != null:
			return popup

	printerr("EditorNodeRef-Could not get ScriptEditor code popup.")
	return null
##
func get_script_editor_popup(): # Dynamic
	return find_by_signal(EditorInterface.get_script_editor(), "PopupMenu", "id_pressed", "ScriptEditor::_menu_option")
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
	return find_by_signal(EditorInterface.get_script_editor(), "HSplitContainer", "dragged", "::_split_dragged", true)

##
func get_script_editor_sidebar_v_split():
	return find_by_signal(EditorInterface.get_script_editor(), "VSplitContainer", "dragged", "::_split_dragged", true)

##
func get_script_editor_tab_container():
	return find_by_signal(EditorInterface.get_script_editor(), "TabContainer", "tab_changed", "ScriptEditor::_tab_changed", true)


##
func get_file_system_popup():
	var fs_popup = find_by_signal(EditorInterface.get_file_system_dock(), "PopupMenu", "id_pressed", "FileSystemDock::_tree_rmb_option")
	node_types_dict["FileSystemPopup"] = fs_popup
	return fs_popup
# private
func _get_file_system_popup():
	return get_node_from_dict("FileSystemPopup")
##
func get_file_system_create_popup():
	return find_by_signal(_get_file_system_popup(), "PopupMenu", "id_pressed", "FileSystemDock::_generic_rmb_option_selected")

## Only exists once a folder has been right-clicked.
func get_file_system_folder_color_popup():
	return find_by_signal(_get_file_system_popup(), "PopupMenu", "id_pressed", "FileSystemDock::_folder_color_index_pressed")

#private func
func _populate_filesystem_popup():
	var fs_popup = _get_file_system_popup()
	var tree = get_file_system_tree() as Tree
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	fs_popup.hide()
##
func get_file_system_tree():
	return find_by_signal(EditorInterface.get_file_system_dock(), "Tree", "item_mouse_selected", "FileSystemDock::_tree_rmb_select", true)

##
func get_file_system_bottom_popup():
	var fs_popup = find_by_signal(EditorInterface.get_file_system_dock(), "PopupMenu", "id_pressed", "FileSystemDock::_file_list_rmb_option")
	node_types_dict["FileSystemBottomPopup"] = fs_popup
	return fs_popup
# private
func _get_file_system_bottom_popup():
	return get_node_from_dict("FileSystemBottomPopup")
##
func get_file_system_bottom_folder_color_popup():
	return find_by_signal(_get_file_system_bottom_popup(), "PopupMenu", "id_pressed", "FileSystemDock::_folder_color_index_pressed")

func get_file_system_bottom_create_popup():
	return find_by_signal(_get_file_system_bottom_popup(), "PopupMenu", "id_pressed", "FileSystemDock::_generic_rmb_option_selected")
#private func
func _populate_filesystem_bottom_popup():
	var fs_popup = _get_file_system_bottom_popup()
	var tree = get_file_system_tree() as Tree
	tree.item_mouse_selected.emit(Vector2.ZERO, 2)
	fs_popup.hide()
##



##
func get_scene_tabs_popup():
	return find_by_signal(get_scene_tabs(), "PopupMenu", "id_pressed", "EditorSceneTabs::_custom_menu_option", true)
##
func get_scene_tree_popup():
	return find_by_signal(get_scene_tree_dock(), "PopupMenu", "id_pressed", "SceneTreeDock::_tool_selected")
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
	return get_node_from_dict("EditorTitleBar")
## Named from 4.5. Before that, find it by its buttons, which are named after their plugins; the
## index differs between platforms (windowed macOS has an extra leading spacer).
func get_title_buttons():
	var title_bar = get_title_bar()
	var bar = title_bar.get_node_or_null("EditorMainScreenButtons")
	if bar != null:
		return bar
	for c in title_bar.get_children():
		for plugin_name in ["2D", "3D", "Script"]:
			if c.get_node_or_null(plugin_name) != null:
				return c
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
	return find_by_signal(get_editor_log(), "LineEdit", "text_changed", "EditorLog::_search_changed", true)
## The container holding the message filter toggles.
func get_editor_log_button_container():
	var filter_button = find_by_signal(get_editor_log(), "Button", "toggled", "EditorLog::_set_filter_active", true)
	return filter_button.get_parent() if filter_button != null else null

func get_editor_log_rich_text_label():
	return find_by_signal(get_editor_log(), "RichTextLabel", "meta_clicked", "EditorLog::_meta_clicked", true)

##
func get_title_menu_bar():
	var title_bar = get_title_bar()
	for c in title_bar.get_children():
		if c.get_class() == "MenuBar":
			return c




## Found by type: from 4.8 the 2D editor is a dock, not a child of the main screen.
func get_2d_editor_popup():
	return find_by_signal(get_node_from_dict("CanvasItemEditor"), "PopupMenu", "id_pressed", "CanvasItemEditor::_add_node_pressed")
