# PetMe
Addon for FFXI / AshitaXI v4 that displays detailed pet information. As of the moment
PetMe displays the following information:

All Jobs:
* Pet name and distance
* Basic pet stats: HP/MP/TP
* Pet Target

BST:
* Charm & Jug duration
* Pet Level
* Ready / Sic and Reward recast timers
* Healing tick counter (Stay)

DRG & SMN coming soon. :tm:

![PetMe: Charmed pet](images/wsic.png "Charmed pet")
![PetMe: Jug pet](images/jug.png "Jug pet")

The PetMe information displayed is largely configurable. After loading (by typing in "/addon load petme" - w/o quotes)
the configuration menu can be brought up by typing in /petme or /pm.

## Install:
To install, grab the latest release (a.k.a. stable version) from [Releases](https://github.com/m4thmatic/PetMe/releases).
Unzip and drop the contents (the "petme" folder) into your *Game > addons* folder.

## Notes:
1)	PetMe must already be loaded during a charm/call beast action to get the pet level & duration (this information is
	not available in the client itself, and thus must be calculated at charm/call time).
2)	Any +charm from any gear must be set manually in the configuration menu. I hope to eventually automate this, but it
	is non-trivial, therefore for the time being this is a manual process. This will need to be updated	anytime you
	modify your +charm gearset.
3)	I personally only play on the HorizonXI private server. This addon should work on retail / other private
	servers, with a couple of caveats. In particular, the jug pet level/duration table will need to be updated w/
	appropriate values & additional pets.

## Planning to add:
1) Automated calculation of +charm
2) Take into account using ability Familiar (reset charm duration)
3) Pet buffs / debuffs (this may not be feasible)

## Commands:
### /petme or /pm
 `/pm` *Brings up the configuration menu*
