# This changes a few things about the SVG TextEdit to make it nicer to use.
extends BetterTextEdit

# I'd prefer to block non-ASCII inputs. SVG syntax is ASCII only, and while
# text blocks and comments allow non-ASCII, they are still difficult to deal with
# because they are two bytes long. <text> tags make the situation a whole lot harder,
# but for now they are not supported. Maybe in some future version I'll have them
# be translated directly into paths or have an abstraction over them, I don't know.
# Either way, not planning to support UTF-8, so I block it if the user tries to type it.
func _handle_unicode_input(unicode_char: int, caret_index: int) -> void:
	if unicode_char <= 127:
		insert_text_at_caret(char(unicode_char), caret_index)
