local gt = "gregtech:gt."
local sides = require("sides")

return {
    REACTOR = {
        SIDE = sides.bottom
    },

    INTERFACE = {
        SIDE = sides.top,
        COOLANT = {
            RANGE = 4,
            OFFSET = 1
        }
    },

    COOLANT = {
        HELIUM = gt.."360k_Helium_Coolantcell",
        NAK = gt.."360k_NaK_Coolantcell",
        SMALL_SP = gt.."540k_Space_Coolantcell",
        LARGE_SP = gt.."1080k_Space_Coolantcell"
    },

    ROD = {
        GLOWSTONE = gt.."rodGlowstone",
        URANIUM = gt.."rodUranium4",
        MOX = gt.."rodMOX4",
        HD_URANIUM = gt.."rodHighDensityUranium4",
        EXCITED_URANIUM = gt.."rodExcitedUranium4",
        HD_PLUTONIUM = gt.."rodHighDensityPlutonium4"
    }
}