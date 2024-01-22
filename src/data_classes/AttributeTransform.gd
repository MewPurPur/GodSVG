## An attribute representing a 2d transform.
class_name AttributeTransform extends Attribute

var _transform := Transform2D.IDENTITY

func _init() -> void:
	default = ""
	set_value(default, SyncMode.SILENT)

func _sync() -> void:
	_transform = TransformParser.text_to_transform(get_value())

func autoformat(text: String) -> String:
	if GlobalSettings.transform_enable_autoformatting:
		return TransformParser.transform_to_text(TransformParser.text_to_transform(text))
	else:
		return text

func set_transform(new_transform: Transform2D, sync_mode := SyncMode.LOUD) -> void:
	_transform = new_transform
	super.set_value(TransformParser.transform_to_text(new_transform), sync_mode)

func get_transform() -> Transform2D:
	return _transform
