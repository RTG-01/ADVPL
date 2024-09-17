#include 'protheus.ch'
#include 'parmtype.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} Editoras
Rotina de cadastro de editoras

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Editoras()
	Private aRotina		:= MenuDef()		//Função de opções do menu da rotina
	Private cAlias 		:= "SZ3"			//Alias padrão da rotina
	Private cCadastro	:= "Editoras"		//Título da rotina
	Private aSize		:= MsAdvSize()

	BEGIN SEQUENCE

		//Verifica se as tabelas necessárias existem no dicionário de dados
		if !AliasInDic("SZ3")
			ShowHelpDlg("SX",{"Dicionário de dados desatualizado."},5,{"Atualize o dicionário de dados para usar esta rotina."},5)
			BREAK
		endif

		dbSelectArea("SZ3")
		SZ3->(dbSetOrder(1))		//Z3_CODIGO+Z3_NOME

		mBrowse(6,1,22,75,cAlias)		//Browse padrão

	END SEQUENCE

return


//--------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Função de menu da rotina de cadastro de editoras

@author Renan Guedes
@since 18/12/2017
@version 1

@return aRotina,Matriz contendo as opções de menu da rotina de cadastro de editoras
/*/
//--------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina		:= {}

	AADD(aRotina,{"Pesquisar"	,"AxPesqui"							,0,1})
	AADD(aRotina,{"Visualizar"	,"AxVisual"							,0,2})
	AADD(aRotina,{"Incluir"		,"StaticCall(Editoras,fManut,3)"	,0,3})
	AADD(aRotina,{"Alterar"		,"StaticCall(Editoras,fManut,4)"	,0,4})
	AADD(aRotina,{"Excluir"		,"StaticCall(Editoras,fManut,5)"	,0,5})

Return aRotina


//--------------------------------------------------------------------
/*/{Protheus.doc} fManut
Função de manutenção do cadastro de editoras

@author Renan Guedes
@since 18/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu
/*/
//--------------------------------------------------------------------
Static Function fManut(nOpc)
	Local nReg			:= 0
	Local oDlg			:= Nil
	Local lOk			:= .F.
	Local bOk			:= {|| IIF(fTudoOk(nOpc),(lOk := .T.,oDlg:End()),)}
	Local bCancel		:= {|| oDlg:End()}
	Local aButtons		:= {}
	Local oEnc			:= Nil
	Local lGrava		:= .F.

	Private aTela[0][0]
	Private aGets[0]

	Default nOpc		:= 0

	If nOpc != 3
		nReg := SZ3->(Recno())
	EndIf

	DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL		//Cria uma janela do tamanho da área de trabalho

	RegToMemory("SZ3",nOpc == 3)		//Carrega os campos para a memória

	//Cria uma enchoice (painel de cadastro) na janela criada
	oEnc := MsMGet():New("SZ3",nReg,nOpc,,,,,{0,0,0,0},,,,,,oDlg)
	oEnc:oBox:Align	:= CONTROL_ALIGN_ALLCLIENT

	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,bOk,bCancel,,aButtons)

	If lOk .And. nOpc != 2
		lOk := fGrava(nOpc)		//Gravação do cadastro de editora
	EndIf

	//Atualiza as reservas
		If lOk
			ConfirmSx8()		//Confirma as reservas
		Else
			RollBackSX8()		//Desfaz as reservas
		EndIf

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fTudoOk
Função de validação da manutenção do cadastro de editoras

@author Renan Guedes
@since 18/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu

@return lRet,Indica se a manutenção é permitida
/*/
//--------------------------------------------------------------------
Static Function fTudoOk(nOpc)
	Local lRet			:= .F.
	Local aArea			:= GetArea()
	Local aAreaSZ4		:= {}

	Default nOpc		:= 0

	BEGIN SEQUENCE

		If nOpc == 5		//Exclusão
			If AliasInDic("SZ4")
				dbSelectArea("SZ4")
				aAreaSZ4 := SZ4->(GetArea())
				SZ4->(dbSetOrder(8))		//Z4_AUTOR+Z4_CODIGO

				//Verifica se a editora está vinculada a algum acervo
				If SZ4->(MsSeek(SZ3->Z3_CODIGO))
					ShowHelpDlg("Acervo",{"Não é possível excluir editora que pertence ao acervo."},5,{"Somente editoras sem vínculo com acervo podem ser excluídas."},5)
					BREAK
				EndIf

				RestArea(aAreaSZ4)
			EndIf
		Else
			//Inclusão ou alteração
			If !Obrigatorio(aGets,aTela)		//Valida todos os campos obrigatórios
				BREAK
			EndIf
		EndIf

		lRet := .T.

	END SEQUENCE

	RestArea(aArea)

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fGrava
Função de gravação da manutenção do cadastro de editoras

@author Renan Guedes
@since 18/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu

@return lRet,Indica se o registro da editora foi gravado/excluído
/*/
//--------------------------------------------------------------------
Static Function fGrava(nOpc)
	Local lRet			:= .T.

	Default nOpc		:= 0

	If Reclock("SZ3",nOpc == 3)
		If nOpc == 5
			SZ3->(dbDelete())		//Exclusão
		Else
			//Inclusão ou alteração
			SZ3->Z3_FILIAL	:= xFilial("SZ3")
			SZ3->Z3_CODIGO	:= M->Z3_CODIGO
			SZ3->Z3_NOME	:= M->Z3_NOME
			SZ3->Z3_CNPJ	:= M->Z3_CNPJ
			SZ3->Z3_CONTATO	:= M->Z3_CONTATO
			SZ3->Z3_EMAIL	:= M->Z3_EMAIL
			SZ3->Z3_LOGRADO	:= M->Z3_LOGRADO
			SZ3->Z3_NUMERO	:= M->Z3_NUMERO
			SZ3->Z3_COMPLE	:= M->Z3_COMPLE
			SZ3->Z3_BAIRRO	:= M->Z3_BAIRRO
			SZ3->Z3_MUNICIP	:= M->Z3_MUNICIP
			SZ3->Z3_UF		:= M->Z3_UF
			SZ3->Z3_CEP		:= M->Z3_CEP
			SZ3->Z3_DDD		:= M->Z3_DDD
			SZ3->Z3_TEL		:= M->Z3_TEL
		EndIf

		SZ3->(MsUnlock())
	Else
		lRet := .F.
	EndIf

Return lRet