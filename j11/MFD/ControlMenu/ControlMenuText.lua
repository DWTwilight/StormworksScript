M = math
MAX = M.max
MIN = M.min

S = screen
DM = S.drawMap
DR = S.drawRect
DRF = S.drawRectF
DL = S.drawLine
DC = S.drawCircle

P = property
PT = P.getText

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

function DD(a, b)
    DL(a, b, a + 2, b)
    DL(a, b + 4, a + 2, b + 4)
    DL(a, b, a, b + 5)
    DL(a + 2, b + 1, a + 2, b + 4)
end

function EE(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function FF(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b, a, b + 5)
end

function GG(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 4)
    DL(a + 2, b + 3, a + 2, b + 5)
end

function HH(a, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function II(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 1, b, a + 1, b + 5)
end

function LL(a, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function NN(a, b)
    DL(a, b, a + 3, b)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function OO(a, b)
    DL(a + 1, b, a + 2, b)
    DL(a + 1, b + 4, a + 2, b + 4)
    DL(a, b + 1, a, b + 4)
    DL(a + 2, b + 1, a + 2, b + 4)
end

function PP(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
end

function SS(a, b)
    DL(a + 1, b, a + 3, b)
    DL(a, b + 4, a + 2, b + 4)
    DL(a, b + 1, a + 3, b + 4)
end

function TT(a, b)
    DL(a, b, a + 3, b)
    DL(a + 1, b, a + 1, b + 5)
end

function colon(a, b)
    DL(a, b + 1, a + 1, b + 1)
    DL(a, b + 3, a + 1, b + 3)
end

function CST(a, b, s)
    if s == "A" then
        AA(a, b)
    elseif s == "C" then
        CC(a, b)
    elseif s == "D" then
        DD(a, b)
    elseif s == "E" then
        EE(a, b)
    elseif s == "F" then
        FF(a, b)
    elseif s == "G" then
        GG(a, b)
    elseif s == "H" then
        HH(a, b)
    elseif s == "I" then
        II(a, b)
    elseif s == "L" then
        LL(a, b)
    elseif s == "N" then
        NN(a, b)
    elseif s == "O" then
        OO(a, b)
    elseif s == "P" then
        PP(a, b)
    elseif s == "S" then
        SS(a, b)
    elseif s == "T" then
        TT(a, b)
    elseif s == ":" then
        colon(a, b)
    end
end

function DST(a, b, c)
    a = math.floor(a)
    b = math.floor(b)
    for d = 1, string.len(c) do
        local sin = c:sub(d, d)
        CST(a, b, sin)
        if sin == "." or sin == " " or sin == ":" then
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

UC2 = H2RGB(PT("UI Secondary Color"))

function onDraw()
    -- lables
    SC(UC2)
    DST(0, 1, "AP CONFIG")
    DST(4, 7, "ALT:")
    DST(4, 14, "SPD:")
    DST(4, 21, "HEA:")
end
