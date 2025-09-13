# res://Scripts/run_enrichment_tracker.gd
extends Node
class_name RunEnrichmentTracker

signal slot_enriched(slot_index: int, enrichment_amount: int)

# Track enrichment levels per slot during current run
# Structure: {slot_index: enrichment_level}
var run_slot_enrichment: Dictionary = {}

# Track which slots have been enriched (for UI updates)
var enriched_slots: Array[int] = []

func _ready():
	# This will be an autoload singleton
	pass

# Initialize for a new run - clear all enrichment
func start_new_run():
	run_slot_enrichment.clear()
	enriched_slots.clear()
	
	print("RunEnrichmentTracker: Started new run - all slot enrichment cleared")

# Add enrichment to a slot (called when Enrich ability activates)
func add_slot_enrichment(slot_index: int, enrichment_amount: int):
	if not slot_index in run_slot_enrichment:
		run_slot_enrichment[slot_index] = 0
	
	run_slot_enrichment[slot_index] += enrichment_amount
	
	# Track which slots are enriched for UI purposes
	if slot_index not in enriched_slots and run_slot_enrichment[slot_index] != 0:
		enriched_slots.append(slot_index)
	elif slot_index in enriched_slots and run_slot_enrichment[slot_index] == 0:
		enriched_slots.erase(slot_index)
	
	emit_signal("slot_enriched", slot_index, enrichment_amount)
	print("RunEnrichmentTracker: Slot ", slot_index, " enriched by ", enrichment_amount, ". Total enrichment: ", run_slot_enrichment[slot_index])

# Get enrichment level for a specific slot
func get_slot_enrichment(slot_index: int) -> int:
	return run_slot_enrichment.get(slot_index, 0)

# Get all enriched slots and their levels
func get_all_enrichment() -> Dictionary:
	return run_slot_enrichment.duplicate()

# Check if a slot is enriched
func is_slot_enriched(slot_index: int) -> bool:
	return get_slot_enrichment(slot_index) > 0

# Get list of enriched slot indices
func get_enriched_slots() -> Array[int]:
	return enriched_slots.duplicate()

# Clear all enrichment (for run end)
func clear_enrichment():
	run_slot_enrichment.clear()
	enriched_slots.clear()
	print("RunEnrichmentTracker: All enrichment cleared")
