IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber
PB = property.getBool

function convertGuideMethods(hud, radar, map, eots)
    local val = 0
    if hud then
        val = val + 1
    end
    val = val << 1
    if radar then
        val = val + 1
    end
    val = val << 1
    if map then
        val = val + 1
    end
    val = val << 1
    if eots then
        val = val + 1
    end
    -- reserved
    val = val << 4
    return val
end

function covertFirstMetadataNumber(defaultGuide, guideMethodNum, type, wid)
    return defaultGuide << 20 | guideMethodNum << 12 | type << 8 | wid
end

function convertSecondMetadataNumber(status, ammoCount)
    return status << 12 | ammoCount
end

-- id on vehicle
VID = PN("Id on Vehicle")
--weapon id
WID = PN("Weapon Id")
-- guide method(s)
GUIDE_HUD = PB("Guide by HUD")
GUIDE_RADAR = PB("Guide by Radar")
GUIDE_MAP = PB("Guide by Map")
GUIDE_EOTS = PB("Guide by EOTS")
GUIDE_VAL = convertGuideMethods(GUIDE_HUD, GUIDE_RADAR, GUIDE_MAP, GUIDE_EOTS)
-- weapon type
TYPE = PN("Weapon Type")
-- default guide method
GUIDE_DEFAULT = PN("Default guide method")
-- number 1
META_NUM_1 = covertFirstMetadataNumber(GUIDE_DEFAULT, GUIDE_VAL, TYPE, WID)

-- status
STATUS = {
    REQUIRE_TARGET = 0,
    READY = 1,
    LAUCHING = 2,
    READY_TO_DETACH = 3
}

function onTick()
    ON(1, META_NUM_1)
    -- status logic should vary
    ON(2, convertSecondMetadataNumber(STATUS.READY, IN(1)))
end
