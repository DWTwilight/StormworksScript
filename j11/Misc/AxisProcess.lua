m = math
abs = m.abs
IN = input.getNumber
ON = output.setNumber
DEAD_ZONE = property.getNumber("Dead Zone")
SMOOTH_FACTOR = property.getNumber("Smooth Factor")
INPUT_FACTOR = 1 / (1 - DEAD_ZONE)

function processInput(I)
    if abs(I) < DEAD_ZONE then
        I = 0
    elseif I > 0 then
        I = (I - DEAD_ZONE) * INPUT_FACTOR
    else
        I = (I + DEAD_ZONE) * INPUT_FACTOR
    end
    return I
end

function lerp(target, value, gain)
    return value + (target - value) * gain
end

function clamp(value, min, max)
    return m.min(max, m.max(value, min))
end

roll, pitch, yaw = 0, 0, 0

function onTick()
    -- smooth roll, pitch, yaw
    roll = lerp(processInput(IN(1)), roll, SMOOTH_FACTOR)
    pitch = lerp(processInput(IN(2)), pitch, SMOOTH_FACTOR)
    yaw = lerp(clamp(processInput(clamp(IN(5), 0, 1)) - processInput(clamp(IN(6), 0, 1)), -1, 1), yaw, SMOOTH_FACTOR)
    ON(1, roll)
    ON(2, pitch)
    ON(3, yaw)

    ON(4, processInput(IN(3)))
    ON(5, processInput(IN(4)))
end
