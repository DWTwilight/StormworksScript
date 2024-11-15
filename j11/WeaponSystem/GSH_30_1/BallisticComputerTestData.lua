-- Machine Gun
-- Muzzle velocity (m/s): 800
-- Drag Coefficient: ?
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 300
-- Despawn Speed (m/s): 50

-- Light Autocannon
-- Muzzle velocity (m/s): 1000
-- Drag Coefficient: 0.02
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 300
-- Despawn Speed (m/s): 50

-- Rotary Autocannon
-- Muzzle velocity (m/s): 1000
-- Drag Coefficient: 0.01
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 300
-- Despawn Speed (m/s): 50

-- Heavy Autocannon
-- Muzzle velocity (m/s): 900
-- Drag Coefficient: 0.005
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 600
-- Despawn Speed (m/s): 50

-- Battle Cannon
-- Muzzle velocity (m/s): 800m
-- Drag Coefficient: 0.002
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 3600
-- Despawn Speed (m/s): N/A (50m/s underwater)

-- Artillery Cannon
-- Muzzle velocity (m/s): 700
-- Drag Coefficient: 0.001
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 3600
-- Despawn Speed (m/s): N/A (50m/s underwater)

-- Big Bertha Cannon
-- Muzzle velocity (m/s): 600
-- Drag Coefficient: 0.0005
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 3600
-- Despawn Speed (m/s): N/A (50m/s underwater)
-- Rocket Launcher
-- Muzzle velocity (m/s): ? (This guy accelerates for a certain amount of time)
-- Drag Coefficient: 0.003
-- Gravity: 30 m/s^2, 0.5m/s/t
-- Despawn Timer (ticks): 3600
-- Despawn Speed (m/s): N/A (50m/s underwater)
-- - Larger caliber projectiles receive proportionally less force from the wind

input = {
    getNumber = function(i)
        local data = {
            0, 0, 0,    -- self v
            0, 0, 0,    -- self pos
            0, 0, 1000, -- target pos
            0, 0, 0,    -- target v
            0, 0,       -- windSpeedX, windSpeedZ
            0, 0, 0     -- self rotation
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
            ["[BC]Drag Coefficient"] = 0.01,
            ["[BC]Muzzel Velocity"] = 1000,
            ["[BC]Gravity"] = 30,
            ["[BC]Precision"] = 0.0001,
            ["[BC]Max Iterations"] = 40,
            ["[BC]Max Tick"] = 300,
            ["[BC]Target Delay Compensation"] = 0,
            ["[BC]Self Delay Compensation"] = 0
        }
        return data[key]
    end
}
