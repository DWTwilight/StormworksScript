M = math
MIN = M.min
MAX = M.max
ABS = M.abs

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

SPEED_SQRT_FACTOR = PN("Speed Factor")
ALTITUDE_FACTOR = PN("Altitude Factor")

TRIM_ZONE = PN("Trim Zone")
TRIM_DELAY = PN("Trim Delay")
TRIM_ROLL_SENS = PN("Roll Trim Sensitivity")
TRIM_PITCH_SENS = PN("Pitch Trim Sensitivity")
TRIM_YAW_SENS = PN("Yaw Trim Sensitivity")

AP_MAX_ROLL_SPEED = PN("AP Max Roll Speed")
AP_MAX_PITCH_SPEED = PN("AP Max Pitch Speed")
AP_MAX_YAW_SPEED = PN("AP Max Yaw Speed")
AP_MAX_ROLL = PN("AP Max Roll")
AP_MAX_PITCH = PN("AP Max Pitch")
AP_THROTTLE_SENSITIVITY = PN("AP Throttle Sensitivity")
AP_THROTTLE_FACTOR = PN("AP Throttle Factor")
AP_THROTTLE_PRECISION = PN("AP Throttle Precision")

-- less -> more sensitive, likly to overshoot
AP_PITCH_FACTOR = 2000
AP_YAW_FACTOR = 0.5

-- current status
AIR_BREAK = false
ROLL_CTRL, PITCH_CTRL, YAW_CTRL, THROTTLE = 0, 0, 0, 0
-- trim
ROLL_TRIM, PITCH_TRIM, YAW_TRIM = 0, 0, 0
RTC, PTC, YTC = TRIM_DELAY, TRIM_DELAY, TRIM_DELAY

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

function trim(value, trim)
    return value * (1 - ABS(trim)) + trim
end

function onTick()
    -- control inputs
    local rollMInput, pitchMInput, yawMInput, throttleMInput = IN(1), IN(2), IN(3), IN(4)
    AIR_BREAK = IB(2)
    local throttleUpM, throttleDownM = IB(3), IB(4)
    local manualControl =
        ABS(rollMInput) > 0 or ABS(pitchMInput) > 0 or ABS(yawMInput) > 0 or AIR_BREAK or throttleUpM or throttleDownM

    if IB(1) then
        -- reset trim values
        ROLL_TRIM, PITCH_TRIM, YAW_TRIM = 0, 0, 0
        -- set outputs
        -- landed, use primitive inputs
        ROLL_CTRL, PITCH_CTRL, YAW_CTRL = rollMInput, pitchMInput, yawMInput
        -- throttle control 
        THROTTLE = throttleMInput
        OB(1, throttleUpM)
        OB(2, throttleDownM)
    else
        -- airborn
        local speed, altitude = IN(5), IN(6)
        local factor = MAX(ALTITUDE_FACTOR, altitude ^ 0.5) / ALTITUDE_FACTOR *
                           (SPEED_SQRT_FACTOR / MAX(ABS(speed) ^ 0.5, SPEED_SQRT_FACTOR))
        local curRollAs, curPitchAs, curYawAs = IN(7), IN(8), IN(9)
        local targetRollSpeed, targetPitchSpeed, targetYawSpeed = 0, 0, 0
        if IB(5) and not manualControl then
            -- ap
        else
            -- manualControl
            -- recalculate trim values
            if not AIR_BREAK then
                if rollMInput == 0 or rollMInput * curRollAs < 0 then
                    if RTC < 0 then
                        ROLL_TRIM = clamp(ROLL_TRIM - curRollAs * factor * TRIM_ROLL_SENS, -0.1, 0.1)
                    else
                        RTC = RTC - 1
                    end
                else
                    RTC = TRIM_DELAY
                end

                if pitchMInput == 0 or pitchMInput * curPitchAs < 0 then
                    if PTC < 0 then
                        PITCH_TRIM = clamp(PITCH_TRIM - curPitchAs * factor * TRIM_PITCH_SENS, -0.8, 0.8)
                    else
                        PTC = PTC - 1
                    end
                else
                    PTC = TRIM_DELAY
                end

                if yawMInput == 0 or yawMInput * curYawAs < 0 then
                    if YTC < 0 then
                        YAW_TRIM = clamp(YAW_TRIM - curYawAs * factor * TRIM_YAW_SENS, -0.1, 0.1)
                    else
                        YTC = YTC - 1
                    end
                else
                    YTC = TRIM_DELAY
                end
            else
                RTC, PTC, YTC = TRIM_DELAY, TRIM_DELAY, TRIM_DELAY
            end
            -- set outputs
            -- manual control, use trimed inputs
            ROLL_CTRL, PITCH_CTRL, YAW_CTRL = trim(rollMInput, ROLL_TRIM), trim(pitchMInput, PITCH_TRIM),
                trim(yawMInput, YAW_TRIM)
            -- throttle control 
            THROTTLE = throttleMInput
            OB(1, throttleUpM)
            OB(2, throttleDownM)
        end
    end

    -- set control outputs
    ON(1, ROLL_CTRL)
    ON(2, PITCH_CTRL)
    if AIR_BREAK then
        ON(3, 1)
        ON(4, 1)
    else
        ON(3, YAW_CTRL)
        ON(4, -YAW_CTRL)
    end
    ON(5, 0.15 * (PITCH_CTRL - ROLL_CTRL))
    ON(6, 0.15 * (PITCH_CTRL + ROLL_CTRL))
    ON(7, THROTTLE)
end
