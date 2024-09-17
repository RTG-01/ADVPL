#include 'protheus.ch'
#include 'parmtype.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} Autores
Rotina de cadastro de autores

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Autores()
	Private aRotina		:= MenuDef()		//Função de opções do menu da rotina
	Private cAlias 		:= "SZ2"			//Alias padrão da rotina
	Private cCadastro	:= "Autores"		//Título da rotina
	Private lTran		:= .F.

	BEGIN SEQUENCE

		//Verifica se as tabelas necessárias existem no dicionário de dados
		if !AliasInDic("SZ2")
			ShowHelpDlg("SX",{"Dicionário de dados desatualizado."},5,{"Atualize o dicionário de dados para usar esta rotina."},5)
			BREAK
		endif

		dbSelectArea("SZ2")
		SZ2->(dbSetOrder(1))		//Z2_CODIGO+Z2_NOME

		mBrowse(6,1,22,75,cAlias)		//Browse padrão

		//Atualiza as reservas
			If lTran
				ConfirmSx8()		//Confirma as reservas
			Else
				RollBackSX8()		//Desfaz as reservas
			EndIf

	END SEQUENCE

return


//--------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Função de menu da rotina de cadastro de autores

@author Renan Guedes
@since 18/12/2017
@version 1

@return aRotina,Matriz contendo as opções de menu da rotina de cadastro de autores
/*/
//--------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina		:= {}

	AADD(aRotina,{"Pesquisar"	,"AxPesqui"						,0,1})
	AADD(aRotina,{"Visualizar"	,"AxVisual"						,0,2})
	AADD(aRotina,{"Incluir"		,"StaticCall(Autores,fInclui)"	,0,3})
	AADD(aRotina,{"Alterar"		,"StaticCall(Autores,fAltera)"	,0,4})
	AADD(aRotina,{"Excluir"		,"StaticCall(Autores,fExclui)"	,0,5})

Return aRotina


//--------------------------------------------------------------------
/*/{Protheus.doc} fInclui
Função de inclusão de autores

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
Static Function fInclui()
	Local nOpcX			:= 0
	
	nOpcX := AxInclui("SZ2",0,3)

	If nOpcX == 1
		lTran := .T.		//Atualiza a variável de controle de uso de reserva na inclusão
	EndIf

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fAltera
Função de alteração de autores

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
Static Function fAltera()
	Local nReg			:= SZ2->(Recno())

	AxAltera("SZ2",nReg,4)

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fExclui
Função de exclusão de autores

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
Static Function fExclui()
	Local aAreaSZ4		:= {}
	Local nReg			:= SZ2->(Recno())

	BEGIN SEQUENCE

		If AliasInDic("SZ4")
			dbSelectArea("SZ4")
			aAreaSZ4 := SZ4->(GetArea())
			SZ4->(dbSetOrder(8))		//Z4_AUTOR+Z4_CODIGO

			//Verifica se o autor está vinculado a algum acervo
			If SZ4->(MsSeek(SZ2->Z2_CODIGO))
				ShowHelpDlg("Acervo",{"Não é possível excluir autor que pertence ao acervo."},5,{"Somente autores sem vínculo com acervo podem ser excluídos."},5)
				BREAK
			EndIf

			RestArea(aAreaSZ4)
		EndIf

		AxDeleta("SZ2",nReg,5)

	END SEQUENCE

Return