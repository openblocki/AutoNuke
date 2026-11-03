local m_reactor = require("reactor-libs.reactor-manager")
local m_lsc = require("reactor-libs.lsc-manager")
local log = require("reactor-libs.log")
local component = require("component")
local term = require("term")
local gpu = component.gpu

local keepAlive = false

local function SCRAM()
    m_reactor.SCRAM()
end

local function setupWidgedBorders()
    gpu.setBackground(0x3f3b47)
    gpu.setForeground(0xf1f72a)

    m_lsc.setupWidget()

    gpu.setBackground(0x3f3b47)
    gpu.setForeground(0xf1f72a)
    m_reactor.setupWidget()

    gpu.setBackground(0x3f3b47)
    gpu.setForeground(0xf1f72a)
    log.setupWidget()

    gpu.setForeground(0x0e6900)
end

local function main()
    local width = 160
    local height = 50
    gpu.setBackground(0x000000)
    gpu.setResolution(width, height)

    log.info("INITIALIZING REACTOR SEQUENCE")

    log.info("SETTING UP REACTORS")

    local reactor_setup_result = m_reactor.setup()

    if not reactor_setup_result then
        log.error("REACTOR SETUP NOT SUCCESSFULL. SCRAMMING!")
        SCRAM()
        error("REACTOR SETUP NOT SUCCESSFULL")
        return -1
    end
    log.info("REACTORS SET UP")

    log.info("SETTING UP LSC")
    local lsc_setup_result = m_lsc.setup()
    
    if not lsc_setup_result then
        log.error("LSC SETUP NOT SUCCESSFULL. SHUTTING DOWN!")
        m_reactor.shutDownRedstoneIOs()
        error("LSC SETUP NOT SUCCESSFULL")
        return -2
    end
    log.info("LSC SET UP")

    --setupWidgedBorders()
    os.sleep(10)

    gpu.setForeground(0x0e6900)
    gpu.setBackground(0x6a7a94)


    keepAlive = true

    setupWidgedBorders()

    local function protected_main()
        m_reactor.shutDownRedstoneIOs()

        while keepAlive do        --0.55
            log.namedTimer("CYCLE")
            m_lsc.tick()          -- 0.1
            m_lsc.drawLSCStatus() -- 0.0

            m_reactor.tick_all()  -- 0.4 (If nothing is happening)

            log.namedDebug("CYCLE")
            log.draw()
        end


        log.error("Out of Cycle")
        m_reactor.shutDownRedstoneIOs()
    end

    local status, err = pcall(protected_main)
    log.error(err)
    log.error(tostring(keepAlive))
    log.error("CONTROLL SCRIPT FINISHED")
    print("CONTROLL SCRIPT ERRORED")
    print(tostring(keepAlive))
    print(err)

    if not status then
        m_reactor.shutDownRedstoneIOs()
        print(err)
    end
    m_reactor.shutDownRedstoneIOs()
end

term.clear()
main()
