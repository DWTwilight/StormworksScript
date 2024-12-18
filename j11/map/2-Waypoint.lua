M2S = map.mapToScreen

S = screen
DRF = S.drawRectF
DT = S.drawText
DL = S.drawLine

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
PT = P.getText

T = table
TRM = T.remove
TIN = T.insert

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

function PBTN(x, y, w, h, text, color, pressColor, visible, tox, toy)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        c = color,
        pc = pressColor,
        pressed = false,
        v = visible,
        tox = tox,
        toy = toy,
        press = function(btn, tx, ty)
            btn.pressed = btn.v and PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
        end,
        clearPress = function(btn)
            btn.onPress = false
            btn.pressed = false
        end,
        draw = function(btn)
            if btn.v then
                local c1, c2
                if btn.pressed then
                    c1, c2 = btn.pc, btn.c
                else
                    c1, c2 = btn.c, btn.pc
                end
                SC(c1)
                DRF(btn.x, btn.y, btn.w, btn.h)
                SC(c2)
                DT(btn.x + btn.tox, btn.y + btn.toy, btn.text)
            end
        end
    }
end

function tar(x, y, z, id, ttl, f)
    return {
        x = x,
        y = y,
        z = z,
        id = id,
        ttl = ttl,
        f = f,
        pressed = false,
        press = function(t, tx, ty)
            local sx, sy = M2S(MX, MY, ZOOM, SCRW, SCRH, t.x, t.z)
            if PIR(tx, ty, sx - HWPW - 1, sy - HWPW - 1, WPW + 2, WPW + 2) then
                t.pressed = not t.pressed
                return true
            end
            return false
        end,
        draw = function(t)
            -- get screen pos
            local sx, sy = M2S(MX, MY, ZOOM, SCRW, SCRH, t.x, t.z)
            if t.id == nil then
                SC(t.pressed and WPC2 or WPC)
            else
                if t.pressed then
                    SC(UC2)
                    DRF(sx - HWPW - 1, sy - HWPW - 1, WPW + 2, WPW + 2)
                end
                SC(t.f and FC or DELC)
            end
            DRF(sx - HWPW, sy - HWPW, WPW, WPW)
        end
    }
end

SCRW, SCRH = PN("Screen Width"), PN("Screen Height")
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
WPC = H2RGB(PT("Waypoint Color"))
WPC2 = H2RGB(PT("Waypoint Press Color"))
DELC = H2RGB(PT("Delete Color"))
FC = H2RGB(PT("Friendly Color"))
JWPD = PN("Jump Waypoint Distance")
WPW = PN("Waypoint Width")
HWPW = WPW // 2
MX, MY, ZOOM = 0, 0, 0 -- mapPosX, mapPosY, mapZoom, zoom value
X, Y = 0, 0            -- vehicleX, vehicleY
WPS = {}
RTS = {}
ST = nil
FCSM = false

AWPB = PBTN(2, 2, 18, 9, "+WP", WPC, WPC2, true, 2, 2)
CLRB = PBTN(22, 2, 18, 9, "CLR", DELC, WPC2, false, 2, 2)
FCSB = PBTN(2, SCRH - 22, 18, 9, "FCS", UC, UC2, false, 2, 2)
RMB = PBTN(2, SCRH - 11, 13, 9, "RM", DELC, WPC2, false, 2, 2)
BTNS = { AWPB, CLRB, FCSB, RMB }

function fWP(x, y)
    for i, wp in ipairs(WPS) do
        if wp.x == x and wp.z == y then
            return i, wp
        end
    end
    return -1, nil
end

function dist(x1, y1, x2, y2)
    return ((x1 - x2) ^ 2 + (y1 - y2) ^ 2) ^ 0.5
end

function onTick()
    -- set default touch data
    OB(3, false) -- touch
    OB(4, false) -- onTouch
    ON(7, 0)     -- tx
    ON(8, 0)     -- ty

    -- read radar data
    for i = 1, 4 do
        local id, x, y, z, ttl, f = IN(i), IN(3 * i + 3), IN(3 * i + 4), IN(3 * i + 5), IN(5), IB(i)
        if id > 0 then
            if RTS[id] ~= nil then
                -- do update
                local t = RTS[id]
                t.x, t.y, t.z, t.ttl, t.f = x, y, z, ttl, f
            else
                RTS[id] = tar(x, y, z, id, ttl, f)
            end
        end
    end
    -- refresh radar data
    local toRM = {}
    for id, t in pairs(RTS) do
        t.ttl = t.ttl - 1
        if t.ttl < 0 then
            TIN(toRM, id)
        end
    end
    for _, id in ipairs(toRM) do
        RTS[id] = nil
        if ST ~= nil and ST.id == id then
            -- clear selected
            ST = nil
        end
    end

    -- update map pos and zoom
    MX, MY, ZOOM, X, Y = IN(28), IN(29), IN(30), IN(31), IN(32)

    -- set clear btn visible or not
    CLRB.v = #WPS > 0
    -- set focus btn visible or not
    FCSB.v = ST ~= nil and not FCSM
    -- set rm btn visible or not
    RMB.v = ST ~= nil and ST.id == nil

    if IB(7) then
        -- on touch
        local pressFlag = true
        local tx, ty = IN(26), IN(27)

        -- press buttons
        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        if IB(8) then
            if AWPB.pressed then
                -- add waypoint if not duplicated
                local i, _ = fWP(MX, MY)
                if i == -1 then
                    TIN(WPS, tar(MX, 0, MY))
                end
            elseif CLRB.pressed then
                -- clear all wps
                WPS = {}
                ST = nil
            elseif FCSB.pressed then
                -- focus on selected wp
                FCSM = true
            elseif RMB.pressed then
                -- rm selected wp
                local i, _ = fWP(ST.x, ST.z)
                TRM(WPS, i)
                ST = nil
            else
                pressFlag = false
                -- press radar targets
                for _, t in pairs(RTS) do
                    if t:press(tx, ty) then
                        pressFlag = true
                        if t.pressed then
                            if ST ~= nil then
                                -- unpress the previous selected one
                                ST.pressed = false
                            end
                            ST = t
                        else
                            -- unpress
                            ST = nil
                        end
                        -- unfocus
                        FCSM = false
                        break
                    end
                end

                if not pressFlag then
                    -- press wps
                    for i, wp in ipairs(WPS) do
                        if wp:press(tx, ty) then
                            pressFlag = true
                            -- check status
                            if wp.pressed then
                                if ST ~= nil then
                                    -- unpress the previous selected one
                                    ST.pressed = false
                                end
                                ST = wp
                            else
                                -- unpress
                                ST = nil
                            end
                            -- unfocus
                            FCSM = false
                            break
                        end
                    end
                end
            end
        end

        if not pressFlag then
            -- pass touch data to next script
            OB(3, true)  -- touch
            OB(4, IB(8)) -- onTouch
            ON(7, tx)    -- tx
            ON(8, ty)    -- ty
        end
    else
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
    end
    ON(9, MX)
    ON(10, MY)
    ON(11, ZOOM)

    -- update focus mode
    FCSM = FCSM and ST ~= nil and not IB(9)
    OB(3, FCSM)
    -- set selected data
    if ST ~= nil then
        -- selected target
        OB(1, true)
        -- target id,x,y,z
        ON(1, ST.id or 0)
        ON(2, ST.x)
        ON(3, ST.y)
        ON(4, ST.z)
    else
        OB(1, false)
        ON(1, 0)
        ON(2, 0)
        ON(3, 0)
        ON(4, 0)
    end
    -- set next waypoint
    if #WPS > 0 then
        local wp = WPS[1]
        OB(2, true)
        ON(5, wp.x)
        ON(6, wp.z)
        local distance = dist(X, Y, wp.x, wp.z)
        ON(12, distance)
        ON(13, math.atan(wp.x - X, wp.z - Y))
        -- check ap & FTWP
        if distance < JWPD then
            -- remove this waypoint
            TRM(WPS, 1)
        end
    else
        OB(2, false)
        ON(5, 0)
        ON(6, 0)
        ON(12, -1)
        ON(13, 0)
    end
end

function onDraw()
    -- draw waypoint lines
    SC(UC2)
    local sx, sy = M2S(MX, MY, ZOOM, SCRW, SCRH, X, Y)
    for _, wp in ipairs(WPS) do
        local x, y = M2S(MX, MY, ZOOM, SCRW, SCRH, wp.x, wp.z)
        DL(sx, sy, x, y)
        sx, sy = x, y
    end
    -- draw waypoints
    for _, wp in ipairs(WPS) do
        wp:draw()
    end

    -- draw radar targets
    for _, t in pairs(RTS) do
        t:draw()
    end

    -- draw buttons
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
