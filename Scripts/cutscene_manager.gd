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
	
	#4
	var first_apollo_boss_win_lines: Array[DialogueLine] = []
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Hello New! Come on in, I can't wait to hear what you have been up to"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Hi there Chiron. I have been toiling under the guidance of the shining one"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Yet you don't seem overjoyed? How then fares Apollo?"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "He appears afflicted. It's clear even to me, he is ….. unhappy"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Ahhh yes… the source of his discontent is known to me"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "What has happened?"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "It brings me no joy to tell you this story, but you can't possibly understand without knowing. It concerns Asclepius."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "His son? The master of medicine?"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Yes the boy spent time under my tutelage, gloriously methodical he was. I barely taught him anything, the most useful thing I ever did was get out of his way."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "But it is his manner of entering the world in which the heart of the issue lies."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "His mother Coronis slept with a mortal while she was pregnant."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "She was unfaithful?"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "So the tale goes."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "In his rage Apollo sent plague arrows to the city, Coronis quickly fell ill."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Apollo arrived in time to see her pass. He delivered Asclepius surgically, a blessing salvaged from an otherwise accursed day."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "So it is guilt then? From which he suffers?"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "The events are agreed upon, sure. As to the reasoning I cannot say. Only Apollo can tell you that and I won't litigate those that are absent."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "I would ask you to speak with him. Seek to understand, not judge and the answers will come"))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "If I can help the sun rise anew I will."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Together I'm sure we can do it."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of determination I'm ready to try again."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))

	#5
	var second_apollo_boss_win_lines: Array[DialogueLine] = []
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Why hello New, nice to see you - but is everything okay? You look ….. Troubled?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I had the opportunity to broach things with Apollo"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Coronis and Asclepius are indeed the source of his woe."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "So much so was to be expected. Did he take the opportunity to explain himself?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "He did"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "But this didn't provide the clarity you hoped it would?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Well no and he asked for my guidance on how to heal"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Interesting, what was his explanation?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Apollo feels his actions are justified in light of Coronis' faithlessness"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "You feel this is unfair?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Dare I say it about the god of reason. But I suspect he is being unreasonable."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Go on"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Coronis is visited upon by Apollo who then departs. There is no sworn covenant, no offer of marriage, no clarity he would even return. In the unknown was she meant to simply wait and hope? Pregnant and alone?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Seeking reliable support seems not only natural but sensible does it not? Apollo hardly put off his other romances during this time, it just all feels a little bit…… a little bit…."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "It's better the words come from your immortal mouth than mine."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Hypocritical."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Apollo is grappling between his sense of wounded pride and an internal suspicion of wrongdoing. In his heart of hearts he knows the punishment was too harsh but he dare not admit it for fear of losing face."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Until the discord between these two positions is erased the torture will continue."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "So how then can it be mended?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Apollo should look to the constellation Corvus the crow, offer his apologies, admit fault, then and only then will he be free from this burden. If you cannot convince him, don't feel so bad, he is immortal after all and will find this peace eventually."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of illumination I'm ready to try again."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))
	
	
	#6
	var first_apollo_boss_loss_lines: Array[DialogueLine] = []

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"New! Come on in, you look{pause:0.5} [slow]perturbed[/slow]",
		"right",
		1.0,
		0.0,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I came up against a foe,{pause:0.8} [slow]I could not see who they were.[/slow]",
		"left",
		0.8,
		0.3,
		1.0
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Nor did I recognise any of the forces used against me,{pause:0.5} such powers I had never seen before.",
		"left",
		0.9,
		0.2,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Describe them if you will",
		"right",
		1.0,
		0.3,
		0.5
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"A giant, whose blows rang out with such force they could still be felt many moments after they had landed.{pause:1.0} A woman slender, but [urgent]sharp[/urgent]…. [slow]sharp in every way you could imagine.[/slow]",
		"left",
		0.9,
		0.2,
		1.2
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"But most perplexing was their leader.{pause:0.8} It seemed they could [speed:1.3]predict my every move[/speed], I found myself second guessing my plays.{pause:1.0} [slow]In the chaos I was defeated.[/slow]",
		"left",
		0.8,
		0.3,
		1.5
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Predicting your moves you say?{pause:0.5} Could sister [speed:1.2]Phoebe[/speed] be playing a joke on you?{pause:0.8} Who else could out predict the God of Augury himself?",
		"right",
		0.9,
		0.3,
		1.0
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Did you notice anything else out of the ordinary?",
		"right",
		1.0,
		0.5,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"Well sometimes I got the feeling I was being watched.{pause:0.8} But I can't know for sure how relevant that is.",
		"left",
		0.9,
		0.3,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"You should [speed:1.2]trust your instinct[/speed].{pause:0.5} The sense of being watched came to you for a reason.{pause:0.8} Perhaps this foe is no divinator but a [slow]simple spy.[/slow]",
		"right",
		1.0,
		0.2,
		1.0
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"Hmmmm{pause:1.0} Observing your tactics prior to engaging you.{pause:0.8} They are taking you seriously as an enemy which paints them as [speed:1.3]intelligent[/speed].",
		"right",
		0.9,
		0.3,
		1.2
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"I will need to meditate on what this portends,{pause:0.8} in the meantime, [urgent]try again, you must![/urgent]",
		"right",
		1.0,
		0.3,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Mnemosyne", 
		"I can feel the pull of [speed:1.2]Ananke[/speed] and with your gift of inspiration{pause:0.5} I'm ready to try again.",
		"left",
		1.0,
		0.3,
		0.8
	))

	first_apollo_boss_loss_lines.append(DialogueLine.new(
		"Chiron", 
		"[slow]I'll be here when you need me.[/slow]",
		"right",
		0.7,
		0.5,
		1.0
	))
	
	#7
	var second_apollo_boss_loss_lines: Array[DialogueLine] = []
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Right! Chiron, I'm back."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "New, why hello. How are things?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I'm frustrated, I encountered that mysterious foe again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "And based on your frustration, you did not fare well?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I fell prey to their machinations once again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I have been thinking on what you told me last time, but what new information were you able to glean from this encounter?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "This enemy seems to be able to predict my moves, when they do so my forces are ambushed upon arrival and are rendered practically useless."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "You still have the sense of being watched in the lead up to the battle?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I do, strongly."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Could it be possible they watch you to learn your preferred battle tactics? The order in which you deploy your troops and where you station them?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Then….. Using that information, know where to lay in wait?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Based on what you say it sounds likely."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "How do we turn this suspicion to practical account?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "We could poison the information. Trick them into thinking our dominant strategy is one way then switching it up during the final showdown."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "That may mean battling suboptimally on purpose. Which runs the risk of defeat to a lesser foe."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Indeed it would be a fine line to walk"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Impressive Chiron."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "With such allied generalship I couldn't possibly lose - won't you join me in the field of battle?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "That's very kind of you New. But you would quickly find my theories are more powerful than my spear arm. I prefer my cave."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "With this information you will find your mettle more than enough."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of stratagem I'm ready to try again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))
	
	#8
	var first_hermes_boss_loss_lines: Array[DialogueLine] = []
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Chiron my friend, I come seeking advice"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "New! Come on in, I just sent Jason home for the day. What should we think about?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I encountered that unnamed foe again"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "A rematch! What happened?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Nothing made sense Chiron. I fought a fierce squirrel, a weakling of a giant and everything in between."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "When I sent forth to capture the weakest enemies my attacks were instead met with iron resistance. My resources were spent without advantage. In the chaos, I was defeated."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "A fierce squirrel you say?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "The mightiest I have ever seen."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "What's worse is Hermes knows what is going on but he refuses to tell me! Odysseus whispered something in his ear, pointed at me and they started laughing."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Quite rude I must say."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "But I too have bad news."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "You do?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I think I also know what's happening. And…."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "and…?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I'm also not going to tell you."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "!?!?!?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Whilst it is helpful to stand on the shoulders of giants, you do have to carve your own path from time to time. I'm not worried. It's hard to imagine the answer escaping your awesome mind for too long."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "You're lucky I like you so much Chiron"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of independence I'm ready to try again"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))
	
	#9
	var second_hermes_boss_loss_lines: Array[DialogueLine] = []
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "New! What a pleasure come on in"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "But oh - the look on your face! Wait, wait, wait, Let me guess."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Go on"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "You faced that particularly illusory foe again didn't you?"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "*nods*"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "You were defeated?"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "*nods*"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "But importantly, you now know what is happening?"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Yes, I do"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "What is your interpretation?"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "This enemy employs deception with respect to their relative strengths"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Weaker units whilst still functionally behaving weakly have the outward appearance of strength."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "The facade is further deepened with abilities that reinforce this perception."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Our faith in your ability to solve the conundrum has been duly rewarded."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Odysseus may have been laughing before. But I bet he is already quietly invoking your guidance when he forms a plan."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Armed with this information, go forth and crush them."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of faith I'm ready to try again"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))
	
	#10
	var first_artemis_boss_loss_lines: Array[DialogueLine] = []
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Hello New! Is that you out there? Come on in"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Chiron, I come in need of your strategic wisdom once more."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "What has happened?"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "It is my adversary - the unnamed foe."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Once again we fought. Even with the support of Artemis, at a crucial juncture I committed my forces before being out-maneouvered. In the chaos, I was defeated."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "The Huntress you say?"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "*nods*"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "I'll keep things simple, I won't talk about Artemis."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Chiron?"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "She has been known to react negatively to insults and flattery both real and imagined. Making the vengeance delivered by Nemesis look restrained in comparison."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "So you really won't ---"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Both real or imagined New"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "……"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "……"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "……"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Thank you, in life some dice are just not worth rolling."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Try fighting again and if you run into trouble we could discuss the battle and its outcome in a purely hypothetical fashion of course."))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of temperance I'm ready to try again"))
	first_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))
	
	#11
	var second_artemis_boss_loss_lines: Array[DialogueLine] = []
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Chiron I once again return with the need for advice"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Very nice to see you New! What should we discuss?"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I'm not really sure how to ask."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Ahh yes are we talking about that hypothetical situation? The one in which any of the otherwise involved members are not to be either blamed nor praised?"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Yes that one"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Well I would probably start by explaining the issue in terms of say - a game"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "In said game you are playing, what seems to be the issue?"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "My opponent seems to turn my strengths against me."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Even if I coordinate an attack and capture the enemy forces, they perform a retreat that is so smooth it could only be planned. Then they retaliate with great ferocity."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "I can think of a few ways of dealing with what you are describing, if I can think of them I bet you can too."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Well I had thought of using the coordinated attack early when there are less foes present, but even if they don't get the advantage of the planned retreat, I have used my trump care to no avail."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "What else had you considered?"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "If I use the coordinated attack as the last movement of the battle, the opponent wouldn't get a chance to counter."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Hmmm, indeed that sounds correct. The wise masters of old first put themselves beyond the possibility of defeat before acting, your description would be in accordance with this."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "But I can't always control whether my maneuver is the last action of any given encounter. The order of each combat it seems is at the will of the fates."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Could you not liken it to the hunter? You can set your ambush up, but you cannot guarantee your quarry will enter."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "If they do however, you can take the perfect singular strike ending things then and there."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "If they don't approach the killing field, you can always stay your hand. Rather than give away your position with a risky and ineffective shot."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "You are saying unless it can be decisive, I shouldn't use my strongest ability at all?"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "Indeed, with this in mind, return to lay in wait once more."))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of patience I'm ready to try again"))
	second_artemis_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))
	
	#12
	var first_demeter_defeat_lines: Array[DialogueLine] = []
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "New!? Is that you? I missed you! Come on in, come on in. Where have you been?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I have been blessed to be training under the guidance of Demeter"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "How fares the protectorate of fertile fecundity?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "She has quite an extreme attachment to Persephone. Her grief at her absence is quite chilling."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "It is known that during winter we are subject to Demeter's mourning for the loss of Persephone."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I expected the goddess to be well….. stronger."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "What a curious thing to say."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I'm grateful really it's just, after witnessing the power of the other Olympians I was a little underwhelmed."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Fascinating. Do you not think Hyperion could say the same thing about you?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "\"New is great and all but after witnessing the power of the other Titans I was a little underwhelmed\""))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "…… I didn't mean it that way."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Seed turns to shoot before solid timber."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "It is in both yours and Demeter's potential for growth in which your strength lies."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "How Epimethean of me."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "But how Promethean of you to recognise the error in your thinking when it is revealed."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Could Atlas have understood such so briskly?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "Consider me converted, what now, should I do?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Tend the soil, with kindness and sweat. It has never yet failed to reward earnest toil."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "You will see you and your niece have more in common than you realise."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of patience I'm ready to try again"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))
	
	
	# dialogue index 0
	var tutorial_cutscene = CutsceneData.new("tutorial_intro", [mnemosyne, chronos], tutorial_lines)
	cutscenes["tutorial_intro"] = tutorial_cutscene
	
	#dialogue index 1
	var opening_awakening_cutscene = CutsceneData.new("opening_awakening", [mnemosyne, chiron], opening_lines)
	cutscenes["opening_awakening"] = opening_awakening_cutscene
	
	# dialogue index 2
	var first_defeat_cutscene = CutsceneData.new("first_defeat_conversation", [mnemosyne, chiron], first_defeat_lines)
	cutscenes["first_defeat_conversation"] = first_defeat_cutscene
	
	# dialogue index 3
	var second_defeat_cutscene = CutsceneData.new("second_defeat_conversation", [mnemosyne, chiron], second_defeat_lines)
	cutscenes["second_defeat_conversation"] = second_defeat_cutscene
	
	#dialogue index 4
	var first_apollo_boss_win_cutscene = CutsceneData.new("first_apollo_boss_win_conversation", [mnemosyne, chiron], first_apollo_boss_win_lines)
	cutscenes["first_apollo_boss_win_conversation"] = first_apollo_boss_win_cutscene
	
	#dialogue index 5
	var second_apollo_boss_win_cutscene = CutsceneData.new("second_apollo_boss_win_conversation", [mnemosyne, chiron], second_apollo_boss_win_lines)
	cutscenes["second_apollo_boss_win_conversation"] = second_apollo_boss_win_cutscene
	
	# dialogue index 6 
	var first_apollo_boss_loss_cutscene = CutsceneData.new("first_apollo_boss_loss_conversation", [mnemosyne, chiron], first_apollo_boss_loss_lines)
	cutscenes["first_apollo_boss_loss_conversation"] = first_apollo_boss_loss_cutscene
	
	# dialogue index 7 
	var second_apollo_boss_loss_cutscene = CutsceneData.new("second_apollo_boss_loss_conversation", [mnemosyne, chiron], second_apollo_boss_loss_lines)
	cutscenes["second_apollo_boss_loss_conversation"] = second_apollo_boss_loss_cutscene
	
	# dialogue index 8 
	var first_hermes_boss_loss_cutscene = CutsceneData.new("first_hermes_boss_loss_conversation", [mnemosyne, chiron], first_hermes_boss_loss_lines)
	cutscenes["first_hermes_boss_loss_conversation"] = first_hermes_boss_loss_cutscene
	
	# dialogue index 9 
	var second_hermes_boss_loss_cutscene = CutsceneData.new("second_hermes_boss_loss_conversation", [mnemosyne, chiron], second_hermes_boss_loss_lines)
	cutscenes["second_hermes_boss_loss_conversation"] = second_hermes_boss_loss_cutscene
	
	# dialogue index 10 
	var first_artemis_boss_loss_cutscene = CutsceneData.new("first_artemis_boss_loss_conversation", [mnemosyne, chiron], first_artemis_boss_loss_lines)
	cutscenes["first_artemis_boss_loss_conversation"] = first_artemis_boss_loss_cutscene
	
	# dialogue index 11 
	var second_artemis_boss_loss_cutscene = CutsceneData.new("second_artemis_boss_loss_conversation", [mnemosyne, chiron], second_artemis_boss_loss_lines)
	cutscenes["second_artemis_boss_loss_conversation"] = second_artemis_boss_loss_cutscene
	
	# dialogue index 12 
	var first_demeter_defeat = CutsceneData.new("first_demeter_defeat_conversation", [mnemosyne, chiron], first_demeter_defeat_lines)
	cutscenes["first_demeter_defeat_conversation"] = first_demeter_defeat
	


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
