extends Control

signal return_to_main_menu
signal new_game_requested

var available_words = []
var selected_count = 0
var guessed_words = []
const MAX_SELECTIONS = 5
var current_row_index = 0  # Track which row we're on
var current_prefix = ""
var current_connecting_word = ""

func _ready():
	# Add loading panel
	var loading_panel = preload("res://loading_panel.tscn").instantiate()
	loading_panel.name = "LoadingPanel"
	add_child(loading_panel)
	loading_panel.hide()
	
	# Add signal connections at the start of _ready
	if not is_connected("return_to_main_menu", Callable(get_parent(), "change_scene_to").bind("main_menu")):
		connect("return_to_main_menu", Callable(get_parent(), "change_scene_to").bind("main_menu"))
	
	if not is_connected("new_game_requested", Callable(get_parent(), "change_scene_to").bind("game_scene")):
		connect("new_game_requested", Callable(get_parent(), "change_scene_to").bind("game_scene"))
	
	var background = ColorRect.new()
	background.color = GameTheme.COLORS.background
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	
	$WordGrid.add_theme_constant_override("separation", 20)
	
	# Always generate new words when starting a game
	$LoadingPanel.show()
	var word_generator = preload("res://word_generator.gd").new()
	add_child(word_generator)
	word_generator.generation_failed.connect(_on_generation_failed)
	word_generator.save_failed.connect(_on_save_failed)
	word_generator.words_saved.connect(_on_words_saved)
	word_generator.generate_and_save_words()

# Rename function to match its purpose
func show_end_game_buttons():
	var button_container = HBoxContainer.new()
	button_container.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
	button_container.add_theme_constant_override("separation", 20)
	
	# Create New Game button
	var new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.custom_minimum_size = Vector2(200, 60)
	
	var new_game_style = StyleBoxFlat.new()
	new_game_style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Green color
	new_game_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	new_game_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	new_game_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	new_game_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	
	new_game_button.add_theme_stylebox_override("normal", new_game_style)
	new_game_button.add_theme_font_size_override("font_size", 24)
	new_game_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	new_game_button.pressed.connect(_on_new_game_pressed)
	
	# Create Main Menu button
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(200, 60)
	
	var main_menu_style = StyleBoxFlat.new()
	main_menu_style.bg_color = Color(0, 0.4, 0.8, 0.8)  # Blue color
	main_menu_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	main_menu_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	main_menu_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	main_menu_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	
	main_menu_button.add_theme_stylebox_override("normal", main_menu_style)
	main_menu_button.add_theme_font_size_override("font_size", 24)
	main_menu_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Add buttons to container
	button_container.add_child(new_game_button)
	button_container.add_child(main_menu_button)
	
	# Create wrapper for vertical spacing
	var container = CenterContainer.new()
	container.custom_minimum_size = Vector2(0, 80)
	container.add_child(button_container)
	$WordGrid.add_child(container)

func _create_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _on_new_game_pressed():
	# Clear existing rows
	for child in $WordGrid.get_children():
		child.queue_free()
	
	# Reset game state
	selected_count = 0
	current_row_index = 0
	guessed_words.clear()
	
	# Generate new words
	$LoadingPanel.show()
	var word_generator = preload("res://word_generator.gd").new()
	add_child(word_generator)
	word_generator.generation_failed.connect(_on_generation_failed)
	word_generator.save_failed.connect(_on_save_failed)
	word_generator.words_saved.connect(_on_words_saved)
	word_generator.generate_and_save_words()

func _on_generation_failed(error: String):
	push_error("Failed to generate words: " + error)
	$LoadingPanel.hide()
	# TODO: Show error dialog

func _on_save_failed(error: String):
	push_error("Failed to save words: " + error)
	$LoadingPanel.hide()
	# TODO: Show error dialog

func _on_words_saved():
	$LoadingPanel.hide()
	# Instead of reloading the scene, just start the game
	setup_first_row()

func _on_main_menu_pressed():
	emit_signal("return_to_main_menu")

func get_next_row_words() -> Array:
	if WordData.WORD_DATA.is_empty() or not WordData.WORD_DATA.has("ROWS"):
			push_error("Word data not properly loaded")
			return []
		
	var rows = WordData.WORD_DATA["ROWS"]
	var row_keys = rows.keys()
	
	# Check if we've used all rows
	if current_row_index >= row_keys.size():
		push_error("No more rows available")
		return []
	
	# Get the current row
	var row_key = row_keys[current_row_index]
	var row_data = rows[row_key]
	
	# Store the connecting word (prefix) for this set
	current_connecting_word = row_data["prefix"]
	
	# Increment for next time
	current_row_index += 1
	
	# Return the words for this row
	return row_data["words"]

func create_word_box(text: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.COLORS.button_normal
	style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = GameTheme.STYLES.button_size
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GameTheme.STYLES.font_size)
	label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	
	panel.add_child(label)
	return panel

func create_word_row(words: Array):
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Give names to our containers for easier reference
	var row = HBoxContainer.new()
	row.name = "WordRow"
	row.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
	row.add_theme_constant_override("separation", 20)
	
	container.position.x = 100
	container.modulate.a = 0
	
	$WordGrid.add_child(container)
	container.add_child(row)
	
	var tween = create_tween()
	tween.tween_property(container, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(container, "modulate:a", 1, 0.3)
	
	# Add word boxes
	for word in words:
		var box = create_word_box(word)
		row.add_child(box)
	
	# Add input field
	var input_container = HBoxContainer.new()
	input_container.name = "InputContainer"
	input_container.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
	
	var input = LineEdit.new()
	input.name = "Input"
	input.placeholder_text = "Type the common morpheme..."
	input.custom_minimum_size = Vector2(300, 50)
	input.add_theme_font_size_override("font_size", 20)
	input.text_submitted.connect(func(text): check_guess(text, container, words))
	input.call_deferred("grab_focus")
	
	input_container.add_child(input)
	container.add_child(input_container)

func check_guess(guess: String, container: Node, words: Array):
	var input = container.get_node("InputContainer/Input")
	var word_row = container.get_node("WordRow")
	var input_container = container.get_node("InputContainer")
	
	# Don't process input if we're already at max selections
	if selected_count >= MAX_SELECTIONS:
		return
		
	# Disable input immediately after submission
	input.editable = false
	
	# Create result label to replace input
	var result_label = Label.new()
	result_label.text = current_connecting_word
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	
	if guess.to_lower() == current_connecting_word.to_lower():
		# Correct guess
		guessed_words.append(guess)
		result_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Green
		
		# Turn the row green
		for box in word_row.get_children():
			var style = box.get_theme_stylebox("panel")
			style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Green color
		
		selected_count += 1
		if selected_count >= MAX_SELECTIONS:
			show_end_game_buttons()
		else:
			create_word_row(get_next_row_words())
	else:
		# Wrong guess
		result_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) # Red
		
		# Turn words red
		for box in word_row.get_children():
			var style = box.get_theme_stylebox("panel")
			style.bg_color = Color(0.8, 0.2, 0.2, 0.8)  # Red color
		
		# Wait a moment, then continue with next row
		await get_tree().create_timer(1.0).timeout
		
		selected_count += 1
		if selected_count >= MAX_SELECTIONS:
			show_end_game_buttons()
		else:
			create_word_row(get_next_row_words())
	
	# Replace input with result label
	input.queue_free()
	input_container.add_child(result_label)

func setup_first_row():
	create_word_row(get_next_row_words())
