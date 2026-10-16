--Author: fear_cro
local ADDON, AI = ...

AI.ADDON = ADDON
AI.VERSION = "0.1.3"
AI.MACRO_NAME = "ActionIconTest"
AI.TEST_SECONDS = 2
AI.results = {}
AI.customEntries = {}
AI.customByID = {}
AI.pendingSerial = 0

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local SUCCESS = "SUCCESSFUL"
local FAILURE = "UNSUCCESSFUL"
local UNTESTED = "UNTESTED"

AI.Colors = {
    normal = { 0.38, 0.67, 0.96 },
    pending = { 1.00, 0.78, 0.16 },
    success = { 0.20, 0.92, 0.32 },
    failure = { 1.00, 0.20, 0.20 },
    muted = { 0.66, 0.69, 0.75 },
}

local function SafeValue(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

function AI.Print(message)
    print("|cff62b4ffActionIcon|r: " .. tostring(message))
end

function AI.GetSpellName(spellID)
    if type(spellID) ~= "number" then return nil end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        name = SafeValue(name)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        name = SafeValue(name)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" then
            local name = SafeValue(info.name)
            if type(name) == "string" and name ~= "" then return name end
        end
    end
end

function AI.GetSpellTexture(spellID)
    if type(spellID) ~= "number" then return nil end
    if GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        texture = SafeValue(texture)
        if ok and (type(texture) == "number" or type(texture) == "string") then return texture end
    end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        texture = SafeValue(texture)
        if ok and (type(texture) == "number" or type(texture) == "string") then return texture end
    end
end

function AI.EntryTexture(entry)
    if not entry then return QUESTION end
    if entry.texture then return entry.texture end
    return AI.GetSpellTexture(entry.id)
        or (entry.icon and ("Interface\\Icons\\" .. entry.icon))
        or QUESTION
end

function AI.EntryKey(section, entry)
    local icon = entry and (entry.icon or entry.texture) or ""
    return tostring(section or "") .. "\031" .. tostring(entry and entry.id or "") .. "\031" .. tostring(icon)
end

function AI.ResultStatus(section, entry)
    return AI.results[AI.EntryKey(section, entry)] or UNTESTED
end

function AI.DisplayStatus(section, entry)
    local key = AI.EntryKey(section, entry)
    if AI.pending and AI.pending.key == key then return "PENDING" end
    return AI.results[key] or UNTESTED
end

local function StatusChanged(section, entry)
    if AI.UpdateDisplayStatus then AI.UpdateDisplayStatus(section, entry) end
    if AI.UIStatusChanged then AI.UIStatusChanged(section, entry) end
end

local function FindMacroIndex()
    if GetMacroInfo then
        local firstCharacter = (tonumber(MAX_ACCOUNT_MACROS) or 120) + 1
        local lastCharacter = firstCharacter + (tonumber(MAX_CHARACTER_MACROS) or 18) - 1
        for index = firstCharacter, lastCharacter do
            local infoOK, name = pcall(GetMacroInfo, index)
            if infoOK and name == AI.MACRO_NAME then return index end
        end
    end
end

local function MacroBody()
    return "/aicallback"
end

function AI.CreateOrUpdateMacro(entry, quiet)
    local entryKey = entry and (tostring(entry.id) .. "\031" .. tostring(entry.icon or entry.texture or "")) or "generic"
    if InCombatLockdown and InCombatLockdown() then
        if AI.macroEntryKey == entryKey then return true end
        if not quiet then AI.Print("The test macro cannot change during combat. Select this spell again after combat, then begin the test.") end
        return false
    end

    local index = FindMacroIndex()
    local body = MacroBody()
    local icon = entry and AI.EntryTexture(entry) or "INV_MISC_QUESTIONMARK"
    local ok, result

    if index and EditMacro then
        ok, result = pcall(EditMacro, index, AI.MACRO_NAME, icon, body, true)
        if not ok then
            ok, result = pcall(EditMacro, index, AI.MACRO_NAME, "INV_MISC_QUESTIONMARK", body, true)
        end
    elseif CreateMacro then
        ok, result = pcall(CreateMacro, AI.MACRO_NAME, icon, body, true)
        if not ok or not result then
            ok, result = pcall(CreateMacro, AI.MACRO_NAME, "INV_MISC_QUESTIONMARK", body, true)
        end
    end

    if not ok or not (index or result) then
        if not quiet then
            AI.Print("The character macro could not be created or updated. Free a character-specific macro slot, then press Create / Update Macro.")
        end
        return false
    end

    AI.macroEntryKey = entryKey
    if not quiet then AI.Print("Character macro " .. AI.MACRO_NAME .. " is ready. Drag it from /macro to an action bar.") end
    return true
end

function AI.CompletePending(status)
    local pending = AI.pending
    if not pending then return false end
    AI.pending = nil
    AI.pendingSerial = AI.pendingSerial + 1
    AI.results[pending.key] = status
    StatusChanged(pending.section, pending.entry)
    return true
end

function AI.BeginTest(entry, section, group)
    if not entry or not section then return false end
    if not AI.CreateOrUpdateMacro(entry, true) then
        AI.Print("This spell was selected, but its test did not start because the macro could not be configured.")
        AI.selected = { entry = entry, section = section, group = group }
        if AI.SetDisplayEntry then AI.SetDisplayEntry(entry, AI.ResultStatus(section, entry)) end
        return false
    end

    if AI.pending then AI.CompletePending(FAILURE) end

    AI.selected = { entry = entry, section = section, group = group }
    AI.pendingSerial = AI.pendingSerial + 1
    local serial = AI.pendingSerial
    local key = AI.EntryKey(section, entry)
    AI.pending = { key = key, entry = entry, section = section, group = group, serial = serial }

    if AI.SetDisplayEntry then AI.SetDisplayEntry(entry, "PENDING") end
    StatusChanged(section, entry)

    local finish = function()
        if AI.pending and AI.pending.serial == serial then AI.CompletePending(FAILURE) end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(AI.TEST_SECONDS, finish)
    else
        local timer = CreateFrame("Frame")
        timer.elapsed = 0
        timer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= AI.TEST_SECONDS then
                self:SetScript("OnUpdate", nil)
                finish()
            end
        end)
    end
    return true
end

function AI.HandleMacroReturn()
    if AI.CompletePending(SUCCESS) then
        AI.Print("a spell was successfully cast")
    else
        AI.Print("No spell test is currently waiting for a macro return.")
    end
end

function AI.AddCustomEntry(spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 or spellID ~= math.floor(spellID) then return nil, "Enter a positive numeric spell ID." end

    local name = AI.GetSpellName(spellID)
    local texture = AI.GetSpellTexture(spellID)
    if not name and not texture then return nil, "That spell ID could not be resolved by the client." end

    local entry = AI.customByID[spellID]
    if not entry then
        entry = { id = spellID, name = name or ("Spell " .. spellID), texture = texture }
        AI.customByID[spellID] = entry
        AI.customEntries[#AI.customEntries + 1] = entry
    else
        entry.name = name or entry.name
        entry.texture = texture or entry.texture
    end
    return entry
end

function AI.ClearCustomResults()
    if AI.pending and AI.pending.section == "CustomID Icons" then AI.CompletePending(FAILURE) end
    for key in pairs(AI.results) do
        if key:match("^CustomID Icons\031") then AI.results[key] = nil end
    end
    wipe(AI.customEntries)
    wipe(AI.customByID)
    if AI.ClearCustomUI then AI.ClearCustomUI() end
    AI.Print("Custom IconID session results cleared.")
end

local function AddReportEntry(lines, indent, section, entry)
    local idLabel = entry.iconOnly and "Texture FileDataID" or "Spell ID"
    local iconRef = entry.icon or entry.texture or AI.GetSpellTexture(entry.id) or "unknown"
    lines[#lines + 1] = indent .. entry.name
        .. " | " .. idLabel .. ": " .. tostring(entry.id)
        .. " | Icon: " .. tostring(iconRef)
        .. " | " .. AI.ResultStatus(section, entry)
end

function AI.BuildReport()
    local lines = {}
    lines[#lines + 1] = "ActionIcon Test Report"
    local timestamp = date and date("%Y-%m-%d %H:%M:%S")
    if timestamp then lines[#lines + 1] = "Generated: " .. timestamp end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "Universal Icons"
    for _, entry in ipairs(AI.Data.Universal) do AddReportEntry(lines, "  ", "Universal Icons", entry) end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "Racial Icons"
    for _, race in ipairs(AI.Data.RaceOrder) do
        lines[#lines + 1] = "  " .. race
        for _, entry in ipairs(AI.Data.Racials[race]) do AddReportEntry(lines, "    ", "Racial Icons", entry) end
    end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "Classes"
    for _, className in ipairs(AI.Data.ClassOrder) do
        lines[#lines + 1] = "  " .. className
        for _, entry in ipairs(AI.Data.Classes[className]) do AddReportEntry(lines, "    ", "Class Icons", entry) end
    end
    lines[#lines + 1] = ""

    lines[#lines + 1] = "Custom IconID"
    if #AI.customEntries == 0 then
        lines[#lines + 1] = "  (no custom IDs tested)"
    else
        local custom = {}
        for i, entry in ipairs(AI.customEntries) do custom[i] = entry end
        table.sort(custom, function(a, b)
            local an, bn = string.lower(a.name or ""), string.lower(b.name or "")
            if an == bn then return a.id < b.id end
            return an < bn
        end)
        for _, entry in ipairs(custom) do AddReportEntry(lines, "  ", "CustomID Icons", entry) end
    end

    return table.concat(lines, "\n")
end

local defaults = {
    iconScale = 1,
    locked = false,
    miniScale = 1,
    miniAlpha = 1,
    miniHidden = false,
}

local function FillDefaults()
    ActionIconDB = ActionIconDB or {}
    for key, value in pairs(defaults) do
        if ActionIconDB[key] == nil then ActionIconDB[key] = value end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        FillDefaults()
        if AI.RestoreDisplay then AI.RestoreDisplay() end
        return
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(1, function() AI.CreateOrUpdateMacro(nil, true) end)
    else
        AI.CreateOrUpdateMacro(nil, true)
    end
    AI.Print("v" .. AI.VERSION .. " loaded. Use /actionicon or right-click the main icon.")
end)

SLASH_ACTIONICON1 = "/actionicon"
SLASH_ACTIONICON2 = "/ai"
SLASH_ACTIONICONRETURN1 = "/aicallback"
SlashCmdList.ACTIONICONRETURN = function()
    AI.HandleMacroReturn()
end

SlashCmdList.ACTIONICON = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$") or "")
    if message == "macro" then
        AI.CreateOrUpdateMacro(AI.selected and AI.selected.entry, false)
    elseif message == "reset" then
        if AI.ResetDisplay then AI.ResetDisplay() end
        if AI.ResetMenu then AI.ResetMenu() end
        AI.Print("Frame positions and sizes reset.")
    elseif AI.ToggleMenu then
        AI.ToggleMenu()
    end
end
