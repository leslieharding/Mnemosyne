# res://Resources/Abilities/wealth_ability.gd
class_name WealthAbility
extends CardAbility

func _init():
	ability_name = "Wealth"
	description = "On play this card grants ALL of your cards exp."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("WealthAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("WealthAbility: Missing required context data")
		return false
	
	# Get the exp tracker
	var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
	if not exp_tracker:
		print("WealthAbility: RunExperienceTrackerAutoload not found!")
		return false
	
	# Get the global progress tracker to access all unlocked cards
	var progress_tracker = game_manager.get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not progress_tracker:
		print("WealthAbility: GlobalProgressTrackerAutoload not found!")
		return false
	
	var exp_amount = 10
	var cards_granted_exp = 0
	
	# Get all unlocked gods
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	print("WealthAbility: Granting ", exp_amount, " exp to all cards in unlocked gods: ", unlocked_gods)
	
	# Iterate through all unlocked gods and their cards
	for god_name in unlocked_gods:
		# Load the god's collection
		var collection_path = "res://Resources/Collections/" + god_name + ".tres"
		var god_collection: GodCardCollection = load(collection_path)
		
		if not god_collection:
			print("WealthAbility: Could not load collection for ", god_name)
			continue
		
		# Get progress for this god
		var god_progress = progress_tracker.get_god_progress(god_name)
		
		# Grant exp to each card in this god's collection
		for card_index in range(god_collection.cards.size()):
			# Initialize card in progress tracker if it doesn't exist
			if not card_index in god_progress:
				god_progress[card_index] = {"total_exp": 0}
			
			# Add exp directly to the global progress tracker
			god_progress[card_index]["total_exp"] += exp_amount
			cards_granted_exp += 1
			
			print("WealthAbility: Granted ", exp_amount, " exp to ", god_name, " card ", card_index, " (", god_collection.cards[card_index].card_name, ")")
	
	# Save the updated progress
	progress_tracker.save_progress()
	
	print("WealthAbility: Successfully granted ", exp_amount, " exp to ", cards_granted_exp, " total cards across all unlocked gods!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
