------------------------------------------------------------------------
-----LOGGING

return {
    info = function(m)
      print("[INFO] ".. m)
    end,
    
    warn = function(m)
      print("[WARN] ".. m)
    end,
    
    error = function(m)
      print("[ERROR] ".. m)
    end,
    
    verbose = function(m)
      local caller = debug.getinfo(3,"n")
      print("[V-INFO] |"..caller.name.. "| "..m)
    end,
    
    split = function()
      print("------------")
    end,
    
    longSplit = function()
        print("---------------------------------")
    end,
    
    beautify = function(m)
        print("#  ".. m)
    end
}