M = math
MIN = M.min
MAX = M.max
ABS = M.abs
RAD = M.rad
PI = M.pi
PI2 = 2 * PI
PIH = PI / 2
PIT = PI / 3
COS = M.cos
SIN = M.sin
AC = M.acos
AS = M.asin
TAN = M.tan

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

SPD_SQRT_F = PN("Speed Factor")
ALT_F = PN("Altitude Factor")

TRIMZ = PN("Trim Zone")
TRIMD = PN("Trim Delay")
TRIM_ROLL_SENS = PN("Roll Trim Sensitivity")
TRIM_PITCH_SENS = PN("Pitch Trim Sensitivity")
TRIM_YAW_SENS = PN("Yaw Trim Sensitivity")

-- AP Throttle Config
AP_THROT_SENS = PN("AP Throttle Sensitivity")
AP_THROT_F = PN("AP Throttle Factor")
AP_THROT_PRECIS = PN("AP Throttle Precision")
AP_THROT_MIN = PN("AP Throttle Min")

-- AP Roll Config
AP_MAX_ROLL = PN("AP Max Roll") -- ap max roll angle
AP_ROLL_SENS = PN("AP Roll Sensitivity") -- ap roll sens propotion to yawDiff
AP_ROLL_CL = PN("AP Roll Control Limit") -- max ap roll control value
AP_ROLL_CTRL_SENS = PN("AP Roll Control Sensitivity")

-- AP Pitch Config
AP_MAX_PITCH = PN("AP Max Pitch") -- max pitch angle
AP_PITCH_SENS = PN("AP Pitch Sensitivity") -- ap pitch speed propotion to pitch offset
AP_MAX_PITCH_SPD = PN("AP Max Pitch Speed") -- max pitch angular speed
AP_PITCH_CTRL_SENS = PN("AP Pitch Control Sensitivity") -- control sens for ap pitch control

-- AP Yaw Config
AP_YAW_CL = PN("AP Yaw Control Limit")
AP_YAW_CTRL_SENS = PN("AP Yaw Control Sensitivity")

AP_POS_W = PN("AP Position Weight") -- weight of pos diff

-- current status
ROLLC, PITCHC, YAWC, THROT = 0, 0, 0, 0
-- trim
ROLLT, PITCHT, YAWT = 0, 0, 0
RTC, PTC, YTC = TRIMD, TRIMD, TRIMD
-- AP status 
APC = TRIMD

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

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return {{COS(qy) * COS(qz), COS(qx) * COS(qy) * SIN(qz) + SIN(qx) * SIN(qy),
             SIN(qx) * COS(qy) * SIN(qz) - COS(qx) * SIN(qy)}, {-SIN(qz), COS(qx) * COS(qz), SIN(qx) * COS(qz)},
            {SIN(qy) * COS(qz), COS(qx) * SIN(qy) * SIN(qz) - SIN(qx) * COS(qy),
             SIN(qx) * SIN(qy) * SIN(qz) + COS(qx) * COS(qy)}}
end

function Mv(M, v)
    local u = {}
    for i = 1, 3 do
        local _ = 0
        for j = 1, 3 do
            _ = _ + M[j][i] * v[j]
        end
        u[i] = _
    end
    return u
end

function EularRotate(v, B)
    local p = Mv(B, {v[1], v[3], v[2]})
    return p[1], p[3], p[2]
end

function calAngleDiff2D(target, current)
    -- Function to calculate the dot product
    local function dotProduct(v1, v2)
        return v1[1] * v2[1] + v1[2] * v2[2]
    end
    local function magnitude(v)
        return (v[1] ^ 2 + v[2] ^ 2) ^ 0.5
    end

    local dot = dotProduct(target, current)
    local mag1 = magnitude(target)
    local mag2 = magnitude(current)
    if mag1 == 0 or mag2 == 0 then
        return 0
    end

    -- Calculate the angle using the dot product and magnitudes
    local angle = AC(dot / (mag1 * mag2))
    if target[1] * current[2] - target[2] * current[1] < 0 then
        return -angle
    else
        return angle
    end
end

-- rotate a vector v along Y axis by ang(rad)
function rotateY(v, ang)
    local x, z = v[1], v[3]
    v[1] = x * COS(ang) + z * SIN(ang)
    v[3] = -x * SIN(ang) + z * COS(ang)
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
        APC = TRIMD
        RTC, PTC, YTC = TRIMD, TRIMD, TRIMD
        -- reset trim values
        ROLLT, PITCHT, YAWT = 0, 0, 0
        -- set outputs
        -- landed, use primitive inputs
        ROLLC, PITCHC, YAWC = rollMInput, pitchMInput, yawMInput

        -- default throttle control 
        THROT = throttleMInput
        OB(1, throttleUpM)
        OB(2, throttleDownM)
    else
        -- airborn
        local gx, gy, gz, airSpeed = IN(5), IN(6), IN(7), IN(8)
        local factor = MAX(ALT_F, gy ^ 0.5) / ALT_F * (SPD_SQRT_F / MAX(ABS(airSpeed) ^ 0.5, SPD_SQRT_F))
        local curRollAs, curPitchAs, curYawAs = IN(9), IN(10), IN(11)
        local autoPilot = IB(5)

        if autoPilot and not manualControl and APC < 0 then
            -- auto pilot on and not manual control
            -- reset trim delays
            RTC, PTC, YTC = TRIMD, TRIMD, TRIMD

            -- update trim when possile 
            if ABS(curPitchAs) < TRIMZ then
                PITCHT = PITCHC
            end
            if ABS(curRollAs) < TRIMZ then
                ROLLT = ROLLC
            end
            if ABS(curYawAs) < TRIMZ then
                YAWT = YAWC
            end

            local targetSpeed, targetSpeedVector = 0, {}

            if IB(7) then
                -- ILS

            else
                -- normal AP
                -- get basic ap config
                local altTarget, yawTarget = IN(12), RAD(IN(13))
                -- for yawTarget above 180
                if yawTarget > PI then
                    yawTarget = yawTarget - PI2
                end
                -- check if fly to waypoint enables
                if IB(6) and IN(14) ~= -1 then
                    -- fly to waypoint enabled, override yaw target
                    yawTarget = IN(15)
                end
                targetSpeed = IN(16) / 3.6
                targetSpeedVector = {SIN(yawTarget), (altTarget - gy) * AP_POS_W, COS(yawTarget)}
            end

            -- get current atitude (global)
            local roll, yaw = IN(17), IN(18)
            -- clamp target Pitch
            local maxSpeedVectorY = TAN(AP_MAX_PITCH) * (targetSpeedVector[1] ^ 2 + targetSpeedVector[3] ^ 2) ^ 0.5
            targetSpeedVector[2] = clamp(targetSpeedVector[2], -maxSpeedVectorY, maxSpeedVectorY)
            -- clamp target yaw
            -- calculate global yawDiff
            local globalYawDiff = calAngleDiff2D({targetSpeedVector[1], targetSpeedVector[3]}, {SIN(yaw), COS(yaw)})
            if globalYawDiff > PIT then
                rotateY(targetSpeedVector, -globalYawDiff + PIT)
            elseif globalYawDiff < -PIT then
                rotateY(targetSpeedVector, -globalYawDiff - PIT)
            end

            -- transform to local
            local tvx, tvy, tvz = EularRotate(targetSpeedVector, Eular2RotMat({IN(19), IN(21), IN(20)}))

            -- get current speed (local)
            local lvx, lvy, lvz = IN(22), IN(23), IN(24)

            -- calculate yaw & pitch offset (local)
            local yawOffset = calAngleDiff2D({tvx, tvz}, {lvx, lvz})
            local pitchOffset = calAngleDiff2D({tvy, (tvx ^ 2 + tvz ^ 2) ^ 0.5}, {lvy, (lvx ^ 2 + lvz ^ 2) ^ 0.5})

            -- calculate controls
            -- roll
            -- local rollTarget = 0
            local rollTarget = clamp(globalYawDiff * AP_ROLL_SENS, -AP_MAX_ROLL, AP_MAX_ROLL)
            ROLLC = clamp((rollTarget - roll) * factor * AP_ROLL_CTRL_SENS, -AP_ROLL_CL, AP_ROLL_CL)

            -- pitch
            local targetPitchSpeed = clamp(pitchOffset * AP_PITCH_SENS, -AP_MAX_PITCH_SPD, AP_MAX_PITCH_SPD)
            PITCHC = clamp(PITCHC + (targetPitchSpeed - curPitchAs) * factor * AP_PITCH_CTRL_SENS, -1, 1)

            -- yaw
            YAWC = clamp((yawOffset * factor * AP_YAW_CTRL_SENS), -AP_YAW_CL, AP_YAW_CL)
            -- throttle
            if targetSpeed <= 0 or manualThrottleControl then
                -- manual throttle control
                THROT = throttleMInput
                OB(1, throttleUpM)
                OB(2, throttleDownM)
            else
                -- auto throttle    
                THROT = MAX(clamp(THROT + clamp((targetSpeed - airSpeed) * AP_THROT_F, -AP_THROT_SENS, AP_THROT_SENS),
                    0, 1), AP_THROT_MIN)
                OB(1, THROT - throttleMInput > AP_THROT_PRECIS)
                OB(2, throttleMInput - THROT > AP_THROT_PRECIS)
            end
        else
            -- manualControl or AP delay 
            if autoPilot and not manualControl then
                APC = APC - 1
            else
                APC = TRIMD
            end
            -- recalculate trim values
            if not airBreak then
                if rollMInput == 0 or rollMInput * curRollAs < 0 then
                    if RTC < 0 then
                        ROLLT = clamp(ROLLT - curRollAs * factor * TRIM_ROLL_SENS, -0.1, 0.1)
                    else
                        RTC = RTC - 1
                    end
                else
                    RTC = TRIMD
                end

                if pitchMInput == 0 or pitchMInput * curPitchAs < 0 then
                    if PTC < 0 then
                        PITCHT = clamp(PITCHT - curPitchAs * factor * TRIM_PITCH_SENS, -0.8, 0.8)
                    else
                        PTC = PTC - 1
                    end
                else
                    PTC = TRIMD
                end

                if yawMInput == 0 or yawMInput * curYawAs < 0 then
                    if YTC < 0 then
                        YAWT = clamp(YAWT - curYawAs * factor * TRIM_YAW_SENS, -0.1, 0.1)
                    else
                        YTC = YTC - 1
                    end
                else
                    YTC = TRIMD
                end
            else
                RTC, PTC, YTC = TRIMD, TRIMD, TRIMD
            end
            -- set outputs
            -- manual control, use trimed inputs
            ROLLC, PITCHC, YAWC = trim(rollMInput, ROLLT), trim(pitchMInput, PITCHT), trim(yawMInput, YAWT)
            -- default throttle control 
            THROT = throttleMInput
            OB(1, throttleUpM)
            OB(2, throttleDownM)
        end
    end

    -- set control outputs
    ON(1, ROLLC)
    ON(2, PITCHC)
    ON(3, YAWC)
    ON(4, 0.15 * (PITCHC - ROLLC))
    ON(5, 0.15 * (PITCHC + ROLLC))
    ON(6, THROT)
end
