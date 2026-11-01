@tool
extends RefCounted
## Checks every EditorNodeRef.Nodes key resolves to the node it names on the running Godot. Class
## alone can't catch a shifted get_child() index, so most keys also carry an identity marker: a
## signal wired to a known editor method, an ancestor class, or a known child. Needs --editor.
## godot_versions_test.gd runs this same suite on the other supported versions.

const EditorNodeRef = preload("res://addons/_lib/editor_node_ref/src/editor_node_ref.gd")
const UNode = preload("uid://bnf4h0107r8b4") #! resolve UtilR.UNode
const CheckInstance = preload("uid://cnx1roduh82r") #! resolve Singletons.CheckInstance

const FIXTURE_SCRIPT = "res://addons/_lib/editor_node_ref/_export_ignore/test/fixtures/fixture_script.gd"
const POPULATE_FRAMES = 300

## Key -> expectation. class: is_class() name. sig: [signal, connected method suffix]. anc: an
## ancestor class. parent: the parent's class. child: a child class. named: a child's name.
## hidden / name: node state. optional: null is fine (only populated by some user actions).
## Markers must survive other plugins rearranging the tree: the console runs after they have.
## since / until: first / last minor where the key resolves; past until it must be null.
## An int key holds overrides from that minor on.
const EXPECT = {
	"FILESYSTEM_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "FileSystemDock::_tree_rmb_option"]},
	"FILESYSTEM_FOLDER_COLOR_POPUP": {"class": "PopupMenu", "optional": true},
	"FILESYSTEM_CREATE_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "FileSystemDock::_generic_rmb_option_selected"]},
	"FILESYSTEM_TREE": {"class": "Tree", "sig": ["item_mouse_selected", "FileSystemDock::_tree_rmb_select"]},
	"FILESYSTEM_BOTTOM_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "FileSystemDock::_file_list_rmb_option"]},
	"FILESYSTEM_BOTTOM_FOLDER_COLOR_POPUP": {"class": "PopupMenu", "optional": true},
	"FILESYSTEM_BOTTOM_CREATE_POPUP": {"class": "PopupMenu", "optional": true},
	"SCRIPT_EDITOR_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "ScriptEditor::_menu_option"],
		8: {"sig": ["id_pressed", "DocumentEditorContainer::_menu_option"]}},
	"SCRIPT_EDITOR_CODE_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "::_edit_option"]},
	"SCRIPT_EDITOR_SYNTAX_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "::_change_syntax_highlighter"]},
	"SCRIPT_EDITOR_MENU_BAR": {"class": "HBoxContainer", "anc": "ScriptEditor", "child": "MenuButton"},
	"SCENE_TABS": {"class": "EditorSceneTabs", "sig": ["tab_changed", "EditorNode::_set_current_scene"]},
	"SCENE_TABS_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "EditorSceneTabs::_custom_menu_option"]},
	"SCENE_TREE_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "SceneTreeDock::_tool_selected"]},
	"SCENE_TREE_DOCK": {"class": "SceneTreeDock"},
	"TITLE_BAR": {"class": "EditorTitleBar"},
	# 4.8 made main screens dock tabs: no button bar, and nothing left to hide for main screen docks.
	"TITLE_BUTTONS": {"until": 7, "class": "Control", "parent": "EditorTitleBar", "named": "Script"},
	"BOTTOM_PANEL": {"class": "VBoxContainer", "parent": "EditorBottomPanel",
		6: {"class": "EditorBottomPanel", "parent": null}},
	# 4.6+ has no button bar (the bottom panel is a TabBar); the getter returns this EditorLog row.
	"BOTTOM_PANEL_BUTTONS": {"class": "HBoxContainer", "anc": "EditorBottomPanel", "child": "Button",
		6: {"anc": "EditorLog", "child": "VBoxContainer"}},
	"EDITOR_LOG": {"class": "EditorLog"},
	"EDITOR_LOG_FILTER": {"class": "LineEdit", "sig": ["text_changed", "EditorLog::_search_changed"]},
	"DOCKS": {"class": "TabContainer", "sig": ["tab_changed", "EditorDockManager::_update_layout"]},
	"TITLE_MENU_BAR": {"class": "MenuBar", "parent": "EditorTitleBar"},
	"EDITOR_2D_POPUP": {"class": "PopupMenu", "sig": ["id_pressed", "CanvasItemEditor::_add_node_pressed"]},
	"EDITOR_LOG_BUTTON_CONTAINER": {"class": "VBoxContainer", "anc": "EditorLog", "child": "Button",
		7: {"class": "HFlowContainer"}},
	"EDITOR_LOG_RICH_TEXT_LABEL": {"class": "RichTextLabel", "anc": "EditorLog"},
	"EDITOR_DOCKS": {"since": 6, "class": "EditorDock"},
	"CLOSED_DOCKS_NODE": {"since": 6, "class": "Control", "parent": "Panel", "hidden": true},
	"SHADER_EDITOR": {"since": 6, "class": "EditorDock", "name": "Shader Editor"},
	"SCRIPT_EDITOR_SIDEBAR_V_SPLIT": {"class": "VSplitContainer", "sig": ["dragged", "::_split_dragged"]},
	"SCRIPT_EDITOR_H_SPLIT": {"class": "HSplitContainer", "sig": ["dragged", "::_split_dragged"]},
	"SCRIPT_EDITOR_TAB_CONTAINER": {"class": "TabContainer", "sig": ["tab_changed", "ScriptEditor::_tab_changed"],
		8: {"sig": ["tab_changed", "DocumentEditorContainer::ensure_select_current"]}},
}


static func run_tests() -> Dictionary:
	var out: Array = []
	var failures = 0
	failures += _test_ref_minor(out)
	if not Engine.is_editor_hint():
		out.append("FAIL needs --editor: EditorNodeRef reads the editor's own node tree")
		return {"result": failures + 1, "output": out}

	var ref = EditorNodeRef.get_instance()
	var tree = Engine.get_main_loop() as SceneTree
	var frames = 0
	while not ref.populated and frames < POPULATE_FRAMES:
		await tree.process_frame
		frames += 1
	if not ref.populated:
		out.append("FAIL never populated after %d frames: a getter likely errored in _popupulate_references" % frames)
		return {"result": failures + 1, "output": out}

	await _ensure_script_editor(tree)
	failures += _test_nodes(ref, out)
	failures += _test_code_popup_parent(ref, out)
	failures += _test_coverage(ref, out)
	out.push_front("editor_node_ref on %s: %d failure(s)" % [Engine.get_version_info().string, failures])
	return {"result": failures, "output": out}


## The SCRIPT_EDITOR_* keys need a script tab current. No refresh here: the values as registered
## are what consumers get, whether the tab was restored at startup or opened just now.
static func _ensure_script_editor(tree:SceneTree) -> void:
	var current = EditorInterface.get_script_editor().get_current_editor()
	if current == null or current.get_class() != "ScriptTextEditor":
		EditorInterface.edit_script(load(FIXTURE_SCRIPT))
		for i in 10:
			await tree.process_frame


## The code popup must belong to the current tab: its own editor, or script_tabs' DummyEditor
## that holds the editor's children while active. Catches a popup from some other tab or menu.
static func _test_code_popup_parent(ref, out:Array) -> int:
	var popup = ref._registry.get(EditorNodeRef.Nodes.SCRIPT_EDITOR_CODE_POPUP)
	var current = EditorInterface.get_script_editor().get_current_editor()
	if not is_instance_valid(popup) or current == null:
		return 0 # _test_nodes reports a missing popup
	var parents = [current]
	var script_tabs = CheckInstance.get_instance("ScriptTabSingleton")
	if is_instance_valid(script_tabs):
		parents.append(script_tabs.get_dummy_editor_from_editor(current))
	if popup.get_parent() in parents:
		out.append("ok   SCRIPT_EDITOR_CODE_POPUP belongs to the current tab")
		return 0
	out.append("FAIL SCRIPT_EDITOR_CODE_POPUP is under %s, not the current tab" % popup.get_parent().get_class())
	return 1


static func _test_ref_minor(out:Array) -> int:
	var cases = {3: 4, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 12: 8}
	var failures = 0
	for minor in cases:
		var got = EditorNodeRef._ref_minor_for(4, minor)
		if got != cases[minor]:
			out.append("FAIL _ref_minor_for(4, %d) = %d, expected %d" % [minor, got, cases[minor]])
			failures += 1
	return failures


static func _test_nodes(ref, out:Array) -> int:
	var minor = Engine.get_version_info().minor
	var failures = 0
	for key in EXPECT:
		var spec = _spec_for(EXPECT[key], minor)
		var registered = ref._registry.has(EditorNodeRef.Nodes[key])
		if minor < spec.get("since", 0):
			if registered:
				out.append("FAIL %s: registered, but expected only from 4.%d" % [key, spec.since])
				failures += 1
			continue
		var value = ref._registry.get(EditorNodeRef.Nodes[key])
		if minor > spec.get("until", minor):
			if value != null:
				out.append("FAIL %s: expected null after 4.%d (got %s)" % [key, spec.until, _describe(value)])
				failures += 1
			else:
				out.append("ok   %s: null (gone after 4.%d)" % [key, spec.until])
			continue
		var problems = []
		if value is Array:
			if value.is_empty():
				problems.append("empty array")
			for item in value:
				problems.append_array(_check(item, spec))
		elif value == null and spec.get("optional", false):
			out.append("ok   %s: null (optional)" % key)
			continue
		else:
			problems = _check(value, spec)
		if problems.is_empty():
			out.append("ok   %s: %s" % [key, _describe(value)])
		else:
			out.append("FAIL %s: %s (got %s)" % [key, "; ".join(problems), _describe(value)])
			failures += 1
	return failures


## Every enum key has an expectation, so a new key can't ship untested.
static func _test_coverage(ref, out:Array) -> int:
	var failures = 0
	for key in EditorNodeRef.Nodes:
		if not EXPECT.has(key):
			out.append("FAIL %s: no expectation in EXPECT" % key)
			failures += 1
	return failures


## Base expectation with every override whose minor <= `minor` applied in order.
static func _spec_for(entry:Dictionary, minor:int) -> Dictionary:
	var spec = {}
	var overrides = []
	for k in entry:
		if k is int:
			overrides.append(k)
		else:
			spec[k] = entry[k]
	overrides.sort()
	for from in overrides:
		if from <= minor:
			spec.merge(entry[from], true)
	return spec


static func _check(node, spec:Dictionary) -> Array:
	if not is_instance_valid(node) or not node is Node:
		return ["not a valid node"]
	var problems = []
	if not node.is_class(spec.class):
		problems.append("not a " + spec.class)
	if spec.has("sig") and _connected(node, spec.sig[0], spec.sig[1]) == null:
		problems.append("%s not connected to *%s" % spec.sig)
	if spec.get("parent") != null and not node.get_parent().is_class(spec.parent):
		problems.append("parent not a " + spec.parent)
	if spec.has("anc") and not _has_ancestor(node, spec.anc):
		problems.append("not inside a " + spec.anc)
	if spec.has("child") and not node.get_children(true).any(func(c): return c.is_class(spec.child)):
		problems.append("no %s child" % spec.child)
	if spec.has("named") and node.get_node_or_null(NodePath(spec.named)) == null:
		problems.append("no child named " + spec.named)
	if spec.has("name") and String(node.name) != spec.name:
		problems.append("not named " + spec.name)
	if spec.has("hidden") and node.visible == spec.hidden:
		problems.append("visible" if spec.hidden else "hidden")
	return problems


## Like UNode.get_signal_callable, but matches a method suffix: a handler can move to a base class
## between versions (ScriptTextEditor::_edit_option became TextEditorBase::_edit_option in 4.7).
static func _connected(node:Node, signal_name:String, method_suffix:String):
	if not node.has_signal(signal_name):
		return null
	if not method_suffix.begins_with("::"):
		return UNode.get_signal_callable(node, signal_name, method_suffix)
	for data in node.get_signal_connection_list(signal_name):
		if String((data.callable as Callable).get_method()).ends_with(method_suffix):
			return data.callable
	return null


static func _has_ancestor(node:Node, cls:String) -> bool:
	var p = node.get_parent()
	while p != null:
		if p.is_class(cls):
			return true
		p = p.get_parent()
	return false


static func _describe(value) -> String:
	if value is Array:
		return "Array[%d]" % value.size()
	if not is_instance_valid(value):
		return "null"
	if value is Node:
		return "%s %s (idx %d in %s)" % [value.get_class(), value.name, value.get_index(true), value.get_parent().get_class()]
	return str(value)
