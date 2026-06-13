-- main.lua
-- Dynamic screen launcher for ComputerCraft MineColonies UI
local Button = require("Button")

local App = {}
App.__index = App
App.name = "Main Menu"
App.version = "v1.0"

-- If automatic discovery cannot list files in the current folder, add screen module names here.
App.screenNames = {
    -- "BuildingManagementScreen",
}

App.minButtonWidth = 10
App.buttonSpacing = 2
App.menuRowStart = 3

function App:new()
    local self = setmetatable({}, App)
    self.monitor = peripheral and peripheral.find and peripheral.find("monitor")
    self.term = self.monitor or term
    self.width, self.height = self.term.getSize()
    self.screenButtons = {}
    self:refreshScreenList()
    self:buildButtons()
    return self
end

function App:getWorkingDirectory()
    if shell and shell.dir then
        return shell.dir()
    end
    return "."
end

function App:refreshScreenList()
    self.screens = {}
    if fs and fs.list then
        local dir = self:getWorkingDirectory()
        for _, entry in ipairs(fs.list(dir)) do
            if entry:match("Screen%.lua$") then
                table.insert(self.screens, entry:gsub("%.lua$", ""))
            end
        end
        table.sort(self.screens)
    end

    if #self.screens == 0 and #self.screenNames > 0 then
        for _, moduleName in ipairs(self.screenNames) do
            table.insert(self.screens, moduleName)
        end
    end

    self.message = (#self.screens > 0)
        and "Tap a screen button to open it." 
        or "No screen modules found. Add *Screen.lua files or list them in main.lua."
end

function App:buildButtons()
    self.screenButtons = {}

    for _, moduleName in ipairs(self.screens) do
        local label = moduleName:gsub("Screen$", "")
        label = label:gsub("(%l)(%u)", "%1 %2")
        if label == "" then
            label = moduleName
        end

        local button = Button:new(label, 1, 1, self.term)
        button.moduleName = moduleName
        table.insert(self.screenButtons, button)
    end

    self:layoutButtons()
end

function App:layoutButtons()
    local count = #self.screenButtons
    if count == 0 then
        return
    end

    local spacing = self.buttonSpacing
    local maxLabelWidth = 0
    for _, button in ipairs(self.screenButtons) do
        maxLabelWidth = math.max(maxLabelWidth, #button.label)
    end

    local buttonWidth = math.max(self.minButtonWidth, maxLabelWidth + 4)
    local maxPerRow = math.max(1, math.floor((self.width - spacing) / (buttonWidth + spacing)))
    local buttonsPerRow = math.min(count, maxPerRow)
    buttonWidth = math.floor((self.width - (buttonsPerRow + 1) * spacing) / buttonsPerRow)
    buttonWidth = math.max(buttonWidth, self.minButtonWidth)

    for index, button in ipairs(self.screenButtons) do
        local row = math.floor((index - 1) / buttonsPerRow)
        local col = (index - 1) % buttonsPerRow
        button.w = math.max(buttonWidth, #button.label + 4)
        button.x = spacing + col * (buttonWidth + spacing)
        button.y = self.menuRowStart + row * (button.h + spacing)
    end
end

function App:clear()
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self.term.clear()
    self.term.setCursorPos(1, 1)
end

function App:drawHeader()
    local title = string.format("%s %s", self.name, self.version)
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self.term.setCursorPos(1, 1)
    self.term.write(string.rep(" ", self.width))

    local titleX = math.max(1, math.floor((self.width - #title) / 2) + 1)
    self.term.setCursorPos(titleX, 1)
    self.term.write(title)
    self.term.setCursorPos(1, 2)
    self.term.write(string.rep("=", self.width))
end

function App:drawMenu()
    for _, button in ipairs(self.screenButtons) do
        button:draw()
    end
end

function App:drawStatusBar()
    local statusY = self.height
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self.term.setCursorPos(1, statusY)
    local statusText = self.message or ""
    self.term.write(statusText .. string.rep(" ", math.max(0, self.width - #statusText)))
end

function App:draw()
    self.width, self.height = self.term.getSize()
    self:clear()
    self:drawHeader()
    self:drawMenu()
    self:drawStatusBar()
end

function App:openScreen(moduleName)
    local program = moduleName
    local ok, err

    if shell and shell.run then
        ok, err = pcall(shell.run, program)
    else
        ok, err = pcall(dofile, program .. ".lua")
    end

    if not ok then
        self.message = "Failed to open " .. program .. ": " .. tostring(err)
    else
        self.message = "Returned from " .. program
    end

    self:refreshScreenList()
    self:buildButtons()
    self:draw()
end

function App:handleInput(event, side, x, y)
    if event == "mouse_click" or event == "monitor_touch" then
        for _, button in ipairs(self.screenButtons) do
            if button:isInside(x, y) then
                self:openScreen(button.moduleName)
                return
            end
        end
    elseif event == "term_resize" then
        self.width, self.height = self.term.getSize()
        self:layoutButtons()
        self:draw()
    end
end

function App:run()
    if self.monitor then
        term.redirect(self.monitor)
    end

    self:draw()

    while true do
        local event, side, x, y = os.pullEvent()
        self:handleInput(event, side, x, y)
    end
end

local launcher = App:new()
launcher:run()
