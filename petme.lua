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
addon.version  = '0.5';

require ('common');
local settings = require('settings');
local imgui = require('imgui');

--------------------------------------------------------------------
local defaultConfig = T{
	chr = nil,
	charm = nil,
	showPetStats = true;
	showNoPet = false;
	showPetTarget = true;
}
local config = settings.load(defaultConfig);

local mobInfo = T{
	hasPet = false;
	mobLevel = 0;
	charmingMob = false;
	charmMobTarget = 0;
	charmMobTargetIndex = 0;
	charmUntil = 0;	
	jugPet = 0;
	petTarget = nil;
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

local jugpet = { --NOTE: These are HorizonXI specific
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
    {petName="Homunculus",       maxlevel=75, duration=60},
    {petName="VoraciousAudrey", maxlevel=75, duration=60},
    {petName="AmbusherAllie",   maxlevel=75, duration=60},
    {petName="PanzerGalahad",   maxlevel=75, duration=60},
    {petName="LifedrinkerLars", maxlevel=75, duration=60},
    {petName="ChopsueyChucky",  maxlevel=75, duration=60},
    {petName="AmigoSabotender", maxlevel=75, duration=30},
}

--------------------------------------------------------------------
function calculateCharmTime()
	-- Set base values
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	local baseChr   = AshitaCore:GetMemoryManager():GetPlayer():GetStat(6);
	local modChr    = AshitaCore:GetMemoryManager():GetPlayer():GetStatModifier(6);
	local charm     = 0;
	local staff		= 0;

	-- If override set, then use those values
	if (config.chr ~= nil) then
		modChr = config.chr;
	end
	if (config.charm ~= nil) then
		charm = config.charm;
	end

	local totalChr = baseChr + modChr;

	-- calculate level difference between player & pet
	local levelDifference = playerLvl - mobInfo.mobLevel;
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
	local baseCharmDuration = math.floor(1.25 * totalChr + 150);
	--Pre-Gear Charm Duration = Base Charm Duration × % Change
	local preGearDuration = baseCharmDuration * lvlModifier;
	--Charm Duration = Pre-gear Charm Duration × ( 1 + 0.05×(Charm+ in gear) )
	local charmDuration = preGearDuration * (1 + (0.05 * charm));
	mobInfo.charmUntil = os.clock() + charmDuration;
end

--------------------------------------------------------------------
function calculateJugPetTime(petName)
	--
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	local duration = 0;

    for _,entry in ipairs(jugpet) do
        if (string.match(entry.petName, petName) ~= nil) then
            duration = entry.duration;
			break;
        end
    end

	local charmDuration = duration * 60; --convert minutes to seconds
	mobInfo.charmUntil = os.clock() + charmDuration;
end

--------------------------------------------------------------------
function getJugLevel(petName)
	local playerLvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	local petLevel = "?";

	for _,entry in ipairs(jugpet) do
        if (string.match(entry.petName, petName) ~= nil) then
			if (playerLvl >= entry.maxlevel + 2) then
            	petLevel = tostring(entry.maxlevel);
			elseif (playerLvl >= entry.maxlevel + 1) then
				petLevel = tostring(playerLvl-2) .. "-" .. tostring(entry.maxlevel);
			else
				petLevel = tostring(playerLvl-2) .. "-" .. tostring(playerLvl);
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
local function GetReadySicRecast()
	--Ready/Sic == ability ID 103
	local readyAbilityID = 102;

	for i = 1,31 do
        local compId = ashita.memory.read_uint8(AbilityRecastPointer + (i * 8) + 3);
        if (compId == readyAbilityID) then
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

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()

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


    if (#args == 2 and args[2]:any('setchr', 'setcharm', 'showstats', 'shownopet')) then
        print('Missing parameter for ' .. args[2]);
        return;
    end

	if (#args == 2 and args[2]:any('resetchr', 'resetcharm')) then
		if (args[2] == 'resetchr') then
        	print("Clearing overide value for +CHR");
			config.chr = nil;
		elseif (args[2] == 'resetcharm') then
			print("Clearing overide value for +Charm");
			config.charm = nil;
		end

		settings.save();
		return;
    end

    if (#args == 3 and args[2]:any('setchr', 'setcharm', 'showstats', 'shownopet', 'showtarget')) then
		if (args[2] == 'setchr') then
        	print("Setting overide value for +CHR to " .. args[3]);
			config.chr = tonumber(args[3]);
		elseif (args[2] == 'setcharm') then
			print("Setting overide value for +Charm to " .. args[3]);
			config.charm = tonumber(args[3]);
		elseif (args[2] == 'showstats') then
			if (args[3] == "true") then
				config.showPetStats = true;
			elseif (args[3] == "false") then
				config.showPetStats = false;
			end
		elseif (args[2] == 'shownopet') then
			if (args[3] == "true") then
				config.showNoPet = true;
			elseif (args[3] == "false") then
				config.showNoPet = false;
			end
		elseif (args[2] == 'showtarget') then
			if (args[3] == "true") then
				config.showPetTarget = true;
			elseif (args[3] == "false") then
				config.showPetTarget = false;
			end
		end

		settings.save();
        return;
    end	
end);

--------------------------------------------------------------------
ashita.events.register('packet_out', 'packet_out_cb', function (e)
	if(e.id == 0xDD) then --Outgoing "check" packet
		if (mobInfo.charmingMob == true) then
			--Modify packet to use the charm target instead of whatever the player is actually targetting
			pktdata = e.data:totable();
			local pckt = struct.pack("BBBBHBBHBBBBBB",pktdata[1],pktdata[2],pktdata[3],pktdata[4],mobInfo.charmMobTarget,pktdata[7],pktdata[8],mobInfo.charmMobTargetIndex,pktdata[11],pktdata[12],pktdata[13],pktdata[14],pktdata[15],pktdata[16]);
			e.data_modified = pckt;	
		end
	end

	if (e.id == 0x1A) then --Outgoing action packet
		local target = struct.unpack('H', e.data, 0x04 + 0x01);
		local targetIndex = struct.unpack('H', e.data, 0x08 + 0x01);
		local category = struct.unpack('H', e.data, 0x0A + 0x01);
		local actionId = struct.unpack('H', e.data, 0x0C + 0x01);

		if (category == 0x09) then --Job Ability
			if (mobInfo.hasPet == false) then --Check to make sure that the player doesn't already have a pet.
				if (actionId == 52) then --Charm
					mobInfo.charmingMob = true;
					--e.blocked = true; --Stop the charm packet from being sent, for debugging

					-- Because players may use different targetting mechanisms, we store the target/index of the mob that
					-- the player is attempting to charm. This can then be used to modify the /check command upon receipt.
					-- This is important, because in the case that the player uses something like /ja "Charm" <stnpc>, the
					-- targetted (i.e. "checked") mob may not be the same as the one being charmed. We could do this by sending
					-- a check packet directly from here, but I found doing it this way to be more consistent. May look into
					-- refining this process a bit more later, but for the moment it works.
					mobInfo.charmMobTarget = target;
					mobInfo.charmMobTargetIndex = targetIndex;

					--Send a Check command
					-- We send a check command prior to charming to get the mob level.
					AshitaCore:GetChatManager():QueueCommand(1, "/check");
					--AshitaCore:GetChatManager():QueueCommand(1, "/check <lastst>");

					--Send "Check" packet 
					--  This simplifies things, but I want to figure out what the other data bytes mean before I feel comfortable sending it regularly
					--local pckt = struct.pack("BBBBHBBHBBBBBB",0xDD,0x08,0x00,0x00,target,0x07,0x01,targetIndex,0x00,0x00,0x00,0xFB,0xEF,0x42);
					--AshitaCore:GetPacketManager():AddOutgoingPacket(0xDD, pckt:totable());
				end

				if (actionId == 85) then --Call Beast
					mobInfo.jugPet = 1;
				end
			end
		end
	end
end);

--------------------------------------------------------------------
ashita.events.register('packet_in', 'packet_in_cb', function (e)

	--Action (action 28, action msg 29)
	--if (e.id == 0x028) then 
		--Possibly use this to determine when call beast is used.
		--Possibly get +chr/+charm & calculate charm duration here.
		--print(e.size);
	--end
	--if (e.id == 0x050) then
	--end

    if (e.id == 0x029) then -- Check packet
		--local target = struct.unpack('H', e.data, 0x04 + 0x01);
		--local targetIndex = struct.unpack('H', e.data, 0x08 + 0x01);
        local param1 = struct.unpack('l', e.data, 0x0C + 0x01);
        local param2 = struct.unpack('L', e.data, 0x10 + 0x01);
		local msg = struct.unpack('H', e.data, 0x18 + 0x01);

        -- If this is a Check packet AND we are attempting to charm a mob
		if ( ((msg >= 0xAA) and (msg <= 0xB2)) or ((param2 >= 0x40) and (param2 <= 0x47))) then -- msg == 0xF9  (impossible to gauge?)

			--When receiving the Check packet and we have just charmed a mob
			if (mobInfo.charmingMob == true) then
				e.blocked = true; --prevent console check text, though other addons (i.e. "checker") will still pick it up and print to console
				mobInfo.mobLevel = param1;
				calculateCharmTime();
				mobInfo.charmingMob = false;
			end
		end
    end

	-- Packet: Pet Sync (copied from PetInfo)
	if (e.id == 0x0068) then
		-- Obtain the player entitiy..
		local player = GetPlayerEntity();
		if (player == nil) then
			mobInfo.target = nil;
			return;
		end
	
		-- Update the players pet target..
		local owner = struct.unpack('I', e.data_modified, 0x08 + 0x01);
		if (owner == player.ServerId) then
			mobInfo.target = struct.unpack('I', e.data_modified, 0x14 + 0x01);
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
    local player = GetPlayerEntity();
	if (player == nil) then -- when zoning
		return;
	end

    local pet = GetEntity(player.PetTargetIndex);
    if (pet == nil) then -- if no pet, set pet to false & return
		mobInfo.hasPet = false;
		--mobInfo.mobLevel = 0;
		--mobInfo.charmingMob = false;
		--mobInfo.charmMobTarget = 0;
		--mobInfo.charmMobTargetIndex = 0;
		--mobInfo.charmUntil = 0;	-- HorizonXI allows jug pets to persist through zoning, so comment out
		--mobInfo.jugPet = 0;		-- HorizonXI allows jug pets to persist through zoning, so comment out

		if (config.showNoPet == false) then
        	return;
		end
    end

	local windowSize = 300;
    imgui.SetNextWindowBgAlpha(0.8);
    imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
	if (imgui.Begin('PetMe', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then

		if (pet == nil) then
			imgui.Text("No pet");
		else
			mobInfo.hasPet = true;

			if (mobInfo.jugPet == 1) then
				calculateJugPetTime(pet.Name);
				mobInfo.jugPet = 2;
			end
			
			-- Obtain pet info
			local petmp = AshitaCore:GetMemoryManager():GetPlayer():GetPetMPPercent();
			local pettp = AshitaCore:GetMemoryManager():GetPlayer():GetPetTP();
			local dist  = ('%.1f'):fmt(math.sqrt(pet.Distance));
			local x, _  = imgui.CalcTextSize(dist);

			-- Display pet name / level / distance
			if (mobInfo.jugPet ~= 0) then
				imgui.Text(pet.Name .. " (Lvl " .. getJugLevel(pet.Name) .. ")");
			elseif (mobInfo.mobLevel > 0) then
				imgui.Text(pet.Name .. " (Lvl " .. tostring(mobInfo.mobLevel) .. ")");
			else
				imgui.Text(pet.Name .. " (Lvl ???)");
			end
			imgui.SameLine();
			imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - x - imgui.GetStyle().FramePadding.x);
			imgui.Text(dist .. "m");

			-- Display pet duration
			if (mobInfo.charmUntil ~= 0) then
				local duration = math.floor(mobInfo.charmUntil - os.clock());
				local hrs = math.floor(duration / 3600);
				local mins = math.floor((duration % 3600) / 60);
				local secs = duration % 60;

				imgui.Text(string.format("Pet Duration: %01d:%02d:%02d", hrs, mins, secs));
			else
				imgui.Text("???");
			end

			-- Display ready/sic recast
			local readyTimer, modifier = GetReadySicRecast();
			if (readyTimer >= 0) then
				if (mobInfo.jugPet ~= 0) then
					local chargesRemaining = math.floor((90 + modifier - readyTimer) / modifier)
					local nextCharge = readyTimer % modifier;
					imgui.Text("Ready: " .. chargesRemaining .. " (" .. tostring(nextCharge) .. "s)");
				else
					imgui.Text("Sic Recast: " .. tostring(readyTimer) .. "s");
				end
			end

			-- Display reward recast
			local rewardTimer, modif = GetRewardRecast();
			if (rewardTimer > 0) then
				imgui.SameLine();
				local reMins = math.floor(rewardTimer / 60);
				local reSecs = rewardTimer % 60;
				rewText = string.format("Reward: %01d:%02d", reMins, reSecs);
				imgui.SetCursorPosX(imgui.GetCursorPosX() + imgui.GetColumnWidth() - imgui.CalcTextSize(rewText));
				imgui.Text(rewText);
			end

			-- Dislay pet stat bars (HPP,MPP,TP)
			if (config.showPetStats == true) then
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
				imgui.ProgressBar(pet.HPPercent / 100, { windowSize/3-10, 15 });

				--Pet MP
				imgui.SameLine();
				imgui.PushStyleColor(ImGuiCol_PlotHistogram, colors.MpBar);
				imgui.ProgressBar(petmp / 100,  { windowSize/3-10, 15 });
				
				--Pet TP
				imgui.SameLine();
				imgui.PushStyleColor(ImGuiCol_PlotHistogram, colors.TpBar);
				imgui.ProgressBar(pettp / 3000,  { windowSize/3-10, 15 }, tostring(pettp));
			end

			-- Display pet's target
			if (config.showPetTarget and mobInfo.target ~= nil and mobInfo.target ~= 0) then
				local target = GetEntityByServerId(mobInfo.target);
				if (target == nil or target.ActorPointer == 0 or target.HPPercent == 0) then
					mobInfo.target = nil;
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
				end
			end

		end
    end
    imgui.End();
end);