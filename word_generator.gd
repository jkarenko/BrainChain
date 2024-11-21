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
    Create five rows of 3 words. The 3 words in a row must have a common morpheme and the player's goal is to guess the morpheme.

    Examples of triplets with common morphemes:
    
    night
    -gown
    -club
    -light

    foot
    -note
    club-
    -bridge

    paper
    -plate
    -plane
    -clip

    light
    -weight
    night-
    sun-

    door
    -bell
    back-
    -knob

    Make sure the words are challenging to guess - they should not be obvious.
    """
    
    var body = {
        "model": "gpt-4o",
        "messages": [
            {
                "role": "system",
                "content": "You are a word expert that creates compound words with common morphemes."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "word_prefix_game_schema",
                "schema": {
                    "type": "object",
                    "properties": {
                    "ROWS": {
                        "type": "object",
                        "properties": {
                        "row1": {
                            "type": "object",
                            "properties": {
                            "prefix": { "type": "string" },
                            "words": {
                                "type": "array",
                                "items": { "type": "string" },
                                "minItems": 3,
                                "maxItems": 3
                            }
                            },
                            "required": ["prefix", "words"]
                        },
                        "row2": {
                            "type": "object",
                            "properties": {
                            "prefix": { "type": "string" },
                            "words": {
                                "type": "array",
                                "items": { "type": "string" },
                                "minItems": 3,
                                "maxItems": 3
                            }
                            },
                            "required": ["prefix", "words"]
                        },
                        "row3": {
                            "type": "object",
                            "properties": {
                            "prefix": { "type": "string" },
                            "words": {
                                "type": "array",
                                "items": { "type": "string" },
                                "minItems": 3,
                                "maxItems": 3
                            }
                            },
                            "required": ["prefix", "words"]
                        },
                        "row4": {
                            "type": "object",
                            "properties": {
                            "prefix": { "type": "string" },
                            "words": {
                                "type": "array",
                                "items": { "type": "string" },
                                "minItems": 3,
                                "maxItems": 3
                            }
                            },
                            "required": ["prefix", "words"]
                        },
                        "row5": {
                            "type": "object",
                            "properties": {
                            "prefix": { "type": "string" },
                            "words": {
                                "type": "array",
                                "items": { "type": "string" },
                                "minItems": 3,
                                "maxItems": 3
                            }
                            },
                            "required": ["prefix", "words"]
                        }
                        },
                        "required": ["row1", "row2", "row3", "row4", "row5"]
                    }
                    },
                    "required": ["ROWS"]
                }
            }
        },
        "temperature": 1.2,
        "max_tokens": 1000
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
    if not data.has("ROWS"):
        print("Missing ROWS key in data: ", data.keys())
        return false
    
    var rows = data["ROWS"]
    if not rows is Dictionary:
        print("ROWS is not a dictionary: ", typeof(rows))
        return false
    
    # Validate each row has the required structure
    for row_key in rows.keys():
        var row = rows[row_key]
        if not row is Dictionary:
            print("Row ", row_key, " is not a dictionary")
            return false
        if not row.has_all(["prefix", "words"]):
            print("Row ", row_key, " missing required keys")
            return false
        if not row["words"] is Array:
            print("Words in row ", row_key, " is not an array")
            return false
        if row["words"].size() != 3:
            print("Row ", row_key, " does not have exactly 3 words")
            return false
    
    return true

# Example usage:
func generate_and_save_words():
    # Check if word_data.json exists and was created today
    # if FileAccess.file_exists("res://word_data.json"):
    #     var file_info = FileAccess.get_modified_time("res://word_data.json")
    #     var current_date = Time.get_datetime_dict_from_system()
    #     var file_date = Time.get_datetime_dict_from_unix_time(file_info)
    #     print("File modified: ", file_date)
    #     print("Current date: ", current_date)

        # Check if file was created today
        # if file_date.year == current_date.year and \
        #    file_date.month == current_date.month and \
        #    file_date.day == current_date.day:
        #     # File exists and was created today, no need to generate new words
        #     emit_signal("words_saved")
        #     return
    
    # File doesn't exist or wasn't created today, generate new words
    generate_daily_words()

func _on_generation_completed(data: Dictionary):
    print("Generation completed with data: ", data)
    # Process the words to remove prefixes
    var processed_data = data.duplicate(true)
    for row_key in processed_data["ROWS"].keys():
        var row = processed_data["ROWS"][row_key]
        var prefix = row["prefix"]
        var words = row["words"]
        
        # Process each word to remove the prefix and hyphen
        for i in range(words.size()):
            var word = words[i]
            # Remove prefix if it's at the start (case: -word)
            if word.begins_with("-"):
                words[i] = word.substr(1)  # Remove hyphen
                if words[i].begins_with(prefix):  # Also remove prefix if present
                    words[i] = words[i].substr(prefix.length())
            # Remove prefix if it's at the end (case: word-)
            elif word.ends_with("-"):
                words[i] = word.substr(0, word.length() - 1)  # Remove hyphen
                if words[i].ends_with(prefix):  # Also remove prefix if present
                    words[i] = words[i].substr(0, words[i].length() - prefix.length())
            # Handle case where prefix is in the middle (case: word-word)
            elif "-" in word:
                var parts = word.split("-")
                if parts.size() == 2:
                    # Take the part that isn't the prefix
                    if parts[0] == prefix:
                        words[i] = parts[1]
                    elif parts[1] == prefix:
                        words[i] = parts[0]
                    else:
                        # If neither part is the prefix, take the second part
                        words[i] = parts[1]
    
    print("Processed data: ", processed_data)
    
    # Instead of saving to file, store in memory
    WordData.set_word_data(processed_data)
    emit_signal("words_saved")

func _on_generation_failed(error: String):
    print("Generation failed: ", error) 

func _on_save_failed(error: String):
    push_error("Save failed: " + error)

func generate_and_wait() -> Dictionary:
    generate_daily_words()
    await words_saved
    return WordData.WORD_DATA
