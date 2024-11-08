SCR = screen
DL = SCR.drawLine
DR = SCR.drawRect
SC = SCR.setColor

IN = input.getNumber
PN = property.getNumber

m = math
pi = m.pi
sin = m.sin
cos = m.cos
tan = m.tan
rad = m.rad
deg = m.deg
abs = m.abs

function D0(a, b)
    DR(a, b, 2, 4)
end

function D1(a, b)
    DL(a + 1, b, a + 1, b + 4)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b + 1, a + 1, b + 1)
end

function D2(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 2, b, a + 2, b + 2)
    DL(a, b + 2, a, b + 4)
end

function D3(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 2, b, a + 2, b + 4)
end

function D4(a, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a + 2, b, a + 2, b + 5)
    DL(a, b, a, b + 2)
end

function D5(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 2)
    DL(a + 2, b + 2, a + 2, b + 4)
end

function D6(a, b)
    DR(a, b + 2, 2, 2)
    DL(a, b, a + 3, b)
    DL(a, b, a, b + 2)
end

function D7(a, b)
    DL(a, b, a + 3, b)
    DL(a + 2, b, a + 2, b + 5)
end

function D8(a, b)
    DR(a, b, 2, 4)
    DL(a, b + 2, a + 3, b + 2)
end

function D9(a, b)
    DR(a, b, 2, 2)
    DL(a + 2, b, a + 2, b + 5)
    DL(a, b + 4, a + 3, b + 4)
end

function dash(a, b)
    DL(a, b + 2, a + 3, b + 2)
end

function CST(a, b, s)
    if s == "0" then
        D0(a, b)
    elseif s == "1" then
        D1(a, b)
    elseif s == "2" then
        D2(a, b)
    elseif s == "3" then
        D3(a, b)
    elseif s == "4" then
        D4(a, b)
    elseif s == "5" then
        D5(a, b)
    elseif s == "6" then
        D6(a, b)
    elseif s == "7" then
        D7(a, b)
    elseif s == "8" then
        D8(a, b)
    elseif s == "9" then
        D9(a, b)
    elseif s == "-" then
        dash(a, b)
    end
end

function DST(a, b, c)
    local l = string.len(c)
    for d = 1, l do
        local s = c:sub(d, d)
        CST(a, b, s)
        a = a + 4
    end
end

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = tonumber("0x" .. e:sub(1, 2)),
        g = tonumber("0x" .. e:sub(3, 4)),
        b = tonumber("0x" .. e:sub(5, 6))
    }
end

-- color
C = H2RGB(property.getText("Main Color"))
T = PN("Transparency")
-- heading config
HG = PN("Heading Gap (px)")
HI = PN("Heading Interval (deg)")
HM = PN("Heading Margin (px)")
-- horizon config
HOI = PN("Horizon Interval (deg)")
HOW = PN("Horizon Width (px)")
HOM = PN("Horizon Margin (px)")
-- hud config
FOV = PN("FOV (rad)")
HUDW = PN("Hud Width (m)")
HUDD = HUDW / 2 / sin(FOV / 2)

function onTick()
    roll, pitch, yaw = IN(1), IN(2), IN(3)
    hAng = (deg(yaw) + 360) % 360
    DTG = IN(4)
end

function rotate(x, y, r)
    local dx, dy = x - SCR_W / 2, -y + SCR_H / 2
    return SCR_W / 2 + dx * cos(r) - dy * sin(r), SCR_H / 2 - dy * cos(r) - dx * sin(r)
end

function CDLR(x1, y1, x2, y2)
    x1, y1 = rotate(x1, y1, roll)
    x2, y2 = rotate(x2, y2, roll)
    DL(x1, y1, x2, y2)
end

function CDSTR(x, y, t)
    x, y = rotate(x, y, roll)
    y = y - 2
    if abs(roll) > pi / 2 then
        x = x + 2
    end
    x = x // 1
    y = y // 1
    DST(x - #t * 2, y, t)
end

function CDDXR(x1, x2, y, gap)
    if x1 > x2 then
        gap = -gap
    end
    for x = x1, x2, gap * 2 do
        CDLR(x, y, x + gap, y)
    end
end

function drawHeading()
    -- draw current heading
    local h = string.format("%.0f", hAng)
    DST((SCR_W - #h * 4) / 2 + 1, 0, h)
    DR(SCR_W / 2 - 7, -2, 14, 8)
    -- draw scaleplate
    -- left
    for i = (hAng // 1) % HI, 180, HI do
        local x = (-i * HG / HI + SCR_W / 2)
        if x < HM then
            break
        end
        local ch = (hAng - i + 360) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if SCR_W / 2 - x > 10 then
                local chs = string.format("%d", ch // 10)
                DST(x - #chs * 2 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end
    -- right
    for i = HI - (hAng // 1) % HI, 180, HI do
        local x = (i * HG / HI + SCR_W / 2)
        if x > SCR_W - HM then
            break
        end
        local ch = (hAng + i) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if x - SCR_W / 2 > 10 then
                local chs = string.format("%d", ch // 10)
                DST(x - #chs * 2 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end
end

function drawPitchLine(ang, d)
    local w, h = SCR_W / 2, SCR_H / 2
    local oy = -HUDD * tan(rad(d)) / (HUDW / 2) * h
    if abs(oy) > h - HOM then
        return false
    end
    oy = h + oy
    if ang > 90 then
        ang = ang - 180
    elseif ang < -90 then
        ang = 180 + ang
    end
    -- draw line
    local a1, a2, a3, a4 = w - HOW / 2, w - HOW / 6, w + HOW / 6 + 1, w + HOW / 2
    if ang >= 0 then
        CDLR(a1, oy, a2, oy)
        CDLR(a4, oy, a3, oy)
        if ang > 0 then
            CDLR(a1, oy, a1, oy + 3)
            CDLR(a4, oy, a4, oy + 3)
        end
    else
        CDDXR(a1, a2, oy, 2)
        CDDXR(a4, a3, oy, 2)
        CDLR(a1, oy, a1, oy - 3)
        CDLR(a4, oy, a4, oy - 3)
    end
    -- draw text
    local t = string.format("%d", ang)
    CDSTR(a1 - #t * 2, oy, t)
    CDSTR(a4 + 2 + #t * 2, oy, t)
    return true
end

function drawHorizon()
    local w, h = SCR_W / 2, SCR_H / 2;
    -- main line
    CDLR(HOM + 7, h, w - 7, h)
    CDLR(SCR_W - HOM - 7, h, w + 7, h)

    DL(w - 2, h, w, h)
    DL(w + 1, h, w + 3, h)
    DL(w, h - 2, w, h)
    DL(w, h + 1, w, h + 3)
    -- draw scaleplate
    local pAng, pi = deg(pitch), deg(pitch) // 1
    -- up
    for d = HOI - pi % HOI, 90, HOI do
        if not drawPitchLine(pi + d, pi + d - pAng) then
            break
        end
    end
    -- down
    for d = pi % HOI, 90, HOI do
        if not drawPitchLine(pi - d, pi - d - pAng) then
            break
        end
    end
end

function onDraw()
    SCR_W = SCR.getWidth()
    SCR_H = SCR.getHeight()
    SC(C.r, C.g, C.b, T)
    drawHorizon()
    drawHeading()
    if DTG < 500 then
        local s = string.format("%.0f", DTG)
        DST(SCR_W - 15 - #s * 4, SCR_H - 5, s)
    end
end
