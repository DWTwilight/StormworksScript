S = screen
DT = S.drawText
DRF = S.drawRectF
DTAF = S.drawTriangleF
DL = S.drawLine

IN = input.getNumber

function onTick()

end

function onDraw()
    -- erase boarder, put in last draw()
    S.setColor(0, 0, 0)
    DTAF(0, 0, 55, 0, 0, 100)
    DTAF(0, 130, 30, 130, 0, -10)
    DTAF(0, 145, 0, 115, 75, 145)
    DTAF(223, 0, 168, 0, 223, 100)
    DTAF(223, 130, 193, 130, 223, -10)
    DTAF(223, 145, 223, 115, 148, 145)
    DRF(223, 0, 2, 224)
    DRF(0, 145, 224, 224)
end
