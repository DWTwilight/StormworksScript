-- output format
-- 1: missile fin roll
-- 2: missile fin pitch
-- 3: current status
m = math
sin = m.sin
cos = m.cos
acos = m.acos
atan = m.atan
abs = m.abs
pi = m.pi

IN = input.getNumber
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

function clamp(value, min, max)
    return m.min(max, m.max(value, min))
end

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return {{cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
             sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy)}, {-sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz)},
            {sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
             sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy)}}
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

function tM(M) -- Transpose matrix
    local N = {{}, {}, {}}
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function EularRotate(v, B)
    local p = Mv(B, {v[1], v[3], v[2]})
    return p[1], p[3], p[2]
end

function target(pos, ttl)
    return {
        pos = pos,
        v = nil,
        ttlF = ttl,
        ttl = ttl,
        update = function(t, pos, ttl)
            if pos == nil then
                t.ttl = t.ttl - 1
            else
                -- update speed
                t.v = {(pos[1] - t.pos[1]) / t.ttlF, (pos[2] - t.pos[2]) / t.ttlF, (pos[3] - t.pos[3]) / t.ttlF}
                t.pos = pos
                t.ttl = ttl
                t.ttlF = ttl
            end
        end,
        curPos = function(t, tickOffset)
            if t.v == nil then
                return t.pos[1], t.pos[2], t.pos[3]
            end
            local totalTickOffset = tickOffset + t.ttlF - t.ttl - 1
            return t.pos[1] + t.v[1] * totalTickOffset, t.pos[2] + t.v[2] * totalTickOffset,
                t.pos[3] + t.v[3] * totalTickOffset
        end
    }
end

-- status enum
STATUS = {
    RT = 0,
    RDY = 1,
    LCH = 2,
    RTD = 3
}

LAUCH_STAT = {
    CHASE = 0,
    STRIKE = 1
}

VID = PN("Id on Vehicle") -- id on vehicle
TICK_PER_SEC = PN("Tick per Sec")
LAUCH_CONTROL_DELAY = PN("Lauch Control Delay(tick)")
TARGET_DELAY_COMPENSATION = PN("Target Delay Compensation")
SELF_DELAY_COMPENSAION = PN("Self Delay Compensation")
YAW_SENSITIVITY = PN("Yaw Sensitivity")
PITCH_SENSITIVITY = PN("Pitch Sensitivity")
YAW_LIMIT = PN("Yaw Limit")
PITCH_LIMIT = PN("Pitch Limit")
DETONATE_THRESHOLD = PN("Detonate Threshold")
TTL = PN("Time To Live") * TICK_PER_SEC
ROLL_STA_FACTOR = PN("Roll STA Factor")
STRIKE_DIST = PN("Strike Distance(m)")

CURRENT_STATUS = STATUS.RT
TARGET_ID = 0
TARGET = nil
DL_FREQ = 0
CUR_LAUCH_STAT = LAUCH_STAT.CHASE

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

function solveQuadratic(a, b, c)
    local discriminant = b ^ 2 - 4 * a * c -- 计算判别式
    if discriminant >= 0 then
        return (-b + math.sqrt(discriminant)) / (2 * a)
    else
        -- 没有实根
        return nil
    end
end

function normalize(x, y, z, l)
    return x / l, y / l, z / l
end

function calInterceptVelocity(x, y, z, speedQuad)
    if TARGET.v == nil then
        return nil, nil, nil, false
    end

    if CUR_LAUCH_STAT == LAUCH_STAT.CHASE then
        -- chase stage
        local tx, ty, tz = TARGET:curPos(0)
        -- check dist and change status 
        local dist = ((tx - x) ^ 2 + (ty - y) ^ 2 + (tz - z) ^ 2) ^ 0.5
        if dist < STRIKE_DIST then
            CUR_LAUCH_STAT = LAUCH_STAT.STRIKE
        end
        -- fly toward target
        return tx - x, ty - y, tz - z, false
    else
        -- strike stage 
        local tx, ty, tz = TARGET:curPos(TARGET_DELAY_COMPENSATION)
        local tvx, tvy, tvz = TARGET.v[1], TARGET.v[2], TARGET.v[3]
        local dist = ((tx - x) ^ 2 + (ty - y) ^ 2 + (tz - z) ^ 2) ^ 0.5
        local nvx, nvy, nvz = normalize(tx - x, ty - y, tz - z, dist)

        local k = solveQuadratic(nvx ^ 2 + nvy ^ 2 + nvz ^ 2, 2 * (nvx * tvx + nvy * tvy + nvz * tvz),
            tvx ^ 2 + tvy ^ 2 + tvz ^ 2 - speedQuad)
        if k == nil or k <= 0 then
            -- fly toward target
            return tx - x, ty - y, tz - z, false
        else
            local timeToImpact = dist / k
            return k * nvx + tvx, k * nvy + tvy, k * nvz + tvz, timeToImpact <= DETONATE_THRESHOLD
        end
    end
end

function onTick()
    if CURRENT_STATUS == STATUS.RT then
        -- initial status
        -- check if this is selected weapon
        if IN(18) == VID then
            -- update target info
            TARGET_ID = IN(19)
            if TARGET_ID ~= 0 then
                -- have target, transform status to ready
                CURRENT_STATUS = STATUS.RDY
            end
        end
    elseif CURRENT_STATUS == STATUS.RDY then
        -- check if this is selected weapon
        if IN(18) == VID then
            -- update target info
            if IN(19) == -999 then
                -- have target & trigger, activate lauch procedure
                CURRENT_STATUS = STATUS.RTD
                -- set datalink freq
                DL_FREQ = IN(29)
            else
                TARGET_ID = IN(19)
                if TARGET == 0 then
                    -- have no target, transform status to require target
                    CURRENT_STATUS = STATUS.RT
                end
            end
        else
            -- not selected weapon, reset status to require target
            CURRENT_STATUS = STATUS.RT
        end
    elseif CURRENT_STATUS == STATUS.RTD then
        -- lauched
        local b = Eular2RotMat({IN(26), IN(28), IN(27)})
        -- calculate roll angular speed
        local _, _, laz = EularRotate({IN(30), IN(31), IN(32)}, b)
        ON(5, -laz * ROLL_STA_FACTOR)
        -- update target info
        local ri = nil
        for i = 1, 4 do
            if IN(i) == TARGET_ID then
                ri = i
                break
            end
        end

        if ri ~= nil then
            -- update or create target info
            local tx, ty, tz = IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5)
            if TARGET == nil then
                TARGET = target({tx, ty, tz}, IN(5))
            else
                TARGET:update({tx, ty, tz}, IN(5))
            end
        end

        -- update ttl
        if TARGET ~= nil then
            TARGET:update()
            if TARGET.ttl < 0 then
                TARGET = nil
            end
        end

        -- update self ttl, detonate if ttl expires
        TTL = TTL - 1
        OB(1, TTL < 0)

        -- set defaults
        ON(1, 0)
        ON(2, 0)
        -- update fin & detonate control
        if LAUCH_CONTROL_DELAY > 0 then
            LAUCH_CONTROL_DELAY = LAUCH_CONTROL_DELAY - 1
        elseif TARGET ~= nil then
            -- calculate fin control data
            -- get physics sensor data
            local x, y, z, vxl, vyl, vzl = IN(20), IN(21), IN(22), IN(23) / TICK_PER_SEC, IN(24) / TICK_PER_SEC,
                IN(25) / TICK_PER_SEC
            local tb = tM(b) -- local to global matrix
            -- get self global speed (per tick)
            local vx, vy, vz = EularRotate({vxl, vyl, vzl}, tb)
            -- get intercept velocity
            local icVx, icVy, icVz, detonate = calInterceptVelocity(x + vx * SELF_DELAY_COMPENSAION,
                y + vy * SELF_DELAY_COMPENSAION, z + vz * SELF_DELAY_COMPENSAION, vxl ^ 2 + vyl ^ 2 + vzl ^ 2)
            if icVx ~= nil then
                -- transform to local speed
                icVx, icVy, icVz = EularRotate({icVx, icVy, icVz}, b)
                -- calculate roll offset, pitch offset
                local yawOffset = calAngleDiff2D({icVx, icVz}, {vxl, vzl})
                local pitchOffset = -calAngleDiff2D({(icVz ^ 2 + icVx ^ 2) ^ 0.5, icVy},
                    {(vzl ^ 2 + vxl ^ 2) ^ 0.5, vyl})

                ON(1, clamp(yawOffset / pi * YAW_SENSITIVITY, -YAW_LIMIT, YAW_LIMIT))
                ON(2, clamp(pitchOffset / pi * PITCH_SENSITIVITY, -PITCH_LIMIT, PITCH_LIMIT))
            end
            OB(1, detonate)
        end
    end
    ON(3, CURRENT_STATUS)
    ON(4, DL_FREQ)
end
