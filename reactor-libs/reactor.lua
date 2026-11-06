local log = require("reactor-libs.log")
local c = require("reactor-libs.reactor_conf")
local layout = require("reactor-libs.reactor-layout")

local Reactor = {
    reactor_chamber = nil, --PROXY
    redstone_io = nil,     --PROXY

    override = false,
    override_reason = "No Reason Specified",

    status = "No Status Set",

    data = {
        adapter_a = nil, -- Acts as ID of Reactor
        redstone_io_a = nil,
    }
}

local function throw(message)
    log.error(message)
    error(message)
end

function Reactor:new(data)
    local instance = setmetatable({}, self)
    self.__index = self

    self.override = data.override or false
    self.override_reason = data.override_reason or "No Reason Specified"

    self.data.adapter_a = data.adapter_a
    self.data.redstone_io_a = data.redstone_io_a

    return instance
end

function Reactor:setup()
    
    local reactor_layout = layout.getReactorLayout(c.COOLANT[self.coolant], c.ROD[self.rod])

    if c.MOX_BEHAVIOUR[self.rod] then
        log.info("Warming up Reactor ".. self:getShortID())
        log.info("This may take a while.")
        log.draw()
        self:warmUp()
    end

    log.info("Setup for Reactor " .. self:getShortID() .. " done.")
end


function Reactor:isActive()
    return self.redstone_io.getOutput(c.REDSTONEIO.SIDE) > 0
end


function Reactor:activate()
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE_EXTRA, 15)
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE, 15)
end

-- Only turns off Redstone IO
function Reactor:deactivate()
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE_EXTRA, 0)
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE, 0)
end

-- Gracefull Shuttdown with Item Checks
function Reactor:shutOff()
    self:deactivate()

    self:checkHeat()

    local coolant, rods = self:getContents()

    self:checkCoolant(coolant)
    self:checkRods(rods)
end

-- @param reason<string?> = "SCRAM"
function Reactor:SCRAM(reason)
    log.scram("SCRAMMING REACTOR")

    self:deactivate()

    self:activateOverride(reason or "SCRAM")
end

function Reactor:userOverride()
    self:activateOverride("Manual User override")
end

-- @param reason <string?>= "No Reason Set"
function Reactor:activateOverride(reason)
    log.warn("Overriding Reactor " .. self:getShortID() .. ".")
    log.warn("Override Reason: " .. (reason or "No Reason Set"))
    log.warn("Reactor will not be managed by AutoNuke until ReActivation")
    log.warn("Defaulting to OFF State")
    log.draw()

    self:shutOff()
    self.override_reason = reason or "No Reason Set"
    self.override = true
end

function Reactor:deactivateOverride(reason)
    log.warn("ReActivating Reactor " .. self:getShortID() .. ".")
    log.warn("Normal behavior will continue in next Reactor Tick")
    log.warn("Defaulting to OFF State")
    log.draw()

    self:shutOff()
    self.override = false
    self.override_reason = reason or "No Reason Set"
end

-- Retrieves ID of Reactor \
-- ID is adapter address
function Reactor:getID()
    return self.data.adapter_a
end

function Reactor:getShortID()
    return string.sub(tostring(self:getID()), 1, 12)
end

function Reactor:getOutput()
    return math.floor(self.reactor_chamber.getReactorEUOutput())
end

function Reactor:getHeatPercentage()
    return math.floor((self.reactor_chamber.getHeat() / self.reactor_chamber.getMaxHeat()) * 100)
end

function Reactor:getStatus()
    if self.override then return "Override: " .. self.override_reason end
    return self.status
end

function Reactor:getIsReactorOn()
    if self.override then return "O" end
    if self:isActive() then return "☑" else return "☐" end
end

function Reactor:getStatusColor()
    if self.override then return 0x61c8ff end
    if not self:isActive() then return 0x3b3838 end
    if not self.status == "Running Fine" and not self.status == "Idling" then return 0xff9d00 end
    if self:isActive() then return 0x009407 end
    return 0x009407
end

return Reactor
