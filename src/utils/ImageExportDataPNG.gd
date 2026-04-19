class_name ImageExportDataPNG extends ImageExportDataRaster

func get_format() -> String:
	return "png"

func image_to_buffer(image: Image) -> PackedByteArray:
	return image.save_png_to_buffer()

func load_from_buffer(image: Image, buffer: PackedByteArray) -> void:
	image.load_png_from_buffer(buffer)

func generate_and_save_image_to_path(file_path: String) -> void:
	return generate_image().save_png(file_path)

func inject_ui_to_control(main_container: VBoxContainer, dimensions: Vector2) -> void:
	var background_hbox := HBoxContainer.new()
	main_container.add_child(background_hbox)
	var background_label := Label.new()
	background_label.text = Translator.translate("Background") + ":"
	background_hbox.add_child(background_label)
	var background_edit := ColorEditWithOptionsScene.instantiate()
	background_edit.setup(true, PackedStringArray(["#ffffff00", "#ffffff", "#000000"]), background_color)
	background_hbox.add_child(background_edit)
	var export_scale_config := ExportScaleConfigScene.instantiate()
	export_scale_config.setup(dimensions, upscale_amount, 65535)  # The limitation is actually 2 million pixels.
	main_container.add_child(export_scale_config)
	
	background_edit.color_picked.connect(set_background_color)
	export_scale_config.scale_changed.connect(set_upscale_amount)
	
	var _on_changed :=\
		func() -> void:
			background_edit.set_color_no_signal(background_color.to_html(true and background_color.a < 1.0))
			export_scale_config.set_export_scale(upscale_amount)
	changed.connect(_on_changed)
	background_edit.tree_exited.connect(changed.disconnect.bind(_on_changed))
	_on_changed.call()
	
	HandlerGUI.register_focus_sequence(main_container, [background_edit, export_scale_config])
