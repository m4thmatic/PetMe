# PetMe
Addon for AshitaXI v4 that displays BST pet information (for both charmed & jug pets). As of the moment
PetMe displays the following information:
* Pet name & distance to pet
* Pet level
* Charm duration
* Ready / Sic recast timers (should take merits into account)
* Reward recast timer
* Pet HP/MP/TP
* Pet Target
I plan to eventually add additional features for other pet jobs, but if nothing else, for right now
it will at least show basic pet information for them (HP/MP/TP).

## Notes:
1)	PetMe must already be loaded during a charm/call beast action to get the pet level & duration.
2)	If you use any form of gearswapping for +CHR, you will need to use use the `setchr` command to overide
	the value for any additional CHR that you get from gear when charming. I plan to eventually automate this,
	but for the time being is necessary. This will need to be used anytime you update your charm gearset.
   	- Example: If your only +CHR gear is 2 Hope Rings (+2CHR each), use the command `/pm setchr 4`
3)	If you use any gear with +charm on it, you need to use the `setcharm` command to set the total +charm value
	from any gear you will be wearing while charming. I plan to eventually automate this, but for the time being
	is necessary. This will need to be used anytime you update your charm gearset.
4)	I personally only play on the HorizonXI private server. This addon should work fine on retail / other private
	servers, however, the jug pet level/duration table will need to be updated w/ appropriate values & additional pets.
5)	This is my first foray into LUA and this code is very much a work in progress (I know, it's all one big mess of
	a file). If you have helpful suggestions, issues, thoughts, etc. you're welcome to DM me on discord @mathmatic.

## Planning to add:
1) Automated calculation of +CHR & +charm
2) Take into account using ability Familiar
3) Pet buffs / debuffs (unclear on how feasible this is)
4) Pet resting status

## Commands:
### /petme or /pm
 `/pm setchr #` *Sets +chr override (use this if you use gearswapping for charming)*  
 `/pm setcharm #` *Set +charm overide (use this if you using gear with +charm for charming)*  

 `/pm resetchr`  *Reset +chr override to default state (value of +chr last time equip menu was open)*  
 `/pm resetcharm`  *Reset +charm override to default state (0)*  

 `/pm showstats [true/false]`  *Turn the display of pet stats (HP/MP/TP) on or off [default: true]*  
 `/pm shownopet [true/false]`  *Always display the pet window (even w/o a pet) [default: false]`*
 `/pm showtarget [true/false]`  *Shows the pet's target [default: true]`*
