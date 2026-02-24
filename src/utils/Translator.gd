## A wrapper around basic TranslationServer methods.
## The update_translations.gd script collects strings from all Translator methods used across the codebase.
@abstract class_name Translator

static func translate(string: String) -> String:
	return TranslationServer.translate(string)

static func translate_with_object(string: String, object: Translation) -> String:
	return object.get_message(string)
