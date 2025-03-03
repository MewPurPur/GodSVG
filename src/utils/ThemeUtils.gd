class_name ThemeUtils extends RefCounted

const regular_font = preload("res://assets/fonts/Font.ttf")
const bold_font = preload("res://assets/fonts/FontBold.ttf")
const mono_font = preload("res://assets/fonts/FontMono.ttf")

const focus_color = Color("66ccffcc")
const common_panel_inner_color = Color("191926")
const common_panel_border_color = Color("414159")
const common_caret_color = Color("ddeeffdd")
const common_selection_color = Color("668cff66")
const common_disabled_selection_color = Color("aaaaaa66")
const common_editable_text_color = Color("ddeeff")
const common_inner_color_disabled = Color("0e0e12")
const common_border_color_disabled = Color("1e1f24")

const common_text_color = Color("ffffffdd")
const common_highlighted_text_color = Color("ffffff")
const common_dim_text_color = Color("ffffffbb")
const common_dimmer_text_color = Color("ffffff77")
const common_subtle_text_color = Color("ffffff55")

const common_button_inner_color_normal = Color("1c1e38")
const common_button_border_color_normal = Color("313859")
const common_button_inner_color_hover = Color("232840")
const common_button_border_color_hover = Color("43567a")
const common_button_inner_color_pressed = Color("3d5499")
const common_button_border_color_pressed = Color("608fbf")

const connected_button_inner_color_normal = Color("10101a")
const connected_button_border_color_normal = Color("272733")
const connected_button_inner_color_hover = Color("181826")
const connected_button_border_color_hover = Color("3a3a4d")
const connected_button_inner_color_pressed = Color("313559")
const connected_button_border_color_pressed = Color("54678c")

const icon_normal_color = Color("bfbfbf")
const context_icon_normal_color = Color("d9d9d9")
const icon_hover_color = Color("ffffff")
const icon_pressed_color = Color("bfdfff")
const icon_toggled_off_color = Color("808080")
const icon_toggled_on_color = Color("ddeeffdd")

const translucent_button_color_normal = Color("ddeeff11")
const translucent_button_color_hover = Color("ddeeff22")
const translucent_button_color_pressed = Color("ddeeff44")
const translucent_button_color_disabled = Color("05060755")
const flat_button_color_hover = Color("ddeeff11")
const flat_button_color_pressed = Color("ddeeff33")
const flat_button_color_hovered_pressed = Color("ddeeff41")  # hover.blend(pressed)
const flat_button_color_disabled = Color("05060744")

const dark_panel_color = Color("11111a")
const light_panel_color = Color("ddeeff0c")
const overlay_panel_inner_color = Color("060614")
const overlay_panel_border_color = Color("344166")

const scrollbar_normal_color = Color("344166")
const scrollbar_hover_color = Color("465580")
const scrollbar_pressed_color = Color("608fbf")
const scrollbar_background_color = Color("0f0f1a99")

const line_edit_focus_color = Color("3d6b99")
const line_edit_background_color = Color("10101a")
const line_edit_normal_border_color = Color("272733")
const line_edit_hover_border_overlay_color = Color("ddeeff1b")
const mini_line_edit_normal_border_color = Color("4d4e66")

const tab_container_panel_inner_color = Color("171726")
const tab_container_panel_border_color = Color("2a2e4d")
const tabbar_background_color = Color("13131f80")
const hovered_tab_color = Color("1f2138")
const normal_tab_color = Color("17192e")
const selected_tab_color = Color("293052")
const selected_tab_border_color = Color("608fbf")

static func generate_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = regular_font
	theme.default_font_size = 13
	_setup_panelcontainer(theme)
	_setup_button(theme)
	_setup_checkbox(theme)
	_setup_checkbutton(theme)
	_setup_itemlist(theme)
	_setup_lineedit(theme)
	_setup_scrollbar(theme)
	_setup_separator(theme)
	_setup_label(theme)
	_setup_tabcontainer(theme)
	_setup_textedit(theme)
	_setup_tooltip(theme)
	return theme

static func generate_and_apply_theme() -> void:
	var default_theme := ThemeDB.get_default_theme()
	default_theme.default_font = regular_font
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
	stylebox.bg_color = common_panel_inner_color
	stylebox.border_color = common_panel_border_color
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
	
	theme.add_type("DarkPanel")
	theme.set_type_variation("DarkPanel", "PanelContainer")
	var dark_stylebox := StyleBoxFlat.new()
	dark_stylebox.set_corner_radius_all(3)
	dark_stylebox.content_margin_left = 4.0
	dark_stylebox.content_margin_right = 4.0
	dark_stylebox.content_margin_top = 2.0
	dark_stylebox.content_margin_bottom = 2.0
	dark_stylebox.bg_color = dark_panel_color
	theme.set_stylebox("panel", "DarkPanel", dark_stylebox)
	
	theme.add_type("LightPanel")
	theme.set_type_variation("LightPanel", "PanelContainer")
	var light_stylebox := StyleBoxFlat.new()
	light_stylebox.set_corner_radius_all(5)
	light_stylebox.content_margin_left = 4.0
	light_stylebox.content_margin_right = 4.0
	light_stylebox.content_margin_top = 2.0
	light_stylebox.content_margin_bottom = 2.0
	light_stylebox.bg_color = light_panel_color
	theme.set_stylebox("panel", "LightPanel", light_stylebox)
	
	theme.add_type("OverlayPanel")
	theme.set_type_variation("OverlayPanel", "PanelContainer")
	var overlay_stylebox := StyleBoxFlat.new()
	overlay_stylebox.set_corner_radius_all(2)
	overlay_stylebox.set_border_width_all(2)
	overlay_stylebox.content_margin_left = 8.0
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
	textbox_stylebox.content_margin_left = 6.0
	textbox_stylebox.content_margin_right = 6.0
	textbox_stylebox.content_margin_top = 2.0
	textbox_stylebox.content_margin_bottom = 4.0
	textbox_stylebox.bg_color = overlay_panel_inner_color * 0.8 + Color.BLACK * 0.2
	textbox_stylebox.border_color = Color(overlay_panel_border_color, 0.6)
	theme.set_stylebox("panel", "TextBox", textbox_stylebox)
	
	theme.add_type("SideTabBar")
	theme.set_type_variation("SideTabBar", "PanelContainer")
	var side_tabbar_stylebox := StyleBoxFlat.new()
	side_tabbar_stylebox.bg_color = tabbar_background_color
	side_tabbar_stylebox.set_content_margin_all(0)
	side_tabbar_stylebox.corner_radius_top_left = 5
	side_tabbar_stylebox.corner_radius_bottom_left = 5
	theme.set_stylebox("panel", "SideTabBar", side_tabbar_stylebox)
	
	theme.add_type("SideBarContent")
	theme.set_type_variation("SideBarContent", "PanelContainer")
	var panel_stylebox := StyleBoxFlat.new()
	panel_stylebox.bg_color = tab_container_panel_inner_color
	panel_stylebox.border_color = tab_container_panel_border_color
	panel_stylebox.set_border_width_all(2)
	panel_stylebox.corner_radius_top_right = 5
	panel_stylebox.corner_radius_bottom_right = 5
	panel_stylebox.content_margin_left = 14
	panel_stylebox.content_margin_right = 2
	panel_stylebox.content_margin_bottom = 2
	panel_stylebox.content_margin_top = 2
	theme.set_stylebox("panel", "SideBarContent", panel_stylebox)

static func _setup_button(theme: Theme) -> void:
	theme.add_type("Button")
	theme.set_constant("h_separation", "Button", 6)
	theme.set_color("font_color", "Button", common_text_color)
	theme.set_color("font_disabled_color", "Button", common_subtle_text_color)
	theme.set_color("font_focus_color", "Button", common_highlighted_text_color)
	theme.set_color("font_hover_color", "Button", common_highlighted_text_color)
	theme.set_color("font_pressed_color", "Button", common_highlighted_text_color)
	theme.set_color("font_hover_pressed_color", "Button", common_highlighted_text_color)
	var button_stylebox := StyleBoxFlat.new()
	button_stylebox.set_corner_radius_all(5)
	button_stylebox.set_border_width_all(2)
	button_stylebox.content_margin_bottom = 3.0
	button_stylebox.content_margin_top = 3.0
	button_stylebox.content_margin_left = 6.0
	button_stylebox.content_margin_right = 6.0
	
	var normal_button_stylebox := button_stylebox.duplicate()
	normal_button_stylebox.bg_color = common_button_inner_color_normal
	normal_button_stylebox.border_color = common_button_border_color_normal
	theme.set_stylebox("normal", "Button", normal_button_stylebox)
	
	var hover_button_stylebox := button_stylebox.duplicate()
	hover_button_stylebox.bg_color = common_button_inner_color_hover
	hover_button_stylebox.border_color = common_button_border_color_hover
	theme.set_stylebox("hover", "Button", hover_button_stylebox)
	
	var pressed_button_stylebox := button_stylebox.duplicate()
	pressed_button_stylebox.bg_color = common_button_inner_color_pressed
	pressed_button_stylebox.border_color = common_button_border_color_pressed
	theme.set_stylebox("pressed", "Button", pressed_button_stylebox)
	
	var disabled_button_stylebox := button_stylebox.duplicate()
	disabled_button_stylebox.bg_color = common_inner_color_disabled
	disabled_button_stylebox.border_color = common_border_color_disabled
	theme.set_stylebox("disabled", "Button", disabled_button_stylebox)
	
	var focus_button_stylebox := button_stylebox.duplicate()
	focus_button_stylebox.draw_center = false
	focus_button_stylebox.border_color = focus_color
	theme.set_stylebox("focus", "Button", focus_button_stylebox)
	
	theme.add_type("IconButton")
	theme.set_type_variation("IconButton", "Button")
	var icon_button_stylebox := StyleBoxFlat.new()
	icon_button_stylebox.set_corner_radius_all(5)
	icon_button_stylebox.set_border_width_all(2)
	icon_button_stylebox.set_content_margin_all(4)
	
	var normal_icon_button_stylebox := icon_button_stylebox.duplicate()
	normal_icon_button_stylebox.bg_color = common_button_inner_color_normal
	normal_icon_button_stylebox.border_color = common_button_border_color_normal
	theme.set_stylebox("normal", "IconButton", normal_icon_button_stylebox)
	
	var hover_icon_button_stylebox := icon_button_stylebox.duplicate()
	hover_icon_button_stylebox.bg_color = common_button_inner_color_hover
	hover_icon_button_stylebox.border_color = common_button_border_color_hover
	theme.set_stylebox("hover", "IconButton", hover_icon_button_stylebox)
	
	var pressed_icon_button_stylebox := icon_button_stylebox.duplicate()
	pressed_icon_button_stylebox.bg_color = common_button_inner_color_pressed
	pressed_icon_button_stylebox.border_color = common_button_border_color_pressed
	theme.set_stylebox("pressed", "IconButton", pressed_icon_button_stylebox)
	
	var disabled_icon_button_stylebox := icon_button_stylebox.duplicate()
	disabled_icon_button_stylebox.bg_color = common_inner_color_disabled
	disabled_icon_button_stylebox.border_color = common_border_color_disabled
	theme.set_stylebox("disabled", "IconButton", disabled_icon_button_stylebox)
	
	theme.add_type("LeftConnectedButton")
	theme.set_type_variation("LeftConnectedButton", "Button")
	theme.set_color("icon_normal_color", "LeftConnectedButton", icon_normal_color)
	theme.set_color("icon_hover_color", "LeftConnectedButton", icon_hover_color)
	theme.set_color("icon_pressed_color", "LeftConnectedButton", icon_pressed_color)
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
	normal_left_connected_button_stylebox.bg_color = connected_button_inner_color_normal
	normal_left_connected_button_stylebox.border_color = connected_button_border_color_normal
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
	
	theme.add_type("LeftConnectedButtonTransparent")
	theme.set_type_variation("LeftConnectedButtonTransparent", "Button")
	theme.set_color("icon_normal_color", "LeftConnectedButtonTransparent", icon_normal_color)
	theme.set_color("icon_hover_color", "LeftConnectedButtonTransparent", icon_hover_color)
	theme.set_color("icon_pressed_color", "LeftConnectedButtonTransparent", icon_pressed_color)
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
	normal_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_normal
	theme.set_stylebox("normal", "LeftConnectedButtonTransparent", normal_left_connected_button_transparent_stylebox)
	
	var hover_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	hover_left_connected_button_transparent_stylebox.draw_center = false
	hover_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "LeftConnectedButtonTransparent", hover_left_connected_button_transparent_stylebox)
	
	var pressed_left_connected_button_transparent_stylebox := left_connected_button_transparent_stylebox.duplicate()
	pressed_left_connected_button_transparent_stylebox.draw_center = false
	pressed_left_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "LeftConnectedButtonTransparent", pressed_left_connected_button_transparent_stylebox)
	
	theme.add_type("RightConnectedButton")
	theme.set_type_variation("RightConnectedButton", "Button")
	theme.set_color("icon_normal_color", "RightConnectedButton", icon_normal_color)
	theme.set_color("icon_hover_color", "RightConnectedButton", icon_hover_color)
	theme.set_color("icon_pressed_color", "RightConnectedButton", icon_pressed_color)
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
	normal_right_connected_button_stylebox.bg_color = connected_button_inner_color_normal
	normal_right_connected_button_stylebox.border_color = connected_button_border_color_normal
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
	
	theme.add_type("RightConnectedButtonTransparent")
	theme.set_type_variation("RightConnectedButtonTransparent", "Button")
	theme.set_color("icon_normal_color", "RightConnectedButtonTransparent", icon_normal_color)
	theme.set_color("icon_hover_color", "RightConnectedButtonTransparent", icon_hover_color)
	theme.set_color("icon_pressed_color", "RightConnectedButtonTransparent", icon_pressed_color)
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
	normal_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_normal
	theme.set_stylebox("normal", "RightConnectedButtonTransparent", normal_right_connected_button_transparent_stylebox)
	
	var hover_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	hover_right_connected_button_transparent_stylebox.draw_center = false
	hover_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_hover
	theme.set_stylebox("hover", "RightConnectedButtonTransparent", hover_right_connected_button_transparent_stylebox)
	
	var pressed_right_connected_button_transparent_stylebox := right_connected_button_transparent_stylebox.duplicate()
	pressed_right_connected_button_transparent_stylebox.draw_center = false
	pressed_right_connected_button_transparent_stylebox.border_color = connected_button_border_color_pressed
	theme.set_stylebox("pressed", "RightConnectedButtonTransparent", pressed_right_connected_button_transparent_stylebox)
	
	theme.add_type("TranslucentButton")
	theme.set_type_variation("TranslucentButton", "Button")
	var translucent_button_stylebox := StyleBoxFlat.new()
	translucent_button_stylebox.set_corner_radius_all(5)
	translucent_button_stylebox.set_content_margin_all(4)
	
	var normal_translucent_button_stylebox := translucent_button_stylebox.duplicate()
	normal_translucent_button_stylebox.bg_color = translucent_button_color_normal
	theme.set_stylebox("normal", "TranslucentButton", normal_translucent_button_stylebox)
	
	var hover_translucent_button_stylebox := translucent_button_stylebox.duplicate()
	hover_translucent_button_stylebox.bg_color = translucent_button_color_hover
	theme.set_stylebox("hover", "TranslucentButton", hover_translucent_button_stylebox)
	
	var pressed_translucent_button_stylebox := translucent_button_stylebox.duplicate()
	pressed_translucent_button_stylebox.bg_color = translucent_button_color_pressed
	theme.set_stylebox("pressed", "TranslucentButton", pressed_translucent_button_stylebox)
	
	var disabled_translucent_button_stylebox := translucent_button_stylebox.duplicate()
	disabled_translucent_button_stylebox.bg_color = translucent_button_color_disabled
	theme.set_stylebox("disabled", "TranslucentButton", disabled_translucent_button_stylebox)
	
	theme.add_type("FlatButton")
	theme.set_type_variation("FlatButton", "Button")
	theme.set_color("icon_normal_color", "FlatButton", icon_normal_color)
	theme.set_color("icon_hover_color", "FlatButton", icon_hover_color)
	theme.set_color("icon_pressed_color", "FlatButton", icon_pressed_color)
	var flat_button_stylebox := StyleBoxFlat.new()
	flat_button_stylebox.set_corner_radius_all(3)
	flat_button_stylebox.set_content_margin_all(2)
	
	var normal_flat_button_stylebox := StyleBoxEmpty.new()
	normal_flat_button_stylebox.set_content_margin_all(2)
	theme.set_stylebox("normal", "FlatButton", normal_flat_button_stylebox)
	
	var hover_flat_button_stylebox := flat_button_stylebox.duplicate()
	hover_flat_button_stylebox.bg_color = flat_button_color_hover
	theme.set_stylebox("hover", "FlatButton", hover_flat_button_stylebox)
	
	var pressed_flat_button_stylebox := flat_button_stylebox.duplicate()
	pressed_flat_button_stylebox.bg_color = flat_button_color_pressed
	theme.set_stylebox("pressed", "FlatButton", pressed_flat_button_stylebox)
	
	var disabled_flat_button_stylebox := flat_button_stylebox.duplicate()
	disabled_flat_button_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "FlatButton", disabled_flat_button_stylebox)
	
	theme.add_type("ContextButton")
	theme.set_type_variation("ContextButton", "Button")
	theme.set_color("icon_normal_color", "ContextButton", context_icon_normal_color)
	theme.set_color("icon_hover_color", "ContextButton", icon_hover_color)
	theme.set_color("icon_pressed_color", "ContextButton", icon_hover_color)
	var context_button_stylebox := StyleBoxFlat.new()
	context_button_stylebox.set_corner_radius_all(3)
	context_button_stylebox.content_margin_bottom = 2
	context_button_stylebox.content_margin_top = 2
	context_button_stylebox.content_margin_left = 3
	context_button_stylebox.content_margin_right = 4
	
	var normal_context_button_stylebox := StyleBoxEmpty.new()
	normal_context_button_stylebox.content_margin_bottom = 2
	normal_context_button_stylebox.content_margin_top = 2
	normal_context_button_stylebox.content_margin_left = 3
	normal_context_button_stylebox.content_margin_right = 4
	theme.set_stylebox("normal", "ContextButton", normal_context_button_stylebox)
	
	var hover_context_button_stylebox := context_button_stylebox.duplicate()
	hover_context_button_stylebox.bg_color = flat_button_color_hover
	theme.set_stylebox("hover", "ContextButton", hover_context_button_stylebox)
	
	var pressed_context_button_stylebox := context_button_stylebox.duplicate()
	pressed_context_button_stylebox.bg_color = flat_button_color_pressed
	theme.set_stylebox("pressed", "ContextButton", pressed_context_button_stylebox)
	
	var disabled_context_button_stylebox := context_button_stylebox.duplicate()
	disabled_context_button_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "ContextButton", disabled_context_button_stylebox)
	
	theme.add_type("TextButton")
	theme.set_type_variation("TextButton", "Button")
	theme.set_color("font_color", "TextButton", icon_toggled_off_color)
	theme.set_color("font_hover_color", "TextButton", icon_toggled_off_color)
	theme.set_color("font_pressed_color", "TextButton", icon_toggled_on_color)
	var text_button_empty_stylebox := StyleBoxEmpty.new()
	text_button_empty_stylebox.content_margin_left = 2.0
	text_button_empty_stylebox.content_margin_right = 2.0
	theme.set_stylebox("normal", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("hover", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("pressed", "TextButton", text_button_empty_stylebox)
	theme.set_stylebox("disabled", "TextButton", text_button_empty_stylebox)
	
	theme.add_type("SideTab")
	theme.set_type_variation("SideTab", "Button")
	theme.set_color("font_color", "SideTab", common_dim_text_color)
	theme.set_color("font_hover_color", "SideTab", common_highlighted_text_color)
	theme.set_color("font_pressed_color", "SideTab", common_highlighted_text_color)
	theme.set_color("font_hover_pressed_color", "SideTab", common_highlighted_text_color)
	
	var normal_sidetab_stylebox := StyleBoxFlat.new()
	normal_sidetab_stylebox.bg_color = normal_tab_color
	normal_sidetab_stylebox.corner_radius_top_left = 4
	normal_sidetab_stylebox.corner_radius_bottom_left = 4
	normal_sidetab_stylebox.content_margin_left = 6
	normal_sidetab_stylebox.content_margin_right = 6
	normal_sidetab_stylebox.content_margin_bottom = 3
	normal_sidetab_stylebox.content_margin_top = 3
	theme.set_stylebox("normal", "SideTab", normal_sidetab_stylebox)
	
	var hovered_sidetab_stylebox := normal_sidetab_stylebox.duplicate()
	hovered_sidetab_stylebox.bg_color = hovered_tab_color
	theme.set_stylebox("hover", "SideTab", hovered_sidetab_stylebox)
	
	var pressed_sidetab_stylebox := StyleBoxFlat.new()
	pressed_sidetab_stylebox.bg_color = selected_tab_color
	pressed_sidetab_stylebox.border_color = selected_tab_border_color
	pressed_sidetab_stylebox.border_width_left = 2
	pressed_sidetab_stylebox.content_margin_left = 10
	pressed_sidetab_stylebox.content_margin_right = 6
	pressed_sidetab_stylebox.content_margin_bottom = 3
	pressed_sidetab_stylebox.content_margin_top = 3
	theme.set_stylebox("pressed", "SideTab", pressed_sidetab_stylebox)
	
	theme.add_type("Swatch")
	theme.set_type_variation("Swatch", "Button")
	var swatch_stylebox := StyleBoxFlat.new()
	swatch_stylebox.set_corner_radius_all(3)
	
	var normal_swatch_stylebox := swatch_stylebox.duplicate()
	normal_swatch_stylebox.bg_color = common_button_border_color_normal
	theme.set_stylebox("normal", "Swatch", normal_swatch_stylebox)
	
	var hover_swatch_stylebox := swatch_stylebox.duplicate()
	hover_swatch_stylebox.bg_color = common_button_border_color_hover
	theme.set_stylebox("hover", "Swatch", hover_swatch_stylebox)
	
	var pressed_swatch_stylebox := swatch_stylebox.duplicate()
	pressed_swatch_stylebox.bg_color = common_button_border_color_pressed
	theme.set_stylebox("pressed", "Swatch", pressed_swatch_stylebox)
	theme.set_stylebox("disabled", "Swatch", pressed_swatch_stylebox)

static func _setup_checkbox(theme: Theme) -> void:
	theme.add_type("CheckBox")
	theme.set_color("font_color", "CheckBox", common_text_color)
	theme.set_color("font_disabled_color", "CheckBox", common_subtle_text_color)
	theme.set_color("font_focus_color", "CheckBox", common_highlighted_text_color)
	theme.set_color("font_hover_color", "CheckBox", common_highlighted_text_color)
	theme.set_color("font_pressed_color", "CheckBox", common_highlighted_text_color)
	theme.set_color("font_hover_pressed_color", "CheckBox", common_highlighted_text_color)
	theme.set_icon("checked", "CheckBox", _icon("GuiBoxChecked"))
	theme.set_icon("checked_disabled", "CheckBox", _icon("GuiBoxCheckedDisabled"))
	theme.set_icon("unchecked", "CheckBox", _icon("GuiBoxUnchecked"))
	theme.set_icon("unchecked_disabled", "CheckBox", _icon("GuiBoxUncheckedDisabled"))
	
	var checkbox_stylebox := StyleBoxFlat.new()
	checkbox_stylebox.set_corner_radius_all(4)
	checkbox_stylebox.content_margin_bottom = 2.0
	checkbox_stylebox.content_margin_top = 2.0
	checkbox_stylebox.content_margin_left = 4.0
	checkbox_stylebox.content_margin_right = 4.0
	
	var empty_checkbox_stylebox := StyleBoxEmpty.new()
	empty_checkbox_stylebox.content_margin_bottom = 2.0
	empty_checkbox_stylebox.content_margin_top = 2.0
	empty_checkbox_stylebox.content_margin_left = 4.0
	empty_checkbox_stylebox.content_margin_right = 4.0
	theme.set_stylebox("normal", "CheckBox", empty_checkbox_stylebox)
	theme.set_stylebox("pressed", "CheckBox", empty_checkbox_stylebox)
	
	var hover_checkbox_stylebox := checkbox_stylebox.duplicate()
	hover_checkbox_stylebox.bg_color = flat_button_color_hover
	theme.set_stylebox("hover", "CheckBox", hover_checkbox_stylebox)
	theme.set_stylebox("hover_pressed", "CheckBox", hover_checkbox_stylebox)
	
	var disabled_checkbox_stylebox := checkbox_stylebox.duplicate()
	disabled_checkbox_stylebox.bg_color = flat_button_color_disabled
	theme.set_stylebox("disabled", "CheckBox", disabled_checkbox_stylebox)

static func _setup_checkbutton(theme: Theme) -> void:
	theme.add_type("CheckButton")
	theme.set_color("font_color", "CheckButton", common_text_color)
	theme.set_color("font_disabled_color", "CheckButton", common_subtle_text_color)
	theme.set_color("font_focus_color", "CheckButton", common_highlighted_text_color)
	theme.set_color("font_hover_color", "CheckButton", common_highlighted_text_color)
	theme.set_color("font_pressed_color", "CheckButton", common_highlighted_text_color)
	theme.set_color("font_hover_pressed_color", "CheckButton", common_highlighted_text_color)
	theme.set_icon("checked", "CheckButton", _icon("GuiToggleChecked"))
	theme.set_icon("unchecked", "CheckButton", _icon("GuiToggleUnchecked"))

static func _setup_itemlist(theme: Theme) -> void:
	theme.add_type("ItemList")
	theme.set_color("font_color", "ItemList", Color(0.9, 0.9, 0.9))
	theme.set_color("font_hovered", "ItemList", Color.WHITE)
	theme.set_color("font_selected", "ItemList", Color.WHITE)
	theme.set_color("guide_color", "ItemList", Color.TRANSPARENT)
	theme.set_constant("icon_margin", "ItemList", 4)
	
	var empty_stylebox := StyleBoxEmpty.new()
	empty_stylebox.set_content_margin_all(1)
	theme.set_stylebox("panel", "ItemList", empty_stylebox)
	theme.set_stylebox("focus", "ItemList", empty_stylebox)
	theme.set_stylebox("cursor", "ItemList", empty_stylebox)
	theme.set_stylebox("cursor_unfocused", "ItemList", empty_stylebox)
	
	var item_stylebox := StyleBoxFlat.new()
	item_stylebox.set_corner_radius_all(3)
	item_stylebox.set_content_margin_all(2)
	
	var hover_item_stylebox := item_stylebox.duplicate()
	hover_item_stylebox.bg_color = flat_button_color_hover
	theme.set_stylebox("hovered", "ItemList", hover_item_stylebox)
	
	var selected_item_stylebox := item_stylebox.duplicate()
	selected_item_stylebox.bg_color = flat_button_color_pressed
	theme.set_stylebox("selected", "ItemList", selected_item_stylebox)
	theme.set_stylebox("selected_focus", "ItemList", selected_item_stylebox)
	
	var hovered_selected_item_stylebox := item_stylebox.duplicate()
	hovered_selected_item_stylebox.bg_color = flat_button_color_hovered_pressed
	theme.set_stylebox("hovered_selected", "ItemList", hovered_selected_item_stylebox)
	theme.set_stylebox("hovered_selected_focus", "ItemList", hovered_selected_item_stylebox)

static func _setup_lineedit(theme: Theme) -> void:
	theme.add_type("LineEdit")
	theme.set_color("caret_color", "LineEdit", common_caret_color)
	theme.set_color("font_color", "LineEdit", common_editable_text_color)
	theme.set_color("font_placeholder_color", "LineEdit", common_subtle_text_color)
	theme.set_color("selection_color", "LineEdit", common_selection_color)
	theme.set_color("disabled_selection_color", "LineEdit", common_disabled_selection_color)
	theme.set_font_size("font_size", "LineEdit", 12)
	theme.set_font("font", "LineEdit", mono_font)
	
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(5)
	stylebox.set_border_width_all(2)
	stylebox.content_margin_left = 5.0
	stylebox.content_margin_right = 5.0
	
	var disabled_stylebox := stylebox.duplicate()
	disabled_stylebox.bg_color = common_inner_color_disabled
	disabled_stylebox.border_color = common_border_color_disabled
	theme.set_stylebox("read_only", "LineEdit", disabled_stylebox)
	
	var normal_stylebox := stylebox.duplicate()
	normal_stylebox.bg_color = line_edit_background_color
	normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LineEdit", normal_stylebox)
	
	var hover_stylebox := stylebox.duplicate()
	hover_stylebox.draw_center = false
	hover_stylebox.border_color = line_edit_hover_border_overlay_color
	theme.set_stylebox("hover", "LineEdit", hover_stylebox)
	
	var focus_stylebox := stylebox.duplicate()
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = line_edit_focus_color
	theme.set_stylebox("focus", "LineEdit", focus_stylebox)
	
	theme.add_type("LeftConnectedLineEdit")
	theme.set_type_variation("LeftConnectedLineEdit", "LineEdit")
	theme.set_font_size("font_size", "LeftConnectedLineEdit", 12)
	theme.set_font("font", "LeftConnectedLineEdit", mono_font)
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
	left_connected_disabled_stylebox.bg_color = common_inner_color_disabled
	left_connected_disabled_stylebox.border_color = common_border_color_disabled
	theme.set_stylebox("read_only", "LeftConnectedLineEdit", left_connected_disabled_stylebox)
	
	var left_connected_normal_stylebox := left_connected_stylebox.duplicate()
	left_connected_normal_stylebox.bg_color = line_edit_background_color
	left_connected_normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "LeftConnectedLineEdit", left_connected_normal_stylebox)
	
	var left_connected_hover_stylebox := left_connected_stylebox.duplicate()
	left_connected_hover_stylebox.draw_center = false
	left_connected_hover_stylebox.border_color = line_edit_hover_border_overlay_color
	theme.set_stylebox("hover", "LeftConnectedLineEdit", left_connected_hover_stylebox)
	
	var left_connected_focus_stylebox := left_connected_stylebox.duplicate()
	left_connected_focus_stylebox.draw_center = false
	left_connected_focus_stylebox.border_color = line_edit_focus_color
	theme.set_stylebox("focus", "LeftConnectedLineEdit", left_connected_focus_stylebox)
	
	theme.add_type("RightConnectedLineEdit")
	theme.set_type_variation("RightConnectedLineEdit", "LineEdit")
	theme.set_font_size("font_size", "RightConnectedLineEdit", 12)
	theme.set_font("font", "RightConnectedLineEdit", mono_font)
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
	right_connected_disabled_stylebox.bg_color = common_inner_color_disabled
	right_connected_disabled_stylebox.border_color = common_border_color_disabled
	theme.set_stylebox("read_only", "RightConnectedLineEdit", right_connected_disabled_stylebox)
	
	var right_connected_normal_stylebox := right_connected_stylebox.duplicate()
	right_connected_normal_stylebox.bg_color = line_edit_background_color
	right_connected_normal_stylebox.border_color = line_edit_normal_border_color
	theme.set_stylebox("normal", "RightConnectedLineEdit", right_connected_normal_stylebox)
	
	var right_connected_hover_stylebox := right_connected_stylebox.duplicate()
	right_connected_hover_stylebox.draw_center = false
	right_connected_hover_stylebox.border_color = line_edit_hover_border_overlay_color
	theme.set_stylebox("hover", "RightConnectedLineEdit", right_connected_hover_stylebox)
	
	var right_connected_focus_stylebox := right_connected_stylebox.duplicate()
	right_connected_focus_stylebox.draw_center = false
	right_connected_focus_stylebox.border_color = line_edit_focus_color
	theme.set_stylebox("focus", "RightConnectedLineEdit", right_connected_focus_stylebox)
	
	theme.add_type("MiniLineEdit")
	theme.set_color("font_color", "MiniLineEdit", common_editable_text_color)
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
	mini_stylebox_normal.bg_color = line_edit_background_color
	mini_stylebox_normal.border_color = mini_line_edit_normal_border_color
	theme.set_stylebox("normal", "MiniLineEdit", mini_stylebox_normal)
	
	var mini_stylebox_hover := mini_stylebox.duplicate()
	mini_stylebox_hover.draw_center = false
	var mini_line_edit_hover_border_overlay_color := line_edit_hover_border_overlay_color
	mini_line_edit_hover_border_overlay_color.a *= 1.5
	mini_stylebox_hover.border_color = mini_line_edit_hover_border_overlay_color
	theme.set_stylebox("hover", "MiniLineEdit", mini_stylebox_hover)
	
	var mini_stylebox_pressed := mini_stylebox.duplicate()
	mini_stylebox_pressed.draw_center = false
	mini_stylebox_pressed.border_color = line_edit_focus_color
	theme.set_stylebox("focus", "MiniLineEdit", mini_stylebox_pressed)
	
	theme.add_type("GoodColorPickerLineEdit")
	theme.set_type_variation("GoodColorPickerLineEdit", "LineEdit")
	theme.set_font_size("font_size", "GoodColorPickerLineEdit", 11)
	theme.set_font("font", "GoodColorPickerLineEdit", mono_font)
	var color_picker_line_edit_stylebox := StyleBoxFlat.new()
	color_picker_line_edit_stylebox.set_corner_radius_all(2)
	color_picker_line_edit_stylebox.bg_color = line_edit_background_color
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
	h_grabber_stylebox.bg_color = scrollbar_normal_color
	theme.set_stylebox("grabber", "HScrollBar", h_grabber_stylebox)
	
	var h_grabber_stylebox_hover := h_stylebox.duplicate()
	h_grabber_stylebox_hover.bg_color = scrollbar_hover_color
	theme.set_stylebox("grabber_highlight", "HScrollBar", h_grabber_stylebox_hover)
	
	var h_grabber_stylebox_pressed := h_stylebox.duplicate()
	h_grabber_stylebox_pressed.bg_color = scrollbar_pressed_color
	theme.set_stylebox("grabber_pressed", "HScrollBar", h_grabber_stylebox_pressed)
	
	var h_scroll_stylebox := StyleBoxFlat.new()
	h_scroll_stylebox.set_corner_radius_all(3)
	h_scroll_stylebox.content_margin_top = 4
	h_scroll_stylebox.content_margin_bottom = 4
	h_scroll_stylebox.bg_color = scrollbar_background_color
	theme.set_stylebox("scroll", "HScrollBar", h_scroll_stylebox)
	
	theme.add_type("VScrollBar")
	var v_stylebox := StyleBoxFlat.new()
	v_stylebox.set_corner_radius_all(3)
	v_stylebox.content_margin_top = 2.0
	v_stylebox.content_margin_bottom = 2.0
	
	var v_grabber_stylebox := v_stylebox.duplicate()
	v_grabber_stylebox.bg_color = scrollbar_normal_color
	theme.set_stylebox("grabber", "VScrollBar", v_grabber_stylebox)
	
	var v_grabber_stylebox_hover := v_stylebox.duplicate()
	v_grabber_stylebox_hover.bg_color = scrollbar_hover_color
	theme.set_stylebox("grabber_highlight", "VScrollBar", v_grabber_stylebox_hover)
	
	var v_grabber_stylebox_pressed := v_stylebox.duplicate()
	v_grabber_stylebox_pressed.bg_color = scrollbar_pressed_color
	theme.set_stylebox("grabber_pressed", "VScrollBar", v_grabber_stylebox_pressed)
	
	var v_scroll_stylebox := StyleBoxFlat.new()
	v_scroll_stylebox.set_corner_radius_all(3)
	v_scroll_stylebox.content_margin_left = 4.0
	v_scroll_stylebox.content_margin_right = 4.0
	v_scroll_stylebox.bg_color = scrollbar_background_color
	theme.set_stylebox("scroll", "VScrollBar", v_scroll_stylebox)

static func _setup_separator(theme: Theme) -> void:
	theme.add_type("HSeparator")
	var stylebox := StyleBoxLine.new()
	stylebox.color = common_panel_border_color
	stylebox.thickness = 2
	theme.set_stylebox("separator", "HSeparator", stylebox)
	
	theme.add_type("SmallHSeparator")
	theme.set_type_variation("SmallHSeparator", "HSeparator")
	var small_stylebox := stylebox.duplicate()
	small_stylebox.color = Color(common_panel_border_color, 0.5)
	small_stylebox.grow_begin = -3
	small_stylebox.grow_end = -3
	theme.set_stylebox("separator", "SmallHSeparator", small_stylebox)

static func _setup_label(theme: Theme) -> void:
	theme.add_type("Label")
	
	theme.add_type("RichTextLabel")
	theme.set_color("selection_color", "RichTextLabel", common_selection_color)
	theme.set_font("bold_font", "RichTextLabel", bold_font)

static func _setup_tabcontainer(theme: Theme) -> void:
	theme.add_type("TabContainer")
	theme.set_color("font_unselected_color", "TabContainer", common_dim_text_color)
	theme.set_color("font_hovered_color", "TabContainer", common_text_color)
	theme.set_color("font_selected_color", "TabContainer", common_highlighted_text_color)
	theme.set_constant("side_margin", "TabContainer", 0)
	theme.set_font_size("font_size", "TabContainer", 14)
	
	var panel_stylebox := StyleBoxFlat.new()
	panel_stylebox.bg_color = tab_container_panel_inner_color
	panel_stylebox.border_color = tab_container_panel_border_color
	panel_stylebox.border_width_left = 2
	panel_stylebox.border_width_right = 2
	panel_stylebox.border_width_bottom = 2
	panel_stylebox.corner_radius_bottom_right = 5
	panel_stylebox.corner_radius_bottom_left = 5
	panel_stylebox.content_margin_left = 8
	panel_stylebox.content_margin_right = 2
	panel_stylebox.content_margin_bottom = 2
	panel_stylebox.content_margin_top = 0
	theme.set_stylebox("panel", "TabContainer", panel_stylebox)
	
	var tab_disabled_stylebox := StyleBoxEmpty.new()
	tab_disabled_stylebox.content_margin_left = 12
	tab_disabled_stylebox.content_margin_right = 12
	tab_disabled_stylebox.content_margin_bottom = 3
	tab_disabled_stylebox.content_margin_top = 3
	theme.set_stylebox("tab_disabled", "TabContainer", tab_disabled_stylebox)
	theme.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	
	var tab_hover_stylebox := StyleBoxFlat.new()
	tab_hover_stylebox.bg_color = hovered_tab_color
	tab_hover_stylebox.corner_radius_top_left = 4
	tab_hover_stylebox.corner_radius_top_right = 4
	tab_hover_stylebox.content_margin_left = 12
	tab_hover_stylebox.content_margin_right = 12
	tab_hover_stylebox.content_margin_bottom = 3
	tab_hover_stylebox.content_margin_top = 3
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hover_stylebox)
	
	var tab_selected_stylebox := StyleBoxFlat.new()
	tab_selected_stylebox.bg_color = selected_tab_color
	tab_selected_stylebox.border_color = selected_tab_border_color
	tab_selected_stylebox.border_width_top = 2
	tab_selected_stylebox.content_margin_left = 12
	tab_selected_stylebox.content_margin_right = 12
	tab_selected_stylebox.content_margin_bottom = 3
	tab_selected_stylebox.content_margin_top = 3
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected_stylebox)
	
	var tab_unselected_stylebox := StyleBoxFlat.new()
	tab_unselected_stylebox.bg_color = normal_tab_color
	tab_unselected_stylebox.corner_radius_top_left = 4
	tab_unselected_stylebox.corner_radius_top_right = 4
	tab_unselected_stylebox.content_margin_left = 12
	tab_unselected_stylebox.content_margin_right = 12
	tab_unselected_stylebox.content_margin_bottom = 3
	tab_unselected_stylebox.content_margin_top = 3
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected_stylebox)
	
	var tabbar_background_stylebox := StyleBoxFlat.new()
	tabbar_background_stylebox.bg_color = tabbar_background_color
	tabbar_background_stylebox.set_content_margin_all(0)
	tabbar_background_stylebox.corner_radius_top_left = 5
	tabbar_background_stylebox.corner_radius_top_right = 5
	theme.set_stylebox("tabbar_background", "TabContainer", tabbar_background_stylebox)

static func _setup_textedit(theme: Theme) -> void:
	theme.add_type("TextEdit")
	theme.set_color("caret_color", "TextEdit", Color.TRANSPARENT)
	theme.set_color("selection_color", "TextEdit", common_selection_color)
	theme.set_font_size("font_size", "TextEdit", 12)
	theme.set_font("font", "TextEdit", mono_font)
	
	var normal_stylebox := StyleBoxFlat.new()
	normal_stylebox.bg_color = line_edit_background_color
	normal_stylebox.border_color = line_edit_normal_border_color
	normal_stylebox.set_border_width_all(2)
	normal_stylebox.set_corner_radius_all(5)
	normal_stylebox.content_margin_left = 5
	theme.set_stylebox("normal", "TextEdit", normal_stylebox)
	
	var focus_stylebox := StyleBoxFlat.new()
	focus_stylebox.draw_center = false
	focus_stylebox.border_color = line_edit_focus_color
	focus_stylebox.set_border_width_all(2)
	focus_stylebox.set_corner_radius_all(5)
	theme.set_stylebox("focus", "TextEdit", focus_stylebox)
	
	var hover_stylebox := StyleBoxFlat.new()
	hover_stylebox.draw_center = false
	hover_stylebox.border_color = line_edit_hover_border_overlay_color
	hover_stylebox.set_border_width_all(2)
	hover_stylebox.set_corner_radius_all(5)
	theme.set_stylebox("hover", "TextEdit", hover_stylebox)

static func _setup_tooltip(theme: Theme) -> void:
	theme.add_type("TooltipPanel")
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = common_panel_inner_color
	stylebox.border_color = common_panel_border_color
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(2)
	stylebox.content_margin_left = 6
	stylebox.content_margin_top = 1
	stylebox.content_margin_right = 6
	stylebox.content_margin_bottom = 3
	theme.set_stylebox("panel", "TooltipPanel", stylebox)
	
	theme.add_type("TooltipLabel")
	theme.set_color("font_color", "TooltipLabel", common_text_color)
	theme.set_font_size("font_size", "TooltipLabel", 14)
	theme.set_font("font", "TooltipLabel", regular_font)


static func _icon(name: String) -> Texture2D:
	return load("res://assets/icons/theme/" + name + ".svg")
