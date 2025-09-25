## A resource passed to ElementRoot.optimize() to determine configs.
class_name Optimizer extends ConfigResource

func get_setting_default(setting: String) -> Variant:
	match setting:
		"remove_comments": return true
		"convert_shapes": return true
		"simplify_path_parameters": return true
	return null

@export var remove_comments := true:
	set(new_value):
		if remove_comments != new_value:
			remove_comments = new_value
			emit_changed()

@export var convert_shapes := true:
	set(new_value):
		if convert_shapes != new_value:
			convert_shapes = new_value
			emit_changed()

@export var simplify_path_parameters := true:
	set(new_value):
		if simplify_path_parameters != new_value:
			simplify_path_parameters = new_value
			emit_changed()
