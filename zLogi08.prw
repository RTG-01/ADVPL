//Bibliotecas
#Include "Totvs.ch"

/*/{Protheus.doc} zLogi08
Demonstrando arrays em AdvPL
@author Atilio
@since 24/02/2020
@version 1.0
@type function
@see https://tdn.totvs.com/display/tec/Matrizes
/*/

User Function zLogi08()
Local aArea := GetArea()
Local aNomes := {}
Local aPessoa := {}
Local aSobreNome := Array(3)
Local nAtual 

aAdd(aNomes, "rafael")
aAdd(aNomes, "Pereira")

aSobreNome[1] := "Atilio"
aSobreNome[2] := "de Informação"
Alert(aNomes[1] +""+ ASobreNome[1])

//Arry Multidimensional
aAdd(aPessoa,{"Rafael",sToD("15/02/1990"),"Itapevi"})
aAdd(aPessoa,{"Atilio",sToD("20/10/1985"),"São Paulo"})
aAdd(aPessoa,{"Maria",sToD("05/06/1995"),"Rio de Janeiro"})

for nAtual := 1 to Len(aPessoa)
 //  alert(aPessoa[nAtual][1] + " - " + DToS(aPessoa[nAtual][2]) + " - " + aPessoa[nAtual][3])
next

//inserindo elementos no Array
aSize(aPessoa, Len(aPessoa) + 1)
aIns(aPessoa, 1)
aPessoa[1] := {"Terminal de Informacao", sToD("20120808", "Internet")}
Alert("Linha 2, Coluna 1: " + aPessoa[2][1])

//Procurando um elemento no array

nPos := aScan(aPessoa, {|x| AllTrim(Upper(x[1])) == "JOAO"})
If nPos > 0
    //MsgInfo("Joao encontrado, na linha " + cValToChar(nPos) + ".", "Atencao")
Else
    //MsgAlert("Joao nao foi encontrado!", "Atencao")

EndIf

//Excluindo elemento no
aDel(aPessoa, nPos)
aSize(aPessoa, Len(aPessoa) - 1)
Alert("Array aPessoa com " + cValToChar(Len(aPessoa)) + " linhas")


RestArea(aArea)
Return
