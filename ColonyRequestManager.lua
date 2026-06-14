local ColonyRequestManager = {}
ColonyRequestManager.__index = ColonyRequestManager
ColonyRequestManager.version = "v1.0"

function ColonyRequestManager:new()
    local self = setmetatable({}, ColonyRequestManager)
    self.requests = {}
    self.statusFilter = "DONT_HAVE"
    self.requireDeliveringZero = true
    return self
end

function ColonyRequestManager:getBuilderRequests()
    self.requests = {}
    local buildings = colony.getBuildings() or {}
    for i = 1, #buildings do
        local building = buildings[i]
        if building and building.type == "builder" then
            local reqs = self:getBuildRequest(building)
            if reqs and #reqs > 0 then
                for _, entry in ipairs(reqs) do
                    if entry.item and self:shouldShowRequest(entry) then
                        local name = entry.item.name or "Unknown"
                        local displayName = entry.item.displayName or "Unknown"
                        local amt = entry.item.count or 0
                        table.insert(self.requests, { name = name, displayName = displayName, count = amt })
                    end
                end
            end
        end
    end
    return self.requests
end

-- Return true when an entry should be shown according to configured filters
function ColonyRequestManager:shouldShowRequest(entry)
    if not entry then return false end
    if self.statusFilter and entry.status ~= self.statusFilter then
        return false
    end
    if self.requireDeliveringZero and entry.delivering ~= 0 then
        return false
    end
    return true
end

function ColonyRequestManager:getBuildRequest(building)
    if not building then return {} end
    local reqs = colony.getBuilderResources(building.location)
    if not reqs then return {} end
    return reqs
end

return ColonyRequestManager
