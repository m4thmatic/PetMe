--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.author   = 'MathMatic';
addon.name     = 'PetMe';
addon.desc     = 'Display BST pet information. Level, Charm Duration, Sic & Ready Charges, Reward Recast, Pet Target.';
addon.version  = '1.3.0';

require ('common');
local settings = require('settings');
local imgui = require('imgui');
local chat = require('chat');
local charmedPet = require('petTypeCharmed');

--------------------------------------------------------------------
local defaultConfig = T{
	window = T{
		scale			= T{1.0},
		opacity			= T{0.8},
		backgroundColor	= T{0.23, 0.23, 0.26, 1.0},
		textColor		= T{1.00, 1.00, 1.00, 1.0},
		borderColor		= T{0.00, 0.00, 0.00, 1.0},	
	},

	components = T{
		petName			= T{true},
		petDuration		= T{true},
		petRecasts		= T{true},
		petStats		= T{true},
		petTarget		= T{true},
		petStayCounter  = T{true},
		hideMap			= T{true},
		hideLog			= T{false},
		alwaysVisible	= T{false},
	},

	--charmGear 			= T{0},
	charmUntil			= T{0}, -- store jug pet charm time, in case of shutdown
}

local petMe = T{
	settings = settings.load(defaultConfig);

	mobInfo = T{
		hasPet 				= false,
		mobLevel 			= 0,
		charmingMob 		= false,
		charmMobTarget 		= 0,
		charmMobTargetIndex = 0,
		charmUntil			= 0,
		petTarget			= nil,
		jugPetJustCalled 	= false;
		petStayTicks		= 0;
	},

	configMenuOpen = {false};
}

---------------------------Lookup Tables---------------------------
local colors = {
	HpBarFull      = { 0.10, 0.60, 0.10, 1.0 },
	HpBar75        = { 0.70, 0.60, 0.10, 1.0 },
	HpBar50        = { 0.80, 0.40, 0.10, 1.0 },
	HpBar25        = { 0.80, 0.10, 0.10, 1.0 },
	MpBar          = { 0.20, 0.20, 0.80, 1.0 },
	TpBar          = { 0.40, 0.40, 0.40, 1.0 },
	TargetBar      = { 0.70, 0.40, 0.40, 1.0 },
}

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

--------------------------------------------------------------------
function checkIsJugPet(petName)
    for _,entry in ipairs(jugPetList) do
        if (string.match(entry.petName, petName) ~= nil) then
            return true;
        end
    end

	return false;
end

--------------------------------------------------------------------
function calculateJugPetTime(petName)
	local duration = 0;

	if (petName ~= nil) then
		for _,entry in ipairs(jugPetList) do
			if (string.match(entry.petName, petName) ~= nil) then
				duration = entry.duration;
				break;
			end
		end

		local charmDuration = duration * 60; --convert minutes to seconds
		petMe.mobInfo.charmUntil = os.time() + charmDuration;
		petMe.settings.charmUntil = T{petMe.mobInfo.charmUntil};

		petMe.mobInfo.jugPetJustCalled = false;

		settings.save();
	end
end

--------------------------------------------------------------------
function getJugLevel(petName)
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	--local petLevel = "?";
	local petLevel = tostring(playerLvl);

	for _,entry in ipairs(jugPetList) do
        if (string.match(entry.petName, petName) ~= nil) then
			if (playerLvl >= entry.maxlevel) then
            	petLevel = tostring(entry.maxlevel);
			
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

--------------------------------------------------------------------------------
---This function is largely based off of code taken from tCrossBar by Thorny----
--------------------------------------------------------------------------------
local AbilityRecastPointer = ashita.memory.find('FFXiMain.dll', 0, '894124E9????????8B46??6A006A00508BCEE8', 0x19, 0);
AbilityRecastPointer = ashita.memory.read_uint32(AbilityRecastPointer);

local function GetAbilityTimerData(id)
    for i = 1,31 do
        local compId = ashita.memory.read_uint8(AbilityRecastPointer + (i * 8) + 3);
        if (compId == id) then
            return {
                Modifier = ashita.memory.read_int16(AbilityRecastPointer + (i * 8) + 4);
                Recast = ashita.memory.read_uint32(AbilityRecastPointer + (i * 4) + 0xF8);
            };
        end
    end
    
    return {
        Modifier = 0,
        Recast = 0
    };
end

local function RecastToString(timer)
    if (timer >= 216000) then
        local h = math.floor(timer / (216000));
        local m = math.floor(math.fmod(timer, 216000) / 3600);
        return string.format('%i:%02i', h, m);
    elseif (timer >= 3600) then
        local m = math.floor(timer / 3600);
        local s = math.floor(math.fmod(timer, 3600) / 60);
        return string.format('%i:%02i', m, s);
    else
        if (timer < 60) then
            return '1';
        else
            return string.format('%i', math.floor(timer / 60));
        end
    end
end


local function GetReadySicRecast(isJugPet)
	--Ready/Sic == ability ID 102
	local data = GetAbilityTimerData(102);
	
	if (isJugPet == true) then
		if (data.Recast == 0) then
			return "Ready: 3 (0s)";
		else
			local baseRecast = 60 * (90 + data.Modifier);
			local chargeValue = baseRecast / 3;
			local remainingCharges = math.floor((baseRecast - data.Recast) / chargeValue);
			local timeUntilNextCharge = math.fmod(data.Recast, chargeValue);
			return "Ready: " .. remainingCharges .. " (" .. tostring(math.ceil(timeUntilNextCharge/60)) .. "s)";
		end
	else
		return "Sic Recast: " .. tostring(math.ceil(data.Recast/60)) .. "s";
	end
end

local function GetRewardRecast()
	--Reward == ability ID 103
	local rewardAbilityID = 103;

	for i = 1,31 do
		local compId = ashita.memory.read_uint8(AbilityRecastPointer + (i * 8) + 3);
		if (compId == rewardAbilityID) then
			modifier = ashita.memory.read_int16(AbilityRecastPointer + (i * 8) + 4);
			recast = ashita.memory.read_uint32(AbilityRecastPointer + (i * 4) + 0xF8);
		end
	end

	if (recast == nil) then
		return -1, -1;
	end

	recast = math.floor(recast / 60);

	return recast, modifier;
end

--------------------------------------------------------------------------------
-------------- This function is copied from the PetInfo addon ------------------
--------------------------------------------------------------------------------
local function GetEntityByServerId(sid)
    for x = 0, 2303 do
        local ent = GetEntity(x);
        if (ent ~= nil and ent.ServerId == sid) then
            return ent;
        end
    end
    return nil;
end

--------------------------------------------------------------------------------
-------------- This function is copied from the XITools addon ------------------
--------------------------------------------------------------------------------
local menuBase = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0);

--- Gets the name of the top-most menu element.
function GetMenuName()
    local subPointer = ashita.memory.read_uint32(menuBase);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

--- Determines if the window should be hidden
function hideWindow()
    local menuName = GetMenuName();
		
	if (petMe.settings.components.hideMap[1] == true) then
		if ( string.match(menuName, 'map') or
		     string.match(menuName, 'cnqframe')
		   ) then
			return true;
		end
	end

	if (petMe.settings.components.hideLog[1] == true) then
		if (string.match(menuName, 'fulllog')) then
			return true;
		end
	end
	
	--Hide when at login screen
    return menuName:match('menu%s+scanlist.*') ~= nil
		or menuName:match('menu%s+dbnamese') ~= nil
		or menuName:match('menu%s+ptc6yesn') ~= nil
		--or menuName:match('menu%s+') ~= nil
		
end

--------------------------------------------------------------------
function renderMenu()

	imgui.SetNextWindowSize({500});

	if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), petMe.configMenuOpen, bit.bor(ImGuiWindowFlags_AlwaysAutoResize))) then

		imgui.Text("Display Options");

		imgui.SliderFloat('Window Scale', petMe.settings.window.scale, 0.1, 2.0, '%.2f');
		imgui.ShowHelp('Scale the window bigger/smaller.');

		imgui.SliderFloat('Window Opacity', petMe.settings.window.opacity, 0.1, 1.0, '%.2f');
		imgui.ShowHelp('Set the window opacity.');

		imgui.ColorEdit4("Text Color", petMe.settings.window.textColor);
		imgui.ColorEdit4("Border Color", petMe.settings.window.borderColor);
		imgui.ColorEdit4("Background Color", petMe.settings.window.backgroundColor);

		imgui.Checkbox('Show basic info', petMe.settings.components.petName);
		imgui.ShowHelp('Shows the pet name, level, and distance.');

		imgui.Checkbox('Show duration', petMe.settings.components.petDuration);
		imgui.ShowHelp('Shows the pet duration.');

		imgui.Checkbox('Show pet recast timers', petMe.settings.components.petRecasts);
		imgui.ShowHelp('Shows ready/sic and reward recast timers.');

		imgui.Checkbox('Show pet healing (stay) ticks', petMe.settings.components.petStayCounter);
		imgui.ShowHelp('Shows an estimated countdown until the next time the pet will recover health when stayed.');

		imgui.Checkbox('Show pet stats', petMe.settings.components.petStats);
		imgui.ShowHelp('Shows the pet\'s HP, MP, and TP percentages.');

		imgui.Checkbox('Show pet target', petMe.settings.components.petTarget);
		imgui.ShowHelp('Shows the pet\'s target / remaining HP percent.');

		imgui.Checkbox('Hide window when map is open', petMe.settings.components.hideMap);
		imgui.ShowHelp('Hides the PetMe window when the map is open.');

		imgui.Checkbox('Hide window when log is open', petMe.settings.components.hideLog);
		imgui.ShowHelp('Hides the PetMe window when the log is open.');
			
		imgui.Checkbox('Always Show Window', petMe.settings.components.alwaysVisible);
		imgui.ShowHelp('Shows the PetMe window even when there is no pet.');

		--if (imgui.Button('  Save  ')) then
		--	settings.save();
		--	petMe.configMenuOpen[1] = false;
        --    print(chat.header(addon.name):append(chat.message('Settings saved.')));
		--end
		--imgui.SameLine();
		if (imgui.Button('  Reset  ')) then
			--settings = defaultConfig;
			settings.reset();
            print(chat.header(addon.name):append(chat.message('Settings reset to default.')));
		end
		imgui.ShowHelp('Resets settings to their default state.');
	end
    --imgui.PopStyleColor(3);
	imgui.End();
end

--------------------------------------------------------------------
function renderPetMe(player, pet)

	local windowSize = 300 * petMe.settings.window.scale[1];
    imgui.SetNextWindowBgAlpha(petMe.settings.window.opacity[1]);
    imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
	imgui.PushStyleColor(ImGuiCol_WindowBg, petMe.settings.window.backgroundColor);
	imgui.PushStyleColor(ImGuiCol_Border, petMe.settings.window.borderColor);
	imgui.PushStyleColor(ImGuiCol_Text, petMe.settings.window.textColor);

	if (imgui.Begin('PetMe', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
		imgui.SetWindowFontScale(petMe.settings.window.scale[1]);

		if (pet == nil) then
			imgui.Text("No pet");
		else
			petMe.mobInfo.hasPet = true;

			if (petMe.mobInfo.jugPetJustCalled == true) then
				calculateJugPetTime(pet.Name);
			end

			if (petMe.mobInfo.charmUntil == 0) then
				petMe.mobInfo.charmUntil = petMe.settings.charmUntil[1];
			end

			-- Obtain pet info
			local petmp = AshitaCore:GetMemoryManager():GetPlayer():GetPetMPPercent();
			local pettp = AshitaCore:GetMemoryManager():GetPlayer():GetPetTP();
			local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
			local x, _  = imgui.CalcTextSize(dist);
			local isJugPet = checkIsJugPet(pet.Name)

			-- Display pet name / level / distance
			if (petMe.settings.components.petName[1] == true) then
				if (isJugPet == true) then
					imgui.Text(pet.Name .. " (Lvl " .. getJugLevel(pet.Name) .. ")");
				elseif (petMe.mobInfo.mobLevel > 0) then
					imgui.Text(pet.Name .. " (Lvl " .. tostring(petMe.mobInfo.mobLevel) .. ")");
				else
					imgui.Text(pet.Name .. " (Lvl ---)");
				end
				imgui.SameLine();
				imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
				imgui.Text(dist .. "m");
			end

			-- Display pet duration
			if (petMe.settings.components.petDuration[1] == true) then
				if (petMe.mobInfo.charmUntil ~= 0) then
					local duration = math.floor(petMe.mobInfo.charmUntil - os.time());
					local hrs = math.floor(duration / 3600);
					local mins = math.floor((duration % 3600) / 60);
					local secs = duration % 60;

					imgui.Text(string.format("Pet Duration: %01d:%02d:%02d", hrs, mins, secs));
				else
					imgui.Text("Pet Duration: (Unknown)");
				end
			end

			-- Display recasts
			if (petMe.settings.components.petRecasts[1] == true) then
				-- Display ready/sic recast
				imgui.Text(GetReadySicRecast(isJugPet));

				-- Display reward recast
				local rewardTimer, modif = GetRewardRecast();
				--if (rewardTimer > 0) then			
					imgui.SameLine();
					local reMins = math.floor(rewardTimer / 60);
					local reSecs = rewardTimer % 60;
					--rewText = string.format("Reward: %01d:%02d", reMins, reSecs);
					rewText = string.format("Reward: %ds", rewardTimer);
					imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.CalcTextSize(rewText));
					imgui.Text(rewText);
				--end
			end

			-- Display pet acc/att stats
				--TBD

			-- Display the healing (stay) tick count
			if (petMe.settings.components.petStayCounter[1] == true) then
				if (petMe.mobInfo.petStayTicks ~= 0) then
					local petMovement = AshitaCore:GetMemoryManager():GetEntity():GetLocalMoveCount(player.PetTargetIndex);
					if (petMovement ~= 0) then
						petMe.mobInfo.petStayTicks = 0;
					else
						if (petMe.mobInfo.petStayTicks - os.time() <= 0) then
							petMe.mobInfo.petStayTicks = os.time() + 10;
						end				
						local petTickCnt = tostring(petMe.mobInfo.petStayTicks - os.time());

						imgui.Text("Healing count: " .. petTickCnt);
					end			
				end
			end

			-- Dislay pet stat bars (HPP,MPP,TP)
			if (petMe.settings.components.petStats[1] == true) then
				if pet.HPPercent > 75 then
					hpBarColor = colors.HpBarFull
				elseif pet.HPPercent > 50 then
					hpBarColor = colors.HpBar75
				elseif pet.HPPercent > 25 then
					hpBarColor = colors.HpBar50
				elseif pet.HPPercent >= 00 then
					hpBarColor = colors.HpBar25
				end

				imgui.Separator();		

				--Pet HP
				imgui.PushStyleColor(ImGuiCol_PlotHistogram, hpBarColor);
				imgui.ProgressBar(pet.HPPercent / 100, { windowSize/3-10, 15*petMe.settings.window.scale[1] });
				imgui.PopStyleColor(1);

				--Pet MP
				imgui.SameLine();
				imgui.PushStyleColor(ImGuiCol_PlotHistogram, colors.MpBar);
				imgui.ProgressBar(petmp / 100,  { windowSize/3-10, 15*petMe.settings.window.scale[1] });
				imgui.PopStyleColor(1);
				
				--Pet TP
				imgui.SameLine();
				imgui.PushStyleColor(ImGuiCol_PlotHistogram, colors.TpBar);
				imgui.ProgressBar(pettp / 3000,  { windowSize/3-10, 15*petMe.settings.window.scale[1] }, tostring(pettp));
				imgui.PopStyleColor(1);
			end

			-- Display pet's target
			if (petMe.settings.components.petTarget[1] and petMe.mobInfo.target ~= nil and petMe.mobInfo.target ~= 0) then
				local target = GetEntityByServerId(petMe.mobInfo.target);
				if (target == nil or target.ActorPointer == 0 or target.HPPercent == 0) then
					petMe.mobInfo.target = nil;
				else
					dist = ('%.1f'):fmt(math.sqrt(target.Distance));
					x, _ = imgui.CalcTextSize(dist);
			
					local tname = target.Name;
					if (tname == nil) then
						tname = '';
					end
			
					imgui.Separator();
					imgui.Text(tname);
					imgui.SameLine();
					imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
					imgui.Text(dist);
					imgui.Text('HP:');
					imgui.SameLine();
					imgui.PushStyleColor(ImGuiCol_PlotHistogram, colors.TargetBar);
					imgui.ProgressBar(target.HPPercent / 100, { -1, 16 });
					imgui.PopStyleColor(1);
				end
			end

		end

		imgui.SetWindowFontScale(1.0); -- reset window scale
    end
    imgui.PopStyleColor(3);
	imgui.End();
end



--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()
    settings.save();
end);

--------------------------------------------------------------------
settings.register('settings', 'settings_update', function(s)
    -- Update the settings table..
    if (s ~= nil) then
        petMe.settings = s;
    end

    -- Save the current settings..
    settings.save();
end);

--------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/petme', '/pm')) then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

	if (#args == 1) then
		petMe.configMenuOpen[1] = not petMe.configMenuOpen[1];
	end
end);

--------------------------------------------------------------------
ashita.events.register('packet_out', 'packet_out_cb', function (e)
	if(e.id == 0xDD) then --Outgoing "check" packet
		if (petMe.mobInfo.charmingMob == true) then
			--Modify packet to use the charm target instead of whatever the player is actually targetting
			pktdata = e.data:totable();
			local pckt = struct.pack("BBBBHBBHBBBBBB",pktdata[1],pktdata[2],pktdata[3],pktdata[4],petMe.mobInfo.charmMobTarget,pktdata[7],pktdata[8],petMe.mobInfo.charmMobTargetIndex,pktdata[11],pktdata[12],pktdata[13],pktdata[14],pktdata[15],pktdata[16]);
			e.data_modified = pckt;	
		end
	end

	if (e.id == 0x1A) then --Outgoing action packet
		local target = struct.unpack('H', e.data, 0x04 + 0x01);
		local targetIndex = struct.unpack('H', e.data, 0x08 + 0x01);
		local category = struct.unpack('H', e.data, 0x0A + 0x01);
		local actionId = struct.unpack('H', e.data, 0x0C + 0x01);

		if (category == 0x09) then --Job Ability
			--print(actionId); -- Action ID: Stay=73, Heel=70, Leave=71
			if (petMe.mobInfo.hasPet == false) then --Check to make sure that the player doesn't already have a pet.
				if (actionId == 52) then --Charm
					petMe.mobInfo.charmingMob = true;
					--e.blocked = true; --Stop the charm packet from being sent, for debugging

					-- Because players may use different targetting mechanisms, we store the target/index of the mob that
					-- the player is attempting to charm. This can then be used to modify the /check command upon receipt.
					-- This is important, because in the case that the player uses something like /ja "Charm" <stnpc>, the
					-- targetted (i.e. "checked") mob may not be the same as the one being charmed. We could do this by sending
					-- a check packet directly from here, but I found doing it this way to be more consistent. May look into
					-- refining this process a bit more later, but for the moment it works.
					petMe.mobInfo.charmMobTarget = target;
					petMe.mobInfo.charmMobTargetIndex = targetIndex;

					--Send a Check command
					-- We send a check command prior to charming to get the mob level.
					AshitaCore:GetChatManager():QueueCommand(1, "/check");
					--AshitaCore:GetChatManager():QueueCommand(1, "/check <lastst>");

					--Send "Check" packet 
					--  This simplifies things, but I want to figure out what the other data bytes mean before I feel comfortable sending it regularly
					--local pckt = struct.pack("BBBBHBBHBBBBBB",0xDD,0x08,0x00,0x00,target,0x07,0x01,targetIndex,0x00,0x00,0x00,0xFB,0xEF,0x42);
					--AshitaCore:GetPacketManager():AddOutgoingPacket(0xDD, pckt:totable());
				end

				if ((actionId == 85) or (actionId == 387)) then --Call Beast (85), Bestial Loyalty (387)
					--calculateJugPetTime(); -- Can't call this here directly, b/c pet doesn't exist yet
					petMe.mobInfo.jugPetJustCalled = true; -- set flag and calculate time later
				end
			else
				if (actionId == 73) then --Stay
					if (petMe.mobInfo.petStayTicks == 0) then
						petMe.mobInfo.petStayTicks = os.time() + 20;
					end
				end
				if (actionId == 70) then --Heel
					petMe.mobInfo.petStayTicks = 0;
				end
			end
		end
	end
end);

--------------------------------------------------------------------
ashita.events.register('packet_in', 'packet_in_cb', function (e)

	--Action (action 28, action msg 29)
	if (e.id == 0x028) then 
		--print(e.id);
		--print(e.data);
		--Possibly use this to determine when call beast is used.
		--Possibly get +chr/+charm & calculate charm duration here.
		--print(e.size);
	end
	--if (e.id == 0x050) then
	--end

    --if (e.id == 0x0C9) then -- Check packet
	--	print("received!");
	--end

    if (e.id == 0x029) then -- Check packet
		--local target = struct.unpack('H', e.data, 0x04 + 0x01);
		--local targetIndex = struct.unpack('H', e.data, 0x08 + 0x01);
        local param1 = struct.unpack('l', e.data, 0x0C + 0x01);
        local param2 = struct.unpack('L', e.data, 0x10 + 0x01);
		local msg    = struct.unpack('H', e.data, 0x18 + 0x01);

        -- If this is a Check packet AND we are attempting to charm a mob
		if ( ((msg >= 0xAA) and (msg <= 0xB2)) or ((param2 >= 0x40) and (param2 <= 0x47))) then -- msg == 0xF9  (impossible to gauge?)

			--When receiving the Check packet and we have just charmed a mob
			if (petMe.mobInfo.charmingMob == true) then
				e.blocked = true; --prevent console check text, though other addons (i.e. "checker") will still pick it up and print to console
				petMe.mobInfo.mobLevel = param1;
				petMe.mobInfo.charmUntil = charmedPet.calculateCharmTime(param1);
				petMe.mobInfo.charmingMob = false;
			end
		end
    end

	-- Packet: Pet Sync (copied from PetInfo)
	if (e.id == 0x0068) then
		-- Obtain the player entitiy..
		local player = GetPlayerEntity();
		if (player == nil) then
			petMe.mobInfo.target = nil;
			return;
		end
	
		-- Update the players pet target..
		local owner = struct.unpack('I', e.data_modified, 0x08 + 0x01);
		if (owner == player.ServerId) then
			petMe.mobInfo.target = struct.unpack('I', e.data_modified, 0x14 + 0x01);
		end
	
		return;
	end
end);


--------------------------------------------------------------------
--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
	if (hideWindow() == false) then
		local player = GetPlayerEntity();
		if (player == nil) then -- when zoning
			return;
		end

		if (petMe.configMenuOpen[1] == true) then
			renderMenu();
		end
		
		local pet = GetEntity(player.PetTargetIndex);
		if (pet == nil) then -- if no pet, set pet to false & return
			petMe.mobInfo.hasPet = false;
			--mobInfo.mobLevel = 0;
			--mobInfo.charmingMob = false;
			--mobInfo.charmMobTarget = 0;
			--mobInfo.charmMobTargetIndex = 0;
			--mobInfo.charmUntil = 0;	-- HorizonXI allows jug pets to persist through zoning, so comment out
			--mobInfo.jugPet = 0;		-- HorizonXI allows jug pets to persist through zoning, so comment out

		--	if (config.alwaysVisible[1] == false) then
		--    	return;
		--	end
		end

		if ((pet ~= nil) or (petMe.settings.components.alwaysVisible[1] == true)) then
			renderPetMe(player, pet);
		end
	end
end);