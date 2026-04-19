class_name ImageExportDataWEBP extends ImageExportDataRaster

@export var lossy := false:
	set(new_value):
		if new_value != lossy:
			lossy = new_value
			emit_changed()

@export var quality := 0.75:
	set(new_value):
		if new_value != quality:
			quality = new_value
			emit_changed()


func get_format() -> String:
	return "webp"

func image_to_buffer(image: Image) -> PackedByteArray:
	return image.save_webp_to_buffer(lossy, quality)

func load_from_buffer(image: Image, buffer: PackedByteArray) -> void:
	image.load_webp_from_buffer(buffer)

func generate_and_save_image_to_path(file_path: String) -> void:
	return generate_image().save_webp(file_path, lossy, quality)

func inject_ui_to_control(main_container: VBoxContainer, dimensions: Vector2) -> void:
	var quality_related_hbox := HBoxContainer.new()
	quality_related_hbox.add_theme_constant_override("separation", 12)
	main_container.add_child(quality_related_hbox)
	var lossless_checkbox := CheckBox.new()
	lossless_checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	lossless_checkbox.text = Translator.translate("Lossless")
	quality_related_hbox.add_child(lossless_checkbox)
	var quality_hbox := HBoxContainer.new()
	quality_related_hbox.add_child(quality_hbox)
	var quality_label := Label.new()
	quality_label.text = Translator.translate("Quality") + ":"
	quality_hbox.add_child(quality_label)
	var quality_edit := NumberEditScene.instantiate()
	quality_edit.min_value = 1.0
	quality_edit.max_value = 100.0
	quality_edit.initial_value = quality * 100
	quality_edit.is_float = false
	quality_edit.custom_minimum_size.x = 40
	quality_hbox.add_child(quality_edit)
	var background_hbox := HBoxContainer.new()
	main_container.add_child(background_hbox)
	var background_label := Label.new()
	background_label.text = Translator.translate("Background") + ":"
	background_hbox.add_child(background_label)
	var background_edit := ColorEditWithOptionsScene.instantiate()
	background_edit.setup(true, PackedStringArray(["#ffffff00", "#ffffff", "#000000"]), background_color)
	background_hbox.add_child(background_edit)
	var export_scale_config := ExportScaleConfigScene.instantiate()
	export_scale_config.setup(dimensions, upscale_amount, 16383)
	main_container.add_child(export_scale_config)
	
	lossless_checkbox.toggled.connect(
		func(toggled_on: bool) -> void:
			if is_instance_valid(borrowed_undo_redo):
				borrowed_undo_redo.create_action("")
				borrowed_undo_redo.add_do_property(self, "lossy", not toggled_on)
				borrowed_undo_redo.add_undo_property(self, "lossy", lossy)
				borrowed_undo_redo.commit_action()
			else:
				lossy = not toggled_on
	)
	quality_edit.value_changed.connect(
		func(new_value: float) -> void:
			var new_quality := new_value / 100
			if is_instance_valid(borrowed_undo_redo):
				borrowed_undo_redo.create_action("")
				borrowed_undo_redo.add_do_property(self, "quality", new_quality)
				borrowed_undo_redo.add_undo_property(self, "quality", quality)
				borrowed_undo_redo.commit_action()
			else:
				quality = new_quality
	)
	background_edit.color_picked.connect(set_background_color)
	export_scale_config.scale_changed.connect(set_upscale_amount)
	
	var _on_changed :=\
		func() -> void:
			lossless_checkbox.button_pressed = not lossy
			quality_hbox.visible = lossy
			quality_edit.text = String.num_uint64(roundi(quality * 100))
			background_edit.set_color_no_signal(background_color.to_html(true and background_color.a < 1.0))
			export_scale_config.set_export_scale(upscale_amount)
	changed.connect(_on_changed)
	background_edit.tree_exited.connect(changed.disconnect.bind(_on_changed))
	_on_changed.call()
	
	HandlerGUI.register_focus_sequence(main_container, [lossless_checkbox, quality_edit, background_edit, export_scale_config])
