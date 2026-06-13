local Panel = {}
Panel.__index = Panel
Panel.version = "v1.0"

function Panel:new(x, y, w, numLines, title, bgColor, textColor, term)
    local self = setmetatable({}, Panel)
    self.x = x or 1
    self.y = y or 1
    self.w = w or 10
    self.numLines = numLines or 10
    self.h = (self.numLines or 10) + 3
    self.title = title or ""
    self.bgColor = bgColor or colors.lightGray
    self.textColor = textColor or colors.black
    self.lines = {}
    self.term = term or term
    return self
end

-- Configure automatic layout for multi-panel arrangements.
-- panelIndex: 1-based index of this panel
-- totalPanels: total number of panels in the row (e.g. 2)
-- panelSpacing: space between panels and edges
-- topY: y coordinate of top of panels
function Panel:setAutoLayout(panelIndex, totalPanels, panelSpacing, topY)
    self.auto = {
        panelIndex = panelIndex or 1,
        totalPanels = totalPanels or 2,
        panelSpacing = panelSpacing or 2,
        topY = topY or 4,
    }
end

-- Compute geometry from parent width using stored auto layout settings.
function Panel:layout(parentWidth)
    if not self.auto then return end
    local s = self.auto
    local spacingTotal = (s.totalPanels + 1) * s.panelSpacing
    local avail = math.max(1, parentWidth - spacingTotal)
    local w = math.floor(avail / s.totalPanels)
    if w < 10 then
        w = math.max(3, parentWidth - (s.panelSpacing * 2))
    end
    local col = (s.panelIndex - 1) % s.totalPanels
    local row = math.floor((s.panelIndex - 1) / s.totalPanels)
    local x = s.panelSpacing + col * (w + s.panelSpacing)
    local y = s.topY + row * ((self.numLines or 10) + 3 + s.panelSpacing)
    self.x = x
    self.w = w
    self.y = y
    self.h = (self.numLines or 10) + 3
end

function Panel:setGeometry(x, y, w, numLines)
    self.x = x or self.x
    self.y = y or self.y
    self.w = w or self.w
    if numLines then
        self.numLines = numLines
        self.h = self.numLines + 3
    end
end

function Panel:setLines(lines)
    self.lines = {}
    if not lines then return end
    for i = 1, (self.numLines or 10) do
        self.lines[i] = lines[i] or ""
    end
end

function Panel:clear()
    paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bgColor)
end

function Panel:draw()
    local paddingLeft = 1
    local paddingTop = 0
    local paddingRight = 1
    local paddingBottom = 0

    paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bgColor)

    self.term.setBackgroundColor(self.bgColor)
    self.term.setTextColor(self.textColor)

    if self.title and #self.title > 0 then
        local label = " " .. self.title .. " "
        local labelX = self.x + math.floor((self.w - #label) / 2)
        self.term.setCursorPos(labelX, self.y + paddingTop)
        self.term.write(label)
    end

    local row = self.y + paddingTop + 1
    local maxRows = self.numLines or (self.h - paddingTop - paddingBottom - 2)
    local contentWidth = self.w - paddingLeft - paddingRight

    for i = 1, maxRows do
        self.term.setCursorPos(self.x + paddingLeft, row)
        local line = self.lines[i] or ""
        if #line > contentWidth then
            line = line:sub(1, contentWidth)
        end
        local paddedLine = line .. string.rep(" ", math.max(0, contentWidth - #line))
        self.term.write(paddedLine)
        row = row + 1
    end
end

return Panel
