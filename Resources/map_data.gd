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
	var completed_node = null
	for node in nodes:
		if node.node_id == node_id:
			node.is_completed = true
			completed_node = node
			break
	
	if completed_node:
		# Disable all other nodes in the same layer
		disable_other_nodes_in_layer(completed_node)
	
	# Update availability of connected nodes
	update_node_availability()

# Disable other nodes in the same layer when one is completed
func disable_other_nodes_in_layer(completed_node: MapNode):
	# Find which layer this node belongs to
	var completed_layer = get_node_layer(completed_node)
	
	if completed_layer != -1:
		var layer_nodes = get_nodes_in_layer(completed_layer)
		for node in layer_nodes:
			if node.node_id != completed_node.node_id and not node.is_completed:
				# Mark as unavailable (but not completed)
				node.is_available = false

# Get which layer a node belongs to
func get_node_layer(target_node: MapNode) -> int:
	var start_index = 0
	
	for layer in range(total_layers):
		var layer_count = layer_node_counts[layer] if layer < layer_node_counts.size() else 0
		
		for i in range(layer_count):
			var node_index = start_index + i
			if node_index < nodes.size() and nodes[node_index].node_id == target_node.node_id:
				return layer
		
		start_index += layer_count
	
	return -1

# Update which nodes are available based on completed nodes
func update_node_availability():
	# First, reset availability for all non-completed nodes
	for node in nodes:
		if not node.is_completed:
			node.is_available = false
	
	# Then set availability based on layer progression
	set_layer_based_availability()

# Set availability based on layer-by-layer progression
func set_layer_based_availability():
	# Layer 0 (starting layer) should always be available if not completed
	var layer_0_nodes = get_nodes_in_layer(0)
	var layer_0_has_completed = false
	
	for node in layer_0_nodes:
		if node.is_completed:
			layer_0_has_completed = true
		elif not layer_0_has_completed:
			node.is_available = true
	
	# For subsequent layers, only make available if previous layer is completed
	for layer in range(1, total_layers):
		var previous_layer_completed = false
		var previous_layer_nodes = get_nodes_in_layer(layer - 1)
		
		# Check if any node in previous layer is completed
		for prev_node in previous_layer_nodes:
			if prev_node.is_completed:
				previous_layer_completed = true
				break
		
		if previous_layer_completed:
			var current_layer_nodes = get_nodes_in_layer(layer)
			var current_layer_has_completed = false
			
			# Check if current layer already has a completed node
			for node in current_layer_nodes:
				if node.is_completed:
					current_layer_has_completed = true
					break
			
			# If no node in current layer is completed, make them available
			if not current_layer_has_completed:
				for node in current_layer_nodes:
					node.is_available = true

# Check if the map is complete (reached end)
func is_map_complete() -> bool:
	# Check if any node in the final layer is completed
	var final_layer = total_layers - 1
	var final_layer_nodes = get_nodes_in_layer(final_layer)
	
	for node in final_layer_nodes:
		if node.is_completed:
			return true
	
	return false
