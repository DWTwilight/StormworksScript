M = math
PI = M.pi
PI2 = 2 * PI
SIN = M.sin

IN = input.getNumber
ON = output.setNumber
PN = property.getNumber

CAMERA_PIVOT_OFFSET_FACTOR = PN("Camera Pivot Offset Factor")
CAMERA_PIVOT_OFFSET_Y = PN("Camera Pivot Offset Y")
LOXF = PN("Look Offset X Factor")

function onTick()
    -- camera pivots
    ON(1, SIN(IN(1) * PI2) * CAMERA_PIVOT_OFFSET_FACTOR * LOXF)
    ON(2, SIN(IN(2) * PI2) * CAMERA_PIVOT_OFFSET_FACTOR + CAMERA_PIVOT_OFFSET_Y)
end
