local log = require("reactor-libs.log")
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

        return optionKeys[userInput]
    end,

    multiSelectNoDefault = function (label, options)
                log.longSplit()
        log.beautify("Please Select ".. label)

        ::selector::
        for k, v in pairs(options) do
            log.beautify(k..". "..v)
        end
        log.beautify("No Default")

        local userInput = io.read()
        userInput = tonumber(userInput)
        
        if userInput == nil then
            log.beautify("No Input. Try Again.")
            goto selector
        end

        if userInput <= 0 or userInput > #options then
            log.beautify("Input Out of Bounds. Try Again.")
            goto selector
        end

        log.longSplit()

        return options[userInput], userInput
    end

}