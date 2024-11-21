-- for test
-- require("new.j11.WeaponSystem.GSH_30_1.BallisticComputerTestData")

M = math
cos = M.cos
sin = M.sin
atan = M.atan
abs = M.abs
acos = M.acos
exp = M.exp
log = M.log

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return { { cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
        sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy) }, { -sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz) },
        { sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
            sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy) } }
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

function tM(M)
    local N = { {}, {}, {} }
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function EularRotate(v, B)
    local PN = Mv(B, { v[1], v[3], v[2] })
    return PN[1], PN[3], PN[2]
end

TICK_PER_SEC = PN("Tick per Sec")
DRAG_COEFFICIENT = -TICK_PER_SEC * log(1 - PN("[BC]Drag Coefficient"))
MUZZEL_VELOCITY = PN("[BC]Muzzel Velocity")
GRAVITY = PN("[BC]Gravity")
PRECISION = PN("[BC]Precision")
MAX_ITER_COUNT = PN("[BC]Max Iterations")
MAX_TICK = PN("[BC]Max Tick")
TARGET_DELAY_COMPENSATION = PN("[BC]Target Delay Compensation")
SELF_DELAY_COMPENSATION = PN("[BC]Self Delay Compensation")

function calculateVelocity(x, y, z, tick, windSpeedX, windSpeedZ)
    local kt = DRAG_COEFFICIENT * tick / TICK_PER_SEC
    local k = DRAG_COEFFICIENT
    local velocityZ = (k * z - kt * windSpeedZ) / (1 - exp(-kt)) + windSpeedZ
    local velocityY = (k * y + GRAVITY * tick / TICK_PER_SEC) / (1 - exp(-kt)) - GRAVITY / k
    local velocityX = (k * x - kt * windSpeedX) / (1 - exp(-kt)) + windSpeedX
    return velocityX, velocityY, velocityZ
end

function calculateGap(muzzelVelocity, x, y, z, tick, windSpeedX, windSpeedZ)
    local velocityX, velocityY, velocityZ = calculateVelocity(x, y, z, tick, windSpeedX, windSpeedZ)
    return muzzelVelocity - (velocityX ^ 2 + velocityY ^ 2 + velocityZ ^ 2) ^ 0.5
end

function calculateTargetPosition(selfX, selfY, selfZ,
                                 selfVX, selfVY, selfVZ,
                                 targetX, targetY, targetZ,
                                 targetVx, targetVy, targetVz,
                                 tick)
    local st = SELF_DELAY_COMPENSATION / TICK_PER_SEC
    selfX, selfY, selfZ = selfX + st * selfVX, selfY + st * selfVY, selfZ + st * selfVZ

    local t = (tick + TARGET_DELAY_COMPENSATION) / TICK_PER_SEC
    return targetX - selfX + targetVx * t,
        targetY - selfY + targetVy * t,
        targetZ - selfZ + targetVz * t
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
    local angle = acos(dot / (mag1 * mag2))
    if target[1] * current[2] - target[2] * current[1] < 0 then
        return -angle
    else
        return angle
    end
end

function onTick()
    if not IB(1) then
        -- BC off, set default values
        OB(1, false) -- can reach target?
        ON(1, 0)     -- muzzel offset x (rad)
        ON(2, 0)     -- muzzel offset y (rad)
        return
    end
    if IB(2) then
        -- update calculation pulse
        local selfVX, selfVY, selfVZ = IN(1), IN(2), IN(3) -- local speed
        -- calculate muzzelVelocity
        local muzzelVelocity = (selfVX ^ 2 + selfVY ^ 2 + (selfVZ + MUZZEL_VELOCITY) ^ 2) ^ 0.5

        local selfX, selfY, selfZ = IN(4), IN(5), IN(6)
        local targetX, targetY, targetZ = IN(7), IN(8), IN(9)
        local targetVx, targetVy, targetVz = IN(10), IN(11), IN(12)
        local windSpeedX, windSpeedZ = IN(13), IN(14)

        -- cal target offset
        local ngeTick = 0
        local posTick = MAX_TICK
        local travelTicks
        local gap = PRECISION
        local iter = 0
        local x, y, z = 0, 0, 0

        while abs(gap) >= PRECISION and iter <= MAX_ITER_COUNT do
            iter = iter + 1
            travelTicks = (posTick + ngeTick) / 2
            x, y, z = calculateTargetPosition(
                selfX, selfY, selfZ,
                selfVX, selfVY, selfVZ,
                targetX, targetY, targetZ,
                targetVx, targetVy, targetVz,
                travelTicks)
            gap = calculateGap(muzzelVelocity, x, y, z, travelTicks, windSpeedX, windSpeedZ)

            if gap > 0 then
                posTick = travelTicks
            else
                ngeTick = travelTicks
            end
        end

        if abs(gap) >= PRECISION then
            -- target cannot reach
            OB(1, false) -- can reach target?
            ON(1, 0)     -- muzzel offset x (rad)
            ON(2, 0)     -- muzzel offset y (rad)
            return
        end

        -- get calculated muzzelVelocity(global)
        local velocityX, velocityY, velocityZ = calculateVelocity(x, y, z, travelTicks, windSpeedX, windSpeedZ)
        -- convert to local muzzelVelocity
        velocityX, velocityY, velocityZ = EularRotate({ velocityX, velocityY, velocityZ },
            Eular2RotMat({ IN(15), IN(17), IN(16) }))

        -- cal local yaw offset
        local yawOffset = calAngleDiff2D({ velocityX, velocityZ }, { selfVX, selfVZ + MUZZEL_VELOCITY })
        -- cal local pitch offset
        local pitchOffset = -calAngleDiff2D(
            { (velocityX ^ 2 + velocityZ ^ 2) ^ 0.5, velocityY },
            { (selfVX ^ 2 + (selfVZ + MUZZEL_VELOCITY) ^ 2) ^ 0.5, selfVY })

        OB(1, true)        -- can reach target?
        ON(1, yawOffset)   -- muzzel yaw offset (rad)
        ON(2, pitchOffset) -- muzzel pitch offset (rad)
    end
end

-- for test
-- onTick()

-- -- backward cal (only pitch offset, start from (0,0,0))
-- local muzzelVelocity = { 0, 0, MUZZEL_VELOCITY }
-- local offsetMuzzelVelocity = { 0, MUZZEL_VELOCITY * sin(pitchOffset), MUZZEL_VELOCITY * cos(pitchOffset) }
-- local pos = { 0, 0, 0 }

-- local dt = 1 / TICK_PER_SEC
-- for i = 1, MAX_TICK do
--     pos[1] = pos[1] + offsetMuzzelVelocity[1] * dt
--     pos[2] = pos[2] + offsetMuzzelVelocity[2] * dt
--     pos[3] = pos[3] + offsetMuzzelVelocity[3] * dt

--     -- output
--     print(string.format("tick: %d, pos: (%f, %f, %f)", i, pos[1], pos[2], pos[3]))

--     -- apply gravity and drag
--     offsetMuzzelVelocity[2] = offsetMuzzelVelocity[2] * 0.99 - GRAVITY / TICK_PER_SEC
--     -- apply drag
--     offsetMuzzelVelocity[3] = offsetMuzzelVelocity[3] * 0.99
-- end
