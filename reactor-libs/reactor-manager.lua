local log = require("reactor-libs.log")
local c = require("reactor-libs.reactor_conf")
local t_helper = require("reactor-libs.term_helper")
local DB = require("reactor-libs.db")
local REACTOR = require("reactor-libs.reactor")
local term_helper = require("reactor-libs.term_helper")

local event = require("event")
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
local transposers = {}
local redstone_ios = {}
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

local function loadUnknownReactor(data) -- Rewrite Done
    local tranpsoser = component.proxy(data.transposer_a)
    local interface_coolant = tranpsoser.getStackInSlot(c.INTERFACE.SIDE, 2)
    local interface_rod = tranpsoser.getStackInSlot(c.INTERFACE.SIDE, 1)
    if interface_rod then
        for k, v in pairs(c.ROD) do
            if v == interface_rod.name then
                interface_rod = k
            end
        end
        log.info("Auto Detected Fuel " .. interface_rod .. " for Reactor " .. data.adapter_a)
    else
        interface_rod = term_helper.multiSelect("Fuel Rod for Reactor " .. data.adapter_a, c.ROD, "GLOWSTONE",
            c.ROD.GLOWSTONE)
    end
    if interface_coolant then
        for k, v in pairs(c.COOLANT) do
            if v == interface_coolant.name then
                interface_coolant = k
            end
        end
        log.info("Auto Detected Coolant " .. interface_coolant .. " for Reactor " .. data.adapter_a)
    else
        interface_coolant = term_helper.multiSelect("Coolant for Reactor " .. data.adapter_a, c, "HELIUM",
            c.COOLANT.HELIUM)
    end
    data.coolant = interface_coolant
    data.rod = interface_rod

    local reactor = loadReactor(data)

    db:addObject(reactor:getData(), reactor:getID())
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

local function resolveUnknownReactors()
    log.info("Resolving Unknown Reactors")
    for _, adapter in pairs(unknown_reactors) do
        gpu.setBackground(0x000000)
        term.clear()

        local transposer, tKey = t_helper.multiSelectNoDefault("Transposer for Reactor " .. adapter, transposers)
        local redstone_io, rKey = t_helper.multiSelectNoDefault("Redstone IO for Reactor " .. adapter, redstone_ios)

        loadUnknownReactor({
            adapter_a = adapter,
            transposer_a = transposer,
            redstone_io_a = redstone_io
        })

        table.remove(transposers, tKey)
        table.remove(redstone_ios, rKey)
    end
    unknown_reactors = {}
end

local function getTransposers()
    local count = 1
    for a, _ in component.list("transposer", true) do
        transposers[count] = a
        count = count + 1
    end
end

local function getRedstoneIOs()
    local count = 1
    for a, _ in component.list("redstone", true) do
        redstone_ios[count] = a
        count = count + 1
    end
end

local function updateWidget()
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

local function tick_all()
    log.namedTimer("TICK_ALL")
    for _, reactor in pairs(reactors) do
        log.namedTimer("SINGLE_REACTOR")
        reactor:tick() --0.35 In Blank Run
        log.namedDebug("SINGLE_REACTOR")
    end
    log.namedDebug("TICK_ALL")
    updateWidget()
end

------------------------------------------------------------------------
-----SETUP
local function setup(addToWidgetFunc, getWidgetFunc)
    log.info("Starting Reactor Setup.")
    log.draw()

    addToWidget = addToWidgetFunc
    getWidget = getWidgetFunc
    db:setPath("reactors")
    configdb:setPath("config")

    getTransposers()
    getRedstoneIOs()
    loadReactors()
    resolveUnknownReactors()
    -- Rewrite Done
    for _, reactor in pairs(reactors) do
        reactor:setup()
        log.draw()
    end
    log.info("Reactor Setup Complete!")
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

return {
    setup = setup,
    SCRAM = SCRAM,
    tick_all = tick_all,
    shutDownRedstoneIOs = shutDownRedstoneIOs,
    updateWidget = updateWidget,
    setupWidget = setupWidget
}
