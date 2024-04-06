local Jug = T{};

local settings = require('settings');
local gConfig = require('config');
local imgui = require('imgui');
local gFunctions = require('helper');

local jugPetList = { --NOTE: These are HorizonXI specific
    --Name, Max Level, Duration (minutes)
    {petName="HareFamiliar",    maxlevel=35, duration=90},
    {petName="SheepFamiliar",   maxlevel=35, duration=60},
    {petName="FlowerpotBill",   maxlevel=40, duration=60},
    {petName="TigerFamiliar",   maxlevel=40, duration=60},
    {petName="FlytrapFamiliar", maxlevel=40, duration=60},
    {petName="LizardFamiliar",  maxlevel=45, duration=60},
    {petName="MayflyFamiliar",  maxlevel=45, duration=60},
    {petName="EftFamiliar",     maxlevel=45, duration=60},
    {petName="BeetleFamiliar",  maxlevel=45, duration=60},
    {petName="AntlionFamiliar", maxlevel=50, duration=60},
    {petName="CrabFamiliar",    maxlevel=55, duration=30},
    {petName="MiteFamiliar",    maxlevel=55, duration=60},
    {petName="KeenearedSteffi", maxlevel=75, duration=90},
    {petName="LullabyMelodia",  maxlevel=75, duration=60},
    {petName="FlowerpotBen",    maxlevel=75, duration=60},
    {petName="SaberSiravarde",  maxlevel=75, duration=60},
    {petName="FunguarFamiliar", maxlevel=65, duration=60},
    {petName="ShellbusterOrob", maxlevel=75, duration=60},
    {petName="ColdbloodComo",   maxlevel=75, duration=60},
    {petName="CourierCarrie",   maxlevel=75, duration=30},
    {petName="Homunculus",      maxlevel=75, duration=60},
    {petName="VoraciousAudrey", maxlevel=75, duration=60},
    {petName="AmbusherAllie",   maxlevel=75, duration=60},
    {petName="PanzerGalahad",   maxlevel=75, duration=60},
    {petName="LifedrinkerLars", maxlevel=75, duration=60},
    {petName="ChopsueyChucky",  maxlevel=75, duration=60},
    {petName="AmigoSabotender", maxlevel=75, duration=30},
}

Jug.initialized = false;
local newJug = false;

initJug = function(pet)
    Jug.calculateJugPetTime(pet.Name);
    gConfig.params.mobInfo.mobLevel = Jug.getJugLevel(pet.Name);
    Jug.initialized = true;
    newJug = false;
end

Jug.newJug = function()
    newJug = true;
end

--------------------------------------------------------------------
function GetReadyRecast()
	--Ready/Sic == ability ID 102
	local data = gFunctions.GetAbilityTimerData(102);
	
	--if (data.Recast == 0) then
	--	return "Ready: 3 (0s)";
	--else
		local baseRecast = 60 * (90 + data.Modifier);
		local chargeValue = baseRecast / 3;
		local remainingCharges = math.floor((baseRecast - data.Recast) / chargeValue);
		local timeUntilNextCharge = math.fmod(data.Recast, chargeValue);
		return {remainingCharges, math.ceil(timeUntilNextCharge/60)};
	--end
end

--------------------------------------------------------------------
Jug.calculateJugPetTime = function(petName)
	local duration = 0;

	if (petName ~= nil) then
		for _,entry in ipairs(jugPetList) do
			if (string.match(entry.petName, petName) ~= nil) then
				duration = entry.duration;
				break;
			end
		end

		local charmDuration = duration * 60; --convert minutes to seconds
		gConfig.params.mobInfo.charmUntil = os.time() + charmDuration;
		gConfig.params.settings.charmUntil = T{gConfig.params.mobInfo.charmUntil};

		gConfig.params.mobInfo.jugPetJustCalled = false;

		settings.save();
	end
end

--------------------------------------------------------------------
Jug.getJugLevel = function(petName)
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	--local petLevel = "?";
	local petLevel = playerLvl;

	for _,entry in ipairs(jugPetList) do
        if (string.match(entry.petName, petName) ~= nil) then
			if (playerLvl >= entry.maxlevel) then
            	petLevel = entry.maxlevel;
			
			-- I believe this is how retail does jug pet levels
			--if (playerLvl >= entry.maxlevel + 2) then
            --	petLevel = tostring(entry.maxlevel);
			--elseif (playerLvl >= entry.maxlevel + 1) then
			--	petLevel = tostring(playerLvl-2) .. "-" .. tostring(entry.maxlevel);
			--else
			--	petLevel = tostring(playerLvl-2) .. "-" .. tostring(playerLvl);
			end

			break;
        end
    end

	return petLevel;
end


--------------------------------------------------------------------
Jug.checkIsJugPet = function(petName)
    for _,entry in ipairs(jugPetList) do
        if (string.match(entry.petName, petName) ~= nil) then
            return true;
        end
    end

	return false;
end

--------------------------------------------------------------------
Jug.gui = function()
    local player = GetPlayerEntity();
    local pet = GetEntity(player.PetTargetIndex);

    if (newJug == true) then
        initJug(pet);
    end

	-- Display pet name / level / distance
	local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
	local x, _  = imgui.CalcTextSize(dist);
	if (gConfig.params.settings.components.petName[1] == true) then
		if (gConfig.params.mobInfo.mobLevel > 0) then
			local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
			local petLvl = gConfig.params.mobInfo.mobLevel;
			if (playerLvl < gConfig.params.mobInfo.mobLevel) then
				petLvl = playerLvl;
			end
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
        if (gConfig.params.mobInfo.charmUntil == 0) then
			gConfig.params.mobInfo.charmUntil = gConfig.params.settings.charmUntil[1];
		end

		local duration = math.floor(gConfig.params.mobInfo.charmUntil - os.time());
		local hrs = math.floor(duration / 3600);
		local mins = math.floor((duration % 3600) / 60);
		local secs = duration % 60;

        imgui.Text(string.format("Pet Duration: %01d:%02d:%02d", hrs, mins, secs));
	end

	-- Display recasts
	if (gConfig.params.settings.components.petRecasts[1] == true) then
		-- Display ready recast
        local readyData = GetReadyRecast();
		imgui.Text("Ready: " .. tostring(readyData[1]) .. " (" .. tostring(readyData[2]) .. "s)");

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


return Jug;