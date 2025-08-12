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

var conversation_shown_this_run: bool = false
var current_run_id: String = ""

func _ready():
	load_conversations()
	setup_conversation_definitions()

# Set up all possible conversations
func setup_conversation_definitions():
	# Story conversations
	register_conversation("first_boss_loss", Priority.STORY, 
		"The weight of defeat teaches us more than the lightness of victory.")
	
	register_conversation("consciousness_breakthrough", Priority.STORY,
		"I sense Mnemosyne's awareness expanding beyond mortal comprehension.")
	
	# Milestone conversations  
	register_conversation("first_deck_unlock", Priority.MILESTONE,
		"You've proven yourself worthy of greater challenges.")
	
	register_conversation("apollo_mastery", Priority.MILESTONE,
		"The sun god's power flows through you with increasing ease.")
	
	register_conversation("first_enemy_mastered", Priority.MILESTONE,
		"Understanding your opponents is the path to true victory.")
	
	register_conversation("first_run_defeat", Priority.STORY,
	"Chiron offers wisdom about the nature of progress and victory.")
		
	register_conversation("hermes_unlocked", Priority.STORY, 
	"The messenger god takes notice of your growing prowess. Swift feet follow swift minds.")	

# Register a conversation definition
func register_conversation(id: String, priority: Priority, description: String):
	if not id in conversations:
		conversations[id] = {
			"priority": priority,
			"description": description,
			"triggered": false,
			"shown": false
		}

# Start a new run - reset the conversation flag
func start_new_run():
	conversation_shown_this_run = false
	current_run_id = str(Time.get_unix_time_from_system())  # Generate unique run ID
	print("ConversationManager: Started new run - conversations enabled")

# Mark that a conversation has been shown this run
func set_conversation_shown_this_run():
	conversation_shown_this_run = true
	print("ConversationManager: Conversation shown this run - further conversations disabled")

# Check if we can show conversations this run
func can_show_conversation_this_run() -> bool:
	return not conversation_shown_this_run

# Update the existing get_conversation_button_state() function in Scripts/conversation_manager.gd
# Replace the entire function (around lines 95-105):

func get_conversation_button_state() -> Dictionary:
	# Check if we've already shown a conversation this run
	if conversation_shown_this_run:
		return {"available": false, "priority": "", "text": "Visit Chiron"}
	
	var next_conv = get_next_conversation()
	if next_conv.is_empty():
		return {"available": false, "priority": "", "text": "Visit Chiron"}
	
	var is_story = next_conv["data"]["priority"] == Priority.STORY
	return {
		"available": true,
		"priority": "STORY" if is_story else "MILESTONE",
		"text": "Visit Chiron" if is_story else "Visit Chiron"
	}



# Trigger a conversation to become available
func trigger_conversation(conversation_id: String):
	if not conversation_id in conversations:
		print("Warning: Unknown conversation ID: ", conversation_id)
		return
	
	var conv = conversations[conversation_id]
	if conv["triggered"] or conv["shown"]:
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
		# Return the first story conversation (you could add more logic here)
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


# Save conversations to disk
func save_conversations():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(conversations)
		save_file.close()
	else:
		print("Failed to save conversations!")

# Load conversations from disk
func load_conversations():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded_data = save_file.get_var()
			if loaded_data is Dictionary:
				conversations = loaded_data
			save_file.close()
			print("Conversations loaded")
		else:
			print("Failed to load conversations!")
	else:
		print("No conversation save found, starting fresh")

# Clear all conversation data (for new game)
func clear_all_conversations():
	conversations.clear()
	setup_conversation_definitions()  # Recreate the base definitions
	save_conversations()
	print("All conversations cleared")

# Debug function
func debug_conversations():
	print("=== CONVERSATION DEBUG ===")
	for conv_id in conversations:
		var conv = conversations[conv_id]
		var priority_name = "STORY" if conv["priority"] == Priority.STORY else "MILESTONE"
		print(conv_id, " - ", priority_name, " - Triggered: ", conv["triggered"], " - Shown: ", conv["shown"])
	print("Has available: ", has_available_conversations())
	print("==========================")
