# res://Scripts/map_generator.gd
class_name MapGenerator
extends RefCounted

# Map generation settings - UPDATED for linear path
static var LAYER_COUNT: int = 6  # 5 unique enemies + 1 boss
static var NODES_PER_LAYER: Array[int] = [1, 1, 1, 1, 1, 1]  # Single path through all enemies
static var MAP_WIDTH: float = 800.0
static var MAP_HEIGHT: float = 600.0
static var LAYER_SPACING: float = MAP_HEIGHT / (LAYER_COUNT - 1)

# Generate a complete map
static func generate_map(god_name: String = "Apollo", deck_name: String = "") -> MapData:
	var map_data = MapData.new()
	map_data.total_layers = LAYER_COUNT
	map_data.layer_node_counts = NODES_PER_LAYER
	
	# PRE-ASSIGN ENEMIES TO TIERS
	var tier_enemy_assignments = assign_enemies_to_tiers(god_name, deck_name)
	print("Tier enemy assignments: ", tier_enemy_assignments)
	
	# Generate nodes for each layer
	var node_id_counter = 0
	var nodes_by_layer: Array = []
	
	for layer in range(LAYER_COUNT):
		var layer_nodes = generate_layer_nodes(layer, node_id_counter, tier_enemy_assignments, god_name)
		nodes_by_layer.append(layer_nodes)
		
		# Add nodes to the main array
		for node in layer_nodes:
			map_data.nodes.append(node)
		
		node_id_counter += layer_nodes.size()
	
	# Generate connections between layers
	connect_layers(nodes_by_layer, map_data)
	
	# Update initial availability (starting nodes should be available)
	map_data.update_node_availability()
	
	return map_data

# Pre-assign enemies to tiers to ensure each enemy is used exactly once
static func assign_enemies_to_tiers(god_name: String = "Apollo", deck_name: String = "") -> Dictionary:
	var enemies_collection: EnemiesCollection = load("res://Resources/Collections/Enemies.tres")
	if not enemies_collection:
		print("ERROR: Could not load enemies collection")
		return {}
	
	var all_enemies = enemies_collection.get_enemy_names()
	
	# Load the enemy pool configuration
	var enemy_pools: GodEnemyPools = load("res://Resources/god_enemy_pools.tres")
	if not enemy_pools:
		push_error("Could not load god enemy pools configuration")
		return {}

	# Get enemies for the current god and deck (includes general, god-specific, and deck-specific)
	var god_enemies = enemy_pools.get_enemy_pool(god_name, deck_name)
	
	# Filter to only use enemies that actually exist in the collection
	var available_enemies = []
	for enemy_name in god_enemies:
		if enemy_name in all_enemies:
			available_enemies.append(enemy_name)
		else:
			print("WARNING: Enemy '", enemy_name, "' not found in collection for god ", god_name)
	
	# Fallback to first 5 available enemies if we don't have enough god-specific ones
	if available_enemies.size() < 5:
		print("Not enough god-specific enemies for ", god_name, ", using general pool")
		available_enemies = []
		for i in range(min(5, all_enemies.size())):
			available_enemies.append(all_enemies[i])
	
	print(god_name, " enemies available: ", available_enemies)
	
	# Shuffle the enemies randomly
	available_enemies.shuffle()
	
	# Assign one enemy to each tier (0-4)
	var tier_assignments = {}
	for tier in range(5):
		if tier < available_enemies.size():
			tier_assignments[tier] = available_enemies[tier]
			print("Tier ", tier, " assigned enemy: ", available_enemies[tier])
		else:
			# Fallback if we somehow don't have enough enemies
			tier_assignments[tier] = "Shadow Acolyte"
			print("Tier ", tier, " fallback to Shadow Acolyte")
	
	return tier_assignments

# Generate nodes for a specific layer
static func generate_layer_nodes(layer: int, starting_id: int, tier_enemy_assignments: Dictionary, god_name: String = "Apollo") -> Array[MapNode]:
	var layer_nodes: Array[MapNode] = []
	var node_count = NODES_PER_LAYER[layer]
	
	# Get actual screen width dynamically
	var screen_width = DisplayServer.window_get_size().x
	var screen_center_x = screen_width / 2.0
	
	# Calculate horizontal spacing for this layer
	var horizontal_spacing = (screen_width * 0.8) / (node_count + 1)  # Use 80% of screen width
	var start_x = screen_width * 0.1  # Start at 10% from left edge
	
	# Position layers so layer 0 (starting enemies) is at the top and boss is at the bottom
	var button_height = 60
	var top_padding = button_height / 2  # Less space at top for starting enemies
	var bottom_padding = button_height  # More space at bottom for boss
	var usable_height = MAP_HEIGHT - top_padding - bottom_padding
	var layer_spacing = usable_height / (LAYER_COUNT - 1) if LAYER_COUNT > 1 else 0
	var y_position = top_padding + (LAYER_COUNT - 1 - layer) * layer_spacing

	for i in range(node_count):
		var x_position = start_x + (i + 1) * horizontal_spacing
		var position = Vector2(x_position, y_position)
		
		# Determine node type based on layer
		var node_type = determine_node_type(layer, i)
		
		# Create the node
		var node = MapNode.new(starting_id + i, node_type, position)
		
		# Assign enemy to this node using the pre-assigned tier enemies
		assign_enemy_to_node_with_tier_assignments(node, layer, tier_enemy_assignments, god_name)
		
		layer_nodes.append(node)
	
	return layer_nodes

# Determine what type of node this should be
static func determine_node_type(layer: int, index_in_layer: int) -> MapNode.NodeType:
	# For now, everything is a battle except the last layer which is boss
	if layer == LAYER_COUNT - 1:
		return MapNode.NodeType.BOSS
	else:
		return MapNode.NodeType.BATTLE

static func assign_enemy_to_node_with_tier_assignments(node: MapNode, layer: int, tier_assignments: Dictionary, god_name: String = "Apollo"):
	var enemies_collection: EnemiesCollection = load("res://Resources/Collections/Enemies.tres")
	if not enemies_collection:
		# Fallback if enemies collection not found
		node.enemy_name = "Shadow Acolyte"
		node.enemy_difficulty = 0
		return
	
	# Assign enemy based on node type
	if node.node_type == MapNode.NodeType.BOSS:
		# Use the god-specific boss
		node.enemy_name = BossConfig.get_boss_name_for_god(god_name)
		node.enemy_difficulty = 2  # Master difficulty for boss
		print("Assigned boss: ", node.enemy_name, " for god: ", god_name)
	else:
		# Get the pre-assigned enemy for this tier
		var assigned_enemy = tier_assignments.get(layer, "Shadow Acolyte")
		
		# Determine difficulty based on tier
		var difficulty: int
		match layer:
			0, 1, 2:  # First 3 tiers - difficulty 1 (Adept)
				difficulty = 1
			3:        # 4th tier - difficulty 2 (Master)
				difficulty = 2
			_:        # 5th tier and beyond - difficulty 3 (or 2 if 3 doesn't exist)
				difficulty = 3
				# Verify difficulty 3 exists for this enemy
				var enemy_collection = enemies_collection.get_enemy(assigned_enemy)
				if enemy_collection:
					var available_difficulties = enemy_collection.get_available_difficulties()
					if not 3 in available_difficulties:
						difficulty = 2  # Fall back to difficulty 2
				else:
					difficulty = 2  # Fallback
		
		node.enemy_name = assigned_enemy
		node.enemy_difficulty = difficulty
		
		print("Assigned enemy: ", assigned_enemy, " (difficulty ", difficulty, ") to layer ", layer, " node")
		
		# Verify the assignment worked
		var enemy_deck = enemies_collection.get_enemy_deck(assigned_enemy, difficulty)
		if enemy_deck.is_empty():
			print("WARNING: No deck found for ", assigned_enemy, " at difficulty ", difficulty, " - falling back to difficulty 1")
			node.enemy_difficulty = 1

# Connect nodes between layers - SIMPLIFIED for linear path
static func connect_layers(nodes_by_layer: Array, map_data: MapData):
	# Connect each layer to the PREVIOUS layer (so starting nodes have no connections)
	for layer in range(1, LAYER_COUNT):  # Start from layer 1, not 0
		var current_layer_nodes = nodes_by_layer[layer]
		var previous_layer_nodes = nodes_by_layer[layer - 1]
		
		# Each node in current layer connects to the single node in previous layer
		for current_node in current_layer_nodes:
			var connections = generate_connections_for_node(
				current_node, 
				current_layer_nodes, 
				previous_layer_nodes
			)
			current_node.connections = connections

# Generate connections for a specific node - SIMPLIFIED for linear path
static func generate_connections_for_node(
	current_node: MapNode, 
	current_layer: Array[MapNode], 
	next_layer: Array[MapNode]
) -> Array[int]:
	
	var connections: Array[int] = []
	
	# For a linear path, each node simply connects to the single node in the previous layer
	if next_layer.size() > 0:
		connections.append(next_layer[0].node_id)
	
	return connections

# Debug function to print the map structure
static func print_map_debug(map_data: MapData):
	print("=== MAP DEBUG ===")
	print("Total nodes: ", map_data.nodes.size())
	print("Total layers: ", map_data.total_layers)
	
	for layer in range(map_data.total_layers):
		var layer_nodes = map_data.get_nodes_in_layer(layer)
		print("Layer ", layer, ": ", layer_nodes.size(), " nodes")
		
		for node in layer_nodes:
			print("  Node ", node.node_id, " (", node.display_name, ") -> ", node.connections)
			print("    Enemy: ", node.enemy_name, " (difficulty ", node.enemy_difficulty, ")")
