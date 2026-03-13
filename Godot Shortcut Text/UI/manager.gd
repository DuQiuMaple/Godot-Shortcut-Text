@tool
extends Panel
#region
var script_editor
var save_path = "res://addons/Godot Shortcut Text/Resource/Shortcuts_Save.json"
#endregion

#region Dictionary Array
var shortcuts_M:Array
var shortcuts_S:Array
var Single_index:int = 0

#Escape character
var escapes = {
	"\\n": "\n",   # 换行
	"{n}": "\n",   # 换行
	"\\t": "\t",   # 制表符
	"\\r": "\r",   # 回车
	"\\\\": "\\",  # 反斜杠本身
	"\\\"": "\"",  # 双引号
	"\\'": "'",    # 单引号
	"\\a": "\a",   # 响铃
	"\\b": "\b",   # 退格
	"\\f": "\f",   # 换页
	"\\v": "\v",   # 垂直制表符
}
#endregion

#region child
#Single 1  Multiple 0
@onready var shortcuts_container_M = %Custom_Shortcuts_M
@onready var shortcuts_container_S = %Custom_Shortcuts_S
var tscn_M = preload("res://addons/Godot Shortcut Text/UI/custom_shortcut_M/Custom_Shortcut_M.tscn")
var tscn_S = preload("res://addons/Godot Shortcut Text/UI/custom_shortcut_S/Custom_Shortcut_S.tscn")
#endregion



#region callback
func _ready() -> void:
	%New_Custom_Shortcut_M.pressed.connect(New_Custom_Shortcut.bind(false))
	%New_Custom_Shortcut_S.pressed.connect(New_Custom_Shortcut.bind(true))
	script_editor = EditorInterface.get_script_editor()

	append_custom_shortcut()
	
	Loading()

func _input(event: InputEvent) -> void:
	#if have multiple key shortcut
	#print(OS.get_keycode_string(event.keycode))
	if shortcuts_M:
		if event is InputEventKey and event.pressed and not event.echo:
			for shortcut in shortcuts_M:
				if shortcut.try_shortcut_text(event):
					insert_text(shortcut.mode,shortcut.shortcut_text)
					get_viewport().set_input_as_handled()   # stop the event spread

	#if have single key shortcut
	if shortcuts_S:
		for shortcut in shortcuts_S:
			if shortcut.try_shortcut_text(event):
				insert_text(shortcut.mode,shortcut.shortcut_text)
				get_viewport().set_input_as_handled()    # stop the event spread
#endregion

#region insert text
#insert text
func insert_text(mode:int,s:String):
	var current_script = script_editor.get_current_script()
	var text_edit = script_editor.get_current_editor().get_base_editor()
	
	if not current_script or not text_edit:
		return

	#Escape character
	for escape in escapes.keys():
		s = s.replace(escape,escapes[escape])
	match mode:
		0: # Normal Mode
			text_edit.insert_text_at_caret(s)
		
		1: # Repeat Mode
			#get current line
			var line_text = text_edit.get_line(text_edit.get_caret_line())
			
			if line_text.ends_with(s):
				#count leading tabs and auto-insert them at the beginning of the next line.
				var tab_num = count_tabs_num(line_text)
				var str = '\n' + '\t'.repeat(tab_num) + s
				
				text_edit.insert_text_at_caret(str)
			else :
				text_edit.insert_text_at_caret(s)
		
		2: # Embrace Mode
			var selected_text:String = text_edit.get_selected_text()
			
			#check if selected text is null
			if selected_text != '':
				
				#get current line
				var line_text = text_edit.get_line(text_edit.get_caret_line())
				
				#count leading tabs and auto-insert them at .
				var tab_num = count_tabs_num(line_text)
				var tabs = '\t'.repeat(tab_num)
				var n_tabs = '\n' + tabs
				
				text_edit.insert_text_at_caret(s.format({'s':selected_text,'t':tabs,'nt':n_tabs}))

#count the number of tabs in front of line
func count_tabs_num(line:String):
	var count:int = 0
	for i in line:
		if i == '\t':
			count += 1
		else :
			break
	return count
#endregion

#region Create or Delete Custom Shortcut
#Create a new Custom Shortcut
func New_Custom_Shortcut(which:bool):
	#which: 1 Single  0 Multiple
	var new
	if not which:
		new = tscn_M.instantiate()
		shortcuts_container_M.add_child(new)
		new.manager = self
	
		shortcuts_M.append(new)
	else :
		new = tscn_S.instantiate()
		shortcuts_container_S.add_child(new)
		new.manager = self
		new.InputMapActionName = name_InputAction()
	
		shortcuts_S.append(new)
	
	return new

#name InputAction
func name_InputAction():
	Single_index += 1
	return 'Godot_Shortcut_Text_InputMapAction' + str(Single_index)

#Delete a Custom Shortcut
func Delete_Custom_Shortcut(node):
	if 'type' in node and node.type == false:
		shortcuts_M.erase(node)
	elif 'type' in node and node.type == true:
		if InputMap.has_action(node.InputMapActionName):
			InputMap.erase_action(node.InputMapActionName)
		shortcuts_S.erase(node)
#endregion

#region warning
func shortcut_conflict_warning(s:String ,k:Key):
	if show_shortcut_conflict_warning():
		var k_s = OS.get_keycode_string(k).to_upper()
		push_error("From Godot Shortcut Text: shortcut conflict - {s} with Key:{k}".format({'s':s,'k':k_s}))

func show_shortcut_conflict_warning():
	return %Shortcut_Conflict_Warning.button_pressed
#endregion

func Reset_Single_Shortcut_InputAction():
	for child in shortcuts_S:
		child.add_InputAction()

#region _ready
#append custom shortcut when _ready() callback
func append_custom_shortcut():
	var children = shortcuts_container_M.get_children()
	for child in children:
		if child.get('type') and not child.type:
			shortcuts_M.append(child)
	children = shortcuts_container_S.get_children()
	for child in children:
		if child.get('type') and child.type:
			shortcuts_S.append(child)
			child.add_InputAction()

#load
func Loading():
	
	var Dic
	var file
	if FileAccess.file_exists(save_path):
		file = FileAccess.open(save_path,FileAccess.READ)
		Dic = JSON.parse_string(file.get_as_text())
		
		if Dic is Dictionary:
			pass
		else :
			push_error("From Godot Shortcut Text: Unable to read archive file")
			return
	else :
		push_error("From Godot Shortcut Text: Unable to open archive file")
		return
	
	if Dic.has('Setting'):
		var setting = Dic['Setting']
		%Shortcut_Conflict_Warning.button_pressed = setting['shortcut_conflict_warning']
	#region load Custom Shortcut
	Dic = Dic.values()
	var new
	for dic in Dic:
		if dic.has('Type'):
			#single
			if dic['Type']:
				var tmp = false
				for child in shortcuts_S:
					#find null shortcut
					if child.shortcut_text == '':
						new = child
						new.InputMapActionName = name_InputAction()
						tmp = true
						break
				if not tmp:
					new = New_Custom_Shortcut(true)
			#multiple
			elif not dic['Type']:
				var tmp = false
				for child in shortcuts_M:
					#find null shortcut
					if child.shortcut_text == '':
						new = child
						tmp = true
						break
				if not tmp:
					new = New_Custom_Shortcut(false)
	
			var insert_text = dic["insert_Text"]
			new.default_setting(
				insert_text,
				dic["Key"],
				dic["mode"],
				[
					dic["Ctrl"],
					dic["Alt"],
					dic["Shift"]
					],
				dic["Enable"])
	#endregion 
	
	file.close()

#Save
func Save():
	var Dic:Dictionary
	var file
	if FileAccess.file_exists(save_path):
		file = FileAccess.open(save_path,FileAccess.WRITE)
		if file == null:
			return
		
		for single in shortcuts_S:
			Dic[str(Dic.size())] = single.Save()
		for multiple in shortcuts_M:
			Dic[str(Dic.size())] = multiple.Save()
		
		Dic['Setting'] = {
			"shortcut_conflict_warning":%Shortcut_Conflict_Warning.button_pressed
		}
		
	var json_dic = JSON.stringify(Dic)
	file.store_string(json_dic)
	file.close()
#endregion
