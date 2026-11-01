local log = require("log")
local fs = require("filesystem")
local serialize = require("serialization")

local Db =  {
    dbPath = nil
}

function Db:new (o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

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
        
        log.info("Creating DB Object")
        local file, err = fs.open(self.dbPath..id, "w")

        if file == nil then
            log.error("Could not create file: "..id..". ERROR: ".. err)
            error("Could not create file: "..id..". ERROR: ".. err)
        end

        local serializedData = serialize.serialize(object)
        log.info("Writing Data")
        file:write(serializedData)
        log.info("Saving File")
        file:close()
end

function Db:objectExists(id)
    self:checkIfPathIsSet()

    return fs.exists(self.dbPath..id)
end

return Db