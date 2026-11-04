local m_reactor = require("reactor-libs.reactor-manager")
local m_lsc = require("reactor-libs.lsc-manager")
local log = require("reactor-libs.log")
local component = require("component")
local term = require("term")
local gpu = component.gpu
local screen = component.screen
local event = require("event")
screen.setPrecise(true)
local keepAlive = false

local function SCRAM(reason)
    m_reactor.SCRAM(reason or "Unknown SCRAM Source")
end

local border_width = 2
local border_height = 1

local function shutOff()
    keepAlive = false
end

local widget = {
    shutDown = {
        x = 90,
        y = 5,
        width = 10,
        height = 5,
        info = "User sent for ShutDown - Deactivating at end of Cycle",
        callback = shutOff
    },
    SCRAM = {
        x = 110,
        y = 5,
        width = 50,
        height = 15,
        info = "User sent for SCRAM - May God help us all.",
        callback = function() SCRAM("User sent for SCRAM") end
    }
}

local function drawBox(x,y, width, height, color, borderColor)
    gpu.setBackground(borderColor)
    gpu.fill(x,y,width,height, " ")

    gpu.setBackground(color)
    gpu.fill(x+border_width, y+border_height, width-border_width*2, height-border_height*2, " ")
end

local function drawText(text, x, y, color)
    gpu.setForeground(color)
    gpu.set(x,y, text)
end

local function setupWidgedBorders()

    drawBox(widget.shutDown.x, widget.shutDown.y, widget.shutDown.width, widget.shutDown.height, 0xb30021 , 0x6b0014)
    drawText("SHUTDOWN", widget.shutDown.x+1,widget.shutDown.y+2, 0xaed1ce)

    drawBox(widget.SCRAM.x, widget.SCRAM.y, widget.SCRAM.width, widget.SCRAM.height, 0xb30021 , 0x6b0014)
    drawText("SCRAM SCRAM SCRAM", widget.SCRAM.x+3, widget.SCRAM.y+3, 0xffffff)

    gpu.setForeground(0xf1f72a)
    gpu.setBackground(0x3f3b47)
    m_lsc.setupWidget()

    gpu.setBackground(0x3f3b47)
    gpu.setForeground(0xf1f72a)
    m_reactor.setupWidget()

    gpu.setBackground(0x3f3b47)
    gpu.setForeground(0xf1f72a)
    log.setupWidget()

    gpu.setForeground(0x0e6900)
end

local function addToWidget(address, object)
   widget[address] = object
end

local function getWidget(address)
    return widget[address]
end

local function userClick(x, y)
    for k, wid in pairs(widget) do
        if x > wid.x and x < wid.x+wid.width and y > wid.y and y < wid.y+wid.height then
            log.info(wid.info)
            log.draw()
            wid.callback()
            widget[k] = nil

            return true
        end
    end

    return true
end

local function main()
    local width = 160
    local height = 50

    keepAlive = true

    gpu.setBackground(0x000000)
    gpu.setResolution(width, height)

    log.info("INITIALIZING REACTOR SEQUENCE")

    log.info("SETTING UP REACTORS")

    local reactor_setup_result = m_reactor.setup(addToWidget, getWidget)

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

    gpu.setForeground(0x0e6900)
    gpu.setBackground(0x6a7a94)


    setupWidgedBorders()

    local function protected_main()
        m_reactor.shutDownRedstoneIOs()

        while keepAlive do
            local eventType, _, x, y, _, _ = event.pull(1)

            screen.setTouchModeInverted(false)

            if eventType == "touch" then
                userClick(x, y)
            end

            log.namedTimer("CYCLE")
            m_lsc.tick()
            m_lsc.drawLSCStatus()

            m_reactor.tick_all()

            log.namedDebug("CYCLE")
            log.draw()

            os.sleep(1) -- Without it clicks dont get registered properly gets mitigated with split server
        end

        log.error("Shutting Down")
        m_reactor.shutDownRedstoneIOs()
        return 1
    end

    local status, err = pcall(protected_main)

    if not status then
        m_reactor.shutDownRedstoneIOs()
        print(err)
    end
    m_reactor.shutDownRedstoneIOs()
    log.error("EOM")
end

term.clear()
main()

event.ignore("touch", userClick)
log.error("EOF")
gpu.setBackground(0x000000)
term.clear()