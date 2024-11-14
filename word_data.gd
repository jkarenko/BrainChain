extends Node

const WORD_CATEGORIES = {
    "animals": ["cat", "dog", "fish", "bird", "mouse", "bear", "lion", "wolf"],
    
    "nature": [
        "tree", "sun", "moon", "star", "leaf", "rock", "lake", "rain",
        "water", "stone", "flower", "cave"
    ],
    
    "buildings": [
        "house", "store", "bank", "school", "tower", "hotel", "farm",
        "station", "port", "shop"
    ],
    
    "vehicles": ["car", "boat", "ship", "train", "plane", "bike", "bus"],
    
    "objects": [
        "book", "pen", "desk", "chair", "lamp", "door", "clock", "key",
        "lock", "bowl", "spoon", "pan", "bone", "shell", "ink", "paper",
        "ball", "beam"
    ],
    
    "food": [
        "bread", "milk", "fish", "cake", "meat", "soup", "rice", "egg",
        "butter", "honey", "cream", "berry"
    ],
    
    "colors": ["blue", "red", "gold", "green", "black", "white", "pink"],
    
    "weather": [
        "rain", "snow", "wind", "storm", "cloud", "fog", "ice",
        "cold", "hot", "air"
    ],
    
    "places": [
        "field", "park", "yard", "kitchen", "room", "land", "mine",
        "track", "way"
    ],
    
    "people": [
        "man", "lady", "mate", "winner"
    ],
    
    "qualities": [
        "high", "wise", "safe", "light", "fire", "head", "eye",
        "mill", "nine"
    ]
}


const WORD_RELATIONSHIPS = {
    # Animals
    "cat": {
        "fish": "strong",
        "mouse": "strong",
        "house": "compound",
        "door": "thematic",
        "milk": "strong",
        "dog": "strong",
        "bird": "strong"
    },
    "dog": {
        "house": "compound",
        "bone": "strong",
        "cat": "strong",
        "bird": "strong"
    },
    "bird": {
        "house": "compound",
        "tree": "strong",
        "dog": "strong",
        "cat": "strong"
    },
    "bear": {
        "fish": "strong",
        "cave": "thematic",
        "honey": "strong",
        "wolf": "thematic"
    },
    "lion": {
        "wolf": "thematic",
        "meat": "strong",
        "cat": "thematic"
    },
    "wolf": {
        "moon": "thematic",
        "meat": "strong",
        "dog": "thematic"
    },
    "mouse": {
        "cat": "strong",
        "house": "thematic",
        "cheese": "strong"
    },
    
    # Nature
    "tree": {
        "leaf": "strong",
        "green": "thematic",
        "rain": "thematic",
        "house": "thematic",
        "top": "compound",
        "bird": "thematic"
    },
    "sun": {
        "moon": "strong",
        "star": "strong",
        "light": "strong",
        "cloud": "thematic",
        "rain": "thematic",
        "flower": "compound"
    },
    "moon": {
        "sun": "strong",
        "star": "strong",
        "light": "strong",
        "beam": "compound",
        "wolf": "thematic"
    },
    "star": {
        "sun": "strong",
        "moon": "strong",
        "light": "strong",
        "fish": "compound"
    },
    "leaf": {
        "tree": "strong",
        "green": "strong",
        "fall": "thematic"
    },
    "rock": {
        "star": "compound",
        "hard": "strong",
        "stone": "strong"
    },
    "lake": {
        "fish": "strong",
        "water": "strong",
        "house": "thematic"
    },

    # Buildings
    "house": {
        "door": "strong",
        "tree": "thematic",
        "car": "thematic",
        "lamp": "thematic",
        "key": "strong",
        "boat": "compound"
    },
    "store": {
        "book": "compound",
        "door": "thematic",
        "shop": "strong"
    },
    "bank": {
        "money": "strong",
        "door": "thematic",
        "safe": "strong"
    },
    "school": {
        "book": "thematic",
        "bus": "compound",
        "house": "compound"
    },
    "tower": {
        "clock": "compound",
        "light": "compound",
        "high": "strong"
    },
    "hotel": {
        "room": "strong",
        "door": "thematic",
        "key": "strong"
    },
    "farm": {
        "house": "compound",
        "yard": "compound",
        "land": "strong"
    },

    # Vehicles
    "car": {
        "door": "strong",
        "key": "thematic",
        "park": "strong",
        "wash": "compound"
    },
    "boat": {
        "house": "compound",
        "water": "strong",
        "lake": "thematic"
    },
    "ship": {
        "water": "strong",
        "yard": "compound",
        "mate": "compound"
    },
    "train": {
        "station": "strong",
        "track": "strong",
        "car": "thematic"
    },
    "plane": {
        "air": "strong",
        "port": "compound",
        "way": "compound"
    },
    "bike": {
        "rack": "compound",
        "way": "compound",
        "ride": "strong"
    },
    "bus": {
        "stop": "compound",
        "school": "compound",
        "station": "strong"
    },

    # Objects
    "book": {
        "pen": "strong",
        "desk": "thematic",
        "store": "compound",
        "lamp": "thematic",
        "shelf": "compound",
        "mark": "compound"
    },
    "pen": {
        "book": "strong",
        "desk": "thematic",
        "ink": "strong"
    },
    "desk": {
        "lamp": "thematic",
        "chair": "strong",
        "book": "thematic"
    },
    "chair": {
        "desk": "strong",
        "rock": "compound",
        "man": "compound"
    },
    "lamp": {
        "light": "strong",
        "desk": "thematic",
        "house": "thematic"
    },
    "door": {
        "key": "strong",
        "house": "strong",
        "way": "compound"
    },
    "clock": {
        "tower": "compound",
        "wise": "compound",
        "work": "compound"
    },
    "key": {
        "door": "strong",
        "lock": "strong",
        "board": "compound"
    },

    # Food
    "fish": {
        "water": "strong",
        "boat": "thematic",
        "lake": "strong",
        "food": "thematic",
        "cat": "strong"
    },
    "bread": {
        "box": "compound",
        "winner": "compound",
        "butter": "strong"
    },
    "milk": {
        "cat": "strong",
        "shake": "compound",
        "man": "compound"
    },
    "cake": {
        "bread": "thematic",
        "walk": "compound",
        "pan": "compound"
    },
    "meat": {
        "ball": "compound",
        "lion": "strong",
        "wolf": "strong"
    },
    "soup": {
        "kitchen": "thematic",
        "bowl": "strong",
        "spoon": "strong"
    },
    "rice": {
        "field": "strong",
        "paper": "compound",
        "cake": "compound"
    },
    "egg": {
        "shell": "strong",
        "plant": "compound",
        "head": "compound"
    },

    # Colors
    "blue": {
        "sky": "strong",
        "water": "thematic",
        "bird": "compound"
    },
    "red": {
        "light": "compound",
        "hot": "compound",
        "fire": "strong"
    },
    "gold": {
        "fish": "compound",
        "star": "thematic",
        "mine": "strong"
    },
    "green": {
        "house": "compound",
        "leaf": "strong",
        "tree": "strong"
    },
    "black": {
        "bird": "compound",
        "board": "compound",
        "berry": "compound"
    },
    "white": {
        "house": "compound",
        "wash": "compound",
        "board": "compound"
    },
    "pink": {
        "eye": "compound",
        "lady": "compound",
        "flower": "thematic"
    },

    # Weather
    "rain": {
        "cloud": "strong",
        "water": "strong",
        "bow": "compound",
        "coat": "compound",
        "drop": "compound"
    },
    "snow": {
        "ball": "compound",
        "man": "compound",
        "fall": "strong"
    },
    "wind": {
        "mill": "compound",
        "fall": "compound",
        "storm": "strong"
    },
    "storm": {
        "cloud": "strong",
        "wind": "strong",
        "rain": "strong"
    },
    "cloud": {
        "rain": "strong",
        "storm": "strong",
        "nine": "compound"
    },
    "fog": {
        "light": "compound",
        "horn": "compound",
        "cloud": "strong"
    },
    "ice": {
        "cream": "compound",
        "berg": "compound",
        "cold": "strong"
    }
}


var _processed_relationships = {}

func _init():
    # Process relationships to make them bidirectional
    _processed_relationships = WORD_RELATIONSHIPS.duplicate(true)
    for word1 in WORD_RELATIONSHIPS:
        for word2 in WORD_RELATIONSHIPS[word1]:
            if not word2 in _processed_relationships:
                _processed_relationships[word2] = {}
            _processed_relationships[word2][word1] = WORD_RELATIONSHIPS[word1][word2]

static func get_relationship_score(word1: String, word2: String) -> Dictionary:
    # Get the singleton instance to access processed relationships
    var instance = Engine.get_main_loop().get_root().get_node_or_null("/root/WordData")
    if instance == null:
        instance = load("res://word_data.gd").new()
    
    var score = 0
    var type = ""
    
    # Check direct relationships first
    if word1 in instance._processed_relationships and word2 in instance._processed_relationships[word1]:
        type = instance._processed_relationships[word1][word2]
    else:
        # Check for common associations
        var common_words = []
        if word1 in instance._processed_relationships and word2 in instance._processed_relationships:
            for related_word in instance._processed_relationships[word1].keys():
                if related_word in instance._processed_relationships[word2]:
                    common_words.append(related_word)
        
        if common_words.size() > 0:
            type = "common"  # They share common associations
    
    match type:
        "compound": score = 40
        "strong": score = 30
        "thematic": score = 20
        "common": score = 10  # Lower score for common association
    
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
