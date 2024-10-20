DL = screen.drawLine;
DR = screen.drawRect;
DC = screen.drawCircle;
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

function AA(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b + 1, a, b + 5)
    DL(a + 2, b + 1, a + 2, b + 5)
end

function BB(a, b)
    DC(a + 1, b + 1, 1)
    DC(a + 1, b + 3, 1)
    DL(a, b, a, b + 5)
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

function JJ(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 2, b, a + 2, b + 5)
    DL(a, b + 3, a, b + 5)
end

function KK(a, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 2)
    DL(a + 2, b + 3, a + 2, b + 5)
end

function LL(a, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function MM(a, b)
    DL(a, b + 1, a + 3, b + 1)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
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

function QQ(a, b)
    DL(a + 1, b, a + 2, b)
    DL(a + 1, b + 3, a + 3, b + 3)
    DL(a, b + 1, a, b + 3)
    DL(a + 2, b + 1, a + 2, b + 5)
end

function RR(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
    DL(a + 2, b + 3, a + 2, b + 5)
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

function UU(a, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function VV(a, b)
    DL(a + 1, b + 3, a + 1, b + 5)
    DL(a, b, a, b + 3)
    DL(a + 2, b, a + 2, b + 3)
end

function WW(a, b)
    DL(a, b + 3, a + 3, b + 3)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function XX(a, b)
    DL(a + 1, b + 2, a + 2, b + 2)
    DL(a, b, a, b + 2)
    DL(a, b + 3, a, b + 5)
    DL(a + 2, b, a + 2, b + 2)
    DL(a + 2, b + 3, a + 2, b + 5)
end

function YY(a, b)
    DL(a, b, a, b + 2)
    DL(a + 2, b, a + 2, b + 2)
    DL(a + 1, b + 2, a + 1, b + 5)
end

function ZZ(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b + 3, a + 3, b)
end

function dot(a, b)
    DL(a, b + 4, a + 1, b + 4)
end

function dash(a, b)
    DL(a, b + 2, a + 3, b + 2)
end

function plus(a, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a + 1, b + 1, a + 1, b + 2)
    DL(a + 1, b + 3, a + 1, b + 4)
end

function colon(a, b)
    DL(a, b + 1, a + 1, b + 1)
    DL(a, b + 3, a + 1, b + 3)
end

function CST(a, b, s)
    if s == "A" then
        AA(a, b)
    elseif s == "B" then
        BB(a, b)
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
    elseif s == "J" then
        JJ(a, b)
    elseif s == "K" then
        KK(a, b)
    elseif s == "L" then
        LL(a, b)
    elseif s == "M" then
        MM(a, b)
    elseif s == "N" then
        NN(a, b)
    elseif s == "O" then
        OO(a, b)
    elseif s == "P" then
        PP(a, b)
    elseif s == "Q" then
        QQ(a, b)
    elseif s == "R" then
        RR(a, b)
    elseif s == "S" then
        SS(a, b)
    elseif s == "T" then
        TT(a, b)
    elseif s == "U" then
        UU(a, b)
    elseif s == "V" then
        VV(a, b)
    elseif s == "W" then
        WW(a, b)
    elseif s == "X" then
        XX(a, b)
    elseif s == "Y" then
        YY(a, b)
    elseif s == "Z" then
        ZZ(a, b)
    elseif s == "0" then
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
    elseif s == "." then
        dot(a, b)
    elseif s == "-" then
        dash(a, b)
    elseif s == "+" then
        plus(a, b)
    elseif s == ":" then
        colon(a, b)
    end
end

function STLen(s)
    local len = 0
    for d = 1, string.len(s) do
        local sin = s:sub(d, d)
        if len ~= 0 then
            len = len + 1
        end
        if sin == "." or sin == " " or sin == ":" then
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
        if sin == "." or sin == " " or sin == ":" then
            a = a + 2
        else
            a = a + 4
        end
    end
end
