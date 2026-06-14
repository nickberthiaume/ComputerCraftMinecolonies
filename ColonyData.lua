local ColonyData = {}
ColonyData.version = "v1.0"

local function sampleRequested()
    return {
        {name = "Oak Planks", count = 128},
        {name = "Cobblestone", count = 64},
        {name = "Glass Pane", count = 32},
    }
end

local function sampleLogistics()
    return {
        {name = "Oak Planks", count = 128, status = "Requested"},
        {name = "Cobblestone", count = 64, status = "Requested"},
    }
end

function ColonyData.parseRequested(raw)
    local items = {}
    local msg = ""
    if type(raw) == "table" and #raw > 0 then
        for _, entry in ipairs(raw) do
            if entry and entry.name then
                table.insert(items, {name = entry.name, displayName = entry.displayNname, count = entry.count or 0})
            end
        end
        msg = "Loaded requested items from colony API."
    else
        items = sampleRequested()
        msg = "Using sample requested items."
    end
    return items, msg
end

function ColonyData.parseLogistics(raw)
    local items = {}
    local msg = ""
    if type(raw) == "table" and #raw > 0 then
        for _, entry in ipairs(raw) do
            if entry and entry.name then
                table.insert(items, {name = entry.name, count = entry.count or 0, status = entry.status or "Pending"})
            end
        end
        msg = "Loaded logistics requester items from colony API."
    else
        items = sampleLogistics()
        msg = "Using sample logistics items."
    end
    return items, msg
end

return ColonyData
