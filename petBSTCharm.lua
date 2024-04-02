local settings = require('settings');
local gConfig = require('config');
local imgui = require('imgui');
local gFunctions = require('helper');

local Charm = T{};

local charmGear = T{
    [17936] = 1, --De Saintre's Axe
    [17950] = 2, --Marid Ancus
    [12517] = 4, --Beast Helm
    [15157] = 5, --Bison Warbonnet
    [15158] = 6, --Brave's Warbonnet
    [16104] = 5, --Khimaira Bonnet
    [16105] = 6, --Stout Bonnet
    [15080] = 5, --Monster Helm
    [15233] = 4, --Beast Helm +1
    [15253] = 5, --Monster Helm +1
    [12646] = 5, --Beast Jackcoat
    [14418] = 5, --Bison Jacket
    [14419] = 6, --Brave's Jacket
    [14566] = 5, --Khimaira Jacket
    [14567] = 6, --Stout Jacket
    [15095] = 6, --Monster Jackcoat
    [14481] = 6, --Beast Jackcoat +1
    [14508] = 7, --Monster Jackcoat +1
    [13969] = 3, --Beast Gloves
    [14850] = 5, --Bison Wristbands
    [14851] = 6, --Brave's Wristbands
    [14981] = 5, --Khimaira Wristbands
    [14982] = 6, --Stout Wristbands
    [14898] = 3, --Beast Gloves +1
    [15110] = 4, --Monster Gloves
    [14917] = 4, --Monster Gloves +1
    [14222] = 6, --Beast Trousers
    [14319] = 5, --Bison Kecks
    [14320] = 6, --Brave's Kecks
    [15645] = 5, --Khimaira Kecks
    [15646] = 6, --Stout Kecks
    [15125] = 2, --Monster Trousers
    [15569] = 6, --Beast Trousers +1
    [15588] = 2, --Monster Trousers +1
    [14097] = 2, --Beast Gaiters
    [15307] = 5, --Bison Gamashes
    [15308] = 6, --Brave's Gamashes
    [15731] = 5, --Khimaira Gamashes
    [15732] = 6, --Stout Gamashes
    [15360] = 2, --Beast Gaiters +1
    [15140] = 3, --Monster Gaiters
    [15673] = 3, --Monster Gaiters +1
    [14658] = 4, --Atlaua's Ring
    [13667] = 5, --Trimmer's Mantle (HorizonXI only, when /BST)
};

local dLevel = {
	{ld = -6, chg = 0.04},
	{ld = -5, chg = 0.08},
	{ld = -4, chg = 0.12},
	{ld = -3, chg = 0.16},
	{ld = -2, chg = 0.33},
	{ld = -1, chg = 0.66},
	{ld =  0, chg = 1.00},
	{ld =  1, chg = 1.40},
	{ld =  2, chg = 1.80},
	{ld =  3, chg = 2.20},
	{ld =  4, chg = 2.60},
	{ld =  5, chg = 3.00},
	{ld =  6, chg = 3.40},
	{ld =  7, chg = 4.00},
	{ld =  8, chg = 5.00},
	{ld =  9, chg = 6.00},
}


function getCharmEquipValue()
    local charmValue = 0;

    for i = 0,15 do
        local equippedItem = AshitaCore:GetMemoryManager():GetInventory():GetEquippedItem(i);
        local index = bit.band(equippedItem.Index, 0x00FF);
        if index > 0 then
            local container = bit.rshift(bit.band(equippedItem.Index, 0xFF00), 8);
            local item = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(container, index);
            if (charmGear[item.Id] ~= nil) then
                charmValue = charmValue + charmGear[item.Id];
            end
        end
    end

    return charmValue;
end

function GetSicRecast()
	--Ready/Sic == ability ID 102
	local data = gFunctions.GetAbilityTimerData(102);
    
    return math.ceil(data.Recast/60);

end

--------------------------------------------------------------------
--function calculateCharmTime()
Charm.calculateCharmTime = function (mobLevel)
	-- Set base values
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	local baseChr   = AshitaCore:GetMemoryManager():GetPlayer():GetStat(6);
	--local charm     = 0;
	--local staff		= 0;

	-- calculate level difference between player & pet
	local levelDifference = playerLvl - mobLevel;
	if (levelDifference < -6) then
		levelDifference = -6;
	elseif (levelDifference > 9) then
		levelDifference = 9;
	end

	-- determine the level modifier
	local lvlModifier = 0;
	for _,item in ipairs(dLevel) do
		if item.ld == levelDifference then
			lvlModifier = item.chg;
		end
	end

	--Base Charm Duration (seconds) = floor(1.25 × CHR + 150 )
	local baseCharmDuration = math.floor(1.25 * baseChr + 150);
	--Pre-Gear Charm Duration = Base Charm Duration × % Change
	local preGearDuration = baseCharmDuration * lvlModifier;
	--Charm Duration = Pre-gear Charm Duration × ( 1 + 0.05×(Charm+ in gear) )
	local charmDuration = preGearDuration * (1 + (0.05 * getCharmEquipValue()));
	return os.time() + charmDuration;
end

Charm.gui = function()
    local player = GetPlayerEntity();
    local pet = GetEntity(player.PetTargetIndex);

	-- Display pet name / level / distance
	local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
	local x, _  = imgui.CalcTextSize(dist);
	if (gConfig.params.settings.components.petName[1] == true) then
		if (gConfig.params.mobInfo.mobLevel > 0) then
			local petLvl = gConfig.params.mobInfo.mobLevel;
			imgui.Text(pet.Name .. " (Lvl " .. tostring(petLvl) .. ")");
		else
			imgui.Text(pet.Name .. " (Lvl ---)");
		end
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
		imgui.Text(dist .. "m");
	end

	-- Display pet duration
	if (gConfig.params.settings.components.petDuration[1] == true) then
		if (gConfig.params.mobInfo.charmUntil ~= 0) then
			local duration = math.floor(gConfig.params.mobInfo.charmUntil - os.time());
			local hrs = math.floor(duration / 3600);
			local mins = math.floor((duration % 3600) / 60);
			local secs = duration % 60;

            imgui.Text(string.format("Pet Duration: %01d:%02d:%02d", hrs, mins, secs));
		else
			imgui.Text("Pet Duration: (Unknown)");
		end
	end

	-- Display recasts
	if (gConfig.params.settings.components.petRecasts[1] == true) then
		-- Display sic recast
		imgui.Text("Sic Recast: " .. tostring(GetSicRecast()) .. "s");

		-- Display reward recast
		local rewardTimer, modif = gFunctions.GetRewardRecast();
			imgui.SameLine();
			local reMins = math.floor(rewardTimer / 60);
			local reSecs = rewardTimer % 60;
			rewText = string.format("Reward: %ds", rewardTimer);
			imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.CalcTextSize(rewText));
			imgui.Text(rewText);
	end

			-- Display pet acc/att stats
				--TBD

	-- Display the healing (stay) tick count
	if (gConfig.params.settings.components.petStayCounter[1] == true) then
		if (gConfig.params.mobInfo.bstPet.stayTicks ~= 0) then
			local petMovement = AshitaCore:GetMemoryManager():GetEntity():GetLocalMoveCount(player.PetTargetIndex);
			if ((petMovement ~= 0) and (gConfig.params.mobInfo.bstPet.stayTicks - os.time() < 19)) then --if pet moves, and it's been > 1second since staying (allow time for pet to stop)
				gConfig.params.mobInfo.bstPet.stayTicks = 0;											--cancel stay
			else
				if (gConfig.params.mobInfo.bstPet.stayTicks - os.time() <= 0) then
					gConfig.params.mobInfo.bstPet.stayTicks = os.time() + 10;
				end				
				local petTickCnt = tostring(gConfig.params.mobInfo.bstPet.stayTicks - os.time());

				imgui.Text("Healing count: " .. petTickCnt);
			end			
		end
	end

end






return Charm