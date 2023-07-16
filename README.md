# PetMe
Addon for AshitaXI v4 that displays BST pet information including pet level, duration, ready/sic timers, etc. This works for both
charmed & jug pets. (Have not currently tested w/ DRG or SMN.)

## Notes:
1)	PetMe must already be loaded during a charm/call beast action to get the pet level & duration.
2)	If you use any form of gearswapping for Charm, you need to use use the `setchr` command to overide
	the value for any additional CHR that you get from gear when charming. If your gear is static, this
	is not necessary. I plan to eventually automate	this, but for the time being is necessary to accurately
	calculate charmed pet duration.
   	- Example: If your only +CHR gear is 2 Hope Rings (+2CHR each), use the command `/pm setchr 4`
4)	If you use any gear with +charm on it, you need to use this command to set the total +charm value
	from any gear you will be wearing while charming.I plan to eventually automate
	this, but for the time being is necessary to accurately calculate charmed pet duration.
5)	This addon was developed on the HorizonXI server. It should work fine on retail / other private servers,
   	however, the jug pet level/duration table will need to be updated w/ appropriate values. I may look into
  	if there's a way to detect & automate this in the future.
7)	This is my first foray into LUA and this code is very much a work in progress. If you have helpful
	suggestions and/or issues, you're welcome to DM me on discord @mathmatic.

## Planning to add:
1) Automated calculation of +CHR & +charm
2) Storing settings & possibly adding a GUI config
3) Take into account using ability Familiar
4) Take into account Sic/Ready recast merits

## Commands:
### /petme or /pm
 `/pm setchr #` *Sets +chr override (use this if you use gearswapping for charming)*  
 `/pm setcharm #` *Set +charm overide (use this if you using gear with +charm for charming)*  

 `/pm resetchr`  *Reset +chr override to default state (value of +chr last time equip menu was open)*  
 `/pm resetcharm`  *Reset +charm override to default state (0)*  

 `/pm showstats [true/false]`  *Turn the display of pet stats (HP/MP/TP) on or off [default: true]*  
 `/pm shownopet [true/false]`  *Always display the pet window (even w/o a pet) [default: false]`*  
