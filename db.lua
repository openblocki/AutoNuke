local log = require("log")
local fs = require("filesystem")
local serialize = require("serialization")

Db =  {
    dbPath = nil
}

function Db:checkIfPathIsSet()
    if self.dbPath then return end
    log.error("Database Path has not been set")
    error("Database ID not set")
end

function Db:setPath(path)
    self.dbPath = "/database/"..path.."/"
end

function Db:getById(id)
    self:checkIfPathIsSet()

    if(fs.exists(self.dbPath..id)) then
        local file = io.open(self.dbPath..id, "r")
        if file then
            local data = file:read("*a")
            file:close()
            return serialize.unserialize(data)
        else
            log.error("Could not open file: "..id)
            error("Could not open file: "..id)
            return nil
        end
    else
        log.error("Could not find file: "..id)
        error("Could not find file: "..id)
        return nil
    end
end

function Db:addObject(object, id)
        self:checkIfPathIsSet()

        local file = io.open(self.dbPath..id, "w")

        if file == nil then
            log.error("Could not create file: "..id)
            error("Could not create file: "..id)
        end

        local serializedData = serialize.serialize(object)
        file:write(serializedData)
        file:close()
end

function Db:objectExists(id)
    self:checkIfPathIsSet()

    return fs.exists(Db.dbPath..id)
end

return Db