local component = require("component")
local log = require("log")
local c = require("reactor_conf")
local t_helper = require("term_helper")

local reactor = {
    interface = "",
    reactor_chamber = "",
    redstone_io = "",
    rod_type = "",
    coolant_type = ""
}

local INTERFACE_COOLANT_SLOT = 1

------------------------------------------------------------------------
----- STATICS

local C = c.COOLANT.HELIUM
local R = c.ROD.GLOWSTONE

local layout = { C, R, R, R, C, R, R, C, R,
    R, R, C, R, R, R, R, C, R,
    C, R, R, R, R, C, R, R, R,
    R, R, R, C, R, R, R, R, C,
    R, C, R, R, R, R, C, R, R,
    R, C, R, R, C, R, R, R, C }


local function resetLayout()
    layout = { C, R, R, R, C, R, R, C, R,
        R, R, C, R, R, R, R, C, R,
        C, R, R, R, R, C, R, R, R,
        R, R, R, C, R, R, R, R, C,
        R, C, R, R, R, R, C, R, R,
        R, C, R, R, C, R, R, R, C }
end

------------------------------------------------------------------------
-----HELPERS
local function getCoolantSlot()
    INTERFACE_COOLANT_SLOT = INTERFACE_COOLANT_SLOT + 1
    if INTERFACE_COOLANT_SLOT > c.INTERFACE.COOLANT.RANGE then
        INTERFACE_COOLANT_SLOT = 1
    end
    return INTERFACE_COOLANT_SLOT + c.INTERFACE.COOLANT.OFFSET
end

------------------------------------------------------------------------
-----INIT
local function loadReactor()
    for a, n in component.list("reactor_chamber", true) do
        log.info("Reactor Chamber: " .. a)
        reactor.reactor_chamber = component.proxy(a)
    end
end

local function loadInterface()
    for a, n in component.list("transposer", true) do
        log.info("Transposer: " .. a)
        reactor.interface = component.proxy(a)
    end
end

local function insertFuelRodInSlot(slot)
    log.verbose("Getting rSlot " .. slot)
    local rSlot = reactor.interface.getStackInSlot(c.REACTOR.SIDE, slot)
    log.verbose("Got rSlot")
    if rSlot ~= nil then
        log.verbose("rSlot not nil")
        reactor.interface.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
    end
    log.verbose("Transfering Rod")
    reactor.interface.transferItem(c.INTERFACE.SIDE, c.REACTOR.SIDE, 1, 1, slot)
    log.verbose("Transfered Rod")
end

local function changeCoolantForSlot(slot)
    local if_slot = getCoolantSlot()
    reactor.interface.swap(c.INTERFACE.SIDE, c.REACTOR.SIDE, if_slot, slot)
end

local function setup()
    local successfull_finish = true

    loadReactor()
    loadInterface()
    
    R = t_helper.multiSelect("DEFAULT FUEL ROD", c.ROD, "GLOWSTONE", c.ROD.GLOWSTONE)
    C = t_helper.multiSelect("DEFAULT COOLANT", c.COOLANT, "HELIUM", c.COOLANT.HELIUM)
    resetLayout()

    local inv = reactor.interface.getAllStacks(c.REACTOR.SIDE)
    local slot = 1



    for item in inv do
        if item.name ~= layout[slot] then
            successfull_finish = false
            log.verbose("Slot Mismatch!")
            log.verbose("Should Be: " .. layout[slot])
            log.verbose("Is: ", item.name)


            if layout[slot] == C then
                changeCoolantForSlot(slot)
            else
                insertFuelRodInSlot(slot)
            end

            log.split()
        end

        slot = slot + 1
    end

    if not successfull_finish then
        setup()
    end
end

setup()
