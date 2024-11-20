extends Node

signal generation_completed(data: Dictionary)
signal generation_failed(error: String)
signal words_saved
signal save_failed(error: String)

const API_URL = "https://api.openai.com/v1/chat/completions"
var api_key: String

var http_request: HTTPRequest

func _ready():
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)
    _load_api_key()
    
    # Connect signals to internal handlers
    generation_completed.connect(_on_generation_completed)
    generation_failed.connect(_on_generation_failed)
    save_failed.connect(_on_save_failed)

func _load_api_key():
    var file = FileAccess.open("res://openai_api_key.txt", FileAccess.READ)
    if file:
        api_key = file.get_as_text().strip_edges()
        file.close()
    else:
        push_error("Failed to load OpenAI API key from openai_api_key.txt")

func generate_daily_words():
    if api_key.is_empty():
        emit_signal("generation_failed", "API key not loaded")
        return
        
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + api_key
    ]
    
    var prompt = """
    Create five rows of 3 words. The 3 words in a row must have a common prefix or suffix and the player's goal is to guess the prefix or suffix.
    
    Examples where the connecting word is in parentheses. Only the word after the parentheses should be used:
    
    (night)gown
    (night)club
    (night)light

    (foot)note
    (foot)ball
    (foot)bridge

    (paper)plate
    (paper)plane
    (paper)clip

    (sun)flower
    (sun)shine
    (sun)set

    (door)bell
    (door)handle
    (door)knob
    """
    
    var body = {
        "model": "gpt-4o",
        "messages": [
            {
                "role": "system",
                "content": "You are a word expert that creates words with common prefixes or suffixes."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "word_chain_schema",
                "schema": {
                    "type": "object",
                    "properties": {
                        "WORD_CATEGORIES": {
                            "type": "object",
                            "properties": {
                                "row1": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 3
                                },
                                "row2": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 3
                                },
                                "row3": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 3
                                },
                                "row4": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 3
                                },
                                "row5": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 3
                                }
                            },
                            "required": ["row1", "row2", "row3", "row4", "row5"]
                        },
                        "WORD_RELATIONSHIPS": {
                            "type": "object",
                            "properties": {
                                "row1": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "word": {"type": "string"},
                                            "connecting_words": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "connecting_word": {"type": "string"},
                                                        "related_word": {"type": "string"},
                                                        "explanation": {
                                                            "type": "string",
                                                            "description": "Explains how both words connect through the connecting_word"
                                                        }
                                                    },
                                                    "required": ["connecting_word", "related_word", "explanation"]
                                                }
                                            }
                                        },
                                        "required": ["word", "connecting_words"]
                                    }
                                },
                                "row2": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "word": {"type": "string"},
                                            "connecting_words": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "connecting_word": {"type": "string"},
                                                        "related_word": {"type": "string"},
                                                        "explanation": {
                                                            "type": "string",
                                                            "description": "Explains how both words connect through the connecting_word"
                                                        }
                                                    },
                                                    "required": ["connecting_word", "related_word", "explanation"]
                                                }
                                            }
                                        },
                                        "required": ["word", "connecting_words"]
                                    }
                                },
                                "row3": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "word": {"type": "string"},
                                            "connecting_words": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "connecting_word": {"type": "string"},
                                                        "related_word": {"type": "string"},
                                                        "explanation": {
                                                            "type": "string",
                                                            "description": "Explains how both words connect through the connecting_word"
                                                        }
                                                    },
                                                    "required": ["connecting_word", "related_word", "explanation"]
                                                }
                                            }
                                        },
                                        "required": ["word", "connecting_words"]
                                    }
                                },
                                "row4": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "word": {"type": "string"},
                                            "connecting_words": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "connecting_word": {"type": "string"},
                                                        "related_word": {"type": "string"},
                                                        "explanation": {
                                                            "type": "string",
                                                            "description": "Explains how both words connect through the connecting_word"
                                                        }
                                                    },
                                                    "required": ["connecting_word", "related_word", "explanation"]
                                                }
                                            }
                                        },
                                        "required": ["word", "connecting_words"]
                                    }
                                },
                                "row5": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "word": {"type": "string"},
                                            "connecting_words": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "connecting_word": {"type": "string"},
                                                        "related_word": {"type": "string"},
                                                        "explanation": {
                                                            "type": "string",
                                                            "description": "Explains how both words connect through the connecting_word"
                                                        }
                                                    },
                                                    "required": ["connecting_word", "related_word", "explanation"]
                                                }
                                            }
                                        },
                                        "required": ["word", "connecting_words"]
                                    }
                                }
                            },
                            "required": ["row1", "row2", "row3", "row4", "row5"]
                        }
                    },
                    "required": ["WORD_CATEGORIES", "WORD_RELATIONSHIPS"]
                }
            }
        },
        "temperature": 0.9,
        "max_tokens": 5000
    }
    
    var error = http_request.request(
        API_URL,
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(body)
    )
    
    if error != OK:
        emit_signal("generation_failed", "HTTP Request failed")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS:
        emit_signal("generation_failed", "Request failed with result: " + str(result))
        return
    
    if response_code != 200:
        emit_signal("generation_failed", "API returned error code: " + str(response_code) + "\n" + body.get_string_from_utf8())
        return
    
    var json = JSON.new()
    var error = json.parse(body.get_string_from_utf8())
    
    if error != OK:
        print("Raw response: ", body.get_string_from_utf8())
        emit_signal("generation_failed", "Failed to parse JSON response: " + json.get_error_message())
        return
    
    var response = json.get_data()
    
    if "choices" not in response or response.choices.is_empty():
        emit_signal("generation_failed", "No choices in response")
        return
    
    var content = response.choices[0].message.content
    print("GPT Response content: ", content)  # Debug output
    
    # Parse the generated JSON content
    error = json.parse(content)
    if error != OK:
        print("Failed to parse content: ", content)
        emit_signal("generation_failed", "Failed to parse generated content: " + json.get_error_message())
        return
    
    var word_data = json.get_data()
    
    # Validate the structure
    if not _validate_word_data(word_data):
        print("Invalid word data structure: ", word_data)
        emit_signal("generation_failed", "Generated data has invalid structure")
        return
    
    emit_signal("generation_completed", word_data)

func _validate_word_data(data: Dictionary) -> bool:
    if not data.has_all(["WORD_CATEGORIES", "WORD_RELATIONSHIPS"]):
        print("Missing required keys in data: ", data.keys())
        return false
    
    var categories = data["WORD_CATEGORIES"]
    if not categories is Dictionary:
        print("WORD_CATEGORIES is not a dictionary: ", typeof(categories))
        return false
    
    var relationships = data["WORD_RELATIONSHIPS"]
    if not relationships is Dictionary:
        print("WORD_RELATIONSHIPS is not a dictionary: ", typeof(relationships))
        return false
    
    # Validate that all categories contain arrays
    for category_name in categories.keys():
        if not categories[category_name] is Array:
            print("Category ", category_name, " is not an array")
            return false
    
    # Validate relationships structure
    # for word1 in relationships.keys():
    #     if not relationships[word1] is Dictionary:
    #         print("Relationship for ", word1, " is not a dictionary")
    #         return false
    #     for word2 in relationships[word1].keys():
    #         var rel_type = relationships[word1][word2]
    #         if not rel_type in ["strong", "thematic", "compound"]:
    #             print("Invalid relationship type: ", rel_type)
    #             return false
    
    return true

# Example usage:
func generate_and_save_words():
    # Check if word_data.json exists and was created today
    if FileAccess.file_exists("res://word_data.json"):
        var file_info = FileAccess.get_modified_time("res://word_data.json")
        var current_date = Time.get_datetime_dict_from_system()
        var file_date = Time.get_datetime_dict_from_unix_time(file_info)
        print("File modified: ", file_date)
        print("Current date: ", current_date)

        # Check if file was created today
        if file_date.year == current_date.year and \
           file_date.month == current_date.month and \
           file_date.day == current_date.day:
            # File exists and was created today, no need to generate new words
            emit_signal("words_saved")
            return
    
    # File doesn't exist or wasn't created today, generate new words
    generate_daily_words()

func _on_generation_completed(data: Dictionary):
    # Save to file
    var file = FileAccess.open("res://word_data.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "  "))
        file.close()
        emit_signal("words_saved")
    else:
        emit_signal("save_failed", "Could not open word_data.json for writing")

func _on_generation_failed(error: String):
    print("Generation failed: ", error) 

func _on_save_failed(error: String):
    push_error("Save failed: " + error)

func generate_and_wait() -> Dictionary:
    generate_daily_words()
    await words_saved
    # Reload the word data
    var file = FileAccess.open("res://word_data.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        var error = json.parse(file.get_as_text())
        if error == OK:
            return json.get_data()
        file.close()
    return {} 
