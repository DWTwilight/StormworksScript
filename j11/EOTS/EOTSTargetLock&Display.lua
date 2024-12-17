M = math
TAN = M.tan
AT = M.atan
SIN = M.sin
COS = M.cos
ABS = M.abs

S = screen
DL = S.drawLine
DR = S.drawRect
DC = S.drawCircle
DT = S.drawText

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
PT = P.getText

PR = pairs
IPR = ipairs

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = tonumber("0x" .. e:sub(1, 2)),
        g = tonumber("0x" .. e:sub(3, 4)),
        b = tonumber("0x" .. e:sub(5, 6)),
        t = tonumber("0x" .. e:sub(7, 8))
    }
end

function SC(c)
    S.setColor(c.r, c.g, c.b, c.t)
end

function createCoordConvertMatrix(yawRad, pitchRad)
    return {
        { COS(yawRad),                  0,             -SIN(yawRad) },
        { -SIN(yawRad) * SIN(pitchRad), COS(pitchRad), -COS(yawRad) * SIN(pitchRad) },
        { SIN(yawRad) * COS(pitchRad),  SIN(pitchRad), COS(yawRad) * COS(pitchRad) }
    }
end

function MMul(v, M)
    local u = { 0, 0, 0 }
    for i = 1, 3 do
        for j = 1, 3 do
            u[i] = u[i] + M[i][j] * v[j]
        end
    end
    return u[1], u[2], u[3]
end

function RT(id, x, y, z, f, ttl)
    return {
        id = id,
        f = f,
        ttl = ttl,
        ttlF = ttl, -- for calculation
        pos = { x, y, z },
        lockF = 0,
        speedL = nil, -- local speed per tick, appose to player
        update = function(t, x, y, z, ttl, f)
            -- update speed
            t.speedL = {
                (x - t.pos[1]) / t.ttlF,
                (y - t.pos[2]) / t.ttlF,
                (z - t.pos[3]) / t.ttlF }
            t.pos = { x, y, z }
            t.ttl = ttl
            t.ttlF = ttl
            t.f = f
        end,
        curAbsPos = function(t)
            if t.speedL == nil then
                return t.pos[1] + OFFSET_X, t.pos[2] + OFFSET_Y, t.pos[3] + OFFSET_Z
            end
            local totalTickOffset = DELAY_C + t.ttlF - t.ttl
            return
                t.pos[1] + t.speedL[1] * totalTickOffset + OFFSET_X,
                t.pos[2] + t.speedL[2] * totalTickOffset + OFFSET_Y,
                t.pos[3] + t.speedL[3] * totalTickOffset + OFFSET_Z
        end,
        curAbsPivot = function(t)
            local x, y, z = t:curAbsPos()
            return AT(x, z), AT(y, (x ^ 2 + z ^ 2) ^ 0.5)
        end,
        curPos = function(t)
            local x, y, z = t:curAbsPos()
            return MMul({ x, y, z }, CAMERA_COORD_MAT)
        end,
        draw = function(t)
            local x, y, z = t:curPos()
            -- check if in front
            if z > 0 then
                local sx, sy =
                    SCR_W / 2 + SCR_W / FOV * AT(x, z) - HRTW - 1,
                    SCR_W / 2 - SCR_W / FOV * AT(y, (x ^ 2 + z ^ 2) ^ 0.5) - HRTW - 1
                if t.lockF == 0 then
                    -- not locked
                    SC(UC)
                elseif t.lockF == 1 then
                    -- locking
                    SC(LOCKB and UC2 or UC)
                else
                    -- locked
                    SC(UC2)
                    -- draw lock line
                    DL(SCR_W / 2, SCR_W / 2, sx + HRTW, sy + HRTW)
                end

                DR(sx, sy, RTW + 1, RTW + 1)
                if t.f then
                    DL(sx, sy, sx + RTW + 1, sy + RTW + 1)
                    DL(sx + RTW + 1, sy, sx, sy + RTW + 1)
                end
                -- draw distance
                local distanceText = string.format("%.1f", (x ^ 2 + y ^ 2 + z ^ 2) ^ 0.5 / 1000)
                DT(sx - #distanceText * 2.5 + 4, sy + RTW + 3, distanceText)
            end
        end,
        canLock = function(t, la)
            local x, y, z = t:curPos()
            if z > 0 then
                local a = AT((x ^ 2 + y ^ 2) ^ 0.5, z)
                return a < t.lockF == 2 and la * 4 or la, a
            end
            return false, 0
        end
    }
end

DELAY_C = PN("Delay Compensate(ticks)")
SCR_W = PN("Screen Width")
RTW = PN("Rardar Target Width")
HRTW = RTW // 2
FOV_MIN = PN("FOV Min(rad)")
FOV_MAX = PN("FOV Max(rad)")
LAP = PN("Lock Angle Percentage") -- opposed to FOV
OFFSET_X = PN("Camera Offset X")
OFFSET_Y = PN("Camera Offset Y")
OFFSET_Z = PN("Camera Offset Z")

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))

CAMERA_COORD_MAT = nil
FOV = 0
RTS = {}
LOCK_T = nil
LOCKB = false

function onTick()
    -- get radar data
    local ttl = IN(5)
    for i = 1, 4 do
        local id, x, y, z, f = IN(i), IN(3 * i + 18), IN(3 * i + 19), IN(3 * i + 20), IB(i)
        -- add/update target to list
        if id ~= 0 then
            if RTS[id] ~= nil then
                -- do update
                RTS[id]:update(x, y, z, ttl, f)
            else
                -- insert new target
                RTS[id] = RT(id, x, y, z, f, ttl)
            end
        end
    end
    -- refresh radar data
    local toRM = {}
    for id, t in PR(RTS) do
        t.ttl = t.ttl - 1
        if t.ttl < 0 then
            table.insert(toRM, id)
        end
    end
    for _, id in IPR(toRM) do
        RTS[id] = nil
        if LOCK_T ~= nil and id == LOCK_T.id then
            LOCK_T = nil
        end
    end

    -- get current camera coord convert matrix
    CAMERA_COORD_MAT = createCoordConvertMatrix(IN(7), IN(8))
    -- calculate current FOV
    FOV = (FOV_MIN - FOV_MAX) * IN(9) + FOV_MAX

    if IN(6) == 3 then
        -- enable EOTS lock
        LOCKB = IB(6)
        -- calculate lock angle
        local la = FOV * LAP

        -- update current lock status
        if LOCK_T ~= nil and LOCK_T.lockF == 2 then
            -- have a locked target
            local canLock, _ = LOCK_T:canLock(la)
            if IB(5) or not canLock then
                -- cancel lock
                LOCK_T.lockF = 0
                LOCK_T = nil
            end
        else
            -- update current lockable target
            local minA = la
            local lockableTarget = nil
            for _, t in pairs(RTS) do
                local canLock, a = t:canLock(la)
                if canLock and a < minA then
                    lockableTarget = t
                    minA = a
                end
            end
            if lockableTarget ~= nil then
                -- replace lockT
                if LOCK_T ~= nil and LOCK_T.id ~= lockableTarget.id then
                    LOCK_T.lockF = 0
                end
                LOCK_T = lockableTarget
                LOCK_T.lockF = 1
            elseif LOCK_T ~= nil then
                -- cancel locking
                LOCK_T.lockF = 0
                LOCK_T = nil
            end

            -- handle lock pulse
            if LOCK_T ~= nil and IB(5) then
                LOCK_T.lockF = 2
            end
        end
    else
        if LOCK_T ~= nil then
            -- cancel locking
            LOCK_T.lockF = 0
            LOCK_T = nil
        end
    end
    if LOCK_T == nil then
        ON(1, 0)
        ON(2, 0)
        ON(3, 0)
        ON(4, 0)
    else
        ON(1, LOCK_T.lockF == 2 and LOCK_T.id or 0)
        ON(2, LOCK_T.lockF)
        local absYaw, absPitch = LOCK_T:curAbsPivot()
        ON(3, absYaw)
        ON(4, absPitch)
    end
end

function onDraw()
    -- draw crosshair
    SC(UC2)
    local w, h = SCR_W / 2, SCR_W / 2;
    DL(w - 2, h, w, h)
    DL(w + 1, h, w + 3, h)
    DL(w, h - 2, w, h)
    DL(w, h + 1, w, h + 3)

    if LOCK_T ~= nil and LOCK_T.lockF == 2 then
        -- only draw locked target
        LOCK_T:draw()
    else
        -- draw radar targets
        for _, t in PR(RTS) do
            t:draw()
        end
    end
end
