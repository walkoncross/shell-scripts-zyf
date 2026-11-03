script John
    property Name: "John"
    property HowManyTimes : 0
 
    to sayHello to someone
        set HowManyTimes to HowManyTimes + 1
        return "Hello " & someone
    end sayHello
 
end script

#tell John to sayHello to "Herb" --result: "Hello Herb"

