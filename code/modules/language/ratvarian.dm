/datum/language/ratvar
	name = "Ratvarian"
	desc = "A timeless language full of power and incomprehensible to the unenlightened."
	var/static/random_speech_verbs = list("clanks", "clinks", "clunks", "clangs")
	ask_verb = "requests"
	exclaim_verb = "proclaims"
	whisper_verb = "imparts"
	key = "R"
	flags = LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	default_priority = 10
	spans = list(SPAN_ROBOT)
	icon_state = "ratvar"

/datum/language/ratvar/scramble_sentence(input)
	. = text2ratvar(input)
