local c = require("reactor-libs.reactor_conf")
local type = {
    C = c.WORD.COOLANT,
    R = c.WORD.ROD
}

local layout ={ "C", "R", "R", "R", "C", "R", "R", "C", "R",
                "R", "R", "C", "R", "R", "R", "R", "C", "R",
                "C", "R", "R", "R", "R", "C", "R", "R", "R",
                "R", "R", "R", "C", "R", "R", "R", "R", "C",
                "R", "C", "R", "R", "R", "R", "C", "R", "R",
                "R", "C", "R", "R", "C", "R", "R", "R", "C" }


local function getTypeForSlot(slot)
    return type[layout[slot]]
end

local function getCoolantSlots()
    return {1,5,8,12,17,19,24,31,36,38,43,47,50,54}
end

local function getRodSlots()
    return {2,3,4,6,7,9,10,11,13,14,15,16,18,20,21,22,23,25,26,27,28,29,30,32,33,34,35,37,39,40,41,42,44,45,46,48,49,51,52,53}
end

return { layout = layout, getTypeForSlot = getTypeForSlot , getCoolantSlots = getCoolantSlots, getRodSlots = getRodSlots}