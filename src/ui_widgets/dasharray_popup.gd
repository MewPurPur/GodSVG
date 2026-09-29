extends PanelContainer

@onready var grid_container: GridContainer = %GridContainer

var attribute: AttributeDasharray

func _ready() -> void:
	sync()

func sync() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.add_child(Control.new())
	var dash_label := Label.new()
	dash_label.text = Translator.translate("Dash")
	dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_container.add_child(dash_label)
	var gap_label := Label.new()
	gap_label.text = Translator.translate("Gap")
	gap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_container.add_child(gap_label)
	
	var dasharray_size := attribute.get_dash_array_size()
	for i in (dasharray_size / 2 + 5):
		var dash_index := i * 2
		var gap_index := dash_index + 1
		
		var pair_index_label := Label.new()
		pair_index_label.text = String.num_uint64(i)
		pair_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid_container.add_child(pair_index_label)
		
		var dash_edit := BetterLineEdit.new()
		dash_edit.custom_minimum_size.x = 48.0
		if dash_index < dasharray_size:
			dash_edit.text = Utils.num_simple(attribute.get_dash_array_element(dash_index))
		else:
			dash_edit.placeholder_text = Utils.num_simple(attribute.get_dash_array_element((dash_index) % dasharray_size))
		grid_container.add_child(dash_edit)
		var gap_edit := BetterLineEdit.new()
		gap_edit.custom_minimum_size.x = 48.0
		if gap_index < dasharray_size:
			gap_edit.text = Utils.num_simple(attribute.get_dash_array_element(gap_index))
		else:
			gap_edit.placeholder_text = Utils.num_simple(attribute.get_dash_array_element((gap_index) % dasharray_size))
		grid_container.add_child(gap_edit)
