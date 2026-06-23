# res://Scripts/run_summary.gd
extends Control

const XP_PER_LEVEL = 50
const SEGMENT_COUNT = 10
const BASE_ANIMATION_DURATION = 1.5
const LEVEL_UP_PAUSE = 0.3
const CARD_ANIMATION_STAGGER = 0.2

var god_name: String = "Apollo"
var deck_index: int = 0
var victory: bool = true

var card_animation_index: int = 0

# Snapshot of run exp taken BEFORE tracker is cleared
var _run_exp_snapshot: Dictionary = {}

# Results computed once in _ready
var _world_level_before: int = 0
var _world_level_after: int = 0
var _mnemosyne_upgrades: Array[Dictionary] = []

func _ready():
	print("==================== RUNSUMMARY _READY START ====================")

	var params = get_scene_params()
	god_name = params.get("god", "Apollo")
	deck_index = params.get("deck_index", 0)
	victory = params.get("victory", true)
	var leather_scraps_earned: int = params.get("leather_scraps_earned", 0)

	print("Run Summary parameters: God=", god_name, " Deck=", deck_index, " Victory=", victory)

	if not victory:
		if has_node("/root/ConversationManagerAutoload"):
			get_node("/root/ConversationManagerAutoload").increment_defeat_count()

	if not victory:
		SoundManagerAutoload.play_music("defeat_theme", 2.0)

	var main_level_manager = get_node_or_null("/root/MainLevelAutoload")
	if main_level_manager:
		_world_level_before = main_level_manager.main_level

	# SNAPSHOT exp data BEFORE saving/clearing
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if tracker:
		_run_exp_snapshot = tracker.get_all_experience().duplicate(true)
		print("Snapshotted exp data: ", _run_exp_snapshot.size(), " cards")
	else:
		print("WARNING: RunExperienceTrackerAutoload not found at snapshot time")

	# Now safe to commit and clear
	save_run_to_global_progress()
	if tracker:
		tracker.clear_run()

	if main_level_manager:
		_world_level_after = main_level_manager.main_level

	var mnemosyne_tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if mnemosyne_tracker and _world_level_after > _world_level_before:
		_mnemosyne_upgrades = mnemosyne_tracker.apply_upgrades_for_world_level_range(
			_world_level_before, _world_level_after
		)
		print("Mnemosyne upgrades this run: ", _mnemosyne_upgrades.size())

	await setup_ui_safely()


func setup_ui_safely():
	print("\n=== Setting up UI ===")

	var main_container = get_node_or_null("MainContainer")
	if not main_container:
		push_error("MainContainer not found!")
		return

	var left_panel = main_container.get_node_or_null("LeftPanel")
	var right_panel = main_container.get_node_or_null("RightPanel")

	if not left_panel or not right_panel:
		push_error("LeftPanel or RightPanel not found!")
		return

	var run_details_container = left_panel.get_node_or_null("RunDetailsContainer")
	if not run_details_container:
		push_error("RunDetailsContainer not found!")
		return

	var title = left_panel.get_node_or_null("Title")
	var god_deck_info = run_details_container.get_node_or_null("GodDeckInfo")
	var outcome_label = run_details_container.get_node_or_null("OutcomeLabel")

	var total_exp_container = left_panel.get_node_or_null("TotalExpContainer")
	if not total_exp_container:
		push_error("TotalExpContainer not found!")
		return

	var capture_total = total_exp_container.get_node_or_null("CaptureTotal")
	var defense_total = total_exp_container.get_node_or_null("DefenseTotal")
	var card_display_container = right_panel.get_node_or_null("CardDetailsContainer")

	if not title or not god_deck_info or not outcome_label or not capture_total or not defense_total:
		push_error("Missing required nodes in panels")
		return

	print("All nodes found successfully!")

	var scraps_earned: int = get_scene_params().get("leather_scraps_earned", 0)
	setup_left_panel_content(title, god_deck_info, outcome_label, capture_total, defense_total, scraps_earned)

	# Inner HBox so cards and mnemosyne sit side by side inside RightPanel (which is a VBoxContainer)
	var inner_hbox = HBoxContainer.new()
	inner_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_hbox.add_theme_constant_override("separation", 12)
	right_panel.add_child(inner_hbox)

	# Card column with scroll
	var card_scroll = ScrollContainer.new()
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner_hbox.add_child(card_scroll)

	var card_vbox = VBoxContainer.new()
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_vbox.add_theme_constant_override("separation", 12)
	card_scroll.add_child(card_vbox)

	await setup_card_displays_panel(card_vbox)

	# Mnemosyne column - only added if there is something to show
	if _world_level_after != _world_level_before or not _mnemosyne_upgrades.is_empty():
		var mnem_scroll = ScrollContainer.new()
		mnem_scroll.custom_minimum_size.x = 220
		mnem_scroll.size_flags_horizontal = Control.SIZE_SHRINK_END
		mnem_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		mnem_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		inner_hbox.add_child(mnem_scroll)

		var mnem_vbox = VBoxContainer.new()
		mnem_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mnem_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		mnem_vbox.add_theme_constant_override("separation", 8)
		mnem_scroll.add_child(mnem_vbox)

		_build_mnemosyne_section(mnem_vbox)

	# Hide the old unused container
	if card_display_container:
		card_display_container.visible = false





func setup_left_panel_content(title_node: Label, god_deck_node: Label, outcome_node: Label, capture_node: Label, defense_node: Label, scraps_earned: int = 0):
	print("\n=== Setting up left panel content ===")
	
	# Set title
	title_node.text = "Run Complete"
	
	# Get deck name for display
	var deck_name = get_deck_name()
	god_deck_node.text = god_name + " - " + deck_name
	god_deck_node.add_theme_font_size_override("font_size", 18)
	god_deck_node.add_theme_color_override("font_color", Color("#DDDDDD"))
	
	# Set outcome
	if victory:
		outcome_node.text = "Victory!"
		outcome_node.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		outcome_node.text = "Defeat"
		outcome_node.add_theme_color_override("font_color", Color("#8A4A4A"))
	
	outcome_node.add_theme_font_size_override("font_size", 24)
	
	# Use snapshot for total exp display (tracker is already cleared by this point)
	var run_total = 0
	for card_data in _run_exp_snapshot.values():
		run_total += card_data.get("total_exp", 0)
	capture_node.text = "⚡ Total Experience Gained: " + str(run_total)
	capture_node.add_theme_font_size_override("font_size", 16)
	capture_node.add_theme_color_override("font_color", Color("#FFD700"))
	defense_node.visible = false
	
	# Show leather scraps reward if any were earned this run
	if scraps_earned > 0:
		var scraps_label = Label.new()
		scraps_label.text = "🪡 +" + str(scraps_earned) + " Leather Scrap" + ("s" if scraps_earned > 1 else "") + " earned!"
		scraps_label.add_theme_font_size_override("font_size", 18)
		scraps_label.add_theme_color_override("font_color", Color("#C8A45A"))
		scraps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_node.get_parent().add_child(scraps_label)
	
	
	print("Left panel content setup complete")

func _build_mnemosyne_section(container: VBoxContainer):
	var world_level_title = Label.new()
	world_level_title.text = "🌍 World Level"
	world_level_title.add_theme_font_size_override("font_size", 20)
	world_level_title.add_theme_color_override("font_color", Color("#DDDDDD"))
	world_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(world_level_title)

	var main_level_manager = get_node_or_null("/root/MainLevelAutoload")
	var level_detail = Label.new()
	if main_level_manager:
		if _world_level_after > _world_level_before:
			level_detail.text = "Lv." + str(_world_level_before) + " → Lv." + str(_world_level_after) + " 🎉"
			level_detail.add_theme_color_override("font_color", Color("#00FF00"))
		else:
			level_detail.text = "Lv." + str(_world_level_after)
			level_detail.add_theme_color_override("font_color", Color("#CCCCCC"))
	else:
		level_detail.text = "World level unavailable"
		level_detail.add_theme_color_override("font_color", Color("#888888"))
	level_detail.add_theme_font_size_override("font_size", 16)
	level_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(level_detail)

	if _mnemosyne_upgrades.is_empty():
		var no_upgrade_label = Label.new()
		no_upgrade_label.text = "No new Mnemosyne upgrades this run"
		no_upgrade_label.add_theme_color_override("font_color", Color("#888888"))
		no_upgrade_label.add_theme_font_size_override("font_size", 13)
		no_upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(no_upgrade_label)
		return

	var upgrades_title = Label.new()
	upgrades_title.text = "✨ Mnemosyne Upgrades"
	upgrades_title.add_theme_font_size_override("font_size", 16)
	upgrades_title.add_theme_color_override("font_color", Color("#DDB0FF"))
	upgrades_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(upgrades_title)

	for upgrade in _mnemosyne_upgrades:
		var upgrade_label = Label.new()
		var stat_names = ["North", "East", "South", "West"]
		var stat_name = stat_names[upgrade.get("stat_index", 0)] if upgrade.get("stat_index", 0) < 4 else "?"
		var card_name = upgrade.get("card_name", "Unknown")
		upgrade_label.text = "• " + card_name + " +" + stat_name
		upgrade_label.add_theme_font_size_override("font_size", 14)
		upgrade_label.add_theme_color_override("font_color", Color("#CCBBFF"))
		upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(upgrade_label)

func get_deck_name() -> String:
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if collection and deck_index < collection.decks.size():
		return collection.decks[deck_index].deck_name
	return "Unknown Deck"

func setup_card_displays_panel(container: VBoxContainer)-> void:
	print("\n=== Setting up card displays panel ===")

	card_animation_index = 0

	if container:
		for child in container.get_children():
			child.queue_free()

	var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")

	if not global_tracker:
		var error_label = Label.new()
		error_label.text = "GlobalProgressTrackerAutoload not available"
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return

	print("Exp snapshot has ", _run_exp_snapshot.size(), " cards")

	if _run_exp_snapshot.is_empty():
		var no_exp_label = Label.new()
		no_exp_label.text = "No experience data found for this run"
		no_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_exp_label.add_theme_color_override("font_color", Color("#888888"))
		container.add_child(no_exp_label)
		return

	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		var error_label = Label.new()
		error_label.text = "Failed to load " + god_name + " collection"
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return

	print("Collection loaded: ", collection.cards.size(), " cards")

	var animation_jobs: Array = []
	var cards_with_exp = 0

	for card_index in _run_exp_snapshot:
		var run_exp_data = _run_exp_snapshot[card_index]

		if card_index >= collection.cards.size():
			print("  Card index ", card_index, " out of bounds, skipping")
			continue

		var card = collection.cards[card_index]
		if not card:
			continue

		# before_total is what global tracker has NOW (already committed) minus what was gained
		var after_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
		var after_total = after_exp_data["total_exp"]
		var total_gain = run_exp_data.get("total_exp", 0)
		var before_total = after_total - total_gain

		print("  Card: ", card.card_name, " before=", before_total, " gain=", total_gain, " after=", after_total)

		var result = create_apollo_style_card_display(card, card_index, before_total, after_total, total_gain)
		container.add_child(result["panel"])
		cards_with_exp += 1
		card_animation_index += 1

		animation_jobs.append({
			"progress_bar": result["progress_bar"],
			"name_label": result["name_label"],
			"before_total": before_total,
			"after_total": after_total,
			"card_name": card.card_name
		})

	await get_tree().process_frame

	for job in animation_jobs:
		await animate_progress_bar(
			job["progress_bar"],
			job["before_total"],
			job["after_total"],
			job["name_label"],
			job["card_name"]
		)

	print("Card displays complete, created ", cards_with_exp, " displays")

func create_gradient_texture(color1: Color, color2: Color) -> GradientTexture1D:
	var gradient = Gradient.new()
	gradient.set_color(0, color1)
	gradient.set_color(1, color2)
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 256
	
	return gradient_texture

func create_progress_bar() -> ColorRect:
	var progress_bar = ColorRect.new()
	progress_bar.custom_minimum_size = Vector2(0, 25)
	
	# Load shader
	var shader = load("res://Shaders/segmented_progress_bar.gdshader")
	if not shader:
		print("ERROR: Failed to load progress bar shader!")
		return progress_bar
	
	# Create shader material
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Set shader parameters
	material.set_shader_parameter("stepify", false)
	material.set_shader_parameter("value", 0.0)
	material.set_shader_parameter("count", SEGMENT_COUNT)
	material.set_shader_parameter("margin", Vector2(0.02, 0.15))
	material.set_shader_parameter("shear_angle", 0.0)
	material.set_shader_parameter("use_value_gradient", false)
	material.set_shader_parameter("invert", false)
	
	# Create gradient textures
	var gradient_x = create_gradient_texture(Color("#4A8A4A"), Color("#6AFF6A"))
	var gradient_y = create_gradient_texture(Color.WHITE, Color.WHITE)
	
	material.set_shader_parameter("gradient_x", gradient_x)
	material.set_shader_parameter("gradient_y", gradient_y)
	
	progress_bar.material = material
	
	return progress_bar

func animate_progress_bar(
	progress_bar: ColorRect,
	before_total: int,
	after_total: int,
	level_label: Label,
	card_name: String
):
	var before_level = ExperienceHelpers.calculate_level(before_total)
	var after_level = ExperienceHelpers.calculate_level(after_total)
	var before_progress = ExperienceHelpers.calculate_progress(before_total)
	var after_progress = ExperienceHelpers.calculate_progress(after_total)
	var total_gain = after_total - before_total

	print("Animating progress bar for ", card_name)
	print("  Before: Lv.", before_level, " (", before_progress, "/", XP_PER_LEVEL, ")")
	print("  After: Lv.", after_level, " (", after_progress, "/", XP_PER_LEVEL, ")")

	if total_gain <= 0:
		progress_bar.material.set_shader_parameter("value", before_progress / float(XP_PER_LEVEL))
		print("  No gain, skipping animation")
		return

	var level_ups = after_level - before_level
	var duration = BASE_ANIMATION_DURATION + (level_ups * 0.5)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	# Use an array so the lambda captures by reference, preserving mutations across tween frames
	# state[0] = tracked_level, state[1] = levels_crossed
	var state = [before_level, 0]
	tween.tween_method(func(xp_gained: float):
		var current_xp = before_total + xp_gained
		var current_level = ExperienceHelpers.calculate_level(int(current_xp))
		var current_progress = ExperienceHelpers.calculate_progress(int(current_xp))
		var shader_value = current_progress / float(XP_PER_LEVEL)
		progress_bar.material.set_shader_parameter("value", shader_value)
		if current_level != state[0]:
			print("LEVELUP DETECTED: ", state[0], " -> ", current_level, " | levels_crossed so far: ", state[1])
			state[0] = current_level
			state[1] += 1
			var is_final_level_up = (state[0] == after_level and level_ups >= 3)
			var pitch = clampf(1.0 + (state[1] - 1) * 0.06, 1.0, 1.3)
			var vol = clampf((state[1] - 1) * 0.8, 0.0, 3.0)
			print("PLAYING SOUND: is_final=", is_final_level_up, " pitch=", pitch, " vol=", vol)
			SoundManagerAutoload.play_level_up_sound(pitch, vol, is_final_level_up)
			level_label.text = card_name + " (Lv." + str(state[0]) + ")"
		, 0.0, float(total_gain), duration)

	await tween.finished
	print("  Animation complete for ", card_name)

func create_apollo_style_card_display(card: CardResource, card_index: int, before_total: int, after_total: int, total_gain: int) -> Dictionary:
	print("Creating card display for: ", card.card_name)

	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 120)

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#3A3A3A")
	style.border_color = Color("#555555")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(margin)

	var h_container = HBoxContainer.new()
	margin.add_child(h_container)

	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_container.add_child(left_side)

	var current_level = 1
	if god_name == "Mnemosyne":
		var memory_manager = get_node_or_null("/root/MemoryJournalManagerAutoload")
		if memory_manager:
			var mnemosyne_data = memory_manager.get_mnemosyne_memory()
			current_level = mnemosyne_data.get("consciousness_level", 1)
	else:
		var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
		if progress_tracker:
			current_level = progress_tracker.get_card_level(god_name, card_index)

	print("  Current level for ", card.card_name, ": ", current_level)

	var name_label = Label.new()
	name_label.text = card.card_name + " (Lv." + str(current_level) + ")"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	left_side.add_child(name_label)

	var effective_values = card.get_effective_values(current_level)
	var values_container = HBoxContainer.new()
	left_side.add_child(values_container)

	var directions = ["N", "E", "S", "W"]
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":" + str(effective_values[i])
		dir_label.add_theme_font_size_override("font_size", 12)
		dir_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		dir_label.custom_minimum_size.x = 35
		values_container.add_child(dir_label)
		if i < 3:
			var spacer = Control.new()
			spacer.custom_minimum_size.x = 5
			values_container.add_child(spacer)

	var v_separator = VSeparator.new()
	h_container.add_child(v_separator)

	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 200
	h_container.add_child(right_side)

	var run_exp_title = Label.new()
	run_exp_title.text = "Experience Gained"
	run_exp_title.add_theme_font_size_override("font_size", 14)
	run_exp_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	run_exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(run_exp_title)

	var run_exp_container = VBoxContainer.new()
	right_side.add_child(run_exp_container)

	var total_exp_label = Label.new()
	total_exp_label.text = "⚡ +" + str(total_gain)
	total_exp_label.add_theme_font_size_override("font_size", 16)
	total_exp_label.add_theme_color_override("font_color", Color("#FFD700"))
	total_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_exp_container.add_child(total_exp_label)

	var progress_bar = create_progress_bar()
	run_exp_container.add_child(progress_bar)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	run_exp_container.add_child(spacer)

	var before_level = ExperienceHelpers.calculate_level(before_total)
	var after_level = ExperienceHelpers.calculate_level(after_total)
	var before_progress = ExperienceHelpers.calculate_progress(before_total)
	var after_progress = ExperienceHelpers.calculate_progress(after_total)

	var progression_label = Label.new()
	if after_level > before_level:
		progression_label.text = "Lv." + str(before_level) + " → Lv." + str(after_level)
		progression_label.add_theme_color_override("font_color", Color("#00FF00"))
	else:
		progression_label.text = str(before_progress) + " → " + str(after_progress) + " / " + str(XP_PER_LEVEL) + " XP"
		progression_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	progression_label.add_theme_font_size_override("font_size", 10)
	progression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_exp_container.add_child(progression_label)

	# Set bar to starting position immediately (visible before animation runs)
	var start_value = before_progress / float(XP_PER_LEVEL)
	progress_bar.material.set_shader_parameter("value", start_value)

	print("  Card display created successfully")
	return {
		"panel": card_panel,
		"progress_bar": progress_bar,
		"name_label": name_label
	}

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

func _on_new_run_button_pressed() -> void:
	SoundManagerAutoload.fade_out_music(1.0)
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

func _on_main_menu_button_pressed() -> void:
	SoundManagerAutoload.fade_out_music(1.0)
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

func save_run_to_global_progress():
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	
	if not tracker or not global_tracker:
		print("Missing trackers for saving progress")
		return
		
	var run_exp = tracker.get_all_experience()
	
	if run_exp.size() == 0:
		print("No run experience to save")
		return
	
	# Apply main level multiplier to all card XP before committing
	var main_level_manager = get_node_or_null("/root/MainLevelAutoload")
	var scaled_run_exp: Dictionary = {}
	
	for card_index in run_exp:
		var card_data = run_exp[card_index]
		var base_total = card_data.get("capture_exp", 0) + card_data.get("defense_exp", 0)
		var scaled_total = main_level_manager.apply_xp(base_total) if main_level_manager else base_total
		scaled_run_exp[card_index] = {
			"capture_exp": scaled_total,
			"defense_exp": 0,
			"total_exp": scaled_total
		}
		if scaled_total != base_total:
			print("MainLevel scaling: card ", card_index, " ", base_total, " → ", scaled_total, " exp")
	
	# Commit scaled exp to global tracker
	global_tracker.add_run_experience(god_name, scaled_run_exp)
	print("Saved scaled run experience to global progress for ", god_name)
	
	# Check for god unlocks now that experience is committed  
	var newly_unlocked = global_tracker.check_god_unlocks()
	for unlocked_god in newly_unlocked:
		print("🎉 God unlocked after run: ", unlocked_god)
	
	# Award main level exp for each card level gained this run
	if main_level_manager:
		var collection_path = "res://Resources/Collections/" + god_name + ".tres"
		var collection: GodCardCollection = load(collection_path)
		if collection:
			for card_index in scaled_run_exp:
				var scaled_total = scaled_run_exp[card_index].get("total_exp", 0)
				if scaled_total <= 0:
					continue
				var after_exp = global_tracker.get_card_total_experience(god_name, card_index).get("total_exp", 0)
				var before_exp = after_exp - scaled_total
				var levels_gained = ExperienceHelpers.levels_gained(before_exp, after_exp)
				if levels_gained > 0:
					var main_exp_award = levels_gained * MainLevelManager.EXP_CARD_LEVEL_UP
					main_level_manager.add_main_exp(main_exp_award)
					print("MainLevel: +", main_exp_award, " exp from ", levels_gained, " card level-up(s) on card ", card_index)
