local gConfig = T{};

--local imgui = require('imgui');
local settings = require('settings');
--local chat = require('chat');

------------------------------ENUMS---------------------------------
gConfig.petType = T{
    NONE = 0,
    CHARMED = 1,
    JUG = 2,
    DRAGON = 3,
    SUMMON = 4,
    PUPPET = 5,
	UNKNOWN = -1,
}

------------------------------SETTINGS------------------------------
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

	charmUntil			= T{0}, -- store jug pet charm time, in case of shutdown
}

gConfig.params = T{
	settings = settings.load(defaultConfig);

	windowSize = 300;
	configMenuOpen = {false};

	mobInfo = T{
		petType             = NONE,
		mobLevel 			= 0,
		charmingMob 		= false,
		charmMobTarget 		= 0,
		charmMobTargetIndex = 0,
		charmUntil			= 0,
		petTarget			= nil,
		--jugPetJustCalled 	= false;
		--petStayTicks		= 0;
		bstPet = T{
			commandStay		= false;
			stayTicks		= 0;
		}
	},

}

---------------------------Lookup Tables---------------------------
gConfig.colors = {
	HpBarFull      = { 0.10, 0.60, 0.10, 1.0 },
	HpBar75        = { 0.70, 0.60, 0.10, 1.0 },
	HpBar50        = { 0.80, 0.40, 0.10, 1.0 },
	HpBar25        = { 0.80, 0.10, 0.10, 1.0 },
	MpBar          = { 0.20, 0.20, 0.80, 1.0 },
	TpBar          = { 0.40, 0.40, 0.40, 1.0 },
	TargetBar      = { 0.70, 0.40, 0.40, 1.0 },
}


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
gConfig.hideWindow = function ()
    local menuName = GetMenuName();
		
	if (gConfig.params.settings.components.hideMap[1] == true) then
		if ( string.match(menuName, 'map') or
		     string.match(menuName, 'cnqframe')
		   ) then
			return true;
		end
	end

	if (gConfig.params.settings.components.hideLog[1] == true) then
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
settings.register('settings', 'settings_update', function(s)
    -- Update the settings table..
    if (s ~= nil) then
        gConfig.params.settings = s;
    end

    -- Save the current settings..
    settings.save();
end);

return gConfig;