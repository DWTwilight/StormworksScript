M = math
MAX = M.max
MIN = M.min
COS = M.cos
SIN = M.sin
AT = M.atan

M2S = map.mapToScreen
S2M = map.screenToMap

S = screen
DM = S.drawMap
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

function PBTN(x, y, w, h, text, color, pressColor, visible, tox, toy, df)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        c = color,
        pc = pressColor,
        pressed = false,
        onPress = false,
        v = visible,
        tox = tox,
        toy = toy,
        df = df, -- custom draw func
        press = function(btn, tx, ty)
            if btn.v then
                local pressed = PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
                btn.onPress = pressed and not btn.pressed
                btn.pressed = pressed
            else
                btn.onPress = false
                btn.pressed = false
            end
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
                if df then
                    df(btn.x + btn.tox, btn.y + btn.toy)
                else
                    DT(btn.x + btn.tox, btn.y + btn.toy, btn.text)
                end
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
SIC = H2RGB(PT("Self Icon Color"))
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
WPC = H2RGB(PT("Waypoint Color"))
WPC2 = H2RGB(PT("Waypoint Press Color"))
DELC = H2RGB(PT("Delete Color"))
FC = H2RGB(PT("Friendly Color"))
ZOOM_F = PN("Zoom Sensitivity")
SMOOTH_F = PN("Smooth Factor")
JWPD = PN("Jump Waypoint Distance")
WPW = PN("Waypoint Width")
ZBD = PN("Zoom Bar Display Duration")
HWPW = WPW // 2

MODE = {
    FREE = 0, -- free mode, not following
    FOLLOW = 1, -- follow self vehicle 
    FOCUS = 2 -- focus on selected target
}
MX, MY, MZ, ZOOM = 0, 0, PN("Initial Zoom"), 0 -- mapPosX, mapPosY, mapZoom, zoom value
MTX, MTY = 0, 0 -- mapTargetPosX, mapTargetPosY
X, Y, YAW = 0, 0, 0 -- vehicleX, vehicleY, vehicleYaw
CUR_MODE = MODE.FOLLOW -- current mode
PRESS_FLAG = false
ZBC = 0 -- zoom bar counter

WPS = {} -- waypoints
RTS = {} -- radar targets
ST = nil -- selected target (Radar/WP)

-- button custom draw
function DZoomIn(x, y)
    DL(x, y + 2, x + 5, y + 2)
    DL(x + 2, y, x + 2, y + 2)
    DL(x + 2, y + 3, x + 2, y + 5)
end

function DZoomOut(x, y)
    DL(x, y + 2, x + 5, y + 2)
end

-- buttons
ZOOM_IN_BTN = PBTN(SCRW - 17, SCRH - 9, 7, 7, "+", UC, UC2, true, 1, 1, DZoomIn)
ZOOM_OUT_BTN = PBTN(SCRW - 9, SCRH - 9, 7, 7, "-", UC, UC2, true, 1, 1, DZoomOut)
RESET_BTN = PBTN(SCRW - 10, 2, 8, 9, "R", UC, UC2, false, 2, 2)
ADD_WP_BTN = PBTN(2, 2, 18, 9, "+WP", WPC, WPC2, true, 2, 2)
CLR_BTN = PBTN(22, 2, 18, 9, "CLR", DELC, WPC2, false, 2, 2)
FCS_BTN = PBTN(2, SCRH - 22, 18, 9, "FCS", UC, UC2, false, 2, 2)
RM_BTN = PBTN(2, SCRH - 11, 13, 9, "RM", DELC, WPC2, false, 2, 2)
BTNS = {ZOOM_IN_BTN, ZOOM_OUT_BTN, RESET_BTN, ADD_WP_BTN, CLR_BTN, FCS_BTN, RM_BTN}

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

function lerp(target, value, gain)
    return value + (target - value) * gain
end

function calZoom(z)
    return 49.9 * (z - 1) ^ 2 + 0.1
end

-- find waypoint by x and y
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

function exitFCS()
    -- check current mode 
    if CUR_MODE == MODE.FOCUS then
        MTX, MTY = ST.x, ST.z
        CUR_MODE = MODE.FREE
    end
end

-- exit focus mode and clear selected target
function clearST()
    exitFCS()
    ST = nil
end

function onTick()
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
            clearST()
        end
    end

    -- update current vehicle status
    X, Y, YAW = IN(18), IN(19), IN(20)

    if IB(5) then
        -- on touch, get touch pixle point
        local tx, ty = IN(21), IN(22)

        -- press buttons
        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        if ZOOM_IN_BTN.pressed then
            -- zoom in btn
            MZ = clamp(MZ + ZOOM_F, 0, 1)
            ZBC = ZBD
        elseif ZOOM_OUT_BTN.pressed then
            -- zoom out btn
            MZ = clamp(MZ - ZOOM_F, 0, 1)
            ZBC = ZBD
        elseif RESET_BTN.onPress then
            -- reset btn
            CUR_MODE = MODE.FOLLOW
        elseif ADD_WP_BTN.onPress then
            -- add waypoint if not duplicated
            local i, _ = fWP(MX, MY)
            if i == -1 then
                TIN(WPS, tar(MX, 0, MY))
            end
        elseif CLR_BTN.onPress then
            -- clear all wps
            WPS = {}
            -- if selected is wp, rm it
            if ST ~= nil and ST.id == nil then
                -- clear selected
                clearST()
            end
        elseif RM_BTN.onPress then
            -- rm selected wp
            local i, _ = fWP(ST.x, ST.z)
            TRM(WPS, i)
            -- clear selected
            clearST()
        elseif FCS_BTN.onPress then
            CUR_MODE = MODE.FOCUS
        elseif not PRESS_FLAG then
            -- check radar targets touch 
            local pressFlag = false
            for _, t in pairs(RTS) do
                if t:press(tx, ty) then
                    pressFlag = true
                    -- exit focus mode
                    exitFCS()
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
                    break
                end
            end

            if not pressFlag then
                -- check waypoint touch
                for i, wp in ipairs(WPS) do
                    if wp:press(tx, ty) then
                        pressFlag = true
                        -- exit focus mode
                        exitFCS()
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
                        break
                    end
                end
            end

            if not pressFlag then
                -- map touch 
                CUR_MODE = MODE.FREE
                MTX, MTY = S2M(MX, MY, ZOOM, SCRW, SCRH, tx, ty)
            end
        end
        PRESS_FLAG = true
    else
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
        PRESS_FLAG = false
        -- keyboard pulse
        if IB(6) then
            CUR_MODE = MODE.FREE
            MTX, MTY = IN(23), IN(24)
        end
    end

    -- update btn visibility
    -- set clear waypoints btn visible if there are wps
    CLR_BTN.v = #WPS > 0
    -- set focus btn visible if selected and not focus mode
    FCS_BTN.v = ST ~= nil and CUR_MODE ~= MODE.FOCUS
    -- set rm btn visible if selected and not radar target
    RM_BTN.v = ST ~= nil and ST.id == nil
    -- set reset btn visible if not follow mode 
    RESET_BTN.v = CUR_MODE ~= MODE.FOLLOW

    -- update MTX, MTY
    if CUR_MODE == MODE.FOLLOW then
        MTX, MTY = X, Y
    elseif CUR_MODE == MODE.FOCUS and ST ~= nil then
        MTX, MTY = ST.x, ST.z
    end

    -- calculate MX, MY, Zoom
    MX = lerp(MTX, MX, SMOOTH_F)
    MY = lerp(MTY, MY, SMOOTH_F)
    ZOOM = calZoom(MZ)

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
    -- set next waypoint data
    if #WPS > 0 then
        local wp = WPS[1]
        OB(2, true)
        ON(5, wp.x)
        ON(6, wp.z)
        local distance = dist(X, Y, wp.x, wp.z)
        ON(7, distance)
        ON(8, AT(wp.x - X, wp.z - Y))
        if distance < JWPD then
            -- remove this waypoint
            TRM(WPS, 1)
        end
    else
        OB(2, false)
        ON(5, 0)
        ON(6, 0)
        ON(7, -1)
        ON(8, 0)
    end
end

function rotate(x, y, r)
    return -x * COS(r) - y * SIN(r), y * COS(r) - x * SIN(r)
end

function onDraw()
    -- draw map
    DM(MX, MY, ZOOM)

    -- draw self icon 
    SC(SIC)
    local sx, sy = M2S(MX, MY, ZOOM, SCRW, SCRH, X, Y)
    local x1, y1 = rotate(0, -5, YAW)
    local x2, y2 = rotate(3, 3, YAW)
    local x3, y3 = rotate(-3, 3, YAW)
    DTAF(sx + x1, sy + y1, sx + x2, sy + y2, sx + x3, sy + y3)

    -- draw waypoint lines
    SC(UC2)
    sx, sy = M2S(MX, MY, ZOOM, SCRW, SCRH, X, Y)
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

    -- draw selected target or next wp distance
    local distance = -1
    if ST ~= nil then
        distance = dist(X, Y, ST.x, ST.z)
    elseif #WPS > 0 then
        local wp = WPS[1]
        distance = dist(X, Y, wp.x, wp.z)
    end
    if distance ~= -1 then
        SC(UC2)
        local distanceText = string.format("%.1f", distance / 1000)
        DT(SCRW - 5 * #distanceText, SCRH - 16, distanceText)
    end

    -- draw zoom bar
    if ZBC > 0 then
        ZBC = ZBC - 1
        local zoomBarHeight = SCRH - 2 * 18
        SC(UC2)
        DRF(SCRW - 5, SCRH - 18, 3, -zoomBarHeight)
        SC(WPC2)
        DRF(SCRW - 5, SCRH - 18, 3, -zoomBarHeight * MZ)
    end

    -- draw buttons
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
