/obj/item/ammo_box/magazine/m45/nato_enforcer
	name = "pistol  magazine (.45)"
	desc = "A single stack M1911 reproduction magazin e, faithfully designed to chamber .45."
	icon = 'icons/hispania/obj/projectiles/projectile.dmi'
	icon_state = "enforcer"

/obj/item/ammo_box/magazine/m45/nato_enforcer/hp
	name = "pistol magazine (.45 HP)"
	desc= "A single stack M1911 reproduction magazine, faithfully designed to chamber .45. Loaded with rounds which deal more damage, but are completely ineffective against armor."
	ammo_type = /obj/item/ammo_casing/c45/hp

/obj/item/ammo_box/magazine/m45/nato_enforcer/ap
	name = "pistol magazine (.45 AP)"
	desc= "A single stack M1911 reproduction magazine, faithfully designed to chamber .45. Loaded with rounds which penetrate armour, but are less effective against normal targets."
	ammo_type = /obj/item/ammo_casing/c45/ap

/obj/item/ammo_box/magazine/m45/nato_enforcer/update_icon()
	..()
	if (ammo_count() >= 8)
		icon_state = "enforcer-8"
	else
		icon_state = "enforcer-[ammo_count()]"

/obj/item/ammo_box/magazine/sniper_rounds/nato_ekho
	name = "Ekho rounds (.50)"
	icon_state = "ekho_mag"
	icon = 'icons/hispania/obj/projectiles/ammo.dmi'


/obj/item/ammo_box/magazine/sniper_rounds/nato_ekho/update_icon()
	..()
	if(ammo_count() == 0)
		icon_state = "[initial(icon_state)]-0"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_box/magazine/internal/derr357/nato
	name = "\improper NATO revolver cylinder"
	ammo_type = /obj/item/ammo_casing/a357
	caliber = ".357"
	max_ammo = 6
