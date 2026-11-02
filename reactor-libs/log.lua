local component = require("component")
local gpu = component.gpu

local left = 80
local top = 30

local width= 80
local height= 20

------------------------------------------------------------------------
-----LOGGING

local LOG = {}

local INFO = "INFO"
local WARN = "WARN"
local ERROR = "ERROR"
local VERBOSE = "VERBOSE"
local SCRAM = "!SCRAM!"

local function draw()
  gpu.setBackground(0x6a7a94)
  gpu.fill(left,top,width-1,height, " ")


  for k,v in pairs(LOG) do
    local message = "["..v.data.."] "..v.message
    if v.data == INFO then
      gpu.setForeground(0x9494e3)
    elseif v.data == WARN then
      gpu.setForeground(0xde8d0b)
    elseif v.data == ERROR then
      gpu.setForeground(0xc41f02)
    elseif v.data == VERBOSE then
      gpu.setForeground(0x665685)
    elseif v.data == SCRAM then
      gpu.setForeground(0xfc0303)
    end
    gpu.set(left,top+k-1,message)
  end

  gpu.setForeground(0x0e6900)
end

local function log(m)
  if #LOG==20 then
    table.remove(LOG,1)
  end
  table.insert(LOG,m)
end

return {
  draw = draw,

  info = function(m)
    log({message = m, data = INFO})
  end,

  warn = function(m)
    log({message = m, data = WARN})
  end,

  error = function(m)
    log({message = m, data = ERROR})
    draw()
  end,

  verbose = function(m)
    local caller = debug.getinfo(3, "n")
    if caller.name == nil then
      caller.name = "main"
    end
    log({message = "|" .. caller.name .. "| " .. m, data = VERBOSE})
  end,

  vWarn = function(m)
    local caller = debug.getinfo(3, "n")
    if caller.name == nil then
      caller.name = "main"
    end
    log({message = "|" .. caller.name .. "| " .. m, data = WARN})
  end,

  scram = function(m)
    log({message = m, data = SCRAM})
    draw()
  end,

  split = function()
    log("------------")
  end,

  longSplit = function()
    log("---------------------------------")
  end,

  beautify = function(m)
    log("#  " .. m)
  end
}
