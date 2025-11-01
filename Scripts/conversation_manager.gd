# res://Scripts/conversation_manager.gd
extends Node
class_name ConversationManager

signal new_conversation_available(conversation_id: String, priority: String)

# Conversation priorities
enum Priority {
	STORY,
	MILESTONE
}

# Conversation data structure
var conversations: Dictionary = {}
var save_path: String = "user://conversations.save"

var defeat_count: int = 0

func _ready():
	load_conversations()
	setup_conversation_definitions()

# Set up all possible conversations
func setup_conversation_definitions():
	# Existing defeat conversations
	register_conversation("first_run_defeat", Priority.STORY,
		"Chiron offers wisdom about the nature of progress and victory.")
	
	register_conversation("second_run_defeat", Priority.STORY,
		"A tale of eastern dragons and the path from weakness to strength.")
	
	# Boss victory conversations
	register_conversation("first_apollo_boss_win", Priority.STORY,
		"Victory over Apollo with your own divine power.")
	
	register_conversation("second_apollo_boss_win", Priority.STORY,
		"Mastery of Apollo through varied approaches.")
	
	# Apollo boss loss conversations
	register_conversation("first_apollo_boss_loss", Priority.STORY,
		"The first encounter with a mysterious predictive foe.")
	
	register_conversation("second_apollo_boss_loss", Priority.STORY,
		"Understanding the enemy who watches and predicts.")
	
	# Hermes boss loss conversations
	register_conversation("first_hermes_boss_loss", Priority.STORY,
		"Facing an illusory and deceptive opponent.")
	
	register_conversation("second_hermes_boss_loss", Priority.STORY,
		"Unveiling the truth behind the deception.")
	
	# Artemis boss loss conversations
	register_conversation("first_artemis_boss_loss", Priority.STORY,
		"The hunter who stalks from the shadows.")
	
	register_conversation("second_artemis_boss_loss", Priority.STORY,
		"Learning to counter the patient huntress.")
	
	# Demeter specific defeat
	register_conversation("first_demeter_defeat", Priority.STORY,
		"Patience and growth in the face of setback.")
	
	
	
	

# Register a conversation definition
func register_conversation(id: String, priority: Priority, description: String):
	if not id in conversations:
		conversations[id] = {
			"priority": priority,
			"description": description,
			"triggered": false,
			"shown": false
		}

# Get conversation button state for UI
func get_conversation_button_state() -> Dictionary:
	var next_conv = get_next_conversation()
	if next_conv.is_empty():
		return {"available": false, "priority": "", "text": "Visit Chiron"}
	
	var is_story = next_conv["data"]["priority"] == Priority.STORY
	return {
		"available": true,
		"priority": "STORY" if is_story else "MILESTONE",
		"text": "Visit Chiron"
	}

func increment_defeat_count():
	defeat_count += 1
	print("Defeat count incremented to: ", defeat_count)
	
	# Trigger appropriate conversation based on defeat count
	if defeat_count == 1:
		print("Triggering first_run_defeat conversation")
		trigger_conversation("first_run_defeat")
	elif defeat_count == 2:
		print("Triggering second_run_defeat conversation")
		trigger_conversation("second_run_defeat")

# Trigger a conversation to become available
func trigger_conversation(conversation_id: String):
	if not conversation_id in conversations:
		print("Warning: Unknown conversation ID: ", conversation_id)
		return
	
	var conv = conversations[conversation_id]
	if conv["triggered"] or conv["shown"]:
		print("Conversation ", conversation_id, " already triggered/shown, skipping")
		return  # Already triggered/shown
	
	conv["triggered"] = true
	save_conversations()
	
	var priority_name = "STORY" if conv["priority"] == Priority.STORY else "MILESTONE"
	emit_signal("new_conversation_available", conversation_id, priority_name)
	
	print("Conversation triggered: ", conversation_id, " (", priority_name, ")")

# Get the next conversation to show (if any)
func get_next_conversation() -> Dictionary:
	# First check for story conversations
	var story_conversations = get_available_conversations_by_priority(Priority.STORY)
	if story_conversations.size() > 0:
		# Return the first story conversation
		return {"id": story_conversations[0], "data": conversations[story_conversations[0]]}
	
	# Then check for milestone conversations
	var milestone_conversations = get_available_conversations_by_priority(Priority.MILESTONE)
	if milestone_conversations.size() > 0:
		# Return a random milestone conversation
		var random_index = randi() % milestone_conversations.size()
		var conv_id = milestone_conversations[random_index]
		return {"id": conv_id, "data": conversations[conv_id]}
	
	# No conversations available
	return {}

# Get available conversations by priority
func get_available_conversations_by_priority(priority: Priority) -> Array[String]:
	var available: Array[String] = []
	for conv_id in conversations:
		var conv = conversations[conv_id]
		if conv["priority"] == priority and conv["triggered"] and not conv["shown"]:
			available.append(conv_id)
	return available

# Mark a conversation as shown
func mark_conversation_shown(conversation_id: String):
	if conversation_id in conversations:
		conversations[conversation_id]["shown"] = true
		save_conversations()
		print("Conversation marked as shown: ", conversation_id)

# Check if any conversations are available
func has_available_conversations() -> bool:
	return get_next_conversation().size() > 0

func save_conversations():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"conversations": conversations,
			"defeat_count": defeat_count
		}
		save_file.store_var(save_data)
		save_file.close()

func load_conversations():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded_data = save_file.get_var()
			if loaded_data is Dictionary:
				if loaded_data.has("conversations"):
					conversations = loaded_data.get("conversations", {})
					defeat_count = loaded_data.get("defeat_count", 0)
				else:
					conversations = loaded_data
					defeat_count = 0

func clear_all_conversations():
	conversations.clear()
	defeat_count = 0  # FIXED: Reset defeat count
	setup_conversation_definitions()  # Recreate the base definitions
	save_conversations()
	print("All conversations cleared - defeat_count reset to 0")

# Debug function
func debug_conversations():
	print("=== CONVERSATION DEBUG ===")
	for conv_id in conversations:
		var conv = conversations[conv_id]
		var priority_name = "STORY" if conv["priority"] == Priority.STORY else "MILESTONE"
		print(conv_id, " - ", priority_name, " - Triggered: ", conv["triggered"], " - Shown: ", conv["shown"])
	print("Has available: ", has_available_conversations())
	print("==========================")
