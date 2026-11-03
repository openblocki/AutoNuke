local component = require("component")
local gpu = component.gpu

local left = 80
local top = 30

local width= 80
local height= 20

local lastTimer = 0
local computer = require("computer")


local NAMED_TIMESTAMP = {}
------------------------------------------------------------------------
-----LOGGING

local LOG = {}

local INFO = "[INFO] "
local WARN = "[WARN] "
local ERROR = "[ERROR] "
local VERBOSE = "[VERBOSE] "
local SCRAM = "[!SCRAM!] "
local EMPTY = ""

local function draw()
  gpu.setBackground(0x6a7a94)
  gpu.fill(left-5,top-5,width+4,height+5, " ")


  for k,v in pairs(LOG) do
    local message = v.data ..v.message
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
    elseif v.data == EMPTY then
      gpu.setForeground(0xffffff)
    end
    --print(message)
    gpu.set(left-5,top+k-6,message)
  end

  gpu.setForeground(0x0e6900)
end

local function setupWidget()
  gpu.fill(73, 24, 88, 28, " ")
  gpu.set(73, 24, "LOG")
  draw()
end

local function log(m)
  if m.data == VERBOSE then return end
  if #LOG==20 then
    table.remove(LOG,1)
  end
  table.insert(LOG,m)
end

return {
  draw = draw,
  setupWidget = setupWidget,

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

  timestamp = function ()
    lastTimer = computer.uptime()
  end,

  namedTimer = function (name)
    NAMED_TIMESTAMP[name] = computer.uptime()
  end,

  namedDebug = function (name)
    local now = computer.uptime()
    log({message = name .. " took ".. now - NAMED_TIMESTAMP[name]  .. " seconds", data = VERBOSE})
  end,

  timedDebug = function (m)
    local now = computer.uptime()
    log({message = "Since last Log: " .. now - lastTimer .." ".. m ,data = VERBOSE})
    lastTimer = now
  end,

  scram = function(m)
    log({message = m, data = SCRAM})
    draw()
  end,

  split = function()
    log({message ="------------", data = EMPTY })
    draw()
  end,

  longSplit = function()
    log({message = "---------------------------------", data = EMPTY})
    draw()
  end,

  beautify = function(m)
    log({message = "#  " .. m, data = EMPTY})
    draw()
  end
}
