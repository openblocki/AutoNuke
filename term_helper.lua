local log = require("log")
return {
    multiSelect = function (label, options, defaultKey, defaultValue)
        

        local optionKeys = {}

        for key in pairs(options) do
            optionKeys[#optionKeys + 1] = key
        end

        log.longSplit()
        log.beautify("Please Select ".. label)

        
        for k, v in pairs(optionKeys) do
            log.beautify(k..". "..v)
        end
        log.beautify("Default: ".. defaultKey)

        local userInput = io.read()
        userInput = tonumber(userInput)
        
        if userInput == nil or userInput == 0 then
            return defaultValue
        end

        if userInput < 0 or userInput > #optionKeys then
            log.beautify("Input Out of Bounds. Selecting Default.")
            return defaultValue
        end

        log.longSplit() 

        return options[optionKeys[userInput]]
    end

}