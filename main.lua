-- ComputerCraft MineColonies UI
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
    self.buttons = {
        request = {label = "Request", x = 0, y = 0, w = 12, h = 1},
        refresh = {label = "Refresh", x = 0, y = 0, w = 12, h = 1},
    }
    return self
end

function App:init()
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

function App:drawColoredBox(x, y, w, h, bgColor, textColor, title)
    paintutils.drawFilledBox(x, y, x + w - 1, y + h - 1, bgColor)
    
    self.term.setBackgroundColor(bgColor)
    self.term.setTextColor(textColor)
    
    if title and #title > 0 then
        local label = " " .. title .. " "
        local labelX = x + math.floor((w - #label) / 2)
        self.term.setCursorPos(labelX, y)
        self.term.write(label)
    end
end

function App:drawPanel(x, y, w, h, title, lines, bgColor, textColor)
    bgColor = bgColor or colors.lightGray
    textColor = textColor or colors.black
    
    self:drawColoredBox(x, y, w, h, bgColor, textColor, title)
    
    self.term.setBackgroundColor(bgColor)
    self.term.setTextColor(textColor)
    
    local row = y + 2
    for i = 1, #lines do
        if row < y + h - 1 then
            self.term.setCursorPos(x + 2, row)
            local line = lines[i]
            if #line > w - 4 then
                line = line:sub(1, w - 4)
            end
            self.term.write(line)
            row = row + 1
        else
            break
        end
    end
end

function App:drawPanels()
    local panelSpacing = 2
    local panelHeight = math.max(8, self.height - 8)
    local halfWidth = math.floor((self.width - 3 * panelSpacing) / 2)
    if halfWidth < 20 then
        halfWidth = self.width - 4
    end
    local leftX = 2
    local rightX = leftX + halfWidth + panelSpacing
    local panelY = 4

    local requestedLines = self:createRequestedItemLines()
    local logisticsLines = self:createLogisticsItemLines()

    self:drawPanel(leftX, panelY, halfWidth, panelHeight, "Requested Items", requestedLines, colors.orange, colors.black)
    if rightX + halfWidth - 1 <= self.width then
        self:drawPanel(rightX, panelY, halfWidth, panelHeight, "Logistics Requested Items", logisticsLines, colors.green, colors.black)
    end
end

function App:createRequestedItemLines()
    local lines = {}
    if #self.requestedItems == 0 then
        table.insert(lines, "No requested items found.")
    else
        for _, item in ipairs(self.requestedItems) do
            table.insert(lines, string.format("%s x%d", item.name, item.count or 0))
        end
    end
    return lines
end

function App:createLogisticsItemLines()
    local lines = {}
    if #self.logisticsItems == 0 then
        table.insert(lines, "No logistics requests found.")
    else
        for _, item in ipairs(self.logisticsItems) do
            table.insert(lines, string.format("%s x%d [%s]", item.name, item.count or 0, item.status or "Pending"))
        end
    end
    return lines
end

function App:drawButtons()
    local buttonRow = self.height - 2
    local requestBtn = self.buttons.request
    local refreshBtn = self.buttons.refresh
    requestBtn.w = #requestBtn.label + 4
    refreshBtn.w = #refreshBtn.label + 4
    requestBtn.y = buttonRow
    refreshBtn.y = buttonRow
    requestBtn.x = math.max(2, math.floor((self.width / 2) - requestBtn.w - 2))
    refreshBtn.x = math.min(self.width - refreshBtn.w - 1, math.floor((self.width / 2) + 2))

    self:drawButton(requestBtn)
    self:drawButton(refreshBtn)
end

function App:drawButton(button)
    local x = button.x
    local y = button.y
    local w = button.w
    
    paintutils.drawFilledBox(x, y, x + w - 1, y, colors.blue)
    self.term.setBackgroundColor(colors.blue)
    self.term.setTextColor(colors.white)
    
    local labelX = x + math.floor((w - #button.label) / 2)
    self.term.setCursorPos(labelX, y)
    self.term.write(button.label)
end

function App:drawStatusBar()
    local statusY = self.height - 1
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
    local items = self:getColonyRequests()

    if type(items) == "table" and #items > 0 then
        self.requestedItems = {}
        for _, entry in ipairs(items) do
            if entry.name then
                table.insert(self.requestedItems, {name = entry.name, count = entry.count or 0})
            end
        end
        self.message = "Loaded requested items from colony API."
    else
        self.requestedItems = {
            {name = "Oak Planks", count = 128},
            {name = "Cobblestone", count = 64},
            {name = "Glass Pane", count = 32},
        }
        self.message = "Using sample requested items."
    end

    local logistics = self:getActiveLogisticsRequests()

    if type(logistics) == "table" and #logistics > 0 then
        self.logisticsItems = {}
        for _, entry in ipairs(logistics) do
            if entry.name then
                table.insert(self.logisticsItems, {name = entry.name, count = entry.count or 0, status = entry.status or "Pending"})
            end
        end
        self.message = "Loaded logistics requester items from colony API."
    else
        self.logisticsItems = {
            {name = "Oak Planks", count = 128, status = "Requested"},
            {name = "Cobblestone", count = 64, status = "Requested"},
        }
        self.message = self.message .. " Refresh to update."
    end
end

function App:onRequest()
    self.message = "Request sent through logistics requester."
    self.term.setCursorPos(1, self.height - 1)
    self.term.write(string.rep(" ", self.width))
    self:drawStatusBar()
end

function App:onRefresh()
    self:refreshData()
    self:draw()
end

function App:isInside(x, y, button)
    return x >= button.x and x <= button.x + button.w - 1 and y == button.y
end

function App:runEventLoop()
    while true do
        local event, side, x, y = os.pullEvent()
        if event == "monitor_touch" then
            if self:isInside(x, y, self.buttons.request) then
                self:onRequest()
            elseif self:isInside(x, y, self.buttons.refresh) then
                self:onRefresh()
            end
        elseif event == "mouse_click" then
            if self:isInside(x, y, self.buttons.request) then
                self:onRequest()
            elseif self:isInside(x, y, self.buttons.refresh) then
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
