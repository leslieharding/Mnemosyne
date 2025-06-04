# res://Resources/map_node.gd
class_name MapNode
extends Resource

enum NodeType {
	BATTLE,
	EVENT,
	SHOP,
	BOSS,
	REST
}

@export var node_type: NodeType = NodeType.BATTLE
@export var position: Vector2 = Vector2.ZERO
@export var connections: Array[int] = []  # Indices of nodes this connects to
@export var is_completed: bool = false
@export var is_available: bool = false
@export var node_id: int = -1

# Enemy encounter data
@export var enemy_name: String = "Shadow Acolyte"  # Which enemy type
@export var enemy_difficulty: int = 0  # 0=easy, 1=medium, 2=hard/boss

# Visual/UI properties
@export var display_name: String = ""
@export var description: String = ""

# Replace the _init function (around lines 21-40)

func _init(id: int = -1, type: NodeType = NodeType.BATTLE, pos: Vector2 = Vector2.ZERO):
	node_id = id
	node_type = type
	position = pos
	is_available = false
	is_completed = false
	
	# Set default enemy data
	enemy_name = "Shadow Acolyte"
	enemy_difficulty = 0
	
	# Set default display info based on type
	match node_type:
		NodeType.BATTLE:
			display_name = "Battle"
			description = "Face an opponent in card combat"
		NodeType.EVENT:
			display_name = "Event"
			description = "A mysterious encounter awaits"
		NodeType.SHOP:
			display_name = "Shop"
			description = "Upgrade your cards"
		NodeType.BOSS:
			display_name = "Boss"
			description = "A powerful enemy blocks your path"
		NodeType.REST:
			display_name = "Rest"
			description = "Recover and prepare"

# Helper to check if this node can be accessed
func can_be_accessed(completed_nodes: Array[int]) -> bool:
	if is_completed:
		return false
		
	# If no connections, it's a starting node
	if connections.is_empty():
		return true
		
	# Check if any connected node is completed
	for connection_id in connections:
		if connection_id in completed_nodes:
			return true
			
	return false
