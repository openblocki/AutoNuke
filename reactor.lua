local m_reactor = require("reactor-manager")
local m_lsc = require("lsc-manager")
local log = require("log")
local keepAlive = false


local function SCRAM()
    m_reactor.SCRAM()
end

local function main()

    local reactor_setup_result = m_reactor.setup()

    if not reactor_setup_result then
        log.error("REACTOR SETUP NOT SUCCESSFULL. SCRAMMING!")
        SCRAM()
        error("REACTOR SETUP NOT SUCCESSFULL")
        return -1
    end

    local lsc_setup_result = m_lsc.setup()

    if not lsc_setup_result then
        log.error("LSC SETUP NOT SUCCESSFULL. SHUTTING DOWN!")
        m_reactor.shutDownRedstoneIOs()
        error("LSC SETUP NOT SUCCESSFULL")
        return -2
    end
    

    keepAlive = true

    local function protected_main()
        m_reactor.shutDownRedstoneIOs()
        while keepAlive do
            m_lsc.tick()
            m_reactor.tick_all()
        end

        m_reactor.shutDownRedstoneIOs()
    end

    local status, err = pcall(protected_main)
    if not status then
        m_reactor.shutDownRedstoneIOs()
        term.clear()
        print(err)
    end
    m_reactor.shutDownRedstoneIOs()
end

main()