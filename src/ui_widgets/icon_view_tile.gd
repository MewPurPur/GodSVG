extends PanelContainer


const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")


signal selected
signal remove_requested
signal texture_changed
signal texture_size_changed


@onready var select_button: Button = %SelectButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var scale_label: Label = %ScaleLabel
@onready var number_edit: NumberEdit = %NumberEdit
@onready var remove_button: Button = %RemoveButton


var texture: Texture2D


var svg_markup: String:
	set(value):
		svg_markup = value
		_update_texture()

var texture_size: int:
	set(value):
		texture_size = value
		if is_instance_valid(number_edit):
			number_edit.set_value(value, false)
		_update_texture()
		texture_size_changed.emit()

var texture_size_string: String


func _ready() -> void:
	select_button.pressed.connect(selected.emit)
	remove_button.pressed.connect(remove_requested.emit)
	number_edit.set_value(texture_size)
	number_edit.value_changed.connect(func(new_value: float) -> void:
		texture_size = new_value as int
	)
	_update_texture()


func _update_texture() -> void:
	if not texture_rect:
		return
	var new_texture := DPITexture.create_from_string(svg_markup)
	var tex_size := _get_tex_scale(Vector2i(new_texture.get_size()))
	if tex_size <= 0.0:
		tex_size = 0.01
	new_texture.base_scale = tex_size
	texture_rect.texture = new_texture
	texture = new_texture
	texture_changed.emit()
	scale_label.text = "(%.1f×)" % tex_size
	texture_size_string = "%s×%s %s" % [new_texture.get_width(), new_texture.get_height(), scale_label.text]


func _get_tex_scale(default_size: Vector2i) -> float:
	return texture_size / float(default_size[default_size.max_axis_index()])
