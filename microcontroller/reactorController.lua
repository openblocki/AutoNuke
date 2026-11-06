-- =================COPYRIGHT NOTICE================
-- This is a Modified version of Edeiwen's EEPROM script
-- => @Edeiwen found on the Official GTNH Discord Server in #"2.9 OC Vacuum Reactors Microcontroller" Thread in #tips-and-ticks
-- =================================================
local component     = require("component")
local fs            = require("filesystem")
local serialize     = require("serialization")
local t             = component.proxy(component.list("transposer")())
local computer      = require("computer")

local gt            = "gregtech:gt."

-- ===================== CONFIG =====================
-- 0=Down, 1=Top, 2=North, 3=South, 4=West, 5=East
local sideInterface = 1
local sideNuke      = 0

local maxDamage     = 80

local indexCoolant  = 2
local indexFuel     = 1

local coolant       = gt .. "360k_Helium_Coolantcell"
local depleted      = gt .. "depletedRodUranium4"

local sleepTime     = 1

local address       = computer.address()
local rIO           = nil -- Allows the MicroController to shut down its own RedstoneIO in case of Distress

local isActive      = false

local signal        = {
    STARTUP = "AN/MICROCONTROLLER/STARTUP",
    REBOOT = "AN/MICROCONTROLLER/REBOOT",
    PONG = "AN/MICROCONTROLLER/PONG",
    DISTRESS = "AN/MICROCONTROLLER/DISTRESS",
    DIMINISHED = "AU/MICROCONTROLLER/DIMINISHED",
    NEEDS_SETUP = "AU/MICROCONTROLLER/NEEDS_SETUP",
    SETUP_DONE = "AU/MICROCONTROLLER/SETUP_DONE"
}

-- ==================================================


local function deactivate()
    isActive = false
    computer.pushSignal(signal.DISTRESS, address)
    rIO.setOutput(1, 0)
    rIO.setOutput(0, 0)
end


local function writeToFile(path, data)
    local file, err = fs.open(path, "w")
    if not file then
        print("ERROR: NOT ABLE TO CREATE / OPEN FILE")
        deactivate()
        error("File Error", err)

        return
    end

    file:write(data)
    file:close()
end

local function activate()
    isActive = true
end


local function swapCoolant(slot)
    local counter = 0

    repeat
        local success = t.swap(sideInterface, sideNuke, indexCoolant, slot, true)
        if not success then counter = counter + 1 end
        if counter > 2 then
            deactivate()
            return -1
        end
        computer.pullSignal(0.1)
    until success
end

local function swapFuelRod(slot)
    local counter = 0
    repeat
        local success = t.swap(sideInterface, sideNuke, indexFuel, slot, true)
        if not success then counter = counter + 1 end
        if counter > 2 then computer.pushSignal(signal.DIMINISHED, address) end -- When a Controller is Diminished, Server waits for 2 PONGS until
        if counter > 5 then break end
        computer.pullSignal(0.1)
    until success
end

local function getReactorLayout(C, R)
    return { C, R, R, R, C, R, R, C, R,
        R, R, C, R, R, R, R, C, R,
        C, R, R, R, R, C, R, R, R,
        R, R, R, C, R, R, R, R, C,
        R, C, R, R, R, R, C, R, R,
        R, C, R, R, C, R, R, R, C }
end

local function fillReactor(cool, rod)
    ::setupReactor::
    local inventory = t.getAllStacks(sideNuke)
    local successfull_finish = true
    local slot = 1
    local layout = getReactorLayout(cool, rod)

    for item in inventory do
        if item and item.name ~= layout[slot] then
            successfull_finish = false

            if not item.name then
                item.name = "Empty"
            end

            if item.name == coolant then
                if swapCoolant(slot) then
                    deactivate()
                    error("COULD NOT SUCCESSFULLY SWAP COOLANT")
                end
            else
                swapFuelRod(slot)
            end
        end
        slot = slot + 1
    end
    if not successfull_finish then
        goto setupReactor
    end
end

local function setup()
    computer.pushSignal(signal.NEEDS_SETUP, address)
    local setup_data = { state = false }
    repeat
        local name, data = computer.pullSignal()
        if name == "AU/SERVER/SETUPDATA/" .. address then
            setup_data = data
            setup_data.state = true
        end
    until setup_data.state

    rIO = component.proxy(setup_data.redstoneIO_a)

    if not rIO then computer.pushSignal(signal.DISTRESS) end

    coolant = t.getStackInSlot(1, indexCoolant).name or coolant
    local rod = t.getStackInSlot(1, indexFuel).name or gt .. "rodUranium4"

    depleted = gt .. "depletedR" .. string.sub(rod, string.len(gt) + 1, string.len(rod))

    local data = {
        rIO_Address = setup_data.redstoneIO_a,
        coolant = coolant,
        depleted = depleted
    }

    writeToFile("cache", serialize.serialize(data))

    fillReactor(coolant, rod)

    print("Setup done")
    isActive = true
end

local function SCRAM()
    deactivate()
end

local function tickReactor()
    while isActive do
        local itemsInNuke = t.getAllStacks(sideNuke)

        for slot, item in ipairs(itemsInNuke) do
            if not item then SCRAM() end
            if item.name == coolant and item.damage >= maxDamage then
                local result = swapCoolant(slot)
                if result then return end
            elseif item.name == depleted then
                swapFuelRod(slot)
            end
        end

        computer.pushSignal(signal.PONG, address)
        computer.pullSignal(sleepTime)
    end
end



local function main()
    computer.pushSignal(signal.STARTUP, address)

    if fs.exists("cache") then
        local cache = nil
        local cache_file = io.open("cache", "r")
        if cache_file then
            local data = cache_file:read("*a")
            cache_file:close()
            cache = serialize.unserialize(data)
            rIO = component.proxy(cache.rIO_Address)
            coolant = cache.coolant
            depleted = cache.depleted
        end
    else
        local _, error = pcall(setup)
        if error then
            SCRAM()
            return
        end
        computer.pushSignal(signal.SETUP_DONE, address)
    end

    local _, error = pcall(tickReactor)
    if error then
        writeToFile("latest.log", error)
    end

    computer.pushSignal(signal.REBOOT, address)
    computer.shutDown(true) -- Try to Reboot by itself
end

main()
deactivate()
computer.beep("...---...") -- Give a Hearable Signal its Rebooting
computer.shutDown(true)    -- Try to Reboot by itself
