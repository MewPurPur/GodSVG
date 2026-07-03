# A popup for picking a path command in conversion context.
extends PanelContainer

const PathCommandConversionButton = preload("res://src/ui_widgets/path_command_conversion_button.tscn")

signal conversion_picked(conversion_method: AttributePathdata.Conversion)

var path_attribute: AttributePathdata
var indices: PackedInt32Array

@onready var exact_conversions: VBoxContainer = %ExactConversions
@onready var exact_label: Label = %ExactLabel
@onready var exact_vbox: VBoxContainer = %ExactConversions/ExactVBox
@onready var lossy_conversions: VBoxContainer = %LossyConversions
@onready var lossy_label: Label = %LossyLabel
@onready var lossy_vbox: VBoxContainer = %LossyConversions/LossyVBox

func _ready() -> void:
	conversion_picked.connect(queue_free.unbind(1))
	exact_label.text = Translator.translate("Exact conversions") + ":"
	lossy_label.text = Translator.translate("Lossy conversions") + ":"

func setup(new_path_attribute: AttributePathdata, new_indices: PackedInt32Array) -> void:
	path_attribute = new_path_attribute
	if not is_node_ready():
		await ready
	
	indices = new_indices.duplicate()
	indices.sort()
	
	var has_zero_index := indices.has(0)
	var command_count := path_attribute.get_command_count()
	var commands: Array[PathCommand] = []
	for i in indices:
		commands.append(path_attribute.get_command(i))
	
	var original_commands_char := commands[0].command_char.to_upper()
	for i in range(1, commands.size()):
		if commands[i].command_char.to_upper() != original_commands_char:
			original_commands_char = "*"
			break
	
	# If there are shorthand commands around selected full commands, warn if the conversion would change the full commands.
	var has_reliant_s_commands := false
	for i in indices.size():
		var current_idx := indices[i]
		if path_attribute.get_command(current_idx).command_char in "Cc" and\
		(((current_idx > 0 and (i == 0 or indices[i - 1] != current_idx - 1)) and path_attribute.get_command(current_idx - 1).command_char in "Ss") or\
		((current_idx < command_count - 1 and (i == indices.size() - 1 or indices[i + 1] != current_idx + 1)) and\
		path_attribute.get_command(current_idx + 1).command_char in "Ss")):
			has_reliant_s_commands = true
			break
	
	var has_reliant_t_commands := false
	for i in indices.size():
		var current_idx := indices[i]
		if path_attribute.get_command(current_idx).command_char in "Qq" and\
		(((current_idx > 0 and (i == 0 or indices[i - 1] != current_idx - 1)) and path_attribute.get_command(current_idx - 1).command_char in "Ss") or\
		((current_idx < command_count - 1 and (i == indices.size() - 1 or indices[i + 1] != current_idx + 1)) and\
		path_attribute.get_command(current_idx + 1).command_char in "Tt")):
			has_reliant_t_commands = true
			break
	
	if original_commands_char != "M":
		var is_m_warned := has_reliant_s_commands or has_reliant_t_commands
		if not is_m_warned:
			for idx in indices:
				if indices.has(idx + 1) or indices.has(idx - 1) or (idx != 0 and path_attribute.get_command(idx - 1).command_char in "Mm") or\
				(idx < command_count - 1 and path_attribute.get_command(idx + 1).command_char in "MmZz"):
					is_m_warned = true
					break
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_MOVEMENT, original_commands_char, false, is_m_warned)
	
	var is_linelike_warned := has_zero_index or has_reliant_s_commands or has_reliant_t_commands
	if original_commands_char != "L":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_LINE, original_commands_char, false, is_linelike_warned)
	if original_commands_char != "H":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_HORIZONTAL_LINE, original_commands_char, false, is_linelike_warned)
	if original_commands_char != "V":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_VERTICAL_LINE, original_commands_char, false, is_linelike_warned)
	
	if original_commands_char != "Z":
		var is_z_disabled := false
		for i in indices.size():
			var current_idx := indices[i]
			if (i != 0 and indices[i - 1] == current_idx - 1) or (current_idx != 0 and path_attribute.get_command(current_idx - 1).command_char in "Zz") or\
			(current_idx < command_count - 1 and path_attribute.get_command(current_idx + 1).command_char in "Zz"):
				is_z_disabled = true
				break
		var is_z_warned := is_linelike_warned
		if not is_z_warned:
			for idx in indices:
				if path_attribute.get_command(idx - 1).command_char in "Mm":
					is_z_warned = true
					break
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_CLOSURE, original_commands_char, is_z_disabled, is_z_warned)
	
	if original_commands_char != "A":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_ELLIPTICAL_ARC, original_commands_char, false, is_linelike_warned)
	
	var is_quadratic_bezier_warned := has_zero_index or has_reliant_s_commands
	if original_commands_char != "Q":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE, original_commands_char, false, is_quadratic_bezier_warned)
	if original_commands_char != "T":
		var is_t_warned := is_quadratic_bezier_warned
		if not is_t_warned:
			for i in indices.size():
				if not ((i != 0 and indices[i - 1] == indices[i] - 1) or path_attribute.get_command(indices[i] - 1).command_char in "QqTt"):
					is_t_warned = true
					break
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE, original_commands_char, false, is_t_warned)
	
	var is_cubic_bezier_warned := has_zero_index or has_reliant_t_commands
	if original_commands_char != "C":
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_CUBIC_BEZIER_CURVE, original_commands_char, false, is_cubic_bezier_warned)
	if original_commands_char != "S":
		var is_s_warned := is_cubic_bezier_warned
		if not has_zero_index:
			for i in indices.size():
				if not ((i != 0 and indices[i - 1] == indices[i] - 1) or path_attribute.get_command(indices[i] - 1).command_char in "CcSs"):
					is_s_warned = true
					break
		add_path_command_button(AttributePathdata.Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE, original_commands_char, false, is_s_warned)
	
	if exact_vbox.get_child_count() == 0:
		exact_conversions.hide()
	
	for vbox in [exact_vbox, lossy_vbox]:
		var children: Array[Control] = []
		for child in vbox.get_children():
			children.append(child)
		HandlerGUI.register_focus_sequence(vbox, children, false)
	HandlerGUI.register_focus_sequence(self, [exact_vbox, lossy_vbox], true)

func add_path_command_button(conversion: AttributePathdata.Conversion, original_commands_char: String, is_disabled := false, is_warned := false) -> void:
	var path_command_button := PathCommandConversionButton.instantiate()
	path_command_button.setup(conversion, original_commands_char, is_disabled, is_warned)
	if not is_disabled:
		path_command_button.pressed_custom.connect(conversion_picked.emit)
	# Determine which container should add them.
	for i in indices:
		if not path_attribute.is_conversion_exact(i, conversion):
			lossy_vbox.add_child(path_command_button)
			return
	exact_vbox.add_child(path_command_button)
