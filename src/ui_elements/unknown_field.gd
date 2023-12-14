## An editor to be tied to an AttributeUnknown.
## Allows attributes to be edited even if they aren't recognized by GodSVG.
extends BetterLineEdit

signal focused
var attribute: AttributeUnknown
var attribute_name: String

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR):
	sync(new_value)
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _ready() -> void:
	super()
	set_value(attribute.get_value())
	tooltip_text = attribute_name + "\n(" + tr(&"#unknown_tooltip") + ")"


func _on_focus_entered() -> void:
	focused.emit()
	super()

func _on_focus_exited() -> void:
	set_value(text)
	super()

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text)


func sync(new_value: String) -> void:
	text = new_value
