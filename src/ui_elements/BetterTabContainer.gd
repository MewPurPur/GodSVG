## A TabContainer with translated tab titles
class_name BetterTabContainer extends TabContainer

var tab_keys: Array

func _ready() -> void:
	for i in get_tab_count():
		tab_keys.append(get_tab_title(i))
	translate_titles()
	GlobalSettings.language_changed.connect(translate_titles)

func translate_titles() -> void:
	for i in tab_keys.size():
		set_tab_title(i,tr(tab_keys[i]))
