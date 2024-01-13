## Allows passing an array of custom horizontal spacings.
class_name CustomSpacedHBoxContainer extends Container

# Array for the spacing between elements.
var _spacing_array: Array  # Array[int]

func _ready() -> void:
	sort_children.connect(_sort_children)

func set_spacing_array(new_arr: Array) -> void:
	_spacing_array = new_arr
	queue_sort()

func _sort_children():
	var current_x := 0.0
	var spacing_arr_size := _spacing_array.size()
	
	for i in get_child_count():
		var child: Control = get_child(i)
		child.position.x = current_x
		
		current_x += child.size.x
		if i < spacing_arr_size:
			current_x += _spacing_array[i]
