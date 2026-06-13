local RequestedLines = {}

function RequestedLines.build(requestedItems, maxEntries)
    maxEntries = maxEntries or 10
    local lines = {}
    if not requestedItems or #requestedItems == 0 then
        table.insert(lines, "No requested items found.")
    else
        for _, item in ipairs(requestedItems) do
            if #lines >= maxEntries then break end
            table.insert(lines, string.format("%s x%d", item.name, item.count or 0))
        end
    end
    while #lines < maxEntries do
        table.insert(lines, "")
    end
    return lines
end

return RequestedLines
