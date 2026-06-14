local RequestedLines = {}
RequestedLines.version = "v1.0"

function RequestedLines.build(requestedItems, maxEntries)
    maxEntries = maxEntries or 10
    local lines = {}
    if not requestedItems or #requestedItems == 0 then
        table.insert(lines, "No requested items found.")
    else
        for _, item in ipairs(requestedItems) do
            if #lines >= maxEntries then break end
            local label = item.displayName or item.name or "Unknown"
            table.insert(lines, string.format("%s x%d", label, item.count or 0))
        end
    end
    while #lines < maxEntries do
        table.insert(lines, "")
    end
    return lines
end

return RequestedLines
