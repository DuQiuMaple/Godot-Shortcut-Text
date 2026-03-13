@tool
extends Panel

#region node
@onready var Key_line_edit = %Shortcut
@onready var Text = %Shortcut_Text
#endregion

#region Keys
var Keys:Key

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

var InputMapActionName:String
var shortcut_text:
	get:
		return Text.text
var current_text:String
var type:bool = true #single 1  multiple 0
var manager


#region Callback func
func _ready() -> void:
	%Delete_Button.pressed.connect(_on_delete_button_pressed)
	%Mode.item_selected.connect(_on_mode_item_selected)
	
	%Ctrl.pressed.connect(_on_Modifier_Keys_button_prressed)
	%Alt.pressed.connect(_on_Modifier_Keys_button_prressed)
	%Shift.pressed.connect(_on_Modifier_Keys_button_prressed)
	
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

#change InputMapAction
func _on_Modifier_Keys_button_prressed():
	if InputMap.has_action(InputMapActionName):
		add_InputAction()
	is_editor_shortcut_used()

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
	if not Keys:
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
	
	#check if trigger InputMap
	if Input.is_action_just_pressed(InputMapActionName):
		#check if has at least one Modifier Key
		if not (is_Crtl or is_Alt or is_Shift):
			push_error("From Godot Shortcut Text: You must set at least one Modifier Key")
			return false
		return true

	return false

#update Shortcut
func shortcut_change(new_text: String) -> void:
	Keys = extract_keys(new_text)
	
	Key_line_edit.text = OS.get_keycode_string(Keys)
	
	add_InputAction()
	
	#check if shortcut conflict
	is_editor_shortcut_used()

#add InputMap
func add_InputAction():
	if not Keys:
		return
	if InputMap.has_action(InputMapActionName):
		InputMap.erase_action(InputMapActionName)
	
	var event = InputEventKey.new()
	event.keycode = Keys
	
	event.ctrl_pressed = is_Crtl
	event.alt_pressed = is_Alt
	event.shift_pressed = is_Shift
	
	InputMap.add_action(InputMapActionName)
	InputMap.action_add_event(InputMapActionName, event)
	
	show_InputMapAction_name()

#show InputMapAtion name to user
func show_InputMapAction_name() -> void:
	%ts.text = "InuputMapName: " + InputMapActionName

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
	var keys:Key
	
	for c in text:
		var ascii = c.unicode_at(0)
		if (ascii >= 65 and ascii <= 90) or (ascii >= 97 and ascii <= 122) or (ascii >= 48 and ascii <= 57):
			var keycode = OS.find_keycode_from_string(c)
			keys = keycode
			break
	return keys

#check if shorcut conflict
func is_editor_shortcut_used():
	var EventKey = InputEventKey.new()
	EventKey.keycode = Keys
	EventKey.ctrl_pressed = is_Crtl
	EventKey.alt_pressed = is_Alt
	EventKey.shift_pressed = is_Shift
	
	var settings = EditorInterface.get_editor_settings()
	var shortcut_names = settings.get_shortcut_list()

	for name in shortcut_names:
		var shortcut = settings.get_shortcut(name)
		if shortcut and shortcut.matches_event(EventKey):
			owner.shortcut_conflict_warning(name,Keys)

#Save
func Save():
	var dic:Dictionary
	dic["Type"] = type
	dic["insert_Text"] = shortcut_text
	dic["Key"] = OS.get_keycode_string(Keys)
	dic["mode"] = mode
	dic["Ctrl"] = is_Crtl
	dic["Alt"] = is_Alt
	dic["Shift"] = is_Shift
	dic["Enable"] = is_Enable
	return dic
#endregion 
