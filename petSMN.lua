local Smn = T{};

local settings = require('settings');
local gConfig = require('config');

local summonList = {
    "Carbuncle",
    "Fenrir",
    "Ifrit",
    "Titan",
    "Leviathan",
    "Garuda",
    "Shiva",
    "Ramuh",
    "Diabolos",
    "Cait Sith",
    "Siren",
    "Atomos",
    "Alexander†",
    "Odin†",
    "Fire Spirit",
    "Ice Spirit",
    "Air Spirit",
    "Earth Spirit",
    "Thunder Spirit",
    "Water Spirit",
    "Light Spirit",
    "Dark Spirit",
}

--------------------------------------------------------------------
Smn.checkIsSummon = function(petName)
    for _,entry in ipairs(summonList) do
        if (string.match(entry, petName) ~= nil) then
            return true;
        end
    end

	return false;
end

--------------------------------------------------------------------
Smn.gui = function()
    local player = GetPlayerEntity();
    local pet = GetEntity(player.PetTargetIndex);

	-- Display pet name / level / distance
	local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
	local x, _  = imgui.CalcTextSize(dist);
	if (gConfig.params.settings.components.petName[1] == true) then
		imgui.Text(pet.Name);
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
		imgui.Text(dist .. "m");
	end
end

return Smn;