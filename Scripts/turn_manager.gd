# res://Scripts/turn_manager.gd
extends Node
class_name TurnManager

signal turn_changed(is_player_turn: bool)
signal game_started()
signal coin_flip_result(player_goes_first: bool)

enum Player {
	HUMAN,
	OPPONENT
}

var current_player: Player
var is_game_active: bool = false

func _ready():
	pass

# Start the game with a coin flip
func start_game():
	is_game_active = false
	perform_coin_flip()

func debug_state():
	print("=== TURN MANAGER DEBUG ===")
	print("is_game_active: ", is_game_active)
	print("current_player: ", current_player)
	print("Player.HUMAN: ", Player.HUMAN)
	print("Player.OPPONENT: ", Player.OPPONENT)
	print("is_player_turn(): ", is_player_turn())
	print("is_opponent_turn(): ", is_opponent_turn())
	print("==========================")


# Simulate coin flip to determine who goes first
func perform_coin_flip():
	# Add a small delay for dramatic effect
	await get_tree().create_timer(1.0).timeout
	
	# 50/50 chance
	var player_goes_first = randf() < 0.5
	
	# Set starting player
	if player_goes_first:
		current_player = Player.HUMAN
		print("Coin flip result: Player goes first!")
	else:
		current_player = Player.OPPONENT
		print("Coin flip result: Opponent goes first!")
	
	# Emit the result
	emit_signal("coin_flip_result", player_goes_first)
	
	# Start the actual game
	is_game_active = true
	emit_signal("game_started")
	emit_signal("turn_changed", current_player == Player.HUMAN)

# Switch to the next player's turn
func next_turn():
	if not is_game_active:
		return
		
	# Switch players
	if current_player == Player.HUMAN:
		current_player = Player.OPPONENT
	else:
		current_player = Player.HUMAN
	
	print("Turn switched to: ", "Player" if current_player == Player.HUMAN else "Opponent")
	emit_signal("turn_changed", current_player == Player.HUMAN)

# Check if it's the player's turn
func is_player_turn() -> bool:
	var result = is_game_active and current_player == Player.HUMAN
	if not result:
		print("is_player_turn() = false because: is_game_active=", is_game_active, " current_player=", current_player, " Player.HUMAN=", Player.HUMAN)
	return result

# Check if it's the opponent's turn
func is_opponent_turn() -> bool:
	return is_game_active and current_player == Player.OPPONENT

# End the game
func end_game():
	is_game_active = false
	print("Game ended")
