-- Object-oriented monitor showing only requests with status == "DONT_HAVE" and delivering == 0
local ColonyMonitor = {}
ColonyMonitor.__index = ColonyMonitor

-- Constructor
function ColonyMonitor.new(opts)
    opts = opts or {}
    local self = setmetatable({}, ColonyMonitor)
    self.monitor = peripheral.find("monitor")
    self.refreshInterval = opts.refreshInterval or 15
    self.textScale = opts.textScale or 0.5
    self.headerText = opts.headerText or "--- Colony API: Active Requests ---"
    self.cursorStartRow = opts.cursorStartRow or 3

    -- Filtering options
    self.statusFilter = opts.statusFilter or "DONT_HAVE"
    self.requireDeliveringZero = opts.requireDeliveringZero
    if self.requireDeliveringZero == nil then
        self.requireDeliveringZero = true
    end

    return self
end

-- Initialize monitor (returns true on success)
function ColonyMonitor:initMonitor()
    if not self.monitor then
        print("Monitor not found! Please attach an external monitor.")
        return false
    end

    self.monitor.clear()
    if self.monitor.setTextScale then
        self.monitor.setTextScale(self.textScale)
    end
    return true
end

function ColonyMonitor:clear()
    self.monitor.clear()
end

function ColonyMonitor:writeLine(text, row)
    if row then
        self.monitor.setCursorPos(1, row)
        -- keep cursorPos consistent for subsequent writes
        self.cursorPos = row + 1
    else
        self.monitor.setCursorPos(1, self.cursorPos)
        self.cursorPos = self.cursorPos + 1
    end
    self.monitor.write(text)
end

function ColonyMonitor:drawHeader()
    self.monitor.setCursorPos(1, 1)
    self.monitor.write(self.headerText)
end

function ColonyMonitor:getBuildings()
    local buildings = colony.getBuildings()
    if not buildings then return {} end
    return buildings
end

function ColonyMonitor:getBuilderRequests(building)
    if not building then return {} end
    local reqs = colony.getBuilderResources(building.location)
    if not reqs then return {} end
    return reqs
end

-- Return true when an entry should be shown according to configured filters
function ColonyMonitor:shouldShowRequest(entry)
    if not entry then return false end
    if self.statusFilter and entry.status ~= self.statusFilter then
        return false
    end
    if self.requireDeliveringZero and entry.delivering ~= 0 then
        return false
    end
    return true
end

-- Render builder requests filtered by shouldShowRequest
function ColonyMonitor:renderRequests()
    local buildings = self:getBuildings()
    self.cursorPos = self.cursorStartRow

    if #buildings == 0 then
        self:writeLine("All citizens satisfied. No active requests!", self.cursorPos)
        return 1
    end

    local anyRequest = false
    for i = 1, #buildings do
        local building = buildings[i]
        if building and building.type == "builder" then
            local reqs = self:getBuilderRequests(building)
            if #reqs > 0 then
                for _, entry in ipairs(reqs) do
                    if entry.item and self:shouldShowRequest(entry) then
                        local name = entry.item.displayName or entry.item.name or "Unknown"
                        local amt = entry.item.count or 0
                        self:writeLine(name .. " x" .. amt)
                        anyRequest = true
                    end
                end
            end
        end
    end

    if not anyRequest then
        self:writeLine("All citizens satisfied. No active requests!")
    end
end

function ColonyMonitor:run()
    while true do
        self:clear()
        self:drawHeader()
        self:renderRequests()
        sleep(self.refreshInterval)
    end
end

-- Usage
local ui = ColonyMonitor.new({
    refreshInterval = 15,
    textScale = 0.5,
    statusFilter = "DONT_HAVE",
    requireDeliveringZero = true,
})
if ui:initMonitor() then
    ui:run()
end