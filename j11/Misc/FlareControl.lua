TOTAL_FLARE_COUNT = property.getNumber("Total Flares")
currentFlares = TOTAL_FLARE_COUNT

function onTick()
    if input.getBool(1) then
        currentFlares = currentFlares - 1
    end
    local lightCount = math.ceil(currentFlares * 8 / TOTAL_FLARE_COUNT)
    for i = 1, 8, 1 do
        output.setBool(i, i <= lightCount)
    end
end
