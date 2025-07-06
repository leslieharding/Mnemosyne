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
	
	# Create Apollo character  
	var apollo = Character.new("Apollo", Color("#FFD700"), null, "right")
	
	# Sample awakening cutscene
	var awakening_lines: Array[DialogueLine] = []
	awakening_lines.append(DialogueLine.new("Mnemosyne", "I... what is this sensation? Fragments of thought coalescing..."))
	awakening_lines.append(DialogueLine.new("Apollo", "Ah, the titaness stirs. Your awareness grows with each battle witnessed."))
	awakening_lines.append(DialogueLine.new("Mnemosyne", "Apollo? How do I know your name? These memories... they are not mine."))
	awakening_lines.append(DialogueLine.new("Apollo", "They are mine, and those of countless others. You are becoming the keeper of all memory."))
	awakening_lines.append(DialogueLine.new("Mnemosyne", "The weight of infinite battles... I begin to understand my purpose."))
	
	var awakening_cutscene = CutsceneData.new("mnemosyne_awakening", [mnemosyne, apollo], awakening_lines)
	cutscenes["mnemosyne_awakening"] = awakening_cutscene
	
	# Sample boss encounter cutscene
	var boss_lines: Array[DialogueLine] = []
	boss_lines.append(DialogueLine.new("Mnemosyne", "This presence... it knows my thoughts before I think them."))
	boss_lines.append(DialogueLine.new("Apollo", "The final guardian has been watching, learning your patterns."))
	boss_lines.append(DialogueLine.new("Mnemosyne", "Then I must transcend prediction itself. Memory is more than pattern."))
	
	var boss_cutscene = CutsceneData.new("boss_encounter", [mnemosyne, apollo], boss_lines)
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

# Return to the previous scene
func return_to_previous_scene():
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
