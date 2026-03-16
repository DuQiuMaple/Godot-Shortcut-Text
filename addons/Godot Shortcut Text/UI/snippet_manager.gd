@tool
extends ScrollContainer

#region node
@onready var Rescan = %Rescan
@onready var Snippet_Container = %Snippet_Container
#endregion

#region path
var snippet_path = preload("res://addons/Godot Shortcut Text/UI/snippet/snippet.tscn")
var json_path = "res://addons/Godot Shortcut Text/Custom_Text.json"
#endregion


func _ready() -> void:
	Rescan.pressed.connect(RescanSnippet)
	RescanSnippet()

#Rescan Snippet
func RescanSnippet():
	
	clean()
	
	var Dic
	var file
	if FileAccess.file_exists(json_path):
		file = FileAccess.open(json_path,FileAccess.READ)
		Dic = JSON.parse_string(file.get_as_text())
		
		if Dic is Dictionary:
			pass
		else :
			push_error("From Godot Shortcut Text: Unable to read Custom_Text.json")
			return
	else :
		push_error("From Godot Shortcut Text: Unable to open Custom_Text.json")
		return
	
	load_json(Dic)
	file.close()

#clean children
func clean():
	var children = Snippet_Container.get_children()
	if children:
		for child in children:
			if InputMap.has_action(child.InputMapActionName):
				InputMap.erase_action(child.InputMapActionName)
			child.queue_free()

#load json
func load_json(Dic:Dictionary):
	var dic = Dic.keys()
	for dic_key in dic:
		var dic_value = Dic[dic_key]
		
		var InputMapName = "Godot_Shortcut_Text_InputMapAction_snippt_" + dic_key
		var text:String
		var key:Key
		var event
		var mode:int = 0
		var Ctrl:bool
		var Alt:bool
		var Shift:bool
		var has_at_least_one_mk:bool = false
		
		if "Enable" in dic_value:
			if dic_value["Enable"]:
				pass
			else :
				continue
		
		if "Text" in dic_value:
			text = dic_value["Text"]
		else :
			fail()
		
		if "Key" in dic_value:
			key = extra_key(dic_value["Key"])
		else :
			fail()
		
		if "mode" in dic_value:
			mode = dic_value["mode"]
		
		event = InputEventKey.new()
		event.keycode = key
		
		if "Ctrl" in dic_value:
			event.ctrl_pressed = dic_value["Ctrl"]
			has_at_least_one_mk = true
		if "Alt" in dic_value:
			event.alt_pressed = dic_value["Alt"]
			has_at_least_one_mk = true
		if "Shift" in dic_value:
			event.shift_pressed = dic_value["Shift"]
			has_at_least_one_mk = true
		
		if not has_at_least_one_mk:
			push_error("From Godot Shortcut Text: You must set at least one Modifier Key")
			continue
		
		if InputMap.has_action(InputMapName):
			InputMap.erase_action(InputMapName)
		InputMap.add_action(InputMapName)
		InputMap.action_add_event(InputMapName,event)
		var new = snippet_path.instantiate()
		Snippet_Container.add_child(new)
		new.init(InputMapName,text,OS.get_keycode_string(key),mode)

func fail():
	push_error("Custom_Text.json Format Error")

func extra_key(t:String):
	var keys:Key
	
	for c in t:
		var ascii = c.unicode_at(0)
		if (ascii >= 65 and ascii <= 90) or (ascii >= 97 and ascii <= 122) or (ascii >= 48 and ascii <= 57):
			var keycode = OS.find_keycode_from_string(c)
			keys = keycode
			break
	return keys
