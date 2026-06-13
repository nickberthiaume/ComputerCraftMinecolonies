local LogisticsLines = {}

function LogisticsLines.build(logisticsItems, maxEntries)
    maxEntries = maxEntries or 10
    local lines = {}
    if not logisticsItems or #logisticsItems == 0 then
        table.insert(lines, "No logistics requests found.")
    else
        for _, item in ipairs(logisticsItems) do
            if #lines >= maxEntries then break end
            table.insert(lines, string.format("%s x%d [%s]", item.name, item.count or 0, item.status or "Pending"))
        end
    end
    while #lines < maxEntries do
        table.insert(lines, "")
    end
    return lines
end

return LogisticsLines
