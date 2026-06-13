local Button = {}
Button.__index = Button

function Button:new(label, x, y, term)
    local self = setmetatable({}, Button)
    self.label = label
    self.x = x
    self.y = y
    self.w = #label + 4
    self.h = 2
    self.term = term
    return self
end

function Button:draw()
    local x = self.x
    local y = self.y
    local w = self.w
    local h = self.h
    
    paintutils.drawFilledBox(x, y, x + w - 1, y + h - 1, colors.blue)
    self.term.setBackgroundColor(colors.blue)
    self.term.setTextColor(colors.white)
    
    local labelY = y + math.floor((h - 1) / 2)
    local labelX = x + math.floor((w - #self.label) / 2)
    self.term.setCursorPos(labelX, labelY)
    self.term.write(self.label)
end

function Button:isInside(x, y)
    return x >= self.x and x <= self.x + self.w - 1 and y >= self.y and y <= self.y + self.h - 1
end

return Button
