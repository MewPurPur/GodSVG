extends PanelContainer

@onready var http: HTTPRequest = $HTTPRequest
@onready var status_label: Label = %OverStatusContainer/StatusLabel
@onready var retry_button: Button = %OverStatusContainer/RetryButton
@onready var results_label: RichTextLabel = %Results
@onready var results_panel: PanelContainer = %ResultsPanel
@onready var current_version_label: Label = $VBoxContainer/CurrentVersionLabel
@onready var prereleases_button: CheckButton = $VBoxContainer/IncludePrereleases
@onready var close_button: Button = $VBoxContainer/CloseButton

var current_version: String = ProjectSettings.get_setting("application/config/version")
var results: Dictionary[String, Array] = {}  # version: [url, is_prerelease]

func _ready() -> void:
	http.request_completed.connect(_on_request_completed)
	retry_button.pressed.connect(request)
	results_label.meta_clicked.connect(OS.shell_open)
	close_button.pressed.connect(queue_free)
	prereleases_button.toggled.connect(display_results.unbind(1))
	
	close_button.text = Translator.translate("Close")
	retry_button.tooltip_text = Translator.translate("Retry")
	retry_button.hide()
	prereleases_button.text = Translator.translate("Show prereleases")
	current_version_label.text = Translator.translate("Current Version") + ": " + current_version
	request()
	HandlerGUI.register_focus_sequence(self, [prereleases_button, retry_button, close_button], true)

func request() -> void:
	status_label.text = Translator.translate("Retrieving information...")
	var err := http.request("https://api.github.com/repos/MewPurPur/GodSVG/releases", ["User-Agent: MewPurPur/GodSVG"])
	if err != OK:
		display_error_message(error_string(err))

# Do not internationalize the errors.
func _on_request_completed(http_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	match http_result:
		http.RESULT_SUCCESS:
			retry_button.hide()
			
			if response_code != 200:
				display_error_message("Response code %d" % response_code)
				return
			
			var json: Variant = JSON.parse_string(body.get_string_from_utf8())
			if json == null:
				display_error_message("Failed to decode JSON")
				return
			
			var current_timestamp := -1
			for release: Dictionary in json:
				if release["name"] == current_version:
					current_timestamp = Time.get_unix_time_from_datetime_string(release["created_at"])
					var is_prerelease: bool = release["prerelease"]
					if is_prerelease:
						prereleases_button.disabled = false
						prereleases_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
						prereleases_button.set_pressed_no_signal(is_prerelease)
					break
			
			if current_timestamp == -1:
				display_error_message("Unable to compare versions")
				return
			
			for release: Dictionary in json:
				var creation_time: String = release["created_at"]
				var timestamp := Time.get_unix_time_from_datetime_string(creation_time)
				if timestamp > current_timestamp:
					results[release["name"]] = [release["html_url"], release["prerelease"]]
			
			display_results()
		
		http.RESULT_TIMEOUT:
			display_error_message("Request timed out (%d sec)" % http.timeout)
		http.RESULT_CANT_CONNECT, http.RESULT_CONNECTION_ERROR, http.RESULT_CANT_RESOLVE:
			display_error_message("Connection failed")
		_:
			display_error_message("Error code %d" % http_result)


func display_error_message(msg: String) -> void:
	status_label.text = Translator.translate("Update check failed")
	results_panel.show()
	results_label.text = msg + "\n[url=https://github.com/MewPurPur/GodSVG/releases]%s[/url]" % Translator.translate("View all releases")
	retry_button.show()

func display_results() -> void:
	# Check if there are results to be displayed.
	var has_results := false
	if prereleases_button.button_pressed:
		has_results = not results.is_empty()
	else:
		for version in results:
			if results[version][1] == false:
				has_results = true
				break
	# Set the text.
	results_label.text = ""
	if not has_results:
		status_label.text = Translator.translate("GodSVG is up-to-date.")
		results_panel.hide()
		return
	else:
		status_label.text = Translator.translate("New versions available!")
		for version in results:
			var result := results[version]
			if prereleases_button.button_pressed or result[1] == false:
				if OS.has_feature("web"):
					results_label.text += version + "\n"
				else:
					results_label.text += "[url=%s]%s[/url]\n" % [result[0], version]
		results_label.text = results_label.text.strip_edges()
		results_panel.show()
