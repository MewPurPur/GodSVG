extends Node

var update_pending := false

const display_path := "user://display.svg"

var string := ""
var data := SVGData.new()
@onready var texture_node: TextureRect = get_tree().current_scene.get_node(^"%Texture")
@onready var code_editor: CodeEdit = get_tree().current_scene.get_node(^"%CodeEdit")

func tags_to_string(superscaled := false, add_xmlns := true) -> String:
	var w := data.w
	var h := data.h
	var scale := 128.0 if superscaled  else 1.0
	# Opening
	string = '<svg width="{w}" height="{h}" viewBox="({w} {h})"'.format(
			{"w": w * scale, "h": h * scale})
	if add_xmlns:
		string += ' xmlns="http://www.w3.org/2000/svg"'
	string += '>'
	if superscaled:
		string += '<g transform="scale(%d)">' % scale
	# Inner tags
	for tag in data.tags:
		string += '<' + tag.title
		for attribute_key in tag.attributes:
			var attribute: SVGAttribute = tag.attributes[attribute_key]
			if attribute.value == attribute.default:
				continue
			
			match attribute.type:
				SVGAttribute.Type.INT:
					string += ' %s="%d"' % [attribute_key, attribute.value]
				SVGAttribute.Type.FLOAT, SVGAttribute.Type.UFLOAT, SVGAttribute.Type.NFLOAT:
					string += ' %s="' % attribute_key + String.num(attribute.value, 4) + '"'
				SVGAttribute.Type.COLOR:
					if attribute.value == "none":
						string += ' %s="%s"' % [attribute_key, attribute.value]
					else:
						string += ' %s="#%s"' % [attribute_key, attribute.value]
				SVGAttribute.Type.PATHDATA:
					string += ' %s="%s"' % [attribute_key, attribute.value]
				SVGAttribute.Type.ENUM:
					string += ' %s="%s"' % [attribute_key, attribute.value]
		string += '/>'
	# Closing
	if superscaled:
		string += '</g>'
	string += '</svg>'
	return string

func string_to_tags() -> void:
	pass  # TODO


func update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		update_display()

func update_display() -> void:
	# Store the SVG string.
	var file := FileAccess.open(display_path, FileAccess.WRITE)
	file.store_string(tags_to_string(true))
	file.close()
	code_editor.text = tags_to_string()
	# Update the display.
	if FileAccess.file_exists(display_path):
		# When/if godot exposes the scale argument of this function,
		# it could be used to replace the superscaled argument.
		var image := Image.load_from_file(display_path)
		var image_texture := ImageTexture.create_from_image(image)
		texture_node.texture = image_texture
	update_pending = false
