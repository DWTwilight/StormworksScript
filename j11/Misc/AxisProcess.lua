m = math
abs = m.abs
IN = input.getNumber
ON = output.setNumber
DEAD_ZONE = property.getNumber("Dead Zone")
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

function onTick()
    ON(1, processInput(IN(1)))
    ON(2, processInput(IN(2)))
    ON(3, processInput((IN(5) - IN(6)) * 0.5))

    ON(4, processInput(IN(3)))
    ON(5, processInput(IN(4)))
end
