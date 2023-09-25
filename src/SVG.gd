extends Node

const display_path := "user://display.svg"

var string := ""
var data := SVGData.new()

var selected_tag_idx: int

func tags_to_string() -> String:
	var w := data.w
	var h := data.h
	# Opening
	string = '<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}"'.format(
			{"w": w, "h": h})
	string += ' xmlns="http://www.w3.org/2000/svg">'
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
	string += '</svg>'
	return string

func string_to_tags() -> void:
	pass  # TODO
