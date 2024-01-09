extends CheckBox

@export var section_name: String
@export var setting_name: String
@export var condition_expression: String = ""


func _ready() -> void:
	if is_condition_met():
		button_pressed = GlobalSettings.get(setting_name)
	else:
		disabled = true


func _on_pressed() -> void:
	GlobalSettings.toggle_bool_setting(section_name, setting_name)


func is_condition_met() -> bool:
	if not condition_expression.is_empty():
		var source := "extends Node\nfunc condition_met() -> bool: return " + condition_expression # Create function out of expression.
		var condition_executor := GDScript.new()
		condition_executor.source_code = source
		condition_executor.reload() # Parse script.
		var run_context: Object = condition_executor.new()
		add_child(run_context)
		var condition_met: bool = run_context.condition_met() # Get result.
		run_context.queue_free()
		return condition_met
	return true
