print("Installing AutoNuke")

local internet = require("internet")
local fs = require("filesystem")

local url = "https://github.com/openblocki/NukeManager"

local home = "/home/"
local libs = "reactor-libs/"
local filesTD = {
    "AutoNuke.lua",
    libs.."db.lua",
    libs.."log.lua",
    libs.."lsc-manager.lua",
    libs.."reactor-layout.lua",
    libs.."reactor.lua",
    libs.."reactor_conf.lua",
    libs.."term-helper.lua",
}

fs.makeDir(home..libs)
fs.makeDir("/database/")
fs.makeDir("/database/config/")
fs.makeDir("/database/reactors/")

local function downloadFile(path)
    local file = io.open(path, "w")
    if not file then 
        error("COULD NOT CREATE FILE "..path)
    end

    local success, response = pcall(internet.request(), url..path)

    if success and response then
        for chunk in response do
            file:write(chunk)
        end

        file:close()
        return true
    else 
        file:close()
        return false, tostring(response)
    end
end

for _, file in pairs(filesTD) do
    local savePath = home..file

    print("DOWNLOADING " .. file)

    local success, err = downloadFile(file)
    
    if success then
        print("SUCCESS")
    else
        print("FAILED")
    end
end

print("DONE")