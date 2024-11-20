extends Node

static var WORD_CATEGORIES = {}
static var WORD_RELATIONSHIPS = {}
static var _processed_relationships = {}

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
    # Process relationships to make them bidirectional
    _processed_relationships = WORD_RELATIONSHIPS.duplicate(true)
    for word1 in WORD_RELATIONSHIPS:
        for word2 in WORD_RELATIONSHIPS[word1]:
            if not word2 in _processed_relationships:
                _processed_relationships[word2] = {}
            _processed_relationships[word2][word1] = WORD_RELATIONSHIPS[word1][word2]

static func get_relationship_score(word1: String, word2: String) -> Dictionary:
    var instance = Engine.get_main_loop().get_root().get_node_or_null("/root/WordData")
    if instance == null:
        instance = load("res://word_data.gd").new()
    
    var score = 0
    var type = ""
    
    if word1 in _processed_relationships and word2 in _processed_relationships[word1]:
        type = _processed_relationships[word1][word2]
    else:
        var common_words = []
        if word1 in _processed_relationships and word2 in _processed_relationships:
            for related_word in _processed_relationships[word1].keys():
                if related_word in _processed_relationships[word2]:
                    common_words.append(related_word)
        
        if common_words.size() > 0:
            type = "common"
    
    match type:
        "compound": score = 40
        "strong": score = 30
        "thematic": score = 20
        "common": score = 10
    
    return {
        "score": score,
        "type": type
    }

static func get_all_words() -> Array:
    var all_words = []
    for category in WORD_CATEGORIES.values():
        all_words.append_array(category)
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
