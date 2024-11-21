extends Node

static var WORD_DATA = {}

func _init():
    # Remove file loading since we'll keep data in memory
    pass

static func set_word_data(data: Dictionary):
    WORD_DATA = data

static func get_all_words() -> Array:
    var all_words = []
    if WORD_DATA.is_empty() or not WORD_DATA.has("ROWS"):
        push_error("Word data not properly loaded")
        return []
        
    for row_key in WORD_DATA["ROWS"].keys():
        all_words.append_array(WORD_DATA["ROWS"][row_key]["words"])
    return all_words
