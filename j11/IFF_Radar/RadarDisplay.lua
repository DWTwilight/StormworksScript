m = math
atan = m.atan
rad = m.rad

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
    return x >= rectX and y >= rectY and x < rectX + rectW and y < rectY + rectH
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

function calSPos(x, y, z)
    if z < 0 then
        return -SCRW, -SCRW
    end
    if MODE then
        local f = SCRW / 2000 / ZOOM
        return (SCRW / 2 + x * f) // 1, (SCRW - z * f) // 1
    else
        local oxa, oya = atan(x, z), atan(y, z)
        return oxa / FOV_RAD * SCRW + SCRW / 2, -oya / FOV_RAD * SCRW + SCRW / 2
    end
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
            local sx, sy = calSPos(t.x, t.y, t.z)
            if PIR(tx, ty, sx - HTW - 1, sy - HTW - 1, TW + 2, TW + 2) then
                t.pd = not t.pd
                return true
            end
            return false
        end,
        draw = function(t)
            -- get screen pos
            local sx, sy = calSPos(t.x, t.y, t.z)
            if t.pd then
                SC(UC2)
                DRF(sx - HTW - 1, sy - HTW - 1, TW + 2, TW + 2)
            end
            SC(t.f and FC or EC)
            DRF(sx - HTW, sy - HTW, TW, TW)
        end
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

function DM(x, y)
    DT(x, y, "M")
end

SCRW = PN("Screen Width")
ZOOM = PN("Iniital Zoom")
MZOOM = PN("Max Zoom")
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
EC = H2RGB(PT("Enemy Color"))
FC = H2RGB(PT("Friendly Color"))
TW = PN("Target Width")
FOV = PN("Display FOV(dgree)")
FOV_RAD = rad(FOV)
HTW = TW // 2
MODE = true
-- buttons
ZIB = PBTN(SCRW - 17, SCRW - 9, 7, 7, UC, UC2, 1, 1, DZI)
ZOB = PBTN(SCRW - 9, SCRW - 9, 7, 7, UC, UC2, 1, 1, DZO)
MODEB = PBTN(2, SCRW - 11, 8, 9, UC, UC2, 2, 2, DM)
BTNS = { ZIB, ZOB, MODEB }

-- radar targets
RTS = {}
-- selected target
ST = nil
PF = false

function setSelectedST()
    if ST ~= nil then
        ON(1, ST.id)
        ON(2, ST.x)
        ON(3, ST.y)
        ON(4, ST.z)
        OB(1, ST.f)
    else
        ON(1, 0)
        ON(2, 0)
        ON(3, 0)
        ON(4, 0)
        OB(1, false)
    end
end

function onTick()
    if IB(5) then
        -- radar on
        local ttl = IN(5)
        for i = 1, 4 do
            local id, lx, ly, lz, f = IN(i), IN(3 * i + 18), IN(3 * i + 19), IN(3 * i + 20), IB(i)
            -- add/update target to list
            if id ~= 0 then
                if RTS[id] ~= nil then
                    -- do update
                    local t = RTS[id]
                    t.x, t.y, t.z, t.ttl, t.f = lx, ly, lz, ttl, f
                else
                    -- insert new target
                    RTS[id] = tar(lx, ly, lz, id, ttl, f)
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
            if ST ~= nil and ST.id == id then
                -- clear selected
                ST = nil
            end
        end
    else
        -- radar off
        RTS = {}
        ST = nil
    end

    -- handle screen touch
    if IB(6) then
        local px, py = IN(6), IN(7)
        -- press buttons
        if MODE then
            ZIB:p(px, py)
            ZOB:p(px, py)
        end
        MODEB:p(px, py)

        if ZIB.op then
            ZOOM = m.min(MZOOM, ZOOM * 2)
        elseif ZOB.op then
            ZOOM = m.max(1, ZOOM / 2)
        elseif MODEB.op then
            MODE = not MODE
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

    setSelectedST()
end

function onDraw()
    if MODE then
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

        -- draw zoom buttons
        ZIB:draw()
        ZOB:draw()
    else
        -- draw radar lines
        SC(UC2)
        DL(SCRW / 2, 0, SCRW / 2, SCRW)
        DL(0, SCRW / 2, SCRW, SCRW / 2)
        SC(UC)
        DT(2, 2, string.format("%d", FOV / 2))
        DT(SCRW - 10, 2, string.format("%d", FOV / 2))

        -- draw radar targets
        for _, t in PR(RTS) do
            t:draw()
        end
    end
    -- draw mode button
    MODEB:draw()
end
