# res://Scripts/run_stat_growth_tracker.gd
extends Node
class_name RunStatGrowthTracker

signal stat_growth_applied(card_index: int, growth_amount: int)

# Track stat growth during current run
# Structure: {card_index: growth_amount}
var run_stat_growth: Dictionary = {}

# Track which cards are in the current deck (by their collection index)
var current_deck_indices: Array[int] = []

func _ready():
	# This will be an autoload singleton
	pass

# Initialize for a new run with the deck's card indices
func start_new_run(deck_indices: Array[int]):
	run_stat_growth.clear()
	current_deck_indices = deck_indices
	
	# Initialize all cards in deck with 0 growth
	for index in deck_indices:
		run_stat_growth[index] = 0
	
	print("RunStatGrowthTracker: Started new run with cards: ", deck_indices)

# Add stat growth for a card (called when Grow ability activates)
func add_stat_growth(card_index: int, growth_amount: int):
	if not card_index in run_stat_growth:
		print("RunStatGrowthTracker: Warning - Card index ", card_index, " not in current run!")
		# Initialize if missing (defensive programming)
		run_stat_growth[card_index] = 0
	
	run_stat_growth[card_index] += growth_amount
	emit_signal("stat_growth_applied", card_index, growth_amount)
	print("RunStatGrowthTracker: Card ", card_index, " gained +", growth_amount, " stat growth. Total growth: +", run_stat_growth[card_index])

# Get current stat growth for a specific card
func get_card_stat_growth(card_index: int) -> int:
	if card_index in run_stat_growth:
		return run_stat_growth[card_index]
	return 0

# Check if a card has any stat growth
func has_stat_growth(card_index: int) -> bool:
	return get_card_stat_growth(card_index) > 0

# Get all cards with stat growth
func get_cards_with_growth() -> Dictionary:
	var cards_with_growth = {}
	for card_index in run_stat_growth:
		if run_stat_growth[card_index] > 0:
			cards_with_growth[card_index] = run_stat_growth[card_index]
	return cards_with_growth

# Apply stat growth to a card's values (helper function)
func apply_growth_to_card_values(base_values: Array[int], card_index: int) -> Array[int]:
	var growth = get_card_stat_growth(card_index)
	if growth <= 0:
		return base_values.duplicate()
	
	var grown_values = base_values.duplicate()
	for i in range(grown_values.size()):
		grown_values[i] += growth
	
	return grown_values

# Get total stat growth gained this run across all cards
func get_total_stat_growth() -> int:
	var total = 0
	for growth in run_stat_growth.values():
		total += growth
	return total

# Clear run data (call when run ends or is abandoned)
func clear_run():
	run_stat_growth.clear()
	current_deck_indices.clear()
	print("RunStatGrowthTracker: Cleared run data")
