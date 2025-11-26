# res://Resources/Abilities/sun_bather_ability.gd
class_name SunBatherAbility
extends CardAbility

func _init():
	ability_name = "Sun Bather"
	description = "When placed on a sunlit spot, gains an additional +1 to all stats (total +2 from sun)"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SunBatherAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SunBatherAbility: Missing required context data")
		return false
	
	# Check if this position is sunlit and sun power is active
	if game_manager.active_deck_power != DeckDefinition.DeckPowerType.SUN_POWER:
		print("SunBatherAbility: No sun power active")
		return false
	
	# Check for darkness shroud (which would negate sun effects)
	if game_manager.darkness_shroud_active:
		print("SunBatherAbility: Darkness shroud blocks sun bathing")
		return false
	
	# Check if this position is sunlit
	if not grid_position in game_manager.sunlit_positions:
		print("SunBatherAbility: Position not sunlit")
		return false
	
	# Apply additional +1 boost (on top of the regular sun boost)
	print("☀️ SUN BATHER ACTIVATED! Additional +1 boost to all stats")
	
	placed_card.values[0] += 1  # North
	placed_card.values[1] += 1  # East
	placed_card.values[2] += 1  # South
	placed_card.values[3] += 1  # West
	
	print("Sun Bather boosted card stats to: ", placed_card.values)
	
	# FIXED: Update the visual display to show the new stats
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card  # Update the card data reference
			child.update_display()         # Refresh the visual display
			print("SunBatherAbility: Updated CardDisplay visual for sun-bathing card")
			break
	# Play sun bather sound effect
	SoundManagerAutoload.play("sun_bather")
	return true
	
	
	
func can_execute(context: Dictionary) -> bool:
	return true
