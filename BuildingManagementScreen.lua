-- ComputerCraft MineColonies UI
local Button = require("Button")
local Panel = require("Panel")
local ColonyData = require("ColonyData")
local ColonyRequestManager = require("ColonyRequestManager")
local RequestedLines = require("RequestedLines")
local LogisticsLines = require("LogisticsLines")
local LogisticsRequester = require("LogisticsRequester")
local Navigation = require("Navigation")

local App = {}
App.__index = App

App.name = "Building Management"
App.version = "v1.24"

function App:new()
    local self = setmetatable({}, App)
    self.monitor = peripheral.find("monitor")
    self.term = self.monitor or term
    self.width, self.height = self.term.getSize()
    self.requestedItems = {}
    self.logisticsItems = {}
    self.message = "Press Request or Refresh to update data."
    self.requestManager = ColonyRequestManager:new()
    self.logisticsRequester = LogisticsRequester:new("Warehouse*", "Create_RedstoneRequester")
    self.scale = self:calculateScale()
    -- construct panels once and configure auto-layout
    self.maxEntries = 10
    self.requestPanel = Panel:new(nil, nil, nil, self.maxEntries, "Builder Requests", colors.orange, colors.black, self.term)
    self.logisticsPanel = Panel:new(nil, nil, nil, self.maxEntries, "Logistics Requested", colors.green, colors.black, self.term)
    self.requestPanel:setAutoLayout(1, 2, 2, 4)
    self.logisticsPanel:setAutoLayout(2, 2, 2, 4)

    self.requestBtn = Button:new("Request", 0, 0, self.term)
    self.refreshBtn = Button:new("Refresh", 0, 0, self.term)
    Navigation.addBackButton(self, self.term, "Main Menu", "main")
    return self
end

function App:calculateScale()
    if self.width >= 100 or self.height >= 50 then
        return 1.5
    elseif self.width >= 80 or self.height >= 30 then
        return 1.2
    else
        return 1.0
    end
end

function App:updateLayout()
    self.width, self.height = self.term.getSize()
    self.scale = self:calculateScale()

    local headerRows = self.height <= 6 and 1 or 2
    self.headerRows = headerRows
    local topY = headerRows + 1
    -- Reserve the last row for the status bar, so 2-row buttons do not overlap it.
    local buttonRow = math.max(topY + 1, self.height - 2)
    self.buttonRow = buttonRow

    local columns = (self.width >= 32) and 2 or 1
    local rows = columns == 2 and 1 or 2
    local availableHeight = math.max(1, buttonRow - topY)
    local panelHeight = math.max(2, math.floor((availableHeight - (rows - 1)) / rows))
    local maxEntries = math.max(0, panelHeight - 3)
    local cappedEntries = math.min(10, maxEntries)
    local cappedPanelHeight = math.min(panelHeight, 10 + 3)

    self.maxEntries = cappedEntries
    self.requestPanel.numLines = cappedEntries
    self.requestPanel.h = cappedPanelHeight
    self.logisticsPanel.numLines = cappedEntries
    self.logisticsPanel.h = cappedPanelHeight

    self.requestPanel:setAutoLayout(1, columns, 1, topY)
    self.logisticsPanel:setAutoLayout(2, columns, 1, topY)
end

function App:init()
    if self.monitor then
        term.redirect(self.monitor)
    end
    self:refreshData()
    self:draw()
    self:runEventLoop()
end

function App:clear()
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self.term.clear()
    self.term.setCursorPos(1, 1)
end

function App:draw()
    self:updateLayout()
    self:clear()
    self:drawHeader()
    self:drawPanels()
    self:drawButtons()
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self:drawStatusBar()
end

function App:drawHeader()
    local title = string.format("%s %s", self.name, self.version)
    self.term.setCursorPos(1, 1)
    self.term.write(string.rep(" ", self.width))
    local titleX = math.max(1, math.floor((self.width - #title) / 2) + 1)
    self.term.setCursorPos(titleX, 1)
    self.term.write(title)

    if self.headerRows and self.headerRows > 1 then
        self.term.setCursorPos(1, 2)
        self.term.write(string.rep("=", self.width))
    end
end

function App:drawPanel(x, y, w, h, title, lines, bgColor, textColor)
    local panel = Panel:new(x, y, w, h, title, bgColor, textColor, self.term)
    panel:setLines(lines)
    panel:draw()
end

function App:drawPanels()
    local maxEntries = self.maxEntries or 10
    local requestedLines = RequestedLines.build(self.requestedItems, maxEntries)
    local logisticsLines = LogisticsLines.build(self.logisticsItems, maxEntries)

    -- update existing panels via their own layout logic, then draw
    if self.requestPanel then
        self.requestPanel:layout(self.width)
        self.requestPanel:setLines(requestedLines)
        self.requestPanel:draw()
    end
    if self.logisticsPanel then
        self.logisticsPanel:layout(self.width)
        self.logisticsPanel:setLines(logisticsLines)
        self.logisticsPanel:draw()
    end
end

function App:drawButtons()
    local buttonRow = self.buttonRow or math.max(3, self.height - 1)
    local spacing = 2

    self.requestBtn.x = 2
    self.requestBtn.y = buttonRow
    self.refreshBtn.x = self.requestBtn.x + self.requestBtn.w + spacing
    self.refreshBtn.y = buttonRow

    Navigation.layoutBackButton(self, buttonRow, self.width, {self.requestBtn, self.refreshBtn}, spacing)
    self:logButtonPositions()

    self.requestBtn:draw()
    self.refreshBtn:draw()
    Navigation.drawBackButton(self)
end

function App:drawStatusBar()
    local statusY = self.height
    self.term.setCursorPos(1, statusY)
    self.term.write(string.rep(" ", self.width))
    self.term.setCursorPos(2, statusY)
    self.term.write(self.message)
end

function App:logDebug(message)
    local logPath = "building_management_clicks.log"
    local handle, err = fs.open(logPath, "a")
    if not handle then
        return false, err
    end
    handle.writeLine(string.format("%s %s", os.date("%Y-%m-%d %H:%M:%S"), message))
    handle.close()
    return true
end

function App:logClickEvent(event, x, y)
    local logPath = "building_management_clicks.log"
    local handle, err = fs.open(logPath, "a")
    if not handle then
        return false, err
    end
    handle.writeLine(string.format("%s @ %d,%d %s", event, x or 0, y or 0, os.date("%Y-%m-%d %H:%M:%S")))
    handle.close()
    return true
end

function App:logButtonHit(event, x, y)
    local logPath = "building_management_clicks.log"
    local handle, err = fs.open(logPath, "a")
    if not handle then
        return false, err
    end
    local requestHit = self.requestBtn:isInside(x, y)
    local refreshHit = self.refreshBtn:isInside(x, y)
    local backHit = self.backBtn and self.backBtn:isInside(x, y)
    handle.writeLine(string.format("Hit test @ %d,%d request=%s refresh=%s back=%s", x or 0, y or 0, tostring(requestHit), tostring(refreshHit), tostring(backHit)))
    handle.close()
    return true
end

function App:logButtonPositions()
    local logPath = "building_management_clicks.log"
    local handle, err = fs.open(logPath, "a")
    if not handle then
        return false, err
    end
    handle.writeLine(string.format("Request button at %d,%d size %d,%d", self.requestBtn.x, self.requestBtn.y, self.requestBtn.w, self.requestBtn.h))
    handle.writeLine(string.format("Refresh button at %d,%d size %d,%d", self.refreshBtn.x, self.refreshBtn.y, self.refreshBtn.w, self.refreshBtn.h))
    if self.backBtn then
        handle.writeLine(string.format("Back button at %d,%d size %d,%d", self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h))
    end
    handle.close()
    return true
end

function App:getColonyRequests()
    return self.requestManager:getBuilderRequests()
end

function App:getActiveLogisticsRequests()
    return {}
end

function App:refreshData()
    local raw = self:getColonyRequests()
    local items, msg = ColonyData.parseRequested(raw)
    self.requestedItems = items or {}
    self.message = msg or ""

    local rawLog = self:getActiveLogisticsRequests()
    local logistics, msg2 = ColonyData.parseLogistics(rawLog)
    self.logisticsItems = logistics or {}
    if msg2 and msg2 ~= "" then
        self.message = self.message .. " " .. msg2
    end
end

function App:onRequest()
    self:logDebug("onRequest called")
    if not self.logisticsRequester then
        self:logDebug("onRequest: no logisticsRequester")
        self.message = "No logistics requester module available."
        self:draw()
        return
    end

    if not self.requestedItems then
        self:logDebug("onRequest: requestedItems nil")
    elseif #self.requestedItems == 0 then
        self:logDebug("onRequest: requestedItems empty")
    end

    if not self.requestedItems or #self.requestedItems == 0 then
        self:logDebug("onRequest: abort, no items")
        self.message = "No builder request items available to send."
        self:draw()
        return
    end

    local pcallSuccess, ok, err = pcall(function()
        return self.logisticsRequester:requestItems(self.requestedItems)
    end)

    if not pcallSuccess then
        self:logDebug(string.format("onRequest: runtime error: %s", tostring(ok)))
        self.message = "Logistics request failed: " .. tostring(ok)
        self:draw()
        return
    end

    self:logDebug(string.format("onRequest: requestItems returned ok=%s err=%s", tostring(ok), tostring(err)))
    if ok then
        self.message = "Submitted item request to the logistics network."
    else
        self.message = "Logistics request failed: " .. tostring(err)
    end

    self:draw()
end

function App:onRefresh()
    self:refreshData()
    self:draw()
end

function App:runEventLoop()
    self.returnToMenu = false
    while true do
        local event, side, x, y = os.pullEvent()
        if event == "monitor_touch" then
            self:logClickEvent("monitor_touch", x, y)
            self:logButtonHit("monitor_touch", x, y)
            if self.requestBtn:isInside(x, y) then
                self:onRequest()
            elseif self.refreshBtn:isInside(x, y) then
                self:onRefresh()
            elseif Navigation.handleBackInput(self, event, x, y) then
                break
            end
        elseif event == "mouse_click" then
            self:logClickEvent("mouse_click", x, y)
            self:logButtonHit("mouse_click", x, y)
            if self.requestBtn:isInside(x, y) then
                self:onRequest()
            elseif self.refreshBtn:isInside(x, y) then
                self:onRefresh()
            elseif Navigation.handleBackInput(self, event, x, y) then
                break
            end
        elseif event == "term_resize" then
            self.width, self.height = self.term.getSize()
            self:draw()
        end

        if self.returnToMenu then
            break
        end
    end
end

local ui = App:new()
ui:init()
