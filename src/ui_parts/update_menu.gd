extends PanelContainer

@onready var http: HTTPRequest = $HTTPRequest
@onready var status_label: RichTextLabel = $VBoxContainer/Status
@onready var current_version_label: Label = $VBoxContainer/CurrentVersionLabel
@onready var prereleases_checkbox: CheckBox = $VBoxContainer/IncludePrereleases
@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var close_button: Button = $VBoxContainer/CloseButton

var current_version: String = ProjectSettings.get_setting("application/config/version")
var results := {}  # Dictionary{String: String}  version: [url, is_prerelease]

func _ready() -> void:
	http.request_completed.connect(_on_request_completed)
	retry_button.pressed.connect(_on_retry)
	status_label.meta_clicked.connect(OS.shell_open)
	close_button.pressed.connect(queue_free)
	prereleases_checkbox.toggled.connect(display_results.unbind(1))
	
	close_button.text = TranslationServer.translate("Close")
	prereleases_checkbox.text = TranslationServer.translate("Include prereleases")
	retry_button.text = TranslationServer.translate("Retry")
	current_version_label.text = TranslationServer.translate("Current Version") + ": " +\
			current_version
	request()

func request() -> void:
	retry_button.hide()
	status_label.text = TranslationServer.translate("Retrieving information...")
	var err := http.request("https://api.github.com/repos/MewPurPur/GodSVG/releases",
			["User-Agent: MewPurPur/GodSVG"])
	if err != OK:
		display_error_message(error_string(err))

# Do not internationalize the errors.
func _on_request_completed(http_result: HTTPRequest.Result, response_code: int,
_headers: PackedStringArray, body: PackedByteArray) -> void:
	match http_result:
		http.RESULT_SUCCESS:
			if response_code != 200:
				display_error_message("Response code %d" % response_code)
				return
			
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json == null:
				display_error_message("Failed to decode JSON")
				return
			
			var current_timestamp := -1
			for release: Dictionary in json:
				if release["name"] == current_version:
					current_timestamp = Time.get_unix_time_from_datetime_string(
							release["created_at"])
					var is_prerelease: bool = release["prerelease"]
					if is_prerelease:
						prereleases_checkbox.disabled = false
						prereleases_checkbox.set_pressed_no_signal(is_prerelease)
					break
			
			for release: Dictionary in json:
				var creation_time: String = release["created_at"]
				var timestamp := Time.get_unix_time_from_datetime_string(creation_time)
				if timestamp > current_timestamp:
					results[release["name"]] = [release["html_url"], release["prerelease"]]
		http.RESULT_TIMEOUT:
			display_error_message("Request timed out (%d sec)" % http.timeout)
			return
		http.RESULT_CANT_CONNECT, http.RESULT_CONNECTION_ERROR, http.RESULT_CANT_RESOLVE:
			display_error_message("Connection failed")
			return
		_:
			display_error_message("Error code %d" % http_result)
			return
	display_results()


func display_error_message(msg: String) -> void:
	status_label.text = TranslationServer.translate("Update check failed") + ": %s" % msg
	retry_button.show()

func _on_retry() -> void:
	retry_button.hide()
	request()

func display_results() -> void:
	# Check if there are results to be displayed.
	var has_results := false
	if prereleases_checkbox.button_pressed:
		has_results = not results.is_empty()
	else:
		for version in results:
			if results[version][1] == false:
				has_results = true
				break
	# Set the text.
	if not has_results:
		status_label.text = TranslationServer.translate("GodSVG is up-to-date.")
		return
	else:
		status_label.text = TranslationServer.translate("New versions") + ":"
		for version in results:
			var result: Array = results[version]
			if prereleases_checkbox.button_pressed or result[1] == false:
				if OS.has_feature("web"):
					status_label.text += "\n%s" % version
				else:
					status_label.text += "\n[url=%s]%s[/url]" % [result[0], version]


func _on_close_pressed() -> void:
	HandlerGUI.remove_overlay()
