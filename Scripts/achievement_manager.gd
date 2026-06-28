# res://Scripts/achievement_manager.gd
extends Node

signal achievement_unlocked(achievement_data: Dictionary)

var unlocked_achievements: Array[String] = []
var save_path: String = "user://achievements.save"

const ACHIEVEMENTS: Array = [
	{
		"id": "argus",
		"name": "Argus",
		"description": "Defeat Argus Panoptes"
	},
	{
		"id": "bellerophon",
		"name": "Bellerophon",
		"description": ""  # TODO: Define condition
	},
	{
		"id": "ceryneian_hind",
		"name": "Ceryneian Hind",
		"description": "Capture the Ceryneian Hind"
	},
	{
		"id": "defeat_defeat",
		"name": "Defeat Defeat",
		"description": "Suffer a perfect loss"
	},
	{
		"id": "erysichthon",
		"name": "Erysichthon",
		"description": "Defeat the Erysichthon"
	},
	{
		"id": "fimbulwinter",
		"name": "Fimbulwinter",
		"description": "Winter will follow winter which follows winter"
	},
	{
		"id": "gaia",
		"name": "Gaia",
		"description": "Capture Antaeus after he is played on the bottom row"
	},
	{
		"id": "hecatoncheires",
		"name": "Hecatoncheires",
		"description": "Defeat the Hecatoncheires in battle"
	},
	{
		"id": "impatient",
		"name": "Impatient",
		"description": "Win a run while Hermes is impatient"
	},
	{
		"id": "jealous",
		"name": "Jealous",
		"description": "Make the goddess of beauty jealous"
	},
	{
		"id": "kronos",
		"name": "Kronos",
		"description": "Defeat the Titan of Time"
	},
	{
		"id": "laughter",
		"name": "Laughter",
		"description": "Make Loki die of laughter"
	},
	{
		"id": "marsyas",
		"name": "Marsyas",
		"description": "Defeat The Wrong Note"
	},
	{
		"id": "nyx",
		"name": "Nyx",
		"description": "Defeat the cultists of Nyx"
	},
	{
		"id": "olympus",
		"name": "Olympus",
		"description": ""  # TODO: Define condition
	},
	{
		"id": "peep",
		"name": "Peep",
		"description": "Defeat the hunting party"
	},
	{
		"id": "questing",
		"name": "Questing",
		"description": "Defeat The Way Home and The Isthmus Road as Hermes"
	},
	{
		"id": "ragnarok",
		"name": "Ragnarok",
		"description": "The end times"
	},
	{
		"id": "the_shoe",
		"name": "The Shoe",
		"description": "Contribute to Víðarr's shoe"
	},
	{
		"id": "tend",
		"name": "Tend",
		"description": "Cultivate a card to level 30"
	},
	{
		"id": "utgarda_loki",
		"name": "Útgarða-Loki",
		"description": "See through the illusions"
	},
	{
		"id": "vengeful",
		"name": "Vengeful",
		"description": "Defeat an enemy previously weakened by a vengeful Artemis"
	},
	{
		"id": "winner_winner",
		"name": "Winner Winner",
		"description": "Achieve a perfect victory"
	},
	{
		"id": "xiphos",
		"name": "Xiphos",
		"description": "Win 100 battles"
	},
	{
		"id": "yours",
		"name": "Yours",
		"description": "Inspire each Muse"
	},
	{
		"id": "zeus",
		"name": "Zeus",
		"description": "Find out what Zeus has been up to"
	},
]

func _ready():
	load_achievements()

# === CORE UNLOCK SYSTEM ===

func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	var achievement_data = get_achievement_data(id)
	if achievement_data.is_empty():
		push_error("AchievementManager: Unknown achievement id: " + id)
		return
	unlocked_achievements.append(id)
	save_achievements()
	emit_signal("achievement_unlocked", achievement_data)
	if has_node("/root/NotificationManagerAutoload"):
		get_node("/root/NotificationManagerAutoload").show_notification(
			"[b]Achievement:[/b] " + achievement_data["name"]
		)
	print("Achievement unlocked: ", id)
	# TODO: SteamAutoload.set_achievement(id)

func is_unlocked(id: String) -> bool:
	return id in unlocked_achievements

# === QUERY FUNCTIONS ===

func get_achievement_data(id: String) -> Dictionary:
	for achievement in ACHIEVEMENTS:
		if achievement["id"] == id:
			return achievement
	return {}

func get_all_achievements() -> Array:
	return ACHIEVEMENTS

func get_unlocked_achievements() -> Array:
	var result: Array = []
	for achievement in ACHIEVEMENTS:
		if is_unlocked(achievement["id"]):
			result.append(achievement)
	return result

func get_unlock_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()
	
# === INDIVIDUAL ACHIEVEMENT TRIGGER FUNCTIONS ===

func trigger_argus() -> void:
	unlock("argus")

func trigger_bellerophon() -> void:
	# TODO: Define and implement unlock condition
	unlock("bellerophon")

func trigger_ceryneian_hind() -> void:
	unlock("ceryneian_hind")

func trigger_defeat_defeat() -> void:
	unlock("defeat_defeat")

func trigger_erysichthon() -> void:
	unlock("erysichthon")

func trigger_fimbulwinter() -> void:
	# TODO: Define exact condition (boss defeat, survive X turns, lose to it, etc.)
	unlock("fimbulwinter")

func trigger_gaia() -> void:
	unlock("gaia")

func trigger_hecatoncheires() -> void:
	unlock("hecatoncheires")

func trigger_impatient() -> void:
	# TODO: Requires knowing what "impatient" state means in the Hermes boss fight
	unlock("impatient")

func trigger_jealous() -> void:
	unlock("jealous")

func trigger_kronos() -> void:
	unlock("kronos")

func trigger_laughter() -> void:
	# TODO: Loki not yet in game
	unlock("laughter")

func trigger_marsyas() -> void:
	unlock("marsyas")

func trigger_nyx() -> void:
	unlock("nyx")

func trigger_olympus() -> void:
	# TODO: Define and implement unlock condition
	unlock("olympus")

func trigger_peep() -> void:
	unlock("peep")

func trigger_questing() -> void:
	# TODO: Needs persistent tracking of both battles won as Hermes before calling unlock
	unlock("questing")

func trigger_ragnarok() -> void:
	# TODO: Define exact end-times condition
	unlock("ragnarok")

func trigger_the_shoe() -> void:
	unlock("the_shoe")

func trigger_tend() -> void:
	unlock("tend")

func trigger_utgarda_loki() -> void:
	# TODO: Define what "seeing through the illusions" means mechanically
	unlock("utgarda_loki")

func trigger_vengeful() -> void:
	unlock("vengeful")

func trigger_winner_winner() -> void:
	unlock("winner_winner")

func trigger_xiphos() -> void:
	# Call this when total win count reaches 100
	unlock("xiphos")

func trigger_yours() -> void:
	# TODO: Muses not yet fully implemented
	unlock("yours")

func trigger_zeus() -> void:
	unlock("zeus")
		
# === PERSISTENCE ===

func save_achievements() -> void:
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(unlocked_achievements)
		save_file.close()
		print("Achievements saved")
	else:
		print("AchievementManager: Failed to save achievements!")

func load_achievements() -> void:
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded = save_file.get_var()
			if loaded is Array:
				unlocked_achievements = loaded
			save_file.close()
			print("Achievements loaded: ", unlocked_achievements.size(), " unlocked")
	else:
		print("AchievementManager: No save found, starting fresh")

func clear_all_achievements() -> void:
	unlocked_achievements.clear()
	save_achievements()
	print("All achievements cleared")
