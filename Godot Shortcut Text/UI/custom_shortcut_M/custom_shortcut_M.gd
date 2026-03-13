@tool
extends Panel

#region node
@onready var Key_line_edit = %Shortcut
@onready var Text = %Shortcut_Text
#endregion

#region Keys
var Keys:Array[int] = []

var is_Crtl:
	get:
		return %Ctrl.is_pressed()
var is_Alt:
	get:
		return %Alt.is_pressed()
var is_Shift:
	get:
		return %Shift.is_pressed()

var is_Enable:
	get:
		return %Enable.button_pressed

var mode:int = 0
#endregion

var shortcut_text:
	get:
		return Text.text
var current_text:String
var type:bool = false #single 1  multiple 0
var manager

#region Callback func
func _ready() -> void:
	%Delete_Button.pressed.connect(_on_delete_button_pressed)
	%Mode.item_selected.connect(_on_mode_item_selected)
	
	Key_line_edit.text_submitted.connect(shortcut_change)
	Key_line_edit.text_changed.connect(text_change)
	Key_line_edit.focus_exited.connect(LineEdit_focus_exited)

#change mode
func _on_mode_item_selected(index: int) -> void:
	mode = index

#delete Custom Shortcut
func _on_delete_button_pressed() -> void:
	manager.Delete_Custom_Shortcut(self)
	queue_free()

#LineEdit_text_change
func text_change(new:String):
	current_text = new

#LineEdit_focus_exited
func LineEdit_focus_exited():
	shortcut_change(current_text)
#endregion 

#check if can trigger shortcut
func try_shortcut_text(event: InputEvent) -> bool:
	#check if have trigger key
	if Keys.is_empty():
		return false
	
	#check if insert text is null
	if shortcut_text == '':
		return false
	
	#check shortcut if enable
	if not is_Enable:
		return false
	#region check Modifier Keys
	#check if Modifier Keys is press when enable
	if is_Crtl:
		if not event.is_command_or_control_pressed():
			return false
	if is_Alt:
		if not event.alt_pressed:
			return false
	if is_Shift:
		if not event.shift_pressed:
			return false
	#endregion check Modifier Keys
	#check Keys
	if Keys.has(event.keycode):
		#check if all key pressed
		for key in Keys:
			if Input.is_key_pressed(key):
				continue
			else :
				return false
		
		#check if has at least one Modifier Key
		if not (is_Crtl or is_Alt or is_Shift):
			push_error("From Godot Shortcut Text: You must set at least one Modifier Key")
			return false
		return true
	
	return false

#update Shortcut
func shortcut_change(new_text: String) -> void:
	Keys = extract_keys(new_text)
	
	Key_line_edit.text = keys_to_string(Keys)

#Default Setting
func default_setting(s:String,k:String,m:int,m_k:Array,atv:bool = true):
	Text.text = s
	
	%Mode.selected = m
	_on_mode_item_selected(m)
	
	%Ctrl.button_pressed = m_k[0]
	%Alt.button_pressed = m_k[1]
	%Shift.button_pressed = m_k[2]
	
	%Enable.button_pressed = atv
	
	shortcut_change(k)

#region Helper func
#extract keys from LineEditor
func extract_keys(text:String):
	var keys:Array[int] = []
	
	for c in text:
		var char_code = c.unicode_at(0)
		
		if char_code >= 65 and char_code <= 90 and char_code not in keys:
			keys.append(char_code)
		
		#lower to upper
		elif char_code >= 97 and char_code <= 122 and char_code - 32 not in keys:
			var key_code = char_code - 32
			keys.append(key_code)
		
		#number
		elif char_code >= 48 and char_code <= 57 and char_code not in keys:
			keys.append(char_code)
	
	keys.sort()
	return keys

#Convert keys to string
func keys_to_string(keys:Array):
	var result = ""
	
	for key in keys:
		result += char(key) + '+'
	
	result = result.left(-1)
	
	return result

#Save
func Save():
	var dic:Dictionary
	dic["Type"] = type
	dic["insert_Text"] = shortcut_text
	dic["Key"] = %Shortcut.text
	dic["mode"] = mode
	dic["Ctrl"] = is_Crtl
	dic["Alt"] = is_Alt
	dic["Shift"] = is_Shift
	dic["Enable"] = is_Enable
	return dic
#endregion 
