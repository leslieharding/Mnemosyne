# res://Resources/map_data.gd
class_name MapData
extends Resource

@export var nodes: Array[MapNode] = []
@export var completed_nodes: Array[int] = []
@export var current_layer: int = 0
@export var total_layers: int = 4

# Map configuration
@export var layer_node_counts: Array[int] = [3, 4, 4, 1]  # nodes per layer

func _init():
	pass

# Get all nodes in a specific layer
func get_nodes_in_layer(layer: int) -> Array[MapNode]:
	var layer_nodes: Array[MapNode] = []
	var start_index = 0
	
	# Calculate starting index for this layer
	for i in range(layer):
		if i < layer_node_counts.size():
			start_index += layer_node_counts[i]
	
	# Get the count for this layer
	var layer_count = layer_node_counts[layer] if layer < layer_node_counts.size() else 0
	
	# Extract nodes for this layer
	for i in range(layer_count):
		var node_index = start_index + i
		if node_index < nodes.size():
			layer_nodes.append(nodes[node_index])
	
	return layer_nodes

# Get available nodes that can be accessed
func get_available_nodes() -> Array[MapNode]:
	var available: Array[MapNode] = []
	
	for node in nodes:
		if node.can_be_accessed(completed_nodes):
			available.append(node)
	
	return available

# Mark a node as completed and update availability
func complete_node(node_id: int):
	if node_id in completed_nodes:
		return
		
	completed_nodes.append(node_id)
	
	# Find and mark the node as completed
	for node in nodes:
		if node.node_id == node_id:
			node.is_completed = true
			break
	
	# Update availability of connected nodes
	update_node_availability()

# Update which nodes are available based on completed nodes
func update_node_availability():
	for node in nodes:
		node.is_available = node.can_be_accessed(completed_nodes)

# Check if the map is complete (reached end)
func is_map_complete() -> bool:
	# Check if any node in the final layer is completed
	var final_layer = total_layers - 1
	var final_layer_nodes = get_nodes_in_layer(final_layer)
	
	for node in final_layer_nodes:
		if node.is_completed:
			return true
	
	return false
