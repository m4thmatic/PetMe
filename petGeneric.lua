local settings = require('settings');
local gConfig = require('config');
local imgui = require('imgui');

local gPet = T{};

gPet.statBars = function(pet)
    local windowSize = gConfig.params.windowSize * gConfig.params.settings.window.scale[1];

    if pet.HPPercent > 75 then
        hpBarColor = gConfig.colors.HpBarFull
    elseif pet.HPPercent > 50 then
        hpBarColor = gConfig.colors.HpBar75
    elseif pet.HPPercent > 25 then
        hpBarColor = gConfig.colors.HpBar50
    elseif pet.HPPercent >= 00 then
        hpBarColor = gConfig.colors.HpBar25
    end

    local petmp = AshitaCore:GetMemoryManager():GetPlayer():GetPetMPPercent();
    local pettp = AshitaCore:GetMemoryManager():GetPlayer():GetPetTP();

    imgui.Separator();

    --Pet HP
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, hpBarColor);
    imgui.ProgressBar(pet.HPPercent / 100, { windowSize/3-10, 15*gConfig.params.settings.window.scale[1] });
    imgui.PopStyleColor(1);

    --Pet MP
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, gConfig.colors.MpBar);
    imgui.ProgressBar(petmp / 100,  { windowSize/3-10, 15*gConfig.params.settings.window.scale[1] });
    imgui.PopStyleColor(1);
                    
    --Pet TP
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, gConfig.colors.TpBar);
    imgui.ProgressBar(pettp / 3000,  { windowSize/3-10, 15*gConfig.params.settings.window.scale[1] }, tostring(pettp));
    imgui.PopStyleColor(1);
end


gPet.targetBar = function(pet)
    local windowSize = gConfig.params.windowSize * gConfig.params.settings.window.scale[1];

    local target = gFunctions.GetEntityByServerId(gConfig.params.mobInfo.petTarget);
    if (target == nil or target.ActorPointer == 0 or target.HPPercent == 0) then
        gConfig.params.mobInfo.petTarget = nil;
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
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, gConfig.colors.TargetBar);
        imgui.ProgressBar(target.HPPercent / 100, { -1, 15*gConfig.params.settings.window.scale[1] });
        imgui.PopStyleColor(1);
    end
end


return gPet;