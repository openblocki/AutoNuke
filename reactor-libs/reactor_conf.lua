local gt = "gregtech:gt."
local sides = require("sides")

return {
    CONFIG = {
        ID = "wb54z6"
    },

    REACTOR = {
        SIDE = sides.bottom,
        HEAT = { -- Max Values are Technicaly 1, but at that Point Reactors will most likely Detonate
            THRESHOLD = 0.5, -- Heat Percentage at which the Reactor Scrams. [0~1] Default: 0.5
            THRESHOLD_MOX = 0.95, -- Heat Percentage at which the Reactor Scrams for MOX behaving Fuels. [0~1] Default: 0.95
            WARMUP_MOX = 0.9 -- Heat Percentage the Reactor warms up to when its Fuel has MOX behaviour [0~1] Default: 0.9
        }
    },

    REDSTONEIO = {
        SIDE = sides.top,
        SIDE_EXTRA = sides.bottom
    },

    LSC = {
        POWERMIN = 0.6, -- When Reactors get Turned on. [0~1] Default: 0.6
        POWERMAX = 0.8  -- When Reactors get Turned off. [0~1] Default: 0.8
    },

    INTERFACE = { -- Key Values: DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
        SIDE = sides.top,
        COOLANT = {
            RANGE = 4, -- How many Cells are in the Interface. [1~7] Default: 4
            OFFSET = 1 -- When the Cells start in the Interface. [1~8] Default: 1
        }
    },

    COOLANT = { --Coolant Cells
        HELIUM = gt.."360k_Helium_Coolantcell",
        NAK = gt.."360k_NaK_Coolantcell",
        SMALL_SP = gt.."540k_Space_Coolantcell",
        LARGE_SP = gt.."1080k_Space_Coolantcell"
    },

    COOLANT_ITEM = {
        HEAT_THRESHOLD = 0.85 -- Damage Percentage when Coolant gets swapped for a new Cell. [0~1] Default: 0.85
    },

    ROD = { -- Fuel Rods
        GLOWSTONE = gt.."rodGlowstone",
        URANIUM = gt.."rodUranium4",
        MOX = gt.."rodMOX4",
        HD_URANIUM = gt.."rodHighDensityUranium4",
        EXCITED_URANIUM = gt.."rodExcitedUranium4",
        HD_PLUTONIUM = gt.."rodHighDensityPlutonium4"
    },

    MOX_BEHAVIOUR = {
        MOX = true,
        HD_PLUTONIUM = true,
        EXCITED_PLUTONIUM = true, -- Not Supported by Default Config
        NAQUADRIA = true -- Not Supported by Default Config
    },

    DEPLETED_ROD = { -- Depleted Versions of the Fuel Rods
        GLOWSTONE = gt.."rodSunnarium",
        URANIUM = gt.."depletedRodUranium4",
        MOX = gt.."depletedRodMOX4",
        HD_URANIUM = gt.."depletedRodHighDensityUranium4",
        EXCITED_URANIUM = gt.."depletedRodExcitedUranium4",
        HD_PLUTONIUM = gt.."depletedRodHighDensityPlutonium4"
    },

    DEFAULT = { -- Key Values: DO NOT CHANGE
        COOLANT = "HELIUM",
        ROD = "URANIUM"
    },

    WORD = { -- Key Values: DO NOT CHANGE
        COOLANT = "COOLANT",
        ROD = "ROD",
    }
}