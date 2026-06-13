local Panel = {}
Panel.__index = Panel

function Panel:new(x, y, w, h, title, bgColor, textColor, term)
    local self = setmetatable({}, Panel)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.title = title
    self.bgColor = bgColor or colors.lightGray
    self.textColor = textColor or colors.black
    self.lines = {}
    self.term = term
    return self
end

function Panel:setLines(lines)
    self.lines = lines or {}
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
    local maxRows = self.h - paddingTop - paddingBottom - 2
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
