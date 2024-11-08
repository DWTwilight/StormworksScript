IN = input.getNumber
IB = input.getBool
ON = output.setNumber

PN = property.getNumber

function calAirPressureFactor(airPressure)
    return 3.58507 * airPressure ^ 3 - 6.83825 * airPressure ^ 2 + 4.07352 * airPressure + 0.20575
end

RAW = {} -- array of [speed, trim]
INIT_FLAG = true
DATA = {}
SAMPLE_SLOT = PN("Sameple Slot")
TRANSITION_RATE = PN("Transition Rate")

function onTick()
    if INIT_FLAG then
        for _, d in ipairs(RAW) do
            DATA[d[0] // SAMPLE_SLOT] = { d[0], d[1] }
        end
        INIT_FLAG = false
    end

    local speed, airPressure = IN(1), IN(2)
    local apf = calAirPressureFactor(airPressure)
    local index = speed // SAMPLE_SLOT

    if IB(1) then
        -- sample current trim
        local pitch = IN(3) / apf
        if math.abs(pitch) < 0.7 then
            if DATA[index] ~= nil then
                DATA[index] = {
                    (1 - TRANSITION_RATE) * DATA[index][0] + TRANSITION_RATE * speed,
                    (1 - TRANSITION_RATE) * DATA[index][1] + pitch * TRANSITION_RATE }
            else
                DATA[index] = { speed, pitch }
            end
        end
    end

    -- calculate current trim base
    local ld, rd = nil, nil
    for _, data in pairs(DATA) do
        if data[0] <= speed then
            if ld == nil then
                ld = data
            elseif data[0] > ld[0] then
                ld = data
            end
        else
            if rd == nil then
                rd = data
            elseif data[0] < rd[0] then
                rd = data
            end
        end
    end

    if ld == nil and rd == nil then
        ON(1, 0)
    elseif ld == nil then
        ON(1, rd[1] * apf)
    elseif rd == nil then
        ON(1, ld[1] * apf)
    else
        ON(1, (ld[1] + (speed - ld[0]) * (rd[1] - ld[1]) / (rd[0] - ld[0])) * apf)
    end
end
