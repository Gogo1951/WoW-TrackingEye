-- SimpleTrackingEye
-- A simple addon to add a tracking button to the minimap using LibDBIcon.
-- License: MIT

local SimpleTrackingEye = {}
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

-- Ensure UIDropDownMenu library is loaded
if not EasyMenu then
    LoadAddOn("Blizzard_UIDropDownMenu")
end

-- Fallback if EasyMenu still isn't available
if not EasyMenu then
    function EasyMenu(menuList, menuFrame, anchor, xOffset, yOffset, displayMode, autoHideDelay)
        if (not menuFrame or not menuFrame:GetName()) then
            menuFrame = CreateFrame("Frame", "EasyMenuDummyFrame", UIParent, "UIDropDownMenuTemplate")
        end
        UIDropDownMenu_Initialize(menuFrame, function(self, level, menuList)
            for i = 1, #menuList do
                local info = UIDropDownMenu_CreateInfo()
                for k, v in pairs(menuList[i]) do
                    info[k] = v
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end, displayMode, nil, menuList)
        ToggleDropDownMenu(1, nil, menuFrame, anchor, xOffset, yOffset, menuList, nil, autoHideDelay)
    end
end

-- List of tracking spells
local trackingSpells = {
    1494,   -- Track Beasts
    19883,  -- Track Humanoids
    19884,  -- Track Undead
    19885,  -- Track Hidden
    19880,  -- Track Elementals
    19878,  -- Track Demons
    19882,  -- Track Giants
    19879,  -- Track Dragonkin
    5225,   -- Track Humanoids (Druid)
    5500,   -- Sense Demons
    5502,   -- Sense Undead
    2383,   -- Find Herbs
    2580,   -- Find Minerals
    2481    -- Find Treasure
}

-- Create a DataBroker object
local trackingLDB = LDB:NewDataObject("SimpleTrackingEye", {
    type = "data source",
    text = "SimpleTrackingEye",
    icon = "Interface\\Icons\\INV_Misc_Map_01", -- Default icon when no tracking is active
    OnClick = function(_, button)
        if button == "LeftButton" then
            SimpleTrackingEye:OpenTrackingMenu()
        elseif button == "RightButton" then
            SimpleTrackingEye:CancelTrackingBuff()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("SimpleTrackingEye")
        tooltip:AddLine("Left-click to select tracking.")
        tooltip:AddLine("Right-click to cancel tracking.")
    end
})

-- Default minimap button settings
local db = {
    minimap = {
        hide = false, -- This allows users to toggle the minimap button
    }
}

-- Register the minimap button with LibDBIcon
icon:Register("SimpleTrackingEye", trackingLDB, db.minimap)

-- Function to find the spell by ID and cast it
local function CastTrackingSpell(spellId)
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        for spellIndex = 1, numSpells do
            local spellBookIndex = offset + spellIndex
            local spellName, _, spellID = GetSpellBookItemName(spellBookIndex, BOOKTYPE_SPELL)
            if spellID == spellId then
                CastSpell(spellBookIndex, BOOKTYPE_SPELL)
                return
            end
        end
    end
end

-- Function to open the tracking menu
function SimpleTrackingEye:OpenTrackingMenu()
    local menu = {
        { text = "Select Tracking", isTitle = true }
    }

    -- Add only known spells to the menu
    for _, spellId in ipairs(trackingSpells) do
        local spellName = GetSpellInfo(spellId)
        if IsPlayerSpell(spellId) then
            table.insert(menu, {
                text = spellName,
                icon = GetSpellTexture(spellId),
                func = function()
                    CastTrackingSpell(spellId) -- Cast the spell using the new function
                end
            })
        end
    end

    EasyMenu(menu, SimpleTrackingEyeMenu, "cursor", 0, 0, "MENU")
end

-- Function to cancel the current tracking buff
function SimpleTrackingEye:CancelTrackingBuff()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if name and tContains(trackingSpells, spellId) then
            CancelUnitBuff("player", i)
            break
        end
    end
end

-- Event handling for updating tracking icon
local frame = CreateFrame("Frame")
frame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
frame:SetScript("OnEvent", function()
    local trackingTexture = GetTrackingTexture()

    if trackingTexture then
        trackingLDB.icon = trackingTexture
    else
        trackingLDB.icon = "Interface\\Icons\\INV_Misc_Map_01" -- Default icon
    end
end)

-- Hide Blizzard's default tracking button
if MiniMapTrackingFrame then
    MiniMapTrackingFrame:Hide()
end
