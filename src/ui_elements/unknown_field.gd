# An editor to be tied to an attribute GodSVG can't recognize, allowing to still edit it.
extends BetterLineEdit

signal focused
var attribute: Attribute

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	sync(new_value)
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	super()
	set_value(attribute.get_value())
	update_translation()


func update_translation() -> void:
	tooltip_text = attribute.name + "\n(%s)" %\
			TranslationServer.translate("GodSVG doesn’t recognize this attribute")


func _on_focus_entered() -> void:
	focused.emit()
	super()

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text)


func sync(new_value: String) -> void:
	text = new_value
