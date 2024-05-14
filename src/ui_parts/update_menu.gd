extends PanelContainer

@onready var status_label: RichTextLabel = %Status
@onready var check_button: Button = %Check
#@onready var prereleases_checkbox: CheckBox = %IncludePrereleases
@onready var http: HTTPRequest = %HTTPRequest


func _ready() -> void:
	status_label.text = "[center]Current Version: " + ProjectSettings.get_setting("application/config/version")

func _on_check_pressed() -> void:
	check_button.disabled = true
	status_label.text = "[center]Checking..."

	var err := http.request(
		"https://api.github.com/repos/MewPurPur/GodSVG/releases",
		["User-Agent: MewPurPur/GodSVG"]
	)

	if err:
		_failed(error_string(err))


func _on_request_completed(result: HTTPRequest.Result, response_code: int,
_headers: PackedStringArray, body: PackedByteArray) -> void:
	match result:
		http.RESULT_SUCCESS:
			if not response_code == 200:
				_failed("Response code "+str(response_code))
				return
			
			var json = JSON.parse_string(body.get_string_from_utf8())
			if not json:
				_failed("Failed to decode JSON")
				return
			
			# Always enabled as long as there is no stable GodSVG release yet.
			var include_prereleases := true  # prereleases_checkbox.button_pressed
			var latest_ver := ""
			var latest_url := ""
			var latest_timestamp := 0
			
			for release: Dictionary in json:
				var is_prerelease := release["prerelease"] as bool
				if is_prerelease and not include_prereleases:
					continue
				
				var timestamp := Time.get_unix_time_from_datetime_string(release["created_at"] as String)
				
				if timestamp > latest_timestamp:
					latest_timestamp = timestamp
					latest_ver = release["name"]
					latest_url = release["html_url"]
			
			var current_ver := ProjectSettings.get_setting("application/config/version") as String
			
			
			if latest_ver == current_ver:
				status_label.text = "[center]No new version available."
			else:
				status_label.parse_bbcode("[center][url=%s]New version available![/url] %s" % [latest_ver, latest_url])
			
			check_button.disabled = false

		http.RESULT_TIMEOUT:
			_failed("Request timed out ("+str(http.timeout)+"s)")
			return
		_:
			_failed("Error code "+str(result))
			return


func _failed(msg: String) -> void:
	status_label.text = "Failed to check for updates:\n"+msg
	check_button.disabled = false


func _on_close_pressed() -> void:
	HandlerGUI.remove_overlay()


func _on_status_label_link_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
