#include 'protheus.ch'
#include 'parmtype.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} Acervo
Rotina de cadastro do acervo

@author Renan Guedes
@since 12/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Acervo()
	Private aRotina			:= MenuDef()		//Fun��o de op��es do menu da rotina
	Private cAlias 			:= "SZ4"			//Alias padr�o da rotina
	Private cCadastro		:= "Acervo"			//T�tulo da rotina
	Private nTamZ5Codigo	:= 0
	Private nTamZ7Exem		:= 0

	BEGIN SEQUENCE

		//Verifica se as tabelas necess�rias existem no dicion�rio de dados
		if !AliasInDic("SZ4") .Or. !AliasInDic("SZ5")
			ShowHelpDlg("SX",{"Dicion�rio de dados desatualizado."},5,{"Atualize o dicion�rio de dados para usar esta rotina."},5)
			BREAK
		endif

		nTamZ5Codigo := TamSX3("Z5_CODIGO")[1]
		nTamZ7Exem := TamSX3("Z7_EXEMPLA")[1]

		dbSelectArea("SZ4")
		SZ4->(dbSetOrder(1))		//Z4_CODIGO+Z4_TITULO

		dbSelectArea("SZ5")
		SZ5->(dbSetOrder(1))		//Z5_ACERVO+Z5_CODIGO

		mBrowse(6,1,22,75,cAlias)		//Browse padr�o

	END SEQUENCE

return


//--------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Fun��o de menu da rotina de cadastro de acervo

@author Renan Guedes
@since 12/12/2017
@version 1

@return aRotina,Matriz contendo as op��es de menu da rotina de cadastro de acervo
/*/
//--------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina		:= {}

	AADD(aRotina,{"Pesquisar"	,"AxPesqui"						,0,1})
	AADD(aRotina,{"Visualizar"	,"StaticCall(Acervo,fManut,2)"	,0,2})
	AADD(aRotina,{"Incluir"		,"StaticCall(Acervo,fManut,3)"	,0,3})
	AADD(aRotina,{"Alterar"		,"StaticCall(Acervo,fManut,4)"	,0,4})
	AADD(aRotina,{"Excluir"		,"StaticCall(Acervo,fManut,5)"	,0,5})

Return aRotina


//--------------------------------------------------------------------
/*/{Protheus.doc} fManut
Fun��o de manuten��o do cadastro de acervo

@author Renan Guedes
@since 12/12/2017
@version 1

@param nOpc,Numerico,N�mero da op��o de menu
/*/
//--------------------------------------------------------------------
Static Function fManut(nOpc)
	Local cSeekKey		:= ""
	Local cWhile		:= "SZ5->Z5_ACERVO"
	Local aNoFields		:= {}
	Local bAfterCols	:= Nil
	Local lOk			:= .F.

	Private aHeader		:= {}
	Private aCols		:= {}
	Private aColsSave	:= {}

	Default nOpc		:= 0

	RegToMemory("SZ4",nOpc == 3)		//Carrega os campos do cabe�alho para a mem�ria

	cSeekKey := M->Z4_CODIGO

	AADD(aNoFields,"Z5_ACERVO")		//Campos que n�o ser�o exibidos nos itens

	If nOpc == 3 .Or. nOpc == 4
		bAfterCols := {|| .T.}
	EndIf

	If FillGetDados(nOpc,"SZ5",1,cSeekKey,{|| &cWhile},,aNoFields,,,,,nOpc == 3,,,bAfterCols)		//Carrega o aHeader e aCols
		If nOpc == 4
			aColsSave := AClone(aCols)
		EndIf

		lOk := Modelo3(cCadastro,"SZ4","SZ5",,"StaticCall(Acervo,fLinhaOk," + cValToChar(nOpc) + ")",,nOpc,nOpc,,.T.,999,,,,,225)		//Janela de cadastro padr�o cabe�alho e itens com tabelas diferentes
	EndIf

	If lOk .And. nOpc != 2
		lOk := fGrava(nOpc)		//Grava��o do cadastro de acervo
	EndIf

	//Atualiza as reservas
		If lOk
			ConfirmSx8()		//Confirma as reservas
		Else
			RollBackSX8()		//Desfaz as reservas
		EndIf

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fGrava
Fun��o de grava��o do cadastro de acervo

@author Renan Guedes
@since 12/12/2017
@version 1

@param nOpc,Numerico,N�mero da op��o de menu
/*/
//--------------------------------------------------------------------
Static Function fGrava(nOpc)
	Local lRet			:= .T.
	Local nLinha		:= 0
	Local nPosCodigo	:= AScan(aHeader,{|x| AllTrim(x[2]) == "Z5_CODIGO"})		//Posi��o do c�digo do exemplar nas colunas dos itens
	Local nPosEmp		:= AScan(aHeader,{|x| AllTrim(x[2]) == "Z5_EMPREST"})		//Posi��o do flag de exemplar emprestado nas colunas dos itens
	Local nPosBloq		:= AScan(aHeader,{|x| AllTrim(x[2]) == "Z5_MSBLQL"})		//Posi��o do flag de exemplar bloqueado nas colunas dos itens
	Local lNovo			:= .T.

	Default nOpc		:= 0

	BeginTran()		//Controle de transa��o

	Do Case
		Case nOpc == 3		//Inclus�o
		If Reclock("SZ4",.T.)
			SZ4->Z4_FILIAL	:= xFilial("SZ4")
			SZ4->Z4_CODIGO	:= M->Z4_CODIGO
			SZ4->Z4_TIPO	:= M->Z4_TIPO
			SZ4->Z4_TITULO	:= M->Z4_TITULO
			SZ4->Z4_AUTOR	:= M->Z4_AUTOR
			SZ4->Z4_EDITORA	:= M->Z4_EDITORA
			SZ4->Z4_EDICAO	:= M->Z4_EDICAO
			SZ4->Z4_ANO		:= M->Z4_ANO
			SZ4->Z4_ISBN	:= M->Z4_ISBN
			SZ4->Z4_PAGINAS	:= M->Z4_PAGINAS
			SZ4->Z4_DEVPREV	:= M->Z4_DEVPREV

			SZ4->(MsUnlock())

			For nLinha := 1 To Len(aCols)
				If !aCols[nLinha,Len(aHeader) + 1]
					If Reclock("SZ5",.T.)
						SZ5->Z5_FILIAL	:= xFilial("SZ5")
						SZ5->Z5_ACERVO	:= M->Z4_CODIGO
						SZ5->Z5_CODIGO	:= aCols[nLinha,nPosCodigo]
						SZ5->Z5_EMPREST	:= aCols[nLinha,nPosEmp]
						SZ5->Z5_MSBLQL	:= aCols[nLinha,nPosBloq]

						SZ5->(MsUnlock())
					Else
						lRet := .F.
					EndIf
				EndIf
			Next nLinha
		Else
			lRet := .F.
		EndIf
		Case nOpc == 4		//Altera��o
		If Reclock("SZ4",.F.)
			SZ4->Z4_TIPO	:= M->Z4_TIPO
			SZ4->Z4_TITULO	:= M->Z4_TITULO
			SZ4->Z4_AUTOR	:= M->Z4_AUTOR
			SZ4->Z4_EDITORA	:= M->Z4_EDITORA
			SZ4->Z4_EDICAO	:= M->Z4_EDICAO
			SZ4->Z4_ANO		:= M->Z4_ANO
			SZ4->Z4_ISBN	:= M->Z4_ISBN
			SZ4->Z4_PAGINAS	:= M->Z4_PAGINAS
			SZ4->Z4_DEVPREV	:= M->Z4_DEVPREV

			SZ4->(MsUnlock())

			For nLinha := 1 To Len(aCols)
				lNovo := .T.

				If Len(aColsSave) >= nLinha
					lNovo := !SZ5->(MsSeek(M->Z4_CODIGO + PADR(aColsSave[nLinha,nPosCodigo],nTamZ5Codigo)))
				EndIf

				If Reclock("SZ5",lNovo)
					If aCols[nLinha,Len(aHeader) + 1]
						SZ5->(dbDelete())
					Else
						SZ5->Z5_FILIAL	:= xFilial("SZ5")
						SZ5->Z5_ACERVO	:= M->Z4_CODIGO
						SZ5->Z5_CODIGO	:= aCols[nLinha,nPosCodigo]
						SZ5->Z5_EMPREST	:= aCols[nLinha,nPosEmp]
						SZ5->Z5_MSBLQL	:= aCols[nLinha,nPosBloq]
					EndIf

					SZ5->(MsUnlock())
				Else
					lRet := .F.
				EndIf
			Next nLinha
		Else
			lRet := .F.
		EndIf
		Case nOpc == 5		//Exclus�o
		dbSelectArea("SZ5")
		SZ5->(dbSetOrder(1))		//Z5_ACERVO+Z5_CODIGO

		//Exclui todos os registros dos exemplares
		If SZ5->(MsSeek(M->Z4_CODIGO))
			While !SZ5->(Eof()) .And. SZ5->Z5_ACERVO == M->Z4_CODIGO
				If Reclock("SZ5",.F.)
					SZ5->(dbDelete())

					SZ5->(MsUnlock())
				Else
					lRet := .F.
				EndIf

				SZ5->(dbSkip())
			End
		EndIf

		dbSelectArea("SZ4")

		If lRet
			//Exclui o registro do acervo
			If Reclock("SZ4",.F.)
				SZ4->(dbDelete())

				SZ4->(MsUnlock())
			Else
				lRet := .F.
			EndIf
		EndIf
	EndCase

	If !lRet
		DisarmTransaction()		//Controle de transa��o
	EndIf

	EndTran()		//Controle de transa��o

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fLinhaOk
Fun��o de valida��o da linha (exemplar) do cadastro de acervo

@author Renan Guedes
@since 12/12/2017
@version 1

@param nOpc,Numerico,N�mero da op��o de menu

@return lRet,Indica se a linha (exemplar) � v�lida
/*/
//--------------------------------------------------------------------
Static Function fLinhaOk(nOpc)
	Local lRet			:= .T.
	Local aArea			:= GetArea()
	Local aAreaSZ7		:= {}
	Local nLinha		:= 0
	Local nPosCodigo	:= AScan(aHeader,{|x| AllTrim(x[2]) == "Z5_CODIGO"})		//Posi��o do c�digo do exemplar nas colunas dos itens
	Local lNovo			:= .T.
	Local cCodigo		:= ""

	Default nOpc		:= 0

	dbSelectArea("SZ7")
	aAreaSZ7 := SZ7->(GetArea())
	SZ7->(dbSetOrder(2))		//Z7_EXEMPLA+Z7_PROTOCO

	BEGIN SEQUENCE

		If nOpc != 5
			If nPosCodigo > 0
				cCodigo := AllTrim(aCols[n,nPosCodigo])

				If !aCols[n,Len(aHeader) + 1]
					//Verifica se n�o h� c�digos de exemplares repetidos
					For nLinha := 1 To Len(aCols)
						If !aCols[nLinha,Len(aHeader) + 1]
							If nLinha != n
								If AllTrim(aCols[nLinha,nPosCodigo]) == cCodigo
									lRet := .F.
									ShowHelpDlg("C�digo",{"Linha " + cValToChar(n) + ": c�digo " + cCodigo + " j� informado na linha " + cValToChar(nLinha) + "."},5,{"Informe um c�digo diferente para o exemplar."},5)
									BREAK
								EndIf
							EndIf
						EndIf
					Next nLinha

					//Verifica se o c�digo do exemplar pode ser alterado
					If nOpc == 4
						If Len(aColsSave) >= n
							If cCodigo != AllTrim(aColsSave[n,nPosCodigo])
								If SZ7->(MsSeek(PADR(aColsSave[n,nPosCodigo],nTamZ7Exem)))
									lRet := .F.
									ShowHelpDlg("Empr�stimo",{"Linha " + cValToChar(n) + ": c�digo " + AllTrim(aColsSave[n,nPosCodigo]) + " n�o pode ser alterado pois est� vinculado a um empr�stimo."},5,{"Para desabilitar o exemplar, marque-o como 'bloqueado'."},5)
									BREAK
								EndIf
							EndIf
						EndIf
					EndIf
				Else
					//Verifica se o exemplar pode ser exclu�do
					If nOpc == 4
						If Len(aColsSave) >= n
							cCodigo := aColsSave[n,nPosCodigo]
						EndIf

						If SZ7->(MsSeek(PADR(cCodigo,nTamZ7Exem)))
							lRet := .F.
							ShowHelpDlg("Empr�stimo",{"Linha " + cValToChar(n) + ": exemplar n�o pode ser exclu�do pois est� vinculado a um empr�stimo."},5,{"Para desabilitar o exemplar, marque-o como 'bloqueado'."},5)
							BREAK
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

	END SEQUENCE

	RestArea(aArea)

Return lRet