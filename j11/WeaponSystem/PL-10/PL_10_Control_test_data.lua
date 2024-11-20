input = {
    getNumber = function(i)
        local data = {
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0,
            0, 0, 0,   -- self pos
            0, 0, 500, -- self v
            0, 0, 0    -- self rotation
        }
        return data[i]
    end,
    getBool = function(i)
        local data = { true, true }
        return data[i]
    end
}
output = {
    setNumber = function(i, num)
        print(string.format("set num#%d: %f", i, num))
    end,
    setBool = function(i, val)
        print(string.format("set bool#%d: %s", i, tostring(val)))
    end
}
property = {
    getNumber = function(key)
        local data = {
            ["Tick per Sec"] = 60,
            ["Target Delay Compensation"] = 0,
            ["Self Delay Compensation"] = 0
        }
        return data[key]
    end
}
