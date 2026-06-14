local ColonyData = {}
ColonyData.version = "v1.1"

local function sampleRequested()
    return {
        {name = "minecraft:oak_planks", displayName = "Oak Planks", count = 128},
        {name = "minecraft:cobblestone", displayName = "Cobblestone", count = 64},
        {name = "minecraft:glass_pane", displayName = "Glass Pane", count = 32},
    }
end

local function sampleLogistics()
    return {
        {name = "minecraft:oak_planks", displayName = "Oak Planks", count = 128, status = "Requested"},
        {name = "minecraft:cobblestone", displayName = "Cobblestone", count = 64, status = "Requested"},
    }
end

function ColonyData.parseRequested(raw)
    local items = {}
    local msg = ""
    if type(raw) == "table" and #raw > 0 then
        for _, entry in ipairs(raw) do
            if entry and entry.name then
                table.insert(items, {
                    name = entry.name,
                    displayName = entry.displayName or entry.name,
                    count = entry.count or 0,
                })
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
                table.insert(items, {
                    name = entry.name,
                    displayName = entry.displayName or entry.name,
                    count = entry.count or 0,
                    status = entry.status or "Pending",
                })
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
