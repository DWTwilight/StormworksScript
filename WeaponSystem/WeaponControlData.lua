IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

function onTick()
    local guideMethod = IN(2)
    ON(1, IN(1))
    ON(2, guideMethod)
    ON(3, guideMethod == -1 and 0 or IN(guideMethod + 3))
    ON(4, IN(7))
    ON(5, IN(8))

    OB(1, IB(1))
end
