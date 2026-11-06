local log = require("reactor-libs.log")
local t_helper = require("reactor-libs.term_helper")
local DB = require("reactor-libs.db")
local REACTOR = require("reactor-libs.reactor")

local event = require("event")
local e_client, e_server = require("events")
local term = require("term")
local component = require("component")
local gpu = component.gpu

local db = DB:new()
local configdb = DB:new()

------------------------------------------------------------------------
-----SAFETY

local function shutDownRedstoneIOs()
    local count = 1
    for a, _ in component.list("redstone", true) do
        log.info("Shutting Down Redstone IO " .. a)
        component.proxy(a).setOutput({ 0, 0, 0, 0, 0, 0 })
        count = count + 1
    end
end

shutDownRedstoneIOs()
------------------------------------------------------------------------
-----VARIABLES
local reactors = {}
local adapters = {}
local known_adapters = {}
local redstone_ios = {}
local known_redstone_ios = {}
local unknown_reactors = {}

------------------------------------------------------------------------
-----HELPERS

local function sendShutdownToNetwork() -- These Events allow other Programs to Receive the info that the Reactors have Shut Down
    --local modem = require("modem")

    --modem.broadcast(0, "AN/E-SHUTDOWN")
    event.push("AN/E-SHUTDOWN")
end

local function SCRAM(reason) -- Rewrite Done
    log.scram("COMPLETE SCRAM INITATED!")
    log.scram("SHUTTING DOWN REDSTONE IOS!")
    shutDownRedstoneIOs()

    for _, reactor in pairs(reactors) do
        log.scram("SCRAMMING REACTOR " .. reactor:getID() .. "!")
        reactor:SCRAM(reason or "Reactor Manager Panicked")
    end

    log.scram("SENDING SHUTDOWN SIGNAL TO NETWORK")
    sendShutdownToNetwork()

    log.scram("SCRAM COMPLETED. RESTART COMPUTER TO REINITIALIZE!")
end


local addToWidget = function(address, object)
    log.error("Widget Registrar has not been set Properly - SCRAMMING for safety")
    SCRAM()
end

local getWidget = function (_)
    log.error("Widget Getter has not been set Properly - SCRAMMING for safety")
    SCRAM()
    return nil
end
------------------------------------------------------------------------
-----LOAD / STARTUP

local function loadReactor(data) -- Rewrite Done
    local reactor = REACTOR:new(data)

    reactors[reactor:getID()] = reactor
    return reactor
end

local function loadReactors() -- Rewrite Done
    for a, _ in component.list("reactor_chamber", true) do
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

    for _, v in pairs(reactors) do
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

local function getAdapters() --Rewrite done for ClientServer
    local count = 1
    for a, _ in component.list("reactor_chamber", true) do
        if known_adapters[a] then goto next end
        adapters[count] = a
        count = count + 1
        ::next::
    end
end

local function getRedstoneIOs() --Rewrite done for ClientServer
    local count = 1
    for a, _ in component.list("redstone", true) do
        if known_redstone_ios[a] then goto next end
        redstone_ios[count] = a
        count = count + 1
        ::next::
    end
end

local function resolveUnknownReactor(address) --Rewrite done for ClientServer
        gpu.setBackground(0x000000)
        term.clear()

        local adapter, aKey = t_helper.multiSelectNoDefault("Adapter for Reactor " .. address, getAdapters())
        local redstone_io, rKey = t_helper.multiSelectNoDefault("Redstone IO for Reactor " .. address, getRedstoneIOs())

        local data = {
            adapter_a = adapter,
            redstone_io_a = redstone_io,
            id = address,
            status = "Setting Up"
        }

        table.remove(adapters, aKey)
        table.remove(redstone_ios, rKey)

        return data
end

local function updateWidget() -- Needs Rewrite
    gpu.setBackground(0x6a7a94)
    gpu.setForeground(0xffffff)

    gpu.set(3, 13, "   │Reactor       │Heat  │Output      │Status")
    gpu.set(3, 14, "───┼──────────────┼──────┼────────────┼───────────────────────────────────")
    local reactor_display_format = " %s | %12s │ %3d%% │ %6dEU/t | %s"

    local count = 0
    for _, reactor in pairs(reactors) do
        local output = reactor:getOutput()
        local heat = reactor:getHeatPercentage()
        local address = reactor:getShortID()
        local status = reactor:getStatus()
        local onOff = reactor:getIsReactorOn()

        local statusColor = reactor:getStatusColor()

        gpu.setBackground(statusColor)
        gpu.fill(3, 15 + count, 76, 1, " ")
        gpu.set(3, 15 + count, string.format(reactor_display_format, onOff, address, heat, output, status))
        if reactor.override and not getWidget(address) then addToWidget(address, {
            isReactor = true,
            x = 3,
            y = 15 + count-1,
            width = 66,
            height = 1,
            info = "Override for Reactor " .. address .. " has been Revoked by user",
            callback = function() reactor:deactivateOverride("Reactivation by User") end
        }) end
        count = count + 1
    end
    gpu.setBackground(0x6a7a94)
    gpu.setForeground(0x999999)

    gpu.fill(3, 15 + count, 66, 1, " ")
    gpu.set(3, 15 + count, "INFO: If a Reactor has been Overriden, to ReActivate Click on that Reactor.")
end

------------------------------------------------------------------------
-----SETUP

local function setup(addToWidgetFunc, getWidgetFunc) --rewrite done ?
    log.info("Starting Reactor Setup.")
    log.draw()

    addToWidget = addToWidgetFunc
    getWidget = getWidgetFunc

    db:setPath("reactors")
    configdb:setPath("config")

    local reactor_list = db:getById("reactor_list")
    reactors = reactor_list

    for reactor in pairs(reactors) do
        known_adapters[reactor.adapter_a] = true
        known_redstone_ios[reactor.redstone_io_a] = true
    end

    getRedstoneIOs()
    getAdapters()

    if #adapters>0 then log.info("New Reactors found. Waiting for Setup Call") end

    log.info("Reactor Mananger Setup Complete!")
    log.draw()
    return 1
end

local function setupWidget()
    gpu.fill(1, 10, 80, 41, " ")
    gpu.set(1, 10, "Reactors")
    gpu.setBackground(0x6a7a94)
    gpu.fill(3, 11, 76, 39, " ")
    updateWidget()

    if (#reactors > 20) then
        gpu.set(3, 11, "Too Many Reactors. Can't display all!!!")
    end
end

local function clientStartup(address)
    if reactors[address] then reactors[address].status = "Starting Up" end
    e_server.startupreceived(address)
    return true
end

local function clientReboot(address)
    if reactors[address] then reactors[address].status = "Rebooting" end

    return true
end

local function clientPong(address)
    if not reactors[address] then return true end
    if reactors[address].diminshed or reactors[address].scrammed or reactors[address].distress then return true end
    reactors[address].status = "Running Fine"
    reactors[address].lastPong = 0

    return true
end

local function clientDistress(address)
    if not reactors[address] then return true end
    if reactors[address].scrammed then return true end

    reactors[address].scrammed = true
    reactors[address].status = "SCRAMMED"

    return true
end

local function clientNeedsSetup(address)
    reactors[address] = resolveUnknownReactor(address)
    e_server.setupdata(address, reactors[address])

    return true
end

local function clientSetupDone(address)
    reactors[address].status = "Setup Done"

    return true
end

return {
    setup = setup,
    SCRAM = SCRAM,
    shutDownRedstoneIOs = shutDownRedstoneIOs,
    updateWidget = updateWidget,
    setupWidget = setupWidget,
    clientDistress = clientDistress,
    clientNeedsSetup = clientNeedsSetup,
    clientPong = clientPong,
    clientReboot = clientReboot,
    clientSetupDone = clientSetupDone,
    clientStartup = clientStartup,}
