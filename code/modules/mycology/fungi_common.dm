/datum/plant/weed/fungus
	name = "Fungus"
	seedcolor = "#224400"
	crop = /obj/item/reagent_containers/food/snacks/mushroom
	nothirst = 1
	starthealth = 20
	growtime = 30
	harvtime = 250
	harvests = 10
	endurance = 40
	cropsize = 3
	force_seed_on_harvest = 1
	vending = 2
	genome = 30
	assoc_reagents = list("space_fungus")
	mutations = list(/datum/plantmutation/fungus/amanita,/datum/plantmutation/fungus/psilocybin,/datum/plantmutation/fungus/cloak)
