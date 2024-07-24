-- This handler computes the area of a circle from its radius.
-- (The area of a circle is equal to pi times its radius squared.)
on areaOfCircle from radius
    -- Make sure the parameter is a real number or an integer.
    if class of radius is contained by {integer, real}
        return radius * radius * pi -- pi is predefined by AppleScript.
    else
        error "The parameter must be a real number or an integer"
    end if
end areaOfCircle
 
 
-- This handler returns the factorial of a number.
on factorial(x)
    set returnVal to 1
    if x > 1 then
        repeat with n from 2 to x
            set returnVal to returnVal * n
        end repeat
    end if
    return returnVal
end factorial
