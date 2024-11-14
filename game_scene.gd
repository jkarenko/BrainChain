extends Control

var available_words = []
var selected_count = 0
var selected_words = []
const MAX_SELECTIONS = 5
var continue_button: Button
var can_drag = false
var dragged_row = null
var original_pos = Vector2.ZERO
var row_positions = []

func _ready():
    var background = ColorRect.new()
    background.color = GameTheme.COLORS.background
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    move_child(background, 0)
    
    $WordGrid.add_theme_constant_override("separation", 20)
    
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
    button.text = words[selected_index]
    button.custom_minimum_size = Vector2(600, 100)
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.mouse_default_cursor_shape = Control.CURSOR_MOVE
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.4, 0.8, 0.8)
    style.corner_radius_top_left = GameTheme.STYLES.corner_radius
    style.corner_radius_top_right = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
    style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
    
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_font_size_override("font_size", GameTheme.STYLES.font_size)
    button.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
    button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    button.gui_input.connect(func(event): _on_row_gui_input(event, button))
    button.add_theme_stylebox_override("hover", style)
    
    return button

func _calculate_row_positions():
    row_positions.clear()
    var current_y = 0
    var row_height = 100  # Button height
    var spacing = $WordGrid.get_theme_constant("separation")
    
    for i in range($WordGrid.get_child_count()):
        row_positions.append(current_y)
        current_y += row_height + spacing

func _on_row_gui_input(event: InputEvent, button: Button):
    if !can_drag:
        return
        
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragged_row = button
                original_pos = button.position
                button.modulate.a = 0.5
                button.z_index = 1
                _calculate_row_positions()
            else:
                if dragged_row:
                    dragged_row.modulate.a = 1.0
                    dragged_row.z_index = 0
                    
                    var drop_index = _get_closest_row_index()
                    if drop_index != -1 and drop_index != dragged_row.get_index():
                        var current_index = dragged_row.get_index()
                        $WordGrid.move_child(dragged_row, drop_index)
                        
                        var word = selected_words[current_index]
                        selected_words.remove_at(current_index)
                        selected_words.insert(drop_index, word)
                    
                    _calculate_row_positions()
                    _reset_row_positions()
                dragged_row = null
                
    elif event is InputEventMouseMotion:
        if dragged_row:
            var delta = event.position + button.position
            dragged_row.position.y = delta.y - dragged_row.size.y / 2
            _update_preview_positions()

func _update_preview_positions():
    if !dragged_row:
        return
        
    var target_index = _get_closest_row_index()
    var current_index = dragged_row.get_index()
    
    _calculate_row_positions()
    for i in range($WordGrid.get_child_count()):
        var child = $WordGrid.get_child(i)
        if child == dragged_row or child is CenterContainer:
            continue
            
        var target_pos = row_positions[i]
        
        if target_index != current_index:
            if target_index > current_index:
                if i > current_index and i <= target_index:
                    target_pos = row_positions[i - 1]
            else:
                if i >= target_index and i < current_index:
                    target_pos = row_positions[i + 1]
                    
        child.get_tree().create_tween().kill()
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(child, "position:y", target_pos, 0.2)

func _reset_row_positions():
    _calculate_row_positions()
    for i in range($WordGrid.get_child_count()):
        var child = $WordGrid.get_child(i)
        if child is CenterContainer:
            continue
            
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(child, "position:y", row_positions[i], 0.2)

func _get_closest_row_index() -> int:
    var local_y = $WordGrid.get_local_mouse_position().y
    var row_height = 100 # Button height
    var spacing = $WordGrid.get_theme_constant("separation")
    var total_height = row_height + spacing
    
    # Calculate the row index based on position relative to row centers
    var index = floor(local_y / total_height)
    
    # Clamp to valid range
    return clampi(index, 0, row_positions.size() - 1)

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
