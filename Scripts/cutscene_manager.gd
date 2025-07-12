# res://Scripts/cutscene_manager.gd
extends Node
class_name CutsceneManager

# Store all available cutscenes
var cutscenes: Dictionary = {}
var viewed_cutscenes: Array[String] = []

# Scene management
var return_scene_path: String = ""
var return_scene_params: Dictionary = {}

func _ready():
	# Load all cutscenes
	load_cutscenes()

# Load and register all cutscenes
func load_cutscenes():
	# For now, we'll create cutscenes programmatically
	# Later these could be loaded from files
	create_sample_cutscenes()

# Create some sample cutscenes for testing
func create_sample_cutscenes():
	# Create Mnemosyne character
	var mnemosyne = Character.new("Mnemosyne", Color("#DDA0DD"), null, "left")
	
	# Create Chrion character  
	var chiron = Character.new("Chiron", Color("#FFD700"), null, "right")
	
	# Create Apollo character  
	var apollo = Character.new("Apollo", Color("#FFD700"), null, "right")
	
	# Create Chronos character  
	var chronos = Character.new("Chronos", Color("#8B4513"), null, "right")
	
	
	# Tutorial introduction cutscene
	var tutorial_lines: Array[DialogueLine] = []
	tutorial_lines.append(DialogueLine.new("Chronos", "This is intro dialogue"))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "It sure is"))
	tutorial_lines.append(DialogueLine.new("Chronos", "well shall we have the tutorial fight or what?"))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "Yeah I guess so"))
	tutorial_lines.append(DialogueLine.new("Chronos", "Alright have at you!"))
	

	var tutorial_cutscene = CutsceneData.new("tutorial_intro", [mnemosyne, chronos], tutorial_lines)
	cutscenes["tutorial_intro"] = tutorial_cutscene
	
	
	# NEW: Opening awakening cutscene
	var opening_lines: Array[DialogueLine] = []
	opening_lines.append(DialogueLine.new("Mnemosyne", "Wow this sure is the opening cutscene and some sample text"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "And this is the second line of it."))
	opening_lines.append(DialogueLine.new("Chiron", "Im the other character in this scene LMAO"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Hey thats pretty cool."))
	opening_lines.append(DialogueLine.new("Chiron", "We really are just reusing the same code"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Yeah but its the first time I've got it to work you know"))
	opening_lines.append(DialogueLine.new("Chiron", "Good for you I guess"))
	
	var opening_cutscene = CutsceneData.new("opening_awakening", [mnemosyne, chiron], opening_lines)
	cutscenes["opening_awakening"] = opening_cutscene
	
	# Sample awakening cutscene (existing)
	var awakening_lines: Array[DialogueLine] = []
	awakening_lines.append(DialogueLine.new("Mnemosyne", "I... what is this sensation? Fragments of thought coalescing..."))
	awakening_lines.append(DialogueLine.new("Apollo", "Ah, the titaness stirs. Your awareness grows with each battle witnessed."))
	awakening_lines.append(DialogueLine.new("Mnemosyne", "Apollo? How do I know your name? These memories... they are not mine."))
	awakening_lines.append(DialogueLine.new("Apollo", "They are mine, and those of countless others. You are becoming the keeper of all memory."))
	awakening_lines.append(DialogueLine.new("Mnemosyne", "The weight of infinite battles... I begin to understand my purpose."))
	
	var awakening_cutscene = CutsceneData.new("mnemosyne_awakening", [mnemosyne, chiron], awakening_lines)
	cutscenes["mnemosyne_awakening"] = awakening_cutscene
	
	# Sample boss encounter cutscene (existing)
	var boss_lines: Array[DialogueLine] = []
	boss_lines.append(DialogueLine.new("Mnemosyne", "This presence... it knows my thoughts before I think them."))
	boss_lines.append(DialogueLine.new("Apollo", "The final guardian has been watching, learning your patterns."))
	boss_lines.append(DialogueLine.new("Mnemosyne", "Then I must transcend prediction itself. Memory is more than pattern."))
	
	var boss_cutscene = CutsceneData.new("boss_encounter", [mnemosyne, chiron], boss_lines)
	cutscenes["boss_encounter"] = boss_cutscene
	
	print("Loaded ", cutscenes.size(), " cutscenes")

# Main function to trigger a cutscene
func play_cutscene(cutscene_id: String):
	if not cutscene_id in cutscenes:
		print("Cutscene not found: ", cutscene_id)
		return
	
	# Store current scene info for return
	var current_scene = get_tree().current_scene
	if current_scene:
		return_scene_path = current_scene.scene_file_path
		
		# Store any scene parameters that might exist
		if get_tree().has_meta("scene_params"):
			return_scene_params = get_tree().get_meta("scene_params")
	
	# Mark as viewed
	if not cutscene_id in viewed_cutscenes:
		viewed_cutscenes.append(cutscene_id)
	
	# Set cutscene data for the cutscene scene
	get_tree().set_meta("cutscene_data", cutscenes[cutscene_id])
	
	print("Playing cutscene: ", cutscene_id)
	
	# Switch to cutscene scene
	get_tree().change_scene_to_file("res://Scenes/Cutscene.tscn")

func return_to_previous_scene():
	# Special handling for tutorial flow
	var last_played = viewed_cutscenes[-1] if viewed_cutscenes.size() > 0 else ""
	
	if last_played == "tutorial_intro":
		print("Completed tutorial intro cutscene, starting tutorial battle")
		# Set up tutorial battle parameters
		get_tree().set_meta("scene_params", {
			"is_tutorial": true,
			"god": "Mnemosyne",
			"opponent": "Chronos"
		})
		get_tree().change_scene_to_file("res://Scenes/CardBattle.tscn")
		return
	elif last_played == "opening_awakening":
		print("Completed post-tutorial cutscene, going to god select")
		get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
		return
	
	if return_scene_path != "":
		# Restore scene parameters if they existed
		if not return_scene_params.is_empty():
			get_tree().set_meta("scene_params", return_scene_params)
		
		print("Returning to: ", return_scene_path)
		get_tree().change_scene_to_file(return_scene_path)
		
		# Clear stored data
		return_scene_path = ""
		return_scene_params.clear()
	else:
		print("No return scene stored, going to main menu")
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

# Check if a cutscene has been viewed
func has_viewed_cutscene(cutscene_id: String) -> bool:
	return cutscene_id in viewed_cutscenes

# Get cutscene data (useful for testing or debugging)
func get_cutscene(cutscene_id: String) -> CutsceneData:
	return cutscenes.get(cutscene_id, null)

# Add a new cutscene at runtime (useful for dynamic content)
func add_cutscene(cutscene_data: CutsceneData):
	cutscenes[cutscene_data.cutscene_id] = cutscene_data

# Get list of all available cutscenes
func get_available_cutscenes() -> Array[String]:
	return cutscenes.keys()
