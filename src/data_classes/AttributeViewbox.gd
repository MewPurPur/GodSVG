## The "viewBox" attribute of [TagSVG].
class_name AttributeViewbox extends Attribute

var rect: Rect2

func _init() -> void:
	type = Type.VIEWBOX
	default = null
	set_value(null, SyncMode.SILENT)

func set_value(rect_string: Variant, emit_attribute_changed := SyncMode.LOUD) -> void:
	if rect_string != null:
		rect = ViewboxParser.string_to_rect(rect_string)
	super(rect_string, emit_attribute_changed)

func set_rect(new_rect: Rect2, emit_attribute_changed := SyncMode.LOUD) -> void:
	rect = new_rect
	super.set_value(ViewboxParser.rect_to_string(new_rect), emit_attribute_changed)


func set_rect_x(new_x: float) -> void:
	rect.position.x = new_x
	set_value(ViewboxParser.rect_to_string(rect))

func set_rect_y(new_y: float) -> void:
	rect.position.y = new_y
	set_value(ViewboxParser.rect_to_string(rect))

func set_rect_w(new_w: float, emit_attribute_changed := SyncMode.LOUD) -> void:
	rect.size.x = new_w
	set_value(ViewboxParser.rect_to_string(rect), emit_attribute_changed)

func set_rect_h(new_h: float, emit_attribute_changed := SyncMode.LOUD) -> void:
	rect.size.y = new_h
	set_value(ViewboxParser.rect_to_string(rect), emit_attribute_changed)
