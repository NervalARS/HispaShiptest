/mob/verb/pray(msg as text)
	set category = "IC"
	set name = "Pray"

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."), confidential = TRUE)
		return

	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)
	if(!msg)
		return
	log_prayer("[src.key]/([src.name]): [msg]")
	if(usr.client)
		if(usr.client.prefs.muted & MUTE_PRAY)
			to_chat(usr, span_danger("You cannot pray (muted)."), confidential = TRUE)
			return
		if(src.client.handle_spam_prevention(msg,MUTE_PRAY))
			return

	var/mutable_appearance/cross = mutable_appearance('icons/obj/storage.dmi', "bible")
	var/font_color = "purple"
	var/prayer_type = "PRAYER"
	var/deity
	if(usr.job == "Chaplain")
		cross.icon_state = "kingyellow"
		font_color = "blue"
		prayer_type = "CHAPLAIN PRAYER"
		if(GLOB.deity)
			deity = GLOB.deity
	else if((usr.faction && ("roumain" in usr.faction)))
		font_color = "purple"
		prayer_type = "SRM PRAYER"
		deity = "Ashen Hunter"

	var/msg_tmp = msg
	GLOB.requests.pray(usr.client, msg, usr.job == "Chaplain")
	msg = span_adminnotice("[icon2html(cross, GLOB.admins)]<b><font color=[font_color]>[prayer_type][deity ? " (to [deity])" : ""]: </font>[ADMIN_FULLMONTY(src)] [ADMIN_SC(src)]:</b> [span_linkify("[msg]")]")

	for(var/client/C in GLOB.admins)
		if(C.prefs.chat_toggles & CHAT_PRAYER)
			to_chat(C, msg, confidential = TRUE)
	to_chat(usr, span_info("You pray to the gods: \"[msg_tmp]\""), confidential = TRUE)
	SSredbot.send_discord_message("admin", "Prayer from [src.key]/([src.name]): [msg]")

	BLACKBOX_LOG_ADMIN_VERB("Prayer")

/// Used by communications consoles to message CentCom
/proc/message_centcom(text, mob/sender)
	var/msg = copytext_char(sanitize(text), 1, MAX_MESSAGE_LEN)
	GLOB.requests.message_centcom(sender.client, msg)
	msg = span_adminnotice("<b><font color=orange>CENTCOM:</font>[ADMIN_FULLMONTY(sender)] [ADMIN_CENTCOM_REPLY(sender)]:</b> [msg]")
	to_chat(GLOB.admins, msg, confidential = TRUE)
	for(var/obj/machinery/computer/communications/console in GLOB.machines)
		console.override_cooldown()

/// Used by communications consoles to message the Syndicate
/proc/message_syndicate(text, mob/sender)
	var/msg = copytext_char(sanitize(text), 1, MAX_MESSAGE_LEN)
	GLOB.requests.message_syndicate(sender.client, msg)
	msg = span_adminnotice("<b><font color=crimson>SYNDICATE:</font>[ADMIN_FULLMONTY(sender)] [ADMIN_SYNDICATE_REPLY(sender)]:</b> [msg]")
	to_chat(GLOB.admins, msg, confidential = TRUE)
	for(var/obj/machinery/computer/communications/console in GLOB.machines)
		console.override_cooldown()

/// Used by communications consoles to request the nuclear launch codes
/proc/nuke_request(text, mob/sender)
	var/msg = copytext_char(sanitize(text), 1, MAX_MESSAGE_LEN)
	GLOB.requests.nuke_request(sender.client, msg)
	msg = span_adminnotice("<b><font color=orange>NUKE CODE REQUEST:</font>[ADMIN_FULLMONTY(sender)] [ADMIN_CENTCOM_REPLY(sender)] [ADMIN_SET_SD_CODE]:</b> [msg]")
	to_chat(GLOB.admins, msg, confidential = TRUE)
	for(var/obj/machinery/computer/communications/console in GLOB.machines)
		console.override_cooldown()
