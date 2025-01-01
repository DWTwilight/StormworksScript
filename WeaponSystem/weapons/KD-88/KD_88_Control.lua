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
    CRUISE = 0,
    STRIKE = 1
}

VID = PN("Id on Vehicle") -- id on vehicle
TPS = PN("Tick per Sec")
LCD = PN("Lauch Control Delay(tick)")
TDC = PN("Target Delay Compensation")
SDC = PN("Self Delay Compensation")
YAWS = PN("Yaw Sensitivity")
PITCHS = PN("Pitch Sensitivity")
YAWL = PN("Yaw Limit")
PITCHL = PN("Pitch Limit")
DTTHRE = PN("Detonate Threshold")
TTL = PN("Time To Live") * TPS
STRIKE_DIST = PN("Strike Distance")
CRUISE_ALT = PN("Cruise Altitude")

C_STAT = STATUS.RT
T_ID = 0
T = nil
DL_FREQ = 0
CUR_LAUCH_STAT = LAUCH_STAT.CRUISE

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
    if T.v == nil then
        return nil, nil, nil, false
    end

    if CUR_LAUCH_STAT == LAUCH_STAT.CRUISE then
        -- cruise stage
        local tx, ty, tz = T:curPos(0)
        local dist = ((tx - x) ^ 2 + (ty - y) ^ 2 + (tz - z) ^ 2) ^ 0.5
        -- calculate target pitch
        local targetPitchAng = clamp((CRUISE_ALT - y) / 2000 * pi, -pi / 4, pi / 4)
        -- cal fake ty
        ty = y + ((tx - x) ^ 2 + (tz - z) ^ 2) ^ 0.5 * sin(targetPitchAng)
        -- check dist and change status 
        if dist <= STRIKE_DIST then
            -- start strike
            CUR_LAUCH_STAT = LAUCH_STAT.STRIKE
        end
        -- fly toward target
        return tx - x, ty - y, tz - z, false
    else
        -- strike stage
        local tx, ty, tz = T:curPos(TDC)
        local tvx, tvy, tvz = T.v[1], T.v[2], T.v[3]
        local dist = ((tx - x) ^ 2 + (ty - y) ^ 2 + (tz - z) ^ 2) ^ 0.5
        local nvx, nvy, nvz = normalize(tx - x, ty - y, tz - z, dist)

        local k = solveQuadratic(nvx ^ 2 + nvy ^ 2 + nvz ^ 2, 2 * (nvx * tvx + nvy * tvy + nvz * tvz),
            tvx ^ 2 + tvy ^ 2 + tvz ^ 2 - speedQuad)
        if k == nil or k <= 0 then
            -- fly toward target
            return tx - x, ty - y, tz - z, false
        else
            local timeToImpact = dist / k
            return k * nvx + tvx, k * nvy + tvy, k * nvz + tvz, timeToImpact <= DTTHRE
        end
    end
end

function onTick()
    if C_STAT == STATUS.RT then
        -- initial status
        -- check if this is selected weapon
        if IN(18) == VID then
            -- update target info
            T_ID = IN(19)
            if T_ID ~= 0 or (IN(32) == 2 and (IN(30) ~= 0 or IN(31) ~= 0)) then
                -- have target, transform status to ready
                C_STAT = STATUS.RDY
            end
        end
    elseif C_STAT == STATUS.RDY then
        -- check if this is selected weapon
        if IN(18) == VID then
            -- update target info
            if IN(19) == -999 then
                -- lauch procedure
                -- have target & trigger, activate lauch procedure
                C_STAT = STATUS.RTD
                -- set datalink freq
                DL_FREQ = IN(29)
                if T_ID == -1 then
                    -- create target mannually
                    T = target({IN(30), 0, IN(31)}, 0)
                    T.v = {0, 0, 0}
                end
            else
                T_ID = IN(19)
                if T_ID == 0 then
                    -- check if is gps target
                    if IN(32) == 2 and (IN(30) ~= 0 or IN(31) ~= 0) then
                        T_ID = -1
                    else
                        -- have no target, transit status to require target
                        C_STAT = STATUS.RT
                    end
                end
            end
        else
            -- not selected weapon, reset status to require target
            C_STAT = STATUS.RT
        end
    elseif C_STAT == STATUS.RTD then
        -- lauched
        if T_ID > 0 then
            -- update radar target info
            local ri = nil
            for i = 1, 4 do
                if IN(i) == T_ID then
                    ri = i
                    break
                end
            end

            if ri ~= nil then
                -- update or create target info
                local tx, ty, tz = IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5)
                if T == nil then
                    T = target({tx, ty, tz}, IN(5))
                else
                    T:update({tx, ty, tz}, IN(5))
                end
            end

            -- update ttl
            if T ~= nil then
                T:update()
                if T.ttl < 0 then
                    T = nil
                end
            end
        end

        -- update self ttl, detonate if ttl expires
        TTL = TTL - 1
        OB(1, TTL < 0)

        -- set defaults
        ON(1, 0)
        ON(2, 0)
        -- update fin & detonate control
        if LCD > 0 then
            LCD = LCD - 1
        elseif T ~= nil then
            -- calculate fin control data
            -- get physics sensor data
            local x, y, z, vxl, vyl, vzl, b = IN(20), IN(21), IN(22), IN(23) / TPS, IN(24) / TPS, IN(25) / TPS,
                Eular2RotMat({IN(26), IN(28), IN(27)})
            local tb = tM(b) -- local to global matrix
            -- get self global speed (per tick)
            local vx, vy, vz = EularRotate({vxl, vyl, vzl}, tb)
            -- get intercept velocity
            local icVx, icVy, icVz, detonate = calInterceptVelocity(x + vx * SDC, y + vy * SDC, z + vz * SDC,
                vxl ^ 2 + vyl ^ 2 + vzl ^ 2)
            if icVx ~= nil then
                -- transform to local speed
                icVx, icVy, icVz = EularRotate({icVx, icVy, icVz}, b)
                -- calculate roll offset, pitch offset
                local yawOffset = calAngleDiff2D({icVx, icVz}, {vxl, vzl})
                local pitchOffset = -calAngleDiff2D({(icVz ^ 2 + icVx ^ 2) ^ 0.5, icVy},
                    {(vzl ^ 2 + vxl ^ 2) ^ 0.5, vyl})

                ON(1, clamp(yawOffset / pi * YAWS, -YAWL, YAWL))
                ON(2, clamp(pitchOffset / pi * PITCHS, -PITCHL, PITCHL))
            end
            OB(1, detonate)
        end
    end
    ON(3, C_STAT)
    ON(4, DL_FREQ)
end
