# res://Resources/Abilities/bolster_confidence_ability.gd
class_name BolsterConfidenceAbility
extends CardAbility

func _init():
	ability_name = "Bolster Confidence"
	description = "When this card captures a player's card it increases the stats of wavering family members by 1."
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	print("=== BOLSTER CONFIDENCE ABILITY TRIGGERED ===")
	
	# Get the card that just made a capture (this aggressive family member)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var game_manager = context.get("game_manager")
	
	print("BolsterConfidenceAbility: Starting execution for capturing card at position ", capturing_position)
	print("Capturing card name: ", capturing_card.card_name if capturing_card else "NULL")
	print("Captured card name: ", captured_card.card_name if captured_card else "NULL")
	
	# Safety checks
	if not capturing_card:
		print("BolsterConfidenceAbility: No capturing card provided")
		return false
	
	if capturing_position == -1:
		print("BolsterConfidenceAbility: Invalid capturing position")
		return false
	
	if not captured_card:
		print("BolsterConfidenceAbility: No captured card provided")
		return false
	
	if not game_manager:
		print("BolsterConfidenceAbility: No game manager provided")
		return false
	
	# Check if this capture was made by an aggressive family member from an enemy-controlled position
	var capturing_owner = game_manager.get_owner_at_position(capturing_position)
	if capturing_owner != game_manager.Owner.OPPONENT:
		print("BolsterConfidenceAbility: Capturing card not owned by opponent - no bolster effect")
		return false
	
	# Verify this was a player card that got captured (not a recapture of family member)
	# We check this by looking at what the captured card was originally
	# For this, we assume if it's not a family member name, it was a player card
	var family_member_names = ["Alphenor", "Cleodoxa", "Astyoche", "Sipylus", "Damasichthon"]
	var was_player_card = not (captured_card.card_name in family_member_names)
	
	print("BolsterConfidenceAbility: Was captured card a player card? ", was_player_card)
	
	if not was_player_card:
		print("BolsterConfidenceAbility: Captured card was not a player card - no bolster effect")
		return false
	
	# Define the wavering family members (those with Infighting ability)
	var wavering_family_members = ["Cleodoxa", "Damasichthon"]
	
	# Find all wavering family members on the board that are still enemy-controlled
	var bolstered_cards = []
	
	for position in range(game_manager.grid_slots.size()):
		if not game_manager.grid_occupied[position]:
			continue  # Empty slot
		
		var card_owner = game_manager.get_owner_at_position(position)
		if card_owner != game_manager.Owner.OPPONENT:
			continue  # Not enemy-controlled
		
		var board_card = game_manager.get_card_at_position(position)
		if not board_card:
			continue  # No card data
		
		# Check if this is a wavering family member
		if board_card.card_name in wavering_family_members:
			print("BolsterConfidenceAbility: Found wavering family member ", board_card.card_name, " at position ", position, " - bolstering confidence!")
			bolstered_cards.append({"position": position, "card": board_card})
	
	# Apply +1 boost to all stats of wavering family members
	var bolster_count = 0
	for bolster_data in bolstered_cards:
		var position = bolster_data.position
		var card = bolster_data.card
		
		print("BolsterConfidenceAbility: Bolstering ", card.card_name, " at position ", position)
		
		# Apply +1 to all stats
		card.values[0] += 1  # North
		card.values[1] += 1  # East
		card.values[2] += 1  # South
		card.values[3] += 1  # West
		
		print("BolsterConfidenceAbility: ", card.card_name, " stats boosted to: ", card.values)
		
		# FIXED: Update the visual display to show the new stats
		var slot = game_manager.grid_slots[position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = card  # Update the card data reference
				child.update_display()  # Refresh the visual display
				print("BolsterConfidenceAbility: Updated CardDisplay visual for bolstered card at position ", position)
				break
		
		bolster_count += 1
	
	if bolster_count > 0:
		print(ability_name, " activated! ", capturing_card.card_name, "'s success bolstered ", bolster_count, " wavering family members!")
		return true
	else:
		print(ability_name, " had no effect - no wavering family members found on opponent's side")
		return false

func can_execute(context: Dictionary) -> bool:
	return true
