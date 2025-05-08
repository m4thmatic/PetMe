-----------------------------INCLUDE--------------------------------
local gConfig = require('config');
local charmedPet = require('petBSTCharm');
local jugPet = require('petBSTJug');

------------------------------ENUMS---------------------------------
local outPacket = T{
    ACTION      = 0x001A,
    CHECK       = 0x00DD,
}

local inPacket = T{
    ACTION      = 0x0028,
    CHECK       = 0x0029,
    PET_SYNC    = 0x0068,
}

local actionPacketAbilityID = T{
    FAMILIAR    = 0x18,
    CHARM       = 0x34,
    GAGUE       = 0x35,
    TAME        = 0x36,
    FIGHT       = 0x45,
    HEEL        = 0x46,
    LEAVE       = 0x47,
    SIC         = 0x48,
    STAY        = 0x49,
    REWARD      = 0x4E,
    CALL_BEAST  = 0x55,
    READY       = 0x163, --Note, pet is actor. Ability ID for self actor is ready ability number (e.g. Lamb Chop is 0x2b1)
    BST_LOYALTY = 0x183,
}

local charmStates = T{
    CHARM_NONE          = 0,
    CHARM_SENDING_PCK   = 1,
    CHARM_CHECK_PCK     = 2,
}

local outPacketActionCategory = T{
    JOB_ABILITY = 0x09,
}

------------------------------VARS----------------------------------
local gPackets = T{};
local charmState = charmStates.CHARM_NONE;
local charmTarget = nil;
local charmTargetIdx = nil;

--------------------------------------------------------------------
gPackets.packet_out_cb = function (e)
	if(e.id == outPacket.CHECK) then --Outgoing "check" packet
		if (charmState == charmStates.CHARM_SENDING_PCK) then
			--Modify packet to use the charm target instead of whatever the player is actually targetting
			pktdata = e.data:totable();
            --Packet structure: https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua, line 954
			local pckt = struct.pack("BBBBHBBHBBBBBB", pktdata[1], pktdata[2], pktdata[3], pktdata[4],
                                                       charmTarget, pktdata[7], pktdata[8], charmTargetIdx,
                                                       pktdata[11], pktdata[12], pktdata[13], pktdata[14],
                                                       pktdata[15], pktdata[16]);
			e.data_modified = pckt;
            charmState = charmStates.CHARM_CHECK_PCK;
		end
        --pktdata = e.data:totable();
        --print(pktdata[13]); --This is the /checkparam flag (0 for normal check, 2 for checkparam)
	end

	if (e.id == outPacket.ACTION) then --Outgoing action packet
        --Packet structure: https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua, line 363
		local target        = struct.unpack('H', e.data, 0x04 + 0x01);
		local targetIndex   = struct.unpack('H', e.data, 0x08 + 0x01);
		local category      = struct.unpack('H', e.data, 0x0A + 0x01);
		local actionId      = struct.unpack('H', e.data, 0x0C + 0x01);

        --For debugging
		--print("Category: " .. string.format("0x%x", category) .. " -- Action ID: " .. string.format("0x%x", actionId));

		if (category == outPacketActionCategory.JOB_ABILITY) then --Job Ability
			if (gConfig.params.mobInfo.petType == gConfig.petType.NONE) then --Check to make sure that the player doesn't already have a pet.
				if (actionId == actionPacketAbilityID.CHARM) then --Charm
					--e.blocked = true; --Stop the charm packet from being sent, for debugging

                    --Set state to sent
                    charmState = charmStates.CHARM_SENDING_PCK;

					-- Because players may use different targetting mechanisms, store the target/index of the mob that
					-- the player is attempting to charm. This can then be used to modify the /check command upon receipt.
					-- This is important, because in the case that the player uses something like /ja "Charm" <stnpc>, the
					-- targetted (i.e. "checked") mob may not be the same as the one being charmed.
					charmTarget = target;
					charmTargetIdx = targetIndex;

					--Send a check command prior to charming to get the mob level & set flag
					AshitaCore:GetChatManager():QueueCommand(1, "/check");
				end
			end
		end
	end
end

--------------------------------------------------------------------
--ashita.events.register('packet_in', 'packet_in_cb', function (e)
gPackets.packet_in_cb = function (e)

    if (e.id == inPacket.CHECK) then --Incomming check packet
        --Packet structure: https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua, line 1865
        local param1 = struct.unpack('l', e.data, 0x0C + 0x01);
        local param2 = struct.unpack('L', e.data, 0x10 + 0x01);
		local msg    = struct.unpack('H', e.data, 0x18 + 0x01);
        -- If this is a Check packet AND we are attempting to charm a mob
        if (charmState == charmStates.CHARM_CHECK_PCK) then
            if ( ((msg >= 0xAA) and (msg <= 0xB2)) or ((param2 >= 0x40) and (param2 <= 0x47))) then -- msg == 0xF9  (impossible to gauge, not relevant)
				e.blocked = true; --prevent console check text, though other addons (i.e. "checker") will still pick it up and print to console
				gConfig.params.mobInfo.mobLevel = param1;
				gConfig.params.mobInfo.charmUntil = charmedPet.calculateCharmTime(param1);
			end
            charmState = charmStates.CHARM_NONE;
		end
    elseif (e.id == inPacket.ACTION) then --Incomming action packet
        --Packet structure: https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua, line 1816
        local actor     = struct.unpack('I', e.data, 0x05 + 0x01);
		local abilityID = bit.band(bit.rshift(struct.unpack('H', e.data, 0x0A + 0x01),6), 0xffff);

        --For debugging
        --print("Ability ID: " .. string.format("0x%x", abilityID) .. " -- pidx: " .. playerIdx .. " -- act: " .. actor);
 
        if (actor == AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0)) then
            if (abilityID == actionPacketAbilityID.CHARM) then
                gConfig.params.mobInfo.petType = gConfig.petType.CHARMED;
            elseif (abilityID == actionPacketAbilityID.CALL_BEAST) then --Call Beast
                gConfig.params.mobInfo.petType = gConfig.petType.JUG;
                jugPet.newJug();
            elseif (abilityID == actionPacketAbilityID.STAY) then --Stay
                if (gConfig.params.mobInfo.bstPet.stayTicks == 0) then        --If stay counter is not already counting
                    gConfig.params.mobInfo.bstPet.stayTicks = os.time() + 20; --Initialize the stay counter
                end
            elseif (abilityID == actionPacketAbilityID.HEEL) then --Heel
                gConfig.params.mobInfo.bstPet.stayTicks = 0; --Reset the stay counter
            elseif (abilityID == actionPacketAbilityID.LEAVE) then --Heel
                gConfig.params.mobInfo.petType = gConfig.petType.NONE;
                gConfig.params.mobInfo.bstPet.stayTicks = 0; --Reset the stay counter
                --jugPet.newJug(); --
            end
        end
	elseif (e.id == inPacket.PET_SYNC) then --Incomming Pet Sync Packet
		--Get the player entity
		local player = GetPlayerEntity();
		
        if (player == nil) then
			gConfig.params.mobInfo.petTarget = nil;
		else
            --Update the pet's target
            local ownerIdx = struct.unpack('I', e.data_modified, 0x08 + 0x01);
            if (ownerIdx == player.ServerId) then
                gConfig.params.mobInfo.petTarget = struct.unpack('I', e.data_modified, 0x14 + 0x01);
            end
        end
    end
end

return gPackets;