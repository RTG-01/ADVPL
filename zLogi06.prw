//Bibliotecas
#Include "Totvs.ch"

//Constantes
#Define STR_NOME "RGP Sistemas"

//Variáveis estáticas
Static dDataHoje := Date()
Static cHoraHoje := Time()

/*/{Protheus.doc} zLogi06
Demonstrando tipos de dados em AdvPL
@author Rafael 
@since 15/10/2025
@version 1.0
@type function
/*/
User Function zLogi06()
	Local aArea := GetArea()
	Local cNome := "Rafael"
	Private cSobreNome := "Goncalves"
	Public _cCidade  := "São Paulo"

//Mostrando variáveis
	MsgInfo(cNome + " " + cSobreNome + " esta em2626265 " + cCidade + " no dia " + dToC(dDataHoje), "Atenção")

//Chamando uma função estática para demonstrar local e private
	fFuncTst()

	RestArea(aArea)
Return

/*/{Protheus.doc} fFuncTst
Função de teste para demonstrar variáveis locais e privadas
@author Atilio
@since 15/02/2020
@version 1.0
@type function
/*/

Static Function fFuncTst()
	Local aArea := GetArea()
	Local cNome := "..."

//Mostrando o nome e sobrenome
	MsgInfo(cNome + " " + cSobreNome, "Atenção")

	RestArea(aArea)
Return







