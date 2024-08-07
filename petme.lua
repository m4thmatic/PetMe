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

addon.author   = 'Mathemagic';
addon.name     = 'PetMe';
addon.desc     = 'Displays detailed pet information.';
addon.version  = '2.1.1';

require ('common');
local gPackets = require('packets');
local gGui = require('gui');
local gConfig = require('config');
local settings = require('settings');

--------------------------------------------------------------------
--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function()

end);

--------------------------------------------------------------------
--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function()
    settings.save();
end);

--------------------------------------------------------------------
--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/petme', '/pm')) then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

	if (#args == 1) then
		gConfig.params.configMenuOpen[1] = not gConfig.params.configMenuOpen[1];
	end
end);

--------------------------------------------------------------------
--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
	gPackets.packet_in_cb(e);
end);

--------------------------------------------------------------------
--[[
* event: packet_out
* desc : Event called when the addon is processing outgoing packets.
--]]
ashita.events.register('packet_out', 'packet_out_cb', function (e)
	gPackets.packet_out_cb(e);
end);


--------------------------------------------------------------------
--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'd3d_present_cb', function ()
	if (gConfig.hideWindow() == false) then
		local player = GetPlayerEntity();
		if (player == nil) then -- when zoning
			return;
		end

		if (gConfig.params.configMenuOpen[1] == true) then
			gGui.renderMenu();
		end
		
		local pet = GetEntity(player.PetTargetIndex);
		if (pet == nil) then -- if no pet, set pet to false & return
			gConfig.params.mobInfo.petType = gConfig.petType.NONE;
		end

		if ((pet ~= nil) or (gConfig.params.settings.components.alwaysVisible[1] == true)) then
			gGui.renderMainWindow();
		end
	end
end);

--------------------------------------------------------------------
ashita.events.register('text_in', 'text_in_cb', function (e)
    if (e.injected == true) then
        return;
    end

	--if (e.mode == 191) then
	--	if (string.match(e.message, "Primary Accuracy:")) then
	--		print (string.match(e.message, "%d+"));
	--	end
	--end

	--print(e.mode);
	--print(" > " .. e.message);
end);