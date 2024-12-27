IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber

ALT_THRS = PN("Altitude Alert Threshold")
ALT_IMP_THRS = PN("Altitude Impact Alert Threshold")
STALL_THRS = PN("Stall Speed Threshold")
FUEL_THRS = PN("Fuel Alert Threshold")

ALERT = {
    NONE = 0,
    FUEL = 1,
    ALTITUDE = 2,
    STALL = 3,
    ENGINE_FAILURE = 4,
    RADAR = 5,
    MISSILE = 6
}
ALERT_COUNT = 6
CUR_ALERT = ALERT.NONE

function onTick()
    if IB(1) then
        -- mute alert
        CUR_ALERT = ALERT.NONE
    else
        if IB(2) then
            CUR_ALERT = ALERT.MISSILE
        elseif IB(3) then
            CUR_ALERT = ALERT.RADAR
        elseif IB(4) then
            CUR_ALERT = ALERT.ENGINE_FAILURE
        elseif not IB(6) and IN(1) < STALL_THRS then
            -- airborn and not enough speed
            CUR_ALERT = ALERT.STALL
        elseif IB(5) and (IN(2) < ALT_THRS or IN(3) < IN(2) / -ALT_IMP_THRS) then
            -- gear up and check
            CUR_ALERT = ALERT.ALTITUDE
        elseif IN(4) < FUEL_THRS then
            CUR_ALERT = ALERT.FUEL
        else
            CUR_ALERT = ALERT.NONE
        end
    end

    ON(1, CUR_ALERT)
    for rank = 1, ALERT_COUNT do
        OB(rank, CUR_ALERT == rank)
    end
end
