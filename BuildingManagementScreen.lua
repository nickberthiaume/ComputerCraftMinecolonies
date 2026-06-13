-- ComputerCraft MineColonies UI
local Button = require("Button")
local Panel = require("Panel")
local ColonyData = require("ColonyData")
local RequestedLines = require("RequestedLines")
local LogisticsLines = require("LogisticsLines")
local Navigation = require("Navigation")

local App = {}
App.__index = App

App.name = "Building Management"
App.version = "v1.5"

function App:new()
    local self = setmetatable({}, App)
    self.monitor = peripheral.find("monitor")
    self.term = self.monitor or term
    self.width, self.height = self.term.getSize()
    self.requestedItems = {}
    self.logisticsItems = {}
    self.message = "Press Request or Refresh to update data."
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
    local columns = (self.width >= 32) and 2 or 1
    local availableHeight = math.max(1, self.height - 6)
    local rows = columns == 2 and 1 or 2
    local panelHeight = math.max(4, math.floor(availableHeight / rows))
    local maxEntries = math.max(1, panelHeight - 3)

    self.maxEntries = maxEntries
    self.requestPanel.numLines = maxEntries
    self.requestPanel.h = maxEntries + 3
    self.logisticsPanel.numLines = maxEntries
    self.logisticsPanel.h = maxEntries + 3

    self.requestPanel:setAutoLayout(1, columns, 1, 4)
    self.logisticsPanel:setAutoLayout(2, columns, 1, 4)
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
    local titleRow = 1
    self.term.setCursorPos(1, titleRow)
    self.term.write(string.rep(" ", self.width))
    local titleX = math.max(1, math.floor((self.width - #title) / 2) + 1)
    self.term.setCursorPos(titleX, titleRow)
    self.term.write(title)
    self.term.setCursorPos(1, 2)
    self.term.write(string.rep("=", self.width))
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
    local buttonRow = self.height - 3
    local spacing = 2

    self.requestBtn.x = 2
    self.requestBtn.y = buttonRow
    self.refreshBtn.x = self.requestBtn.x + self.requestBtn.w + spacing
    self.refreshBtn.y = buttonRow

    Navigation.layoutBackButton(self, buttonRow, self.width, {self.requestBtn, self.refreshBtn}, spacing)

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

function App:getColonyRequests()
    return {}
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
    self.message = "Request sent through logistics requester."
    self.term.setCursorPos(1, self.height)
    self.term.write(string.rep(" ", self.width))
    self:drawStatusBar()
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
            if self.requestBtn:isInside(x, y) then
                self:onRequest()
            elseif self.refreshBtn:isInside(x, y) then
                self:onRefresh()
            elseif Navigation.handleBackInput(self, event, x, y) then
                break
            end
        elseif event == "mouse_click" then
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
