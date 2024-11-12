M = math
cos = M.cos
sin = M.sin
atan = M.atan
abs = M.abs

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
DRAG_COEFFICIENT = 1 - (1 - PN("[BC]Drag Coefficient")) ^ TICK_PER_SEC
MUZZEL_VELOCITY = PN("[BC]Muzzel Velocity")
GRAVITY = PN("[BC]Gravity")
PRECISION = PN("[BC]Precision")
MAX_ITER_COUNT = PN("[BC]Max Iterations")
BARREL_HORIZONTAL_OFFSET = PN("[BC]Barrel Horizontal Offset")
BARREL_VERTICAL_OFFSET = PN("[BC]Barrel Vertical Offset")

function calculateVelocity(x, y, z, tick, windSpeedX, windSpeedZ, selfSpeedX, selfSpeedZ, selfSpeedY)
    local kt = DRAG_COEFFICIENT * tick / TICK_PER_SEC
    local k = DRAG_COEFFICIENT
    local velocityZ = (k * z - kt * windSpeedZ) / (1 - math.exp(-kt)) + windSpeedZ
    local velocityY = (k * y + GRAVITY * tick / TICK_PER_SEC) / (1 - math.exp(-kt)) - GRAVITY / k
    local velocityX = (k * x - kt * windSpeedX) / (1 - math.exp(-kt)) + windSpeedX
    return velocityX - selfSpeedX, velocityY - selfSpeedY, velocityZ - selfSpeedZ
end

function calculateGap(muzzelVelocity, x, y, z, tick, windSpeedX, windSpeedZ, selfSpeedX, selfSpeedZ, selfSpeedY)
    local velocityX, velocityY, velocityZ = calculateVelocity(x, y, z, tick, windSpeedX, windSpeedZ, selfSpeedX,
        selfSpeedZ, selfSpeedY)
    return muzzelVelocity - (velocityX ^ 2 + velocityY ^ 2 + velocityZ ^ 2) ^ 0.5
end

function calculateTargetPosition(targetX, targetY, targetZ, targetAbsoluteVx, targetAbsoluteVy, targetAbsoluteVz, tick)
    local t = tick / TICK_PER_SEC
    return targetX + targetAbsoluteVx * t,
        targetY + targetAbsoluteVy * t,
        targetZ + targetAbsoluteVz * t
end

function convertGlobalXZToRelative(x, z, yaw)
    return x * cos(yaw) - z * sin(yaw), z * cos(yaw) + x * sin(yaw)
end

function convertLocalToRelativeValues(x, y, z, yaw, b)
    -- transform from local value to global relative value
    local globalX, globalY, globalZ = EularRotate({ x, y, z }, b)
    local rx, rz = convertGlobalXZToRelative(globalX, globalZ, yaw)
    return rx, globalY, rz
end

function onTick()
    if IN(18) == 1 and IN(2) == 2 then
        -- locked and use GSH-30-1
        if IB(1) then
            -- update calculation
            local yaw = IN(12)

            local selfVX, selfVY, selfVZ = IN(1), IN(2), IN(3)
            local targetX, targetY, targetZ = IN(4), IN(5), IN(6)
            local targetVx, targetVy, targetVz = IN(7), IN(8), IN(9)
            local windSpeedX, windSpeedZ = IN(10), IN(11)

            -- cal target offset
            local ngeTick = 0
            local posTick = 300
            local travelTicks
            local gap = PRECISION
            local iter = 0
            local x, y, z = 0, 0, 0

            while abs(gap) >= PRECISION and iter <= MAX_ITER_COUNT do
                iter = iter + 1
                travelTicks = (posTick + ngeTick) / 2
                x, y, z = calculateTargetPosition(
                    targetX, targetY, targetZ,
                    targetVx, targetVy, targetVz,
                    travelTicks)
                gap = calculateGap(MUZZEL_VELOCITY, x, y, z, travelTicks, windSpeedX, windSpeedZ, selfVX, selfVY, selfVZ)

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

            local velocityX, velocityY, velocityZ = calculateVelocity(
                x, y, z, travelTicks,
                windSpeedX, windSpeedZ,
                selfVX, selfVY, selfVZ)
            local yawTarget =
                yaw + atan(velocityX / velocityZ)
            local xz = (velocityX ^ 2 + velocityZ ^ 2) ^ 0.5
            local lx, ly, lz = EularRotate({ xz * sin(yawTarget), velocityY, xz * cos(yawTarget) }, B)

            OB(1, true)                              -- can reach target?
            ON(1, atan(lx, lz))                      -- muzzel offset x (rad)
            ON(2, atan(ly, (lx ^ 2 + lz ^ 2) ^ 0.5)) -- muzzel offset y (rad)
        end
    else
        OB(1, false) -- can reach target?
        ON(1, 0)     -- muzzel offset x (rad)
        ON(2, 0)     -- muzzel offset y (rad)
    end
end
