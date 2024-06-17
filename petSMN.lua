local Smn = T{};

local settings = require('settings');
local gConfig = require('config');
local imgui = require('imgui');
local gFunctions = require('helper');

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
function GetBPRageRecast()
	--Blood Pact, Rage == ability recast ID 175
	local data = gFunctions.GetAbilityTimerData(173);
    
    return math.ceil(data.Recast/60);
end

--------------------------------------------------------------------
function GetBPWardRecast()
	--Blood Pack, Ward == ability recast ID 174
	local data = gFunctions.GetAbilityTimerData(174);
    
    return math.ceil(data.Recast/60);

end

--------------------------------------------------------------------
Smn.gui = function()
    local player = GetPlayerEntity();
    local pet = GetEntity(player.PetTargetIndex);

	-- Display pet name / distance
	local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
	local x, _  = imgui.CalcTextSize(dist);
	if (gConfig.params.settings.components.petName[1] == true) then
		imgui.Text(pet.Name);
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
		imgui.Text(dist .. "m");
	end

    	-- Display recasts
	if (gConfig.params.settings.components.petRecasts[1] == true) then
		-- Display ready recast
		imgui.Text("BP Rage Recast: " .. tostring(GetBPRageRecast()) .. "s");
		imgui.Text("BP Ward Recast: " .. tostring(GetBPWardRecast()) .. "s");
    end
end

return Smn;