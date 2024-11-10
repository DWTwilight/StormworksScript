m = math
abs = m.abs
IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

SPEED_SQRT_FACTOR = PN("Speed Factor")
ALTITUDE_FACTOR = PN("Altitude Factor")
TRIM_ZONE = PN("Trim Zone")

AP_MAX_ROLL_SPEED = PN("AP Max Roll Speed")
AP_MAX_PITCH_SPEED = PN("AP Max Pitch Speed")
AP_MAX_YAW_SPEED = PN("AP Max Yaw Speed")
AP_MAX_ROLL = PN("AP Max Roll")
AP_MAX_PITCH = PN("AP Max Pitch")
AP_THROTTLE_SENSITIVITY = PN("AP Throttle Sensitivity")
AP_THROTTLE_FACTOR = PN("AP Throttle Factor")
AP_THROTTLE_PRECISION = PN("AP Throttle Precision")

M_PITCH_TRIM_FACTOR = PN("Mannual Pitch Trim Factor")

-- less -> more sensitive, likly to overshoot
AP_PITCH_FACTOR = 2000
AP_YAW_FACTOR = 0.5

function clamp(value, min, max)
    return m.min(max, m.max(value, min))
end

function trim(value, trim)
    return value * (1 - abs(trim)) + trim
end

function setOutputs(roll, pitch, yaw)
    ON(1, roll)
    ON(2, pitch)
    ON(3, yaw)
    ON(10, yaw)
    ON(4, 0.15 * (pitch - roll))
    ON(5, 0.15 * (pitch + roll))
end

function setAirbreak(roll)
    local pitch = -1
    ON(1, roll)
    ON(2, pitch)
    ON(3, 1)
    ON(10, -1)
    ON(4, 0.15 * (pitch - roll))
    ON(5, 0.15 * (pitch + roll))
end

pitchTrim, rollTrim, yawTrim = 0, 0, 0
apPitch, apRoll, apYaw = 0, 0, 0
apThrottle = 0
AP_FLAG = false

function calRadDiff(t, v)
    local diff = t - v
    if diff > m.pi then
        diff = diff - 2 * m.pi
    elseif diff < -m.pi then
        diff = diff + 2 * m.pi
    end
    return diff
end

function convertWithRoll(pitchSpeed, yawSpeed, roll)
    return m.cos(roll) * pitchSpeed + m.sin(roll) * yawSpeed, -m.sin(roll) * pitchSpeed + m.cos(roll) * yawSpeed
end

function isNaN(v)
    return type(v) == "number" and v ~= v
end

function onTick()
    -- controls
    local rollMInput, pitchMInput, yawMInput = IN(1), IN(2), IN(3)
    local airbreak = IB(7)
    local manualControl = (abs(rollMInput) + abs(pitchMInput) + abs(yawMInput) > 0) or airbreak
    local manualThrottleControl = IB(3) or IB(4) or IB(6)
    local landed = IB(1)
    local ap = IB(2)
    local throttle = IN(18)
    if landed then
        if airbreak then
            setAirbreak(rollMInput)
        else
            setOutputs(rollMInput, pitchMInput, yawMInput)
        end

        -- whether activate trim pid
        OB(1, false)
        OB(2, false)
        OB(3, false)
        -- pid targets
        ON(6, 0)
        ON(7, 0)
        ON(8, 0)
        -- throttle
        ON(9, throttle)
        OB(5, IB(3))
        OB(6, IB(4))

        AP_FLAG = false
    else
        local rollPid, pitchPid, yawPid = IN(4), IN(5), IN(6)
        if isNaN(rollPid) or isNaN(pitchPid) or isNaN(yawPid) then
            -- restart pid
            OB(1, false)
            OB(2, false)
            OB(3, false)
        else
            local speed, altitude = IN(7), IN(8)
            local factor = m.max(ALTITUDE_FACTOR, m.sqrt(altitude)) / ALTITUDE_FACTOR *
                (SPEED_SQRT_FACTOR / m.max(m.abs(speed) ^ 0.5, SPEED_SQRT_FACTOR))
            local curRollAS, curPitchAs, curYawAs = IN(15), IN(16), IN(17)
            if ap and not manualControl then
                if not AP_FLAG then
                    -- reset AP controls
                    apPitch = pitchTrim
                    apRoll = rollTrim
                    apYaw = yawTrim
                    apThrottle = throttle
                    AP_FLAG = true
                end
                -- auto pilot on and not manual control
                local roll, pitch, yaw = IN(9), IN(10), IN(11)
                local altTarget, speedTarget, yawTarget = IN(12), IN(13) / 3.6, IN(14) / 180 * m.pi
                if IB(5) then
                    -- fly to next waypoint
                    local wpx, wpz = IN(19), IN(20)
                    -- double check
                    if wpx ~= 0 or wpz ~= 0 then
                        -- calculate yawTarget
                        local selfX, selfZ = IN(21), IN(22)
                        yawTarget = m.atan(wpx - selfX, wpz - selfZ)
                    end
                end
                if yawTarget > m.pi then
                    yawTarget = yawTarget - 2 * m.pi
                end

                -- cal row target
                local yawDiff = calRadDiff(yawTarget, yaw)
                local rollTarget = clamp(AP_MAX_ROLL * (yawDiff / AP_YAW_FACTOR), -AP_MAX_ROLL, AP_MAX_ROLL)

                -- cal pitch target
                local pitchTarget = clamp(AP_MAX_PITCH * ((altTarget - altitude) / AP_PITCH_FACTOR), -AP_MAX_PITCH,
                    AP_MAX_PITCH)

                -- cal roll, pitch, yaw speed
                local rollSpeed = clamp(AP_MAX_ROLL_SPEED * (calRadDiff(rollTarget, roll) / m.pi * 5),
                    -AP_MAX_ROLL_SPEED, AP_MAX_ROLL_SPEED)
                local pitchSpeed = clamp(AP_MAX_PITCH_SPEED * (calRadDiff(pitchTarget, pitch) / m.pi * 5),
                    -AP_MAX_PITCH_SPEED, AP_MAX_PITCH_SPEED)
                local yawSpeed = clamp(AP_MAX_YAW_SPEED * (yawDiff / m.pi * 3),
                    -AP_MAX_YAW_SPEED, AP_MAX_YAW_SPEED)

                pitchSpeed, yawSpeed = convertWithRoll(pitchSpeed, yawSpeed, roll)

                -- whether activate trim pid
                OB(1, true)
                OB(2, true)
                OB(3, true)
                -- pid targets
                ON(6, pitchSpeed)
                ON(7, rollSpeed)
                ON(8, yawSpeed)

                -- trim when possible
                if abs(curPitchAs) < TRIM_ZONE then
                    pitchTrim = apPitch
                end
                if abs(curRollAS) < TRIM_ZONE then
                    rollTrim = apRoll
                end
                if abs(curYawAs) < TRIM_ZONE then
                    yawTrim = apYaw
                end

                -- controls
                apPitch = clamp(apPitch + pitchPid * factor, -1, 1)
                apRoll = clamp(apRoll + rollPid * factor, -1, 1)
                apYaw = clamp(apYaw + yawPid * factor, -1, 1)

                setOutputs(apRoll, apPitch, apYaw)

                -- auto throttle
                if manualThrottleControl then
                    apThrottle = throttle
                    ON(9, throttle)
                    OB(5, IB(3))
                    OB(6, IB(4))
                else
                    apThrottle = clamp(apThrottle +
                        clamp((speedTarget - speed) / AP_THROTTLE_FACTOR,
                            -AP_THROTTLE_SENSITIVITY, AP_THROTTLE_SENSITIVITY),
                        0, 1)
                    -- throttle
                    ON(9, apThrottle)
                    OB(5, apThrottle - throttle > AP_THROTTLE_PRECISION)
                    OB(6, throttle - apThrottle > AP_THROTTLE_PRECISION)
                end
            else
                -- manual control
                -- apply trim
                pitchTrim = clamp(pitchTrim + pitchPid * factor, -0.75, 0.75)
                rollTrim = clamp(rollTrim + rollPid * factor, -0.1, 0.1)
                yawTrim = clamp(yawTrim + yawPid * factor, -0.1, 0.1)

                -- whether activate trim pid
                OB(1, abs(rollMInput) < TRIM_ZONE and not airbreak)
                OB(2, abs(pitchMInput) < TRIM_ZONE and not airbreak)
                OB(3, abs(yawMInput) < TRIM_ZONE and not airbreak)
                -- pid targets
                ON(6, 0)
                ON(7, 0)
                ON(8, 0)
                -- throttle
                ON(9, throttle)
                OB(5, IB(3))
                OB(6, IB(4))

                -- trim pitch when mannual control
                if curPitchAs < TRIM_ZONE and pitchPid == 0 then
                    pitchTrim = pitchTrim + pitchMInput * M_PITCH_TRIM_FACTOR
                end

                if airbreak then
                    setAirbreak(trim(rollMInput, rollTrim))
                else
                    setOutputs(
                        trim(rollMInput, rollTrim),
                        trim(pitchMInput, pitchTrim),
                        trim(yawMInput, yawTrim))
                end
                AP_FLAG = false
            end
        end
    end
    OB(4, AP_FLAG)
end
