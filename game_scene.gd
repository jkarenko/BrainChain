extends Control

var available_words = []
var selected_count = 0
var selected_words = []
const MAX_SELECTIONS = 5

func _ready():
    var background = ColorRect.new()
    background.color = GameTheme.COLORS.background
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    move_child(background, 0)
    
    # Get words from 3 random categories to ensure some related words
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

func create_label_style(is_selected: bool = false) -> StyleBoxFlat:
    var label_style = StyleBoxFlat.new()
    label_style.bg_color = GameTheme.COLORS.selected_word if is_selected else GameTheme.COLORS.button_normal
    label_style.corner_radius_top_left = GameTheme.STYLES.corner_radius
    label_style.corner_radius_top_right = GameTheme.STYLES.corner_radius
    label_style.corner_radius_bottom_left = GameTheme.STYLES.corner_radius
    label_style.corner_radius_bottom_right = GameTheme.STYLES.corner_radius
    return label_style

func on_word_selected(button: Button, _position: int, words: Array):
    var parent_row = button.get_parent()
    
    # Create new row with labels instead of buttons
    var selected_row = HBoxContainer.new()
    selected_row.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
    selected_row.add_theme_constant_override("separation", 20)
    
    # Replace the button row with label row
    $WordGrid.add_child(selected_row)
    $WordGrid.move_child(selected_row, parent_row.get_index())
    
    # Create three labels
    for i in range(3):
        var container = CenterContainer.new()
        container.custom_minimum_size = GameTheme.STYLES.button_size
        selected_row.add_child(container)
        
        var label = Label.new()
        label.text = words[i]
        label.custom_minimum_size = GameTheme.STYLES.button_size
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", GameTheme.STYLES.font_size)
        container.add_child(label)
        
        if i == _position:  # Selected word
            label.add_theme_stylebox_override("normal", create_label_style(true))
            label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
            label.pivot_offset = GameTheme.STYLES.button_size / 2
            
            # Animate after adding to scene
            var tween = create_tween()
            tween.tween_property(label, "scale", Vector2(0.9, 0.9), 0.1)
            tween.tween_property(label, "scale", Vector2(1, 1), 0.1)
        else:  # Unselected words
            label.add_theme_stylebox_override("normal", create_label_style(false))
            label.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
            # Fade animation for unselected words
            label.modulate.a = 1
            create_tween().tween_property(label, "modulate:a", 0.5, 0.3)
    
    parent_row.queue_free()
    selected_words.append(words[_position])
    
    selected_count += 1
    if selected_count >= MAX_SELECTIONS:
        game_over()
    else:
        create_word_row(get_random_words(3))


func create_word_row(words: Array):
    var row = HBoxContainer.new()
    row.set_alignment(HBoxContainer.ALIGNMENT_CENTER)
    row.add_theme_constant_override("separation", 20)
    
    # Set initial position for slide-in animation
    row.position.x = 100
    row.modulate.a = 0
    
    $WordGrid.add_child(row)
    
    # Animate row appearance
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
