extends Control

# Runs every time the mouse moves. Returning true means you can drop the TIDs.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Array[PackedInt32Array]:
		return false
	get_parent().update_proposed_tid()
	for tid in data:
		if Utils.is_tid_parent(tid, Indications.proposed_drop_tid):
			return false
	return true

# Runs when you drop the TIDs.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Array[PackedInt32Array]:
		SVG.move_tags_to(data, Indications.proposed_drop_tid)
