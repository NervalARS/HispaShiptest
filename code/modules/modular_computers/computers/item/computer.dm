// This is the base type that does all the hardware stuff.
// Other types expand it - tablets use a direct subtypes, and
// consoles and laptops use "procssor" item that is held inside machinery piece
/obj/item/modular_computer
	name = "modular microcomputer"
	desc = "A small portable microcomputer."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "laptop"
	integrity_failure = 0.5
	max_integrity = 100
	armor = list("melee" = 0, "bullet" = 20, "laser" = 20, "energy" = 100, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 0, "acid" = 0)

	light_system = MOVABLE_LIGHT_DIRECTIONAL
	light_range = 2.3
	light_power = 0.6
	light_color = "#FFFFFF"
	light_on = FALSE

	var/enabled = 0											// Whether the computer is turned on.
	var/screen_on = 1										// Whether the computer is active/opened/it's screen is on.
	var/device_theme = "ntos"								// Sets the theme for the main menu, hardware config, and file browser apps. Overridden by certain non-NT devices.
	var/datum/computer_file/program/active_program = null	// A currently active program running on the computer.
	var/hardware_flag = 0									// A flag that describes this device type
	var/last_power_usage = 0
	var/last_battery_percent = 0							// Used for deciding if battery percentage has chandged
	var/last_world_time = "00:00"
	var/list/last_header_icons

	var/base_active_power_usage = 50						// Power usage when the computer is open (screen is active) and can be interacted with. Remember hardware can use power too.
	var/base_idle_power_usage = 5							// Power usage when the computer is idle and screen is off (currently only applies to laptops)

	// Modular computers can run on various devices. Each DEVICE (Laptop, Console, Tablet,..)
	// must have it's own DMI file. Icon states must be called exactly the same in all files, but may look differently
	// If you create a program which is limited to Laptops and Consoles you don't have to add it's icon_state overlay for Tablets too, for example.

	var/icon_state_unpowered = null							// Icon state when the computer is turned off.
	var/icon_state_powered = null							// Icon state when the computer is turned on.
	var/icon_state_menu = "menu"							// Icon state overlay when the computer is turned on, but no program is loaded that would override the screen.
	var/display_overlays = TRUE								// If FALSE, don't draw overlays on this device at all
	var/max_hardware_size = 0								// Maximal hardware w_class. Tablets/PDAs have 1, laptops 2, consoles 4.
	var/steel_sheet_cost = 5								// Amount of steel sheets refunded when disassembling an empty frame of this computer.

	// Important hardware (must be installed for computer to work)

	// Optional hardware (improves functionality, but is not critical for computer to work)

	var/list/all_components = list()						// List of "connection ports" in this computer and the components with which they are plugged

	var/list/idle_threads							// Idle programs on background. They still receive process calls but can't be interacted with.
	var/obj/physical = null									// Object that represents our computer. It's used for Adjacent() and UI visibility checks.

	/// If the computer has a flashlight/LED light/what-have-you installed
	var/has_light = FALSE


/obj/item/modular_computer/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	if(!physical)
		physical = src
	idle_threads = list()
	update_appearance()


/obj/item/modular_computer/Destroy()
	kill_program(forced = TRUE)
	STOP_PROCESSING(SSobj, src)
	for(var/H in all_components)
		var/obj/item/computer_hardware/CH = all_components[H]
		if(CH.holder == src)
			CH.on_remove(src)
			CH.holder = null
			all_components.Remove(CH.device_type)
			qdel(CH)
	physical = null
	return ..()

/obj/item/modular_computer/AltClick(mob/user)
	..()
	if(issilicon(user))
		return

	if(user.canUseTopic(src, BE_CLOSE))
		var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
		if(card_slot)
			card_slot.try_eject(null, user)

// Gets IDs/access levels from card slot. Would be useful when/if PDAs would become modular PCs.
/obj/item/modular_computer/GetAccess()
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	if(card_slot)
		return card_slot.GetAccess()
	return ..()

/obj/item/modular_computer/GetID()
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	if(card_slot)
		return card_slot.GetID()
	return ..()

/obj/item/modular_computer/RemoveID()
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	if(!card_slot)
		return
	return card_slot.RemoveID()

/obj/item/modular_computer/InsertID(obj/item/inserting_item)
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	if(!card_slot)
		return FALSE
	var/obj/item/card/inserting_id = inserting_item.RemoveID()
	if(!inserting_id)
		return FALSE
	return card_slot.try_insert(inserting_id)

/obj/item/modular_computer/MouseDrop(obj/over_object, src_location, over_location)
	var/mob/M = usr
	if((!istype(over_object, /atom/movable/screen)) && usr.canUseTopic(src, BE_CLOSE))
		return attack_self(M)
	return ..()

/obj/item/modular_computer/attack_ai(mob/user)
	return attack_self(user)

/obj/item/modular_computer/attack_ghost(mob/dead/observer/user)
	. = ..()
	if(.)
		return
	if(enabled)
		ui_interact(user)
	else if(isAdminGhostAI(user))
		var/response = alert(user, "This computer is turned off. Would you like to turn it on?", "Admin Override", "Yes", "No")
		if(response == "Yes")
			turn_on(user)

/obj/item/modular_computer/emag_act(mob/user)
	if(!enabled)
		to_chat(user, span_warning("You'd need to turn the [src] on first."))
		return FALSE
	obj_flags |= EMAGGED //Mostly for consistancy purposes; the programs will do their own emag handling
	var/newemag = FALSE
	var/obj/item/computer_hardware/hard_drive/drive = all_components[MC_HDD]
	for(var/datum/computer_file/program/app in drive.stored_files)
		if(!istype(app))
			continue
		if(app.run_emag())
			newemag = TRUE
	if(newemag)
		to_chat(user, span_notice("You swipe \the [src]. A console window momentarily fills the screen, with white text rapidly scrolling past."))
		return TRUE
	to_chat(user, span_notice("You swipe \the [src]. A console window fills the screen, but it quickly closes itself after only a few lines are written to it."))
	return FALSE

/obj/item/modular_computer/examine(mob/user)
	. = ..()
	if(obj_integrity <= integrity_failure * max_integrity)
		. += span_danger("It is heavily damaged!")
	else if(obj_integrity < max_integrity)
		. += span_warning("It is damaged.")

	. += get_modular_computer_parts_examine(user)

/obj/item/modular_computer/update_icon_state()
	icon_state = enabled ? icon_state_powered : icon_state_unpowered
	return ..()

/obj/item/modular_computer/update_overlays()
	. = ..()
	if(!display_overlays)
		return
	if(enabled)
		. += active_program?.program_icon_state || icon_state_menu

	if(obj_integrity <= integrity_failure * max_integrity)
		. += "bsod"
		. += "broken"


// On-click handling. Turns on the computer if it's off and opens the GUI.
/obj/item/modular_computer/interact(mob/user)
	if(enabled)
		ui_interact(user)
	else
		turn_on(user)

/obj/item/modular_computer/proc/turn_on(mob/user)
	var/issynth = issilicon(user) // Robots and AIs get different activation messages.
	if(obj_integrity <= integrity_failure * max_integrity)
		if(issynth)
			to_chat(user, span_warning("You send an activation signal to \the [src], but it responds with an error code. It must be damaged."))
		else
			to_chat(user, span_warning("You press the power button, but the computer fails to boot up, displaying variety of errors before shutting down again."))
		return

	// If we have a recharger, enable it automatically. Lets computer without a battery work.
	var/obj/item/computer_hardware/recharger/recharger = all_components[MC_CHARGE]
	if(recharger)
		recharger.enabled = 1

	if(all_components[MC_CPU] && use_power()) // use_power() checks if the PC is powered
		if(issynth)
			to_chat(user, span_notice("You send an activation signal to \the [src], turning it on."))
		else
			to_chat(user, span_notice("You press the power button and start up \the [src]."))
		enabled = 1
		update_appearance()
		ui_interact(user)
	else // Unpowered
		if(issynth)
			to_chat(user, span_warning("You send an activation signal to \the [src] but it does not respond."))
		else
			to_chat(user, span_warning("You press the power button but \the [src] does not respond."))

// Process currently calls handle_power(), may be expanded in future if more things are added.
/obj/item/modular_computer/process(seconds_per_tick)
	if(!enabled) // The computer is turned off
		last_power_usage = 0
		return 0

	if(obj_integrity <= integrity_failure * max_integrity)
		shutdown_computer()
		return 0

	if(active_program && active_program.requires_ntnet && !get_ntnet_status(active_program.requires_ntnet_feature))
		active_program.event_networkfailure(0) // Active program requires NTNet to run but we've just lost connection. Crash.

	for(var/I in idle_threads)
		var/datum/computer_file/program/P = I
		if(P.requires_ntnet && !get_ntnet_status(P.requires_ntnet_feature))
			P.event_networkfailure(1)

	if(active_program)
		if(active_program.program_state != PROGRAM_STATE_KILLED)
			active_program.process_tick(seconds_per_tick)
			active_program.ntnet_status = get_ntnet_status()
		else
			active_program = null

	for(var/I in idle_threads)
		var/datum/computer_file/program/P = I
		if(P.program_state != PROGRAM_STATE_KILLED)
			P.process_tick(seconds_per_tick)
			P.ntnet_status = get_ntnet_status()
		else
			idle_threads.Remove(P)

	handle_power(seconds_per_tick) // Handles all computer power interaction
	//check_update_ui_need()

/**
 * Displays notification text alongside a soundbeep when requested to by a program.
 *
 * After checking tha the requesting program is allowed to send an alert, creates
 * a visible message of the requested text alongside a soundbeep. This proc adds
 * text to indicate that the message is coming from this device and the program
 * on it, so the supplied text should be the exact message and ending punctuation.
 *
 * Arguments:
 * The program calling this proc.
 * The message that the program wishes to display.
 */

/obj/item/modular_computer/proc/alert_call(datum/computer_file/program/call_source, alerttext, sound = 'sound/machines/twobeep_high.ogg')
	if(!call_source || !call_source.alert_able || call_source.alert_silenced || !alerttext) //Yeah, we're checking alert_able. No, you don't get to make alerts that the user can't silence.
		return
	playsound(src, sound, 50, TRUE)
	visible_message(span_notice("The [src] displays a [call_source.filedesc] notification: [alerttext]"))
	var/mob/living/holder = loc
	if(istype(holder))
		to_chat(holder, "[icon2html(src)] [span_notice("The [src] displays a [call_source.filedesc] notification: [alerttext]")]")

// Function used by NanoUI's to obtain data for header. All relevant entries begin with "PC_"
/obj/item/modular_computer/proc/get_header_data()
	var/list/data = list()

	data["PC_device_theme"] = device_theme

	var/obj/item/computer_hardware/battery/battery_module = all_components[MC_CELL]
	var/obj/item/computer_hardware/recharger/recharger = all_components[MC_CHARGE]

	if(battery_module && battery_module.battery)
		switch(battery_module.battery.percent())
			if(80 to 200) // 100 should be maximal but just in case..
				data["PC_batteryicon"] = "batt_100.gif"
			if(60 to 80)
				data["PC_batteryicon"] = "batt_80.gif"
			if(40 to 60)
				data["PC_batteryicon"] = "batt_60.gif"
			if(20 to 40)
				data["PC_batteryicon"] = "batt_40.gif"
			if(5 to 20)
				data["PC_batteryicon"] = "batt_20.gif"
			else
				data["PC_batteryicon"] = "batt_5.gif"
		data["PC_batterypercent"] = "[round(battery_module.battery.percent())]%"
		data["PC_showbatteryicon"] = 1
	else
		data["PC_batteryicon"] = "batt_5.gif"
		data["PC_batterypercent"] = "N/C"
		data["PC_showbatteryicon"] = battery_module ? 1 : 0

	if(recharger && recharger.enabled && recharger.check_functionality() && recharger.use_power(0))
		data["PC_apclinkicon"] = "charging.gif"

	switch(get_ntnet_status())
		if(0)
			data["PC_ntneticon"] = "sig_none.gif"
		if(1)
			data["PC_ntneticon"] = "sig_low.gif"
		if(2)
			data["PC_ntneticon"] = "sig_high.gif"
		if(3)
			data["PC_ntneticon"] = "sig_lan.gif"

	if(idle_threads.len)
		var/list/program_headers = list()
		for(var/I in idle_threads)
			var/datum/computer_file/program/P = I
			if(!P.ui_header)
				continue
			program_headers.Add(list(list(
				"icon" = P.ui_header
			)))

		data["PC_programheaders"] = program_headers

	data["PC_stationtime"] = station_time_timestamp()
	data["PC_hasheader"] = 1
	data["PC_showexitprogram"] = active_program ? 1 : 0 // Hides "Exit Program" button on mainscreen
	return data

// Relays kill program request to currently active program. Use this to quit current program.
/obj/item/modular_computer/proc/kill_program(forced = FALSE)
	if(active_program)
		active_program.kill_program(forced)
		active_program = null
	var/mob/user = usr
	if(user && istype(user))
		ui_interact(user) // Re-open the UI on this computer. It should show the main screen now.
	update_appearance()

// Returns 0 for No Signal, 1 for Low Signal and 2 for Good Signal. 3 is for wired connection (always-on)
/obj/item/modular_computer/proc/get_ntnet_status(specific_action = 0)
	var/obj/item/computer_hardware/network_card/network_card = all_components[MC_NET]
	if(network_card)
		return network_card.get_signal(specific_action)
	else
		return 0

/obj/item/modular_computer/proc/add_log(text)
	if(!get_ntnet_status())
		return FALSE
	var/obj/item/computer_hardware/network_card/network_card = all_components[MC_NET]
	return SSnetworks.station_network.add_log(text, network_card)

/obj/item/modular_computer/proc/shutdown_computer(loud = 1)
	kill_program(forced = TRUE)
	for(var/datum/computer_file/program/P in idle_threads)
		P.kill_program(forced = TRUE)
		idle_threads.Remove(P)
	if(loud)
		physical.visible_message(span_notice("\The [src] shuts down."))
	enabled = 0
	update_appearance()

/obj/item/modular_computer/screwdriver_act(mob/user, obj/item/tool)
	if(!all_components.len)
		to_chat(user, span_warning("This device doesn't have any components installed."))
		return
	var/list/component_names = list()
	for(var/h in all_components)
		var/obj/item/computer_hardware/H = all_components[h]
		component_names.Add(H.name)

	var/choice = input(user, "Which component do you want to uninstall?", "Computer maintenance", null) as null|anything in sortList(component_names)

	if(!choice)
		return

	if(!Adjacent(user))
		return

	var/obj/item/computer_hardware/H = find_hardware_by_name(choice)

	if(!H)
		return

	uninstall_component(H, user)
	return


/obj/item/modular_computer/attackby(obj/item/W as obj, mob/user as mob)
	// Insert items into the components
	for(var/h in all_components)
		var/obj/item/computer_hardware/H = all_components[h]
		if(H.try_insert(W, user))
			return

	// Insert new hardware
	if(istype(W, /obj/item/computer_hardware))
		if(install_component(W, user))
			return

	if(W.tool_behaviour == TOOL_WRENCH)
		if(all_components.len)
			to_chat(user, span_warning("Remove all components from \the [src] before disassembling it."))
			return
		new /obj/item/stack/sheet/metal(get_turf(src.loc), steel_sheet_cost)
		physical.visible_message(span_notice("\The [src] is disassembled by [user]."))
		relay_qdel()
		qdel(src)
		return

	if(W.tool_behaviour == TOOL_WELDER)
		if(obj_integrity == max_integrity)
			to_chat(user, span_warning("\The [src] does not require repairs."))
			return

		if(!W.tool_start_check(user, src, amount=1))
			return

		to_chat(user, span_notice("You begin repairing damage to \the [src]..."))
		if(W.use_tool(src, user, 20, volume=50, amount=1))
			obj_integrity = max_integrity
			to_chat(user, span_notice("You repair \the [src]."))
		return

	..()

// Used by processor to relay qdel() to machinery type.
/obj/item/modular_computer/proc/relay_qdel()
	return

// Perform adjacency checks on our physical counterpart, if any.
/obj/item/modular_computer/Adjacent(atom/neighbor)
	if(physical && physical != src)
		return physical.Adjacent(neighbor)
	return ..()
