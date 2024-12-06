M = math
TAN = M.tan
AT = M.atan
SIN = M.sin

S = screen
DL = S.drawLine
DR = S.drawRect
DC = S.drawCircle

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

function CDL(x1, y1, x2, y2)
    DL((x1 + OX) // 1, (y1 + OY) // 1, (x2 + OX) // 1, (y2 + OY) // 1)
end

function CDR(x, y, w, h)
    DR((x + OX) // 1, (y + OY) // 1, w, h)
end

function CDC(x, y, r)
    DC((x + OX) // 1, (y + OY) // 1, r)
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
        curPos = function(t, tickOffset)
            if t.speedL == nil then
                return t.pos[1], t.pos[2], t.pos[3]
            end
            local totalTickOffset = tickOffset + t.ttlF - t.ttl
            return t.pos[1] + t.speedL[1] * totalTickOffset,
                t.pos[2] + t.speedL[2] * totalTickOffset,
                t.pos[3] + t.speedL[3] * totalTickOffset
        end,
        draw = function(t)
            -- check if in front
            local x, y, z = t:curPos(DELAY_C)
            if z > 0 then
                local sx, sy =
                    SCR_W / 2 + (x / z) * L - HRTW - 1,
                    SCR_W / 2 + (y / z) * -L - HRTW - 1
                if t.lockF == 0 then
                    -- not locked
                    SC(RTC)
                elseif t.lockF == 1 then
                    -- locking
                    SC(LOCKB and RTLC or RTC)
                else
                    -- locked
                    SC(RTLC)
                    if BC_REACHABLE then
                        -- draw shoot circle
                        local ox, oy = SCR_W / 2 + L * TAN(BC_OFFSET_YAW), SCR_W / 2 + -L * TAN(BC_OFFSET_PITCH)
                        CDL(ox, oy, sx + HRTW, sy + HRTW)
                        CDC(ox, oy, 3)
                    else
                        -- draw lock line
                        CDL(SCR_W / 2, SCR_W / 2, sx + HRTW, sy + HRTW)
                    end
                end

                CDR(sx, sy, RTW + 1, RTW + 1)
                if t.f then
                    CDL(sx, sy, sx + RTW + 1, sy + RTW + 1)
                    CDL(sx + RTW + 1, sy, sx, sy + RTW + 1)
                end
            end
        end,
        canLock = function(t)
            local x, y, z = t:curPos(DELAY_C)
            if z > 0 and (x ^ 2 + y ^ 2 + z ^ 2) ^ 0.5 <= RANGE * 1000 then
                local a = AT((x ^ 2 + y ^ 2) ^ 0.5, z)
                return a < t.lockF == 2 and LA * 4 or LA, a
            end
            return false, 0
        end
    }
end

DELAY_C = PN("Delay Compensate(ticks)")
SCR_W = PN("Screen Width")
LOF = PN("Look Offset Factor")
COY = PN("Crosshair Offset Y")
FOV = PN("FOV (rad)")
RTW = PN("Rardar Target Width")
LA = PN("Lock Angle(rad)")
HRTW = RTW // 2

CC = H2RGB(PT("Crosshair Color"))
RTC = H2RGB(PT("Rardar Target Color"))
RTLC = H2RGB(PT("Rardar Target Lock Color"))

L = SCR_W / 2 / TAN(FOV / 2)
OX, OY = 0, 0
RTS = {}
LOCK_T = nil
RANGE = 0
LOCKB = false

BC_REACHABLE = false
BC_OFFSET_YAW, BC_OFFSET_PITCH = 0, 0

function onTick()
    BC_REACHABLE = false
    BC_OFFSET_YAW, BC_OFFSET_PITCH = 0, 0

    OX, OY = IN(6) * LOF / 2, -IN(7) * LOF - COY
    local curVid = IN(8)
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

    if IN(9) == 0 then
        -- enable hud lock
        LOCKB = IB(6)
        -- set range
        RANGE = curVid == 1 and 4 or 200

        -- update current lock status
        if LOCK_T ~= nil and LOCK_T.lockF == 2 then
            -- have a locked target
            local canLock, _ = LOCK_T:canLock()
            if IB(5) or not canLock then
                -- cancel lock
                LOCK_T.lockF = 0
                LOCK_T = nil
            end
        else
            -- update current lockable target
            local minA = LA
            local lockableTarget = nil
            for _, t in pairs(RTS) do
                local canLock, a = t:canLock()
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
    else
        ON(1, LOCK_T.lockF == 2 and LOCK_T.id or 0)
        ON(2, LOCK_T.lockF)
        ON(18, curVid)
        if curVid == 1 then
            -- get bc data
            BC_REACHABLE = IB(7)
            BC_OFFSET_YAW, BC_OFFSET_PITCH = IN(13), IN(14)
        end
    end
end

function onDraw()
    -- draw crosshair
    SC(CC)
    local w, h = SCR_W / 2, SCR_W / 2;
    CDL(w - 2, h, w, h)
    CDL(w + 1, h, w + 3, h)
    CDL(w, h - 2, w, h)
    CDL(w, h + 1, w, h + 3)

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
