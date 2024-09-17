#include 'protheus.ch'
#include 'parmtype.ch'

#DEFINE MAXIMO_EXEMPLARES		003

//--------------------------------------------------------------------
/*/{Protheus.doc} Emprestimos
Rotina de cadastro de empréstimos

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Emprestimos()
	Local aCores			:= {}

	Private aRotina			:= MenuDef()		//Função de opções do menu da rotina
	Private cAlias 			:= "SZ6"			//Alias padrão da rotina
	Private cCadastro		:= "Empréstimo"		//Título da rotina
	Private aSize			:= MsAdvSize()
	Private nTamZ4Codigo	:= 0
	Private nTamZ5Codigo	:= 0
	Private nTamZ7Prot		:= 0

	BEGIN SEQUENCE

		//Verifica se as tabelas necessárias existem no dicionário de dados
		if !AliasInDic("SZ4") .Or. !AliasInDic("SZ5") .Or. !AliasInDic("SZ6") .Or. !AliasInDic("SZ7")
			ShowHelpDlg("SX",{"Dicionário de dados desatualizado."},5,{"Atualize o dicionário de dados para usar esta rotina."},5)
			BREAK
		endif

		nTamZ4Codigo := TamSX3("Z4_CODIGO")[1]
		nTamZ5Codigo := TamSX3("Z5_CODIGO")[1]
		nTamZ7Prot := TamSX3("Z7_PROTOCO")[1]

		dbSelectArea("SZ6")
		SZ6->(dbSetOrder(1))		//Z6_PROTOCO

		dbSelectArea("SZ7")
		SZ7->(dbSetOrder(1))		//Z7_PROTOCO+Z7_EXEMPLA

		//Legenda dos status
		AADD(aCores,{"Z6_STATUS == 'E'",'BR_VERDE'})		//Em aberto
		AADD(aCores,{"Z6_STATUS == 'D'",'BR_AZUL'})			//Devolvido

		mBrowse(6,1,22,75,cAlias,,,,,,aCores)		//Browse padrão com legenda

	END SEQUENCE

return


//--------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Função de menu da rotina de cadastro de empréstimos

@author Renan Guedes
@since 18/12/2017
@version 1

@return aRotina,Matriz contendo as opções de menu da rotina de cadastro de empréstimos
/*/
//--------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina		:= {}

	AADD(aRotina,{"Pesquisar"	,"AxPesqui"								,0,1})
	AADD(aRotina,{"Visualizar"	,"StaticCall(Emprestimos,fManut,2)"		,0,2})
	AADD(aRotina,{"Incluir"		,"StaticCall(Emprestimos,fManut,3)"		,0,3})
	AADD(aRotina,{"Devolver"	,"StaticCall(Emprestimos,fDevolver,4)"	,0,4})
	AADD(aRotina,{"Excluir"		,"StaticCall(Emprestimos,fManut,5)"		,0,5})
	AADD(aRotina,{"Legenda"		,"StaticCall(Emprestimos,fLegenda)"		,0,3})

Return aRotina


//--------------------------------------------------------------------
/*/{Protheus.doc} fLegenda
Função de exibição da legenda dos empréstimos

@author Renan Guedes
@since 18/12/2017
@version 1
/*/
//--------------------------------------------------------------------
Static Function fLegenda()
	Local aLegenda		:= {}

	AADD(aLegenda,{"BR_VERDE"	,"Em aberto"})
	AADD(aLegenda,{"BR_AZUL"	,"Devolvido"})

	BrwLegenda("Legenda","",aLegenda)

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fManut
Função de manutenção do cadastro de empréstimos

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
	Local oPanelProt	:= Nil
	Local oPanelExem	:= Nil
	Local oProtocolo	:= Nil
	Local cSeekKey		:= ""
	Local cWhile		:= "SZ7->Z7_PROTOCO"
	Local aNoFields		:= {}
	Local bAfterCols	:= Nil
	Local lGrava		:= .F.

	Private oExemplares	:= Nil
	Private aHeader		:= {}
	Private aCols		:= {}
	Private aTela[0][0]
	Private aGets[0]

	Default nOpc		:= 0

	If nOpc != 3
		nReg := SZ6->(Recno())
	EndIf

	DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL

	//Cria o painel dos exemplares (getDados)
	oPanelExem := TPanelCSS():New(10,10,"Exemplares",oDlg,,,,,,10,15)
	oPanelExem:Align := CONTROL_ALIGN_ALLCLIENT

	//Cria o painel do cabeçalho (enchoice)
	oPanelProt := TPanelCSS():New(10,10,"Protocolo",oDlg,,,,,,10,85)
	oPanelProt:Align := CONTROL_ALIGN_TOP

	RegToMemory("SZ6",nOpc == 3)

	oProtocolo := MsMGet():New("SZ6",nReg,nOpc,,,,,{0,0,0,0},,,,,,oPanelProt)
	oProtocolo:oBox:Align	:= CONTROL_ALIGN_ALLCLIENT

	cSeekKey := M->Z6_PROTOCO

	If nOpc == 3 .Or. nOpc == 4
		bAfterCols := {|| .T.}
	EndIf

	AADD(aNoFields,"Z7_PROTOCO")

	If FillGetDados(nOpc,"SZ7",1,cSeekKey,{|| &cWhile},,aNoFields,,,,,nOpc == 3,,,bAfterCols)
		oExemplares := MsNewGetDados():New(001,001,001,001,IIF(nOpc != 2,GD_INSERT + GD_UPDATE + GD_DELETE,0),"StaticCall(Emprestimos,fLinhaOk," + cValToChar(nOpc) + ")","AllwaysTrue",,,,MAXIMO_EXEMPLARES,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPanelExem,aHeader,aCols)
		oExemplares:ForceRefresh()
		oExemplares:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	EndIf

	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,bOk,bCancel,,aButtons)

	If lOk .And. nOpc != 2
		lOk := fGrava(nOpc)
	EndIf

	//Atualiza as reservas
	If lOk
		ConfirmSx8()
	Else
		RollBackSX8()
	EndIf

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fTudoOk
Função de validação da manutenção do cadastro de empréstimos

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

	BEGIN SEQUENCE

		//Inclusão ou alteração
		If !Obrigatorio(aGets,aTela)		//Valida todos os campos obrigatórios
			BREAK
		EndIf

		If Type("n") != "N"
			Private n := oExemplares:nAt
		EndIf

		If !fLinhaOk(nOpc)
			BREAK
		EndIf

		lRet := .T.

	END SEQUENCE

	RestArea(aArea)

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fGrava
Função de gravação da manutenção do cadastro de empréstimos

@author Renan Guedes
@since 18/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu

@return lRet,Indica se gravou o empréstimo
/*/
//--------------------------------------------------------------------
Static Function fGrava(nOpc)
	Local lRet			:= .T.
	Local nLinha		:= 0
	Local nPosExem		:= AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_EXEMPLA"})
	Local nPosPrev		:= AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_DEVPREV"})

	Default nOpc		:= 0

	BeginTran()		//Controle de transação

	Do Case
		Case nOpc == 3		//Inclusão
		If Reclock("SZ6",.T.)
			SZ6->Z6_FILIAL	:= xFilial("SZ6")
			SZ6->Z6_PROTOCO	:= M->Z6_PROTOCO
			SZ6->Z6_USUARIO	:= M->Z6_USUARIO
			SZ6->Z6_DATA	:= M->Z6_DATA
			SZ6->Z6_STATUS	:= M->Z6_STATUS

			SZ6->(MsUnlock())

			For nLinha := 1 To Len(oExemplares:aCols)
				If !oExemplares:aCols[nLinha,Len(oExemplares:aHeader) + 1]
					If Reclock("SZ7",.T.)
						SZ7->Z7_FILIAL	:= xFilial("SZ7")
						SZ7->Z7_PROTOCO	:= M->Z6_PROTOCO
						SZ7->Z7_EXEMPLA	:= oExemplares:aCols[nLinha,nPosExem]
						SZ7->Z7_DEVPREV	:= oExemplares:aCols[nLinha,nPosPrev]

						SZ7->(MsUnlock())

						If !fEmpDev(oExemplares:aCols[nLinha,nPosExem],"E")
							lRet := .F.
						EndIf
					Else
						lRet := .F.
					EndIf
				EndIf
			Next nLinha
		Else
			lRet := .F.
		EndIf
		Case nOpc == 5		//Exclusão
		dbSelectArea("SZ7")
		SZ7->(dbSetOrder(1))		//Z7_PROTOCO+Z7_EXEMPLA

		//Exclui todos os registros dos exemplares
		If SZ7->(MsSeek(M->Z6_PROTOCO))
			While !SZ7->(Eof()) .And. SZ7->Z7_PROTOCO == M->Z6_PROTOCO
				If fEmpDev(SZ7->Z7_EXEMPLA,"D")
					If Reclock("SZ7",.F.)
						SZ7->(dbDelete())

						SZ7->(MsUnlock())
					Else
						lRet := .F.
					EndIf
				Else
					lRet := .F.
				EndIf

				SZ7->(dbSkip())
			End
		EndIf

		dbSelectArea("SZ6")

		If lRet
			//Exclui o registro do acervo
			If Reclock("SZ6",.F.)
				SZ6->(dbDelete())

				SZ6->(MsUnlock())
			Else
				lRet := .F.
			EndIf
		EndIf
	EndCase

	If !lRet
		DisarmTransaction()		//Controle de transação
	EndIf

	EndTran()		//Controle de transação

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fLinhaOk
Função de validação da linha (exemplar) do cadastro de empréstimo

@author Renan Guedes
@since 12/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu

@return lRet,Indica se a linha (exemplar) é válida
/*/
//--------------------------------------------------------------------
Static Function fLinhaOk(nOpc)
	Local lRet			:= .T.
	Local aArea			:= GetArea()
	Local aAreaSZ5		:= {}
	Local nLinha		:= 0
	Local nPosExem		:= AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_EXEMPLA"})
	Local cExemplar		:= ""

	Default nOpc		:= 0

	dbSelectArea("SZ5")
	aAreaSZ5 := SZ5->(GetArea())
	SZ5->(dbSetOrder(2))		//Z5_CODIGO+Z5_ACERVO

	BEGIN SEQUENCE

		If nOpc != 5
			If nPosExem > 0
				cExemplar := AllTrim(oExemplares:aCols[oExemplares:nAt,nPosExem])

				If !oExemplares:aCols[oExemplares:nAt,Len(oExemplares:aHeader) + 1]
					//Verifica se não há códigos de exemplares repetidos
					For nLinha := 1 To Len(oExemplares:aCols)
						If !oExemplares:aCols[nLinha,Len(oExemplares:aHeader) + 1]
							If nLinha != n
								If AllTrim(oExemplares:aCols[nLinha,nPosExem]) == cExemplar
									lRet := .F.
									ShowHelpDlg("Exemplar",{"Linha " + cValToChar(n) + ": exemplar " + cExemplar + " já informado na linha " + cValToChar(nLinha) + "."},5,{"Verifique o código do exemplar."},5)
									BREAK
								EndIf
							EndIf
						EndIf
					Next nLinha

					//Verifica se o exemplar está emprestado ou bloqueado
					If SZ5->(MsSeek(PADR(cExemplar,nTamZ5Codigo)))
						If SZ5->Z5_EMPREST == "S"
							lRet := .F.
							ShowHelpDlg("Exemplar",{"Linha " + cValToChar(n) + ": exemplar " + cExemplar + " já emprestado."},5,{"Verifique o código do exemplar."},5)
							BREAK
						EndIf

						If SZ5->Z5_MSBLQL == "1"
							lRet := .F.
							ShowHelpDlg("Exemplar",{"Linha " + cValToChar(n) + ": exemplar " + cExemplar + " bloqueado para empréstimo."},5,{"Verifique o código do exemplar."},5)
							BREAK
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

	END SEQUENCE

	RestArea(aAreaSZ5)
	RestArea(aArea)

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fData
Função de validação da data do empréstimo e cálculo das datas de devolução

@author Renan Guedes
@since 18/12/2017
@version 1

@param dEmp,Data,Data do empréstimo

@return lRet,Indica se a data do empréstimo é válida
/*/
//--------------------------------------------------------------------
Static Function fData(dEmp)
	Local lRet			:= .F.
	Local aArea			:= GetArea()
	Local aAreaSZ4		:= {}
	Local aAreaSZ5		:= {}
	Local nPosExem		:= 0
	Local nPosPrev		:= 0
	Local nLinha		:= 0

	Default dEmp		:= CTOD("")

	BEGIN SEQUENCE

		If dEmp > dDataBase
			ShowHelpDlg("Data",{"A data do empréstimo [" + DTOC(dEmp) + "] não pode ser maior do que a data atual [" + DTOC(dDataBase) + "]."},5,{"Informe uma data igual ou menor do que a atual."},5)
			BREAK
		EndIf

		If Type("oExemplares:aHeader") == "A" .And. Type("oExemplares:aCols") == "A"
			nPosExem := AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_EXEMPLA"})		//Posição do código do exemplar nas colunas dos itens
			nPosPrev := AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_DEVPREV"})		//Posição da data prevista de devolução do exemplar nas colunas dos itens

			If nPosExem > 0 .And. nPosPrev > 0
				dbSelectArea("SZ4")
				aAreaSZ4 := SZ4->(GetArea())
				SZ4->(dbSetOrder(1))		//Z4_CODIGO+Z4_TITULO

				dbSelectArea("SZ5")
				aAreaSZ5 := SZ5->(GetArea())
				SZ5->(dbSetOrder(2))		//Z5_CODIGO+Z5_ACERVO

				For nLinha := 1 To Len(oExemplares:aCols)
					If !oExemplares:aCols[nLinha,Len(oExemplares:aHeader) + 1]
						If SZ5->(MsSeek(oExemplares:aCols[nLinha,nPosExem]))
							If SZ4->(MsSeek(SZ5->Z5_ACERVO))
								oExemplares:aCols[nLinha,nPosPrev] := DataValida(dEmp + SZ4->Z4_DEVPREV,.T.)
							EndIf
						EndIf
					EndIf
				Next nLinha

				RestArea(aAreaSZ5)
				RestArea(aAreaSZ4)
			EndIf
		EndIf

		lRet := .T.

	END SEQUENCE

	RestArea(aArea)

Return lRet



//--------------------------------------------------------------------
/*/{Protheus.doc} fDev
Função de gatilho da data de devolução prevista

@author Renan Guedes
@since 18/12/2017
@version 1

@return dDevPrev,Data prevista da devolução do exemplar
/*/
//--------------------------------------------------------------------
Static Function fDev()
	Local aArea			:= GetArea()
	Local aAreaSZ4		:= {}
	Local aAreaSZ5		:= {}
	Local nPosExem		:= AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_EXEMPLA"})
	Local nPosPrev		:= AScan(oExemplares:aHeader,{|x| AllTrim(x[2]) == "Z7_DEVPREV"})
	Local dDevPrev		:= CTOD("")

	If !Empty(M->Z6_DATA) .And. !Empty(oExemplares:aCols[oExemplares:nAt,nPosExem])
		If nPosExem > 0 .And. nPosPrev > 0
			dbSelectArea("SZ4")
			aAreaSZ4 := SZ4->(GetArea())
			SZ4->(dbSetOrder(1))		//Z4_CODIGO+Z4_TITULO

			dbSelectArea("SZ5")
			aAreaSZ5 := SZ5->(GetArea())
			SZ5->(dbSetOrder(2))		//Z5_CODIGO+Z5_ACERVO

			If !oExemplares:aCols[oExemplares:nAt,Len(oExemplares:aHeader) + 1]
				If SZ5->(MsSeek(oExemplares:aCols[oExemplares:nAt,nPosExem]))
					If SZ4->(MsSeek(SZ5->Z5_ACERVO))
						dDevPrev := DataValida(M->Z6_DATA + SZ4->Z4_DEVPREV,.T.)
					EndIf
				EndIf
			EndIf

			RestArea(aAreaSZ5)
			RestArea(aAreaSZ4)
		EndIf
	EndIf

	RestArea(aArea)

Return dDevPrev


//--------------------------------------------------------------------
/*/{Protheus.doc} fEmpDev
Função de gravação da situação de empréstimo do exemplar

@author Renan Guedes
@since 18/12/2017
@version 1

@return lRet,Indica se gravou a situação de empréstimo do exemplar
/*/
//--------------------------------------------------------------------
Static Function fEmpDev(cCodigo,cEmpDev)
	Local lRet			:= .F.
	Local aArea			:= GetArea()
	Local aAreaSZ5		:= {}
	Local nTamZ5Codigo	:= TamSX3("Z5_CODIGO")[1]
	Local cEmprestado	:= ""

	Default cCodigo		:= ""
	Default cEmpDev		:= ""

	Do Case
		Case cEmpDev == "E"
		cEmprestado := "S"
		Case cEmpDev == "D"
		cEmprestado := "N"
	EndCase

	dbSelectArea("SZ5")
	aAreaSZ5 := SZ5->(GetArea())
	SZ5->(dbSetOrder(2))		//Z5_CODIGO+Z5_ACERVO

	If SZ5->(MsSeek(PADR(cCodigo,nTamZ5Codigo)))
		If Reclock("SZ5",.F.)
			SZ5->Z5_EMPREST := cEmprestado

			SZ5->(MsUnlock())

			lRet := .T.
		EndIf
	EndIf

	RestArea(aAreaSZ5)
	RestArea(aArea)

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fDevolver
Função de devolução de exemplares

@author Renan Guedes
@since 18/12/2017
@version 1

@param nOpc,Numerico,Número da opção de menu
/*/
//--------------------------------------------------------------------
Static Function fDevolver(nOpc)
	Local lRet			:= .T.
	Local aArea			:= GetArea()
	Local aAreaSZ7		:= {}
	Local cVar			:= Nil
	Local cTitulo		:= "Devolução"
	Local oOk			:= LoadBitmap(GetResources(),"CHECKED")
	Local oNo			:= LoadBitmap(GetResources(),"UNCHECKED")
	Local lOk			:= .F.
	Local bOk			:= {|| IIF(fCheckDev(),(lOk := .T.,oDev:End()),)}
	Local bCancel		:= {|| oDev:End()}
	Local aButtons		:= {}
	Local oLbx			:= Nil
	Local oDev			:= Nil
	Local lDev			:= .T.
	Local nItem			:= 0

	Private aVetor		:= {}

	Default nOpc		:= 0

	dbSelectArea("SZ7")
	aAreaSZ7 := SZ7->(GetArea())
	SZ7->(dbSetOrder(1))		//Z7_PROTOCO+Z7_EXEMPLA

	BEGIN SEQUENCE

		If SZ6->Z6_STATUS != "E"
			ShowHelpDlg("Status",{"O empréstimo foi totalmente devolvido."},5,{"A devolução só é possível para empréstimos em aberto."},5)
			BREAK
		EndIf

		If SZ7->(MsSeek(SZ6->Z6_PROTOCO))
			While !SZ7->(Eof()) .And. SZ7->Z7_PROTOCO == SZ6->Z6_PROTOCO
				If Empty(SZ7->Z7_DEVREAL)
					AADD(aVetor,{.F.,SZ7->Z7_EXEMPLA,AllTrim(GetAdvFVal("SZ4","Z4_TITULO",GetAdvFVal("SZ5","Z5_ACERVO",SZ7->Z7_EXEMPLA,2,""),1,"")),SZ7->Z7_DEVPREV})
				EndIf
				SZ7->(dbSkip())
			End
		EndIf

		DEFINE MSDIALOG oDev TITLE cTitulo FROM 0,0 TO 200,500 PIXEL

		@10,10 LISTBOX oLbx VAR cVar FIELDS HEADER " ","Exemplar","Título","Dev. prevista"	SIZE 100,100 OF oDev PIXEL ON dblClick(aVetor[oLbx:nAt,1] := !aVetor[oLbx:nAt,1],oLbx:Refresh())
		oLbx:Align := CONTROL_ALIGN_ALLCLIENT
		oLbx:SetArray(aVetor)
		oLbx:bLine := {|| {IIF(aVetor[oLbx:nAt,1],oOk,oNo),aVetor[oLbx:nAt,2],aVetor[oLbx:nAt,3],aVetor[oLbx:nAt,4]}}

		ACTIVATE MSDIALOG oDev CENTERED ON INIT EnchoiceBar(oDev,bOk,bCancel,,aButtons)

		If lOk
			BeginTran()		//Controle de transação

			For nItem := 1 To Len(aVetor)
				If aVetor[nItem,1]
					If fEmpDev(aVetor[nItem,2],"D")
						If SZ7->(MsSeek(SZ6->Z6_PROTOCO + aVetor[nItem,2]))
							If Reclock("SZ7",.F.)
								SZ7->Z7_DEVREAL := dDataBase
							Else
								lRet := .F.
							EndIf
						Else
							lRet := .F.
						EndIf
					Else
						lRet := .F.
					EndIf
				Else
					lDev := .F.
				EndIf
			Next nItem

			If lDev
				If Reclock("SZ6",.F.)
					SZ6->Z6_STATUS := "D"
				Else
					lRet := .F.
				EndIf
			EndIf

			If !lRet
				DisarmTransaction()		//Controle de transação
			EndIf

			EndTran()		//Controle de transação
		EndIf

	END SEQUENCE

	RestArea(aAreaSZ7)
	RestArea(aArea)

Return


//--------------------------------------------------------------------
/*/{Protheus.doc} fCheckDev
Função de validação da marcação de exemplares para devolução

@author Renan Guedes
@since 18/12/2017
@version 1

@return lRet,Indica se ao menos um exemplar foi marcado
/*/
//--------------------------------------------------------------------
Static Function fCheckDev()
	Local lRet			:= .F.

	AEVal(aVetor,{|Dev| IIF(Dev[1],lRet := .T.,)})

Return lRet