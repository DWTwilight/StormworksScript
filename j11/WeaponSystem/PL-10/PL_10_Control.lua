IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

-- status
STATUS = {
    REQUIRE_TARGET = 0,
    READY = 1,
    LAUCHING = 2,
    READY_TO_DETACH = 3
}

CURRENT_STATUS = STATUS.REQUIRE_TARGET

function onTick()
    if CURRENT_STATUS == 0 then
        -- initial status
        -- check if is selected weapon
    end
end
