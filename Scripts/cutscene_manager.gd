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
	tutorial_lines.append(DialogueLine.new("Chronos", "New! Sister dearest. Why won't you join me and the other titans? We have been having fun fighting all morning"))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "Chronos thank you for inviting me, but you know I can't fight, I can't really do much of anything."))
	tutorial_lines.append(DialogueLine.new("Chronos", "Yes I know that but why? You are a titan are you not? We are the straining ones! fighting is what we do. What use is your gift of memory? By all accounts you don't seem to be using your talents anyway, you seem mostly useless, it's vexing."))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "You’re right, I don't really understand why I am a titan."))
	tutorial_lines.append(DialogueLine.new("Chronos", "None of us understand it New. Maybe you just need more encouragement, come lets fight!"))
	

	var tutorial_cutscene = CutsceneData.new("tutorial_intro", [mnemosyne, chronos], tutorial_lines)
	cutscenes["tutorial_intro"] = tutorial_cutscene
	
	
	# NEW: Opening awakening cutscene
	var opening_lines: Array[DialogueLine] = []
	opening_lines.append(DialogueLine.new("Chiron", "You fought well Mnemosyne"))
	opening_lines.append(DialogueLine.new("Mnemosyne", " I don't think I…"))
	opening_lines.append(DialogueLine.new("Chiron", "You fought well, with the tools you have available at this time"))
	opening_lines.append(DialogueLine.new("Chiron", "Given the fullness of said time, Chronos would do best to avoid you."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Hold on; who are you? How do you know me?"))
	opening_lines.append(DialogueLine.new("Chiron", "So it's true then, what an honour. To speak to the Titaness of memory before she understands the extent of her power. My name is Chiron."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "And you are a..."))
	opening_lines.append(DialogueLine.new("Chiron", "A centaur, yes"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Sorry for being so crude"))
	opening_lines.append(DialogueLine.new("Chiron", "How fascinating, you know one day it will be me apologising to you for the incompleteness of my thought"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Okay enough please, you have to tell me what you mean by all this"))
	opening_lines.append(DialogueLine.new("Chiron", "Chaos, the Fate’s, Moros if you will, whatever source you want to invoke has decided your realm would be that of memory.  More than that, a divine infinite capacity to remember and learn."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "So I can learn? That's it?"))
	opening_lines.append(DialogueLine.new("Chiron", "Why yes but can't you see what that means? You are immortal, you will live forever. Forever is a long time to learn, to improve. "))
	opening_lines.append(DialogueLine.new("Chiron", "Chronos as divine a being he undoubtedly is, doesn't have this potential. What you see now is what you will see come millenia."))
	opening_lines.append(DialogueLine.new("Chiron", "So in a cosmic sense the only way you could possibly ever lose to someone like Chronos is to never do anything. You could take a step once every hundred years and eventually you would win. "))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Well okay I must say when you put it like that it's quite encouraging, but I don't really know where to start."))
	opening_lines.append(DialogueLine.new("Chiron", "It feels a little ridiculous me telling you of all people how to learn"))
	opening_lines.append(DialogueLine.new("Chiron", "But when I learn something new, I usually find someone I trust and ask them to teach me."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "So will you then? Teach me?"))
	opening_lines.append(DialogueLine.new("Chiron", "Of course I will. Who would be foolish enough to pass up such an opportunity. Where should we start?"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "I want to be able to stand up for myself"))
	opening_lines.append(DialogueLine.new("Chiron", "My advice, start with relying on the power of others, until you have built up your own strength"))
	opening_lines.append(DialogueLine.new("Chiron", "Go and visit Apollo, he owes me one for Asclepius."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Thank you Chiron. "))
	

	
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
			"god": "Mnemosyne",  # This should be the player's god
			"deck_index": 0,     # Add deck index for consistency
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
