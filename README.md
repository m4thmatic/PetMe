# PetMe
Addon for AshitaXI v4 that displays pet information including pet level &amp; duration.

## Notes:
1)	PetMe must already be loaded during a charm/call beast action to get the pet level & duration.
2)	If you use any form of gearswapping for Charm, you need to use use the `setchr` command to overide
	the value for any additional CHR that you get from gear when charming. I plan to eventually automate
	this, but for the time being is necessary.  
   	- Example: If your only +CHR gear is 2 Hope Rings (+2CHR each), use the command `/pm setchr 4`
3)	If you use any gear with +charm on it, you need to use this command to set the total +charm value
	from any gear you will be wearing while charming.I plan to eventually automate
	this, but for the time being is necessary.
4)	This is my first foray into LUA and this code is very much a work in progress. If you have helpful
	suggestions and/or issues, you're welcome to DM me on discord @mathmatic.

## Planning to add:
1) Automated calculation of +CHR & +charm
2) Storing settings & possibly adding a GUI config

## Commands:
### /petme or /pm
 `/pm setchr #` *Sets +chr override (use this if you use gearswapping for charming)*  
 `/pm setcharm #` *Set +charm overide (use this if you using gear with +charm for charming)*  

 `/pm resetchr`  *Reset +chr override to default state (value of +chr last time equip menu was open)*  
 `/pm resetcharm`  *Reset +charm override to default state (0)*  

 `/pm showstats [true/false]`  *Turn the display of pet stats (HP/MP/TP) on or off [default: true]*  
 `/pm shownopet [true/false]`  *Always display the pet window (even w/o a pet) [default: false]`*  
