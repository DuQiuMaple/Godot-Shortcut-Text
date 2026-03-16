@tool
extends EditorPlugin

const main_tscn = preload("res://addons/Godot Shortcut Text/UI/manager.tscn")
var main

func _enter_tree() -> void:
	main = main_tscn.instantiate()
	main.name = 'Godot Shortcut Text'
	
	add_control_to_bottom_panel(main,'Godot Shortcut Text')

func _exit_tree() -> void:
	if main:
		main.Save()
		remove_control_from_bottom_panel(main)
		main.queue_free()
