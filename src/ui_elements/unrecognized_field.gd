# An editor to be tied to an attribute GodSVG can't recognize, allowing to still edit it.
extends BetterLineEdit

var tag: Tag
var attribute_name: String

func set_value(new_value: String, save := true) -> void:
	sync(new_value)
	var attribute := tag.get_attribute(attribute_name)
	if attribute.get_value() != new_value:
		attribute.set_value(new_value, save)


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	super()
	set_value(tag.get_attribute(attribute_name).get_value())
	update_translation()
	text_submitted.connect(set_value)

func sync(new_value: String) -> void:
	text = new_value

func update_translation() -> void:
	tooltip_text = attribute_name + "\n(%s)" %\
			TranslationServer.translate("GodSVG doesn’t recognize this attribute")
