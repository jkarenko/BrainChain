extends Control

var available_words = []
var selected_count = 0
var selected_words = []
const MAX_SELECTIONS = 5
var continue_button: Button
var can_drag = false
var dragged_row = null
var original_pos = Vector2.ZERO

func _ready():
    var background = ColorRect.new()
    background.color = GameTheme.COLORS.background
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    move_child(background, 0)
    
    available_words = preload("res://word_data.gd").get_words_from_categories(3)
    available_words.shuffle()
    setup_first_row()

func get_random_words(count: int) -> Array:
    var words = []
    if available_words.size() < count:
        available_words = preload("res://word_data.gd").get_words_from_categories(3)
        available_words.shuffle()
    for i in range(count):
        words.append(available_words.pop_front())
    return words

func create_button_style(is_hover: bool = false) -> StyleBoxFlat:
    var button_style = StyleBoxFlat.new()
    button_style.bg_color = GameTheme.COLORS.primary if is_hover else GameTheme.COLORS.button_normal
    button_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
    button_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
    button_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
    button_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
    return button_style

func create_selected_row_button(words: Array, selected_index: int) -> Button:
    var button = Button.new()
    
    # Only use the selected word
    button.text = words[selected_index]
    button.custom_minimum_size = Vector2(600, 50)  # Same width as three buttons + spacing
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.mouse_default_cursor_shape = Control.CURSOR_MOVE
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.4, 0.8, 0.8)  # Blue color
    style.corner_radius_top_left = GameTheme.STYLES.corner_radius
    style.corner_radius_top_right = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
    
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_font_size_override("font_size", GameTheme.STYLES.font_size)
    button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    # Add drag functionality
    button.gui_input.connect(func(event): _on_row_gui_input(event, button))
    
    return button

func _on_row_gui_input(event: InputEvent, button: Button):
    if !can_drag:
        return
        
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragged_row = button
                original_pos = button.global_position
                button.modulate.a = 0.5
            else:
                if dragged_row:
                    dragged_row.modulate.a = 1.0
                    var drop_index = _get_closest_row_index(get_global_mouse_position())
                    if drop_index != -1:
                        var current_index = dragged_row.get_index()
                        if current_index != drop_index:
                            $WordGrid.move_child(dragged_row, drop_index)
                            # Update selected_words array
                            var word = selected_words[current_index]
                            selected_words.remove_at(current_index)
                            selected_words.insert(drop_index, word)
                    dragged_row.global_position = original_pos
                dragged_row = null
                
    elif event is InputEventMouseMotion:
        if dragged_row:
            dragged_row.global_position = get_global_mouse_position() - dragged_row.size / 2

func _get_closest_row_index(mouse_pos: Vector2) -> int:
    var closest_index = -1
    var min_distance = INF
    
    for i in range($WordGrid.get_child_count()):
        var child = $WordGrid.get_child(i)
        var distance = abs(child.global_position.y - mouse_pos.y)
        if distance < min_distance:
            min_distance = distance
            closest_index = i
            
    return closest_index

func on_word_selected(button: Button, _position: int, words: Array):
    var parent_row = button.get_parent()
    selected_words.append(words[_position])
    
    var selected_row_button = create_selected_row_button(words, _position)
    $WordGrid.add_child(selected_row_button)
    $WordGrid.move_child(selected_row_button, parent_row.get_index())
    
    parent_row.queue_free()
    
    selected_count += 1
    if selected_count >= MAX_SELECTIONS:
        show_continue_button()
    else:
        create_word_row(get_random_words(3))

func show_continue_button():
    can_drag = true
    continue_button = Button.new()
    continue_button.text = "Continue"
    continue_button.custom_minimum_size = Vector2(200, 60)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.8, 0.2, 0.8)  # Green color
    style.corner_radius_top_left = GameTheme.STYLES.corner_radius
    style.corner_radius_top_right = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
    
    continue_button.add_theme_stylebox_override("normal", style)
    continue_button.add_theme_font_size_override("font_size", 24)
    continue_button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
    continue_button.pressed.connect(game_over)
    
    var container = CenterContainer.new()
    container.custom_minimum_size = Vector2(0, 80)
    container.add_child(continue_button)
    $WordGrid.add_child(container)

func create_word_row(words: Array):
    var row = HBoxContainer.new()
    row.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
    row.add_theme_constant_override("separation", 20)
    
    row.position.x = 100
    row.modulate.a = 0
    
    $WordGrid.add_child(row)
    
    var tween = create_tween()
    tween.tween_property(row, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(row, "modulate:a", 1, 0.3)
    
    for i in range(3):
        var button = Button.new()
        button.text = words[i]
        button.custom_minimum_size = GameTheme.STYLES.button_size
        button.add_theme_stylebox_override("normal", create_button_style())
        button.add_theme_stylebox_override("hover", create_button_style(true))
        button.add_theme_stylebox_override("pressed", create_button_style(true))
        button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
        button.add_theme_font_size_override("font_size", GameTheme.STYLES.font_size)
        button.pressed.connect(func(): on_word_selected(button, i, words))
        row.add_child(button)

func setup_first_row():
    create_word_row(get_random_words(3))

func game_over():
    var end_screen = load("res://end_screen.tscn").instantiate()
    end_screen.set_words(selected_words)
    get_parent().add_child(end_screen)
    queue_free()
