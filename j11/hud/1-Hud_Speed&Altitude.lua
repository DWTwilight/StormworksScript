SCR = screen
DL = SCR.drawLine
DR = SCR.drawRect
DRF = SCR.drawRectF
DC = SCR.drawCircle
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
at = m.atan

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
    for d = 1, string.len(c) do
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
-- hud config
FOV = PN("FOV (rad)")
HUDW = PN("Hud Width (m)")
HUDD = HUDW / 2 / sin(FOV / 2)
-- speed config
SI = PN("Speed Interval")
SG = PN("Speed Gap (px)")
-- altitude config
AI = PN("Altitude Interval (m)")
AG = PN("Altitude Gap (px)")

function onTick()
    speedX, speedY, speedZ, speed = IN(1), IN(2), IN(3), IN(4) * 3.6
    altitude = IN(5)
    throttle = IN(6)
    vSpeed = IN(7) * 60
end

function getPixOffset(ang)
    return SCR_H * ang / FOV
end

function drawSpeed()
    local w, h = SCR_W / 2, SCR_H / 2
    -- draw current speed
    local s = string.format("%.0f", speed)
    DST(20 - 4 * #s, SCR_H / 2 - 2, s)
    DR(2, SCR_H / 2 - 4, 18, 8)
    -- draw scaleplate
    local si = speed // 1
    -- up
    local int = 5 * SI
    for i = SI - si % SI, 2000, SI do
        local cs = si + i
        local oy = (cs - speed) * SG / SI
        if oy > h - 10 then
            break
        elseif oy > 3 then
            local oh = h - oy
            if cs % int == 0 then
                DL(2, oh, 6, oh)
                if oy > 6 then
                    DST(7, oh - 2, string.format("%d", cs // int))
                end
            else
                DL(2, oh, 4, oh)
            end
        end
    end
    -- down
    for i = si % SI, 2000, SI do
        local cs = si - i
        local oy = (speed - cs) * SG / SI
        if oy > h - 10 or cs < 0 then
            break
        elseif oy > 4 then
            local oh = h + oy
            if cs % int == 0 then
                DL(2, oh, 6, oh)
                if oy > 6 then
                    DST(7, oh - 2, string.format("%d", cs // int))
                end
            else
                DL(2, oh, 4, oh)
            end
        end
    end
    -- draw throttle
    s = string.format("%d", (throttle * 100) // 1)
    DST(0, SCR_H - 9, s)
    local tl = SCR_H - 20
    local l = m.max(1, tl * throttle // 1)
    DRF(0, 10 + tl - l, 2, l)
    -- draw speed vector
    local sz = m.max(speedZ, 10)
    local ox, oy = getPixOffset(at(speedX, sz)), getPixOffset(at(speedY, sz))
    w = w + ox
    h = h - oy
    DC(w, h, 3)
    DL(w, h - 3, w, h - 6)
    DL(w - 3, h, w - 6, h)
    DL(w + 3, h, w + 6, h)
end

function drawAltitude()
    local h = SCR_H / 2
    -- draw current altitude
    local s = string.format("%.0f", altitude)
    DST(SCR_W - 4 * #s + 1, SCR_H / 2 - 2, s)
    DR(SCR_W - 21, SCR_H / 2 - 4, 22, 8)
    -- draw scaleplate
    local ai = altitude // 1
    -- up
    local int = 5 * AI
    for i = AI - ai % AI, 25000, AI do
        local ca = ai + i
        local oy = (ca - altitude) * AG / AI
        if oy > h - 10 then
            break
        elseif oy > 3 then
            local oh = h - oy
            if ca % int == 0 then
                DL(SCR_W - 6, oh, SCR_W - 2, oh)
                if oy > 6 then
                    local as = string.format("%d", ca // int)
                    DST(SCR_W - 6 - #as * 4, oh - 2, as)
                end
            else
                DL(SCR_W - 4, oh, SCR_W - 2, oh)
            end
        end
    end
    -- down
    for i = ai % AI, 25000, AI do
        local ca = ai - i
        local oy = (altitude - ca) * AG / AI
        if oy > h - 10 then
            break
        elseif oy > 4 then
            local oh = h + oy
            if ca % int == 0 then
                DL(SCR_W - 6, oh, SCR_W - 2, oh)
                if oy > 6 then
                    local as = string.format("%d", ca // int)
                    DST(SCR_W - 6 - #as * 4, oh - 2, as)
                end
            else
                DL(SCR_W - 4, oh, SCR_W - 2, oh)
            end
        end
    end
    -- draw vertical speed
    s = string.format("%.0f", vSpeed)
    DST(SCR_W - 4 * #s + 1, SCR_H - 9, s)
    local tl = (SCR_H - 28) / 2
    local l = tl * m.min(1, math.abs(vSpeed) / 50)
    if vSpeed > 0 then
        DRF(SCR_W - 2, 11 + tl - l, 2, l)
    else
        DRF(SCR_W - 2, h + 4, 2, l)
    end
end

function onDraw()
    SCR_W = SCR.getWidth()
    SCR_H = SCR.getHeight()
    SC(C.r, C.g, C.b, T)
    drawSpeed()
    drawAltitude()
end
