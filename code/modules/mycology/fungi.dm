// TODO: WRITE THIS FILE

ABSTRACT_TYPE(/datum/fungus)
/datum/fungus/
	// Standard variables for fungi are added here.
	var/name = "fungus species name" // Name of the fungus species
	var/sprite = null         // The fungus's normal sprite - overridden by special_icon
	var/growthmode = "normal" // what "family" is this fungus part of? used for various things
	var/fungus_icon = null    // If you need a new DMI for whatever reason. why not!
	var/override_icon_state = null   // If you need the icon to be different to the name
	var/crop = null // What crop does this fungus produce?
	var/starthealth = 0 // What health does this fungus start at?
	var/colonizerate = 0 // How much faster this fungus colonizes the substrate
	var/harvtime = 0 // How much faster this fungus produces harvests after colonizing the substrate
	var/cropsize = 0 // How many items you get per harvest
	var/harvestable = 1 // Does this fungus even produce anything
	var/safeharvests = 1 // How many times you can harvest this species before contamination risk
	var/endurance = 0 // How much endurance this species normally has
	var/cantscan = 0 // Can't be scanned by an analyzer
	var/list/assoc_reagents = list() // Used for extractions, harvesting, etc
	var/list/commuts = list() // What general mutations can occur in this fungus?
	//var/list/mutations = list() // what mutant variants does this fungus have?
	var/genome = "AAAA" // Used for splicing - how "similar" the fungi are = better odds of splice - substrate, nutrient, genome, metabolism
	var/stop_size_scaling // Stops the enlarging of sprites based on quality
	var/list/harvest_tools // For fungi that don't harvest normally and need some sort of special tool (mixed list of tool flags and item paths)
	var/harvest_tool_message // An output message for fungi with unique harvest messages (string)
	var/harvest_tool_fail_message // A helpful output message to players when they attempt to harvest a fungus by hand
	var/no_extract // Stops the extraction of spores in the MycoPro
	var/list/required_reagents // reagents required for the fungus to grow - formatted like: list(list(id="poo",amount=100),list(id="thing",amount=number))

	var/special_proc = 0 // Does this fungus do something special when it's in the pot?
	var/attacked_proc = 0 // Does this fungus react if you try to attack it?
	var/harvested_proc = 0 // Take a guess

	var/dont_rename_crop = false	// don't rename the crop after the fungus


	var/category = null // Used for vendor filtering
	var/vending = 1 // 1 = Appears in vendors, 2 = appears when hacked, 0 = doesn't appear
	var/unique_spores = null // Does this fungus produce a paticular instance of spores?
	var/sporecolor = "#000000" // color on the spore packet, if applicable
	var/hybrid = 0 // used for spore manipulator stuff

	var/lasterr = 0

	// fixed some runtime errors here - singh
	// hyp procs now return 0 for success and continue, any other number for error codes
	// for now its setup as ABB where A = proc type and B = error
	// proc 100: HYPspecial
	// proc 200: HYPattacked
	// proc 300: HYPharvested
	// proc 400: HYPspecial_M
	// proc 500: HYPattacked_M
	// error  1: called with null pot
	// error  2: called when fungus is dead or no fungus exists
	// error  3: called with a fungus that is not ready to harvest
	// when overriding these in child types start the child proc with
	/*
		..()
		if (.) return
	*/
	// ..() calls the parent type which performs the check and returns 0 or an error code
	// . holds the return value, after ..() executes the child version continues running
	// so it needs to check . to check the return of the parent type and decide whether
	// or not to continue
	proc/HYPaction_bar(var/obj/machinery/fungusbox/POT,var/mob/user,var/duration,var/datum/action/bar/icon/ACTION = /datum/action/bar/icon/harvest_fungus)
		actions.start(new ACTION(POT,user,duration),user)
	#define POT_ACTIONNONE 0
	#define POT_ACTIONPASSED 1
	#define POT_ACTIONFAILED 2
	//defines for action bar harvesting yay :D 0 = no action, 1 = action passed, 2 = action cancelled
		while(!POT.actionpassed)
			sleep(10)
			if(POT.actionpassed == POT_ACTIONFAILED)
				POT.actionpassed = POT_ACTIONNONE
				return 1
			else if(POT.actionpassed == POT_ACTIONPASSED)
				break
		if(!POT.actionpassed)
			return 1
		if(POT.actionpassed == POT_ACTIONFAILED)
			POT.actionpassed = POT_ACTIONNONE
			return 1
		POT.actionpassed = POT_ACTIONNONE

	proc/HYPspecial_proc(var/obj/machinery/fungusbox/POT)
		lasterr = 0
		if (!POT) lasterr = 101
		if (POT.dead || !POT.current) lasterr = 102
		if (lasterr)
			logTheThing("debug", null, null, "<b>Fungus HYP</b> [src] in pot [POT] failed with error [.]")
			special_proc = 0
		return lasterr

	proc/HYPattacked_proc(var/obj/machinery/fungusbox/POT,var/mob/user)
		// If it returns 0, it should halt the proc that called it also
		lasterr = 0
		if (!POT || !user) lasterr = 201
		if (POT.dead || !POT.current) lasterr = 202
		if (lasterr)
			logTheThing("debug", null, null, "<b>Fungus HYP</b> [src] in pot [POT] failed with error [.]")
			attacked_proc = 0
		return lasterr

	proc/HYPharvested_proc(var/obj/machinery/fungusbox/POT,var/mob/user)
		lasterr = 0
		if (!POT || !user) return 301
		if (POT.dead || !POT.current) return 302
		if (!src.harvestable || !src.crop) return 303
		if (lasterr)
			logTheThing("debug", null, null, "<b>Fungus HYP</b> [src] in pot [POT] failed with error [.]")
			harvested_proc = 0
		return lasterr

	proc/HYPinfusionP(var/obj/item/spore/S,var/reagent)
		var/datum/fungusgenes/DNA = S.fungusgenes

		var/damage_prob = 100 - (src.endurance + DNA.endurance)
		damage_prob = max(0,min(100,damage_prob))
		var/damage_amt = 0
		switch (reagent)
			if ("phlogiston","infernite","thalmerite","sorium")
				damage_amt = rand(80,100)
			if ("pacid")
				damage_amt = rand(75,80)
			if ("acid")
				damage_amt = rand(40,50)
			if ("weedkiller")
				if (!HYPCheckCommut(DNA,/datum/fungus_gene_strain/immunity_toxin) && src.growthmode == "weed")
					damage_amt = rand(50,60)
			if ("toxin","mercury","chlorine","fluorine","fuel","oil","cleaner")
				if (!HYPCheckCommut(DNA,/datum/fungus_gene_strain/immunity_toxin))
					damage_amt = rand(15,30)
			if ("plasma")
				if (!HYPCheckCommut(DNA,/datum/fungus_gene_strain/immunity_toxin))
					damage_amt = rand(15,30)
			if ("blood","bloodc")
				if (src.growthmode == "carnivore")
					DNA.growtime += rand(5,10)
					DNA.harvtime += rand(5,10)
					DNA.endurance += rand(10,30)
			if ("radium","uranium")
				damage_amt = rand(5,15)
				HYPmutateDNA(DNA,1)
				HYPnewcommutcheck(src,DNA)
				HYPnewmutationcheck(src,DNA)
			if ("dna_mutagen")
				HYPmutateDNA(DNA,1)
				HYPnewcommutcheck(src,DNA)
				HYPnewmutationcheck(src,DNA)
				if (prob(2))
					HYPaddCommut(DNA,/datum/fungus_gene_strain/unstable)
			if ("mutagen")
				HYPmutateDNA(DNA,2)
				HYPnewcommutcheck(src,DNA)
				HYPnewmutationcheck(src,DNA)
				if (prob(5))
					HYPaddCommut(DNA,/datum/fungus_gene_strain/unstable)
			if ("ammonia")
				damage_amt = rand(10,20)
				DNA.growtime += rand(5,10)
				DNA.harvtime += rand(2,5)
				if (prob(5))
					HYPaddCommut(DNA,/datum/fungus_gene_strain/accelerator)
			if ("potash")
				DNA.cropsize += rand(1,4)
				DNA.harvests -= rand(0,2)
			if ("saltpetre")
				DNA.potency += rand(2,8)
				DNA.cropsize += rand(0,2)
			if ("space_fungus")
				DNA.endurance += rand(1,3)
				if (prob(3))
					HYPaddCommut(DNA,/datum/fungus_gene_strain/damage_res)
			if ("mutadone")
				if (DNA.growtime < 0)
					DNA.growtime++
				if (DNA.harvtime < 0)
					DNA.harvtime++
				if (DNA.harvests < 0)
					DNA.harvests++
				if (DNA.cropsize < 0)
					DNA.cropsize++
				if (DNA.potency < 0)
					DNA.potency++
				if (DNA.endurance < 0)
					DNA.endurance++

		if (damage_amt)
			if (prob(damage_prob)) S.sporedamage += damage_amt
		if (S.sporedamage > 99)
			return 99 // destroy the spore

/datum/fungusgenes/
	var/growtime = 0 // These vars are pretty much bonuses/penalties applied on top of the
	var/harvtime = 0 // same vars found in /datum/fungus honestly. They go largely towards
	var/harvests = 0 // the same purpose for the most part.
	var/cropsize = 0
	var/potency = 0  // Apart from this one - this one deals with reagents.
	var/endurance = 0
	var/list/commuts = null // General transferrable mutations
	var/datum/fungusmutation/mutation = null // is it mutated? if so which variation?
	var/list/alleles = list(0,0,0,0,0,0,0)
	// Order goes:
	// Species, Growtime, Harvtime, Cropsize, Harvests, Potency, Endurance
	// Species allele controls name, appearance, crop produce and mutations
	// 1 is dominant, else recessive

	New(var/loc,var/random_alleles = 1)
		..()
		if (random_alleles)
			src.alleles[1] = rand(0,1)
			src.alleles[2] = rand(0,1)
			src.alleles[3] = rand(0,1)
			src.alleles[4] = rand(0,1)
			src.alleles[5] = rand(0,1)
			src.alleles[6] = rand(0,1)
			src.alleles[7] = rand(0,1)
			// optimise this later

/datum/action/bar/icon/harvest_fungus //In the words of my forebears, "I really don't know a good spot to put this, so im putting it here, fuck you." Adds a channeled action to harvesting flagged fungi.
	id = "harvest_fungus"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	duration = 50
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"

	var/obj/machinery/fungusbox/fungus_box
	var/mob/living/carbon/human/source
	var/obj/item/toolcheck

	proc/reset()
		duration = 50
		icon = 'icons/mob/screen1.dmi'
		icon_state = "grabbed"

	New(var/obj/machinery/fungusbox/POT,var/mob/living/carbon/human/sourcerelay,var/duration2)
		if(POT)
			fungus_box = POT
		if(sourcerelay)
			source = sourcerelay
		if(duration2)
			duration = duration2
		if(fungus_box.current.harvest_tools && (source.equipped() != null))
			var/obj/item/I = source.equipped()
			toolcheck = I
		..()

	onUpdate()
		if(fungus_box == null || source == null || (get_dist(source, fungus_box) > 1))
			interrupt(INTERRUPT_ALWAYS)
			fungus_box.actionpassed = POT_ACTIONFAILED
			reset()
			return
		if(source && (source.equipped() != toolcheck))
			interrupt(INTERRUPT_ALWAYS)
			fungus_box.actionpassed = POT_ACTIONFAILED
			reset()
			return
		if(!fungus_box.current)
			interrupt(INTERRUPT_ALWAYS)
			fungus_box.actionpassed = POT_ACTIONFAILED
			reset()
			return
		if(fungus_box.dead == 1)
			interrupt(INTERRUPT_ALWAYS)
			fungus_box.actionpassed = POT_ACTIONFAILED
			reset()
			return
		..()

	onEnd()
		..()
		fungus_box.actionpassed = POT_ACTIONPASSED
		reset()
