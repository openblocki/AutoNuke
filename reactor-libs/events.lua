local event = require("event")

local autoNuke = "AU/" 
local micro = autoNuke.."MICROCONTROLLER/"
local serv = autoNuke.."SERVER/"

local client = {}
local server = {}

client.startup = micro.."STARTUP"
client.reboot = micro.."REBOOT"
client.pong = micro.."PONG"
client.distress = micro.."DISTRESS"
client.diminshed = micro.."DIMINISHED"
client.needs_setup = micro.."NEEDS_SETUP"
client.setup_done = micro.."SETUP_DONE"
client.scrammed = micro.."SCRAMMED"


function server.setupdata(address, data) event.push(serv.."SETUPDATA/"..address, data) end

function server.startupreceived(address) event.push(serv.."RECEIVED/"..address) end

function server.idle(address) event.push(serv.."IDLE/"..address) end

function server.ping() event.push(serv.."PING") end

function server.scram() event.push(serv.."SCRAM") end

function server.activate(address) event.push(serv.."ACTIVATE/"..address) end

function server.deactivate(address) event.push(serv.."DEACTIVATE/"..address) end

return client, server