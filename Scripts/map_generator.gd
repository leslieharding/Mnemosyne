# res://Scripts/map_generator.gd
class_name MapGenerator
extends RefCounted

# Map generation settings
static var LAYER_COUNT: int = 4
static var NODES_PER_LAYER: Array[int] = [3, 4, 4, 1]  # Start, Middle, Middle, Boss
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
	var layer_nodes: Array[MapN ode] = []
	var node_count = NODES_PER_LAYER[layer]
	
	# Calculate horizontal spacing for this layer
	var horizontal_spacing = MAP_WIDTH / (node_count + 1)
	var y_position = layer * LAYER_SPACING
	
	for i in range(node_count):
		var x_position = (i + 1) * horizontal_spacing
		var position = Vector2(x_position, y_position)
		
		# Determine node type based on layer
		var node_type = determine_node_type(layer, i)
		
		# Create the node
		var node = MapNode.new(starting_id + i, node_type, position)
		layer_nodes.append(node)
	
	return layer_nodes

# Determine what type of node this should be
static func determine_node_type(layer: int, index_in_layer: int) -> MapNode.NodeType:
	# For now, everything is a battle except the last layer which is boss
	if layer == LAYER_COUNT - 1:
		return MapNode.NodeType.BOSS
	else:
		return MapNode.NodeType.BATTLE

# Connect nodes between layers
static func connect_layers(nodes_by_layer: Array, map_data: MapData):
	# Connect each layer to the next
	for layer in range(LAYER_COUNT - 1):
		var current_layer_nodes = nodes_by_layer[layer]
		var next_layer_nodes = nodes_by_layer[layer + 1]
		
		# Each node in current layer connects to some nodes in next layer
		for current_node in current_layer_nodes:
			var connections = generate_connections_for_node(
				current_node, 
				current_layer_nodes, 
				next_layer_nodes
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
