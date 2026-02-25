@abstract class_name ThemeUtils

static var main_font: FontVariation = preload("res://assets/fonts/MainFont.tres")
static var bold_font: FontVariation = preload("res://assets/fonts/BoldFont.tres")
static var mono_font: FontVariation = preload("res://assets/fonts/MonoFont.tres")

static var base_color: Color
static var accent_color: Color
static var is_theme_dark: bool

static var max_contrast_color: Color  # White on dark theme, black on light theme.
static var extreme_theme_color: Color  # Black on dark theme, white on light theme.
static var tinted_contrast_color: Color  # Base color used to derive icon colors and other UI elements.
static var gray_color: Color  # Light gray on dark theme, darker gray on light theme.
static var tinted_gray_color: Color  # Used for disabled items that'd normally use tinted_contrast_color.
static var black_or_white_counter_accent_color: Color

static var warning_icon_color: Color
static var info_icon_color: Color
static var folder_color: Color
static var text_file_color: Color

static var hover_selected_inspector_frame_inner_color: Color
static var hover_selected_inspector_frame_title_color: Color
static var selected_inspector_frame_inner_color: Color
static var selected_inspector_frame_title_color: Color
static var active_inspector_frame_border_color: Color
static var hover_inspector_frame_inner_color: Color
static var hover_inspector_frame_title_color: Color
static var hover_inspector_frame_border_color: Color
static var inspector_frame_inner_color: Color
static var inspector_frame_title_color: Color
static var inspector_frame_border_color: Color

static var intermediate_color: Color  # Color of button borders, derived from the accent color.
static var soft_intermediate_color: Color  # Color of button insides.
static var softer_intermediate_color: Color  # Color of tabs.
static var intermediate_hover_color: Color
static var soft_intermediate_hover_color: Color
static var softer_intermediate_hover_color: Color

static var desaturated_color: Color  # Color of line edits and others.
static var disabled_color: Color

static var soft_base_color: Color
static var softer_base_color: Color
static var soft_accent_color: Color

static var hover_overlay_color: Color
static var pressed_overlay_color: Color
static var hover_pressed_overlay_color: Color

static var soft_hover_overlay_color: Color
static var soft_pressed_overlay_color: Color
static var soft_hover_pressed_overlay_color: Color

static var strong_hover_overlay_color: Color
static var stronger_hover_overlay_color: Color

static var basic_panel_inner_color: Color
static var basic_panel_border_color: Color
static var subtle_panel_border_color: Color

static var caret_color: Color
static var selection_color: Color
static var disabled_selection_color: Color

static var text_color: Color
static var highlighted_text_color: Color
static var dim_text_color: Color
static var dimmer_text_color: Color
static var subtle_text_color: Color
static var editable_text_color: Color

static var common_button_inner_color_pressed: Color
static var common_button_border_color_pressed: Color
static var common_button_inner_color_disabled: Color
static var common_button_border_color_disabled: Color

static var connected_button_inner_color_hover: Color
static var connected_button_border_color_hover: Color
static var connected_button_inner_color_pressed: Color
static var connected_button_border_color_pressed: Color

static var context_icon_normal_color: Color
static var context_icon_hover_color: Color
static var context_icon_pressed_color: Color

static var flat_button_color_disabled: Color

static var subtle_flat_panel_color: Color
static var contrast_flat_panel_color: Color
static var overlay_panel_inner_color: Color
static var overlay_panel_border_color: Color

static var scrollbar_pressed_color: Color

static var focus_color: Color
static var weak_focus_color: Color
static var dim_focus_color: Color

static var line_edit_inner_color: Color
static var line_edit_normal_border_color: Color
static var mini_line_edit_inner_color: Color
static var mini_line_edit_normal_border_color: Color
static var line_edit_inner_color_disabled: Color
static var line_edit_border_color_disabled: Color

static var text_edit_alternative_inner_color: Color

static var selected_tab_color: Color
static var selected_tab_border_color: Color

static func color_difference(color1: Color, color2: Color) -> float:
	return (absf(color1.r - color2.r) + absf(color1.g - color2.g) + absf(color1.b - color2.b)) / 3.0

static func recalculate_colors() -> void:
	base_color = Configs.savedata.base_color
	accent_color = Configs.savedata.accent_color
	is_theme_dark = (base_color.get_luminance() < 0.5)
	
	max_contrast_color = Color("#fff") if is_theme_dark else Color("000")
	extreme_theme_color = Color("#000") if is_theme_dark else Color("fff")
	tinted_contrast_color = Color("#def") if is_theme_dark else Color("061728")
	gray_color = Color("808080") if is_theme_dark else Color("666")
	tinted_gray_color = tinted_contrast_color.blend(Color(extreme_theme_color, 0.475))
	black_or_white_counter_accent_color = Color("#000") if accent_color.get_luminance() > 0.625 else Color("fff")
	
	warning_icon_color = Color("fca") if is_theme_dark else Color("96592c")
	info_icon_color = Color("acf") if is_theme_dark else Color("3a6ab0")
	folder_color = Color("88b6dd") if is_theme_dark else Color("528fcc")
	text_file_color = Color("fec") if is_theme_dark else Color("cc9629")
	
	hover_selected_inspector_frame_inner_color = Color.from_hsv(0.625, 0.48, 0.27) if ThemeUtils.is_theme_dark else Color.from_hsv(0.625, 0.27, 0.925)
	hover_selected_inspector_frame_title_color = hover_selected_inspector_frame_inner_color.lerp(max_contrast_color, 0.02)
	selected_inspector_frame_inner_color = Color.from_hsv(0.625, 0.5, 0.25) if ThemeUtils.is_theme_dark else Color.from_hsv(0.625, 0.23, 0.925)
	selected_inspector_frame_title_color = selected_inspector_frame_inner_color.lerp(max_contrast_color, 0.02)
	active_inspector_frame_border_color = Color.from_hsv(0.6, 0.75, 0.8) if ThemeUtils.is_theme_dark else Color.from_hsv(0.6, 0.75, 0.625)
	hover_inspector_frame_inner_color = Color.from_hsv(0.625, 0.57, 0.19) if ThemeUtils.is_theme_dark else Color.from_hsv(0.625, 0.16, 0.9)
	hover_inspector_frame_title_color = hover_inspector_frame_inner_color.lerp(max_contrast_color, 0.02)
	hover_inspector_frame_border_color = Color.from_hsv(0.6, 0.55, 0.45) if ThemeUtils.is_theme_dark else Color.from_hsv(0.6, 0.55, 0.8)
	inspector_frame_inner_color = Color.from_hsv(0.625, 0.6, 0.16) if ThemeUtils.is_theme_dark else Color.from_hsv(0.625, 0.12, 0.9)
	inspector_frame_title_color = inspector_frame_inner_color.lerp(max_contrast_color, 0.02)
	inspector_frame_border_color = Color.from_hsv(0.6, 0.5, 0.35) if ThemeUtils.is_theme_dark else Color.from_hsv(0.6, 0.5, 0.875)
	
	intermediate_color = base_color
	if is_theme_dark:
		intermediate_color.s *= 0.96
		intermediate_color.v = 0.25 + 0.4 * sqrt(intermediate_color.v)
		if is_zero_approx(base_color.s):
			intermediate_color.h = accent_color.h
		elif base_color.h <= 5/6.0 and base_color.h > 1/6.0:
			intermediate_color.h = move_toward(intermediate_color.h, 1/6.0, 0.05)
	else:
		intermediate_color.s = 0.3 + 0.4 * sqrt(intermediate_color.s)
		intermediate_color.v *= 0.92
		if is_zero_approx(base_color.s):
			if not is_zero_approx(accent_color.s):
				intermediate_color.h = accent_color.h
			else:
				intermediate_color.s = 0
				intermediate_color.v *= 0.9
	
	desaturated_color = intermediate_color.lerp(gray_color, 0.3).lerp(extreme_theme_color, 0.08)
	if not is_theme_dark:
		desaturated_color.v *= 0.9
	disabled_color = intermediate_color.lerp(gray_color, 0.8)
	
	soft_base_color = base_color.lerp(max_contrast_color, 0.015 if is_theme_dark else 0.03)
	softer_base_color = base_color.lerp(max_contrast_color, 0.04 if is_theme_dark else 0.08)
	soft_accent_color = accent_color.lerp(extreme_theme_color, 0.1)
	hover_overlay_color = Color(tinted_contrast_color, 0.08)
	pressed_overlay_color = Color(tinted_contrast_color.lerp(soft_accent_color, 0.6), 0.24)
	hover_pressed_overlay_color = hover_overlay_color.blend(pressed_overlay_color)
	
	soft_hover_overlay_color = Color(tinted_contrast_color, 0.06)
	soft_pressed_overlay_color = Color(tinted_contrast_color.lerp(soft_accent_color, 0.4), 0.18)
	var softer_hover_overlay_color := soft_hover_overlay_color
	softer_hover_overlay_color.a *= 0.5
	soft_hover_pressed_overlay_color = softer_hover_overlay_color.blend(soft_pressed_overlay_color)
	
	strong_hover_overlay_color = Color(tinted_contrast_color, 0.12)
	stronger_hover_overlay_color = Color(tinted_contrast_color, 0.16)
	
	intermediate_hover_color = intermediate_color.blend(strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color)
	soft_intermediate_color = intermediate_color.lerp(extreme_theme_color, 0.36 if is_theme_dark else 0.48)
	soft_intermediate_hover_color = soft_intermediate_color.blend(soft_hover_overlay_color if is_theme_dark else hover_overlay_color)
	softer_intermediate_color = intermediate_color.lerp(extreme_theme_color, 0.44)
	if not is_theme_dark:
		softer_intermediate_color.s *= 0.8
	softer_intermediate_hover_color = softer_intermediate_color.blend(soft_hover_overlay_color if is_theme_dark else hover_overlay_color)
	
	text_color = Color(max_contrast_color, 0.875)
	highlighted_text_color = Color(max_contrast_color)
	dim_text_color = Color(max_contrast_color, 0.75)
	dimmer_text_color = Color(max_contrast_color, 0.5)
	subtle_text_color = Color(max_contrast_color, 0.375)
	editable_text_color = tinted_contrast_color
	
	basic_panel_inner_color = softer_base_color
	basic_panel_border_color = base_color.lerp(max_contrast_color, 0.24)
	basic_panel_border_color.s = minf(basic_panel_border_color.s * 2.0, lerpf(basic_panel_border_color.s, 1.0, 0.2))
	subtle_panel_border_color = basic_panel_border_color.lerp(extreme_theme_color, 0.24)
	
	caret_color = Color(tinted_contrast_color, 0.875)
	selection_color = Color(accent_color, 0.375)
	disabled_selection_color = Color(gray_color, 0.4)
	
	common_button_inner_color_pressed = intermediate_color.lerp(accent_color, 0.64).lerp(extreme_theme_color, 0.4)
	common_button_border_color_pressed = intermediate_color.lerp(accent_color, 0.8)
	common_button_inner_color_disabled = desaturated_color.lerp(gray_color, 0.4).lerp(extreme_theme_color, 0.72)
	common_button_border_color_disabled = desaturated_color.lerp(gray_color, 0.4).lerp(extreme_theme_color, 0.56)
	
	context_icon_normal_color = tinted_contrast_color.lerp(extreme_theme_color, 0.2)
	context_icon_hover_color = tinted_contrast_color
	context_icon_pressed_color = max_contrast_color
	
	flat_button_color_disabled = Color(Color.BLACK, maxf(0.16, 0.48 - color_difference(Color.BLACK, basic_panel_inner_color) * 2)) if is_theme_dark\
			else Color(Color.BLACK, 0.055)
	
	subtle_flat_panel_color = base_color
	contrast_flat_panel_color = Color(tinted_contrast_color, 0.1)
	overlay_panel_inner_color = base_color.lerp(extreme_theme_color, 0.1)
	overlay_panel_border_color = base_color.lerp(max_contrast_color, 0.32)
	overlay_panel_border_color.s = minf(overlay_panel_border_color.s * 4.0, lerpf(overlay_panel_border_color.s, 1.0, 0.6))
	overlay_panel_border_color.v = lerpf(overlay_panel_border_color.v, 1.0, 0.125)
	
	scrollbar_pressed_color = intermediate_color.blend(Color(tinted_contrast_color.lerp(accent_color.lerp(max_contrast_color, 0.1), 0.2), 0.4))
	
	focus_color = accent_color
	weak_focus_color = Color(focus_color, 0.72)
	dim_focus_color = Color(accent_color, 0.48)
	
	line_edit_inner_color = desaturated_color.lerp(extreme_theme_color, 0.74)
	line_edit_normal_border_color = desaturated_color.lerp(extreme_theme_color, 0.42 if is_theme_dark else 0.35)
	mini_line_edit_inner_color = desaturated_color.lerp(extreme_theme_color, 0.78)
	mini_line_edit_normal_border_color = desaturated_color.lerp(max_contrast_color, 0.04)
	line_edit_inner_color_disabled = desaturated_color.lerp(gray_color, 0.4).lerp(extreme_theme_color, 0.88)
	line_edit_border_color_disabled = desaturated_color.lerp(gray_color, 0.4).lerp(extreme_theme_color, 0.68)
	
	text_edit_alternative_inner_color = base_color.lerp(extreme_theme_color, 0.2)
	text_edit_alternative_inner_color.s *= 0.6
	
	connected_button_inner_color_hover = line_edit_inner_color.blend(hover_overlay_color)
	connected_button_border_color_hover = line_edit_normal_border_color.blend(strong_hover_overlay_color)
	connected_button_inner_color_pressed = line_edit_inner_color.lerp(common_button_inner_color_pressed, 0.8)
	connected_button_border_color_pressed = line_edit_normal_border_color.lerp(common_button_border_color_pressed, 0.6)
	
	selected_tab_color = softer_intermediate_hover_color.lerp(accent_color, 0.2)
	selected_tab_border_color = Color(accent_color, 0.88)

static func rebuild_fonts() -> void:
	main_font.base_font = FontFile.new()
	if not Configs.savedata.main_font_path.is_empty():
		main_font.base_font.load_dynamic_font(Configs.savedata.main_font_path)
	
	bold_font.base_font = FontFile.new()
	if not Configs.savedata.bold_font_path.is_empty():
		bold_font.base_font.load_dynamic_font(Configs.savedata.bold_font_path)
	
	mono_font.base_font = FontFile.new()
	if not Configs.savedata.mono_font_path.is_empty():
		mono_font.base_font.load_dynamic_font(Configs.savedata.mono_font_path)

static func generate_theme() -> Theme:
	recalculate_colors()
	var theme := Theme.new()
	theme.default_font = main_font
	theme.default_font_size = 13
	_setup_panelcontainer(theme)
	_setup_button(theme)
	_setup_context_button(theme)
	_setup_checkbox(theme)
	_setup_checkbutton(theme)
	_setup_dropdown(theme)
	_setup_itemlist(theme)
	_setup_lineedit(theme)
	_setup_scrollbar(theme)
	_setup_separator(theme)
	_setup_label(theme)
	_setup_tabcontainer(theme)
	_setup_textedit(theme)
	_setup_tooltip(theme)
	_setup_splitcontainer(theme)
	return theme

static func generate_and_apply_theme() -> void:
	var default_theme := ThemeDB.get_default_theme()
	default_theme.default_font = main_font
	default_theme.default_font_size = 13
	var generated_theme := generate_theme()
	default_theme.merge_with(generated_theme)


static func _setup_panelcontainer(theme: Theme) -> void:
	theme.add_type("PanelContainer")
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.set_border_width_all(2)
	stylebox.content_margin_left = 2.0
	stylebox.content_margin_right = 2.0
	stylebox.bg_color = basic_panel_inner_color
	stylebox.border_color = basic_panel_border_color
	theme.set_stylebox("panel", "PanelContainer", stylebox)
	
	theme.add_type("SpaciousPanel")
	theme.set_type_variation("SpaciousPanel", "PanelContainer")
	var spacious_stylebox := stylebox.duplicate()
	spacious_stylebox.content_margin_left = 10.0
	spacious_stylebox.content_margin_right = 10.0
	spacious_stylebox.content_margin_top = 4.0
	spacious_stylebox.content_margin_bottom = 8.0
	theme.set_stylebox("panel", "SpaciousPanel", spacious_stylebox)
	
	theme.add_type("Window")
	theme.set_stylebox("embedded_border", "Window", stylebox)
	
	theme.add_type("AcceptDialog")
	theme.set_stylebox("panel", "AcceptDialog", spacious_stylebox)
	
	theme.add_type("SubtleFlatPanel")
	theme.set_type_variation("SubtleFlatPanel", "PanelContainer")
	var subtle_panel_stylebox := StyleBoxFlat.new()
	subtle_panel_stylebox.set_corner_radius_all(3)
	subtle_panel_stylebox.content_margin_left = 4.0
	subtle_panel_stylebox.content_margin_right = 4.0
	subtle_panel_stylebox.content_margin_top = 2.0
	subtle_panel_stylebox.content_margin_bottom = 2.0
	subtle_panel_stylebox.bg_color = subtle_flat_panel_color
	theme.set_stylebox("panel", "SubtleFlatPanel", subtle_panel_stylebox)
	
	theme.add_type("ContrastFlatPanel")
	theme.set_type_variation("ContrastFlatPanel", "PanelContainer")
	var contrast_panel_stylebox := StyleBoxFlat.new()
	contrast_panel_stylebox.set_corner_radius_all(5)
	contrast_panel_stylebox.content_margin_left = 4.0
	contrast_panel_stylebox.content_margin_right = 4.0
	contrast_panel_stylebox.content_margin_top = 2.0
	contrast_panel_stylebox.content_margin_bottom = 2.0
	contrast_panel_stylebox.bg_color = contrast_flat_panel_color
	theme.set_stylebox("panel", "ContrastFlatPanel", contrast_panel_stylebox)
	
	theme.add_type("OutlinedPanel")
	theme.set_type_variation("OutlinedPanel", "PanelContainer")
	var outlined_panel_stylebox := StyleBoxFlat.new()
	outlined_panel_stylebox.set_corner_radius_all(2)
	outlined_panel_stylebox.set_border_width_all(2)
	outlined_panel_stylebox.set_expand_margin_all(2.0)
	outlined_panel_stylebox.set_content_margin_all(0.0)
	outlined_panel_stylebox.bg_color = Color.TRANSPARENT
	outlined_panel_stylebox.border_color = overlay_panel_border_color
	theme.set_stylebox("panel", "OutlinedPanel", outlined_panel_stylebox)
	
	theme.add_type("OverlayPanel")
	theme.set_type_variation("OverlayPanel", "PanelContainer")
	var overlay_stylebox := StyleBoxFlat.new()
	overlay_stylebox.set_corner_radius_all(2)
	overlay_stylebox.set_border_width_all(2)
	overlay_stylebox.content_margin_left = 10.0
	overlay_stylebox.content_margin_right = 10.0
	overlay_stylebox.content_margin_top = 6.0
	overlay_stylebox.content_margin_bottom = 10.0
	overlay_stylebox.bg_color = overlay_panel_inner_color
	overlay_stylebox.border_color = overlay_panel_border_color
	theme.set_stylebox("panel", "OverlayPanel", overlay_stylebox)
	
	theme.add_type("TextBox")
	theme.set_type_variation("TextBox", "PanelContainer")
	var textbox_stylebox := StyleBoxFlat.new()
	textbox_stylebox.set_corner_radius_all(2)
	textbox_stylebox.set_border_width_all(2)
	textbox_stylebox.bg_color = overlay_panel_inner_color.lerp(extreme_theme_color, 0.2)
	textbox_stylebox.border_color = subtle_panel_border_color
	theme.set_stylebox("panel", "TextBox", textbox_stylebox)

static func _setup_button(theme: Theme) -> void:
	theme.add_type("Button")
	theme.set_constant("h_separation", "Button", 5)
	theme.set_color("font_color", "Button", text_color)
	theme.set_color("font_disabled_color", "Button", subtle_text_color)
	theme.set_color("font_focus_color", "Button", highlighted_text_color)
	theme.set_color("font_hover_color", "Button", highlighted_text_color)
	theme.set_color("font_pressed_color", "Button", highlighted_text_color)
	theme.set_color("font_hover_pressed_color", "Button", highlighted_text_color)
	theme.set_color("icon_normal_color", "Button", tinted_contrast_color)
	theme.set_color("icon_hover_color", "Button", tinted_contrast_color)
	theme.set_color("icon_pressed_color", "Button", max_contrast_color)
	theme.set_color("icon_hover_pressed_color", "Button", max_contrast_color)
	theme.set_color("icon_focus_color", "Button", max_contrast_color)
	theme.set_color("icon_disabled_color", "Button", tinted_gray_color)
	var button_stylebox := StyleBoxFlat.new()
	button_stylebox.set_corner_radius_all(5)
	button_stylebox.set_border_width_all(2)
	button_stylebox.content_margin_bottom = 3.0
	button_stylebox.content_margin_top = 3.0
	button_stylebox.content_margin_left = 6.0
	button_stylebox.content_margin_right = 6.0
	
	var normal_button_stylebox := button_stylebox.duplicate()
	normal_button_stylebox.bg_color = soft_intermediate_color
	normal_button_stylebox.border_color = intermediate_color
	theme.set_stylebox("normal", "Button", normal_button_stylebox)
	
	var hover_button_stylebox := button_stylebox.duplicate()
	hover_button_stylebox.bg_color = soft_intermediate_hover_color
	hover_button_stylebox.border_color = intermediate_hover_color
	theme.set_stylebox("hover", "Button", hover_button_stylebox)
	
	var pressed_button_stylebox := button_stylebox.duplicate()
	pressed_button_stylebox.bg_color = common_button_inner_color_pressed
	pressed_button_stylebox.border_color = common_button_border_color_pressed
	theme.set_stylebox("pressed", "Button", pressed_button_stylebox)
	
	var hover_pressed_button_stylebox := button_stylebox.duplicate()
	hover_pressed_button_stylebox.bg_color = common_button_inner_color_pressed.blend(hover_overlay_color)
	hover_pressed_button_stylebox.border_color = common_button_border_color_pressed.blend(hover_overlay_color)
	theme.set_stylebox("hover_pressed", "Button", hover_pressed_button_stylebox)
	
	var disabled_button_stylebox := button_stylebox.duplicate()
	disabled_button_stylebox.bg_color = common_button_inner_color_disabled
	disabled_button_stylebox.border_color = common_button_border_color_disabled
	theme.set_stylebox("disabled", "Button", disabled_button_stylebox)
	
	var button_focus_stylebox := button_stylebox.duplicate()
	button_focus_stylebox.draw_center = false
	button_focus_stylebox.border_color = focus_color
	theme.set_stylebox("focus", "Button", button_focus_stylebox)
	
	theme.add_type("IconButton")
	theme.set_type_variation("IconButton", "Button")
	
	var normal_icon_button_stylebox := normal_button_stylebox.duplicate()
	normal_icon_button_stylebox.set_content_margin_all(4)
	theme.set_stylebox("normal", "IconButton", normal_icon_button_stylebox)
	
	var hover_icon_button_stylebox := hover_button_stylebox.duplicate()
	hover_icon_button_stylebox.set_content_margin_all(4)
	theme.set_stylebox("hover", "IconButton", hover_icon_button_stylebox)
	
	var pressed_icon_button_stylebox := pressed_button_stylebox.duplicate()
	pressed_icon_button_stylebox.set_content_margin_all(4)
	theme.set_stylebox("pressed", "IconButton", pressed_icon_button_stylebox)
	
	var hover_pressed_icon_button_stylebox := hover_pressed_button_stylebox.duplicate()
	hover_pressed_icon_button_stylebox.set_content_margin_all(4)
	theme.set_stylebox("hover_pressed", "IconButton", hover_pressed_icon_button_stylebox)
	
	var disabled_icon_button_stylebox := disabled_button_stylebox.duplicate()
	disabled_icon_button_stylebox.set_content_margin_all(4)
	theme.set_stylebox("disabled", "IconButton", disabled_icon_button_stylebox)
	
	theme.add_type("LeftConnectedButton")
	theme.set_type_variation("LeftConnectedButton", "Button")
	theme.set_color("icon_normal_color", "LeftConnectedButton", context_icon_normal_color)
	theme.set_color("icon_hover_color", "LeftConnectedButton", context_icon_hover_color)
	var left_connected_button_stylebox := StyleBoxFlat.new()
	left_connected_button_stylebox.corner_radius_bottom_left = 0
	left_connected_button_stylebox.corner_radius_top_left = 0
	left_connected_button_stylebox.corner_radius_bottom_right = 5
	left_connected_button_stylebox.corner_radius_top_right = 5
	left_connected_button_stylebox.border_width_left = 1
	left_connected_button_stylebox.border_width_right = 2
	left_connected_button_stylebox.border_width_top = 2
	left_connected_button_stylebox.border_width_bottom = 2
	left_connected_button_stylebox.content_margin_bottom = 4.0
	left_connected_button_stylebox.content_margin_top = 4.0
	left_connected_button_stylebox.content_margin_left = 4.0
	left_connected_button_stylebox.content_margin_right = 5.0
	
	var normal_left_connected_button_stylebox := left_connected_button_stylebox.duplicate()
	normal_left_connected_button_stylebox.bg_color = line_edit_inner_color
	normal_left_connected_button_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LeftConnectedButton", normal_left_connected_button_stylebox)
	# Disabled theme is not currently used, but is needed for correct spacing.
	theme.set_stylebox("disabled", "LeftConnectedButton", normal_left_connected_button_stylebox)
	
	var hover_left_connected_button_stylebox := left_connected_button_stylebox.duplicate()
	hover_left_connected_button_stylebox.bg_color = connected_button_inner_color_hover
	hover_left_connected_button_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "LeftConnectedButton", hover_left_connected_button_stylebox)
	
	var pressed_left_connected_button_stylebox := left_connected_button_stylebox.duplicate()
	pressed_left_connected_button_stylebox.bg_color = connected_button_inner_color_pressed
	pressed_left_connected_button_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "LeftConnectedButton", pressed_left_connected_button_stylebox)
	
	var hover_pressed_left_connected_button_stylebox := left_connected_button_stylebox.duplicate()
	hover_pressed_left_connected_button_stylebox.bg_color = connected_button_inner_color_pressed.blend(hover_overlay_color)
	hover_pressed_left_connected_button_stylebox.border_color = connected_button_border_color_pressed.blend(hover_overlay_color)
	theme.set_stylebox("hover_pressed", "LeftConnectedButton", hover_pressed_left_connected_button_stylebox)
	
	var left_connected_button_focus_stylebox := left_connected_button_stylebox.duplicate()
	left_connected_button_focus_stylebox.draw_center = false
	left_connected_button_focus_stylebox.border_color = focus_color
	theme.set_stylebox("focus", "LeftConnectedButton", left_connected_button_focus_stylebox)
	
	theme.add_type("LeftConnectedButtonTransparent")
	theme.set_type_variation("LeftConnectedButtonTransparent", "Button")
	var left_connected_button_transparent_stylebox := StyleBoxFlat.new()
	left_connected_button_transparent_stylebox.corner_radius_bottom_left = 0
	left_connected_button_transparent_stylebox.corner_radius_top_left = 0
	left_connected_button_transparent_stylebox.corner_radius_bottom_right = 5
	left_connected_button_transparent_stylebox.corner_radius_top_right = 5
	left_connected_button_transparent_stylebox.border_width_left = 1
	left_connected_button_transparent_stylebox.border_width_right = 2
	left_connected_button_transparent_stylebox.border_width_top = 2
	left_connected_button_transparent_stylebox.border_width_bottom = 2
	
	var normal_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	normal_left_connected_button_transparent_stylebox.draw_center = false
	normal_left_connected_button_transparent_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LeftConnectedButtonTransparent", normal_left_connected_button_transparent_stylebox)
	
	var hover_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	hover_left_connected_button_transparent_stylebox.draw_center = false
	hover_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "LeftConnectedButtonTransparent", hover_left_connected_button_transparent_stylebox)
	
	var pressed_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	pressed_left_connected_button_transparent_stylebox.draw_center = false
	pressed_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "LeftConnectedButtonTransparent", pressed_left_connected_button_transparent_stylebox)
	
	var hover_pressed_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	hover_pressed_left_connected_button_transparent_stylebox.draw_center = false
	hover_pressed_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed.blend(hover_overlay_color)
	theme.set_stylebox("hover_pressed", "LeftConnectedButtonTransparent", hover_pressed_left_connected_button_transparent_stylebox)
	
	theme.add_type("RightConnectedButton")
	theme.set_type_variation("RightConnectedButton", "Button")
	theme.set_color("icon_normal_color", "RightConnectedButton", context_icon_normal_color)
	theme.set_color("icon_hover_color", "RightConnectedButton", context_icon_hover_color)
	var right_connected_button_stylebox := StyleBoxFlat.new()
	right_connected_button_stylebox.corner_radius_bottom_left = 5
	right_connected_button_stylebox.corner_radius_top_left = 5
	right_connected_button_stylebox.corner_radius_bottom_right = 0
	right_connected_button_stylebox.corner_radius_top_right = 0
	right_connected_button_stylebox.border_width_left = 2
	right_connected_button_stylebox.border_width_right = 1
	right_connected_button_stylebox.border_width_top = 2
	right_connected_button_stylebox.border_width_bottom = 2
	right_connected_button_stylebox.content_margin_bottom = 4.0
	right_connected_button_stylebox.content_margin_top = 4.0
	right_connected_button_stylebox.content_margin_left = 5.0
	right_connected_button_stylebox.content_margin_right = 4.0
	
	var normal_right_connected_button_stylebox := right_connected_button_stylebox.duplicate()
	normal_right_connected_button_stylebox.bg_color = line_edit_inner_color
	normal_right_connected_button_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "RightConnectedButton", normal_right_connected_button_stylebox)
	# Disabled theme is not currently used, but is needed for correct spacing.
	theme.set_stylebox("disabled", "RightConnectedButton", normal_right_connected_button_stylebox)
	
	var hover_right_connected_button_stylebox := right_connected_button_stylebox.duplicate()
	hover_right_connected_button_stylebox.bg_color = connected_button_inner_color_hover
	hover_right_connected_button_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "RightConnectedButton", hover_right_connected_button_stylebox)
	
	var pressed_right_connected_button_stylebox := right_connected_button_stylebox.duplicate()
	pressed_right_connected_button_stylebox.bg_color = connected_button_inner_color_pressed
	pressed_right_connected_button_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "RightConnectedButton", pressed_right_connected_button_stylebox)
	
	var hover_pressed_right_connected_button_stylebox := right_connected_button_stylebox.duplicate()
	hover_pressed_right_connected_button_stylebox.bg_color = connected_button_inner_color_pressed.blend(hover_overlay_color)
	hover_pressed_right_connected_button_stylebox.border_color = connected_button_border_color_pressed.blend(hover_overlay_color)
	theme.set_stylebox("hover_pressed", "RightConnectedButton", hover_pressed_right_connected_button_stylebox)
	
	var right_connected_button_focus_stylebox := right_connected_button_stylebox.duplicate()
	right_connected_button_focus_stylebox.draw_center = false
	right_connected_button_focus_stylebox.border_color = focus_color
	theme.set_stylebox("focus", "RightConnectedButton", right_connected_button_focus_stylebox)
	
	theme.add_type("RightConnectedButtonTransparent")
	theme.set_type_variation("RightConnectedButtonTransparent", "Button")
	var right_connected_button_transparent_stylebox := StyleBoxFlat.new()
	right_connected_button_transparent_stylebox.corner_radius_bottom_left = 5
	right_connected_button_transparent_stylebox.corner_radius_top_left = 5
	right_connected_button_transparent_stylebox.corner_radius_bottom_right = 0
	right_connected_button_transparent_stylebox.corner_radius_top_right = 0
	right_connected_button_transparent_stylebox.border_width_left = 2
	right_connected_button_transparent_stylebox.border_width_right = 1
	right_connected_button_transparent_stylebox.border_width_top = 2
	right_connected_button_transparent_stylebox.border_width_bottom = 2
	
	var normal_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	normal_right_connected_button_transparent_stylebox.draw_center = false
	normal_right_connected_button_transparent_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "RightConnectedButtonTransparent", normal_right_connected_button_transparent_stylebox)
	
	var hover_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	hover_right_connected_button_transparent_stylebox.draw_center = false
	hover_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "RightConnectedButtonTransparent", hover_right_connected_button_transparent_stylebox)
	
	var pressed_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	pressed_right_connected_button_transparent_stylebox.draw_center = false
	pressed_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "RightConnectedButtonTransparent", pressed_right_connected_button_transparent_stylebox)
	
	var hover_pressed_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	hover_pressed_right_connected_button_transparent_stylebox.draw_center = false
	hover_pressed_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed.blend(hover_overlay_color)
	theme.set_stylebox("hover_pressed", "RightConnectedButtonTransparent", hover_pressed_right_connected_button_transparent_stylebox)
	
	theme.add_type("TranslucentButton")
	theme.set_type_variation("TranslucentButton", "Button")
	theme.set_color("icon_normal_color", "TranslucentButton", context_icon_normal_color)
	theme.set_color("icon_hover_color", "TranslucentButton", context_icon_hover_color)
	theme.set_color("icon_pressed_color", "TranslucentButton", context_icon_pressed_color)
	
	var normal_translucent_button_stylebox := StyleBoxFlat.new()
	normal_translucent_button_stylebox.set_corner_radius_all(5)
	normal_translucent_button_stylebox.set_content_margin_all(4)
	normal_translucent_button_stylebox.bg_color = hover_overlay_color
	theme.set_stylebox("normal", "TranslucentButton", normal_translucent_button_stylebox)
	
	var hover_translucent_button_stylebox := normal_translucent_button_stylebox.duplicate()
	hover_translucent_button_stylebox.bg_color = stronger_hover_overlay_color
	theme.set_stylebox("hover", "TranslucentButton", hover_translucent_button_stylebox)
	
	var pressed_translucent_button_stylebox := normal_translucent_button_stylebox.duplicate()
	pressed_translucent_button_stylebox.bg_color = hover_pressed_overlay_color
	theme.set_stylebox("pressed", "TranslucentButton", pressed_translucent_button_stylebox)
	
	var disabled_translucent_button_stylebox := normal_translucent_button_stylebox.duplicate()
	disabled_translucent_button_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "TranslucentButton", disabled_translucent_button_stylebox)
	
	theme.add_type("FlatButton")
	theme.set_type_variation("FlatButton", "Button")
	theme.set_color("icon_normal_color", "FlatButton", context_icon_normal_color)
	theme.set_color("icon_hover_color", "FlatButton", context_icon_hover_color)
	theme.set_color("icon_pressed_color", "FlatButton", context_icon_pressed_color)
	theme.set_color("icon_hover_pressed_color", "FlatButton", context_icon_pressed_color)
	
	var flat_button_stylebox := StyleBoxFlat.new()
	flat_button_stylebox.set_corner_radius_all(3)
	flat_button_stylebox.set_content_margin_all(2)
	
	var normal_flat_button_stylebox := StyleBoxEmpty.new()
	normal_flat_button_stylebox.set_content_margin_all(2)
	theme.set_stylebox("normal", "FlatButton", normal_flat_button_stylebox)
	
	var hover_flat_button_stylebox := flat_button_stylebox.duplicate()
	hover_flat_button_stylebox.bg_color = hover_overlay_color
	theme.set_stylebox("hover", "FlatButton", hover_flat_button_stylebox)
	
	var pressed_flat_button_stylebox := flat_button_stylebox.duplicate()
	pressed_flat_button_stylebox.bg_color = pressed_overlay_color
	theme.set_stylebox("pressed", "FlatButton", pressed_flat_button_stylebox)
	theme.set_stylebox("hover_pressed", "FlatButton", pressed_flat_button_stylebox)
	
	var disabled_flat_button_stylebox := flat_button_stylebox.duplicate()
	disabled_flat_button_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "FlatButton", disabled_flat_button_stylebox)
	
	var flat_button_focus_stylebox := flat_button_stylebox.duplicate()
	flat_button_focus_stylebox.set_border_width_all(2)
	flat_button_focus_stylebox.draw_center = false
	flat_button_focus_stylebox.border_color = focus_color
	theme.set_stylebox("focus", "FlatButton", flat_button_focus_stylebox)
	
	theme.add_type("PathCommandAbsoluteButton")
	theme.set_type_variation("PathCommandAbsoluteButton", "Button")
	var path_command_absolute_button_stylebox_normal := StyleBoxFlat.new()
	path_command_absolute_button_stylebox_normal.set_border_width_all(2)
	path_command_absolute_button_stylebox_normal.set_corner_radius_all(4)
	path_command_absolute_button_stylebox_normal.content_margin_left = 5.0
	path_command_absolute_button_stylebox_normal.content_margin_right = 5.0
	path_command_absolute_button_stylebox_normal.content_margin_top = 0.0
	path_command_absolute_button_stylebox_normal.content_margin_bottom = 0.0
	path_command_absolute_button_stylebox_normal.bg_color = Color("cc7a29") if ThemeUtils.is_theme_dark else Color("f2cb91")
	path_command_absolute_button_stylebox_normal.border_color = Color("e6ae5c") if ThemeUtils.is_theme_dark else Color("ffaa33")
	theme.set_stylebox("normal", "PathCommandAbsoluteButton", path_command_absolute_button_stylebox_normal)
	theme.set_stylebox("disabled", "PathCommandAbsoluteButton", path_command_absolute_button_stylebox_normal)

	var path_command_absolute_button_stylebox_hover := path_command_absolute_button_stylebox_normal.duplicate()
	path_command_absolute_button_stylebox_hover.bg_color = Color("d9822b") if ThemeUtils.is_theme_dark else Color("f2c279")
	path_command_absolute_button_stylebox_hover.border_color = Color("f2cb91") if ThemeUtils.is_theme_dark else Color("f29718")
	theme.set_stylebox("hover", "PathCommandAbsoluteButton", path_command_absolute_button_stylebox_hover)

	var path_command_absolute_button_stylebox_pressed := path_command_absolute_button_stylebox_normal.duplicate()
	path_command_absolute_button_stylebox_pressed.bg_color = Color("ffbf40") if ThemeUtils.is_theme_dark else Color("f2ae49")
	path_command_absolute_button_stylebox_pressed.border_color = Color("ffecb3") if ThemeUtils.is_theme_dark else Color("e68600")
	theme.set_stylebox("pressed", "PathCommandAbsoluteButton", path_command_absolute_button_stylebox_pressed)

	theme.add_type("PathCommandRelativeButton")
	theme.set_type_variation("PathCommandRelativeButton", "Button")
	var path_command_relative_button_stylebox_normal := path_command_absolute_button_stylebox_normal.duplicate()
	path_command_relative_button_stylebox_normal.bg_color = Color("a329cc") if ThemeUtils.is_theme_dark else Color("d291f2")
	path_command_relative_button_stylebox_normal.border_color = Color("bd73e6") if ThemeUtils.is_theme_dark else Color("bb33ff")
	theme.set_stylebox("normal", "PathCommandRelativeButton", path_command_relative_button_stylebox_normal)
	theme.set_stylebox("disabled", "PathCommandRelativeButton", path_command_relative_button_stylebox_normal)

	var path_command_relative_button_stylebox_hover := path_command_absolute_button_stylebox_normal.duplicate()
	path_command_relative_button_stylebox_hover.bg_color = Color("ad2bd9") if ThemeUtils.is_theme_dark else Color("ca79f2")
	path_command_relative_button_stylebox_hover.border_color = Color("d291f2") if ThemeUtils.is_theme_dark else Color("aa18f2")
	theme.set_stylebox("hover", "PathCommandRelativeButton", path_command_relative_button_stylebox_hover)

	var path_command_relative_button_stylebox_pressed := path_command_absolute_button_stylebox_normal.duplicate()
	path_command_relative_button_stylebox_pressed.bg_color = Color("bf40ff") if ThemeUtils.is_theme_dark else Color("ba49f2")
	path_command_relative_button_stylebox_pressed.border_color = Color("dfb3ff") if ThemeUtils.is_theme_dark else Color("9900e6")
	theme.set_stylebox("pressed", "PathCommandRelativeButton", path_command_relative_button_stylebox_pressed)
	
	theme.add_type("TextButton")
	theme.set_type_variation("TextButton", "Button")
	theme.set_color("font_color", "TextButton", dimmer_text_color)
	theme.set_color("font_hover_color", "TextButton", dim_text_color)
	theme.set_color("font_pressed_color", "TextButton", text_color)
	theme.set_color("font_hover_pressed_color", "TextButton", highlighted_text_color)
	var text_button_empty_stylebox := StyleBoxEmpty.new()
	text_button_empty_stylebox.content_margin_left = 2.0
	text_button_empty_stylebox.content_margin_right = 2.0
	theme.set_stylebox("normal", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("hover", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("pressed", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("hover_pressed", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("disabled", "TextButton", text_button_empty_stylebox)
	
	theme.add_type("SideTab")
	theme.set_type_variation("SideTab", "Button")
	
	var normal_sidetab_stylebox := StyleBoxFlat.new()
	normal_sidetab_stylebox.bg_color = softer_intermediate_color
	normal_sidetab_stylebox.corner_radius_top_left = 4
	normal_sidetab_stylebox.corner_radius_bottom_left = 4
	normal_sidetab_stylebox.content_margin_left = 6.0
	normal_sidetab_stylebox.content_margin_right = 6.0
	normal_sidetab_stylebox.content_margin_bottom = 3.0
	normal_sidetab_stylebox.content_margin_top = 3.0
	theme.set_stylebox("normal", "SideTab", normal_sidetab_stylebox)
	
	var hovered_sidetab_stylebox := normal_sidetab_stylebox.duplicate()
	hovered_sidetab_stylebox.bg_color = softer_intermediate_hover_color
	theme.set_stylebox("hover", "SideTab", hovered_sidetab_stylebox)
	
	var pressed_sidetab_stylebox := StyleBoxFlat.new()
	pressed_sidetab_stylebox.bg_color = selected_tab_color
	pressed_sidetab_stylebox.border_color = selected_tab_border_color
	pressed_sidetab_stylebox.border_width_left = 2
	pressed_sidetab_stylebox.content_margin_left = 10.0
	pressed_sidetab_stylebox.content_margin_right = 6.0
	pressed_sidetab_stylebox.content_margin_bottom = 3.0
	pressed_sidetab_stylebox.content_margin_top = 3.0
	theme.set_stylebox("pressed", "SideTab", pressed_sidetab_stylebox)
	theme.set_stylebox("hover_pressed", "SideTab", pressed_sidetab_stylebox)
	
	theme.add_type("Swatch")
	theme.set_type_variation("Swatch", "Button")
	var swatch_stylebox := StyleBoxFlat.new()
	swatch_stylebox.set_corner_radius_all(3)
	
	var normal_swatch_stylebox := swatch_stylebox.duplicate()
	normal_swatch_stylebox.bg_color = intermediate_color
	theme.set_stylebox("normal", "Swatch", normal_swatch_stylebox)
	
	var hover_swatch_stylebox := swatch_stylebox.duplicate()
	hover_swatch_stylebox.bg_color = intermediate_color.blend(stronger_hover_overlay_color)
	theme.set_stylebox("hover", "Swatch", hover_swatch_stylebox)
	
	var swatch_focus_stylebox := swatch_stylebox.duplicate()
	swatch_focus_stylebox.draw_center = false
	swatch_focus_stylebox.border_color = focus_color
	swatch_focus_stylebox.set_border_width_all(2)
	theme.set_stylebox("focus", "Swatch", swatch_focus_stylebox)
	
	var pressed_swatch_stylebox := swatch_stylebox.duplicate()
	pressed_swatch_stylebox.bg_color = common_button_border_color_pressed
	theme.set_stylebox("pressed", "Swatch", pressed_swatch_stylebox)
	theme.set_stylebox("disabled", "Swatch", pressed_swatch_stylebox)

static func _setup_context_button(theme: Theme) -> void:
	theme.add_type("ContextButton")
	theme.set_type_variation("ContextButton", "Control")
	theme.set_color("icon_color", "ContextButton", context_icon_normal_color)
	theme.set_color("icon_disabled_color", "ContextButton", tinted_gray_color)
	theme.set_color("icon_focus_color", "ContextButton", context_icon_pressed_color)
	theme.set_color("font_color", "ContextButton", text_color)
	theme.set_color("font_disabled_color", "ContextButton", subtle_text_color)
	theme.set_color("font_focus_color", "ContextButton", highlighted_text_color)
	
	var context_button_stylebox := StyleBoxFlat.new()
	context_button_stylebox.set_corner_radius_all(3)
	
	var hover_context_button_stylebox := context_button_stylebox.duplicate()
	hover_context_button_stylebox.bg_color = stronger_hover_overlay_color
	theme.set_stylebox("focus", "ContextButton", hover_context_button_stylebox)
	
	var disabled_context_button_stylebox := context_button_stylebox.duplicate()
	disabled_context_button_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "ContextButton", disabled_context_button_stylebox)

static func _setup_checkbox(theme: Theme) -> void:
	theme.add_type("CheckBox")
	theme.set_constant("h_separation", "CheckBox", 5)
	theme.set_color("font_color", "CheckBox", text_color)
	theme.set_color("font_disabled_color", "CheckBox", subtle_text_color)
	theme.set_color("font_focus_color", "CheckBox", text_color)
	theme.set_color("font_hover_color", "CheckBox", highlighted_text_color)
	theme.set_color("font_pressed_color", "CheckBox", text_color)
	theme.set_color("font_hover_pressed_color", "CheckBox", highlighted_text_color)
	theme.set_icon("checked", "CheckBox", DPITexture.create_from_string(
		"""<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
			<rect x="1" y="1" rx="2.5" height="14" width="14" fill="#%s"/>
			<path d="M11.5 3.7 5.9 9.3 4.2 7.6 2.7 9.1l3.2 3.2L13 5.2z" fill="#%s"/>
		</svg>""" % [soft_accent_color.to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	theme.set_icon("checked_disabled", "CheckBox", DPITexture.create_from_string(
		"""<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
			<g opacity=".4">
				<rect x="1" y="1" rx="2.5" height="14" width="14" fill="#%s"/>
				<path d="M11.5 3.7 5.9 9.3 4.2 7.6 2.7 9.1l3.2 3.2L13 5.2z" fill="#%s"/>
			</g>
		</svg>""" % [soft_accent_color.lerp(gray_color, 0.2).to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	theme.set_icon("unchecked", "CheckBox", DPITexture.create_from_string(
		"""<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
			<rect x="1" y="1" rx="2.5" height="14" width="14" fill="#%s" opacity=".6"/>
		</svg>""" % gray_color.to_html(false))
	)
	theme.set_icon("unchecked_disabled", "CheckBox", DPITexture.create_from_string(
		"""<svg height="16" width="16" xmlns="http://www.w3.org/2000/svg">
			<rect x="1" y="1" rx="2.5" width="14" height="14" fill="#%s" opacity=".2"/>
		</svg>""" % gray_color.to_html(false))
	)
	
	var checkbox_stylebox := StyleBoxFlat.new()
	checkbox_stylebox.set_corner_radius_all(4)
	checkbox_stylebox.content_margin_bottom = 2.0
	checkbox_stylebox.content_margin_top = 2.0
	checkbox_stylebox.content_margin_left = 3.0
	checkbox_stylebox.content_margin_right = 3.0
	
	var empty_checkbox_stylebox := StyleBoxEmpty.new()
	empty_checkbox_stylebox.content_margin_bottom = 2.0
	empty_checkbox_stylebox.content_margin_top = 2.0
	empty_checkbox_stylebox.content_margin_left = 3.0
	empty_checkbox_stylebox.content_margin_right = 3.0
	theme.set_stylebox("normal", "CheckBox", empty_checkbox_stylebox)
	theme.set_stylebox("pressed", "CheckBox", empty_checkbox_stylebox)
	
	var hover_checkbox_stylebox := checkbox_stylebox.duplicate()
	hover_checkbox_stylebox.bg_color = hover_overlay_color
	theme.set_stylebox("hover", "CheckBox", hover_checkbox_stylebox)
	theme.set_stylebox("hover_pressed", "CheckBox", hover_checkbox_stylebox)
	
	var disabled_checkbox_stylebox := checkbox_stylebox.duplicate()
	disabled_checkbox_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "CheckBox", disabled_checkbox_stylebox)
	
	var focus_stylebox := StyleBoxFlat.new()
	focus_stylebox.set_corner_radius_all(4)
	focus_stylebox.set_border_width_all(2)
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = weak_focus_color
	theme.set_stylebox("focus", "CheckBox", focus_stylebox)

static func _setup_checkbutton(theme: Theme) -> void:
	theme.add_type("CheckButton")
	theme.set_color("font_color", "CheckButton", text_color)
	theme.set_color("font_disabled_color", "CheckButton", subtle_text_color)
	theme.set_color("font_focus_color", "CheckButton", text_color)
	theme.set_color("font_hover_color", "CheckButton", highlighted_text_color)
	theme.set_color("font_pressed_color", "CheckButton", text_color)
	theme.set_color("font_hover_pressed_color", "CheckButton", highlighted_text_color)
	theme.set_icon("checked", "CheckButton", DPITexture.create_from_string(
		"""<svg width="32" height="16" xmlns="http://www.w3.org/2000/svg">
			<rect height="14" width="30" rx="7" x="1" y="1" fill="#%s"/>
			<circle cx="24" cy="8" r="5.5" fill="#%s"/>
		</svg>""" % [soft_accent_color.to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	theme.set_icon("checked_disabled", "CheckButton", DPITexture.create_from_string(
		"""<svg width="32" height="16" xmlns="http://www.w3.org/2000/svg">
			<g opacity=".6">
				<rect height="14" width="30" rx="7" x="1" y="1" fill="#%s"/>
				<circle cx="24" cy="8" r="5.5" fill="#%s"/>
			</g>
		</svg>""" % [soft_accent_color.lerp(gray_color, 0.2).to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	theme.set_icon("unchecked", "CheckButton", DPITexture.create_from_string(
		"""<svg width="32" height="16" xmlns="http://www.w3.org/2000/svg">
			<rect height="14" width="30" rx="7" x="1" y="1" fill="#%s" opacity=".6"/>
			<circle cx="8" cy="8" r="5.5" fill="#%s"/>
		</svg>""" % [gray_color.to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	theme.set_icon("unchecked_disabled", "CheckButton", DPITexture.create_from_string(
		"""<svg width="32" height="16" xmlns="http://www.w3.org/2000/svg">
			<rect height="14" width="30" rx="7" x="1" y="1" fill="#%s" opacity=".2"/>
			<circle cx="8" cy="8" r="5.5" fill="#%s" opacity=".6"/>
		</svg>""" % [gray_color.to_html(false), black_or_white_counter_accent_color.to_html(false)])
	)
	var focus_stylebox := StyleBoxFlat.new()
	focus_stylebox.set_corner_radius_all(4)
	focus_stylebox.set_border_width_all(2)
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = weak_focus_color
	theme.set_stylebox("focus", "CheckButton", focus_stylebox)

static func _setup_itemlist(theme: Theme) -> void:
	# TODO Keep track of https://github.com/godotengine/godot/issues/56045
	theme.add_type("ItemList")
	theme.set_color("font_color", "ItemList", text_color)
	theme.set_color("font_hovered_color", "ItemList", highlighted_text_color)
	theme.set_color("font_selected_color", "ItemList", highlighted_text_color)
	theme.set_color("font_hovered_selected_color", "ItemList", highlighted_text_color)
	theme.set_color("guide_color", "ItemList", Color.TRANSPARENT)
	theme.set_constant("icon_margin", "ItemList", 4)
	
	var empty_stylebox := StyleBoxEmpty.new()
	empty_stylebox.set_content_margin_all(1)
	
	var panel_stylebox := StyleBoxFlat.new()
	panel_stylebox.bg_color = basic_panel_inner_color
	panel_stylebox.border_color = basic_panel_border_color
	panel_stylebox.set_border_width_all(2)
	panel_stylebox.set_content_margin_all(2)
	panel_stylebox.set_corner_radius_all(5)
	theme.set_stylebox("panel", "ItemList", panel_stylebox)
	
	var focus_stylebox := panel_stylebox.duplicate()
	focus_stylebox.border_color = dim_focus_color
	focus_stylebox.draw_center = false
	theme.set_stylebox("focus", "ItemList", focus_stylebox)
	
	var item_stylebox := StyleBoxFlat.new()
	item_stylebox.set_corner_radius_all(3)
	item_stylebox.set_content_margin_all(2)
	
	var hover_item_stylebox := item_stylebox.duplicate()
	hover_item_stylebox.bg_color = hover_overlay_color
	theme.set_stylebox("hovered", "ItemList", hover_item_stylebox)
	
	var selected_item_stylebox := item_stylebox.duplicate()
	selected_item_stylebox.bg_color = pressed_overlay_color
	theme.set_stylebox("selected", "ItemList", selected_item_stylebox)
	theme.set_stylebox("selected_focus", "ItemList", selected_item_stylebox)
	
	var hovered_selected_item_stylebox := item_stylebox.duplicate()
	hovered_selected_item_stylebox.bg_color = hover_pressed_overlay_color
	theme.set_stylebox("hovered_selected", "ItemList", hovered_selected_item_stylebox)
	theme.set_stylebox("hovered_selected_focus", "ItemList", hovered_selected_item_stylebox)
	
	var item_cursor_stylebox := item_stylebox.duplicate()
	item_cursor_stylebox.set_border_width_all(1)
	item_cursor_stylebox.border_color = Color(focus_color, 0.36)
	item_cursor_stylebox.draw_center = false
	theme.set_stylebox("cursor", "ItemList", item_cursor_stylebox)
	
	var item_cursor_unfocused_stylebox := item_cursor_stylebox.duplicate()
	item_cursor_unfocused_stylebox.border_color = Color(focus_color, 0.12)
	theme.set_stylebox("cursor_unfocused", "ItemList", item_cursor_unfocused_stylebox)

static func _setup_dropdown(theme: Theme) -> void:
	theme.add_type("Dropdown")
	theme.set_type_variation("Dropdown", "Control")
	theme.set_font_size("font_size", "Dropdown", 12)
	theme.set_font("font", "Dropdown", main_font)
	theme.set_color("font_color", "Dropdown", ThemeUtils.editable_text_color)
	
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(5)
	stylebox.set_border_width_all(2)
	stylebox.content_margin_left = 5.0
	stylebox.content_margin_right = 5.0
	
	var normal_stylebox := stylebox.duplicate()
	normal_stylebox.bg_color = line_edit_inner_color
	normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "Dropdown", normal_stylebox)
	
	var hover_stylebox := stylebox.duplicate()
	hover_stylebox.draw_center = false
	hover_stylebox.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "Dropdown", hover_stylebox)
	
	var focus_stylebox := hover_stylebox.duplicate()
	focus_stylebox.border_color = weak_focus_color
	theme.set_stylebox("focus", "Dropdown", focus_stylebox)

static func _setup_lineedit(theme: Theme) -> void:
	theme.add_type("LineEdit")
	theme.set_color("caret_color", "LineEdit", caret_color)
	theme.set_color("font_color", "LineEdit", editable_text_color)
	theme.set_color("font_uneditable_color", "LineEdit", dimmer_text_color)
	theme.set_color("font_placeholder_color", "LineEdit", subtle_text_color)
	theme.set_color("font_selected_color", "LineEdit", highlighted_text_color)
	theme.set_color("selection_color", "LineEdit", selection_color)
	theme.set_color("disabled_selection_color", "LineEdit", disabled_selection_color)
	theme.set_font_size("font_size", "LineEdit", 12)
	theme.set_font("font", "LineEdit", mono_font)
	
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(5)
	stylebox.set_border_width_all(2)
	stylebox.content_margin_left = 5.0
	stylebox.content_margin_right = 5.0
	
	var disabled_stylebox := stylebox.duplicate()
	disabled_stylebox.bg_color = line_edit_inner_color_disabled
	disabled_stylebox.border_color = line_edit_border_color_disabled
	theme.set_stylebox("read_only", "LineEdit", disabled_stylebox)
	
	var normal_stylebox := stylebox.duplicate()
	normal_stylebox.bg_color = line_edit_inner_color
	normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LineEdit", normal_stylebox)
	
	var hover_stylebox := stylebox.duplicate()
	hover_stylebox.draw_center = false
	hover_stylebox.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "LineEdit", hover_stylebox)
	
	var focus_stylebox := stylebox.duplicate()
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = dim_focus_color
	theme.set_stylebox("focus", "LineEdit", focus_stylebox)
	
	theme.add_type("LeftConnectedLineEdit")
	theme.set_type_variation("LeftConnectedLineEdit", "LineEdit")
	var left_connected_stylebox := StyleBoxFlat.new()
	left_connected_stylebox.corner_radius_top_left = 0
	left_connected_stylebox.corner_radius_bottom_left = 0
	left_connected_stylebox.corner_radius_top_right = 5
	left_connected_stylebox.corner_radius_bottom_right = 5
	left_connected_stylebox.border_width_left = 1
	left_connected_stylebox.border_width_right = 2
	left_connected_stylebox.border_width_top = 2
	left_connected_stylebox.border_width_bottom = 2
	left_connected_stylebox.content_margin_left = 5.0
	left_connected_stylebox.content_margin_right = 5.0
	left_connected_stylebox.content_margin_top = 0.0
	left_connected_stylebox.content_margin_bottom = 0.0
	
	var left_connected_disabled_stylebox := left_connected_stylebox.duplicate()
	left_connected_disabled_stylebox.bg_color = line_edit_inner_color_disabled
	left_connected_disabled_stylebox.border_color = line_edit_border_color_disabled
	theme.set_stylebox("read_only", "LeftConnectedLineEdit", left_connected_disabled_stylebox)
	
	var left_connected_normal_stylebox := left_connected_stylebox.duplicate()
	left_connected_normal_stylebox.bg_color = line_edit_inner_color
	left_connected_normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LeftConnectedLineEdit", left_connected_normal_stylebox)
	
	var left_connected_hover_stylebox := left_connected_stylebox.duplicate()
	left_connected_hover_stylebox.draw_center = false
	left_connected_hover_stylebox.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "LeftConnectedLineEdit", left_connected_hover_stylebox)
	
	var left_connected_focus_stylebox := left_connected_stylebox.duplicate()
	left_connected_focus_stylebox.draw_center = false
	left_connected_focus_stylebox.border_color = dim_focus_color
	theme.set_stylebox("focus", "LeftConnectedLineEdit", left_connected_focus_stylebox)
	
	theme.add_type("RightConnectedLineEdit")
	theme.set_type_variation("RightConnectedLineEdit", "LineEdit")
	var right_connected_stylebox := StyleBoxFlat.new()
	right_connected_stylebox.corner_radius_top_left = 5
	right_connected_stylebox.corner_radius_bottom_left = 5
	right_connected_stylebox.corner_radius_top_right = 0
	right_connected_stylebox.corner_radius_bottom_right = 0
	right_connected_stylebox.border_width_left = 2
	right_connected_stylebox.border_width_right = 1
	right_connected_stylebox.border_width_top = 2
	right_connected_stylebox.border_width_bottom = 2
	right_connected_stylebox.content_margin_left = 5.0
	right_connected_stylebox.content_margin_right = 5.0
	right_connected_stylebox.content_margin_top = 0.0
	right_connected_stylebox.content_margin_bottom = 0.0
	
	var right_connected_disabled_stylebox := right_connected_stylebox.duplicate()
	right_connected_disabled_stylebox.bg_color = line_edit_inner_color_disabled
	right_connected_disabled_stylebox.border_color = line_edit_border_color_disabled
	theme.set_stylebox("read_only", "RightConnectedLineEdit", right_connected_disabled_stylebox)
	
	var right_connected_normal_stylebox := right_connected_stylebox.duplicate()
	right_connected_normal_stylebox.bg_color = line_edit_inner_color
	right_connected_normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "RightConnectedLineEdit", right_connected_normal_stylebox)
	
	var right_connected_hover_stylebox := right_connected_stylebox.duplicate()
	right_connected_hover_stylebox.draw_center = false
	right_connected_hover_stylebox.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "RightConnectedLineEdit", right_connected_hover_stylebox)
	
	var right_connected_focus_stylebox := right_connected_stylebox.duplicate()
	right_connected_focus_stylebox.draw_center = false
	right_connected_focus_stylebox.border_color = dim_focus_color
	theme.set_stylebox("focus", "RightConnectedLineEdit", right_connected_focus_stylebox)
	
	theme.add_type("MiniLineEdit")
	theme.set_color("font_color", "MiniLineEdit", editable_text_color)
	theme.set_type_variation("MiniLineEdit", "LineEdit")
	theme.set_font_size("font_size", "MiniLineEdit", 10)
	theme.set_font("font", "MiniLineEdit", mono_font)
	var mini_stylebox := StyleBoxFlat.new()
	mini_stylebox.corner_radius_top_left = 3
	mini_stylebox.corner_radius_bottom_left = 0
	mini_stylebox.corner_radius_top_right = 3
	mini_stylebox.corner_radius_bottom_right = 0
	mini_stylebox.border_width_left = 0
	mini_stylebox.border_width_right = 0
	mini_stylebox.border_width_top = 0
	mini_stylebox.border_width_bottom = 2
	mini_stylebox.content_margin_left = 3.0
	mini_stylebox.content_margin_right = 3.0
	mini_stylebox.content_margin_bottom = 0.0
	
	var mini_stylebox_normal := mini_stylebox.duplicate()
	mini_stylebox_normal.bg_color = mini_line_edit_inner_color
	mini_stylebox_normal.border_color = mini_line_edit_normal_border_color
	theme.set_stylebox("normal", "MiniLineEdit", mini_stylebox_normal)
	
	var mini_stylebox_hover := mini_stylebox.duplicate()
	mini_stylebox_hover.draw_center = false
	mini_stylebox_hover.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "MiniLineEdit", mini_stylebox_hover)
	
	var mini_stylebox_pressed := mini_stylebox.duplicate()
	mini_stylebox_pressed.draw_center = false
	mini_stylebox_pressed.border_color = mini_line_edit_normal_border_color.blend(dim_focus_color)
	theme.set_stylebox("focus", "MiniLineEdit", mini_stylebox_pressed)
	
	theme.add_type("GoodColorPickerLineEdit")
	theme.set_type_variation("GoodColorPickerLineEdit", "LineEdit")
	theme.set_font_size("font_size", "GoodColorPickerLineEdit", 11)
	theme.set_font("font", "GoodColorPickerLineEdit", mono_font)
	var color_picker_line_edit_stylebox := StyleBoxFlat.new()
	color_picker_line_edit_stylebox.set_corner_radius_all(2)
	color_picker_line_edit_stylebox.bg_color = mini_line_edit_inner_color
	theme.set_stylebox("normal", "GoodColorPickerLineEdit", color_picker_line_edit_stylebox)
	var empty_stylebox := StyleBoxEmpty.new()
	theme.set_stylebox("hover", "GoodColorPickerLineEdit", empty_stylebox)
	theme.set_stylebox("focus", "GoodColorPickerLineEdit", empty_stylebox)
	theme.set_stylebox("read_only", "GoodColorPickerLineEdit", empty_stylebox)

static func _setup_scrollbar(theme: Theme) -> void:
	theme.add_type("HScrollBar")
	var h_stylebox := StyleBoxFlat.new()
	h_stylebox.set_corner_radius_all(3)
	h_stylebox.content_margin_left = 2.0
	h_stylebox.content_margin_right = 2.0
	
	var h_grabber_stylebox := h_stylebox.duplicate()
	h_grabber_stylebox.bg_color = intermediate_color
	theme.set_stylebox("grabber", "HScrollBar", h_grabber_stylebox)
	
	var h_grabber_stylebox_hover := h_stylebox.duplicate()
	h_grabber_stylebox_hover.bg_color = intermediate_hover_color
	theme.set_stylebox("grabber_highlight", "HScrollBar", h_grabber_stylebox_hover)
	
	var h_grabber_stylebox_pressed := h_stylebox.duplicate()
	h_grabber_stylebox_pressed.bg_color = scrollbar_pressed_color
	theme.set_stylebox("grabber_pressed", "HScrollBar", h_grabber_stylebox_pressed)
	
	var h_scroll_stylebox := StyleBoxFlat.new()
	h_scroll_stylebox.set_corner_radius_all(3)
	h_scroll_stylebox.content_margin_top = 4.0
	h_scroll_stylebox.content_margin_bottom = 4.0
	h_scroll_stylebox.bg_color = softer_base_color
	theme.set_stylebox("scroll", "HScrollBar", h_scroll_stylebox)
	
	theme.add_type("VScrollBar")
	var v_stylebox := StyleBoxFlat.new()
	v_stylebox.set_corner_radius_all(3)
	v_stylebox.content_margin_top = 2.0
	v_stylebox.content_margin_bottom = 2.0
	
	var v_grabber_stylebox := v_stylebox.duplicate()
	v_grabber_stylebox.bg_color = intermediate_color
	theme.set_stylebox("grabber", "VScrollBar", v_grabber_stylebox)
	
	var v_grabber_stylebox_hover := v_stylebox.duplicate()
	v_grabber_stylebox_hover.bg_color = intermediate_hover_color
	theme.set_stylebox("grabber_highlight", "VScrollBar", v_grabber_stylebox_hover)
	
	var v_grabber_stylebox_pressed := v_stylebox.duplicate()
	v_grabber_stylebox_pressed.bg_color = scrollbar_pressed_color
	theme.set_stylebox("grabber_pressed", "VScrollBar", v_grabber_stylebox_pressed)
	
	var v_scroll_stylebox := StyleBoxFlat.new()
	# TODO Make the background more coherent, without corners.
	v_scroll_stylebox.set_corner_radius_all(3)
	v_scroll_stylebox.content_margin_left = 4.0
	v_scroll_stylebox.content_margin_right = 4.0
	v_scroll_stylebox.bg_color = softer_base_color
	theme.set_stylebox("scroll", "VScrollBar", v_scroll_stylebox)

static func _setup_separator(theme: Theme) -> void:
	theme.add_type("HSeparator")
	var stylebox := StyleBoxLine.new()
	stylebox.color = basic_panel_border_color
	stylebox.thickness = 2
	theme.set_stylebox("separator", "HSeparator", stylebox)
	
	theme.add_type("SmallHSeparator")
	theme.set_type_variation("SmallHSeparator", "HSeparator")
	var small_stylebox := stylebox.duplicate()
	small_stylebox.color = Color(basic_panel_border_color, 0.5)
	small_stylebox.grow_begin = -3
	small_stylebox.grow_end = -3
	theme.set_stylebox("separator", "SmallHSeparator", small_stylebox)

static func _setup_label(theme: Theme) -> void:
	theme.add_type("Label")
	theme.set_color("font_color", "Label", text_color)
	
	theme.add_type("TitleLabel")
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", 15)
	theme.set_color("font_color", "TitleLabel", highlighted_text_color)
	
	theme.add_type("BoldTitleLabel")
	theme.set_type_variation("BoldTitleLabel", "Label")
	theme.set_font_size("font_size", "BoldTitleLabel", 16)
	theme.set_font("font", "BoldTitleLabel", bold_font)
	theme.set_color("font_color", "BoldTitleLabel", highlighted_text_color)
	
	theme.add_type("RichTextLabel")
	theme.set_color("default_color", "RichTextLabel", text_color)
	theme.set_color("selection_color", "RichTextLabel", selection_color)
	theme.set_font("bold_font", "RichTextLabel", bold_font)
	theme.set_font("mono_font", "RichTextLabel", mono_font)

static func _setup_tabcontainer(theme: Theme) -> void:
	theme.add_type("TabContainer")
	theme.set_color("font_unselected_color", "TabContainer", dim_text_color)
	theme.set_color("font_hovered_color", "TabContainer", text_color)
	theme.set_color("font_selected_color", "TabContainer", highlighted_text_color)
	theme.set_constant("side_margin", "TabContainer", 0)
	
	var panel_stylebox := StyleBoxFlat.new()
	panel_stylebox.bg_color = soft_base_color.lerp(softer_base_color, 0.5)
	panel_stylebox.border_color = subtle_panel_border_color
	panel_stylebox.border_width_left = 2
	panel_stylebox.border_width_right = 2
	panel_stylebox.border_width_bottom = 2
	panel_stylebox.corner_radius_bottom_right = 5
	panel_stylebox.corner_radius_bottom_left = 5
	panel_stylebox.content_margin_left = 2
	panel_stylebox.content_margin_right = 2
	panel_stylebox.content_margin_bottom = 2
	panel_stylebox.content_margin_top = 0
	theme.set_stylebox("panel", "TabContainer", panel_stylebox)
	
	var tab_stylebox := StyleBoxFlat.new()
	tab_stylebox.corner_radius_top_left = 4
	tab_stylebox.corner_radius_top_right = 4
	tab_stylebox.content_margin_left = 12.0
	tab_stylebox.content_margin_right = 12.0
	tab_stylebox.content_margin_bottom = 3.0
	tab_stylebox.content_margin_top = 3.0
	
	theme.set_stylebox("tab_disabled", "TabContainer", tab_stylebox)  # Unused
	
	var tab_focus_stylebox := StyleBoxFlat.new()
	tab_focus_stylebox.set_border_width_all(2)
	tab_focus_stylebox.draw_center = false
	tab_focus_stylebox.border_color = focus_color
	theme.set_stylebox("tab_focus", "TabContainer", tab_focus_stylebox)
	
	var tab_hover_stylebox := tab_stylebox.duplicate()
	tab_hover_stylebox.bg_color = softer_intermediate_hover_color
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hover_stylebox)
	
	var tab_selected_stylebox := tab_stylebox.duplicate()
	tab_selected_stylebox.corner_radius_top_left = 0
	tab_selected_stylebox.corner_radius_top_right = 0
	tab_selected_stylebox.border_width_top = 2
	tab_selected_stylebox.bg_color = selected_tab_color
	tab_selected_stylebox.border_color = selected_tab_border_color
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected_stylebox)
	
	var tab_unselected_stylebox := tab_stylebox.duplicate()
	tab_unselected_stylebox.bg_color = softer_intermediate_color
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected_stylebox)
	
	var side_tab_stylebox := StyleBoxFlat.new()
	side_tab_stylebox.corner_radius_top_left = 4
	side_tab_stylebox.corner_radius_bottom_left = 4
	side_tab_stylebox.content_margin_top = 3.0
	side_tab_stylebox.content_margin_bottom = 3.0
	side_tab_stylebox.content_margin_left = 4.0
	side_tab_stylebox.content_margin_right = 10.0
	
	var side_tab_hover_stylebox := side_tab_stylebox.duplicate()
	side_tab_hover_stylebox.bg_color = softer_intermediate_hover_color
	theme.set_stylebox("side_tab_hovered", "TabContainer", side_tab_hover_stylebox)
	
	var side_tab_selected_stylebox := side_tab_stylebox.duplicate()
	side_tab_selected_stylebox.corner_radius_top_left = 0
	side_tab_selected_stylebox.corner_radius_bottom_left = 0
	side_tab_selected_stylebox.content_margin_left = 8.0
	side_tab_selected_stylebox.content_margin_right = 6.0
	side_tab_selected_stylebox.border_width_left = 2
	side_tab_selected_stylebox.bg_color = selected_tab_color
	side_tab_selected_stylebox.border_color = selected_tab_border_color
	theme.set_stylebox("side_tab_selected", "TabContainer", side_tab_selected_stylebox)
	
	var side_tab_unselected_stylebox := side_tab_stylebox.duplicate()
	side_tab_unselected_stylebox.bg_color = softer_intermediate_color
	theme.set_stylebox("side_tab_unselected", "TabContainer", side_tab_unselected_stylebox)
	
	var tabbar_background_stylebox := StyleBoxFlat.new()
	tabbar_background_stylebox.bg_color = soft_base_color
	tabbar_background_stylebox.set_content_margin_all(0)
	tabbar_background_stylebox.corner_radius_top_left = 5
	tabbar_background_stylebox.corner_radius_top_right = 5
	theme.set_stylebox("tabbar_background", "TabContainer", tabbar_background_stylebox)

static func _setup_textedit(theme: Theme) -> void:
	theme.add_type("TextEdit")
	theme.set_color("caret_color", "TextEdit", Color.TRANSPARENT)
	theme.set_color("selection_color", "TextEdit", selection_color)
	theme.set_constant("line_spacing", "TextEdit", 3)
	theme.set_font_size("font_size", "TextEdit", 12)
	theme.set_font("font", "TextEdit", mono_font)
	
	var normal_stylebox := StyleBoxFlat.new()
	normal_stylebox.bg_color = line_edit_inner_color
	normal_stylebox.border_color = line_edit_normal_border_color
	normal_stylebox.set_border_width_all(2)
	normal_stylebox.set_corner_radius_all(5)
	normal_stylebox.content_margin_left = 6.0
	theme.set_stylebox("normal", "TextEdit", normal_stylebox)
	theme.set_stylebox("read_only", "TextEdit", normal_stylebox)
	
	var focus_stylebox := normal_stylebox.duplicate()
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = dim_focus_color
	theme.set_stylebox("focus", "TextEdit", focus_stylebox)
	
	var hover_stylebox := focus_stylebox.duplicate()
	hover_stylebox.border_color = strong_hover_overlay_color if is_theme_dark else stronger_hover_overlay_color
	theme.set_stylebox("hover", "TextEdit", hover_stylebox)

static func _setup_tooltip(theme: Theme) -> void:
	theme.add_type("TooltipPanel")
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = basic_panel_inner_color
	stylebox.border_color = basic_panel_border_color
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(2)
	stylebox.content_margin_left = 6.0
	stylebox.content_margin_top = 1.0
	stylebox.content_margin_right = 6.0
	stylebox.content_margin_bottom = 3.0
	theme.set_stylebox("panel", "TooltipPanel", stylebox)
	
	theme.add_type("TooltipLabel")
	theme.set_color("font_color", "TooltipLabel", text_color)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	theme.set_font("font", "TooltipLabel", main_font)

static func _setup_splitcontainer(theme: Theme) -> void:
	theme.add_type("SplitContainer")
	theme.set_icon("grabber", "VSplitContainer", DPITexture.create_from_string(
		"""<svg width="32" height="4" xmlns="http://www.w3.org/2000/svg">
			<path d="M1 1h30v2H1z" fill="#%s" opacity=".6"/>
		</svg>""" % desaturated_color.to_html(false))
	)
	theme.set_icon("grabber", "HSplitContainer", DPITexture.create_from_string(
		"""<svg width="4" height="48" xmlns="http://www.w3.org/2000/svg">
			<path d="M1 1v46h2V1z" fill="#%s" opacity=".6"/>
		</svg>""" % desaturated_color.to_html(false))
	)
