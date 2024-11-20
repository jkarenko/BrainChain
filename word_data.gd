extends Node

static var WORD_DATA = {}

func _init():
    load_word_data()

static func load_word_data():
    # Load the JSON file
    var file = FileAccess.open("res://word_data.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        var error = json.parse(file.get_as_text())
        if error == OK:
            WORD_DATA = json.get_data()
        file.close()

static func reload_word_data():
    # Clear existing data
    WORD_DATA.clear()
    # Load fresh data
    load_word_data()

static func get_all_words() -> Array:
    var all_words = []
    if WORD_DATA.is_empty() or not WORD_DATA.has("ROWS"):
        push_error("Word data not properly loaded")
        return []
        
    for row_key in WORD_DATA["ROWS"].keys():
        all_words.append_array(WORD_DATA["ROWS"][row_key]["words"])
    return all_words
