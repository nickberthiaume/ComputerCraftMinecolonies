-- Navigation.lua
-- Shared navigation helper for screen modules
local Navigation = {}
Navigation.__index = Navigation
Navigation.version = "v1.0"

function Navigation.addBackButton(screen, term, label, returnCommand)
    screen.backBtn = require("Button"):new(label or "Back", 0, 0, term)
    screen.returnToMenu = false
    screen.returnCommand = returnCommand or "main"
end

function Navigation.layoutBackButton(screen, buttonRow, parentWidth, existingButtons, spacing)
    spacing = spacing or 2
    local totalWidth = screen.backBtn.w
    for _, btn in ipairs(existingButtons or {}) do
        totalWidth = totalWidth + btn.w + spacing
    end
    totalWidth = totalWidth + spacing

    local startX = math.max(2, math.floor((parentWidth - totalWidth) / 2) + 1)
    local x = startX
    for _, btn in ipairs(existingButtons or {}) do
        btn.x = x
        btn.y = buttonRow
        x = x + btn.w + spacing
    end

    screen.backBtn.x = x
    screen.backBtn.y = buttonRow
end

function Navigation.drawBackButton(screen)
    if screen.backBtn then
        screen.backBtn:draw()
    end
end

function Navigation.handleBackInput(screen, event, x, y)
    if not screen.backBtn then
        return false
    end
    if event == "mouse_click" or event == "monitor_touch" then
        if screen.backBtn:isInside(x, y) then
            screen.returnToMenu = true
            return true
        end
    end
    return false
end

function Navigation.maybeReturn(screen)
    if screen.returnToMenu and shell and shell.run then
        shell.run(screen.returnCommand or "main")
    end
end

return Navigation
