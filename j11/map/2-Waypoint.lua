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

function waypoint(x, y)
    return {
        x = x,
        y = y,
        pressed = false,
        press = function(wp, tx, ty)
            local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, wp.x, wp.y)
            if PIR(tx, ty, sx - HWPW - 1, sy - HWPW - 1, WPW + 2, WPW + 2) then
                wp.pressed = not wp.pressed
                return true
            end
            return false
        end,
        draw = function(wp)
            -- set color
            SC(wp.pressed and WPC2 or WPC)
            -- get screen pos
            local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, wp.x, wp.y)
            DRF(sx - HWPW, sy - HWPW, WPW, WPW)
        end
    }
end

SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
WPC = H2RGB(PT("Waypoint Color"))
WPC2 = H2RGB(PT("Waypoint Press Color"))
DELC = H2RGB(PT("Delete Color"))
WPW = PN("Waypoint Width")
HWPW = WPW // 2
MX, MY, ZOOM = 0, 0, 0 -- mapPosX, mapPosY, mapZoom, zoom value
X, Y = 0, 0            -- vehicleX, vehicleY
WPS = {}
S_WP = nil
FCS_M = false

ADDWP_BTN = PBTN(2, 2, 18, 9, "+WP", WPC, WPC2, true, 2, 2)
CLR_BTN = PBTN(22, 2, 18, 9, "CLR", DELC, WPC2, false, 2, 2)
FCS_BTN = PBTN(2, SCR_H - 22, 18, 9, "FCS", UC, UC2, false, 2, 2)
RM_BTN = PBTN(2, SCR_H - 11, 13, 9, "RM", DELC, WPC2, false, 2, 2)
BTNS = { ADDWP_BTN, CLR_BTN, FCS_BTN, RM_BTN }

function findWP(x, y)
    for i, wp in ipairs(WPS) do
        if wp.x == x and wp.y == y then
            return i, wp
        end
    end
    return -1, nil
end

function onTick()
    -- update map pos and zoom
    MX, MY, ZOOM, X, Y = IN(3), IN(4), IN(5), IN(6), IN(7)

    -- set clear btn visible or not
    CLR_BTN.v = #WPS > 0
    -- set focus btn visible or not
    FCS_BTN.v = S_WP ~= nil and not FCS_M
    -- set rm btn visible or not
    RM_BTN.v = S_WP ~= nil

    if IB(1) then
        -- on touch
        local pressFlag = true
        local tx, ty = IN(1), IN(2)

        -- press buttons
        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        if IB(2) then
            if ADDWP_BTN.pressed then
                -- add waypoint if not duplicated
                local i, _ = findWP(MX, MY)
                if i == -1 then
                    table.insert(WPS, waypoint(MX, MY))
                end
            elseif CLR_BTN.pressed then
                -- clear all wps
                WPS = {}
                S_WP = nil
            elseif FCS_BTN.pressed then
                -- focus on selected wp
                FCS_M = true
            elseif RM_BTN.pressed then
                -- rm selected wp
                local i, _ = findWP(S_WP.x, S_WP.y)
                table.remove(WPS, i)
                S_WP = nil
            else
                pressFlag = false
                -- press wps
                for i, wp in ipairs(WPS) do
                    if wp:press(tx, ty) then
                        pressFlag = true
                        -- check status
                        if wp.pressed then
                            if S_WP ~= nil then
                                -- unpress the previous selected one
                                S_WP.pressed = false
                            end
                            S_WP = wp
                        else
                            -- unpress
                            S_WP = nil
                        end
                        -- unfocus
                        FCS_M = false
                        break
                    end
                end
            end
        end

        if not pressFlag then
            -- pass touch data to next script
            OB(1, true)  -- touch
            OB(2, IB(2)) -- onTouch
            ON(1, tx)    -- tx
            ON(2, ty)    -- ty
        end
    else
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
        -- set touch data
        OB(1, false) -- touch
        OB(2, false) -- onTouch
        ON(1, 0)     -- tx
        ON(2, 0)     -- ty
    end
    ON(3, MX)
    ON(4, MY)
    ON(5, ZOOM)

    -- update focus mode
    FCS_M = FCS_M and S_WP ~= nil and not IB(3)
    OB(3, FCS_M)
    if FCS_M then
        -- focus mode
        -- target x,y,z
        ON(6, S_WP.x)
        ON(7, 0)
        ON(8, S_WP.y)
    end
end

function onDraw()
    -- draw waypoint lines
    SC(UC2)
    local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, X, Y)
    for _, wp in ipairs(WPS) do
        local x, y = M2S(MX, MY, ZOOM, SCR_W, SCR_H, wp.x, wp.y)
        DL(sx, sy, x, y)
        sx, sy = x, y
    end
    -- draw waypoints
    for _, wp in ipairs(WPS) do
        wp:draw()
    end

    -- draw buttons
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
