local gui = T{};
local gConfig = require('config');
local imgui = require('imgui');
local settings = require('settings');
local chat = require('chat');
local gFunctions = require('helper');
local genPet = require("petGeneric");
local jugPet = require("petBSTJug");
local charmPet = require("petBSTCharm");
local smnPet = require("petSMN");
local drgPet = require("petDRG");

--------------------------------------------------------------------
gui.renderMenu = function()

	imgui.SetNextWindowSize({500});

	if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), gConfig.params.configMenuOpen, bit.bor(ImGuiWindowFlags_AlwaysAutoResize))) then

		imgui.Text("Display Options");

		imgui.SliderFloat('Window Scale', gConfig.params.settings.window.scale, 0.1, 2.0, '%.2f');
		imgui.ShowHelp('Scale the window bigger/smaller.');

		imgui.SliderFloat('Window Opacity', gConfig.params.settings.window.opacity, 0.1, 1.0, '%.2f');
		imgui.ShowHelp('Set the window opacity.');

		imgui.ColorEdit4("Text Color", gConfig.params.settings.window.textColor);
		imgui.ColorEdit4("Border Color", gConfig.params.settings.window.borderColor);
		imgui.ColorEdit4("Background Color", gConfig.params.settings.window.backgroundColor);

		imgui.Checkbox('Show basic info', gConfig.params.settings.components.petName);
		imgui.ShowHelp('Shows the pet name, level, and distance.');

		imgui.Checkbox('Show duration', gConfig.params.settings.components.petDuration);
		imgui.ShowHelp('Shows the pet duration.');

		imgui.Checkbox('Show pet recast timers', gConfig.params.settings.components.petRecasts);
		imgui.ShowHelp('Shows ready/sic and reward recast timers.');

		imgui.Checkbox('Show pet healing (stay) ticks', gConfig.params.settings.components.petStayCounter);
		imgui.ShowHelp('Shows an estimated countdown until the next time the pet will recover health when stayed.');

		imgui.Checkbox('Show pet stats', gConfig.params.settings.components.petStats);
		imgui.ShowHelp('Shows the pet\'s HP, MP, and TP percentages.');

		imgui.Checkbox('Show pet target', gConfig.params.settings.components.petTarget);
		imgui.ShowHelp('Shows the pet\'s target / remaining HP percent.');

		imgui.Checkbox('Hide window when map is open', gConfig.params.settings.components.hideMap);
		imgui.ShowHelp('Hides the PetMe window when the map is open.');

		imgui.Checkbox('Hide window when log is open', gConfig.params.settings.components.hideLog);
		imgui.ShowHelp('Hides the PetMe window when the log is open.');
			
		imgui.Checkbox('Always Show Window', gConfig.params.settings.components.alwaysVisible);
		imgui.ShowHelp('Shows the PetMe window even when there is no pet.');

        imgui.Separator();
        imgui.Separator();
        imgui.Separator();
		if (imgui.Button('  Reset  ')) then
            settings.reset();
            print(chat.header(addon.name):append(chat.message('Settings reset to default.')));
		end
		imgui.ShowHelp('Resets settings to their default state.');
        imgui.Separator();
        imgui.Separator();
        imgui.Separator();
	end
    --imgui.PopStyleColor(3);
	imgui.End();
end

--------------------------------------------------------------------
function petSpecificGui(petType)
	if (petType == gConfig.petType.CHARMED) then
		charmPet.gui();
	elseif (petType == gConfig.petType.JUG) then
		jugPet.gui();
	elseif (petType == gConfig.petType.SUMMON) then
		smnPet.gui();
	elseif (petType == gConfig.petType.DRAGON) then
		drgPet.gui();
	else --This should not happen
		imgui.Text(pet.Name .. " (Unknown Pet Type: " .. petType .. ")");
	end
end

--------------------------------------------------------------------
gui.renderMainWindow = function()
	local player = GetPlayerEntity();
	local pet = GetEntity(player.PetTargetIndex);

	local windowSize = gConfig.params.windowSize * gConfig.params.settings.window.scale[1];
    imgui.SetNextWindowBgAlpha(gConfig.params.settings.window.opacity[1]);
    imgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
	imgui.PushStyleColor(ImGuiCol_WindowBg, gConfig.params.settings.window.backgroundColor);
	imgui.PushStyleColor(ImGuiCol_Border, gConfig.params.settings.window.borderColor);
	imgui.PushStyleColor(ImGuiCol_Text, gConfig.params.settings.window.textColor);

	if (imgui.Begin('PetMe', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
		imgui.SetWindowFontScale(gConfig.params.settings.window.scale[1]);

		--local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
		--local petIndex = AshitaCore:GetMemoryManager():GetEntity():GetPetTargetIndex(myIndex);
		--local Status = AshitaCore:GetMemoryManager():GetEntity():GetStatus(petIndex);
		--imgui.Text("Status: " .. tostring(Status));
	
		if (pet == nil) then
			imgui.Text("No active pet");
			if (gConfig.params.mobInfo.lastPetType ~= gConfig.petType.NONE and gConfig.params.mobInfo.lastPetType ~= nil) then
				petSpecificGui(gConfig.params.mobInfo.lastPetType);
			end
		else
			-- Display job specific pet info
			if (gConfig.params.mobInfo.petType == gConfig.petType.NONE or gConfig.params.mobInfo.petType == nil) then --If pet type is set to NONE, but pet exists, try and determine type
				if (jugPet.checkIsJugPet(pet.Name) == true) then
					gConfig.params.mobInfo.petType = gConfig.petType.JUG;
				elseif (smnPet.checkIsSummon(pet.Name) == true) then
					gConfig.params.mobInfo.petType = gConfig.petType.SUMMON;
				elseif (drgPet.checkIsDragon(pet.Name) == true) then
					gConfig.params.mobInfo.petType = gConfig.petType.DRAGON;
				else
					gConfig.params.mobInfo.petType = gConfig.petType.CHARMED; --Assumed
				end
			else
				petSpecificGui(gConfig.params.mobInfo.petType);
			end

			gConfig.params.mobInfo.lastPetType = gConfig.params.mobInfo.petType;

			-- Dislay pet stat bars (HPP,MPP,TP)
			if (gConfig.params.settings.components.petStats[1] == true) then
				--imgui.Separator();
				genPet.statBars(pet);
			end

			-- Display pet's target
			if (gConfig.params.settings.components.petTarget[1] and gConfig.params.mobInfo.petTarget ~= nil and gConfig.params.mobInfo.petTarget ~= 0) then
				genPet.targetBar(pet);
			end

		end

		imgui.SetWindowFontScale(1.0); -- reset window scale
    end
    imgui.PopStyleColor(3);
	imgui.End();
end

return gui