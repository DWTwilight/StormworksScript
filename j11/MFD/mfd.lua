M = math
MAX = M.max
MIN = M.min

S = screen
DM = S.drawMap
DR = S.drawRect
DRF = S.drawRectF
DL = S.drawLine
DC = S.drawCircle

IN = input.getNumber
IB = input.getBool
ON = output.setNumber

P = property
PT = P.getText
PN = P.getNumber

function AA(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b + 1, a, b + 5)
    DL(a + 2, b + 1, a + 2, b + 5)
end

function CC(a, b)
    DL(a + 1, b, a + 3, b)
    DL(a + 1, b + 4, a + 3, b + 4)
    DL(a, b + 1, a, b + 4)
end

function EE(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function LL(a, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function PP(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
end

function RR(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
    DL(a + 2, b + 3, a + 2, b + 5)
end

function TT(a, b)
    DL(a, b, a + 3, b)
    DL(a + 1, b, a + 1, b + 5)
end

function WW(a, b)
    DL(a, b + 3, a + 3, b + 3)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function CST(a, b, s)
    if s == "A" then
        AA(a, b)
    elseif s == "C" then
        CC(a, b)
    elseif s == "E" then
        EE(a, b)
    elseif s == "L" then
        LL(a, b)
    elseif s == "P" then
        PP(a, b)
    elseif s == "R" then
        RR(a, b)
    elseif s == "T" then
        TT(a, b)
    elseif s == "W" then
        WW(a, b)
    end
end

function STLen(s)
    local len = 0
    for d = 1, string.len(s) do
        local sin = s:sub(d, d)
        if len ~= 0 then
            len = len + 1
        end
        if sin == "." or sin == " " then
            len = len + 1
        else
            len = len + 3
        end
    end
    return len
end

function DST(a, b, c)
    a = math.floor(a)
    b = math.floor(b)
    for d = 1, string.len(c) do
        local sin = c:sub(d, d)
        CST(a, b, sin)
        if sin == "." or sin == " " then
            a = a + 2
        else
            a = a + 4
        end
    end
end

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

function ToggleButton(x, y, w, h, text, color, toggleColor, toggled)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        tlen = STLen(text),
        c = color,
        tc = toggleColor,
        toggled = toggled,
        toggle = function(btn, tx, ty)
            btn.toggled = PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
            return btn.toggled
        end,
        clearToggle = function(btn)
            btn.toggled = false
        end,
        draw = function(btn)
            local c1, c2
            if btn.toggled then
                c1, c2 = btn.tc, btn.c
            else
                c1, c2 = btn.c, btn.tc
            end
            SC(c1)
            DRF(btn.x, btn.y, btn.w, btn.h)
            SC(c2)
            DST(btn.x + btn.w // 2 - btn.tlen // 2, btn.y + (btn.h - 5) / 2, btn.text)
        end
    }
end

TOUCH_FLAG = false
UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")

SELECT_INDEX = 1
TABS = {
    ToggleButton(SCR_W - 34, SCR_H - 7, 17, 7, "CTRL", UC, UC2, true),
    ToggleButton(SCR_W - 17, SCR_H - 7, 17, 7, "WEAP", UC, UC2, false) }

function onTick()
    if IB(1) then
        if not TOUCH_FLAG then
            local tx, ty = IN(3), IN(4)
            -- handle touch
            for i, btn in ipairs(TABS) do
                if btn:toggle(tx, ty) then
                    SELECT_INDEX = i
                end
            end
            -- clear other tabs
            for i, btn in ipairs(TABS) do
                btn.toggled = i == SELECT_INDEX
            end
        end
        TOUCH_FLAG = true
    else
        TOUCH_FLAG = false
    end
    ON(1, SELECT_INDEX)
end

function onDraw()
    for _, btn in ipairs(TABS) do
        btn:draw()
    end
end
