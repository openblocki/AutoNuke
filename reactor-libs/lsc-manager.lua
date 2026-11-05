local c = require("reactor-libs.reactor_conf")
local log = require("reactor-libs.log")
local event = require("event")
local component = require("component")
local gpu = component.gpu

local lsc = {}

local function tick()
    lsc.POWER = lsc.MACHINE.getEUStored()
    lsc.POWERIN = lsc.MACHINE.getAverageElectricInput()
    lsc.POWEROUT = lsc.MACHINE.getAverageElectricOutput()

    event.push("AN/STATUS/LSC", lsc)
end

local function setup()

    for a, n in component.list() do
        if n == "gt_machine" then
            local gt_proxy = component.proxy(a)
            if gt_proxy.getName() == "multimachine.supercapacitor" then
                lsc.MACHINE = gt_proxy
            end
        end
    end

    lsc.MAXPOWER = lsc.MACHINE.getEUCapacity()
    lsc.MAXPOWERSTRING = lsc.MACHINE.getEUCapacityString()
    lsc.TURNONPOWER = lsc.MAXPOWER * c.LSC.POWERMIN
    lsc.TURNOFFPOWER = lsc.MAXPOWER * c.LSC.POWERMAX
    
    lsc.AVGPOWER = function ()
      return lsc.POWERIN - lsc.POWEROUT
    end

    tick()
    return 1
end

local function drawLSCStatus()

    gpu.setBackground(0x6a7a94)
    gpu.setForeground(0x0e6900)
    gpu.fill(3, 2, 33, 5, " ")
    gpu.set(3, 2, "[Max Power] " .. lsc.MAXPOWER .. " EU")
    gpu.set(3, 4, "[Current Power] " .. lsc.POWER.. " EU")
    gpu.set(3, 6, "[AVG Power] " .. lsc.AVGPOWER().. " EU/t")
end

local function setupWidget()
    gpu.fill(1, 1, 37, 7, " ")
    gpu.set(1, 1, "LSC")
    drawLSCStatus()
end

local function needsPower()
    if(lsc.AVGPOWER()<0) then return true end -- If Usage is Higher than Generation turn on regardless of Energy Level

    if(lsc.POWER>lsc.TURNOFFPOWER) then return false end

    if(lsc.POWER<lsc.TURNONPOWER) then return true end

    --event.push("AN/LOG/UNEXPECTED", "LSC Function :needsPower(): moved unexpected")

    return true
end

local function getLSC()
    return lsc
end

return {
    tick = tick,
    setup = setup,
    needsPower = needsPower,
    getLSC = getLSC,
    setupWidget = setupWidget,
    drawLSCStatus = drawLSCStatus
}
