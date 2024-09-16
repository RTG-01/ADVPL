user Function Func1()
Local cVar1 := "local"
Private cVar2 :="Private"

U_func2()

Return

User Function Func2()
Alert(cVar2) //Private
Alert(cVar2) //Local

Return


