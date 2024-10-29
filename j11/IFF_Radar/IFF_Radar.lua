m = math
sin = m.sin
cos = m.cos

S = screen
DRF = S.drawRectF
DL = S.drawLine
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

function PIR(x, y, rectX, rectY, rectW, rectH)
    return x >= rectX and y > rectY and x < rectX + rectW and y <= rectY + rectH
end

function PBTN(x, y, w, h, color, pc, tox, toy, df)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        c = color,
        pc = pc,
        pd = false,
        op = false,
        tox = tox,
        toy = toy,
        df = df,
        p = function(btn, tx, ty)
            local pd = PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
            btn.op = pd and not btn.pd
            btn.pd = pd
        end,
        clearPress = function(btn)
            btn.op = false
            btn.pd = false
        end,
        draw = function(btn)
            local c1, c2
            if btn.pd then
                c1, c2 = btn.pc, btn.c
            else
                c1, c2 = btn.c, btn.pc
            end
            SC(c1)
            DRF(btn.x, btn.y, btn.w, btn.h)
            SC(c2)
            df(btn.x + btn.tox, btn.y + btn.toy)
        end
    }
end

function calSPos(x, y)
    local f = SCRW / 2000 / ZOOM
    return SCRW / 2 + x * f, SCRW - y * f
end

function tar(x, y, z, id, ttl, f)
    return {
        x = x,
        y = y,
        z = z,
        id = id,
        ttl = ttl,
        f = f,
        pd = false,
        p = function(t, tx, ty)
            local sx, sy = calSPos(t.x, t.z)
            if PIR(tx, ty, sx - HTW - 1, sy - HTW - 1, TW + 2, TW + 2) then
                t.pd = not t.pd
                return true
            end
            return false
        end,
        draw = function(t)
            -- get screen pos
            local sx, sy = calSPos(t.x, t.z)
            if t.pd then
                SC(UC2)
                DRF(sx - HTW - 1, sy - HTW - 1, TW + 2, TW + 2)
            end
            SC(t.f and FC or EC)
            DRF(sx - HTW, sy - HTW, TW, TW)
        end
    }
end

function E2Mat(E)
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

function G2L(v, B)
    local p = Mv(B, { v[1], v[3], v[2] })
    return p[1], p[3], p[2]
end

function IFFTarget(id, channel)
    return {
        id = id,
        channel = channel,
        ttl = IFFCC
    }
end

-- button custom draw
function DZI(x, y)
    DL(x, y + 2, x + 5, y + 2)
    DL(x + 2, y, x + 2, y + 2)
    DL(x + 2, y + 3, x + 2, y + 5)
end

function DZO(x, y)
    DL(x, y + 2, x + 5, y + 2)
end

SCRW = PN("Screen Width")
IFFCC = PN("IFF Channel Count")
ZOOM = PN("Iniital Zoom")
MZOOM = PN("Max Zoom")
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
EC = H2RGB(PT("Enemy Color"))
FC = H2RGB(PT("Friendly Color"))
TW = PN("Target Width")
HTW = TW // 2
-- buttons
ZIB = PBTN(SCRW - 17, SCRW - 9, 7, 7, UC, UC2, 1, 1, DZI)
ZOB = PBTN(SCRW - 9, SCRW - 9, 7, 7, UC, UC2, 1, 1, DZO)
BTNS = { ZIB, ZOB }

IFFM = {}
-- radar targets
RTS = {}
-- selected target
ST = nil
PF = false

function SDIFFC()
    for i = 1, IFFCC do
        OB(33 - i, false)
    end
end

function SDRD()
    for i = 1, 17 do
        -- id, ttl, global pos
        ON(i, 0)
    end
    for i = 20, 32 do
        -- local pos
        -- selected id
        ON(i, 0)
    end
    for i = 1, 4 do
        -- is friendly
        OB(i, false)
    end
end

function onTick()
    SDIFFC()
    -- IFF
    if IB(2) then
        -- IFF On
        -- read current IFF Data
        local id, channel = IN(1), IN(2)
        if id ~= 0 then
            IFFM[id] = IFFTarget(id, channel)
        end
        -- refresh IFF_MAPPING
        local toRemove = {}
        for id, t in PR(IFFM) do
            t.ttl = t.ttl - 1
            if t.ttl < 0 then
                table.insert(toRemove, id)
            end
        end
        for _, id in IPR(toRemove) do
            IFFM[id] = nil
        end
        -- set IFF occupied channels
        for _, t in PR(IFFM) do
            OB(33 - t.channel, true)
        end
    else
        -- IFF Off
        IFFM = {}
    end

    SDRD()
    if IB(1) then
        -- radar on
        local ttl, x, y, z, B = IN(19), IN(20), IN(21), IN(22), nil
        for i = 1, 4 do
            local id, tx, ty, tz = IN(4 * i - 1), IN(4 * i), IN(4 * i + 1), IN(4 * i + 2)
            if id > 0 then
                -- set id
                ON(i, id)
                -- set global pos
                ON(3 * i + 3, tx)
                ON(3 * i + 4, ty)
                ON(3 * i + 5, tz)
                -- set local pos
                if B == nil then
                    B = E2Mat({ IN(23), IN(25), IN(24) })
                end
                local lx, ly, lz = G2L({ tx - x, ty - y, tz - z }, B)
                ON(3 * i + 17, lx)
                ON(3 * i + 18, ly)
                ON(3 * i + 19, lz)
                -- set friendly
                local f = IFFM[id] ~= nil
                OB(i, f)

                -- add/update target to list
                if RTS[id] ~= nil then
                    -- do update
                    local t = RTS[id]
                    t.x, t.y, t.z, t.ttl, t.f = lx, ly, lz, ttl, f
                else
                    RTS[id] = tar(lx, ly, lz, id, ttl, f)
                end
            end
        end
        ON(5, ttl)
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
            if ST ~= nil and ST.id == id then
                -- clear selected
                ST = nil
            end
        end

        -- handle screen touch
        if IB(3) then
            local px, py = IN(26) * 3 + 1, IN(27) * 3 + 1
            -- press buttons
            for _, btn in IPR(BTNS) do
                btn:p(px, py)
            end

            if ZIB.op then
                ZOOM = m.min(MZOOM, ZOOM * 2)
            elseif ZOB.op then
                ZOOM = m.max(1, ZOOM / 2)
            elseif not PF then
                -- press radar targets
                for _, t in PR(RTS) do
                    if t:p(px, py) then
                        if t.pd then
                            if ST ~= nil then
                                -- unpress the previous selected one
                                ST.pd = false
                            end
                            ST = t
                        else
                            -- unpress
                            ST = nil
                        end
                        break
                    end
                end
            end
            PF = true
        else
            for _, btn in IPR(BTNS) do
                btn:clearPress()
            end
            PF = false
        end
        if ST ~= nil then
            ON(32, ST.id)
        end
    else
        RTS = {}
        ST = nil
    end
end

function onDraw()
    -- draw radar lines
    SC(UC2)
    DC(SCRW / 2, SCRW, SCRW)
    DC(SCRW / 2, SCRW, SCRW / 2)
    DL(SCRW / 2, SCRW, SCRW / 2, 0)
    DL(SCRW / 2, SCRW, 0, SCRW / 2)
    DL(SCRW / 2, SCRW, SCRW, SCRW / 2)
    SC(UC)
    local z1, z2 = string.format("%d", ZOOM), string.format("%d", ZOOM * 2)
    DT(SCRW - #z1 * 5, SCRW * 0.72, z1)
    DT(SCRW - #z2 * 5, SCRW * (2 - 3 ^ 0.5) / 2 - 7, z2)

    -- draw radar targets
    for _, t in PR(RTS) do
        t:draw()
    end

    -- draw buttons
    for _, btn in IPR(BTNS) do
        btn:draw()
    end
end
