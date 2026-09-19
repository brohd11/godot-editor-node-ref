extends "res://addons/addon_lib/editor_node_ref/src/editor_node_ref_versions/get_ed_node_ref_4_6.gd"

func get_editor_log_button_container():
	return get_editor_log().get_child(1).get_child(0).get_child(1)

func get_script_editor_menu_bar(): # Dynamic
	var menu_bars_hbox = EditorInterface.get_script_editor().get_child(0).get_child(0)
	return menu_bars_hbox # menu bar has been redesigned
	#var menu_hboxes = menu_bars_hbox.get_children()
	#var menu_hbox:HBoxContainer
	#for child in menu_hboxes:
		#if child.visible and child is HBoxContainer:
			#menu_hbox = child
			#break
	#if not is_instance_valid(menu_hbox):
		##print("Could not get current script editor menu bar.")
		#pass
	#return menu_hbox

func get_script_editor_syntax_popup(): # Dynamic
	var menu_hbox:HBoxContainer = get_script_editor_menu_bar()
	if not is_instance_valid(menu_hbox):
		return
	var menu_popup:PopupMenu
	for control in menu_hbox.get_children():
		if control.get_class() != "EditMenusSTE":
			continue
		var menu_buttons = control.get_children()
		for button in menu_buttons:
			if button.text == "Edit":
				menu_popup = button.get_popup()
				break
	if not is_instance_valid(menu_popup):
		#print("Could not find edit menu popup.")
		return
	var syntax_popup = menu_popup.get_child(menu_popup.get_child_count() - 1)
	if syntax_popup.item_count == 0:
		menu_popup.show()
		syntax_popup.show()
		# this is the one to trigger build, others not sure if needed
		syntax_popup.about_to_popup.emit()
		menu_popup.hide.call_deferred()
	return syntax_popup

func get_docks():
	var tab_containers = node_types_dict.get("SideDockTabContainer", [])
	var docks = []
	for tab in tab_containers:
		if tab.name.begins_with("DockSlot"):
			docks.append(tab)
	return docks

func get_closed_docks_node():
	return EditorInterface.get_base_control().get_child(11) # magic number 11, will this be reliable?
