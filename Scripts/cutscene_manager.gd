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
	# Chronos speaks energetically - use faster speeds for excitement
	tutorial_lines.append(DialogueLine.new(
		"Chronos", 
		"[urgent]New![/urgent] Sister dearest. Why won't you join me and the other titans? We have been having [speed:1.5]fun fighting[/speed] all morning",
		"right",
		1.0,  # Base typing speed
		0.0,  # Pre-line delay
		0.5   # Post-line delay for dramatic pause
	))
	
	# Mnemosyne speaks hesitantly - use slower, more thoughtful pacing
	tutorial_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Chronos thank you for inviting me, but{pause:0.8} you know I can't fight, [slow]I can't really do much of anything[/slow].",
		"left",
		0.8,  # Slightly slower base speed for uncertainty
		0.3   # Pre-line delay for hesitation
	))
	
	# Chronos gets frustrated - mix of speeds to show emotion
	tutorial_lines.append(DialogueLine.new(
		"Chronos", 
		"Yes I know that but [urgent]why?[/urgent] You are a titan are you not? We are the [speed:1.3]straining ones![/speed] Fighting is what we do.{pause:1.0} Have you seen Atlas? He's so strong I bet he could hold up the entire world if he tried. 
",
		"right",
		1.0,
		0.0,
		0.8   # Longer pause after harsh words
	))
	
	tutorial_lines.append(DialogueLine.new(
		"Chronos", 
		"What use is your gift of memory? By all accounts you don't seem to be using your talents anyway, you seem mostly useless, it's vexing. 
",
		"right",
		1.0,
		0.0,
		0.8   # Longer pause after harsh words
	))
	
	# Mnemosyne responds sadly - very slow and contemplative
	tutorial_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"[slow]You're right[/slow], I don't really understand why I am a titan.",
		"left",
		0.6,  # Much slower for sadness
		0.5,  # Pause before speaking
		1.0   # Long pause after admission
	))
	
	# Chronos tries to be encouraging - building energy
	tutorial_lines.append(DialogueLine.new(
		"Chronos", 
		"None of us understand it New.{pause:0.8} Maybe you just need more [speed:1.4]encouragement[/speed], come [urgent]lets fight![/urgent]",
		"right",
		1.2,  # Faster for encouragement
		0.3,
		0.5
	))
	

	var tutorial_cutscene = CutsceneData.new("tutorial_intro", [mnemosyne, chronos], tutorial_lines)
	cutscenes["tutorial_intro"] = tutorial_cutscene
	
	
	# First conversation with Chiron
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
	opening_lines.append(DialogueLine.new("Chiron", "Chronos as divine a being he undoubtedly is, doesn't have this potential. What you see now is what you will get come millenia."))
	opening_lines.append(DialogueLine.new("Chiron", "So in a cosmic sense the only way you could possibly ever lose to someone like Chronos is to never do anything. You could take a step once every hundred years and eventually you would win. "))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Well okay I must say when you put it like that it's quite encouraging, but I don't really know where to start."))
	opening_lines.append(DialogueLine.new("Chiron", "It feels a little ridiculous me telling you of all people how to learn"))
	opening_lines.append(DialogueLine.new("Chiron", "But when I learn something new, I usually find someone I trust and ask them to teach me."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "So will you then? Teach me?"))
	opening_lines.append(DialogueLine.new("Chiron", "Of course I will. Who would be foolish enough to pass up such an opportunity. Where should we start?"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "I want to be able to stand up for myself, I want to show Chronos i'm worthy of being a Titan"))
	opening_lines.append(DialogueLine.new("Chiron", "As I just mentioned, first find a trustworthy mentor, rely on their knowledge and skills - while learning. You will find eventually your own strength is all that is required. "))
	opening_lines.append(DialogueLine.new("Chiron", "Go and visit Apollo, he owes me one for Asclepius."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Thank you Chiron. "))
	opening_lines.append(DialogueLine.new("Chiron", "I’ll be here when you need me."))


	# First defeat conversation 
	var first_defeat_lines: Array[DialogueLine] = []

	# Create the full conversation with proper pacing and emotional beats
	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Back already New? Come on in and rest.",
		"right",
		1.0,
		0.0,
		0.5
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"[slow]I didn't do so well Chiron[/slow]",
		"left",
		0.8,
		0.3,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Tell me what happened?",
		"right",
		0.9,
		0.2,
		0.5
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I was defeated.{pause:0.8} [slow]Quite easily it seems, nothing was achieved.[/slow]",
		"left",
		0.7,
		0.3,
		1.0
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Nothing was achieved?",
		"right",
		1.0,
		0.3,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Hmmm{pause:0.5} colour me confused….",
		"right",
		0.9,
		0.2,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"How so?",
		"left",
		1.0,
		0.2,
		0.5
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Word has come to me [speed:1.2]Phoebus Apollo[/speed] has agreed to be your ally.{pause:1.0} Only someone as mighty as a Titan could consider such a union, with an Olympian no less, as [slow]nothing[/slow].",
		"right",
		0.9,
		0.3,
		1.2
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Well….",
		"left",
		0.8,
		0.5,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"I am also informed that your confederates on this joint quest have also improved their experience through combat under your guidance.",
		"right",
		1.0,
		0.2,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"I'm told they [speed:1.3]can't wait[/speed] to see what strength and abilities future ventures with you will yield them.",
		"right",
		1.1,
		0.1,
		1.0
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"……..{pause:2.0}",
		"left",
		0.5,
		0.5,
		1.5
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Sorry for being so direct.{pause:0.8} But we talked earlier about victory being assured if you only took one step every hundred years.",
		"right",
		0.9,
		0.3,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Yet in a cosmic blink of an eye you have already taken several,{pause:0.5} I can't help but celebrate,{pause:0.3} [speed:1.4]how could I not?[/speed]",
		"right",
		1.0,
		0.2,
		1.2
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Thank you for your kind words Chiron.",
		"left",
		0.9,
		0.8,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I can feel the pull of [speed:1.2]Ananke[/speed] and with your gift of inspiration{pause:0.5} I'm ready to try again.",
		"left",
		1.0,
		0.3,
		0.8
	))

	first_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"[slow]I'll be here when you need me.[/slow]",
		"right",
		0.7,
		0.5,
		1.0
	))
	# Second defeat conversation - NEW ADDITION
	var second_defeat_lines: Array[DialogueLine] = []

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"New! Come on in, come on in",
		"right",
		1.1,
		0.0,
		0.5
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Chiron, you are so positive but{pause:0.5} [slow]it is with ill tidings I return[/slow]",
		"left",
		0.8,
		0.3,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"For I am once again, defeated.",
		"left",
		0.7,
		0.2,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Tell me about your last adventure, [speed:1.3]you must![/speed]",
		"right",
		1.0,
		0.2,
		0.5
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"There's not much to tell unfortunately,{pause:0.8} [slow]that is the point[/slow]",
		"left",
		0.8,
		0.3,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"You remind me of a tale from the east.{pause:0.5} Would you believe it? [speed:1.2]Whole worlds exist beyond the wine dark sea.[/speed]",
		"right",
		0.9,
		0.3,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"But anyway, to the east there was once a fish.",
		"right",
		1.0,
		0.2,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"A fish?",
		"left",
		1.0,
		0.3,
		0.5
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Well more specifically a carp, but more importantly{pause:0.5} [speed:1.2]the carp was magic[/speed]",
		"right",
		0.9,
		0.2,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"A magic carp?",
		"left",
		1.0,
		0.3,
		0.5
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Indeed. The carp was forced to fight! Often against it's will.",
		"right",
		1.0,
		0.2,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"In the beginning the carp could do nearly nothing,{pause:0.5} more specifically it could splash around,{pause:0.3} [slow]the effect was negligible.[/slow]",
		"right",
		0.9,
		0.2,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Once it had run out of the energy to splash, it found it could struggle.{pause:0.8} It would hurt itself whilst struggling but{pause:0.5} at least it could make progress.",
		"right",
		0.9,
		0.2,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Eventually after struggling for some time it learned it could tackle.{pause:0.5} It was still slow progress but [speed:1.3]lightning quick[/speed] compared to memories of splashing.",
		"right",
		1.0,
		0.2,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"One day after tackling a particularly challenging adversary{pause:1.0} [speed:1.4]The carp transformed into a massive dragon, powerful and fearsome.[/speed]",
		"right",
		0.9,
		0.3,
		1.2
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"It's a lovely tale Chiron.{pause:0.8} Am I to interpret{pause:0.5} [slow]I am a carp splashing so to speak?[/slow]",
		"left",
		0.8,
		0.3,
		1.0
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"Splashing yes, struggling maybe.{pause:0.8} But [speed:1.2]blessedly[/speed] on one's way to dragoonhood.",
		"right",
		0.9,
		0.3,
		1.2
	))

	second_defeat_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I can feel the pull of [speed:1.2]Ananke[/speed] and with your gift of inspiration{pause:0.5} I'm ready to try again.",
		"left",
		1.0,
		0.3,
		0.8
	))

	second_defeat_lines.append(DialogueLine.new(
		"Chiron", 
		"[slow]I can be found in this locale whence my presence is required.[/slow]",
		"right",
		0.7,
		0.5,
		1.0
	))
	var first_boss_loss_lines: Array[DialogueLine] = []

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"New! Come on in, you look{pause:0.5} [slow]perturbed[/slow]",
		"right",
		1.0,
		0.0,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I came up against a foe,{pause:0.8} [slow]I could not see who they were.[/slow]",
		"left",
		0.8,
		0.3,
		1.0
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Nor did I recognise any of the forces used against me,{pause:0.5} such powers I had never seen before.",
		"left",
		0.9,
		0.2,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Describe them if you will",
		"right",
		1.0,
		0.3,
		0.5
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"A giant, whose blows rang out with such force they could still be felt many moments after they had landed.{pause:1.0} A woman slender, but [urgent]sharp[/urgent]…. [slow]sharp in every way you could imagine.[/slow]",
		"left",
		0.9,
		0.2,
		1.2
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"But most perplexing was their leader.{pause:0.8} It seemed they could [speed:1.3]predict my every move[/speed], I found myself second guessing my plays.{pause:1.0} [slow]In the chaos I was defeated.[/slow]",
		"left",
		0.8,
		0.3,
		1.5
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Predicting your moves you say?{pause:0.5} Could sister [speed:1.2]Phoebe[/speed] be playing a joke on you?{pause:0.8} Who else could out predict the God of Augury himself?",
		"right",
		0.9,
		0.3,
		1.0
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Did you notice anything else out of the ordinary?",
		"right",
		1.0,
		0.5,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Well sometimes I got the feeling I was being watched.{pause:0.8} But I can't know for sure how relevant that is.",
		"left",
		0.9,
		0.3,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"You should [speed:1.2]trust your instinct[/speed].{pause:0.5} The sense of being watched came to you for a reason.{pause:0.8} Perhaps this foe is no divinator but a [slow]simple spy.[/slow]",
		"right",
		1.0,
		0.2,
		1.0
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Hmmmm{pause:1.0} Observing your tactics prior to engaging you.{pause:0.8} They are taking you seriously as an enemy which paints them as [speed:1.3]intelligent[/speed].",
		"right",
		0.9,
		0.3,
		1.2
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"I will need to meditate on what this portends,{pause:0.8} in the meantime, [urgent]try again, you must![/urgent]",
		"right",
		1.0,
		0.3,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I can feel the pull of [speed:1.2]Ananke[/speed] and with your gift of inspiration{pause:0.5} I'm ready to try again.",
		"left",
		1.0,
		0.3,
		0.8
	))

	first_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"[slow]I'll be here when you need me.[/slow]",
		"right",
		0.7,
		0.5,
		1.0
	))

	var first_boss_loss_cutscene = CutsceneData.new("first_boss_loss_conversation", [mnemosyne, chiron], first_boss_loss_lines)
	cutscenes["first_boss_loss_conversation"] = first_boss_loss_cutscene
	
	
	
	var first_defeat_cutscene = CutsceneData.new("first_defeat_conversation", [mnemosyne, chiron], first_defeat_lines)
	cutscenes["first_defeat_conversation"] = first_defeat_cutscene
	
	var second_defeat_cutscene = CutsceneData.new("second_defeat_conversation", [mnemosyne, chiron], second_defeat_lines)
	cutscenes["second_defeat_conversation"] = second_defeat_cutscene

	var opening_awakening_cutscene = CutsceneData.new("opening_awakening", [mnemosyne, chiron], opening_lines)
	cutscenes["opening_awakening"] = opening_awakening_cutscene


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
	TransitionManagerAutoload.change_scene_to("res://Scenes/Cutscene.tscn")

func return_to_previous_scene():
	# Special handling for tutorial flow
	var last_played = viewed_cutscenes[-1] if viewed_cutscenes.size() > 0 else ""
	
	if last_played == "tutorial_intro":
		print("Completed tutorial intro cutscene, starting tutorial battle")
		# FIXED: Set up tutorial battle parameters more explicitly
		get_tree().set_meta("scene_params", {
			"is_tutorial": true,
			"god": "Mnemosyne",  # This should be the player's god
			"deck_index": 0,     # Add deck index for consistency
			"opponent": "Chronos"
		})
		print("Tutorial params set: ", get_tree().get_meta("scene_params"))
		TransitionManagerAutoload.change_scene_to("res://Scenes/CardBattle.tscn")
		return
	elif last_played == "opening_awakening":
		print("Completed post-tutorial cutscene, going to god select")
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")
		return
	
	if return_scene_path != "":
		# Restore scene parameters if they existed
		if not return_scene_params.is_empty():
			get_tree().set_meta("scene_params", return_scene_params)
		
		print("Returning to: ", return_scene_path)
		TransitionManagerAutoload.change_scene_to(return_scene_path)
		
		# Clear stored data
		return_scene_path = ""
		return_scene_params.clear()
	else:
		print("No return scene stored, going to main menu")
		TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

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
