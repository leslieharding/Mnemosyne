# res://Scripts/feedback_manager.gd
extends Node

const WEBHOOK_URL = "https://discord.com/api/webhooks/1505355872304627913/BorpfKtgDKuQK6DQqzNQaCLJSmGFl6glKe9MK_0fXI0fZ1UGE_k_KGucIYh0mmnAR-zz"

var overlay: CanvasLayer = null
var http_request: HTTPRequest
var is_open: bool = false

# UI refs
var category_option: OptionButton
var text_input: TextEdit
var status_label: Label
var submit_button: Button


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)


func _input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_F1:
			if is_open:
				close_overlay()
			else:
				open_overlay()
			get_viewport().set_input_as_handled()


func open_overlay():
	if is_open:
		return
	is_open = true
	get_tree().paused = true

	if overlay == null:
		build_overlay()

	overlay.visible = true
	text_input.text = ""
	status_label.text = ""
	submit_button.disabled = false
	category_option.selected = 0
	text_input.grab_focus()


func close_overlay():
	if not is_open:
		return
	is_open = false
	get_tree().paused = false
	if overlay:
		overlay.visible = false


func build_overlay():
	overlay = CanvasLayer.new()
	overlay.layer = 10
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	# Full-screen dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.add_child(bg)

	# Centered panel
	var panel = PanelContainer.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -200
	panel.offset_bottom = 200
	bg.add_child(panel)

	var margin = MarginContainer.new()
	margin.process_mode = Node.PROCESS_MODE_ALWAYS
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Playtest Feedback  (F1 to close)"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Category label + dropdown
	var cat_label = Label.new()
	cat_label.text = "Category:"
	vbox.add_child(cat_label)

	category_option = OptionButton.new()
	category_option.process_mode = Node.PROCESS_MODE_ALWAYS
	category_option.add_item("Bug")
	category_option.add_item("Balance")
	category_option.add_item("Feel / UX")
	category_option.add_item("Other")
	vbox.add_child(category_option)

	# Feedback label + text box
	var fb_label = Label.new()
	fb_label.text = "Feedback:"
	vbox.add_child(fb_label)

	text_input = TextEdit.new()
	text_input.process_mode = Node.PROCESS_MODE_ALWAYS
	text_input.custom_minimum_size = Vector2(0, 100)
	text_input.placeholder_text = "Describe what happened or what you noticed..."
	text_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(text_input)

	# Submit / Cancel buttons
	var hbox = HBoxContainer.new()
	hbox.process_mode = Node.PROCESS_MODE_ALWAYS
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	submit_button = Button.new()
	submit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	submit_button.text = "Submit"
	submit_button.custom_minimum_size = Vector2(120, 0)
	submit_button.pressed.connect(_on_submit_pressed)
	hbox.add_child(submit_button)

	var cancel_button = Button.new()
	cancel_button.process_mode = Node.PROCESS_MODE_ALWAYS
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(120, 0)
	cancel_button.pressed.connect(close_overlay)
	hbox.add_child(cancel_button)

	# Status line
	status_label = Label.new()
	status_label.process_mode = Node.PROCESS_MODE_ALWAYS
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	vbox.add_child(status_label)


func _on_submit_pressed():
	var feedback_text = text_input.text.strip_edges()
	if feedback_text.is_empty():
		status_label.text = "Please enter some feedback first."
		status_label.add_theme_color_override("font_color", Color("#FF6666"))
		return

	submit_button.disabled = true
	status_label.text = "Sending..."
	status_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	send_feedback(feedback_text)


func gather_context() -> Dictionary:
	var ctx = {}

	var current_scene = get_tree().current_scene
	ctx["scene"] = current_scene.scene_file_path.get_file().get_basename() \
		if current_scene else "Unknown"

	if get_tree().has_meta("scene_params"):
		var params = get_tree().get_meta("scene_params")
		ctx["god"] = str(params.get("god", "None"))
		ctx["deck_index"] = str(params.get("deck_index", "None"))
	else:
		ctx["god"] = "None"
		ctx["deck_index"] = "None"

	ctx["platform"] = OS.get_name()
	ctx["timestamp"] = Time.get_datetime_string_from_system(true, false) + "Z"

	return ctx


func send_feedback(feedback_text: String):
	var ctx = gather_context()
	var categories = ["Bug", "Balance", "Feel / UX", "Other"]
	var category = categories[category_option.selected]

	var embed = {
		"title": "🎮 " + category + " — Playtest Feedback",
		"color": get_category_color(category),
		"fields": [
			{"name": "Scene", "value": ctx["scene"], "inline": true},
			{"name": "God", "value": ctx["god"], "inline": true},
			{"name": "Deck Index", "value": ctx["deck_index"], "inline": true},
			{"name": "Platform", "value": ctx["platform"], "inline": true},
			{"name": "Feedback", "value": feedback_text, "inline": false}
		],
		"timestamp": ctx["timestamp"]
	}

	var payload = JSON.stringify({"embeds": [embed]})
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(WEBHOOK_URL, headers, HTTPClient.METHOD_POST, payload)

	if error != OK:
		status_label.text = "Request error: " + str(error) + ". Note your feedback manually."
		status_label.add_theme_color_override("font_color", Color("#FF6666"))
		submit_button.disabled = false


func get_category_color(category: String) -> int:
	match category:
		"Bug":       return 0xFF4444
		"Balance":   return 0xFFAA00
		"Feel / UX": return 0x44AAFF
		_:           return 0x888888


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	# Discord returns 204 No Content on success
	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 204]:
		status_label.text = "Sent! Thank you."
		status_label.add_theme_color_override("font_color", Color("#44FF44"))
		await get_tree().create_timer(1.5).timeout
		close_overlay()
	else:
		var msg = "Failed (HTTP %d). Please note your feedback manually." % response_code
		if result != HTTPRequest.RESULT_SUCCESS:
			msg = "Network error (%d). Please note your feedback manually." % result
		status_label.text = msg
		status_label.add_theme_color_override("font_color", Color("#FF6666"))
		submit_button.disabled = false
