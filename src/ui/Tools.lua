setfenv(1, Gromissingcrafts)

---@type ScriptType[]
local SCRIPT_TYPES = {
    "OnAnimFinished",
    "OnChar",
    "OnClick",
    "OnColorSelect",
    "OnCursorChanged",
    "OnDoubleClick",
    "OnDragStart",
    "OnDragStop",
    "OnEditFocusGained",
    "OnEditFocusLost",
    "OnEnter",
    "OnEnterPressed",
    "OnEscapePressed",
    "OnEvent",
    "OnHide",
    "OnHorizontalScroll",
    "OnHyperlinkClick",
    "OnHyperlinkEnter",
    "OnHyperlinkLeave",
    "OnInputLanguageChanged",
    "OnKeyDown",
    "OnKeyUp",
    "OnLeave",
    "OnLoad",
    "OnMessageScrollChanged",
    "OnMouseDown",
    "OnMouseUp",
    "OnMouseWheel",
    "OnReceiveDrag",
    "OnScrollRangeChanged",
    "OnShow",
    "OnSizeChanged",
    "OnSpacePressed",
    "OnTabPressed",
    "OnTextChanged",
    "OnTextSet",
    "OnTooltipAddMoney",
    "OnTooltipCleared",
    "OnTooltipSetDefaultAnchor",
    "OnUpdate",
    "OnUpdateModel",
    "OnValueChanged",
    "OnVerticalScroll",
}

---@param frame Frame
function clearFrame(frame)
    for _, scriptType in ipairs(SCRIPT_TYPES) do
        if frame:HasScript(scriptType) then
            frame:SetScript(scriptType, nil)
        end
    end
    frame:UnregisterAllEvents()
    frame:ClearAllPoints()
    frame:Hide()
    frame:SetParent(nil)
end

---@param frame Frame
---@return string
function getFrameId(frame)
    assert(type(frame) == "table")
    local _, _, address = strfind(tostring(frame), "table: (%x+)")
    assert(type(address) == "string")
    return --[[---@type string]] address
end

local delayFrame = nil
local delayQueue = {}

---@param delayInFrames 0|1
---@param callback fun():void
function callDelayed(delayInFrames, callback)
    if delayInFrames == 0 then
        callback()
    else
        tinsert(delayQueue, callback)
        if delayFrame == nil then
            delayFrame = CreateFrame("Frame")
        end
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:SetScript("OnUpdate", nil)
            local pending = delayQueue
            delayQueue = {}
            for _, fn in ipairs(pending) do
                fn()
            end
        end)
    end
end

--[[
Vanilla 1.12 has no reliable native hooksecurefunc (that's a post-1.12 Blizzard
API tied to the secure-execution/taint system Turtle WoW's client may or may
not back-port). Replace the target global function with a wrapper that calls
our callback and then the original, same technique LibItemTooltip already
uses to hook GameTooltip methods.
]]
---@param funcName string
---@param callback fun(...): void
function hookGlobalFunction(funcName, callback)
    local original = getglobal(funcName)
    if type(original) ~= "function" then
        return
    end

    setglobal(funcName, function(...)
        callback(unpack(arg))
        return original(unpack(arg))
    end)
end
