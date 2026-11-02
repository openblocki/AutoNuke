local log = require("reactor-libs.log")
local c = require("reactor-libs.reactor_conf")
local t_helper = require("reactor-libs.term_helper")
local DB = require("reactor-libs.db")
local REACTOR = require("reactor-libs.reactor")

local event = require("event")
local term = require("term")
local component = require("component")

local db = DB:new()
local configdb = DB:new()

------------------------------------------------------------------------
-----SAFETY

local function shutDownRedstoneIOs()
    local count = 1
    for a, n in component.list("redstone", true) do
        log.info("Shutting Down Redstone IO ".. a)
        component.proxy(a).setOutput({ 0, 0, 0, 0, 0, 0 })
        count = count + 1
    end
end

shutDownRedstoneIOs()
------------------------------------------------------------------------
-----VARIABLES
local reactors = {}
local transposers = {}
local redstone_ios = {}
local unknown_reactors = {}
local INTERFACE_COOLANT_SLOT = 1

------------------------------------------------------------------------
-----HELPERS
local function sendShutdownToNetwork() -- These Events allow other Programs to Receive the info that the Reactors have Shut Down
   local modem = require("modem")
   

   modem.broadcast(0, "AN/E-SHUTDOWN")
   event.push("AN/E-SHUTDOWN")
end

local function SCRAM() -- Rewrite Done
    log.scram("COMPLETE SCRAM INITATED!")
    log.scram("SHUTTING DOWN REDSTONE IOS!")
    shutDownRedstoneIOs()

    for reactor in reactors do
        log.scram("SCRAMMING REACTOR "..reactor:getID() .."!")
        reactor:SCRAM()
    end

    log.scram("SENDING SHUTDOWN SIGNAL TO NETWORK")
    sendShutdownToNetwork()

    log.scram("SCRAM COMPLETED. RESTART COMPUTER TO REINITIALIZE!")
end

------------------------------------------------------------------------
-----LOAD / STARTUP
local function loadReactor(data) -- Rewrite Done
    local reactor = REACTOR:new(data)

    reactors[reactor:getID()] = reactor
    return reactor
end

local function loadUnknownReactor(data) -- Rewrite Done
    local reactor = loadReactor(data)

    db:addObject(reactor:getData(), reactor:getID())
end

local function loadReactors() -- Rewrite Done
    for a, n in component.list("reactor_chamber", true) do
        log.info("Reactor Chamber Found: " .. a)
        if db:objectExists(a) then
            log.info("Reactor Found in Database. Loading now")

            local data = db:getById(a)
            if data == nil then

                log.error("Reactor could not be Retrieved from DB")
                error("Reactor could not be Retrieved from DB")
            end

            loadReactor(data)

            log.info("Reactor successfully loaded!")
        else

            log.info("Reactor not Found in DB. Adding to Queue")
            unknown_reactors[#unknown_reactors + 1] = a
        end
        log.draw()
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

local function resolveUnknownReactors() -- Rewrite Done
    for k, adapter in pairs(unknown_reactors) do
        term.clear()

        local transposer, tKey = t_helper.multiSelectNoDefault("Transposer for Reactor " .. v, transposers)
        local redstone_io, rKey = t_helper.multiSelectNoDefault("Redstone IO for Reactor " .. v, redstone_ios)

        loadUnknownReactor({
            adapter_a = adapter,
            transposer_a = transposer,
            redstone_io_a = redstone_io})
            
        table.remove(transposers, tKey)
        table.remove(redstone_ios, rKey)
    end
    unknown_reactors = {}
end

local function getTransposers()
    local count = 1
    for a, n in component.list("transposer", true) do
        transposers[count] = a
        count = count + 1
    end
end

local function getRedstoneIOs()
    local count = 1
    for a, n in component.list("redstone", true) do
        redstone_ios[count] = a
        count = count + 1
    end
end

local function tick_all() -- Rewritten / Update Logging
    for reactor in reactors do
        reactor:tick()
    end

    log.info("Ticked Reactors")
end

------------------------------------------------------------------------
-----SETUP
local function setup()
    log.info("Starting Reactor Setup.")
    log.draw()
    db:setPath("reactors")
    configdb:setPath("config")

    getTransposers()
    getRedstoneIOs()
    loadReactors()

    resolveUnknownReactors()

    -- Rewrite Done
    for reactor in reactors do
        reactor.setup()
        log.draw()
    end
    log.info("Reactor Setup Complete!")
    log.draw()
    return 1
end

return {
    setup = setup,
    SCRAM = SCRAM,
    tick_all = tick_all
}