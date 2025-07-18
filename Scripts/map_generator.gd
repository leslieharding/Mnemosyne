# res://Scripts/map_generator.gd
class_name MapGenerator
extends RefCounted

# Map generation settings
static var LAYER_COUNT: int = 6  # Or however many layers you want
static var NODES_PER_LAYER: Array[int] = [3, 3, 3, 3, 2, 1]  # Start, Early, Mid, Late, Elite, Boss
static var MAP_WIDTH: float = 800.0
static var MAP_HEIGHT: float = 600.0
static var LAYER_SPACING: float = MAP_HEIGHT / (LAYER_COUNT - 1)

# Generate a complete map
static func generate_map() -> MapData:
	var map_data = MapData.new()
	map_data.total_layers = LAYER_COUNT
	map_data.layer_node_counts = NODES_PER_LAYER
	
	# Generate nodes for each layer
	var node_id_counter = 0
	var nodes_by_layer: Array = []
	
	for layer in range(LAYER_COUNT):
		var layer_nodes = generate_layer_nodes(layer, node_id_counter)
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

# Generate nodes for a specific layer
static func generate_layer_nodes(layer: int, starting_id: int) -> Array[MapNode]:
	var layer_nodes: Array[MapNode] = []
	var node_count = NODES_PER_LAYER[layer]
	
	# Calculate horizontal spacing for this layer
	var horizontal_spacing = MAP_WIDTH / (node_count + 1)
	# Invert the Y position so layer 0 is at the bottom and final layer is at top
	# Add padding so buttons don't go off-screen (button height is ~60px)
	var button_height = 60
	var padding = button_height / 2
	var usable_height = MAP_HEIGHT - (2 * padding)
	var layer_spacing = usable_height / (LAYER_COUNT - 1) if LAYER_COUNT > 1 else 0
	var y_position = padding + (LAYER_COUNT - 1 - layer) * layer_spacing

	for i in range(node_count):
		var x_position = (i + 1) * horizontal_spacing
		var position = Vector2(x_position, y_position)
		
		# Determine node type based on layer
		var node_type = determine_node_type(layer, i)
		
		# Create the node
		var node = MapNode.new(starting_id + i, node_type, position)
		
		# Assign enemy to this node
		assign_enemy_to_node(node, layer, i)
		
		layer_nodes.append(node)
	
	return layer_nodes

# Determine what type of node this should be
static func determine_node_type(layer: int, index_in_layer: int) -> MapNode.NodeType:
	# For now, everything is a battle except the last layer which is boss
	if layer == LAYER_COUNT - 1:
		return MapNode.NodeType.BOSS
	else:
		return MapNode.NodeType.BATTLE

static func assign_enemy_to_node(node: MapNode, layer: int, index_in_layer: int):
	var enemies_collection: EnemiesCollection = load("res://Resources/Collections/Enemies.tres")
	if not enemies_collection:
		# Fallback if enemies collection not found
		node.enemy_name = "Shadow Acolyte"
		node.enemy_difficulty = 0
		return
	
	var enemy_names = enemies_collection.get_enemy_names()
	
	# Assign enemy based on node type first, then layer
	if node.node_type == MapNode.NodeType.BOSS:
		# Always assign the boss to boss nodes
		node.enemy_name = "?????"
		node.enemy_difficulty = 2  # Master difficulty for boss
		print("Assigned boss: ????? to boss node")
	else:
		# Regular enemy assignment based on layer
		match layer:
			0:  # Starting layer - easy enemies
				# Use the first few enemies, excluding the boss
				var regular_enemies = []
				for enemy_name in enemy_names:
					if enemy_name != "?????":
						regular_enemies.append(enemy_name)
				
				if regular_enemies.size() > 0:
					node.enemy_name = regular_enemies[index_in_layer % regular_enemies.size()]
				else:
					node.enemy_name = "Shadow Acolyte"  # Fallback
				node.enemy_difficulty = 0
			1, 2:  # Middle layers - medium enemies
				var regular_enemies = []
				for enemy_name in enemy_names:
					if enemy_name != "?????":
						regular_enemies.append(enemy_name)
				
				if regular_enemies.size() > 0:
					node.enemy_name = regular_enemies[index_in_layer % regular_enemies.size()]
				else:
					node.enemy_name = "Shadow Acolyte"  # Fallback
				node.enemy_difficulty = 1
			_:
				# Fallback for any other layers
				node.enemy_name = "Shadow Acolyte"
				node.enemy_difficulty = 0

# Connect nodes between layers - REVERSE the connection direction
static func connect_layers(nodes_by_layer: Array, map_data: MapData):
	# Connect each layer to the PREVIOUS layer (so starting nodes have no connections)
	for layer in range(1, LAYER_COUNT):  # Start from layer 1, not 0
		var current_layer_nodes = nodes_by_layer[layer]
		var previous_layer_nodes = nodes_by_layer[layer - 1]
		
		# Each node in current layer connects to some nodes in previous layer
		for current_node in current_layer_nodes:
			var connections = generate_connections_for_node(
				current_node, 
				current_layer_nodes, 
				previous_layer_nodes
			)
			current_node.connections = connections

# Generate connections for a specific node
static func generate_connections_for_node(
	current_node: MapNode, 
	current_layer: Array[MapNode], 
	next_layer: Array[MapNode]
) -> Array[int]:
	
	var connections: Array[int] = []
	
	# Simple connection logic: each node connects to 1-2 nodes in the next layer
	var connection_count = randi_range(1, min(2, next_layer.size()))
	
	# Find the closest nodes in the next layer based on horizontal position
	var distances: Array = []
	for i in range(next_layer.size()):
		var next_node = next_layer[i]
		var distance = abs(current_node.position.x - next_node.position.x)
		distances.append({"index": i, "distance": distance, "node_id": next_node.node_id})
	
	# Sort by distance
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Connect to the closest nodes
	for i in range(min(connection_count, distances.size())):
		connections.append(distances[i].node_id)
	
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
