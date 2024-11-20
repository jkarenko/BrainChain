extends Control

var available_words = []
var selected_count = 0
var guessed_words = []
const MAX_SELECTIONS = 5
var current_row_index = 0  # Track which row we're on
var current_prefix = ""
var current_connecting_word = ""

func _ready():
	var background = ColorRect.new()
	background.color = GameTheme.COLORS.background
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	
	$WordGrid.add_theme_constant_override("separation", 20)
	
	# Force reload of word data to ensure we have the latest version
	WordData.reload_word_data()
	
	# Initialize game with words from all rows
	available_words = []
	if WordData.WORD_DATA.is_empty() or not WordData.WORD_DATA.has("ROWS"):
		push_error("Word data not properly loaded")
		return
		
	setup_first_row()

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
	input.placeholder_text = "Type the common prefix..."
	input.custom_minimum_size = Vector2(300, 50)
	input.add_theme_font_size_override("font_size", 20)
	input.text_submitted.connect(func(text): check_guess(text, container, words))
	input.call_deferred("grab_focus")
	
	input_container.add_child(input)
	container.add_child(input_container)

func check_guess(guess: String, container: Node, words: Array):
	var input = container.get_node("InputContainer/Input")
	var word_row = container.get_node("WordRow")
	
	# Don't process input if we're already at max selections
	if selected_count >= MAX_SELECTIONS:
		return
		
	# Disable input immediately after submission
	input.editable = false
	
	if guess.to_lower() == current_connecting_word.to_lower():
		# Correct guess
		guessed_words.append(guess)
		
		# Turn the row green
		for box in word_row.get_children():
			var style = box.get_theme_stylebox("panel")
			style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Green color
		
		selected_count += 1
		if selected_count >= MAX_SELECTIONS:
			show_main_menu_button()
		else:
			create_word_row(get_next_row_words())
	else:
		# Wrong guess - turn words red
		for box in word_row.get_children():
			var style = box.get_theme_stylebox("panel")
			style.bg_color = Color(0.8, 0.2, 0.2, 0.8)  # Red color
		
		# Wait a moment, then continue with next row
		await get_tree().create_timer(1.0).timeout
		
		selected_count += 1
		if selected_count >= MAX_SELECTIONS:
			show_main_menu_button()
		else:
			create_word_row(get_next_row_words())

func show_main_menu_button():
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(200, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Green color
	style.corner_radius_top_left = GameTheme.STYLES.corner_radius
	style.corner_radius_top_right = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
	style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
	
	main_menu_button.add_theme_stylebox_override("normal", style)
	main_menu_button.add_theme_font_size_override("font_size", 24)
	main_menu_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
	main_menu_button.pressed.connect(return_to_main_menu)
	
	var container = CenterContainer.new()
	container.custom_minimum_size = Vector2(0, 80)
	container.add_child(main_menu_button)
	$WordGrid.add_child(container)

func return_to_main_menu():
	get_parent().change_scene_to("main_menu")

func setup_first_row():
	create_word_row(get_next_row_words())
