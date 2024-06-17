local Drg = T{};

local settings = require('settings');
local gConfig = require('config');
local imgui = require('imgui');
local gFunctions = require('helper');

local dragonList = {
    "Azure","Cerulean","Rygor","Firewing","Delphyne","Ember","Rover","Max","Buster","Duke","Oscar","Maggie",
    "Jessie","Lady","Hien","Raiden","Lumiere","Eisenzahn","Pfeil","Wuffi","George","Donryu","Qiqiru","Karav-Marav",
    "Oboro","Darug-Borug","Mikan","Vhiki","Sasavi","Tatang","Nanaja","Khocha","Nanaja","Khocha","Dino","Chomper",
    "Huffy","Pouncer","Fido","Lucy","Jake","Rocky","Rex","Rusty","Himmelskralle","Gizmo","Spike","Sylvester","Milo",
    "Tom","Toby","Felix","Komet","Bo","Molly","Unryu","Daisy","Baron","Ginger","Muffin","Lumineux","Quatrevents",
    "Toryu","Tataba","Etoilazuree","Grisnuage","Belorage","Centonnerre","Nouvellune","Missy","Amedeo","Tranchevent",
    "Soufflefeu","Etoile","Tonnerre","Nuage","Foudre","Hyuh","Orage","Lune","Astre","Waffenzahn","Soleil","Courageux",
    "Koffla-Paffla","Venteuse","Lunaire","Tora","Celeste","Galja-Mogalja","Gaboh","Vhyun","Orageuse","Stellaire",
    "Solaire","Wirbelwind","Blutkralle","Bogen","Junker","Flink","Knirps","Bodo","Soryu","Wanaro","Totona",
    "Levian-Movian","Kagero","Joseph","Paparaz","Coco","Ringo","Nonomi","Teter","Gigima","Gogodavi","Rurumo","Tupah",
    "Jyubih","Majha",
}

--------------------------------------------------------------------
Drg.checkIsDragon = function(petName)
    for _,entry in ipairs(dragonList) do
        if (string.match(entry, petName) ~= nil) then
            return true;
        end
    end

	return false;
end

--------------------------------------------------------------------
Drg.gui = function()
    local player = GetPlayerEntity();
    local pet = GetEntity(player.PetTargetIndex);

	-- Display pet name / level / distance
	if (gConfig.params.settings.components.petName[1] == true and pet ~= nil) then
        local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
        local x, _  = imgui.CalcTextSize(dist);
        imgui.Text(pet.Name);
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
		imgui.Text(dist .. "m");
	end
end

return Drg;