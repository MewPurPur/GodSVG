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
		if number_edit:
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
	var tex := SVGTexture.create_from_string(svg_markup)
	var tex_size := _get_tex_scale(Vector2i(tex.get_size()))
	if tex_size <= 0.0:
		tex_size = 0.01
	tex.base_scale = tex_size
	texture_rect.texture = tex
	texture = tex
	texture_changed.emit()
	scale_label.text = "(%.1fx)" % tex_size
	texture_size_string = "%sx%s %s" % [tex.get_width(), tex.get_height(), scale_label.text]


func _get_tex_scale(default_size: Vector2i) -> float:
	var max_dim_size := texture_size as int
	
	return max_dim_size / float(default_size[default_size.max_axis_index()])
