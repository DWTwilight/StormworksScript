S2M = map.screenToMap
M2S = map.mapToScreen

M = math
MAX = M.max
MIN = M.min
COS = M.cos
SIN = M.sin

S = screen
DRF = S.drawRectF
DTAF = S.drawTriangleF
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

function PushButton(x, y, w, h, text, color, pressColor, visible, tox, toy)
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
        draw = function(wp)
            -- set color
            SC(wp.pressed and WPC2 or WPC)
            -- get screen pos
            local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, x, y)
            DRF(sx - WPW / 2, sy - WPW / 2, WPW, WPW)
        end
    }
end

SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")
UC2 = H2RGB(PT("Basic Secondary Color"))
WPC = H2RGB(PT("Waypoint Color"))
WPC2 = H2RGB(PT("Waypoint Press Color"))
DELC = H2RGB(PT("Delete Color"))
WPW = PN("Waypoint Width")
MX, MY, ZOOM = 0, 0, 0 -- mapPosX, mapPosY, mapZoom, zoom value
X, Y = 0, 0            -- vehicleX, vehicleY
WAYPOINTS = {}
TOUCH_FLAG = false

ADD_WP_BTN = PushButton(2, 2, 18, 9, "+WP", WPC, WPC2, true, 2, 2)
CLEAR_ALL_BTN = PushButton(22, 2, 18, 9, "CLR", DELC, WPC2, false, 2, 2)
BTNS = { ADD_WP_BTN, CLEAR_ALL_BTN }

function onTick()
    -- update map pos and zoom
    MX, MY, ZOOM, X, Y = IN(3), IN(4), IN(5), IN(6), IN(7)

    -- set clear btn visible or not
    CLEAR_ALL_BTN.v = #WAYPOINTS > 0

    if IB(1) then
        -- on touch
        local pressFlag = true
        local tx, ty = IN(1), IN(2)

        -- press buttons
        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        if ADD_WP_BTN.pressed and IB(2) then
            -- add waypoint
            table.insert(WAYPOINTS, waypoint(MX, MY))
        elseif CLEAR_ALL_BTN.pressed and IB(2) then
            -- clear all wps
            WAYPOINTS = {}
        else
            pressFlag = false
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
end

function onDraw()
    -- draw waypoint lines
    SC(UC2)
    local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, X, Y)
    for _, wp in ipairs(WAYPOINTS) do
        local x, y = M2S(MX, MY, ZOOM, SCR_W, SCR_H, wp.x, wp.y)
        DL(sx, sy, x, y)
        sx, sy = x, y
    end
    -- draw waypoints
    for _, wp in ipairs(WAYPOINTS) do
        wp:draw()
    end

    -- draw buttons
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
