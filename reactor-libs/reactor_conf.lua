local gt = "gregtech:gt."
local sides = require("sides")

return {
    CONFIG = {
        ID = "wb54z6"
    },

    REACTOR = {
        SIDE = sides.bottom,
        HEAT = {
            MAX = 10000, -- NOT ACTUAL VALUE YET
            THRESHOLD = 0.5,
            THRESHOLD_MOX = 0.95,
        }
    },

    REDSTONEIO = {
        SIDE = sides.top
    },

    LSC = {
        POWERMIN = 0.6,
        POWERMAX = 0.8
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

    COOLANT_ITEM = {
        HEAT_THRESHOLD = 0.85
    },

    ROD = {
        GLOWSTONE = gt.."rodGlowstone",
        URANIUM = gt.."rodUranium4",
        MOX = gt.."rodMOX4",
        HD_URANIUM = gt.."rodHighDensityUranium4",
        EXCITED_URANIUM = gt.."rodExcitedUranium4",
        HD_PLUTONIUM = gt.."rodHighDensityPlutonium4"
    },

    DEPLETED_ROD = {
        GLOWSTONE = gt.."rodSunnarium",
        URANIUM = gt.."depletedRodUranium4",
        MOX = gt.."depletedRodMOX4",
        HD_URANIUM = gt.."depletedRodHighDensityUranium4",
        EXCITED_URANIUM = gt.."depletedRodExcitedUranium4",
        HD_PLUTONIUM = gt.."depletedRodHighDensityPlutonium4"
    },

    DEFAULT = {
        COOLANT = "HELIUM",
        ROD = "URANIUM"
    },

    WORD = {
        COOLANT = "COOLANT",
        ROD = "ROD",
    }
}