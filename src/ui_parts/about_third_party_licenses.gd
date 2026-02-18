extends VBoxContainer

const UNUSED_MODULE_PATHS: PackedStringArray = ["modules/betsy", "modules/godot_physics_2d",
	"modules/godot_physics_3d", "modules/jolt_physics", "modules/lightmapper_rd", "thirdparty/brotli",
	"thirdparty/cvtt", "thirdparty/basis_universal", "thirdparty/d3d12", "thirdparty/etcpak",
	"thirdparty/graphite", "thirdparty/meshoptimizer", "thirdparty/minimp3", "thirdparty/minizip",
	"thirdparty/openxr", "thirdparty/tinyexr", "thirdparty/vhacd", "thirdparty/volk",
	"thirdparty/vulkan", "thirdparty/xatlas"
]

@onready var godsvg_parts: VBoxContainer = $GodSVGParts
@onready var godot_parts: VBoxContainer = $GodotParts
@onready var license_texts: VBoxContainer = $LicenseTexts

func _ready() -> void:
	for control: Control in [godsvg_parts, godot_parts, license_texts]:
		for child in control.get_children():
			child.queue_free()
	
	# This part doesn't need to be translated.
	var godsvg_parts_label := Label.new()
	godsvg_parts_label.text = "GodSVG components"
	var godot_parts_label := Label.new()
	godot_parts_label.text = "Godot Engine components"
	var license_texts_label := Label.new()
	license_texts_label.text = "Licenses"
	for label: Label in [godsvg_parts_label, godot_parts_label, license_texts_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = "TitleLabel"
		label.add_theme_font_size_override("font_size", 17)
	godsvg_parts.add_child(godsvg_parts_label)
	godot_parts.add_child(godot_parts_label)
	license_texts.add_child(license_texts_label)
	
	var godot_copyright_info := Engine.get_copyright_info()
	var godot_engine_copyright: Dictionary
	for dict in godot_copyright_info:
		if dict.name == "Godot Engine":
			dict.parts[0].erase("files")
			godot_engine_copyright = dict
			break
	
	var godsvg_copyright_info: Array[Dictionary] = [
		godot_engine_copyright,
		{
			"name": "Noto Sans font",
			"parts": [
				{
					"copyright": ["2012, Google Inc."],
					"license": "OFL-1.1",
					"files": ["res://visual/fonts/original/NotoSans-SemiBold.woff2", "res://visual/fonts/original/NotoSans-ExtraBold.woff2"]
				}
			]
		},
		{
			"name": "Droid Sans font",
			"parts": [
				{
					"copyright": ["2008, The Android Open Source Project"],
					"license": "Apache-2.0",
					"files": ["res://visual/fonts/original/DroidSansFallback.woff2"]
				}
			]
		},
		{
			"name": "JetBrains Mono font",
			"parts": [
				{
					"copyright": ["2020, JetBrains s.r.o."],
					"license": "OFL-1.1",
					"files": ["res://visual/fonts/original/JetBrainsMono-Medium.woff2"]
				}
			]
		}
	]
	
	for copyright_info in godsvg_copyright_info:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 11)
		for part in copyright_info["parts"]:
			if part.has("files"):
				label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
			label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
		var vbox := VBoxContainer.new()
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.text = copyright_info["name"]
		vbox.add_child(name_label)
		vbox.add_child(label)
		godsvg_parts.add_child(vbox)
	
	# Clean up Godot's copyright info from some stripped modules to show more relevant components and load the UI faster.
	var used_licenses: PackedStringArray
	for copyright_info_idx in range(godot_copyright_info.size() - 1, -1, -1):
		var copyright_info: Dictionary = godot_copyright_info[copyright_info_idx]
		for part_idx in range(copyright_info["parts"].size() -1, -1, -1):
			var part: Dictionary = copyright_info["parts"][part_idx]
			if part.has("files"):
				for i in range(part["files"].size() - 1, -1, -1):
					for module_path in UNUSED_MODULE_PATHS:
						if module_path in part["files"][i]:
							part["files"].remove_at(i)
							break
				if part["files"].is_empty():
					godot_copyright_info.erase(copyright_info)
				else:
					var used_license: String = part["license"]
					if not used_license in used_licenses:
						used_licenses.append(used_license)
	
	for copyright_info in godot_copyright_info:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 11)
		for part in copyright_info["parts"]:
			if part.has("files"):
				label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
			label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
		var vbox := VBoxContainer.new()
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.text = copyright_info["name"]
		vbox.add_child(name_label)
		vbox.add_child(label)
		godot_parts.add_child(vbox)
	
	var licenses_dict := Engine.get_license_info()
	for license_name in licenses_dict:
		if not license_name in used_licenses:
			continue
		var license_vbox := VBoxContainer.new()
		var license_title := Label.new()
		license_title.add_theme_font_size_override("font_size", 14)
		license_title.text = license_name
		license_vbox.add_child(license_title)
		var license_text := Label.new()
		license_text.add_theme_font_override("font", ThemeUtils.mono_font)
		license_text.add_theme_font_size_override("font_size", 11)
		license_text.text = licenses_dict[license_name]
		license_vbox.add_child(license_text)
		license_texts_label.add_child(license_vbox)
