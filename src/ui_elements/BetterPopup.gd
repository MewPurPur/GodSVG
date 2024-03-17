## A Popup that automatically shrinks down to the size of its single control.
@icon("res://visual/editor_only/BetterPopup.svg")
class_name BetterPopup extends Popup

func _init() -> void:
	disable_3d = true
	transparent_bg = true

func _enter_tree() -> void:
	popup_hide.connect(queue_free)
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node) -> void:
	if get_child_count() == 1 and node is Control:
		node.resized.connect(reset_size)
