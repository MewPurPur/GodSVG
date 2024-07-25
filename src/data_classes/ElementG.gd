class_name ElementG extends Element

const name = "g"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"opacity": return "1"
		_: return ""

# TODO: It's not enough to merge up with the bounding boxes of the children.
# If they are transformed it would be wrong.
func get_bounding_box() -> Rect2:
	var bounding_box := Rect2()
	#var established_bb := false
	#for child in get_children():
		#if DB.is_attribute_recognized(child.name, "transform"):
			#var cbb: Rect2 = child.get_transformed_bounding_box()
			#if not established_bb:
				#bounding_box = cbb
				#established_bb = true
			#else:
				#bounding_box = bounding_box.merge(cbb)
	return bounding_box
