local log = require("reactor-libs.log")
local c = require("reactor-libs.reactor_conf")
local component = require("component")
local lsc = require("reactor-libs.lsc-manager")
local layout = require("reactor-libs.reactor-layout")

local Reactor = {
    reactor_chamber = nil,  --PROXY
    transposer = nil,       --PROXY
    redstone_io = nil,      --PROXY

    coolant = nil,
    rod = nil,

    override = false,
    override_reason = "No Reason Specified",

    coolant_slot = 1,

    skip_cycle = false,

    data = {
        adapter_a = nil, -- Acts as ID of Reactor 
        transposer_a = nil,
        redstone_io_a = nil
    }
}

function Reactor:new(data)
    local instance = setmetatable({}, self)

    self.coolant = data.coolant or c.DEFAULT.COOLANT
    self.rod = data.rod or c.DEFAULT.ROD

    self.reactor_chamber = component.proxy(data.adapter_a) or throw("PROXY FOR REACTOR ADAPTER "..data.adapter_a.." NOT FOUND!")
    self.transposer = component.proxy(data.transposer_a) or throw("PROXY FOR REACTOR TRANSPOSER "..data.transposer_a.." NOT FOUND!")
    self.redstone_io = component.proxy(data.redstone_io_a) or throw("PROXY FOR REACTOR REDSTONE_IO "..data.redstone_io_a.." NOT FOUND!")

    self.override = data.override or false
    self.override_reason = data.override_reason or "No Reason Specified"

    self.data.adapter_a = data.adapter_a
    self.data.transposer_a = data.transposer_a
    self.data.redstone_io_a = data.redstone_io_a

    return instance
end

function Reactor:getData() -- Used to get Data to load into Database
    local data = self.data
    data.coolant = self.coolant
    data.rod = self.rod
    data.override = self.override
    data.override_reason = self.override_reason
end

function Reactor:getCoolantSlot()
    self.coolant_slot = self.coolant_slot + 1

    if self.coolant_slot > c.INTERFACE.COOLANT.RANGE then
        self.coolant.slot = 1
    end

    return self.coolant.slot + c.INTERFACE.COOLANT.OFFSET
end

function Reactor:changeCoolantInSlot(slot)

    if not slot then
        log.vWarn("No Slot defined. Skipping Next Cycle")
        self:skipCycle()
        return 0
    end

    local counter = 0

    ::retryCoolant::
    local if_slot = self:getCoolantSlot()
    log.info("Changing Coolant for Reactor "..self:getID()..": "..if_slot.. "->"..slot)

    local interfaceItem = self.transposer.getStackInSlot(c.INTERFACE.SIDE, if_slot)
    if not interfaceItem then
        if counter > 5 then
            log.error("Could not swap Coolant for Reactor ".. self:getID().. " after ".. counter .. " tries.")
            log.error("Deactivating Reactor ".. self:getID() .. " for next Cycle")
            
            self:skipCycle()
            return 0
        end

        log.warn("No Coolant found in Interface Slot ".. if_slot.. ". Try " .. counter)
        log.warn("Trying next slot")
        counter = counter + 1
        goto retryCoolant

    elseif interfaceItem.name ~= c.COOLANT[self.coolant] then
        log.error("Interface Provided wrong Coolant for Reactor ".. self:getID())
        self:override("INTERFACE PROVIDED WRONG COOLANT: ".. interfaceItem.name)
    end

    self.transposer.swap(c.INTERFACE.SIDE, c.REACTOR.SIDE, if_slot, slot)
end

function Reactor:changeFuelRodInSlot(slot)

    if not slot then
        log.vWarn("No Slot defined. Not Changing Fuel Rod")
        return 0
    end

    local transposer = self.transposer

    local reactorItem = transposer.getStackInSlot(c.REACTOR.SIDE, slot)
    
    if reactorItem ~= nil then
        transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
    end

    local interfaceItem = transposer.getStackInSlot(c.INTERFACE.SIDE, 1)
    
    if not interfaceItem then
        log.error("Interface of Reactor "..self:getID().." has run out of Fuel Rods, skipping next Cycle")
        self:skipCycle()
        return 0
    end

    transposer.transferItem(c.INTERFACE.SIDE, c.REACTOR.SIDE, 1, 1, slot)

end

function Reactor:tick()
    if(self.override) then return end
    if(self.skip_cycle) then
        self.skip_cycle = false
        return
    end

    self:checkHeat()
    self:checkCoolant()
    self:checkRods()

    if self:isActive() and not self:canBeActive() then
        log.info("Reactor ".. self:getID() .. " is active but should be off. Turning off")
        self:deactivate()
    elseif not self:isActive() and self:canBeActive() and lsc.needsPower() then
        log.info("Turning on Reactor ".. self:getID() .. ".")
        self:activate()
    elseif self:isActive() and self:canBeActive() and not lsc.needsPower() then
        log.info("Deactivating Reactor "..self:getID().." due to high Power Levels")
        self:deactivate()
    elseif self:isActive() == self:canBeActive() and lsc.needsPower() then
        goto finish_tick
    else
        log.error("Unexcepted state missmatch. Deactivating for next Cycle")
        self:skipCycle()
    end

    ::finish_tick::
end

function Reactor:isActive()
    return self.redstone_io.getOutput(c.REDSTONEIO.SIDE) > 0
end

function Reactor:canBeActive()
    return (self:isHeatThresholdGood() + self:isCoolantGood() + self:areRodsGood()) == 3
end

function Reactor:isHeatThresholdGood() -- Non Triggering
    local currentHeat = self.reactor_chamber.getHeat()
    if c.ROD[self.rod] == c.ROD.MOX then
        if(currentHeat >= c.REACTOR.HEAT.MAX*c.REACTOR.HEAT.THRESHOLD_MOX) then
            return false
        end
    else
        if currentHeat >= c.REACTOR.HEAT.MAX*c.REACTOR.HEAT.THRESHOLD then
            return false
        end
    end

    return true
end

function Reactor:isCoolantGood() -- Non Triggering
    local badCoolant = {}

    for slot in layout.getCoolantSlots() do
        local item = self.reactor_chamber.getStackInSlot(c.REACTOR.SIDE, slot)

        if not item then
            log.warn("Reactor ".. self:getID() .. " missing Coolant in Slot ".. slot)
            table.insert(badCoolant, slot)
            goto nextCoolant
        end

        local currentHeat = item.damage
        local maxHeat = item.maxDamage
        local itemName = item.name

        if currentHeat > maxHeat * c.COOLANT_ITEM.HEAT_THRESHOLD then
            log.info("Changing Coolant for Reactor".. self:getID())
            table.insert(badCoolant, slot)
        elseif itemName ~= c.COOLANT[self.coolant] then
            log.warn("Unexpected Coolant for Reactor")
            table.insert(badCoolant, slot)
        end

        ::nextCoolant::
    end

    return #badCoolant>0, badCoolant
end

function Reactor:areRodsGood() -- Non Triggering
    local badRod = {}

    for slot in layout.getRodSlots() do
        local item = self.reactor_chamber.getStackInSlot(c.REACTOR.SIDE, slot)

        if not item then
            log.warn("Reactor ".. self:getID() .. " missing Fuel Rod in Slot ".. slot)
            table.insert(badRod, slot)
            goto nextRod
        end
        local itemName = item.name

        if itemName == c.DEPLETED_ROD[self.rod] then
            log.info("Changing Fuel Rod for Reactor".. self:getID())
            table.insert(badRod, slot)
        elseif itemName ~= c.ROD[self.rod] then
            log.warn("Unexpected Fuel Rod for Reactor")
            table.insert(badRod, slot)
        end

        ::nextRod::
    end

    return #badRod>0, badRod
end

function Reactor:checkHeat()
    if self:isHeatThresholdGood() then
        return
    end

    log.error("Reactor "..self:getID().. " went over the Heat threshold. ")
    log.error(self.reactor_chamber.getHeat().."/"..c.REACTOR.HEAT.MAX.. " => " .. c.REACTOR.HEAT.MAX/self.reactor_chamber.getHeat())
    self:SCRAM("HEAT THRESHOLD OVERSTEPPED")
end

function Reactor:checkCoolant() -- Maybe Copy isCoolantGood but make it swap while the check is running if current way is not fast enough
    local coolantGood, badCoolant = self:isCoolantGood()

    if not coolantGood then
        for slot in badCoolant do
            self:changeCoolantInSlot(slot)
        end
    end
end

function Reactor:checkRods() -- Check if any Rods are depleted or not present and replace or shutdown if not possible
    local rodsGood, badRods = self:areRodsGood()

    if not rodsGood then
        for slot in badRods do
            self:changeFuelRodInSlot(slot)
        end
    end
end

function Reactor:skipCycle()
    self:deactivate()
    self.skip_cycle = true
end

function Reactor:activate()
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE, 15)
end

-- Only turns off Redstone IO
function Reactor:deactivate()
    self.redstone_io.setOutput(c.REDSTONEIO.SIDE, 0)
end

-- Gracefull Shuttdown with Item Checks
function Reactor:shutOff()
    self:deactivate()

    self:checkHeat()
    self:checkCoolant()
    self:checkRods()
end

local function removeAllFuelRods(self)
    local slot = 1
    for item in self.transposer.getAllStacks(c.REACTOR.SIDE) do
        if not item then goto next end
        if item.name == self.rod then
            self.transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
        end
        ::next::
        slot = slot + 1
    end
end

local function removeAllCoolant(self)
    local slot = 1
    for item in self.transposer.getAllStacks(c.REACTOR.SIDE) do
        if not item then goto next end
        if item.name == self.coolant then
            self.transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
        end
        ::next::
        slot = slot + 1
    end
end

-- @param reason<string?> = "SCRAM"
function Reactor:SCRAM(reason)
    log.error("SCRAMMING REACTOR")

    self:deactivate()
    removeAllFuelRods(self)
    removeAllCoolant(self)

    self:activateOverride(reason or "SCRAM")
end

function Reactor:userOverride()
    self:activateOverride("Manual User override")
end

-- @param reason <string?>= "No Reason Set"
function Reactor:activateOverride(reason)
    log.warn("Overriding Reactor ".. self:getID() .. ".")
    log.warn("Override Reason: ".. (reason or "No Reason Set"))
    log.warn("Reactor will not be managed by AutoNuke until ReActivation")
    log.warn("Defaulting to OFF State")
    log.draw()

    self:shutOff()
    self.override_reason = reason or "No Reason Set"
    self.override = true
end

function Reactor:deactivateOverride()
    log.warn("ReActivating Reactor ".. self:getID() .. ".")
    log.warn("Normal behavior will continue in next Reactor Tick")
    log.warn("Defaulting to OFF State")
    log.draw()

    self:shutOff()
    self.override = false
    self.override_reason = "No Reason Set"
end

-- Retrieves ID of Reactor \
-- ID is adapter address
function Reactor:getID()
    return self.data.adapter_a
end

return Reactor