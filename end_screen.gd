extends Control

const WordData = preload("res://word_data.gd")
var selected_words = []
var score = 0

func set_words(words: Array):
	selected_words = words
	calculate_score()

func calculate_score():
	score = 0
	var connections = []
	
	# Check relationships between adjacent words
	for i in range(selected_words.size() - 1):
		var word1 = selected_words[i]
		var word2 = selected_words[i + 1]
		
		var connecting_words = find_connecting_words(word1, word2)
		if connecting_words.size() > 0:
			# Award points for each valid connection
			score += 50  # Base score for each connection
			connections.append({
				"from": i,
				"to": i + 1,
				"connecting_word": connecting_words[0]
			})
	
	# Chain bonus: consecutive relationships
	var chain_length = find_longest_chain()
	if chain_length > 2:
		score += (chain_length - 2) * 25

func find_longest_chain() -> int:
	var longest = 1
	var current = 1
	
	for i in range(selected_words.size() - 1):
		var word1 = selected_words[i]
		var word2 = selected_words[i + 1]
		
		var connecting_words = find_connecting_words(word1, word2)
		if connecting_words.size() > 0:
			current += 1
			longest = max(longest, current)
		else:
			current = 1
	
	return longest

func _ready():
	style_buttons()
	setup_word_display()
	
	$VBoxContainer/GameOverLabel.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	$VBoxContainer/PlayAgainButton.pressed.connect(on_play_again_pressed)
	$VBoxContainer/MainMenuButton.pressed.connect(on_menu_pressed)

func calculate_word_scores() -> Dictionary:
	var word_scores = {}
	
	# Initialize scores
	for word in selected_words:
		word_scores[word] = 0
	
	# Only calculate scores for adjacent words
	for i in range(selected_words.size() - 1):
		var word1 = selected_words[i]
		var word2 = selected_words[i + 1]
		
		var connecting_words = find_connecting_words(word1, word2)
		if connecting_words.size() > 0:
			# Split the base score between the two words
			var connection_score = 50  # Base score for each connection
			word_scores[word1] += connection_score / 2
			word_scores[word2] += connection_score / 2
	
	return word_scores

func setup_word_display():
	var words_container = $VBoxContainer/WordsContainer
	var word_scores = calculate_word_scores()
	var word_nodes = []
	
	# First pass: Add all words and their scores
	for i in range(selected_words.size()):
		var word_row = HBoxContainer.new()
		word_row.alignment = BoxContainer.ALIGNMENT_CENTER
		word_row.modulate.a = 0
		
		var word_button = Button.new()
		word_button.text = selected_words[i]
		word_button.custom_minimum_size = Vector2(200, 50)
		
		var style = StyleBoxFlat.new()
		style.bg_color = GameTheme.COLORS.selected_word
		style.corner_radius_top_left = GameTheme.STYLES.corner_radius
		style.corner_radius_top_right = GameTheme.STYLES.corner_radius
		style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
		style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
		
		word_button.add_theme_stylebox_override("normal", style)
		word_button.add_theme_font_size_override("font_size", 24)
		word_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
		word_button.pressed.connect(func(): show_associations(selected_words[i]))
		
		word_row.add_child(word_button)
		
		# Add score label if word has any score
		var word_score = word_scores[selected_words[i]]
		if word_score > 0:
			var score_label = Label.new()
			score_label.text = "+%d" % word_score
			score_label.add_theme_font_size_override("font_size", 24)
			score_label.add_theme_color_override("font_color", GameTheme.COLORS.primary)
			score_label.custom_minimum_size = Vector2(80, 0)
			score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			word_row.add_child(score_label)
		
		words_container.add_child(word_row)
		word_nodes.append(word_row)
		
		var tween = create_tween()
		
		# Check for common associations with previous words
		if i > 0:
			var word1 = selected_words[i-1]
			var word2 = selected_words[i]
			var connecting_words = find_connecting_words(word1, word2)

			# If there's an indirect connection via a common word
			if connecting_words.size() > 0 and connecting_words[0] != "Direct":
				var connector_row = HBoxContainer.new()
				connector_row.alignment = BoxContainer.ALIGNMENT_CENTER
				connector_row.modulate.a = 0
				
				var connector_label = Button.new()
				connector_label.text = connecting_words[0]
				connector_label.custom_minimum_size = Vector2(150, 35)
				
				var connector_style = StyleBoxFlat.new()
				connector_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)  # Darker grey
				connector_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
				connector_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
				connector_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
				connector_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
				
				connector_label.add_theme_stylebox_override("normal", connector_style)
				connector_label.add_theme_font_size_override("font_size", 18)
				connector_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				
				connector_row.add_child(connector_label)
				
				# Insert the connector row before the current word row
				var current_index = word_row.get_index()
				words_container.move_child(word_row, current_index)
				words_container.add_child(connector_row)
				words_container.move_child(connector_row, current_index)
				
				# Animate connector
				tween.tween_property(connector_row, "modulate:a", 1, 0.3).set_delay(i * 0.15)
				tween.parallel().tween_property(connector_row, "position:x", 0, 0.3).from(50)
		
		tween.tween_property(word_row, "modulate:a", 1, 0.3).set_delay(i * 0.15)
		tween.parallel().tween_property(word_row, "position:x", 0, 0.3).from(50)
	
	# Highlight connections after words appear
	await get_tree().create_timer(selected_words.size() * 0.15 + 0.3).timeout
	highlight_connections(word_nodes)



func highlight_connections(word_nodes: Array):
	for i in range(selected_words.size() - 1):
		var word1 = selected_words[i]
		var word2 = selected_words[i + 1]
		
		var connecting_words = find_connecting_words(word1, word2)
		if connecting_words.size() > 0:
			var color = GameTheme.COLORS.selected_word  # default color
			var tween = create_tween()
			tween.tween_property(word_nodes[i], "modulate", Color(color, 1.2), 0.3)
			tween.parallel().tween_property(word_nodes[i + 1], "modulate", Color(color, 1.2), 0.3)
			tween.tween_property(word_nodes[i], "modulate", Color.WHITE, 0.3)
			tween.parallel().tween_property(word_nodes[i + 1], "modulate", Color.WHITE, 0.3)


func find_connecting_words(word1: String, word2: String) -> Array:
	# First check for direct connections in both directions
	if word1 in WordData.WORD_RELATIONSHIPS and word2 in WordData.WORD_RELATIONSHIPS[word1]:
		return ["Direct"]
	if word2 in WordData.WORD_RELATIONSHIPS and word1 in WordData.WORD_RELATIONSHIPS[word2]:
		return ["Direct"]
	
	# Get all relationships for both words
	var word1_rels = WordData.WORD_RELATIONSHIPS.get(word1, {})
	var word2_rels = WordData.WORD_RELATIONSHIPS.get(word2, {})
	
	# Check for common connections
	var connecting_words = []
	for rel_word in word1_rels.keys():
		if rel_word in word2_rels:
			connecting_words.append(rel_word)
	
	# Also check the reverse direction
	for rel_word in word2_rels.keys():
		if rel_word in word1_rels and not rel_word in connecting_words:
			connecting_words.append(rel_word)
	
	return connecting_words


func show_associations(clicked_word: String):
	var existing = get_node_or_null("AssociationsPopup")
	if existing:
		existing.queue_free()
	
	var popup = PanelContainer.new()
	popup.name = "AssociationsPopup"
	popup.position = Vector2(50, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.COLORS.button_normal
	style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(300, 0)
	
	# Title
	var title = Label.new()
	title.text = "Connections for '%s'" % clicked_word
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Find connections within selected words
	var word_idx = selected_words.find(clicked_word)
	var connections_found = false
	
	if word_idx != -1:
		# Check previous word
		if word_idx > 0:
			var prev_word = selected_words[word_idx - 1]
			var connection = WordData.find_connecting_words(prev_word, clicked_word)
			if connection.size() > 0:
				var rel_label = Label.new()
				rel_label.text = "• '%s' is connected to '%s' via '%s'\n  %s" % [
					prev_word,
					clicked_word,
					connection[0],  # connecting word
					connection[1]   # explanation
				]
				rel_label.add_theme_font_size_override("font_size", 18)
				rel_label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
				rel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(rel_label)
				connections_found = true
		
		# Check next word
		if word_idx < selected_words.size() - 1:
			var next_word = selected_words[word_idx + 1]
			var connection = WordData.find_connecting_words(clicked_word, next_word)
			if connection.size() > 0:
				var rel_label = Label.new()
				rel_label.text = "• '%s' is connected to '%s' via '%s'\n  %s" % [
					clicked_word,
					next_word,
					connection[0],  # connecting word
					connection[1]   # explanation
				]
				rel_label.add_theme_font_size_override("font_size", 18)
				rel_label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
				rel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(rel_label)
				connections_found = true

	
	if !connections_found:
		var no_rel_label = Label.new()
		no_rel_label.text = "No connecting words found"
		no_rel_label.add_theme_font_size_override("font_size", 18)
		no_rel_label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
		no_rel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_rel_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(100, 40)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = GameTheme.COLORS.primary
	button_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	button_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	button_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	button_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	
	close_button.add_theme_stylebox_override("normal", button_style)
	close_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	close_button.pressed.connect(func(): popup.queue_free())
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_child(close_button)
	vbox.add_child(button_container)
	
	popup.add_child(vbox)
	add_child(popup)
	
	# Center the popup
	await get_tree().process_frame
	popup.position = (get_viewport_rect().size - popup.size) / 2


func style_buttons():
	for button in [$VBoxContainer/PlayAgainButton, $VBoxContainer/MainMenuButton]:
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = GameTheme.COLORS.button_normal
		normal_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
		normal_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
		normal_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
		normal_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = GameTheme.COLORS.primary
		
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", hover_style)
		button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)

func on_play_again_pressed():
	get_parent().change_scene_to("game_scene")

func on_menu_pressed():
	get_parent().change_scene_to("main_menu")
