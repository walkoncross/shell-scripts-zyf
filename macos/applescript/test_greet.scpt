property defaultClientName : "Mary Smith"
 
on greetClient(nameOfClient)
    display dialog ("Hello " & nameOfClient & "!")
end greetClient
 
script testGreet
    greetClient(defaultClientName)
end script
 
run testGreet --result: "Hello Mary Smith!"
greetClient("Joe Jones") --result: "Hello Joe Jones!"
