# res://Scripts/boss_prediction_tracker.gd
extends Node
class_name BossPredictionTracker

signal pattern_recorded(turn_number: int, card_index: int, grid_position: int)

# Track card play patterns when player goes first
# Structure: {"turn_1": [(card_index, grid_position), ...], "turn_2": [...], ...}
var play_patterns: Dictionary = {}

# Track if we're currently recording (only when player goes first)
var is_recording: bool = false
var current_turn_number: int = 0

func _ready():
	# Initialize pattern storage for all 5 turns
	for i in range(1, 6):
		play_patterns["turn_" + str(i)] = []

# Start recording a new battle (call when player wins coin flip)
func start_recording_battle():
	is_recording = true
	current_turn_number = 0
	print("BossPredictionTracker: Started recording new battle")

# Stop recording (call when battle ends or player doesn't go first)
func stop_recording():
	is_recording = false
	current_turn_number = 0
	print("BossPredictionTracker: Stopped recording")

# Record a card play (call when player places a card)
func record_card_play(card_index: int, grid_position: int):
	if not is_recording:
		return
	
	current_turn_number += 1
	
	if current_turn_number > 5:
		print("BossPredictionTracker: Warning - turn number exceeded 5")
		return
	
	var turn_key = "turn_" + str(current_turn_number)
	var play_data = [card_index, grid_position]
	
	play_patterns[turn_key].append(play_data)
	
	print("BossPredictionTracker: Recorded turn ", current_turn_number, " - Card ", card_index, " at position ", grid_position)
	emit_signal("pattern_recorded", current_turn_number, card_index, grid_position)

# Get prediction for boss AI
func get_boss_prediction(turn_number: int, available_cards: Array[int], available_positions: Array[int]) -> Dictionary:
	if turn_number < 1 or turn_number > 5:
		return {"card": -1, "position": -1, "confidence": 0.0}
	
	var turn_key = "turn_" + str(turn_number)
	var turn_data = play_patterns.get(turn_key, [])
	
	if turn_data.is_empty():
		# No data available - random selection
		return {
			"card": available_cards[randi() % available_cards.size()] if available_cards.size() > 0 else -1,
			"position": available_positions[randi() % available_positions.size()] if available_positions.size() > 0 else -1,
			"confidence": 0.0
		}
	
	# Calculate card frequencies for this turn
	var predicted_card = get_most_likely_card(turn_data, available_cards)
	if predicted_card == -1:
		return {"card": -1, "position": -1, "confidence": 0.0}
	
	# Calculate position frequencies for the predicted card
	var predicted_position = get_most_likely_position(predicted_card, available_positions)
	if predicted_position == -1:
		return {"card": predicted_card, "position": -1, "confidence": 0.0}
	
	# Calculate confidence (percentage of times this combination appeared)
	var total_plays = turn_data.size()
	var matching_plays = 0
	for play in turn_data:
		if play[0] == predicted_card and play[1] == predicted_position:
			matching_plays += 1
	
	var confidence = float(matching_plays) / float(total_plays) if total_plays > 0 else 0.0
	
	print("BossPredictionTracker: Prediction for turn ", turn_number, " - Card ", predicted_card, " at position ", predicted_position, " (confidence: ", confidence, ")")
	
	return {
		"card": predicted_card,
		"position": predicted_position,
		"confidence": confidence
	}

# Find the most likely card for this turn from available cards
func get_most_likely_card(turn_data: Array, available_cards: Array[int]) -> int:
	var card_frequencies: Dictionary = {}
	
	# Count frequencies of available cards
	for play in turn_data:
		var card_index = play[0]
		if card_index in available_cards:
			if card_index in card_frequencies:
				card_frequencies[card_index] += 1
			else:
				card_frequencies[card_index] = 1
	
	if card_frequencies.is_empty():
		# No historical data for available cards - choose random
		return available_cards[randi() % available_cards.size()] if available_cards.size() > 0 else -1
	
	# Find card(s) with highest frequency
	var max_frequency = 0
	var most_frequent_cards: Array[int] = []
	
	for card_index in card_frequencies:
		var frequency = card_frequencies[card_index]
		if frequency > max_frequency:
			max_frequency = frequency
			most_frequent_cards = [card_index]
		elif frequency == max_frequency:
			most_frequent_cards.append(card_index)
	
	# If tie, choose randomly from most frequent
	return most_frequent_cards[randi() % most_frequent_cards.size()]

# Find the most likely position for a specific card from available positions
func get_most_likely_position(card_index: int, available_positions: Array[int]) -> int:
	var position_frequencies: Dictionary = {}
	
	# Look at all historical plays of this card across all turns
	for turn_key in play_patterns:
		var turn_data = play_patterns[turn_key]
		for play in turn_data:
			if play[0] == card_index:  # This card was played
				var position = play[1]
				if position in available_positions:
					if position in position_frequencies:
						position_frequencies[position] += 1
					else:
						position_frequencies[position] = 1
	
	if position_frequencies.is_empty():
		# No historical data for this card in available positions - choose random
		return available_positions[randi() % available_positions.size()] if available_positions.size() > 0 else -1
	
	# Find position(s) with highest frequency
	var max_frequency = 0
	var most_frequent_positions: Array[int] = []
	
	for position in position_frequencies:
		var frequency = position_frequencies[position]
		if frequency > max_frequency:
			max_frequency = frequency
			most_frequent_positions = [position]
		elif frequency == max_frequency:
			most_frequent_positions.append(position)
	
	# If tie, choose randomly from most frequent
	return most_frequent_positions[randi() % most_frequent_positions.size()]

# Get current pattern data (for debugging)
func get_pattern_data() -> Dictionary:
	return play_patterns.duplicate(true)

# Clear all pattern data (for new runs)
func clear_patterns():
	for i in range(1, 6):
		play_patterns["turn_" + str(i)] = []
	print("BossPredictionTracker: Cleared all pattern data")

# Get statistics for debugging
func get_statistics() -> Dictionary:
	var stats = {}
	for turn_key in play_patterns:
		stats[turn_key] = play_patterns[turn_key].size()
	return stats
