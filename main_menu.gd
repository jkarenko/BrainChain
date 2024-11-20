extends Control

func _ready():
    style_button($VBoxContainer/StartButton)
    style_button($VBoxContainer/HowToPlayButton)
    style_button($VBoxContainer/GenerateButton)
    $VBoxContainer/Title.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
    $VBoxContainer/StartButton.pressed.connect(on_start_pressed)
    $VBoxContainer/HowToPlayButton.pressed.connect(on_how_to_play_pressed)
    $VBoxContainer/GenerateButton.pressed.connect(on_generate_pressed)
    
    $LoadingPanel.hide()

func style_button(button: Button):
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

func on_start_pressed():
    get_parent().change_scene_to("game_scene")

func on_how_to_play_pressed():
    get_parent().change_scene_to("how_to_play")

func on_generate_pressed():
    $LoadingPanel.show()
    var word_generator = preload("res://word_generator.gd").new()
    add_child(word_generator)
    word_generator.generation_failed.connect(_on_generation_failed)
    word_generator.save_failed.connect(_on_save_failed)
    word_generator.words_saved.connect(_on_words_saved)
    word_generator.generate_daily_words()

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
