# res://Resources/dialogue_line.gd
class_name DialogueLine
extends Resource

@export var speaker_id: String = ""
@export var text: String = ""
@export var speaker_position: String = "auto"

# Existing timing controls
@export var typing_speed_multiplier: float = 1.0
@export var pre_line_delay: float = 0.0
@export var post_line_delay: float = 0.0

# NEW: Support for inline markup
var parsed_segments: Array = []  # Will store parsed text segments with their properties

func _init(speaker: String = "", dialogue_text: String = "", position: String = "auto", 
		   typing_speed: float = 1.0, pre_delay: float = 0.0, post_delay: float = 0.0):
	speaker_id = speaker
	text = dialogue_text
	speaker_position = position
	typing_speed_multiplier = typing_speed
	pre_line_delay = pre_delay
	post_line_delay = post_delay
	
	# Parse the text when initialized
	parse_text_markup()

# NEW: Parse markup tags in the text
func parse_text_markup():
	parsed_segments.clear()
	
	# If no markup, treat as single segment
	if not text.contains("[") and not text.contains("{"):
		parsed_segments.append({
			"text": text,
			"speed": 1.0,
			"pause_before": 0.0,
			"pause_after": 0.0
		})
		return
	
	var current_pos = 0
	var working_text = text
	
	# Regular expression patterns for our markup
	# [speed:0.5]text[/speed] - changes speed
	# {pause:1.0} - adds a pause
	# [urgent]text[/urgent] - preset for urgent text (fast)
	# [slow]text[/slow] - preset for slow text
	
	while current_pos < working_text.length():
		var next_tag_start = working_text.find("[", current_pos)
		var next_pause = working_text.find("{pause:", current_pos)
		
		# Find which comes first
		var next_special = -1
		var tag_type = ""
		
		if next_tag_start != -1 and (next_pause == -1 or next_tag_start < next_pause):
			next_special = next_tag_start
			tag_type = "speed"
		elif next_pause != -1:
			next_special = next_pause
			tag_type = "pause"
		
		# If no more special tags, add remaining text
		if next_special == -1:
			if current_pos < working_text.length():
				parsed_segments.append({
					"text": working_text.substr(current_pos),
					"speed": 1.0,
					"pause_before": 0.0,
					"pause_after": 0.0
				})
			break
		
		# Add text before the tag (if any)
		if next_special > current_pos:
			parsed_segments.append({
				"text": working_text.substr(current_pos, next_special - current_pos),
				"speed": 1.0,
				"pause_before": 0.0,
				"pause_after": 0.0
			})
		
		# Process the tag
		if tag_type == "pause":
			var pause_end = working_text.find("}", next_special)
			if pause_end != -1:
				var pause_content = working_text.substr(next_special + 7, pause_end - next_special - 7)
				var pause_duration = pause_content.to_float()
				
				# Add pause as a special segment
				parsed_segments.append({
					"text": "",
					"speed": 1.0,
					"pause_before": pause_duration,
					"pause_after": 0.0
				})
				
				current_pos = pause_end + 1
			else:
				current_pos = next_special + 1
				
		elif tag_type == "speed":
			var tag_content = working_text.substr(next_special + 1)
			var tag_end_marker = "[/"
			var speed_multiplier = 1.0
			var end_tag_pos = -1
			
			# Check for speed tag with value
			if tag_content.begins_with("speed:"):
				var close_bracket = tag_content.find("]")
				if close_bracket != -1:
					var speed_value = tag_content.substr(6, close_bracket - 6).to_float()
					speed_multiplier = speed_value
					
					# Find the closing tag
					var end_tag = "[/speed]"
					end_tag_pos = working_text.find(end_tag, next_special)
					
					if end_tag_pos != -1:
						var text_start = next_special + close_bracket + 2
						var segment_text = working_text.substr(text_start, end_tag_pos - text_start)
						
						parsed_segments.append({
							"text": segment_text,
							"speed": speed_multiplier,
							"pause_before": 0.0,
							"pause_after": 0.0
						})
						
						current_pos = end_tag_pos + end_tag.length()
					else:
						current_pos = next_special + 1
				else:
					current_pos = next_special + 1
					
			# Check for preset tags
			elif tag_content.begins_with("urgent]"):
				end_tag_pos = working_text.find("[/urgent]", next_special)
				if end_tag_pos != -1:
					var text_start = next_special + 8
					var segment_text = working_text.substr(text_start, end_tag_pos - text_start)
					
					parsed_segments.append({
						"text": segment_text,
						"speed": 2.5,  # Fast for urgent
						"pause_before": 0.0,
						"pause_after": 0.0
					})
					
					current_pos = end_tag_pos + 9
				else:
					current_pos = next_special + 1
					
			elif tag_content.begins_with("slow]"):
				end_tag_pos = working_text.find("[/slow]", next_special)
				if end_tag_pos != -1:
					var text_start = next_special + 6
					var segment_text = working_text.substr(text_start, end_tag_pos - text_start)
					
					parsed_segments.append({
						"text": segment_text,
						"speed": 0.4,  # Slow
						"pause_before": 0.0,
						"pause_after": 0.0
					})
					
					current_pos = end_tag_pos + 7
				else:
					current_pos = next_special + 1
			else:
				# Unrecognized tag, skip it
				current_pos = next_special + 1

# Get the clean text without markup
func get_clean_text() -> String:
	var clean = ""
	for segment in parsed_segments:
		clean += segment.text
	return clean




#Flexible Text Speed Implementation Guide
#Basic Implementation
#Your system is already set up! You just need to use the markup tags in your dialogue text when creating DialogueLine objects.
#Available Markup Tags
#Speed Control Tags
#gdscript"[speed:0.5]slow text[/speed]"     # Half speed (0.5x)
#"[speed:2.0]fast text[/speed]"     # Double speed (2.0x)
#"[urgent]emergency![/urgent]"      # Preset fast (2.5x speed)
#"[slow]contemplative[/slow]"       # Preset slow (0.4x speed)
#Pause Tags
#gdscript"Before{pause:1.0}after"           # 1 second pause mid-sentence
#"Text{pause:0.5}more text"         # 0.5 second pause
#Line-Level Timing
#gdscriptDialogueLine.new(
	#"Speaker",
	#"Text content",
	#"position",
	#1.2,    # typing_speed_multiplier - affects whole line
	#0.5,    # pre_line_delay - pause before typing starts  
	#1.0     # post_line_delay - pause after line finishes
#)
#Dramatic Effect Examples
#Building Tension
#gdscriptDialogueLine.new(
	#"Villain", 
	#"You think you can [slow]stop me[/slow]?{pause:1.5} [urgent]Think again![/urgent]",
	#"right",
	#0.8,  # Slower base for menace
	#1.0,  # Pause before speaking
	#0.5
#)
#Emotional Outburst
#gdscriptDialogueLine.new(
	#"Hero", 
	#"[urgent]No! This can't be happening![/urgent]{pause:2.0} [slow]Why didn't I see this coming?[/slow]",
	#"left",
	#1.3,  # Faster base for emotion
	#0.0,  # No delay - immediate reaction
	#1.5   # Long pause for impact
#)
#Mystical/Wise Character
#gdscriptDialogueLine.new(
	#"Oracle", 
	#"The threads of fate{pause:1.0} reveal [slow]many truths[/slow],{pause:0.8} but [urgent]beware[/urgent]{pause:1.5} the [slow]price of knowledge[/slow].",
	#"center",
	#0.7,  # Slower base for wisdom
	#2.0,  # Long pause before speaking
	#2.5   # Very long pause after prophecy
#)
#Quick Banter
#gdscriptDialogueLine.new(
	#"Sidekick", 
	#"[urgent]Wait, what?[/urgent] [speed:1.5]Did you just say we're going WHERE?[/speed]",
	#"left",
	#1.4,  # Fast base for energy
	#0.0,  # Immediate reaction
	#0.3   # Quick transition
#)
