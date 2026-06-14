local LogisticsRequester = {}
LogisticsRequester.__index = LogisticsRequester
LogisticsRequester.version = "v1.2"

function LogisticsRequester:new(address, requesterName)
    local self = setmetatable({}, LogisticsRequester)
    self.address = address or ""
    self.requesterName = requesterName or "Create_RedstoneRequester"
    self.requester = self:findRequester()
    return self
end

function LogisticsRequester:findRequester()
    if not peripheral or not peripheral.find then
        return nil
    end

    if type(self.requesterName) == "string" and self.requesterName ~= "" then
        local found = peripheral.find(self.requesterName)
        if found then
            return found
        end

        if peripheral.getType then
            found = peripheral.find(function(name)
                return peripheral.getType(name) == self.requesterName
            end)
            if found then
                return found
            end
        end
    end

    return nil
end

function LogisticsRequester:setDestination(address)
    self.address = address or ""
    if not self.requester then
        return false, "No RedstoneRequester peripheral available"
    end

    local function tryCall(fn, ...)
        if type(fn) ~= "function" then
            return nil, "not a function", false
        end
        local ok, a, b = pcall(fn, ...)
        if not ok then
            return nil, a, false
        end
        return a, b, true
    end

    if self.requester.setDestination then
        local ok, err, called = tryCall(self.requester.setDestination, self.address)
        if called then
            return ok, err
        end
        ok, err, called = tryCall(self.requester.setDestination, self.requester, self.address)
        if called then
            return ok, err
        end
    end
    if self.requester.setTarget then
        local ok, err, called = tryCall(self.requester.setTarget, self.address)
        if called then
            return ok, err
        end
        ok, err, called = tryCall(self.requester.setTarget, self.requester, self.address)
        if called then
            return ok, err
        end
    end
    if self.requester.setAddress then
        local ok, err, called = tryCall(self.requester.setAddress, self.address)
        if called then
            return ok, err
        end
        ok, err, called = tryCall(self.requester.setAddress, self.requester, self.address)
        if called then
            return ok, err
        end
    end

    self.requester.address = self.address
    return true
end

function LogisticsRequester:chunkItems(items)
    local chunks = {}
    local current = {}

    for _, item in ipairs(items) do
        if item and item.name and tonumber(item.count) and tonumber(item.count) > 0 then
            table.insert(current, {
                name = tostring(item.name),
                count = tonumber(item.count),
            })

            if #current >= 9 then
                table.insert(chunks, current)
                current = {}
            end
        end
    end

    if #current > 0 then
        table.insert(chunks, current)
    end

    return chunks
end

function LogisticsRequester:requestItems(items)
    if type(items) ~= "table" then
        return false, "items must be a table"
    end
    if not self.requester then
        return false, "No RedstoneRequester peripheral found"
    end
    if not self.address or self.address == "" then
        return false, "Request address not set"
    end

    local batches = self:chunkItems(items)
    if #batches == 0 then
        return false, "No valid request items provided"
    end

    local requestFn = self.requester.request
    if not requestFn then
        return false, "RedstoneRequester does not support request()"
    end

    local ok, err = self:setDestination(self.address)
    if not ok then
        return false, err or "Failed to set destination address"
    end

    for _, batch in ipairs(batches) do
        ok, err = requestFn(batch, self.address)
        if not ok then
            return false, err or "Request submission failed"
        end
    end

    return true
end

return LogisticsRequester
