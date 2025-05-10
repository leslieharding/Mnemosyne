extends Node2D

# Reference to the Apollo card collection
var apollo_collection: GodCardCollection
var selected_deck_index: int = -1  # -1 means no deck selected

func _ready():
	# Load the Apollo card collection
	apollo_collection = load("res://Resources/Collections/apollo.tres")
	
	# Update the deck button labels with actual deck names
	if apollo_collection:
		$VBoxContainer/Deck1Button.text = apollo_collection.decks[0].deck_name
		$VBoxContainer/Deck2Button.text = apollo_collection.decks[1].deck_name
		$VBoxContainer/Deck3Button.text = apollo_collection.decks[2].deck_name
	
	# The StartGameButton should start disabled until a deck is selected
	$VBoxContainer/StartGameButton.disabled = true

# Back button
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Connect these in the editor or use the existing connections
func _on_deck_1_button_pressed() -> void:
	select_deck(0)


func _on_deck_2_button_pressed() -> void:
	select_deck(1)


func _on_deck_3_button_pressed() -> void:
	select_deck(2)
	
func _on_start_game_button_pressed() -> void:
	if selected_deck_index >= 0:
		# Pass the selected deck index to the game scene
		get_tree().set_meta("scene_params", {
			"deck_index": selected_deck_index
		})
		
		# Change to the game scene
		get_tree().change_scene_to_file("res://Scenes/ApolloGame.tscn")
	
# Helper function to handle deck selection
func select_deck(index: int) -> void:
	selected_deck_index = index
	
	# Reset all buttons to normal appearance
	$VBoxContainer/Deck1Button.disabled = false
	$VBoxContainer/Deck2Button.disabled = false
	$VBoxContainer/Deck3Button.disabled = false
	
	# Disable the selected button to show which is selected
	match index:
		0: $VBoxContainer/Deck1Button.disabled = true
		1: $VBoxContainer/Deck2Button.disabled = true
		2: $VBoxContainer/Deck3Button.disabled = true
	
	# Enable the start button now that a deck is selected
	$VBoxContainer/StartGameButton.disabled = false
	
	# Optionally, you could display the deck description somewhere
	print("Selected deck: ", apollo_collection.decks[index].deck_name)
	print("Description: ", apollo_collection.decks[index].deck_description)
