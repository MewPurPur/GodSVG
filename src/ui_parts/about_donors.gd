extends VBoxContainer

@onready var diamond_donors_label: Label = $DiamondDonors/Label
@onready var diamond_donors_list: PanelGrid = $DiamondDonors/List
@onready var golden_donors_label: Label = $GoldenDonors/Label
@onready var golden_donors_list: PanelGrid = $GoldenDonors/List
@onready var donors_label: Label = $Donors/Label
@onready var donors_list: PanelGrid = $Donors/List
@onready var past_diamond_donors_label: Label = $PastDiamondDonors/Label
@onready var past_diamond_donors_list: PanelGrid = $PastDiamondDonors/List
@onready var past_golden_donors_label: Label = $PastGoldenDonors/Label
@onready var past_golden_donors_list: PanelGrid = $PastGoldenDonors/List
@onready var past_donors_label: Label = $PastDonors/Label
@onready var past_donors_list: PanelGrid = $PastDonors/List


func _ready() -> void:
	var app_info := Utils.get_app_info()
	
	donors_label.text = Translator.translate("Donors")
	golden_donors_label.text = Translator.translate("Golden donors")
	diamond_donors_label.text = Translator.translate("Diamond donors")
	
	# Once the past donors lists start filling up, they will never unfill,
	# so no need to bother with logic, we can just unhide it manually.
	if app_info.donors.is_empty() and app_info.anonymous_donors == 0:
		donors_list.hide()
	else:
		donors_list.items = app_info.donors
		if app_info.anonymous_donors != 0:
			donors_list.dim_last_item = true
			donors_list.items.append("%d anonymous" % app_info.anonymous_donors)
	
	if app_info.golden_donors.is_empty() and app_info.anonymous_golden_donors == 0:
		golden_donors_list.hide()
	else:
		golden_donors_list.items = app_info.golden_donors
		if app_info.anonymous_golden_donors != 0:
			golden_donors_list.dim_last_item = true
			golden_donors_list.items.append("%d anonymous" % app_info.anonymous_golden_donors)
	
	if app_info.diamond_donors.is_empty() and app_info.anonymous_diamond_donors == 0:
		diamond_donors_list.hide()
	else:
		diamond_donors_list.items = app_info.diamond_donors
		if app_info.anonymous_diamond_donors != 0:
			diamond_donors_list.dim_last_item = true
			diamond_donors_list.items.append("%d anonymous" % app_info.anonymous_diamond_donors)
	
	past_donors_list.items = app_info.past_donors
	if app_info.past_anonymous_donors != 0:
		past_donors_list.dim_last_item = true
		past_donors_list.items.append("%d anonymous" % app_info.past_anonymous_donors)
	
	past_golden_donors_list.items = app_info.past_golden_donors
	if app_info.past_anonymous_golden_donors != 0:
		past_golden_donors_list.dim_last_item = true
		past_golden_donors_list.items.append("%d anonymous" % app_info.past_anonymous_golden_donors)
	
	past_donors_list.items = app_info.past_diamond_donors
	if app_info.past_anonymous_diamond_donors != 0:
		past_diamond_donors_list.dim_last_item = true
		past_diamond_donors_list.items.append("%d anonymous" % app_info.past_anonymous_diamond_donors)
