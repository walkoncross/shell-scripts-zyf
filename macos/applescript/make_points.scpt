on makePoint(x, y)
    script thePoint
        property xCoordinate:x
        property yCoordinate:y
    end script
    return thePoint
end makePoint
 
set myPoint to makePoint(10,20)
get xCoordinate of myPoint  --result: 10
get yCoordinate of myPoint  --result: 20
