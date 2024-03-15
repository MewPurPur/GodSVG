## A Popup that automatically shrinks down to the size of its single control.
class_name BetterPopup extends Popup

func _init() -> void:
	disable_3d = true
	transparent_bg = true

func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node) -> void:
	if get_child_count() == 1 and node is Control:
		node.resized.connect(_on_child_resized)

func _on_child_resized() -> void:
	size = Vector2i.ZERO
