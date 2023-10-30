## A popup for picking a color.
extends Popup

signal color_picked(new_color: String)

@onready var swatch_containers: Array[Node] =\
		[%PureSwatches, %CommonSwatches, %RainbowSwatches]

func _ready() -> void:
	for swatch_container in swatch_containers:
		for swatch in swatch_container.get_children():
			swatch.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_mask == MOUSE_BUTTON_LEFT:
		for swatch_container in swatch_containers:
			for swatch in swatch_container.get_children():
				if swatch.get_global_rect().has_point(get_mouse_position()):
					color_picked.emit(swatch.color_hex)
					hide()
