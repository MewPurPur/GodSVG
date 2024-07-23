extends PanelContainer

var type: String

@onready var transform_list: VBoxContainer = $TransformList
@onready var transform_icon: TextureRect = $TransformList/TopPanel/TransformIcon
@onready var transform_label: Label = $TransformList/TopPanel/TransformLabel
@onready var more_button: Button = $TransformList/TopPanel/MoreButton

var fields: Array[BetterLineEdit]
