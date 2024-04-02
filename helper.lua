gFunctions = T{};

--------------------------------------------------------------------------------
---This function is largely based off of code taken from tCrossBar by Thorny----
--------------------------------------------------------------------------------
local AbilityRecastPointer = ashita.memory.find('FFXiMain.dll', 0, '894124E9????????8B46??6A006A00508BCEE8', 0x19, 0);
AbilityRecastPointer = ashita.memory.read_uint32(AbilityRecastPointer);

gFunctions.GetAbilityTimerData = function(id)
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

gFunctions.GetRewardRecast = function()
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
gFunctions.GetEntityByServerId = function(sid)
    for x = 0, 2303 do
        local ent = GetEntity(x);
        if (ent ~= nil and ent.ServerId == sid) then
            return ent;
        end
    end
    return nil;
end





return gFunctions;
