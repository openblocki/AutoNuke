local m_reactor = require("reactor-libs.reactor-manager")
local m_lsc = require("reactor-libs.lsc-manager")
local log = require("reactor-libs.log")
local component =  require("component")
local colors = require("colors")
local gpu = component.gpu

local keepAlive = false

local function SCRAM()
    m_reactor.SCRAM()
end

local function main()
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

    keepAlive = true

    local function drawLSCStatus()
        local lsc = m_lsc.getLSC()

        gpu.setBackground(0x6a7a94)
        gpu.fill(2,2,23,5, " ")
        gpu.set(3,2,"Max Power: "..lsc.MAXPOWER)
        gpu.set(3,4,"Current Power: "..lsc.POWER)
        gpu.set(3,6,"AVG Power: "..lsc.AVGPOWER())
    end

    local function setupWidgedBorders()
        gpu.setBackground(0x3f3b47)
        gpu.setForeground(0xf1f72a)
        gpu.fill(1,1,25,7, " ")
        gpu.set(1,1,"LSC")
        gpu.fill(78,29,83,23, " ")
        gpu.set(78,29,"LOG")
        gpu.setForeground(0x0e6900)
    end

    local function protected_main()
        local width = 160
        local height = 50
        gpu.freeAllBuffers()
        gpu.setResolution(width,height)
        gpu.fill(1, 1, width, height, " ")  -- Clear screen
        setupWidgedBorders()

        gpu.setForeground(0x0e6900)
        gpu.setBackground(0x6a7a94)

        m_reactor.shutDownRedstoneIOs()
        while keepAlive do
            log.info("Ticking LSC")
            m_lsc.tick()
            drawLSCStatus()


            -- Add Reactor Turn on and off 
            local reactor_status = true
            log.info("Checking LSC status")
            if m_lsc.needsPower() then -- And if Reactors are off
                    log.info("Activating Reactors")
            elseif not m_lsc.needsPower() then -- And if Reactors are on
                log.info("Reactors turned off due to full Energy Storage")
            end
            
            log.info("ticking reactors")
            if reactor_status then
                m_reactor.tick_all()
            end

            log.info("Cycle Finished")
            log.draw()
        end


        log.info("out of cycle")
        m_reactor.shutDownRedstoneIOs()
    end

    local status, err = pcall(protected_main)
    log.warn(tostring(keepAlive))
    log.warn("CONTROLL SCRIPT FINISHED")
    
    if not status then
        m_reactor.shutDownRedstoneIOs()
        print(err)
    end
    m_reactor.shutDownRedstoneIOs()
end

main()