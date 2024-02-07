## A node that intercepts scrolling events and turns them into smoothed scroll events.
## (Works only on one window at a time. Should be manually added to sub-windows.)
class_name SmoothScroll extends Control

## Controls how fast the smoothing animation is.
@export var scroll_speed: float = 20.0
## Controls how big of a step single scroll will move.
@export var scroll_step: float = 1.0

# The last known mouse position.
var _last_pos: Vector2
var _last_pos_global: Vector2

var _needed_scroll: Vector2  # The amount that hasn't been scrolled yet.
var _last_event: InputEventMouseButton  # Last event to copy properties from.

@onready var _window := get_window()


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Update position on mouse motion.
		_last_pos = event.position
		_last_pos_global = event.global_position
	
	elif event is InputEventMouseButton:
		
			
		# Only intercept scrolling events.
		if not event.pressed or not event.button_index in [MOUSE_BUTTON_WHEEL_DOWN,
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_WHEEL_LEFT]:
			return
		
		# Detect if input doesn't have smooth factor.
		# That is when the factor is a multiple of 1, an integer.
		if roundf(event.factor) == event.factor:
			_last_event = event
			accept_event()
			
			# Calculate the step factor.
			# The event factor can be higher than 1, which has to be taken into account.
			var factor := scroll_step * maxf(event.factor, 1.0)
			
			match event.button_index:
				MOUSE_BUTTON_WHEEL_DOWN:
					_needed_scroll.y += factor
				MOUSE_BUTTON_WHEEL_UP:
					_needed_scroll.y -= factor
				MOUSE_BUTTON_WHEEL_RIGHT:
					_needed_scroll.x += factor
				MOUSE_BUTTON_WHEEL_LEFT:
					_needed_scroll.x -= factor


func _process(delta: float) -> void:
	if _needed_scroll.length_squared() < 0.001:  # Dont always process, to save cpu.
		return
	
	var event: InputEventMouseButton = _last_event  # Copy properties of last scroll event.
	
	# Calculate distance to scroll on this frame.
	# Limit to 0.99 to prevent overshoot and infinite feedback on low FPS.
	var dist := _needed_scroll * minf(delta * scroll_speed, 0.99)
	var abs_dist := dist.abs()
	
	# Clear scroll buttons from mask.
	event.button_mask &= ~0b1111000  # from 8 to 64
	
	if abs_dist.x < abs_dist.y:
		# Vertical scroll.
		if dist.y > 0:
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.button_mask |= 0b0010000  # 16
		else:
			event.button_index = MOUSE_BUTTON_WHEEL_UP
			event.button_mask |= 0b0001000  # 8
		
		# Decrease needed scroll amount by the amount scrolled.
		_needed_scroll.y -= dist.y
		event.factor = abs_dist.y
	else:
		# Horizontal scroll.
		if dist.x > 0:
			event.button_index = MOUSE_BUTTON_WHEEL_RIGHT
			event.button_mask |= 0b1000000  # 64
		else:
			event.button_index = MOUSE_BUTTON_WHEEL_LEFT
			event.button_mask |= 0b0100000  # 32
		
		_needed_scroll.x -= dist.x
		event.factor = abs_dist.x
	
	# Apply position data to event.
	event.position = _last_pos * _window.content_scale_factor
	event.global_position = _last_pos_global
	
	# Send fake input event with factor.
	Input.parse_input_event(event)
	event = event.duplicate()
	# Disable pressed state.
	event.button_mask &= ~0b1111000
	event.pressed = false
	Input.parse_input_event(event)
