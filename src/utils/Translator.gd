# A wrapper around basic TranslationServer methods. There is an update_translations script
# which checks all Translator methods used across the codebase to collect their strings.
@abstract class_name Translator

static func translate(string: String) -> String:
	return TranslationServer.translate(string)
