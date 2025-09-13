# res://Resources/Abilities/enrich_ability.gd
class_name EnrichAbility
extends CardAbility

func _init():
	ability_name = "Enrich"
	description = "On play, choose a slot. For the remainder of the run this slot will boost the stats of friendly cards by 1"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("EnrichAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("EnrichAbility: Missing required context data")
		return false
	
	# Get the owner of the enriching card (should be player only)
	var enricher_owner = game_manager.get_owner_at_position(grid_position)
	if enricher_owner != game_manager.Owner.PLAYER:
		print("EnrichAbility: Only player cards can use Enrich")
		return false
	
	# Check for Seasons power and modify enrichment accordingly
	var enrichment_amount = 1  # Default enrichment
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				enrichment_amount = 2  # Double enrichment in Summer
				print("EnrichAbility: Summer season - doubling enrichment to +2")
			game_manager.Season.WINTER:
				enrichment_amount = -1  # Negative enrichment in Winter
				print("EnrichAbility: Winter season - negative enrichment to -1")
	
	print("EnrichAbility activated! ", placed_card.card_name, " can now enrich a target slot with ", enrichment_amount, " enhancement")
	
	# Enable enrich mode in the game manager
	game_manager.start_enrich_mode(grid_position, enricher_owner, placed_card, enrichment_amount)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
