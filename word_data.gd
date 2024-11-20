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

static func get_relationship_score(word1: String, word2: String) -> Dictionary:
    var instance = Engine.get_main_loop().get_root().get_node_or_null("/root/WordData")
    if instance == null:
        instance = load("res://word_data.gd").new()
    
    # Search through relationships to find connections
    for row_data in WORD_RELATIONSHIPS.values():
        for word_data in row_data:
            if word_data["word"] == word1 and word2 in word_data["related_to"]:
                return {
                    "score": 30,  # Default score for direct relationships
                    "type": word_data["relationship"]
                }
            elif word_data["word"] == word2 and word1 in word_data["related_to"]:
                return {
                    "score": 30,  # Default score for direct relationships
                    "type": word_data["relationship"]
                }
    
    return {
        "score": 0,
        "type": ""
    }

static func get_all_words() -> Array:
    var all_words = []
    for row_key in WORD_CATEGORIES.keys():
        all_words.append_array(WORD_CATEGORIES[row_key])
    return all_words

static func get_words_from_categories(num_categories: int) -> Array:
    var categories = WORD_CATEGORIES.keys()
    categories.shuffle()
    
    var selected_words = []
    for i in range(min(num_categories, categories.size())):
        selected_words.append_array(WORD_CATEGORIES[categories[i]])
    
    return selected_words

static func are_words_related(word1: String, word2: String) -> bool:
    return get_relationship_score(word1, word2).score > 0
