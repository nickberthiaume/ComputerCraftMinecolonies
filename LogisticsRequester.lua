local LogisticsRequester = {}
LogisticsRequester.__index = LogisticsRequester
LogisticsRequester.version = "v2.0"

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
    self.requester.setAddress(address)
    self.address = address
    return true
end

function LogisticsRequester:isValidItem(item)
    return item and item.name and tonumber(item.count) and tonumber(item.count) > 0
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

    if not self.requester.setRequest then
        return false, "RedstoneRequester does not support setRequest()"
    end
    if not self.requester.request then
        return false, "RedstoneRequester does not support request()"
    end

    local ok, err = self:setDestination(self.address)
    if not ok then
        return false, err or "Failed to set destination address"
    end

    local requestCount = 0
    for _, item in ipairs(items) do
        if self:isValidItem(item) then
            local request = { name = tostring(item.name), count = tonumber(item.count) }
            local success, requestErr = pcall(self.requester.setRequest, self.requester, request)
            if not success then
                return false, requestErr or "Failed to set item request"
            end

            success, requestErr = pcall(self.requester.request, self.requester)
            if not success then
                return false, requestErr or "Failed to send item request"
            end

            requestCount = requestCount + 1
        end
    end

    if requestCount == 0 then
        return false, "No valid request items provided"
    end

    return true
end

return LogisticsRequester
