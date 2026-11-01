local log = require("log")


local function tick()

end

local function setup()

    return 1
end

local function needsPower()
end

return {
    tick = tick,
    setup = setup,
    needsPower = needsPower
}