print("Installing AutoNuke")

local internet = require("internet")
local fs = require("filesystem")

local url = "https://github.com/openblocki/NukeManager/"

local home = "/home/"
local libs = "reactor-libs/"
local filesTD = {
    "AutoNuke.lua",
    libs .. "db.lua",
    libs .. "log.lua",
    libs .. "lsc-manager.lua",
    libs .. "reactor-layout.lua",
    libs .. "reactor.lua",
    libs .. "reactor_conf.lua",
    libs .. "term-helper.lua",
}

fs.makeDirectory(home .. libs)
fs.makeDirectory("/database/")
fs.makeDirectory("/database/config/")
fs.makeDirectory("/database/reactors/")

local function downloadFile(path)
    local file = io.open(path, "w")
    if not file then
        error("COULD NOT CREATE FILE " .. path)
    end

    print("Installing " .. path)

    local sContent = ""
    local result, response = pcall(internet.request, url .. path)
    if not result then
        return nil
    end
    
    for chunk in response do
        sContent = sContent .. chunk
    end


    file:write(sContent)

    file:close()
end

for _, file in ipairs(filesTD) do
    local savePath = home .. file

    print("DOWNLOADING " .. file)

    local success, err = downloadFile(file)

    if success then
        print("SUCCESS")
    else
        print("FAILED")
    end
end

print("DONE")
