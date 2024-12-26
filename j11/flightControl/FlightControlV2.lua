M = math
MIN = M.min
MAX = M.max
ABS = M.abs
RAD = M.rad
PI = M.pi
PI2 = 2 * PI
COS = M.cos
SIN = M.sin

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

AP_MAX_PITCH_SPEED = PN("AP Max Pitch Speed")
AP_MAX_PITCH = PN("AP Max Pitch")
AP_THROTTLE_SENSITIVITY = PN("AP Throttle Sensitivity")
AP_THROTTLE_FACTOR = PN("AP Throttle Factor")
AP_THROTTLE_PRECISION = PN("AP Throttle Precision")
AP_PITCH_FACTOR = PN("AP Pitch Factor") -- less -> more sensitive, likely to overshoot
AP_ROLL_SENS = PN("AP Roll Sensitivity")
AP_PITCH_SENS = PN("AP Pitch Sensitivity")
AP_YAW_SENS = PN("AP Yaw Sensitivity")
AP_SMOOTH_FACTOR = PN("AP Smooth Factor")

-- current status
ROLL_CTRL, PITCH_CTRL, YAW_CTRL, THROTTLE = 0, 0, 0, 0
-- trim
ROLL_TRIM, PITCH_TRIM, YAW_TRIM = 0, 0, 0
RTC, PTC, YTC = TRIM_DELAY, TRIM_DELAY, TRIM_DELAY
-- AP status 
APC = TRIM_DELAY

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

function trim(value, trim)
    return value * (1 - ABS(trim)) + trim
end

function lerp(target, current, gain)
    return current + gain * (target - current)
end

function calRadDiff(t, v)
    local diff = t - v
    if diff > PI then
        diff = diff - PI2
    elseif diff < -PI then
        diff = diff + PI2
    end
    return diff
end

function convertWithRoll(pitchSpeed, yawSpeed, roll)
    return COS(roll) * pitchSpeed + SIN(roll) * yawSpeed, -SIN(roll) * pitchSpeed + COS(roll) * yawSpeed
end

function onTick()
    -- control inputs
    local rollMInput, pitchMInput, yawMInput, throttleMInput = IN(1), IN(2), IN(3), IN(4)
    local landed, airBreak = IB(1), IB(2)
    local throttleUpM, throttleDownM = IB(3), IB(4)
    local manualThrottleControl = throttleUpM or throttleDownM
    local manualControl = ABS(rollMInput) > 0 or ABS(pitchMInput) > 0 or ABS(yawMInput) > 0 or airBreak or
                              manualThrottleControl

    if landed then
        -- landed
        APC = TRIM_DELAY
        RTC, PTC, YTC = TRIM_DELAY, TRIM_DELAY, TRIM_DELAY
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
        local autoPilot = IB(5)
        if autoPilot and not manualControl and APC < 0 then
            -- ap
            RTC, PTC, YTC = TRIM_DELAY, TRIM_DELAY, TRIM_DELAY
            -- auto pilot on and not manual control
            local roll, pitch, yaw = IN(10), IN(11), IN(12)

            local altTarget, speedTarget, yawTarget = IN(13), IN(14) / 3.6, RAD(IN(15))
            if IB(6) and IN(17) ~= -1 then
                -- fly to waypoint 
                yawTarget = IN(16)
            end
            if yawTarget > PI then
                yawTarget = yawTarget - PI2
            end

            -- cal pitch target
            local pitchTarget = clamp(AP_MAX_PITCH * ((altTarget - altitude) / AP_PITCH_FACTOR), -AP_MAX_PITCH,
                AP_MAX_PITCH)
            local pitchSpeed = clamp(AP_MAX_PITCH_SPEED * (calRadDiff(pitchTarget, pitch) / PI * 5),
                -AP_MAX_PITCH_SPEED, AP_MAX_PITCH_SPEED)

            -- update trim when possile 
            if ABS(curPitchAs) < TRIM_ZONE then
                PITCH_TRIM = PITCH_CTRL
            end
            if ABS(curRollAs) < TRIM_ZONE then
                ROLL_TRIM = ROLL_CTRL
            end
            if ABS(curYawAs) < TRIM_ZONE then
                YAW_TRIM = YAW_CTRL
            end

            -- update controls 
            ROLL_CTRL = lerp(clamp(-roll * factor * AP_ROLL_SENS, -0.5, 0.5), ROLL_CTRL, AP_SMOOTH_FACTOR)
            PITCH_CTRL = clamp(PITCH_CTRL + (pitchSpeed - curPitchAs) * factor * AP_PITCH_SENS, -0.5, 0.5)
            YAW_CTRL = lerp(clamp(calRadDiff(yawTarget, yaw) * factor * AP_YAW_SENS, -0.5, 0.5), YAW_CTRL,
                AP_SMOOTH_FACTOR)

            -- auto throttle
            if manualThrottleControl then
                THROTTLE = throttleMInput
                OB(1, throttleUpM)
                OB(2, throttleDownM)
            else
                THROTTLE = clamp(THROTTLE +
                                     clamp((speedTarget - speed) / AP_THROTTLE_FACTOR, -AP_THROTTLE_SENSITIVITY,
                        AP_THROTTLE_SENSITIVITY), 0, 1)
                OB(1, THROTTLE - throttleMInput > AP_THROTTLE_PRECISION)
                OB(2, throttleMInput - THROTTLE > AP_THROTTLE_PRECISION)
            end
        else
            -- manualControl or AP delay 
            if autoPilot and not manualControl then
                APC = APC - 1
            else
                APC = TRIM_DELAY
            end
            -- recalculate trim values
            if not airBreak then
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
    if airBreak and not landed then
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
