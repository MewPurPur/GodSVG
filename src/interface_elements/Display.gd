extends VBoxContainer

@onready var viewport: Viewport = $ViewportContainer/Viewport
@onready var zoom_reset_button: Button = %ZoomReset
@onready var display: TextureRect = %Checkerboard

var zoom_level := 1.0:
	set(value):
		zoom_level = clampf(value, 0.25, 4.0)
		zoom_reset_button.text = "%d%%" % (zoom_level * 100)
		viewport.size_2d_override = viewport.size / zoom_level
		clamp_view()

func _on_zoom_out_pressed() -> void:
	zoom_level /= 2

func _on_zoom_in_pressed() -> void:
	zoom_level *= 2

func _on_zoom_reset_pressed() -> void:
	zoom_level = 1.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		display.position += event.relative / zoom_level
		clamp_view()

func clamp_view() -> void:
	display.position = display.position.clamp(
			-viewport.size / 2, viewport.size / zoom_level - Vector2(16, 16))
