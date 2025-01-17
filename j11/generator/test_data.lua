input = {
    getNumber = function(i)
        local data = { 3, -- engine L RPS
            3             -- engine R RPS
        }
        return data[i]
    end,
    getBool = function(i)
        local data = { true, true } -- process pulse
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
            ["Generator Min RPS"] = 10,
            ["Gearbox Count"] = 3,
            ["GBR_1_OFF"] = 1,
            ["GBR_1_ON"] = 2,
            ["GBR_2_OFF"] = 1,
            ["GBR_2_ON"] = 3,
            ["GBR_3_OFF"] = 1,
            ["GBR_3_ON"] = 3
        }
        return data[key]
    end
}
