local ADDON, AI = ...

local menu
local activeTab = "Universal Icons"
local activeClass = "Druid"
local tabButtons, classButtons = {}, {}
local itemPool, headerPool = {}, {}
local scroll, scrollChild, customPanel, reportPanel
local customIcon, customName, customStatus, customEntry
local reportEdit

local CONTENT_WIDTH = 900
local CELL_HEIGHT = 48
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function Backdrop()
    return {
        bgFile = WHITE,
        edgeFile = WHITE,
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }
end

local function ColorFor(status)
    if status == "PENDING" then return AI.Colors.pending end
    if status == "SUCCESSFUL" then return AI.Colors.success end
    if status == "UNSUCCESSFUL" then return AI.Colors.failure end
    return AI.Colors.normal
end

local function PaintEntryButton(button)
    if not button.entry then return end
    local status = AI.DisplayStatus(button.section, button.entry)
    local color = ColorFor(status)
    button:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    button.label:SetTextColor(color[1], color[2], color[3], 1)
    button.status = status
end

local function EntryTooltip(button)
    local entry = button.entry
    if not entry then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddLine((entry.iconOnly and "Texture FileDataID: " or "Spell ID: ") .. tostring(entry.id), 0.72, 0.76, 0.82)
    GameTooltip:AddLine("Result: " .. tostring(button.status or "UNTESTED"), 1, 0.82, 0)
    GameTooltip:AddLine("Click to begin a 2-second test", 0.82, 0.84, 0.88)
    GameTooltip:Show()
end

local function AcquireItem(index)
    local button = itemPool[index]
    if button then return button end

    button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    button:SetHeight(42)
    button:SetBackdrop(Backdrop())
    button:SetBackdropColor(0.035, 0.045, 0.065, 0.92)

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetColorTexture(1, 1, 1, 0.07)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(34, 34)
    button.icon:SetPoint("LEFT", 4, 0)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
    button.label:SetPoint("RIGHT", button, "RIGHT", -7, 0)
    button.label:SetJustifyH("LEFT")
    if button.label.SetWordWrap then button.label:SetWordWrap(false) end

    button:SetScript("OnClick", function(self)
        if self.entry then AI.BeginTest(self.entry, self.section, self.group) end
    end)
    button:SetScript("OnEnter", EntryTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    itemPool[index] = button
    return button
end

local function AcquireHeader(index)
    local header = headerPool[index]
    if header then return header end
    header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetTextColor(1, 0.82, 0.18)
    header:SetJustifyH("LEFT")
    headerPool[index] = header
    return header
end

local function HideCatalogObjects()
    for _, button in ipairs(itemPool) do
        button:Hide()
        button.entry, button.section, button.group = nil, nil, nil
    end
    for _, header in ipairs(headerPool) do header:Hide() end
end

local function SetItem(button, entry, section, group, x, y, width)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x, y)
    button:SetWidth(width)
    button.entry, button.section, button.group = entry, section, group
    button.icon:SetTexture(AI.EntryTexture(entry))
    button.label:SetText(entry.name)
    PaintEntryButton(button)
    button:Show()
end

local function RenderSimple(entries, columns, section, group)
    HideCatalogObjects()
    local gap = 10
    local width = math.floor((CONTENT_WIDTH - gap * (columns - 1)) / columns)
    for index, entry in ipairs(entries) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        SetItem(AcquireItem(index), entry, section, group, column * (width + gap), -row * CELL_HEIGHT, width)
    end
    local rows = math.ceil(#entries / columns)
    scrollChild:SetHeight(math.max(1, rows * CELL_HEIGHT + 8))
    scroll:SetVerticalScroll(0)
end

local function RenderRacials()
    HideCatalogObjects()
    local itemIndex, headerIndex, y = 0, 0, 0
    local gap = 12
    local width = math.floor((CONTENT_WIDTH - gap) / 2)
    for _, race in ipairs(AI.Data.RaceOrder) do
        headerIndex = headerIndex + 1
        local header = AcquireHeader(headerIndex)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, y)
        header:SetText(race)
        header:Show()
        y = y - 25
        for column, entry in ipairs(AI.Data.Racials[race]) do
            itemIndex = itemIndex + 1
            SetItem(AcquireItem(itemIndex), entry, "Racial Icons", race, (column - 1) * (width + gap), y, width)
        end
        y = y - 56
    end
    scrollChild:SetHeight(math.max(1, -y + 4))
    scroll:SetVerticalScroll(0)
end

local function PaintTabs()
    for name, button in pairs(tabButtons) do
        local active = name == activeTab
        button.bg:SetColorTexture(active and 0.16 or 0.055, active and 0.34 or 0.07, active and 0.52 or 0.10, 1)
        button.text:SetTextColor(active and 1 or 0.70, active and 0.86 or 0.72, active and 0.30 or 0.78, 1)
    end
    for name, button in pairs(classButtons) do
        local active = activeTab == "Class Icons" and name == activeClass
        button.bg:SetColorTexture(active and 0.18 or 0.05, active and 0.38 or 0.06, active and 0.20 or 0.08, 1)
        button.text:SetTextColor(active and 0.40 or 0.68, active and 1 or 0.70, active and 0.46 or 0.76, 1)
    end
end

local function ShowTab(name)
    activeTab = name
    local classes = name == "Class Icons"
    for _, button in pairs(classButtons) do button:SetShown(classes) end

    scroll:Hide()
    customPanel:Hide()
    reportPanel:Hide()

    if name == "Universal Icons" then
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 24, -92)
        scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -42, 42)
        scroll:Show()
        RenderSimple(AI.Data.Universal, 3, "Universal Icons", "Universal")
    elseif name == "Racial Icons" then
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 24, -92)
        scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -42, 42)
        scroll:Show()
        RenderRacials()
    elseif name == "Class Icons" then
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 24, -126)
        scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -42, 42)
        scroll:Show()
        RenderSimple(AI.Data.Classes[activeClass], 3, "Class Icons", activeClass)
    elseif name == "CustomID Icons" then
        HideCatalogObjects()
        customPanel:Show()
    elseif name == "Report" then
        HideCatalogObjects()
        reportPanel:Show()
    end
    PaintTabs()
end

local function CreateTab(name, index)
    local button = CreateFrame("Button", nil, menu)
    button:SetSize(174, 30)
    button:SetPoint("TOPLEFT", menu, "TOPLEFT", 25 + (index - 1) * 180, -44)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(name)
    button:SetScript("OnClick", function() ShowTab(name) end)
    tabButtons[name] = button
end

local function CreateClassTab(name, index)
    local button = CreateFrame("Button", nil, menu)
    button:SetSize(96, 26)
    button:SetPoint("TOPLEFT", menu, "TOPLEFT", 27 + (index - 1) * 100, -80)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER")
    button.text:SetText(name)
    button:SetScript("OnClick", function()
        activeClass = name
        ShowTab("Class Icons")
    end)
    classButtons[name] = button
end

local function CreateCustomPanel()
    local panel = CreateFrame("Frame", nil, menu)
    panel:SetPoint("TOPLEFT", menu, "TOPLEFT", 24, -92)
    panel:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -24, 42)
    customPanel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("Custom Spell ID Test")
    title:SetTextColor(1, 0.82, 0.18)

    local help = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    help:SetText("Enter a numeric spell ID. Test resolves its client icon, updates both display icons, configures the macro, and begins the two-second return window.")
    help:SetWidth(820)
    help:SetJustifyH("LEFT")

    local input = CreateFrame("EditBox", "ActionIconCustomIDInput", panel, "InputBoxTemplate")
    input:SetSize(220, 30)
    input:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 4, -24)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(10)
    input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local inputLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("BOTTOMLEFT", input, "TOPLEFT", -4, 4)
    inputLabel:SetText("Spell ID")

    local test = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    test:SetSize(110, 28)
    test:SetPoint("LEFT", input, "RIGHT", 12, 0)
    test:SetText("Test")

    local clear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clear:SetSize(140, 28)
    clear:SetPoint("LEFT", test, "RIGHT", 10, 0)
    clear:SetText("Clear Results")
    clear:SetScript("OnClick", AI.ClearCustomResults)

    local iconFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    iconFrame:SetSize(86, 86)
    iconFrame:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -2, -32)
    iconFrame:SetBackdrop(Backdrop())
    iconFrame:SetBackdropColor(0.03, 0.04, 0.06, 1)
    iconFrame:SetBackdropBorderColor(AI.Colors.normal[1], AI.Colors.normal[2], AI.Colors.normal[3], 1)

    customIcon = iconFrame:CreateTexture(nil, "ARTWORK")
    customIcon:SetPoint("TOPLEFT", 6, -6)
    customIcon:SetPoint("BOTTOMRIGHT", -6, 6)
    customIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    customIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    customIcon:SetAlpha(0.35)
    customIcon.frame = iconFrame

    customName = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    customName:SetPoint("LEFT", iconFrame, "RIGHT", 18, 12)
    customName:SetText("No custom ID tested")
    customName:SetTextColor(AI.Colors.muted[1], AI.Colors.muted[2], AI.Colors.muted[3])

    customStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    customStatus:SetPoint("LEFT", iconFrame, "RIGHT", 18, -14)
    customStatus:SetText("UNTESTED")

    test:SetScript("OnClick", function()
        input:ClearFocus()
        local entry, errorMessage = AI.AddCustomEntry(input:GetText())
        if not entry then
            AI.Print(errorMessage)
            return
        end
        customEntry = entry
        customIcon:SetTexture(AI.EntryTexture(entry))
        customIcon:SetAlpha(1)
        customName:SetText(entry.name .. "  (" .. entry.id .. ")")
        AI.BeginTest(entry, "CustomID Icons", "Custom")
    end)
end

local function CreateReportPanel()
    local panel = CreateFrame("Frame", nil, menu)
    panel:SetPoint("TOPLEFT", menu, "TOPLEFT", 24, -92)
    panel:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -24, 42)
    reportPanel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 6, -6)
    title:SetText("Test Report")
    title:SetTextColor(1, 0.82, 0.18)

    local show = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    show:SetSize(130, 28)
    show:SetPoint("TOPRIGHT", -8, -4)
    show:SetText("Show Results")

    local help = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    help:SetText("Show Results rebuilds the complete report and selects all text for copying. Untested catalog entries remain listed as UNTESTED.")
    help:SetWidth(760)
    help:SetJustifyH("LEFT")

    local editScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    editScroll:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 2, -12)
    editScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 4)

    local edit = CreateFrame("EditBox", "ActionIconReportEditBox", editScroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    if edit.SetTextInsets then edit:SetTextInsets(8, 8, 8, 8) end
    edit:SetWidth(835)
    edit:SetHeight(1)
    edit:SetMaxLetters(0)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editScroll:SetScrollChild(edit)
    reportEdit = edit

    show:SetScript("OnClick", function()
        local text = AI.BuildReport()
        reportEdit:SetText(text)
        reportEdit:SetHeight(math.max(520, (reportEdit:GetStringHeight() or 0) + 24))
        reportEdit:SetCursorPosition(0)
        reportEdit:HighlightText(0, -1)
        reportEdit:SetFocus()
        editScroll:SetVerticalScroll(0)
    end)
end

local function BuildMenu()
    if menu then return end

    menu = CreateFrame("Frame", "ActionIconMenu", UIParent, "BackdropTemplate")
    menu:SetSize(980, 710)
    menu:SetPoint("CENTER")
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:SetMovable(true)
    menu:EnableMouse(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    menu:SetBackdropColor(0.02, 0.025, 0.04, 0.98)
    menu:SetBackdropBorderColor(0.25, 0.55, 0.90, 1)
    menu:SetScript("OnDragStart", function(self) self:StartMoving() end)
    menu:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        ActionIconDB.menuPosition = { point, relativePoint, x, y }
    end)
    menu:SetScript("OnHide", function() if reportEdit then reportEdit:ClearFocus() end end)

    local saved = ActionIconDB and ActionIconDB.menuPosition
    if type(saved) == "table" and saved[1] and saved[2] then
        menu:ClearAllPoints()
        menu:SetPoint(saved[1], UIParent, saved[2], saved[3] or 0, saved[4] or 0)
    end

    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 24, -18)
    title:SetText("ActionIcon  |  Forever Spell Test Environment")
    title:SetTextColor(0.38, 0.71, 1)

    local close = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local macro = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    macro:SetSize(170, 24)
    macro:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, -3)
    macro:SetText("Create / Update Macro")
    macro:SetScript("OnClick", function() AI.CreateOrUpdateMacro(AI.selected and AI.selected.entry, false) end)

    local names = { "Universal Icons", "Racial Icons", "Class Icons", "CustomID Icons", "Report" }
    for index, name in ipairs(names) do CreateTab(name, index) end
    for index, className in ipairs(AI.Data.ClassOrder) do CreateClassTab(className, index) end

    scroll = CreateFrame("ScrollFrame", "ActionIconCatalogScroll", menu, "UIPanelScrollFrameTemplate")
    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(CONTENT_WIDTH, 1)
    scroll:SetScrollChild(scrollChild)

    CreateCustomPanel()
    CreateReportPanel()

    local footer = menu:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT", 24, 18)
    footer:SetText("Click an icon, then click ActionIconTest on your action bar within 2 seconds.  /actionicon  /ai")

    ShowTab(activeTab)
    menu:Hide()
end

function AI.UIStatusChanged(section, entry)
    for _, button in ipairs(itemPool) do
        if button:IsShown() and button.entry and button.section == section and AI.EntryKey(section, button.entry) == AI.EntryKey(section, entry) then
            PaintEntryButton(button)
        end
    end

    if customEntry and section == "CustomID Icons" and AI.EntryKey(section, customEntry) == AI.EntryKey(section, entry) then
        local status = AI.DisplayStatus(section, customEntry)
        local color = ColorFor(status)
        customIcon.frame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
        customName:SetTextColor(color[1], color[2], color[3], 1)
        customStatus:SetText(status)
        customStatus:SetTextColor(color[1], color[2], color[3], 1)
    end
end

function AI.ClearCustomUI()
    customEntry = nil
    if not customIcon then return end
    customIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    customIcon:SetAlpha(0.35)
    customName:SetText("No custom ID tested")
    customName:SetTextColor(AI.Colors.muted[1], AI.Colors.muted[2], AI.Colors.muted[3])
    customStatus:SetText("UNTESTED")
    customStatus:SetTextColor(1, 1, 1)
    customIcon.frame:SetBackdropBorderColor(AI.Colors.normal[1], AI.Colors.normal[2], AI.Colors.normal[3], 1)
end

function AI.ToggleMenu()
    BuildMenu()
    menu:SetShown(not menu:IsShown())
end

function AI.ResetMenu()
    if ActionIconDB then ActionIconDB.menuPosition = nil end
    if menu then
        menu:ClearAllPoints()
        menu:SetPoint("CENTER")
    end
end
