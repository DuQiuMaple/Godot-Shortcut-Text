@tool
extends PanelContainer

var InputMapActionName:String

#region node
@onready var text = %insert_text
@onready var key = %key_text

var shortcut_text:String
var mode:int
#endregion

func init(n:String ,t:String ,k:String ,m:int):
	InputMapActionName = n
	
	shortcut_text = t
	text.text = 'Insert_Text:\n' + t
	key.text = 'Key: ' + k
	mode = m

#check if can trigger shortcut
func try_shortcut_text(event: InputEvent) -> bool:
	#check if trigger InputMap
	if Input.is_action_just_pressed(InputMapActionName):
		return true
	else :
		return false
