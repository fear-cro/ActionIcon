--Author: fear_cro
local ADDON, AI = ...

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local BASE_SIZE = 56

local frame = CreateFrame("Button", "ActionIconMainFrame", UIParent, "BackdropTemplate")
frame:SetSize(BASE_SIZE, BASE_SIZE)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:RegisterForClicks("RightButtonUp")
frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
frame:SetBackdropColor(0.03, 0.04, 0.06, 0.92)
AI.mainFrame = frame

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(44, 44)
icon:SetPoint("CENTER")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
icon:SetTexture(QUESTION)
AI.mainTexture = icon

local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("TOP", frame, "BOTTOM", 0, -2)
statusText:SetTextColor(0.75, 0.78, 0.84)
statusText:SetText("READY")

local grip = CreateFrame("Button", nil, frame)
grip:SetSize(12, 12)
grip:SetPoint("BOTTOMRIGHT", -1, 1)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

local mini = CreateFrame("Frame", "ActionIconMiniFrame", UIParent)
local miniTexture = mini:CreateTexture(nil, "OVERLAY")
miniTexture:SetAllPoints(mini)
miniTexture:Hide()
AI.miniFrame = mini
AI.miniTexture = miniTexture

local MINI_PX, MINI_X, MINI_Y = 18, 19, 7

-- Preserve ActionLITE's sharp physical-pixel rendering if another addon hooks
-- SetTexture and changes the texture's pixel-grid settings.
local snapOn = miniTexture.IsSnappingToPixelGrid and miniTexture:IsSnappingToPixelGrid()
local snapBias = miniTexture.GetTexelSnappingBias and miniTexture:GetTexelSnappingBias()
local function SetSharpMiniTexture(path)
    miniTexture:SetTexture(path)
    if snapOn ~= nil and miniTexture.SetSnapToPixelGrid then miniTexture:SetSnapToPixelGrid(snapOn) end
    if snapBias ~= nil and miniTexture.SetTexelSnappingBias then miniTexture:SetTexelSnappingBias(snapBias) end
end

local miniHeight, miniEffective, miniScale = 0, 0, 0

local function LayoutMini(force)
    local factor = tonumber(ActionIconDB and ActionIconDB.miniScale) or 1
    factor = math.max(0.5, math.min(2, factor))
    if not GetPhysicalScreenSize then
        if force or miniHeight == 0 or factor ~= miniScale then
            miniHeight, miniScale = -1, factor
            mini:SetSize(MINI_PX * factor, MINI_PX * factor)
            mini:ClearAllPoints()
            mini:SetPoint("TOPLEFT", UIParent, "TOPLEFT", MINI_X, MINI_Y)
        end
        return
    end

    local _, physicalHeight = GetPhysicalScreenSize()
    local effective = UIParent:GetEffectiveScale()
    if type(physicalHeight) ~= "number" or physicalHeight <= 0 or type(effective) ~= "number" or effective <= 0 then return end
    if not force and physicalHeight == miniHeight and effective == miniEffective and factor == miniScale then return end

    miniHeight, miniEffective, miniScale = physicalHeight, effective, factor
    local pixel = 768 / (physicalHeight * effective)
    mini:SetSize(MINI_PX * pixel * factor, MINI_PX * pixel * factor)
    mini:ClearAllPoints()
    mini:SetPoint("TOPLEFT", UIParent, "TOPLEFT", MINI_X * pixel, MINI_Y * pixel)
end

local function ApplyStatus(status)
    local color = AI.Colors.normal
    local label = "READY"
    if status == "PENDING" then
        color, label = AI.Colors.pending, "WAITING"
    elseif status == "SUCCESSFUL" then
        color, label = AI.Colors.success, "SUCCESS"
    elseif status == "UNSUCCESSFUL" then
        color, label = AI.Colors.failure, "FAILED"
    end
    frame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    statusText:SetTextColor(color[1], color[2], color[3], 1)
    statusText:SetText(label)
end

function AI.SetDisplayEntry(entry, status)
    AI.displayEntry = entry
    local texture = AI.EntryTexture(entry)
    icon:SetTexture(texture or QUESTION)
    icon:SetVertexColor(1, 1, 1, 1)
    SetSharpMiniTexture(texture or QUESTION)
    miniTexture:SetVertexColor(1, 1, 1, 1)
    miniTexture:SetShown(entry ~= nil and not (ActionIconDB and ActionIconDB.miniHidden))
    ApplyStatus(status)
    LayoutMini()
end

function AI.ClearMiniIcon()
    miniTexture:Hide()
    miniTexture:SetTexture(nil)
end

function AI.UpdateDisplayStatus(section, entry)
    if not AI.selected or AI.selected.entry ~= entry or AI.selected.section ~= section then return end
    AI.SetDisplayEntry(entry, AI.DisplayStatus(section, entry))
end

local function SavePosition()
    ActionIconDB = ActionIconDB or {}
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    ActionIconDB.iconPosition = { point, relativePoint, x, y }
end

frame:SetScript("OnDragStart", function(self)
    if not (ActionIconDB and ActionIconDB.locked) then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)
frame:SetScript("OnClick", function(_, button)
    if button == "RightButton" and AI.ToggleMenu then AI.ToggleMenu() end
end)
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("ActionIcon", 0.38, 0.71, 1)
    if AI.displayEntry then
        GameTooltip:AddLine(AI.displayEntry.name, 1, 1, 1)
        GameTooltip:AddLine("ID: " .. tostring(AI.displayEntry.id), 0.72, 0.75, 0.80)
    else
        GameTooltip:AddLine("No spell selected", 0.72, 0.75, 0.80)
    end
    GameTooltip:AddLine("Drag: move  |  Corner: scale", 1, 0.82, 0)
    GameTooltip:AddLine("Right-click: open test menu", 1, 0.82, 0)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

local sizing = false
grip:SetScript("OnMouseDown", function()
    if not (ActionIconDB and ActionIconDB.locked) then sizing = true end
end)
grip:SetScript("OnMouseUp", function()
    if not sizing then return end
    sizing = false
    SavePosition()
end)
grip:SetScript("OnHide", function() sizing = false end)
grip:SetScript("OnUpdate", function()
    if not sizing then return end
    local cursorX = GetCursorPosition()
    local effective = frame:GetEffectiveScale()
    local leftPixels, topPixels = frame:GetLeft() * effective, frame:GetTop() * effective
    local scale = math.max(0.5, math.min(2, (cursorX - leftPixels) / BASE_SIZE / UIParent:GetEffectiveScale()))
    ActionIconDB.iconScale = scale
    frame:SetScale(scale)
    effective = frame:GetEffectiveScale()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", leftPixels / effective, topPixels / effective)
end)

function AI.RestoreDisplay()
    ActionIconDB = ActionIconDB or {}
    frame:SetScale(tonumber(ActionIconDB.iconScale) or 1)
    frame:EnableMouse(not ActionIconDB.locked)
    grip:SetShown(not ActionIconDB.locked)

    local position = ActionIconDB.iconPosition
    if type(position) == "table" and position[1] and position[2] then
        frame:ClearAllPoints()
        frame:SetPoint(position[1], UIParent, position[2], position[3] or 0, position[4] or 0)
    end

    local alpha = tonumber(ActionIconDB.miniAlpha) or 1
    mini:SetAlpha(math.max(0, math.min(1, alpha)))
    mini:SetShown(not ActionIconDB.miniHidden)
    LayoutMini(true)
    AI.SetDisplayEntry(AI.displayEntry, AI.displayEntry and "UNTESTED" or nil)
end

function AI.ResetDisplay()
    ActionIconDB = ActionIconDB or {}
    ActionIconDB.iconPosition = nil
    ActionIconDB.iconScale = 1
    frame:SetScale(1)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
end

LayoutMini(true)
ApplyStatus(nil)
