# res://Scripts/cutscene_manager.gd
extends Node
class_name CutsceneManager

var cutscenes: Dictionary = {}
var viewed_cutscenes: Array[String] = []
var replay_from_journal: bool = false

var save_path: String = "user://viewed_cutscenes.save"

# Scene management
var return_scene_path: String = ""
var return_scene_params: Dictionary = {}

func _ready():
	# Load all cutscenes
	load_cutscenes()
	load_viewed_cutscenes()

# Load and register all cutscenes
func load_cutscenes():
	# For now, we'll create cutscenes programmatically
	# Later these could be loaded from files
	create_sample_cutscenes()

# Create some sample cutscenes for testing
# Create some sample cutscenes for testing
func create_sample_cutscenes():
	# Load portrait textures
	var chiron_portrait = load("res://Assets/Images/Chiron.png")
	var mnemosyne_portrait = load("res://Assets/Images/Mnemosyne.png")

	# Create Mnemosyne character
	var mnemosyne = Character.new("Mnemosyne", Color("#1F4A3D"), mnemosyne_portrait, "left")
	# Create Chrion character  
	var chiron = Character.new("Chiron", Color("#1F4A3D"), chiron_portrait, "right")
	
	# Create Chronos character  
	var chronos = Character.new("Chronos", Color("#1F4A3D"), null, "right")


	# -------------------------------------------------------------------------
	# CUTSCENE 0 - Tutorial introduction (Mnemosyne and Chronos)
	# -------------------------------------------------------------------------
	var tutorial_lines: Array[DialogueLine] = []
	tutorial_lines.append(DialogueLine.new("Chronos", "New! Sister dearest. Why won't you join me and the other titans? We have been having fun fighting all morning."))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "Chronos you know I can't fight, I can't really do much of anything."))
	tutorial_lines.append(DialogueLine.new("Chronos", "Yes I know that but why? You are a titan are you not? We are the straining ones! Fighting is what we do."))
	tutorial_lines.append(DialogueLine.new("Chronos", "Before I gelded father he would always go on and on about your potential for power."))
	tutorial_lines.append(DialogueLine.new("Chronos", "What use is your gift of memory? By all accounts you don't seem to be using your talents anyway, you seem mostly useless, it's vexing."))
	tutorial_lines.append(DialogueLine.new("Mnemosyne", "You're right, I don't really understand why I am a titan."))
	tutorial_lines.append(DialogueLine.new("Chronos", "None of us understand it New. Maybe you just need more encouragement, come let's fight!"))


	# -------------------------------------------------------------------------
	# CUTSCENE 1 - Post tutorial (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var opening_lines: Array[DialogueLine] = []
	opening_lines.append(DialogueLine.new("Chiron", "You fought well Mnemosyne"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "I don't think I…."))
	opening_lines.append(DialogueLine.new("Chiron", "You fought well, with the tools you have available at this time"))
	opening_lines.append(DialogueLine.new("Chiron", "Given the fullness of said time, Chronos would do best to avoid you."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Hold on… who are you? How do you know me?"))
	opening_lines.append(DialogueLine.new("Chiron", "So it's true then, what an honour. To speak to the Titaness of memory before she understands the extent of her power. My name is Chiron."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "And you are a….."))
	opening_lines.append(DialogueLine.new("Chiron", "A centaur, yes"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Sorry"))
	opening_lines.append(DialogueLine.new("Chiron", "How fascinating, you know one day it will be me apologising to you for the incompleteness of my thought"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Okay enough please, you have to tell me what you mean by all this"))
	opening_lines.append(DialogueLine.new("Chiron", "Chaos, the Fate's, Moros if you will, whatever source you want to invoke has decided your realm would be that of memory. More than that, a divine infinite capacity to remember and learn."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "So I can learn? That's it?"))
	opening_lines.append(DialogueLine.new("Chiron", "Why yes but can't you see what that means? You are immortal, you will live forever. Forever is a long time to learn, to improve."))
	opening_lines.append(DialogueLine.new("Chiron", "Chronos as divine a being my father undoubtedly is, doesn't have this potential. What you see now is what you will get come millenia."))
	opening_lines.append(DialogueLine.new("Chiron", "So in a cosmic sense the only way you could possibly ever lose to someone like Chronos is to never do anything. You could take a step once every hundred years and eventually you would win."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Well okay I must say when you put it like that it's quite encouraging, but I don't really know where to start."))
	opening_lines.append(DialogueLine.new("Chiron", "When I learn something new, I usually find someone I trust and ask them to teach me."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "So will you then? Teach me?"))
	opening_lines.append(DialogueLine.new("Chiron", "Of course I will. It will be fun to mess with dad. What do you want to learn?"))
	opening_lines.append(DialogueLine.new("Mnemosyne", "I want to be able to stand up for myself, I want to show Chronos i'm worthy of being a Titan"))
	opening_lines.append(DialogueLine.new("Chiron", "As I just mentioned, first find a trustworthy mentor, rely on their knowledge and skills - while learning. You will find eventually your own strength is all that is required."))
	opening_lines.append(DialogueLine.new("Chiron", "Go and visit Apollo, he owes me for Asclepius."))
	opening_lines.append(DialogueLine.new("Mnemosyne", "Thank you Chiron."))
	opening_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 2 - First defeat (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var first_defeat_lines: Array[DialogueLine] = []
	first_defeat_lines.append(DialogueLine.new("Chiron", "Back already New? Come on in and rest."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "I didn't do so well Chiron"))
	first_defeat_lines.append(DialogueLine.new("Chiron", "Tell me what happened?"))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "I was defeated. Quite easily it seems, nothing was achieved."))
	first_defeat_lines.append(DialogueLine.new("Chiron", "Nothing was achieved?"))
	first_defeat_lines.append(DialogueLine.new("Chiron", "Hmmm colour me confused…."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "How so?"))
	first_defeat_lines.append(DialogueLine.new("Chiron", "Word has come to me Phoebus Apollo has agreed to be your ally. Only someone as mighty as a Titan could consider such a union, with an Olympian no less, as nothing."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "Well…."))
	first_defeat_lines.append(DialogueLine.new("Chiron", "I am also informed that your confederates on this joint quest have also improved their experience through combat under your guidance."))
	first_defeat_lines.append(DialogueLine.new("Chiron", "I'm told they can't wait to see what strength and abilities future ventures with you will yield them."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "…….."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "It's just defeating Chronos feels as far away as ever"))
	first_defeat_lines.append(DialogueLine.new("Chiron", "You wish to defeat Chronos do you?"))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "Well, yeah  --"))
	first_defeat_lines.append(DialogueLine.new("Chiron", "And I wish Selene would respond to my requests for an evening together. But worthwhile tasks take time and effort."))
	first_defeat_lines.append(DialogueLine.new("Chiron", "Your journey has but begun, give yourself some grace."))
	first_defeat_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of inspiration I'm ready to try again."))
	first_defeat_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 3 - Second defeat (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var second_defeat_lines: Array[DialogueLine] = []
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "Chiron! Are you there?"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "New?"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "Come on in, come on in. How goes your latest adventure?"))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "I am reluctant to say, for I return, once again, cloaked in defeat and failure."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "You consider your latest attempt a failure? And that this is a bad thing? Hmmm most curious"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "Have you ever met your sister-in-law Pandora?"))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "No I haven't."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "But are you aware of her role in ending the golden age of man?"))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "It is said overpowering curiosity led her to open a sacred pithos containing all the ills and evils of the world."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "Indeed."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "Strife. Pain. Murder. Lies. Ruin. Oath Breaking. Grief. Famine."))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "Good memory dear friend, but I don't know what you are getting at here."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "You were right to state all ills and evils were released. But I ask you, where among them is failure?"))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "I…… well."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "It's not there is it? What are we to make of that?"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "Had failure been evil would it not have been there hand in hand with Eris?"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "The interpretation is obvious. Failure is not evil let alone bad. The primordial evils understood this."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "It is only through the eyes of failure one can begin to see success."))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "So what then? I am to court defeat?"))
	second_defeat_lines.append(DialogueLine.new("Chiron", "You should both avoid being defeated and avoid wallowing in defeat with equal ferocity."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "See failure as a necessary fee for success."))
	second_defeat_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of clarity I'm ready to try again."))
	second_defeat_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 4 - Third defeat (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var third_defeat_lines: Array[DialogueLine] = []
	third_defeat_lines.append(DialogueLine.new("Chiron", "New! Come on in, come on in"))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "Chiron, you are so positive but it is with ill tidings I return"))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "For I am once again, defeated."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "Tell me about your last adventure, you must!"))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "There's not much to tell unfortunately, that is the point"))
	third_defeat_lines.append(DialogueLine.new("Chiron", "You remind me of a tale from the east. Would you believe it? Whole worlds exist beyond the wine dark sea."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "But anyway, to the east there was once a fish."))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "A fish?"))
	third_defeat_lines.append(DialogueLine.new("Chiron", "well more specifically a carp, but more importantly the carp was magic"))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "A magic carp?"))
	third_defeat_lines.append(DialogueLine.new("Chiron", "Indeed."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "In the beginning the carp could do nothing, it could but splash around, the effect was negligible."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "Once it had run out of the energy to splash, it found it could struggle. It would hurt itself whilst struggling but at least it could make progress."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "Eventually after struggling for some time it learned it could tackle. It remained slow progress but lightning quick compared to memories of splashing."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "One day after tackling a particularly challenging adversary. The carp transformed into a massive dragon, powerful and fearsome."))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "It's a lovely tale Chiron. Am I to interpret I am a carp splashing so to speak?"))
	third_defeat_lines.append(DialogueLine.new("Chiron", "Splashing yes, struggling maybe, tackling soon. But blessedly on one's way to dragonhood."))
	third_defeat_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of perseverance I'm ready to try again."))
	third_defeat_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 5 - First Apollo boss win (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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
	first_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of determination I'm ready to try again."))
	first_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 6 - Second Apollo boss win (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Dare I say it about the god of reason. But I do."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Go on"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Coronis is visited upon by Apollo who then departs. There is no sworn covenant, no offer of marriage, no clarity he would even return. In the unknown was she meant to simply wait and hope? Pregnant and alone?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Seeking reliable support seems not only natural but sensible does it not? Apollo hardly put off his other romances during this time, it just all feels a little bit…… a little bit…."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "It's better the words come from your mouth than mine."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Hypocritical."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Apollo is grappling between his sense of wounded pride and an internal suspicion of wrongdoing. In his heart of hearts he knows the punishment was too harsh but he dare not admit it for fear of losing face."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Until the discord between these two positions is erased the torture will continue."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "So how then can it be mended?"))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "Apollo should look to the constellation Corvus the crow, offer his apologies, admit fault, then and only then will he be free from this burden. If you cannot convince him, don't feel so bad, he is immortal after all and will find this peace eventually."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of illumination I'm ready to try again."))
	second_apollo_boss_win_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 7 - First Apollo boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var first_apollo_boss_loss_lines: Array[DialogueLine] = []
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "New! Come on in, you look… perturbed"))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I came up against a foe, I could not see who they were."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Nor did I recognise any of the forces used against me, such powers I had never seen before."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Describe them if you will"))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "A giant, whose blows rang out with such force they could still be felt many moments after they had landed. A woman slender, but sharp…. sharp in every way you could imagine."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "But most perplexing was their leader. It seemed they could predict my every move, I found myself second guessing my plays. In the chaos, I was defeated."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Predicting your moves you say? Could sister Phoebe be playing a joke on you? Who else could out predict the God of Augury himself?"))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Did you notice anything else out of the ordinary?"))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Well sometimes I got the feeling I was being watched. But I can't know for sure how relevant that is."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "You should trust your instinct. The sense of being watched came to you for a reason. Perhaps this foe is no divinator but a simple spy."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Hmmmm…. Observing your tactics prior to engaging you. They are taking you seriously as an enemy which paints them as intelligent."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I will need to meditate on what this portends, in the meantime, try again, you must!"))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of inspiration I'm ready to try again."))
	first_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 8 - Second Apollo boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var second_apollo_boss_loss_lines: Array[DialogueLine] = []
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Right! Chiron, I'm back."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "New, why hello. How are things?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I encountered that mysterious foe again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "And based on your frustration, you did not fare well?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I fell prey to their machinations once again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I have been thinking on what you told me last time, but what new information were you able to glean from this encounter?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "This enemy seems to be able to predict my moves, when they do so my forces are ambushed upon arrival and are rendered practically useless. I can then hear him laughing."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "You still have the sense of being watched in the lead up to the battle?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I do, strongly."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Could it be possible they watch you to learn your preferred battle tactics? The order in which you deploy your troops and where you station them?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Then….. Using that information, know where to lay in wait?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Based on what you say it sounds likely."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "How do we turn this suspicion to practical account?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "We could poison the information. Trick them into thinking our dominant strategy is one way then switching it up during the final encounter."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "That may mean battling suboptimally on purpose. Which runs the risk of defeat to a lesser foe."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "Indeed it would be a fine line to walk"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Impressive Chiron."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "With such allied generalship I couldn't possibly lose - won't you join me in the field of battle?"))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "That's very kind of you New. But you would quickly find my theories are more powerful than my spear arm. I prefer my cave."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "With this information you will find your mettle more than enough."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of stratagem I'm ready to try again."))
	second_apollo_boss_loss_lines.append(DialogueLine.new("Chiron", "I'll be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 9 - First Hermes boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I think I know what's happening too. And…."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "and…?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I'm also not going to tell you."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "!?!?!?"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Whilst it is helpful to stand on the shoulders of giants, you do have to carve your own path from time to time. I'm not worried. It's hard to imagine the answer escaping your awesome mind for too long."))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "You're lucky I like you so much Chiron"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of independence I'm ready to try again"))
	first_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 10 - Second Hermes boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "What is weak appears strong, what is strong appears weak"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "The facade is further deepened with abilities that reinforce this perception."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Our faith in your ability to solve the conundrum has been duly rewarded."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Odysseus may have been laughing before. But I bet he is already quietly invoking your guidance when he forms a plan."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "Armed with this information, go forth and crush them."))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of faith I'm ready to try again"))
	second_hermes_boss_loss_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 11 - First Artemis boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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


	# -------------------------------------------------------------------------
	# CUTSCENE 12 - Second Artemis boss loss (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
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
	second_artemis_boss_loss_lines.append(DialogueLine.new("Mnemosyne", "Well I had thought of using the coordinated attack early when there are less foes present, but even if they don't get the advantage of the planned retreat, I have used my trump card to no avail."))
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


	# -------------------------------------------------------------------------
	# CUTSCENE 13 - First Demeter defeat (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var first_demeter_defeat_lines: Array[DialogueLine] = []
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "New!? Is that you? I missed you! Come on in, come on in. Where have you been?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I have been blessed to be training under the guidance of Demeter"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "How fares the protectorate of fertile fecundity?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "She has quite an extreme attachment to Persephone."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "It is known that during winter we are subject to Demeter's mourning for the loss of Persephone."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I expected the goddess to be well….. stronger."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "What a curious thing to say."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I'm grateful really it's just, after witnessing the power of the other Olympians I was a little underwhelmed."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Fascinating. Do you not think Hyperion could say the same thing about you?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "\"New is great and all but after witnessing the power of the other Titans I was a little underwhelmed\""))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "…… I didn't mean it that way."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Seed turns to shoot before timber most solid."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "It is in both yours and Demeter's potential for growth in which your strength lies."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "How Epimethean of me."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "But how Promethean of you to recognise the error in your thinking when it is revealed."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Could Atlas have understood such so briskly?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "Consider me converted, what now, should I do?"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "Tend the soil, with kindness and sweat. It has never yet failed to reward earnest toil."))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "You will see you and your niece have more in common than you realise."))
	first_demeter_defeat_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of patience I'm ready to try again"))
	first_demeter_defeat_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))

	# -------------------------------------------------------------------------
	# CUTSCENE 14 - Post Chronos victory (Mnemosyne and Odin)
	# -------------------------------------------------------------------------
	# Odin has no portrait asset yet - using null like Chronos
	var odin = Character.new("Odin", Color("#1F4A3D"), null, "right")

	var post_chronos_victory_lines: Array[DialogueLine] = []
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Chiron my friend you won't believe what just happened! I finally did it!"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "….."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Chiron?"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "….."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "….."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "….."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "You know I had to sacrifice one of my eyes to get Muninn to sit on my shoulder?"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Who goes there!?"))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Peace friend. They call me Wanderer, Warrior was my father"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Where is Chiron?"))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "If you are asking about this cave's owner. He had already joined Thiazi's eyes by the time we arrived"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "You are standing in a site of great import, a place of power, its rightful owner absent. Riddles will not be abided Stranger. Explain yourself"))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Forgive me it is another land from which I hail. I appreciate my words and their weaving are thus unfamiliar."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "I did not know Chiron. But I can see from your face that the distance and depth of your relationship was close and cavernous. Out of this respect I will tread carefully."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "It seems he has passed from this world."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Chiron…… Dead?"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "You must be mistaken for he is immortal."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "He was gone when you arrived. He will just be out, his return imminent."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "I'm sorry. Huginn here has since been and returned to me with confirmation. A venom to rival Jormungandr drove him to request death. It was granted."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Fear not he is honoured in death and remains immortal. He has joined the stars."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "I…I… I can't believe it."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "*points* You can see him there, the horse man. He's easy to spot for he is next to the moon. It seems she is visiting him this eve."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "……."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "You finally did it my friend."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "I would not normally intrude on those in the throws of grief. I hope it demonstrates the urgency of my cause that I still do so."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "It is your guidance of which I seek."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Me? We do not know each other, in what manner could I be helpful?"))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Ragnarok comes, the end times."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Having searched the worlds beholden to Igdrasil I have not found a way to prevent it. In my desperation I cast the net wider and Muninn led me here."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "I arrived to discover the Master of Memory, Mnemosyne, had not only contended with our greatest enemy, but defeat him in what is now routine."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "So here I stand as Odin. The All-Father. The One-Eyed. Beseeching you to take up our cause. Come with me to Vigrid and together let us destroy Loki."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "……."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Stirring words Odin"))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "Those victories you hold in such high regard. They are a product of the tutelage gifted to me by Chiron."))
	post_chronos_victory_lines.append(DialogueLine.new("Mnemosyne", "To respect and honor that gift. I will come."))
	post_chronos_victory_lines.append(DialogueLine.new("Odin", "Blessed be. To Vigrid! To Destiny! To Ragnarok!"))


	# -------------------------------------------------------------------------
	# CUTSCENE 15 - First Hermes boss win (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var first_hermes_boss_win_lines: Array[DialogueLine] = []
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Chiron!?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Did you see him?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "What do you mean? Who?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Autolycus!"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "I watched him the whole time. But he still managed to steal my Hens Teeth!"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Hens Teeth? Autolycus doesn't strike me as the potion brewing type"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "He's not! He just steals it for fun! It's tradition at this point. I turned when I heard you arrive and that was all the distraction he needed."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "He puts it back a few days later just to mess with me."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Bah! He is a son of Hermes after all, what can you do?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Plus it's hard to stay too mad. He came to me to tend his wounds but also to gloat."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "What about?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "His recent expeditionary success. Under your guidance."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Why yes we defeated the mysterious foe, it's hardly defeating Chronos mind you."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "People are starting to whisper New."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "What do you mean?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Your father Ouranus, when he was lord of us all, spoke of your power."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "If he is to be believed you are the most powerful among us."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I too, find that hard to believe, I mean, look at me."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "You had spent so long in a near dormant state that eventually the claims to your power were forgotten."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Chronos, fearful of this prophecy, quietly visited you, but seeing your apparent weakness, laughed off his fathers words."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Zeus, the same paranoia upon him, also visited you. He uhhhh…. quite liked what he saw and the world was blessed with the 9 muses."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "With your recent victories, the whispers are wondering if maybe old Uranus was right all along."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Whispers or not. My goal remains the same, besting Chronos."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "I never doubted your conviction. Plus our arrangement is working out very well for me in kind."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "How so?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Selene"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "She responded to my last message"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "She is interested to know what it's like to tutor the titan of memory."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Do I sense a date on the horizon?"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "She hasn't yet agreed to meet, but she is interested in me, which is more than I could say before."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "Now kindly get back out there and amaze a few more people would you? Especially if the moon is watching."))
	first_hermes_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of determination I'm ready to try again"))
	first_hermes_boss_win_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 16 - First Artemis boss win (Mnemosyne and Chiron)
	# -------------------------------------------------------------------------
	var first_artemis_boss_win_lines: Array[DialogueLine] = []
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "New! Won't you come on in, how nice to have you visit"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "You're in a good mood Chiron"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Am I? Why shouldn't I be? I certainly won't apologise for being so"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "It's not a problem, quite the opposite. It's nice to see you so excited."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Enough about me. I want to hear about your latest victory!"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I prevailed in my latest encounter with the mysterious foe."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "More evidence emerges attesting to your growing mastery."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "It's nice, but I still don't really get it Chiron"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "What do you mean?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I spent eons an afterthought of the cosmos"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "You are wondering what the source of your sudden power is?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Well… yes"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Over what realm do you have dominion?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Memory, as you well know"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "At the beginning of all things, there was, how do I put this? Very little to remember. Barely anything had happened after all."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Is it then not surprising that the steward of memory was, at that time, of little consequence?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "….."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Since Prometheus gifted divine fire to humans there has been more to know, more desire for memory."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "The ability to Randomly Access Memory has thus become more important than ever before"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "It's only natural it's presiding deity should rise in turn."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "My power derives from my usefulness? Relevance?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "There are many paths to power New, usefulness is but one of them."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "There's still something I don't understand"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Yes?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I came straight here to tell you about my latest victory, but somehow you already knew."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "You got me New. I had indeed been informed."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "Care to explain?"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "As your last expedition was with Artemis, naturally her silver sister Selene was watching. It is from her the news of your victory came."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "The good mood is suddenly starting to make more sense now"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Aphrodite be blessed! She not only messaged me, but did so first, unprompted."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "Unprompted, New."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "That's wonderful friend, surely a meeting is in your future"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "One can dare to dream. I better send you one your way New, else you will be stuck here watching me smile until the end of time."))
	first_artemis_boss_win_lines.append(DialogueLine.new("Mnemosyne", "I can feel the pull of Ananke and with your gift of mirth I'm ready to try again"))
	first_artemis_boss_win_lines.append(DialogueLine.new("Chiron", "I will be here when you need me."))


	# -------------------------------------------------------------------------
	# CUTSCENE 17 - First Demeter boss win (Mnemosyne and Chiron)
	# No dialogue written in script yet - placeholder
	# -------------------------------------------------------------------------
	var first_demeter_boss_win_lines: Array[DialogueLine] = []
	first_demeter_boss_win_lines.append(DialogueLine.new("Chiron", "..."))


	# -------------------------------------------------------------------------
	# CUTSCENE 18 - First Muninn vision (Mnemosyne and Odin)
	# -------------------------------------------------------------------------
	var first_muninn_vision_lines: Array[DialogueLine] = []
	first_muninn_vision_lines.append(DialogueLine.new("Odin", "O'er Mithgarth Hugin and Munin both each day set forth to fly; For Hugin I fear lest he come not home, but for Munin my care is more"))
	first_muninn_vision_lines.append(DialogueLine.new("Odin", "Grímnismál, stanza 20"))


	# -------------------------------------------------------------------------
	# CUTSCENE 19 - Second Muninn vision (Mnemosyne and Odin)
	# -------------------------------------------------------------------------
	var second_muninn_vision_lines: Array[DialogueLine] = []
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "No greater lord of deception exists beyond Loki, lie smith."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "He tests his plans with counter plans as naturally as you or I would breathe."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "For even as he plotted his escape in salmon form he was also creating the first net. Scheming, imagining, how a salmon could possibly be caught."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "Not one second later his thoughts had turned to how to avoid a net as a salmon, such is the depth of trickery at his disposal."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "Lost in machination he did not hear us approach till it was nearly too late."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "We arrived to see the hastily burnt invention in the hearth. Kvasir, the wise, was able to divine its meaning and the wolf's father was imprisoned."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "Loki's irresistible genius was the seat of his downfall."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "Now as he plans for Ragnarok. He is making the same mistake."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "He is forming plans within plans within counterplans."))
	second_muninn_vision_lines.append(DialogueLine.new("Odin", "But much like a net, oh blood brother, you are showing us the source of our salvation."))
	# -------------------------------------------------------------------------
	# CUTSCENE 20 - Third Muninn vision (Mnemosyne and Odin)
	# -------------------------------------------------------------------------
	var third_muninn_vision_lines: Array[DialogueLine] = []
	third_muninn_vision_lines.append(DialogueLine.new("Odin", "But straight thereafter shall Vidar stride forth and set one foot upon the lower jaw of the Wolf"))
	third_muninn_vision_lines.append(DialogueLine.new("Odin", "On that foot he has the shoe, materials for which have been gathering throughout all time. It is the waste pieces that people cut from their shoes at the toe and heel."))
	third_muninn_vision_lines.append(DialogueLine.new("Odin", "Therefore anyone that is concerned to give assistance to the Aesir must throw these pieces away."))
	third_muninn_vision_lines.append(DialogueLine.new("Odin", "With one hand he will grasp the Wolf's upper jaw and tear apart its mouth, and this will cause the Wolf's death"))
	third_muninn_vision_lines.append(DialogueLine.new("Odin", "Gylfaginning, Stanza 51, Of Ragnarokr"))
	# -------------------------------------------------------------------------
	# CUTSCENE 21 - Fourth Muninn vision (Mnemosyne and Odin)
	# -------------------------------------------------------------------------
	var fourth_muninn_vision_lines: Array[DialogueLine] = []
	fourth_muninn_vision_lines.append(DialogueLine.new("Odin", "Then shall come to pass these tidings also: all the earth shall tremble so, that trees shall be torn up from the earth, and the crags fall to ruin; and all fetters and bonds shall be broken and rent."))
	fourth_muninn_vision_lines.append(DialogueLine.new("Odin", "Gylfaginning, Stanza 51, Of Ragnarokr"))

	# =========================================================================
	# Register all cutscenes
	# =========================================================================

	# dialogue index 0
	var tutorial_cutscene = CutsceneData.new("tutorial_intro", [mnemosyne, chronos], tutorial_lines)
	cutscenes["tutorial_intro"] = tutorial_cutscene

	# dialogue index 1
	var opening_awakening_cutscene = CutsceneData.new("opening_awakening", [mnemosyne, chiron], opening_lines)
	cutscenes["opening_awakening"] = opening_awakening_cutscene

	# dialogue index 2
	var first_defeat_cutscene = CutsceneData.new("first_defeat_conversation", [mnemosyne, chiron], first_defeat_lines)
	cutscenes["first_defeat_conversation"] = first_defeat_cutscene

	# dialogue index 3
	var second_defeat_cutscene = CutsceneData.new("second_defeat_conversation", [mnemosyne, chiron], second_defeat_lines)
	cutscenes["second_defeat_conversation"] = second_defeat_cutscene

	# dialogue index 4
	var third_defeat_cutscene = CutsceneData.new("third_defeat_conversation", [mnemosyne, chiron], third_defeat_lines)
	cutscenes["third_defeat_conversation"] = third_defeat_cutscene

	# dialogue index 5
	var first_apollo_boss_win_cutscene = CutsceneData.new("first_apollo_boss_win_conversation", [mnemosyne, chiron], first_apollo_boss_win_lines)
	cutscenes["first_apollo_boss_win_conversation"] = first_apollo_boss_win_cutscene

	# dialogue index 6
	var second_apollo_boss_win_cutscene = CutsceneData.new("second_apollo_boss_win_conversation", [mnemosyne, chiron], second_apollo_boss_win_lines)
	cutscenes["second_apollo_boss_win_conversation"] = second_apollo_boss_win_cutscene

	# dialogue index 7
	var first_apollo_boss_loss_cutscene = CutsceneData.new("first_apollo_boss_loss_conversation", [mnemosyne, chiron], first_apollo_boss_loss_lines)
	cutscenes["first_apollo_boss_loss_conversation"] = first_apollo_boss_loss_cutscene

	# dialogue index 8
	var second_apollo_boss_loss_cutscene = CutsceneData.new("second_apollo_boss_loss_conversation", [mnemosyne, chiron], second_apollo_boss_loss_lines)
	cutscenes["second_apollo_boss_loss_conversation"] = second_apollo_boss_loss_cutscene

	# dialogue index 9
	var first_hermes_boss_loss_cutscene = CutsceneData.new("first_hermes_boss_loss_conversation", [mnemosyne, chiron], first_hermes_boss_loss_lines)
	cutscenes["first_hermes_boss_loss_conversation"] = first_hermes_boss_loss_cutscene

	# dialogue index 10
	var second_hermes_boss_loss_cutscene = CutsceneData.new("second_hermes_boss_loss_conversation", [mnemosyne, chiron], second_hermes_boss_loss_lines)
	cutscenes["second_hermes_boss_loss_conversation"] = second_hermes_boss_loss_cutscene

	# dialogue index 11
	var first_artemis_boss_loss_cutscene = CutsceneData.new("first_artemis_boss_loss_conversation", [mnemosyne, chiron], first_artemis_boss_loss_lines)
	cutscenes["first_artemis_boss_loss_conversation"] = first_artemis_boss_loss_cutscene

	# dialogue index 12
	var second_artemis_boss_loss_cutscene = CutsceneData.new("second_artemis_boss_loss_conversation", [mnemosyne, chiron], second_artemis_boss_loss_lines)
	cutscenes["second_artemis_boss_loss_conversation"] = second_artemis_boss_loss_cutscene

	# dialogue index 13
	var first_demeter_defeat = CutsceneData.new("first_demeter_defeat_conversation", [mnemosyne, chiron], first_demeter_defeat_lines)
	cutscenes["first_demeter_defeat_conversation"] = first_demeter_defeat
	
	# dialogue index 14
	var post_chronos_victory_cutscene = CutsceneData.new("post_chronos_victory", [mnemosyne, odin], post_chronos_victory_lines)
	cutscenes["post_chronos_victory"] = post_chronos_victory_cutscene

	# dialogue index 15
	var first_hermes_boss_win_cutscene = CutsceneData.new("first_hermes_boss_win_conversation", [mnemosyne, chiron], first_hermes_boss_win_lines)
	cutscenes["first_hermes_boss_win_conversation"] = first_hermes_boss_win_cutscene

	# dialogue index 16
	var first_artemis_boss_win_cutscene = CutsceneData.new("first_artemis_boss_win_conversation", [mnemosyne, chiron], first_artemis_boss_win_lines)
	cutscenes["first_artemis_boss_win_conversation"] = first_artemis_boss_win_cutscene

	# dialogue index 17
	var first_demeter_boss_win_cutscene = CutsceneData.new("first_demeter_boss_win_conversation", [mnemosyne, chiron], first_demeter_boss_win_lines)
	cutscenes["first_demeter_boss_win_conversation"] = first_demeter_boss_win_cutscene

	# dialogue index 18
	var first_muninn_vision_cutscene = CutsceneData.new("first_muninn_vision", [mnemosyne, odin], first_muninn_vision_lines)
	cutscenes["first_muninn_vision"] = first_muninn_vision_cutscene

	# dialogue index 19
	var second_muninn_vision_cutscene = CutsceneData.new("second_muninn_vision", [mnemosyne, odin], second_muninn_vision_lines)
	cutscenes["second_muninn_vision"] = second_muninn_vision_cutscene

	# dialogue index 20
	var third_muninn_vision_cutscene = CutsceneData.new("third_muninn_vision", [mnemosyne, odin], third_muninn_vision_lines)
	cutscenes["third_muninn_vision"] = third_muninn_vision_cutscene

	# dialogue index 21
	var fourth_muninn_vision_cutscene = CutsceneData.new("fourth_muninn_vision", [mnemosyne, odin], fourth_muninn_vision_lines)
	cutscenes["fourth_muninn_vision"] = fourth_muninn_vision_cutscene


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
	
	if not cutscene_id in viewed_cutscenes:
		viewed_cutscenes.append(cutscene_id)
		save_viewed_cutscenes()
	
	# Set cutscene data for the cutscene scene
	get_tree().set_meta("cutscene_data", cutscenes[cutscene_id])
	
	print("Playing cutscene: ", cutscene_id)
	
	# Switch to cutscene scene
	TransitionManagerAutoload.change_scene_to("res://Scenes/Cutscene.tscn")

func return_to_previous_scene():
	# If replaying from journal, skip all special handling and return to source scene
	if replay_from_journal:
		replay_from_journal = false
		get_tree().set_meta("reopen_memory_journal", "remember")
		if return_scene_path != "":
			if not return_scene_params.is_empty():
				get_tree().set_meta("scene_params", return_scene_params)
			print("Returning from journal replay to: ", return_scene_path)
			TransitionManagerAutoload.change_scene_to(return_scene_path)
			return_scene_path = ""
			return_scene_params.clear()
		else:
			TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")
		return

	# Normal flow special handling
	var last_played = viewed_cutscenes[-1] if viewed_cutscenes.size() > 0 else ""

	if last_played == "tutorial_intro":
		print("Completed tutorial intro cutscene, starting tutorial battle")
		get_tree().set_meta("scene_params", {
			"is_tutorial": true,
			"god": "Mnemosyne",
			"deck_index": 0,
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
		if not return_scene_params.is_empty():
			get_tree().set_meta("scene_params", return_scene_params)
		print("Returning to: ", return_scene_path)
		TransitionManagerAutoload.change_scene_to(return_scene_path)
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


func save_viewed_cutscenes():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(viewed_cutscenes)
		save_file.close()
		print("Viewed cutscenes saved")
	else:
		print("Failed to save viewed cutscenes!")

func load_viewed_cutscenes():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			viewed_cutscenes = save_file.get_var()
			save_file.close()
			print("Viewed cutscenes loaded: ", viewed_cutscenes)
		else:
			print("Failed to load viewed cutscenes!")

func clear_viewed_cutscenes():
	viewed_cutscenes.clear()
	save_viewed_cutscenes()
	print("Viewed cutscenes cleared")
