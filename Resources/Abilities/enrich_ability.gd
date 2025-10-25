# res://Resources/Abilities/enrich_ability.gd
class_name EnrichAbility
extends CardAbility

func _init():
	ability_name = "Enrich"
	description = "On play, choose a slot. For the remainder of the run this slot will boost the stats of friendly cards by 1"
	trigger_condition = TriggerType.ON_PLAY

# Static helper function to get level-scaled enrichment amount
static func get_enrichment_for_level(card_level: int) -> int:
	# Every level: card_level
	# Level 1: +1, Level 2: +2, Level 3: +3, etc.
	return card_level

# Static helper function to get dynamic description based on level
static func get_description_for_level(card_level: int) -> String:
	var enrichment_amount = get_enrichment_for_level(card_level)
	return "On play, choose a slot. For the remainder of the run this slot will boost the stats of friendly cards by " + str(enrichment_amount)

# Static helper function to get base stat scaling for cards with Enrich ability
# This gives permanent stat increases based on card level (separate from enrichment bonus)
static func get_stat_bonus_for_level(card_level: int) -> int:
	# Every 4 levels (slowest scaling - Enrich is easiest to stack)
	# Levels 1-4: +0, Levels 5-8: +1, Levels 9-12: +2, etc.
	return int(floor(float(card_level - 1) / 2.0))

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	var card_level = context.get("card_level", 1)
	
	print("EnrichAbility: Starting execution for card at position ", grid_position, " (Level ", card_level, ")")
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("EnrichAbility: Missing required context data")
		return false
	
	var enricher_owner = game_manager.get_owner_at_position(grid_position)
	if enricher_owner != game_manager.Owner.PLAYER:
		print("EnrichAbility: Only player cards can use Enrich")
		return false
	
	# Calculate level-scaled enrichment amount
	var enrichment_amount = get_enrichment_for_level(card_level)
	
	# Check for Seasons power
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				enrichment_amount *= 2
				print("EnrichAbility: Summer season - doubling enrichment to +", enrichment_amount)
			game_manager.Season.WINTER:
				enrichment_amount = -enrichment_amount
				print("EnrichAbility: Winter season - negative enrichment to ", enrichment_amount)
	
	print("EnrichAbility activated! ", placed_card.card_name, " can now enrich a target slot with ", enrichment_amount, " enhancement")
	
	game_manager.start_enrich_mode(grid_position, enricher_owner, placed_card, enrichment_amount)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
