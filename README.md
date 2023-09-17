# PetMe
Addon for FFXI / AshitaXI v4 that displays BST pet information (for both charmed & jug pets). As of the moment
PetMe displays the following information:
* Pet name & distance to pet
* Pet level
* Charm duration
* Ready / Sic recast timers (merits may currently mess these up a bit)
* Reward recast timer
* Pet HP/MP/TP
* Pet Target
I plan to eventually add additional features for other pet jobs, but if nothing else, for right now
it will at least show basic pet information for them (HP/MP/TP).

## Notes:
1)	PetMe must already be loaded during a charm/call beast action to get the pet level & duration.
2)	If you use any gear with +charm on it, you need to use the `setcharm` command to set the total +charm value
	from any gear you will be wearing while charming. I hope to eventually automate this, but for the time being
	it's a manual process. This value will be stored between sessions, but will need to be updated anytime you 
	change your +charm gearset.
4)	I personally only play on the HorizonXI private server. This addon should work fine on retail / other private
	servers, however, the jug pet level/duration table will need to be updated w/ appropriate values & additional pets.
	Note: Horizon uses some different internal values for Sic/Ready merits, so the number of Ready charges/countdown
	may be messed up elsewhere.
5)	This code is very much a work in progress (I know, it's all one big mess of a file). Working on a big update with
	more configuration options / easy to use GUI menu. If you have helpful suggestions, issues, thoughts, etc. you're 
	welcome to DM me on discord @mathmatic.

## Planning to add:
1) Automated calculation of +charm
2) Take into account using ability Familiar (reset charm duration)
3) Pet buffs / debuffs (this may not be feasible)
4) Pet resting status (may not be feasible as well)
5) Gui menu for configuration

## Commands:
### /petme or /pm
 `/pm setcharm #` *Set +charm overide (use this if you using gear with +charm for charming)*  
 `/pm resetcharm`  *Reset +charm override to default state (0)*  

 `/pm showstats [true/false]`  *Turn the display of pet stats (HP/MP/TP) on or off [default: true]*  
 `/pm shownopet [true/false]`  *Always display the pet window (even w/o a pet) [default: false]`*
 `/pm showtarget [true/false]`  *Shows the pet's target [default: true]`*
