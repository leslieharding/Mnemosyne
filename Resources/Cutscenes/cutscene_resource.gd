# res://Resources/Cutscenes/cutscene_resource.gd
extends Resource
class_name CutsceneResource

@export var cutscene_id: String
@export var cutscene_name: String
@export var dialogue_sequence: Array[DialogueData]
@export var next_scene: String = ""  # Scene to go to after cutscene
@export var background_color: Color = Color.BLACK
