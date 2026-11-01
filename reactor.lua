local component = require("component")
local log = require("log")
local c = require("reactor_conf")
local t_helper = require("term_helper")
local term = require("term")
local db = require("db")

local reactors = {}
local transposers = {}
local redstone_ios = {}
local unknown_reactors = {}

local INTERFACE_COOLANT_SLOT = 1

------------------------------------------------------------------------
----- STATICS
local C = c.COOLANT.HELIUM
local R = c.ROD.GLOWSTONE

local layout = {}


local function resetLayout()
    layout = { C, R, R, R, C, R, R, C, R,
        R, R, C, R, R, R, R, C, R,
        C, R, R, R, R, C, R, R, R,
        R, R, R, C, R, R, R, R, C,
        R, C, R, R, R, R, C, R, R,
        R, C, R, R, C, R, R, R, C }
end
resetLayout()

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
----- DB STUFF
local function getReactorFromDB()
    return db:getById("500e695a-00dc-45b4-9741-4975f58737d0")
end

local function addReactorToDB(data, id)
    db:addObject(data, id)
end
------------------------------------------------------------------------
-----LOAD

local function loadReactor(adapter, transposer, redstone_io)
    local reactor = {
        reactor_chamber = component.proxy(adapter),
        transposer = component.proxy(transposer),
        redstone_io = component.proxy(redstone_io),
        data = {
            adapter = adapter,
            transposer = transposer,
            redstone_io = redstone_io
        }
    }
    reactors[adapter] = reactor
end

local function loadReactors()
    for a, n in component.list("reactor_chamber", true) do
        log.info("Reactor Chamber: " .. a)
        if db:objectExists(a) then
            log.info("Reactor Found in Database. Loading now")
            local data = db:getById(a)
            if data == nil then
                log.error("Reactor could not be Retrieved from DB")
                error("Reactor could not be Retrieved from DB")
            end
            loadReactor(data.adapter, data.transposer, data.redstone_io)

        else
            log.info("Reactor not Found in DB. Adding to Queue")
            unknown_reactors[#unknown_reactors+1] = a
        end
    end

    for k, v in pairs(reactors) do
        for x, y in pairs(transposers) do
            if y == v.data.transposer then
                table.remove(transposers, x)
            end
        end
        for x, y in pairs(redstone_ios) do
            if y == v.data.redstone_ios then
                table.remove(redstone_ios, x)
            end
        end
    end
end

local function resolveUnknownReactors()
    for k, v in pairs(unknown_reactors) do
        term.clear()
        for x, y in pairs(transposers) do
            log.beautify("Transposer")
            log.beautify(x)
            log.beautify(y)
        end
        for x, y in pairs(redstone_ios) do
            log.beautify("Redstone IOS")
            log.beautify(x)
            log.beautify(y)
        end

        local transposer, tKey = t_helper.multiSelectNoDefault("Transposer for Reactor "..v, transposers)
        local redstone_io, rKey = t_helper.multiSelectNoDefault("Redstone IO for Reactor "..v, redstone_ios)

        loadReactor(v, transposer, redstone_io)
        table.remove(transposers, tKey)
        table.remove(redstone_ios, rKey)
    end
    unknown_reactors = {}
end

local function getTransposers()
    local count = 1
    for a, n in component.list("transposer", true) do
        log.info("Transposer "..count..": " .. a)
        transposers[count] = a
        count = count + 1
    end
end

local function getRedstoneIOs()
    local count = 1
    for a, n in component.list("redstone", true) do
        log.info("Redstone IO "..count..": " .. a)
        redstone_ios[count] = a
        count = count + 1
    end
end

------------------------------------------------------------------------
-----SETUP
local function insertFuelRodInSlot(slot, address)
    log.verbose("Getting rSlot " .. slot)
    local rSlot = reactors[address].transposer.getStackInSlot(c.REACTOR.SIDE, slot)
    log.verbose("Got rSlot")
    if rSlot ~= nil then
        log.verbose("rSlot not nil")
        reactors[address].transposer.transferItem(c.REACTOR.SIDE, c.INTERFACE.SIDE, 1, slot, 9)
    end
    log.verbose("Transfering Rod")
    reactors[address].transposer.transferItem(c.INTERFACE.SIDE, c.REACTOR.SIDE, 1, 1, slot)
    log.verbose("Transfered Rod")
end

local function changeCoolantForSlot(slot, address)
    local if_slot = getCoolantSlot()
    log.warn(if_slot.." & "..slot)
    reactors[address].transposer.swap(c.INTERFACE.SIDE, c.REACTOR.SIDE, if_slot, slot)
end

local function setup()
    db:setPath("reactors")
    getTransposers()
    getRedstoneIOs()
    loadReactors()

    resolveUnknownReactors()

    local address = "500e695a-00dc-45b4-9741-4975f58737d0"

    R = t_helper.multiSelect("DEFAULT FUEL ROD", c.ROD, "GLOWSTONE", c.ROD.GLOWSTONE)
    C = t_helper.multiSelect("DEFAULT COOLANT", c.COOLANT, "HELIUM", c.COOLANT.HELIUM)
    resetLayout()

    local inv = reactors[address].transposer.getAllStacks(c.REACTOR.SIDE)

    ::fillReactor::
    local successfull_finish = true
    local slot = 1

    for item in inv do
        if item.name ~= layout[slot] then
            successfull_finish = false
            log.verbose("Slot Mismatch!")
            log.verbose("Should Be: " .. layout[slot])
            log.verbose("Is: ", item.name)

            if layout[slot] == C then
                changeCoolantForSlot(slot, address)
            else
                insertFuelRodInSlot(slot, address)
            end

            log.split()
        end

        slot = slot + 1
    end

    if not successfull_finish then
        goto fillReactor
    end

    log.info("Reactor Setup Complete!")
end

setup()