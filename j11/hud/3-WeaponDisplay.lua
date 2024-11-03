M = math
TAN = M.tan
AT = M.atan

S = screen
DL = S.drawLine
DR = S.drawRect

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

function RT(id, x, y, z, f, ttl)
    return {
        id = id,
        x = x,
        y = y,
        z = z,
        f = f,
        ttl = ttl,
        locked = false,
        draw = function(t)
            -- check if in front
            if t.z > 0 then
                SC(t.locked and RTLC or RTC)
                local sx, sy = SCR_W / 2 + AT(t.x, t.z) * L - HRTW - 1, SCR_W / 2 + AT(t.y, t.z) * -L - HRTW - 1
                CDR(sx, sy, RTW + 1, RTW + 1)
                if t.f then
                    CDL(sx, sy, sx + RTW + 1, sy + RTW + 1)
                    CDL(sx + RTW + 1, sy, sx, sy + RTW + 1)
                end
            end
        end,
        canLock = function(t)
            local a = AT((t.x ^ 2 + t.y ^ 2) ^ 0.5, t.z)
            return t.z > 0 and a < LA, a
        end
    }
end

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

function onTick()
    OX, OY = IN(6) * LOF / 2, -IN(7) * LOF - COY

    -- get radar data
    local ttl = IN(5)
    for i = 1, 4 do
        local id, x, y, z, f = IN(i), IN(3 * i + 18), IN(3 * i + 19), IN(3 * i + 20), IB(i)
        -- add/update target to list
        if id ~= 0 then
            if RTS[id] ~= nil then
                -- do update
                local t = RTS[id]
                t.x, t.y, t.z, t.ttl, t.f = x, y, z, ttl, f
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

    -- draw radar targets
    for _, t in PR(RTS) do
        t:draw()
    end
end
