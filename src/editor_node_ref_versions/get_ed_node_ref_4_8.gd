extends "res://addons/_lib/editor_node_ref/src/editor_node_ref_versions/get_ed_node_ref_4_7.gd"

# 4.8 moved the script editor's internals into a DocumentEditorContainer, a level deeper.

## Main screens are dock tabs now; there is no button bar.
func get_title_buttons():
	return null

func get_script_editor_popup(): # Dynamic
	return find_by_signal(EditorInterface.get_script_editor(), "PopupMenu", "id_pressed", "DocumentEditorContainer::_menu_option", true)

func get_script_editor_tab_container():
	return find_by_signal(EditorInterface.get_script_editor(), "TabContainer", "tab_changed", "DocumentEditorContainer::ensure_select_current", true)

func get_script_editor_menu_bar(): # Dynamic
	var files_button = find_by_signal(EditorInterface.get_script_editor(), "Button", "toggled", "DocumentEditorContainer::_toggle_files_pressed", true)
	return files_button.get_parent() if files_button != null else null

func get_script_editor_syntax_popup(): # Dynamic
	var syntax_popup = find_by_signal(get_script_editor_menu_bar(), "PopupMenu", "id_pressed", "::_change_syntax_highlighter", true)
	if syntax_popup == null:
		return
	if syntax_popup.item_count == 0:
		# Built on first show, as in 4.7.
		var menu_popup = syntax_popup.get_parent()
		menu_popup.show()
		syntax_popup.show()
		syntax_popup.about_to_popup.emit()
		menu_popup.hide.call_deferred()
	return syntax_popup
