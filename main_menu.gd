extends Control

func _ready():
    style_button($VBoxContainer/StartButton)
    $VBoxContainer/Title.add_theme_color_override("font_color", GameTheme.COLORS.text_light)
    $VBoxContainer/StartButton.pressed.connect(on_start_pressed)

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
