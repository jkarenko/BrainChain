extends Node

static var WORD_CATEGORIES = {}
static var WORD_RELATIONSHIPS = {}

func _init():
    # Load the JSON file
    var file = FileAccess.open("res://word_data.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        var error = json.parse(file.get_as_text())
        if error == OK:
            var data = json.get_data()
            WORD_CATEGORIES = data["WORD_CATEGORIES"]
            WORD_RELATIONSHIPS = data["WORD_RELATIONSHIPS"]
        file.close()

static func find_connecting_words(word1: String, word2: String) -> Array:
    # Search through relationships to find connections
    for row_data in WORD_RELATIONSHIPS.values():
        for word_entry in row_data:
            if word_entry["word"] == word1:
                # Check if word2 is in any of the connecting_words entries
                for connection in word_entry["connecting_words"]:
                    if connection["related_word"] == word2:
                        return [connection["connecting_word"], connection["explanation"]]
            elif word_entry["word"] == word2:
                # Check the reverse direction
                for connection in word_entry["connecting_words"]:
                    if connection["related_word"] == word1:
                        return [connection["connecting_word"], connection["explanation"]]
    
    return []

static func get_all_words() -> Array:
    var all_words = []
    for row_key in WORD_CATEGORIES.keys():
        all_words.append_array(WORD_CATEGORIES[row_key])
    return all_words
