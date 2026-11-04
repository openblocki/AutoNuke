local log = require("reactor-libs.log")
local c = require("reactor-libs.reactor_conf")
local component = require("component")
local lsc = require("reactor-libs.lsc-manager")
local layout = require("reactor-libs.reactor-layout")

local Reactor = {
    reactor_chamber = nil, --PROXY
    transposer = nil,      --PROXY
    redstone_io = nil,     --PROXY

    maxHeat = 100, -- Defaults to 100 to SCRAM quickly in case of bad Setup
    coolant = nil,
    rod = nil,

    override = false,
    override_reason = "No Reason Specified",

    coolant_slot = 1,

    skip_cycle = false,

    status = "No Status Set",

    data = {
        adapter_a = nil, -- Acts as ID of Reactor
        transposer_a = nil,
        redstone_io_a = nil,
        maxheat = 100 -- Defaults to 100 to SCRAM quickly in case of bad Setup
    }
}

local function throw(message)
    log.error(message)
    error(message)
end

function Reactor:new(data)
    local instance = setmetatable({}, self)
    self.__index = self

    self.coolant = data.coolant or c.DEFAULT.COOLANT
    self.rod = data.rod or c.DEFAULT.ROD

    self.reactor_chamber = component.proxy(data.adapter_a) or
    throw("PROXY FOR REACTOR ADAPTER " .. data.adapter_a .. " NOT FOUND!")
    self.transposer = component.proxy(data.transposer_a) or
    throw("PROXY FOR REACTOR TRANSPOSER " .. data.transposer_a .. " NOT FOUND!")
    self.redstone_io = component.proxy(data.redstone_io_a) or
    throw("PROXY FOR REACTOR REDSTONE_IO " .. data.redstone_io_a .. " NOT FOUND!")

    self.maxHeat = self.reactor_chamber.getMaxHeat() or 100

    self.override = data.override or false
    self.override_reason = data.override_reason or "No Reason Specified"

    self.data.maxHeat = self.maxHeat
    self.data.adapter_a = data.adapter_a
    self.data.transposer_a = data.transposer_a
    self.data.redstone_io_a = data.redstone_io_a

    return instance
end

function Reactor:setup()
    local inventory = self.transposer.getAllStacks(c.REACTOR.SIDE)
    local reactor_layout = layout.getReactorLayout(c.COOLANT[self.coolant], c.ROD[self.rod])

    if c.MOX_BEHAVIOUR[self.rod] then
        log.info("Warming up Reactor ".. self:getShortID())
        log.info("This may take a while.")
        log.draw()
        self:warmUp()
    end

    ::setupReactor::
    local successfull_finish = true
    local slot = 1

    for item in inventory do
        if item.name ~= reactor_layout[slot] then
            successfull_finish = false
            log.verbose("Slot missmatch at Reactor " .. self:getShortID())
            log.verbose("Should be: " .. reactor_layout[slot])

            if not item.name then
                item.name = "Empty"
            end
            log.verbose("Is: " .. item.name)

            if layout.getTypeForSlot(slot) == c.WORD.COOLANT then
                self:changeCoolantInSlot(slot)
            else
                self:changeFuelRodInSlot(slot)
            end
        end
        slot = slot + 1
    end
    if not successfull_finish then
        goto setupReactor
    end

    log.info("Setup for Reactor " .. self:getShortID() .. " done.")
end

function Reactor:warmUp()
    local currentHeatPercentage = self:getHeatPercentage()
    local heatGoal = c.REACTOR.HEAT.WARMUP_MOX
    if currentHeatPercentage >= heatGoal*100 then
        log.info("Warmup Phase was cancelled as Reactor " .. self:getShortID() .." is already at or over Heat Goal")
        log.info("Current Heat: " .. currentHeatPercentage .. "%. Heat Goal: "..heatGoal*100 .."%")
        log.draw()
        return 1
    end

    self:deactivate()
    self:changeFuelRodInSlot(1) -- One Rod may be to slow, maybe increase that

    self:activate()
     while self:getHeatPercentage() < heatGoal*100 do
        os.sleep(0.5) -- Lets the OS yield so this doesnt crash
     end
    self:deactivate()

    log.info("Warm Up for Reactor ".. self:getShortID() .. " finished. Continuing Setup.")
    log.draw()
    self.transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, 1, 9)
end

function Reactor:getData() -- Used to get Data to load into Database
    local data = self.data
    data.coolant = self.coolant
    data.rod = self.rod
    data.override = self.override
    data.override_reason = self.override_reason
    data.status = self.status

    return data
end

function Reactor:getCoolantSlot()
    self.coolant_slot = self.coolant_slot + 1

    if self.coolant_slot > c.INTERFACE.COOLANT.RANGE then
        self.coolant_slot = 1
    end

    return self.coolant_slot + c.INTERFACE.COOLANT.OFFSET
end

function Reactor:changeCoolantInSlot(slot)
    if not slot then
        log.vWarn("No Slot defined. Skipping Next Cycle")
        self:skipCycle("No Coolant Slot Defined")
        return 0
    end

    local counter = 0

    ::retryCoolant::
    local if_slot = self:getCoolantSlot()
    log.info("Changing Coolant for Reactor " .. self:getShortID())

    local interfaceItem = self.transposer.getStackInSlot(c.INTERFACE.SIDE, if_slot)
    if not interfaceItem then
        if counter > 5 then
            log.error("Could not swap Coolant for Reactor " .. self:getShortID() .. " after " .. counter .. " tries.")
            log.error("Deactivating Reactor " .. self:getShortID() .. " for next Cycle")

            self:skipCycle("No Coolant found in Interface")
            return 0
        end

        log.warn("No Coolant found in Interface Slot " .. if_slot .. ". Try " .. counter)
        log.warn("Trying next slot")
        counter = counter + 1
        goto retryCoolant
    elseif interfaceItem.name ~= c.COOLANT[self.coolant] then
        log.error("Interface Provided wrong Coolant for Reactor " .. self:getShortID())
        self:override("INTERFACE PROVIDED WRONG COOLANT: " .. interfaceItem.name)
    end

    self.transposer.swap(c.INTERFACE.SIDE, c.REACTOR.SIDE, if_slot, slot)
end

function Reactor:changeFuelRodInSlot(slot)
    if not slot then
        log.vWarn("No Slot defined. Not Changing Fuel Rod")
        return 0
    end

    log.info("Changing Fuel Rod for Reactor " .. self:getShortID())

    local transposer = self.transposer

    local reactorItem = transposer.getStackInSlot(c.REACTOR.SIDE, slot)

    if reactorItem ~= nil then
        transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
    end

    local interfaceItem = transposer.getStackInSlot(c.INTERFACE.SIDE, 1)

    if not interfaceItem then
        log.warn("Interface of Reactor " .. self:getShortID() .. " has run out of Fuel Rods")
        self.status = "Missing Fuel Rods"
        --self:skipCycle("No Fuel Rods in Interface") -- Deactivated for now since it is not Harmfull
        return 0
    end

    transposer.transferItem(c.INTERFACE.SIDE, c.REACTOR.SIDE, 1, 1, slot)
end

function Reactor:tick()
    if (self.override) then return end
    if (self.skip_cycle) then
        self.skip_cycle = false
        return
    end
    self:checkHeat()                               -- 0.05

    local coolant, rods = self:getContents()       -- 0.049

    self:checkCoolant(coolant)                     -- 0.0
    self:checkRods(rods)                           -- 0.0
    local isActive = self:isActive()               -- 0.0
    local canBeActive = self:canBeActive()         --0.1
    local needsPower = lsc.needsPower()            -- 0.0

    if isActive == canBeActive and needsPower then -- 0.0
        self.status = "Running Fine"
        return
    elseif isActive and not canBeActive then
        self.status = "Turned off for Safety"
        log.info("Reactor " .. self:getShortID() .. " is active but should be off. Turning off")
        self:deactivate()
    elseif not isActive and canBeActive and needsPower then
        self.status = "Turning on"
        log.info("Turning on Reactor " .. self:getShortID() .. ".")
        self:activate()
    elseif isActive and canBeActive and not needsPower then
        self.status = "Idling"
        log.info("Deactivating Reactor " .. self:getShortID() .. " due to high Power Levels")
        self:deactivate()
    elseif not isActive and canBeActive and not needsPower then
        return
    else
        log.error("Unexcepted state missmatch. Deactivating for next Cycle")
        self:skipCycle("Unexpected State Missmatch")
    end
end

function Reactor:getContents()
    local lay = layout.getReactorLayout(c.WORD.COOLANT, c.WORD.ROD)

    local items = self.transposer.getAllStacks(c.REACTOR.SIDE)

    local coolant = {}
    local rods = {}

    for k, v in pairs(lay) do
        if v == c.WORD.COOLANT then
            table.insert(coolant, { item = items[k], slot = k })
        else
            table.insert(rods, { item = items[k], slot = k })
        end
    end

    return coolant, rods
end

function Reactor:isActive()
    return self.redstone_io.getOutput(c.REDSTONEIO.SIDE) > 0
end

function Reactor:canBeActive()               -- Make Parallel?
    local cool, rod = self:getContents()
    local heat = self:isHeatThresholdGood()  -- 0.05
    local coolant = self:isCoolantGood(cool) -- 0.7
    local rods = self:areRodsGood(rod)       -- 2.0 (Its Acceptable if Rods are Depleted for a single Cycle)

    local canBeActive = heat and coolant and rods
    return canBeActive
end

function Reactor:isHeatThresholdGood() -- Non Triggering
    local currentHeat = self.reactor_chamber.getHeat()
    if c.MOX_BEHAVIOUR[self.rod] then
        if (currentHeat >= self.maxHeat * c.REACTOR.HEAT.THRESHOLD_MOX) then
            return false
        end
    else
        if currentHeat >= self.maxHeat * c.REACTOR.HEAT.THRESHOLD then
            return false
        end
    end

    return true
end

function Reactor:isCoolantGood(coolant) -- Non Triggering
    local badCoolant = {}

    for _, cool in pairs(coolant) do
        if not cool.item then
            log.warn("Reactor " .. self:getShortID() .. " missing Coolant in Slot " .. cool.slot)
            table.insert(badCoolant, cool.slot)
            goto nextCoolant
        end

        local currentHeat = cool.item.damage
        local maxHeat = cool.item.maxDamage
        local itemName = cool.item.name

        if currentHeat > maxHeat * c.COOLANT_ITEM.HEAT_THRESHOLD then
            table.insert(badCoolant, cool.slot)
        elseif itemName ~= c.COOLANT[self.coolant] then
            log.warn("Unexpected Coolant for Reactor " .. self:getShortID())
            table.insert(badCoolant, cool.slot)
        end

        ::nextCoolant::
    end

    return #badCoolant == 0, badCoolant
end

function Reactor:areRodsGood(rod)
    local badRod = {}

    for _, ro in pairs(rod) do
        if not ro.item then
            log.warn("Reactor " .. self:getShortID() .. " missing Fuel Rod in Slot " .. ro.slot)
            table.insert(badRod, ro.slot)
            goto nextRod
        end
        local itemName = ro.item.name

        if itemName == c.DEPLETED_ROD[self.rod] then
            table.insert(badRod, ro.slot)
        elseif itemName ~= c.ROD[self.rod] then
            log.warn("Unexpected Fuel Rod for Reactor " .. self:getShortID())
            table.insert(badRod, ro.slot)
        end

        ::nextRod::
    end

    return #badRod == 0, badRod
end

function Reactor:checkHeat()
    if self:isHeatThresholdGood() then
        return
    end

    local maxHeat = self.reactor_chamber.getMaxHeat()
    local heat = self.reactor_chamber.getHeat()

    log.error("Reactor " .. self:getShortID() .. " went over the Heat threshold. ")
    log.error(heat ..
    "/" .. maxHeat .. " => " .. (maxHeat/heat)*100 .. "%")
    self:SCRAM("HEAT THRESHOLD OVERSTEPPED")
end

function Reactor:checkCoolant(coolant)
    local coolantGood, badCoolant = self:isCoolantGood(coolant)
    if not coolantGood then
        for _, slot in pairs(badCoolant) do
            log.info("Changing Coolant for Reactor " .. self:getShortID())
            self:changeCoolantInSlot(slot)
        end
    end
end

function Reactor:checkRods(rod)
    local rodsGood, badRods = self:areRodsGood(rod)
    -- Maybe Do on Seperate Thread to since this can be non Blocking
    if not rodsGood then
        for _, slot in pairs(badRods) do
            log.info("Changing Rod for Reactor " .. self:getShortID())
            self:changeFuelRodInSlot(slot)
        end
    end
end

function Reactor:skipCycle(reason)
    self.status = "Skipping Cycle: " .. (reason or "No Reason")
    self:deactivate()
    self.skip_cycle = true
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

local function removeAllFuelRods(self)
    local slot = 1
    for item in self.transposer.getAllStacks(c.REACTOR.SIDE) do -- Remove If check to increase Speed
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
    log.scram("SCRAMMING REACTOR")

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
