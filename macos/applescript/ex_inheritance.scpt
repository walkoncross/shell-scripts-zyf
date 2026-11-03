script Alex
    on sayHello()
        return "Hello, " & getName()
    end sayHello
    on getName()
        return "Alex"
    end getName
end script
 
script AlexJunior
    property parent : Alex
    on getName()
        return "Alex Jr"
    end getName
end script
 
-- Sample calls to handlers in the script objects:
tell Alex to sayHello() --result: "Hello, Alex"
tell AlexJunior to sayHello() --result: "Hello, Alex Jr."
 
tell Alex to getName() --result: "Alex"
tell AlexJunior to getName() --result: "Alex Jr"
