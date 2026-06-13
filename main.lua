-- ComputerCraft MineColonies UI
local Button = require("Button")
local Panel = require("Panel")
local ColonyData = require("ColonyData")

local App = {}
App.__index = App

App.name = "MineColonies Request Manager"
App.version = "v1.0"

function App:new()
    local self = setmetatable({}, App)
    self.monitor = peripheral.find("monitor")
    self.term = self.monitor or term
    self.width, self.height = self.term.getSize()
    self.requestedItems = {}
    self.logisticsItems = {}
    self.message = "Press Request or Refresh to update data."
    self.scale = self:calculateScale()
    -- construct panels once
    local maxEntries = 10
    local halfWidth = math.floor((self.width - 3 * 2) / 2)
    local leftX = 2
    local panelY = 4
    self.requestPanel = Panel:new(leftX, panelY, halfWidth, maxEntries, "Requested Items", colors.orange, colors.black, self.term)
    local rightX = leftX + halfWidth + 2
    self.logisticsPanel = Panel:new(rightX, panelY, halfWidth, maxEntries, "Logistics Requested Items", colors.green, colors.black, self.term)

    self.requestBtn = Button:new("Request", 0, 0, self.term)
    self.refreshBtn = Button:new("Refresh", 0, 0, self.term)
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
    self.width, self.height = self.term.getSize()
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
    local panelSpacing = 2
    local maxEntries = 10
    local panelHeight = maxEntries + 3
    local halfWidth = math.floor((self.width - 3 * panelSpacing) / 2)
    if halfWidth < 20 then
        halfWidth = self.width - 4
    end
    local leftX = 2
    local rightX = leftX + halfWidth + panelSpacing
    local panelY = 4

    local requestedLines = self:createRequestedItemLines(maxEntries)
    local logisticsLines = self:createLogisticsItemLines(maxEntries)

    -- update existing panels' geometry and content, then draw
    if self.requestPanel then
        self.requestPanel:setGeometry(leftX, panelY, halfWidth, maxEntries)
        self.requestPanel:setLines(requestedLines)
        self.requestPanel:draw()
    end
    if self.logisticsPanel and rightX + halfWidth - 1 <= self.width then
        self.logisticsPanel:setGeometry(rightX, panelY, halfWidth, maxEntries)
        self.logisticsPanel:setLines(logisticsLines)
        self.logisticsPanel:draw()
    end
end

function App:createRequestedItemLines(maxEntries)
    maxEntries = maxEntries or 10
    local lines = {}
    if #self.requestedItems == 0 then
        table.insert(lines, "No requested items found.")
    else
        for _, item in ipairs(self.requestedItems) do
            if #lines >= maxEntries then break end
            table.insert(lines, string.format("%s x%d", item.name, item.count or 0))
        end
    end
    while #lines < maxEntries do
        table.insert(lines, "")
    end
    return lines
end

function App:createLogisticsItemLines(maxEntries)
    maxEntries = maxEntries or 10
    local lines = {}
    if #self.logisticsItems == 0 then
        table.insert(lines, "No logistics requests found.")
    else
        for _, item in ipairs(self.logisticsItems) do
            if #lines >= maxEntries then break end
            table.insert(lines, string.format("%s x%d [%s]", item.name, item.count or 0, item.status or "Pending"))
        end
    end
    while #lines < maxEntries do
        table.insert(lines, "")
    end
    return lines
end

function App:drawButtons()
    local buttonRow = self.height - 3
    self.requestBtn.x = math.max(2, math.floor((self.width / 2) - self.requestBtn.w - 2))
    self.requestBtn.y = buttonRow
    self.refreshBtn.x = math.min(self.width - self.refreshBtn.w - 1, math.floor((self.width / 2) + 2))
    self.refreshBtn.y = buttonRow

    self.requestBtn:draw()
    self.refreshBtn:draw()
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
    while true do
        local event, side, x, y = os.pullEvent()
        if event == "monitor_touch" then
            if self.requestBtn:isInside(x, y) then
                self:onRequest()
            elseif self.refreshBtn:isInside(x, y) then
                self:onRefresh()
            end
        elseif event == "mouse_click" then
            if self.requestBtn:isInside(x, y) then
                self:onRequest()
            elseif self.refreshBtn:isInside(x, y) then
                self:onRefresh()
            end
        elseif event == "term_resize" then
            self.width, self.height = self.term.getSize()
            self:draw()
        end
    end
end

local ui = App:new()
ui:init()
