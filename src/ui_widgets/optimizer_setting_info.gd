extends PanelContainer

var formatter := Formatter.new(Formatter.Preset.PRETTY)

@onready var label: Label = %Label
@onready var before_label: Label = %BeforeLabel
@onready var before_text_edit: BetterTextEdit = %BeforeTextEdit
@onready var after_label: Label = %AfterLabel
@onready var after_text_edit: BetterTextEdit = %AfterTextEdit
@onready var vbox_container: VBoxContainer = $VBoxContainer

var main_text := ""
var before_text := ""
var after_text := ""

func setup(example_root: ElementRoot, optimizer: Optimizer, new_main_text: String) -> void:
	main_text = new_main_text
	before_text = SVGParser.root_to_markup(example_root, formatter)
	example_root.optimize(optimizer)
	after_text = SVGParser.root_to_markup(example_root, formatter)

func _ready() -> void:
	before_label.add_theme_color_override("font_color", ThemeUtils.dim_text_color)
	after_label.add_theme_color_override("font_color", ThemeUtils.dim_text_color)
	before_text_edit.syntax_highlighter = SVGHighlighter.new()
	after_text_edit.syntax_highlighter = SVGHighlighter.new()
	
	label.text = main_text
	before_label.text = Translator.translate("Before") + " (%d B)" % before_text.length()
	before_text_edit.text = before_text
	after_label.text = Translator.translate("After") + " (%d B)" % after_text.length()
	after_text_edit.text = after_text
