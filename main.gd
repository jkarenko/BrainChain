# main.gd
extends Node

func _ready():
    change_scene_to("main_menu")

func change_scene_to(scene_name: String):
    # Remove current scene
    var current_scene = get_child(0) if get_child_count() > 0 else null
    if current_scene:
        current_scene.queue_free()
    
    # Load and add new scene
    var scene_path = "res://" + scene_name + ".tscn"
    var new_scene = load(scene_path).instantiate()
    add_child(new_scene)
