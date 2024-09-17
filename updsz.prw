#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
"    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"+;
"QPushButton:pressed {	color: #FFFFFF; "+;
"    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
"    border-top-width: 3px; "+;
"    border-left-width: 3px; "+;
"    border-right-width: 3px; "+;
"    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDSZ
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDSZ( cEmpAmb, cFilAmb )

	Local   aSay      := {}
	Local   aButton   := {}
	Local   aMarcadas := {}
	Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
	Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
	Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
	Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
	Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
	Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
	Local   cDesc6    := ""
	Local   cDesc7    := ""
	Local   lOk       := .F.
	Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

	Private oMainWnd  := NIL
	Private oProcess  := NIL

	#IFDEF TOP
	TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
	#ENDIF

	__cInterNet := NIL
	__lPYME     := .F.

	Set Dele On

	// Mensagens de Tela Inicial
	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )
	aAdd( aSay, cDesc4 )
	aAdd( aSay, cDesc5 )
	//aAdd( aSay, cDesc6 )
	//aAdd( aSay, cDesc7 )

	// Botoes Tela Inicial
	aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
	aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

	If lAuto
		lOk := .T.
	Else
		FormBatch(  cTitulo,  aSay,  aButton )
	EndIf

	If lOk
		If lAuto
			aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
		Else
			aMarcadas := EscEmpresa()
		EndIf

		If !Empty( aMarcadas )
			If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
				oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
				oProcess:Activate()

				If lAuto
					If lOk
						MsgStop( "Atualização Realizada.", "UPDSZ" )
					Else
						MsgStop( "Atualização não Realizada.", "UPDSZ" )
					EndIf
					dbCloseAll()
				Else
					If lOk
						Final( "Atualização Concluída." )
					Else
						Final( "Atualização não Realizada." )
					EndIf
				EndIf

			Else
				MsgStop( "Atualização não Realizada.", "UPDSZ" )

			EndIf

		Else
			MsgStop( "Atualização não Realizada.", "UPDSZ" )

		EndIf

	EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
	Local   aInfo     := {}
	Local   aRecnoSM0 := {}
	Local   cAux      := ""
	Local   cFile     := ""
	Local   cFileLog  := ""
	Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
	Local   cTCBuild  := "TCGetBuild"
	Local   cTexto    := ""
	Local   cTopBuild := ""
	Local   lOpen     := .F.
	Local   lRet      := .T.
	Local   nI        := 0
	Local   nPos      := 0
	Local   nRecno    := 0
	Local   nX        := 0
	Local   oDlg      := NIL
	Local   oFont     := NIL
	Local   oMemo     := NIL

	Private aArqUpd   := {}

	If ( lOpen := MyOpenSm0(.T.) )

		dbSelectArea( "SM0" )
		dbGoTop()

		While !SM0->( EOF() )
			// Só adiciona no aRecnoSM0 se a empresa for diferente
			If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
			.AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
				aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
			EndIf
			SM0->( dbSkip() )
		End

		SM0->( dbCloseArea() )

		If lOpen

			For nI := 1 To Len( aRecnoSM0 )

				If !( lOpen := MyOpenSm0(.F.) )
					MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
					Exit
				EndIf

				SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

				RpcSetType( 3 )
				RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

				lMsFinalAuto := .F.
				lMsHelpAuto  := .F.

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
				AutoGrLog( Replicate( " ", 128 ) )
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )
				AutoGrLog( " Dados Ambiente" )
				AutoGrLog( " --------------------" )
				AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
				AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
				AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
				AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
				AutoGrLog( " Environment........: " + GetEnvServer()  )
				AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
				AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
				AutoGrLog( " Versão.............: " + GetVersao(.T.) )
				AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
				AutoGrLog( " Computer Name......: " + GetComputerName() )

				aInfo   := GetUserInfo()
				If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
					AutoGrLog( " " )
					AutoGrLog( " Dados Thread" )
					AutoGrLog( " --------------------" )
					AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
					AutoGrLog( " Estação............: " + aInfo[nPos][2] )
					AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
					AutoGrLog( " Environment........: " + aInfo[nPos][6] )
					AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
				EndIf
				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " " )

				If !lAuto
					AutoGrLog( Replicate( "-", 128 ) )
					AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
				EndIf

				oProcess:SetRegua1( 8 )


				oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX2()


				FSAtuSX3()


				oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSIX()

				oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				oProcess:IncRegua2( "Atualizando campos/índices" )

				// Alteração física dos arquivos
				__SetX31Mode( .F. )

				If FindFunction(cTCBuild)
					cTopBuild := &cTCBuild.()
				EndIf

				For nX := 1 To Len( aArqUpd )

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
						!aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
							TcInternal( 25, "CLOB" )
						EndIf
					EndIf

					If Select( aArqUpd[nX] ) > 0
						dbSelectArea( aArqUpd[nX] )
						dbCloseArea()
					EndIf

					X31UpdTable( aArqUpd[nX] )

					If __GetX31Error()
						Alert( __GetX31Trace() )
						MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
						AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
					EndIf

					If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
						TcInternal( 25, "OFF" )
					EndIf

				Next nX


				oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX6()

				oProcess:IncRegua1( "Dicionário de gatilhos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX7()


				oProcess:IncRegua1( "Dicionário de consultas padrão" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSXB()


				oProcess:IncRegua1( "Dicionário de relacionamentos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuSX9()


				oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
				FSAtuHlp()

				AutoGrLog( Replicate( "-", 128 ) )
				AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
				AutoGrLog( Replicate( "-", 128 ) )

				RpcClearEnv()

			Next nI

			If !lAuto

				cTexto := LeLog()

				Define Font oFont Name "Mono AS" Size 5, 12

				Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

				@ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
				oMemo:bRClicked := { || AllwaysTrue() }
				oMemo:oFont     := oFont

				Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
				Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
				MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

				Activate MsDialog oDlg Center

			EndIf

		EndIf

	Else

		lRet := .F.

	EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
	Local aEstrut   := {}
	Local aSX2      := {}
	Local cAlias    := ""
	Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
	Local cEmpr     := ""
	Local cPath     := ""
	Local nI        := 0
	Local nJ        := 0

	AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

	aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
	"X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
	"X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


	dbSelectArea( "SX2" )
	SX2->( dbSetOrder( 1 ) )
	SX2->( dbGoTop() )
	cPath := SX2->X2_PATH
	cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
	cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

	aAdd( aSX2, {'SZ1',cPath,'SZ1'+cEmpr,'USUARIO','USUARIO','USUARIO','C','','','','Z1_CODIGO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ2',cPath,'SZ2'+cEmpr,'AUTOR','AUTOR','AUTOR','C','','','','Z2_CODIGO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ3',cPath,'SZ3'+cEmpr,'EDITORA','EDITORA','EDITORA','C','','','','Z3_CODIGO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ4',cPath,'SZ4'+cEmpr,'ACERVO','ACERVO','ACERVO','C','','','','Z4_CODIGO+Z4_TITULO+Z4_AUTOR+Z4_EDITORA+Z4_ANO+Z4_EDICAO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ5',cPath,'SZ5'+cEmpr,'EXEMPLAR','EXEMPLAR','EXEMPLAR','C','','','','Z5_ACERVO+Z5_CODIGO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ6',cPath,'SZ6'+cEmpr,'EMPRESTIMO','EMPRESTIMO','EMPRESTIMO','C','','','','Z6_PROTOCO','','','','','','','C','C',0} )
	aAdd( aSX2, {'SZ7',cPath,'SZ7'+cEmpr,'ITEM','ITEM','ITEM','C','','','','Z7_PROTOCO+Z7_EXEMPLA','','','','','','','C','C',0} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX2 ) )

	dbSelectArea( "SX2" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSX2 )

		oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

		If !SX2->( dbSeek( aSX2[nI][1] ) )

			If !( aSX2[nI][1] $ cAlias )
				cAlias += aSX2[nI][1] + "/"
				AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
			EndIf

			RecLock( "SX2", .T. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
						FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
					Else
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf
				EndIf
			Next nJ
			MsUnLock()

		Else

			If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
				RecLock( "SX2", .F. )
				SX2->X2_UNICO := aSX2[nI][12]
				MsUnlock()

				If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
					TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
				EndIf

				AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
			EndIf

			RecLock( "SX2", .F. )
			For nJ := 1 To Len( aSX2[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
						FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
					EndIf

				EndIf
			Next nJ
			MsUnLock()

		EndIf

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
	Local aEstrut   := {}
	Local aSX3      := {}
	Local cAlias    := ""
	Local cAliasAtu := ""
	Local cSeqAtu   := ""
	Local cX3Campo  := ""
	Local cX3Dado   := ""
	Local nI        := 0
	Local nJ        := 0
	Local nPosArq   := 0
	Local nPosCpo   := 0
	Local nPosOrd   := 0
	Local nPosSXG   := 0
	Local nPosTam   := 0
	Local nPosVld   := 0
	Local nSeqAtu   := 0
	Local nTamSeek  := Len( SX3->X3_CAMPO )

	AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

	aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
	{ "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
	{ "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
	{ "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
	{ "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
	{ "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
	{ "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

	aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


	aAdd( aSX3, {{'SZ1',.T.},{'01',.T.},{'Z1_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'02',.T.},{'Z1_CODIGO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Código',.T.},{'Código',.T.},{'Código',.T.},{'Código do usuário',.T.},{'Código do usuário',.T.},{'Código do usuário',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(INCLUI,GETSXENUM("SZ1","Z1_CODIGO",,1),M->Z1_CODIGO)',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistChav("SZ1")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'03',.T.},{'Z1_NOME',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome',.T.},{'Nome',.T.},{'Nome',.T.},{'Nome do usuário',.T.},{'Nome do usuário',.T.},{'Nome do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'04',.T.},{'Z1_TIPODOC',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Tipo doc.',.T.},{'Tipo doc.',.T.},{'Tipo doc.',.T.},{'Tipo do documento',.T.},{'Tipo do documento',.T.},{'Tipo do documento',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'1=RG;2=CNH;3=RE;4=Passaporte;5=Outro',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'05',.T.},{'Z1_DOC',.T.},{'C',.T.},{50,.T.},{0,.T.},{'Documento',.T.},{'Número',.T.},{'Número',.T.},{'Número do documento',.T.},{'Número do documento',.T.},{'Número do documento',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'06',.T.},{'Z1_LOGRADO',.T.},{'C',.T.},{250,.T.},{0,.T.},{'Logradouro',.T.},{'Logradouro',.T.},{'Logradouro',.T.},{'Logradouro do usuário',.T.},{'Logradouro do usuário',.T.},{'Logradouro do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'07',.T.},{'Z1_NUMERO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Número',.T.},{'Número',.T.},{'Número',.T.},{'Número do logradouro',.T.},{'Número do logradouro',.T.},{'Número do logradouro',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'08',.T.},{'Z1_COMPLE',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Complemento',.T.},{'Complemento',.T.},{'Complemento',.T.},{'Complemento do logradouro',.T.},{'Complemento do logradouro',.T.},{'Complemento do logradouro',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'09',.T.},{'Z1_BAIRRO',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Bairro',.T.},{'Bairro',.T.},{'Bairro',.T.},{'Bairro do usuário',.T.},{'Bairro do usuário',.T.},{'Bairro do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'10',.T.},{'Z1_MUNICIP',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Município',.T.},{'Município',.T.},{'Município',.T.},{'Município do usuário',.T.},{'Município do usuário',.T.},{'Município do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'11',.T.},{'Z1_UF',.T.},{'C',.T.},{2,.T.},{0,.T.},{'UF',.T.},{'UF',.T.},{'UF',.T.},{'UF do usuário',.T.},{'UF do usuário',.T.},{'UF do usuário',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'12',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SX5","12"+M->Z1_UF)',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'12',.T.},{'Z1_CEP',.T.},{'C',.T.},{8,.T.},{0,.T.},{'CEP',.T.},{'CEP',.T.},{'CEP',.T.},{'CEP do usuário',.T.},{'CEP do usuário',.T.},{'CEP do usuário',.T.},{'@R 99999-999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'13',.T.},{'Z1_GENERO',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Genero',.T.},{'Genero',.T.},{'Genero',.T.},{'Genero do usuário',.T.},{'Genero do usuário',.T.},{'Genero do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'F=Feminino;M=Masculino',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'14',.T.},{'Z1_NASCIME',.T.},{'D',.T.},{8,.T.},{0,.T.},{'Nascimento',.T.},{'Nascimento',.T.},{'Nascimento',.T.},{'Data de nascimento',.T.},{'Data de nascimento',.T.},{'Data de nascimento',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'15',.T.},{'Z1_EMAIL',.T.},{'C',.T.},{150,.T.},{0,.T.},{'e-mail',.T.},{'e-mail',.T.},{'e-mail',.T.},{'e-mail do usuário',.T.},{'e-mail do usuário',.T.},{'e-mail do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'16',.T.},{'Z1_CPF',.T.},{'C',.T.},{11,.T.},{0,.T.},{'CPF',.T.},{'CPF',.T.},{'CPF',.T.},{'CPF do usuário',.T.},{'CPF do usuário',.T.},{'CPF do usuário',.T.},{'@R 999.999.999-99',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'17',.T.},{'Z1_DDDFIXO',.T.},{'C',.T.},{2,.T.},{0,.T.},{'DDD fixo',.T.},{'DDD fixo',.T.},{'DDD fixo',.T.},{'DDD telefone fixo',.T.},{'DDD telefone fixo',.T.},{'DDD telefone fixo',.T.},{'@R 99',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'18',.T.},{'Z1_FIXO',.T.},{'C',.T.},{9,.T.},{0,.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone fixo',.T.},{'Telefone fixo',.T.},{'Telefone fixo',.T.},{'@R 999999999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'19',.T.},{'Z1_DDDCEL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'DDD celular',.T.},{'DDD celular',.T.},{'DDD celular',.T.},{'DDD do telefone celular',.T.},{'DDD do telefone celular',.T.},{'DDD do telefone celular',.T.},{'@R 99',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ1',.T.},{'20',.T.},{'Z1_CELULAR',.T.},{'C',.T.},{9,.T.},{0,.T.},{'Celular',.T.},{'Celular',.T.},{'Celular',.T.},{'Telefone celular',.T.},{'Telefone celular',.T.},{'Telefone celular',.T.},{'@R 999999999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ2',.T.},{'01',.T.},{'Z2_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ2',.T.},{'02',.T.},{'Z2_CODIGO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Código',.T.},{'Código',.T.},{'Código',.T.},{'Código do autor',.T.},{'Código do autor',.T.},{'Código do autor',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(INCLUI,GETSXENUM("SZ2","Z2_CODIGO",,1),M->Z2_CODIGO)',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistChav("SZ2")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ2',.T.},{'03',.T.},{'Z2_TIPO',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Tipo',.T.},{'Tipo',.T.},{'Tipo',.T.},{'Tipo do autor',.T.},{'Tipo do autor',.T.},{'Tipo do autor',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'P=Pessoa;E=Evento;C=Entidade coletiva',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ2',.T.},{'04',.T.},{'Z2_NOME',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome',.T.},{'Nome',.T.},{'Nome',.T.},{'Nome do autor',.T.},{'Nome do autor',.T.},{'Nome do autor',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'01',.T.},{'Z3_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'02',.T.},{'Z3_CODIGO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Código',.T.},{'Código',.T.},{'Código',.T.},{'Código da editora',.T.},{'Código da editora',.T.},{'Código da editora',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(INCLUI,GETSXENUM("SZ3","Z3_CODIGO",,1),M->Z3_CODIGO)',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistChav("SZ3")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'03',.T.},{'Z3_NOME',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome',.T.},{'Nome',.T.},{'Nome',.T.},{'Nome da editora',.T.},{'Nome da editora',.T.},{'Nome da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'04',.T.},{'Z3_CNPJ',.T.},{'C',.T.},{14,.T.},{0,.T.},{'CNPJ',.T.},{'CNPJ',.T.},{'CNPJ',.T.},{'CNPJ da editora',.T.},{'CNPJ da editora',.T.},{'CNPJ da editora',.T.},{'@R 99.999.999/9999-99',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'05',.T.},{'Z3_CONTATO',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome contato',.T.},{'Nome contato',.T.},{'Nome contato',.T.},{'Nome do contato',.T.},{'Nome do contato',.T.},{'Nome do contato',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'06',.T.},{'Z3_EMAIL',.T.},{'C',.T.},{150,.T.},{0,.T.},{'e-mail',.T.},{'e-mail',.T.},{'e-mail',.T.},{'e-mail da editora',.T.},{'e-mail da editora',.T.},{'e-mail da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'07',.T.},{'Z3_LOGRADO',.T.},{'C',.T.},{250,.T.},{0,.T.},{'Logradouro',.T.},{'Logradouro',.T.},{'Logradouro',.T.},{'Logradouro da editora',.T.},{'Logradouro da editora',.T.},{'Logradouro da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'08',.T.},{'Z3_NUMERO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Número',.T.},{'Número',.T.},{'Número',.T.},{'Número do logradouro',.T.},{'Número do logradouro',.T.},{'Número do logradouro',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'09',.T.},{'Z3_COMPLE',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Complemento',.T.},{'Complemento',.T.},{'Complemento',.T.},{'Complemento do logradouro',.T.},{'Complemento do logradouro',.T.},{'Complemento do logradouro',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'10',.T.},{'Z3_BAIRRO',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Bairro',.T.},{'Bairro',.T.},{'Bairro',.T.},{'Bairro da editora',.T.},{'Bairro da editora',.T.},{'Bairro da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'11',.T.},{'Z3_MUNICIP',.T.},{'C',.T.},{100,.T.},{0,.T.},{'Município',.T.},{'Município',.T.},{'Município',.T.},{'Município da editora',.T.},{'Município da editora',.T.},{'Município da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'12',.T.},{'Z3_UF',.T.},{'C',.T.},{2,.T.},{0,.T.},{'UF',.T.},{'UF',.T.},{'UF',.T.},{'UF da editora',.T.},{'UF da editora',.T.},{'UF da editora',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'12',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SX5","12"+M->Z3_UF)',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'13',.T.},{'Z3_CEP',.T.},{'C',.T.},{8,.T.},{0,.T.},{'CEP',.T.},{'CEP',.T.},{'CEP',.T.},{'CEP da editora',.T.},{'CEP da editora',.T.},{'CEP da editora',.T.},{'@R 99999-999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'14',.T.},{'Z3_DDD',.T.},{'C',.T.},{2,.T.},{0,.T.},{'DDD',.T.},{'DDD',.T.},{'DDD',.T.},{'DDD telefone',.T.},{'DDD telefone',.T.},{'DDD telefone',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ3',.T.},{'15',.T.},{'Z3_TEL',.T.},{'C',.T.},{9,.T.},{0,.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone',.T.},{'Telefone',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'01',.T.},{'Z4_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'02',.T.},{'Z4_CODIGO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Código',.T.},{'Código',.T.},{'Código',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(INCLUI,GETSXENUM("SZ4","Z4_CODIGO",,1),M->Z4_CODIGO)',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistChav("SZ4")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'03',.T.},{'Z4_TIPO',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Tipo',.T.},{'Tipo',.T.},{'Tipo',.T.},{'Tipo do exemplar',.T.},{'Tipo do exemplar',.T.},{'Tipo do exemplar',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'L=Livro;R=Revista;J=Jornal;A=Artigo',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'04',.T.},{'Z4_TITULO',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Título',.T.},{'Título',.T.},{'Título',.T.},{'Título do exemplar',.T.},{'Título do exemplar',.T.},{'Título do exemplar',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'05',.T.},{'Z4_AUTOR',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Autor',.T.},{'Autor',.T.},{'Autor',.T.},{'Autor do exemplar',.T.},{'Autor do exemplar',.T.},{'Autor do exemplar',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'SZ2',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'S',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SZ2")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'06',.T.},{'Z4_NOMEAUT',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome autor',.T.},{'Nome autor',.T.},{'Nome autor',.T.},{'Nome do autor',.T.},{'Nome do autor',.T.},{'Nome do autor',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(!INCLUI,POSICIONE("SZ2",1,M->Z4_AUTOR,"Z2_NOME"),"")',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'V',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'Posicione("SZ2",1,SZ4->Z4_AUTOR,"Z2_NOME")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'07',.T.},{'Z4_EDITORA',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Editora',.T.},{'Editora',.T.},{'Editora',.T.},{'Editora do exemplar',.T.},{'Editora do exemplar',.T.},{'Editora do exemplar',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'SZ3',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'S',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'Vazio() .Or. ExistCpo("SZ3")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'08',.T.},{'Z4_NOMEEDI',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Nome editora',.T.},{'Nome editora',.T.},{'Nome editora',.T.},{'Nome da editora',.T.},{'Nome da editora',.T.},{'Nome da editora',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(!INCLUI,POSICIONE("SZ3",1,M->Z4_EDITORA,"Z3_NOME"),"")',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'V',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'Posicione("SZ3",1,SZ4->Z4_EDITORA,"Z3_NOME")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'09',.T.},{'Z4_EDICAO',.T.},{'C',.T.},{3,.T.},{0,.T.},{'Edição',.T.},{'Edição',.T.},{'Edição',.T.},{'Edição do exemplar',.T.},{'Edição do exemplar',.T.},{'Edição do exemplar',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'10',.T.},{'Z4_ANO',.T.},{'N',.T.},{4,.T.},{0,.T.},{'Ano',.T.},{'Ano',.T.},{'Ano',.T.},{'Ano de publicação',.T.},{'Ano de publicação',.T.},{'Ano de publicação',.T.},{'@E 9999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'11',.T.},{'Z4_ISBN',.T.},{'C',.T.},{13,.T.},{0,.T.},{'ISBN',.T.},{'ISBN',.T.},{'ISBN',.T.},{'ISBN do exemplar',.T.},{'ISBN do exemplar',.T.},{'ISBN do exemplar',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'12',.T.},{'Z4_PAGINAS',.T.},{'N',.T.},{6,.T.},{0,.T.},{'N. páginas',.T.},{'N. páginas',.T.},{'N. páginas',.T.},{'Número de páginas',.T.},{'Número de páginas',.T.},{'Número de páginas',.T.},{'@E 999999',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ4',.T.},{'13',.T.},{'Z4_DEVPREV',.T.},{'N',.T.},{2,.T.},{0,.T.},{'Devolução',.T.},{'Devolução',.T.},{'Devolução',.T.},{'Dias para devolução',.T.},{'Dias para devolução',.T.},{'Dias para devolução',.T.},{'99',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ5',.T.},{'01',.T.},{'Z5_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ5',.T.},{'02',.T.},{'Z5_ACERVO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Cód. acervo',.T.},{'Cód. acervo',.T.},{'Cód. acervo',.T.},{'Código do acervo',.T.},{'Código do acervo',.T.},{'Código do acervo',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SZ4")',.T.},{'Vazio() .Or. ExistCpo("SZ4")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ5',.T.},{'03',.T.},{'Z5_CODIGO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Código',.T.},{'Código',.T.},{'Código',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistChav("SZ5")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ5',.T.},{'04',.T.},{'Z5_EMPREST',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Emprestado?',.T.},{'Emprestado?',.T.},{'Emprestado?',.T.},{'Exemplar emprestado?',.T.},{'Exemplar emprestado?',.T.},{'Exemplar emprestado?',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'"N"',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'S=Sim;N=Não',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ5',.T.},{'05',.T.},{'Z5_MSBLQL',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Bloqueado?',.T.},{'Bloqueado?',.T.},{'Bloqueado?',.T.},{'Registro bloqueado',.T.},{'Registro bloqueado',.T.},{'Registro bloqueado',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{"'2'",.T.},{'',.T.},{9,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'L',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'1=Sim;2=Não',.T.},{'1=Si;2=No',.T.},{'1=Yes;2=No',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'01',.T.},{'Z6_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'02',.T.},{'Z6_PROTOCO',.T.},{'C',.T.},{15,.T.},{0,.T.},{'Protocolo',.T.},{'Protocolo',.T.},{'Protocolo',.T.},{'Protocolo do empréstimo',.T.},{'Protocolo do empréstimo',.T.},{'Protocolo do empréstimo',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(INCLUI,GETSXENUM("SZ6","Z6_PROTOCO",,1),M->Z6_PROTOCO)',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'03',.T.},{'Z6_USUARIO',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Cód. usuário',.T.},{'Cód. usuário',.T.},{'Cód. usuário',.T.},{'Código do usuário',.T.},{'Código do usuário',.T.},{'Código do usuário',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'SZ1',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'S',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SZ2")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'04',.T.},{'Z6_NOME',.T.},{'C',.T.},{200,.T.},{0,.T.},{'Usuário',.T.},{'Usuário',.T.},{'Usuário',.T.},{'Nome do usuário',.T.},{'Nome do usuário',.T.},{'Nome do usuário',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'IIF(!INCLUI,POSICIONE("SZ1",1,M->Z6_USUARIO,"Z1_NOME"),"")',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'V',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'Posicione("SZ1",1,SZ6->Z6_USUARIO,"Z1_NOME")',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'05',.T.},{'Z6_DATA',.T.},{'D',.T.},{8,.T.},{0,.T.},{'Data',.T.},{'Data',.T.},{'Data',.T.},{'Data do empréstimo',.T.},{'Data do empréstimo',.T.},{'Data do empréstimo',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'DDATABASE',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. StaticCall(Emprestimos,fData,M->Z6_DATA)',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ6',.T.},{'06',.T.},{'Z6_STATUS',.T.},{'C',.T.},{1,.T.},{0,.T.},{'Status',.T.},{'Status',.T.},{'Status',.T.},{'Status do empréstimo',.T.},{'Status do empréstimo',.T.},{'Status do empréstimo',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'"E"',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'E=Em aberto;D=Devolvido',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ7',.T.},{'01',.T.},{'Z7_FILIAL',.T.},{'C',.T.},{2,.T.},{0,.T.},{'Filial',.T.},{'Sucursal',.T.},{'Branch',.T.},{'Filial do Sistema',.T.},{'Sucursal',.T.},{'Branch of the System',.T.},{'@!',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128),.T.},{'',.T.},{'',.T.},{1,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'033',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ7',.T.},{'02',.T.},{'Z7_PROTOCO',.T.},{'C',.T.},{15,.T.},{0,.T.},{'Cód. proto.',.T.},{'Cód. proto.',.T.},{'Cód. proto.',.T.},{'Código do protocolo',.T.},{'Código do protocolo',.T.},{'Código do protocolo',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'N',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ7',.T.},{'03',.T.},{'Z7_EXEMPLA',.T.},{'C',.T.},{10,.T.},{0,.T.},{'Cód. exemp.',.T.},{'Cód. exemp.',.T.},{'Cód. exemp.',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'Código do exemplar',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'',.T.},{'SZ5',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'S',.T.},{'U',.T.},{'S',.T.},{'A',.T.},{'R',.T.},{'€',.T.},{'Vazio() .Or. ExistCpo("SZ5",,2)',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ7',.T.},{'04',.T.},{'Z7_DEVPREV',.T.},{'D',.T.},{8,.T.},{0,.T.},{'Dev. prev.',.T.},{'Dev. prev.',.T.},{'Dev. prev.',.T.},{'Devolução prevista',.T.},{'Devolução prevista',.T.},{'Devolução prevista',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'CTOD("")',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'€',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )
	aAdd( aSX3, {{'SZ7',.T.},{'05',.T.},{'Z7_DEVREAL',.T.},{'D',.T.},{8,.T.},{0,.T.},{'Dev. real',.T.},{'Dev. real',.T.},{'Dev. real',.T.},{'Devolução real',.T.},{'Devolução real',.T.},{'Devolução real',.T.},{'',.T.},{'',.T.},{ Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) +Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160),.T.},{'CTOD("")',.T.},{'',.T.},{0,.T.},{Chr(254) + Chr(192),.T.},{'',.T.},{'',.T.},{'U',.T.},{'S',.T.},{'V',.T.},{'R',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'N',.T.},{'',.T.},{'',.T.},{'',.T.}} )

	//
	// Atualizando dicionário
	//
	nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
	nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
	nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
	nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
	nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
	nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

	aSort( aSX3,,, { |x,y| x[nPosArq][1]+x[nPosOrd][1]+x[nPosCpo][1] < y[nPosArq][1]+y[nPosOrd][1]+y[nPosCpo][1] } )

	oProcess:SetRegua2( Len( aSX3 ) )

	dbSelectArea( "SX3" )
	dbSetOrder( 2 )
	cAliasAtu := ""

	For nI := 1 To Len( aSX3 )

		//
		// Verifica se o campo faz parte de um grupo e ajusta tamanho
		//
		If !Empty( aSX3[nI][nPosSXG][1] )
			SXG->( dbSetOrder( 1 ) )
			If SXG->( MSSeek( aSX3[nI][nPosSXG][1] ) )
				If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
					aSX3[nI][nPosTam][1] := SXG->XG_SIZE
					AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
					AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
					" por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
				EndIf
			EndIf
		EndIf

		SX3->( dbSetOrder( 2 ) )

		If !( aSX3[nI][nPosArq][1] $ cAlias )
			cAlias += aSX3[nI][nPosArq][1] + "/"
			aAdd( aArqUpd, aSX3[nI][nPosArq][1] )
		EndIf

		If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo][1], nTamSeek ) ) )

			//
			// Busca ultima ocorrencia do alias
			//
			If ( aSX3[nI][nPosArq][1] <> cAliasAtu )
				cSeqAtu   := "00"
				cAliasAtu := aSX3[nI][nPosArq][1]

				dbSetOrder( 1 )
				SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
				dbSkip( -1 )

				If ( SX3->X3_ARQUIVO == cAliasAtu )
					cSeqAtu := SX3->X3_ORDEM
				EndIf

				nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
			EndIf

			nSeqAtu++
			cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

			RecLock( "SX3", .T. )
			For nJ := 1 To Len( aSX3[nI] )
				If     nJ == nPosOrd  // Ordem
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

				ElseIf aEstrut[nJ][2] > 0
					SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] ) )

				EndIf
			Next nJ

			dbCommit()
			MsUnLock()

			AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo][1] )

		Else

			//
			// Verifica se o campo faz parte de um grupo e ajsuta tamanho
			//
			If !Empty( SX3->X3_GRPSXG ) .AND. SX3->X3_GRPSXG <> aSX3[nI][nPosSXG][1]
				SXG->( dbSetOrder( 1 ) )
				If SXG->( MSSeek( SX3->X3_GRPSXG ) )
					If aSX3[nI][nPosTam][1] <> SXG->XG_SIZE
						aSX3[nI][nPosTam][1] := SXG->XG_SIZE
						AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo][1] + " NÃO atualizado e foi mantido em [" + ;
						AllTrim( Str( SXG->XG_SIZE ) ) + "]"+ CRLF + ;
						"   por pertencer ao grupo de campos [" + SX3->X3_GRPSXG + "]" + CRLF )
					EndIf
				EndIf
			EndIf

			//
			// Verifica todos os campos
			//
			For nJ := 1 To Len( aSX3[nI] )

				If aSX3[nI][nJ][2]
					cX3Campo := AllTrim( aEstrut[nJ][1] )
					cX3Dado  := SX3->( FieldGet( aEstrut[nJ][2] ) )

					If  aEstrut[nJ][2] > 0 .AND. ;
					PadR( StrTran( AllToChar( cX3Dado ), " ", "" ), 250 ) <> ;
					PadR( StrTran( AllToChar( aSX3[nI][nJ][1] ), " ", "" ), 250 ) .AND. ;
					!cX3Campo  == "X3_ORDEM"

						AutoGrLog( "Alterado campo " + aSX3[nI][nPosCpo][1] + CRLF + ;
						"   " + PadR( cX3Campo, 10 ) + " de [" + AllToChar( cX3Dado ) + "]" + CRLF + ;
						"            para [" + AllToChar( aSX3[nI][nJ][1] )           + "]" + CRLF )

						RecLock( "SX3", .F. )
						FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ][1] )
						MsUnLock()
					EndIf
				EndIf
			Next

		EndIf

		oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
	Local aEstrut   := {}
	Local aSIX      := {}
	Local lAlt      := .F.
	Local lDelInd   := .F.
	Local nI        := 0
	Local nJ        := 0

	AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

	aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
	"DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

	aAdd( aSIX, {'SZ1','1','Z1_CODIGO+Z1_NOME','Código+Nome','Codigo+Nome','Codigo+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ1','2','Z1_NOME+Z1_CODIGO','Nome+Código','Nome+Código','Nome+Código','U','','','S'} )
	aAdd( aSIX, {'SZ1','3','Z1_CPF+Z1_CODIGO+Z1_NOME','CPF+Código+Nome','CPF+Código+Nome','CPF+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ1','4','Z1_DOC+Z1_CODIGO+Z1_NOME','Documento+Código+Nome','Documento+Código+Nome','Documento+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ1','5','Z1_EMAIL+Z1_CODIGO+Z1_NOME','e-mail+Código+Nome','e-mail+Código+Nome','e-mail+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ1','6','Z1_DDDFIXO+Z1_FIXO+Z1_CODIGO+Z1_NOME','DDD fixo+Telefone+Código+Nome','DDD fixo+Telefone+Código+Nome','DDD fixo+Telefone+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ1','7','Z1_DDDCEL+Z1_CELULAR+Z1_CODIGO+Z1_NOME','DDD celular+Celular+Código+Nome','DDD celular+Celular+Código+Nome','DDD celular+Celular+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ2','1','Z2_CODIGO+Z2_NOME','Código+Nome','Código+Nome','Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ2','2','Z2_NOME+Z2_CODIGO','Nome+Código','Nome+Código','Nome+Código','U','','','S'} )
	aAdd( aSIX, {'SZ3','1','Z3_CODIGO+Z3_NOME','Código+Nome','Código+Nome','Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ3','2','Z3_CNPJ+Z3_CODIGO+Z3_NOME','CNPJ+Código+Nome','CNPJ+Código+Nome','CNPJ+Código+Nome','U','','','S'} )
	aAdd( aSIX, {'SZ3','3','Z3_NOME+Z3_CODIGO','Nome+Código','Nome+Código','Nome+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','1','Z4_CODIGO+Z4_TITULO','Código+Título','Código+Título','Código+Título','U','','','S'} )
	aAdd( aSIX, {'SZ4','2','Z4_TITULO+Z4_AUTOR+Z4_CODIGO','Título+Autor+Código','Título+Autor+Código','Título+Autor+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','3','Z4_TITULO+Z4_EDITORA+Z4_CODIGO','Título+Editora+Código','Título+Editora+Código','Título+Editora+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','4','Z4_TITULO+Z4_ANO+Z4_CODIGO','Título+Ano+Código','Título+Ano+Código','Título+Ano+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','5','Z4_TITULO+Z4_EDICAO+Z4_CODIGO','Título+Edição+Código','Título+Edição+Código','Título+Edição+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','6','Z4_ISBN+Z4_TITULO+Z4_CODIGO','ISBN+Título+Código','ISBN+Título+Código','ISBN+Título+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','7','Z4_TITULO+Z4_CODIGO','Título+Código','Título+Código','Título+Código','U','','','S'} )
	aAdd( aSIX, {'SZ4','8','Z4_AUTOR+Z4_CODIGO','Autor+Código','Autor+Código','Autor+Código','U','','','S'} )
	aAdd( aSIX, {'SZ5','1','Z5_ACERVO+Z5_CODIGO','Cód. acervo+Código','Cód. acervo+Código','Cód. acervo+Código','U','','','S'} )
	aAdd( aSIX, {'SZ5','2','Z5_CODIGO+Z5_ACERVO','Código+Cód. acervo','Código+Cód. acervo','Código+Cód. acervo','U','','','S'} )
	aAdd( aSIX, {'SZ6','1','Z6_PROTOCO','Protocolo','Protocolo','Protocolo','U','','','S'} )
	aAdd( aSIX, {'SZ6','2','Z6_DATA+Z6_PROTOCO','Data+Protocolo','Data+Protocolo','Data+Protocolo','U','','','S'} )
	aAdd( aSIX, {'SZ6','3','Z6_USUARIO+Z6_DATA+Z6_PROTOCO','Cód. usuário+Data+Protocolo','Cód. usuário+Data+Protocolo','Cód. usuário+Data+Protocolo','U','','','S'} )
	aAdd( aSIX, {'SZ7','1','Z7_PROTOCO+Z7_EXEMPLA','Cód. proto.+Cód. exemp.','Cód. proto.+Cód. exemp.','Cód. proto.+Cód. exemp.','U','','','S'} )
	aAdd( aSIX, {'SZ7','2','Z7_EXEMPLA+Z7_PROTOCO','Cód. exemp.+Cód. proto.','Cód. exemp.+Cód. proto.','Cód. exemp.+Cód. proto.','U','','','S'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSIX ) )

	dbSelectArea( "SIX" )
	SIX->( dbSetOrder( 1 ) )

	For nI := 1 To Len( aSIX )

		lAlt    := .F.
		lDelInd := .F.

		If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
			AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
		Else
			lAlt := .T.
			aAdd( aArqUpd, aSIX[nI][1] )
			If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
			StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
				AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
				lDelInd := .T. // Se for alteração precisa apagar o indice do banco
			EndIf
		EndIf

		RecLock( "SIX", !lAlt )
		For nJ := 1 To Len( aSIX[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
			EndIf
		Next nJ
		MsUnLock()

		dbCommit()

		If lDelInd
			TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
		EndIf

		oProcess:IncRegua2( "Atualizando índices..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Função de processamento da gravação do SX6 - Parâmetros

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
	Local aEstrut   := {}
	Local aSX6      := {}
	Local cAlias    := ""
	Local lContinua := .T.
	Local lReclock  := .T.
	Local nI        := 0
	Local nJ        := 0
	Local nTamFil   := Len( SX6->X6_FIL )
	Local nTamVar   := Len( SX6->X6_VAR )

	AutoGrLog( "Ínicio da Atualização" + " SX6" + CRLF )

	aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
	"X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
	"X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
	"X6_PYME"   }

	aAdd( aSX6, {'  ','FS_GCTCOT','C','Tipo Contrato para cotacao','Tipo Contrato para cotizacion','Contract type for quotation','','','','','','','001','001','001','S','','','001','001','001','S'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX6 ) )

	dbSelectArea( "SX6" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSX6 )
		lContinua := .F.
		lReclock  := .F.

		If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
			lContinua := .T.
			lReclock  := .T.
			AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
		Else
			lContinua := .T.
			lReclock  := .F.
			AutoGrLog( "Foi alterado o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " de [" + ;
			AllTrim( SX6->X6_CONTEUD ) + "]" + " para [" + AllTrim( aSX6[nI][13] ) + "]" )
		EndIf

		If lContinua
			If !( aSX6[nI][1] $ cAlias )
				cAlias += aSX6[nI][1] + "/"
			EndIf

			RecLock( "SX6", lReclock )
			For nJ := 1 To Len( aSX6[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()
		EndIf

		oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX7
Função de processamento da gravação do SX7 - Gatilhos

@author TOTVS Protheus
@since  25/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX7()
	Local aEstrut   := {}
	Local aAreaSX3  := SX3->( GetArea() )
	Local aSX7      := {}
	Local cAlias    := ""
	Local nI        := 0
	Local nJ        := 0
	Local nTamSeek  := Len( SX7->X7_CAMPO )

	AutoGrLog( "Ínicio da Atualização" + " SX7" + CRLF )

	aEstrut := { "X7_CAMPO", "X7_SEQUENC", "X7_REGRA", "X7_CDOMIN", "X7_TIPO", "X7_SEEK", ;
	"X7_ALIAS", "X7_ORDEM"  , "X7_CHAVE", "X7_PROPRI", "X7_CONDIC" }

	aAdd( aSX7, {'Z4_AUTOR','001','SZ2->Z2_NOME','Z4_NOMEAUT','P','S','SZ2',1,'M->Z4_AUTOR','U','!EMPTY(M->Z4_AUTOR)'} )
	aAdd( aSX7, {'Z4_EDITORA','001','SZ3->Z3_NOME','Z4_NOMEEDI','P','S','SZ3',1,'M->Z4_EDITORA','U','!EMPTY(M->Z4_EDITORA)'} )
	aAdd( aSX7, {'Z6_USUARIO','001','SZ1->Z1_NOME','Z6_NOME','P','S','SZ1',1,'M->Z6_USUARIO','U','!EMPTY(M->Z6_USUARIO)'} )
	aAdd( aSX7, {'Z7_EXEMPLA','001','StaticCall(Emprestimos,fDev)','Z7_DEVPREV','P','N','',0,'','U','!EMPTY(M->Z6_DATA)'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX7 ) )

	dbSelectArea( "SX3" )
	dbSetOrder( 2 )

	dbSelectArea( "SX7" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSX7 )

		If !SX7->( dbSeek( PadR( aSX7[nI][1], nTamSeek ) + aSX7[nI][2] ) )

			If !( aSX7[nI][1] $ cAlias )
				cAlias += aSX7[nI][1] + "/"
				AutoGrLog( "Foi incluído o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] )
			EndIf

			RecLock( "SX7", .T. )
		Else

			If !( aSX7[nI][1] $ cAlias )
				cAlias += aSX7[nI][1] + "/"
				AutoGrLog( "Foi alterado o gatilho " + aSX7[nI][1] + "/" + aSX7[nI][2] )
			EndIf

			RecLock( "SX7", .F. )
		EndIf

		For nJ := 1 To Len( aSX7[nI] )
			If FieldPos( aEstrut[nJ] ) > 0
				FieldPut( FieldPos( aEstrut[nJ] ), aSX7[nI][nJ] )
			EndIf
		Next nJ

		dbCommit()
		MsUnLock()

		If SX3->( dbSeek( SX7->X7_CAMPO ) )
			RecLock( "SX3", .F. )
			SX3->X3_TRIGGER := "S"
			MsUnLock()
		EndIf

		oProcess:IncRegua2( "Atualizando Arquivos (SX7)..." )

	Next nI

	RestArea( aAreaSX3 )

	AutoGrLog( CRLF + "Final da Atualização" + " SX7" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXB
Função de processamento da gravação do SXB - Consultas Padrao

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSXB()
	Local aEstrut   := {}
	Local aSXB      := {}
	Local cAlias    := ""
	Local nI        := 0
	Local nJ        := 0

	AutoGrLog( "Ínicio da Atualização" + " SXB" + CRLF )

	aEstrut := { "XB_ALIAS"  , "XB_TIPO"   , "XB_SEQ"    , "XB_COLUNA" , "XB_DESCRI" , "XB_DESCSPA", "XB_DESCENG", ;
	"XB_WCONTEM", "XB_CONTEM" }


	aAdd( aSXB, {'SZ1','1','01','DB','Usuário','Usuário','Usuário','','SZ1'} )
	aAdd( aSXB, {'SZ1','2','01','02','Nome','Nome','Nome','',''} )
	aAdd( aSXB, {'SZ1','2','02','03','Cpf','Cpf','Cpf','',''} )
	aAdd( aSXB, {'SZ1','2','03','04','Documento','Documento','Documento','',''} )
	aAdd( aSXB, {'SZ1','2','04','05','E-mail','E-mail','E-mail','',''} )
	aAdd( aSXB, {'SZ1','2','05','06','Ddd Fixo+telefone','Ddd Fixo+telefone','Ddd Fixo+telefone','',''} )
	aAdd( aSXB, {'SZ1','2','06','07','Ddd Celular+celular','Ddd Celular+celular','Ddd Celular+celular','',''} )
	aAdd( aSXB, {'SZ1','3','01','01','Cadastra Novo','Incluye Nuevo','Add New','','01'} )
	aAdd( aSXB, {'SZ1','4','01','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','01','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','01','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','01','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','01','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','01','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','01','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','01','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','01','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','02','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','02','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','02','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','02','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','02','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','02','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','02','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','02','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','02','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','03','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','03','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','03','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','03','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','03','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','03','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','03','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','03','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','03','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','04','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','04','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','04','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','04','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','04','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','04','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','04','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','04','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','04','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','05','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','05','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','05','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','05','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','05','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','05','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','05','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','05','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','05','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','06','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','06','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','06','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','06','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','06','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','06','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','06','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','06','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','06','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','07','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','07','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','07','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','07','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','07','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','07','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','07','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','07','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','07','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','08','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','08','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','08','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','08','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','08','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','08','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','08','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','08','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','08','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','4','09','01','Código','Código','Código','','Z1_CODIGO'} )
	aAdd( aSXB, {'SZ1','4','09','02','Nome','Nome','Nome','','Z1_NOME'} )
	aAdd( aSXB, {'SZ1','4','09','03','Documento','Número','Número','','Z1_DOC'} )
	aAdd( aSXB, {'SZ1','4','09','04','e-mail','e-mail','e-mail','','Z1_EMAIL'} )
	aAdd( aSXB, {'SZ1','4','09','05','CPF','CPF','CPF','','Z1_CPF'} )
	aAdd( aSXB, {'SZ1','4','09','06','DDD fixo','DDD fixo','DDD fixo','','Z1_DDDFIXO'} )
	aAdd( aSXB, {'SZ1','4','09','07','Telefone','Telefone','Telefone','','Z1_FIXO'} )
	aAdd( aSXB, {'SZ1','4','09','08','DDD celular','DDD celular','DDD celular','','Z1_DDDCEL'} )
	aAdd( aSXB, {'SZ1','4','09','09','Celular','Celular','Celular','','Z1_CELULAR'} )
	aAdd( aSXB, {'SZ1','5','01','','','','','','SZ1->Z1_CODIGO'} )
	aAdd( aSXB, {'SZ2','1','01','DB','Autor','Autor','Autor','','SZ2'} )
	aAdd( aSXB, {'SZ2','2','01','02','Nome','Nome','Nome','',''} )
	aAdd( aSXB, {'SZ2','3','01','01','Cadastra Novo','Incluye Nuevo','Add New','','01'} )
	aAdd( aSXB, {'SZ2','4','01','01','Código','Código','Código','','Z2_CODIGO'} )
	aAdd( aSXB, {'SZ2','4','01','02','Nome','Nome','Nome','','Z2_NOME'} )
	aAdd( aSXB, {'SZ2','4','01','03','Tipo','Tipo','Tipo','','Z2_TIPO'} )
	aAdd( aSXB, {'SZ2','5','01','','','','','','SZ2->Z2_CODIGO'} )
	aAdd( aSXB, {'SZ3','1','01','DB','Editora','Editora','Editora','','SZ3'} )
	aAdd( aSXB, {'SZ3','2','01','03','Nome+código','Nome+código','Nome+código','',''} )
	aAdd( aSXB, {'SZ3','3','01','01','Cadastra Novo','Incluye Nuevo','Add New','','01'} )
	aAdd( aSXB, {'SZ3','4','01','01','Código','Código','Código','','Z3_CODIGO'} )
	aAdd( aSXB, {'SZ3','4','01','02','Nome','Nome','Nome','','Z3_NOME'} )
	aAdd( aSXB, {'SZ3','4','01','03','CNPJ','CNPJ','CNPJ','','Z3_CNPJ'} )
	aAdd( aSXB, {'SZ3','5','01','','','','','','SZ3->Z3_CODIGO'} )
	aAdd( aSXB, {'SZ4','1','01','DB','Acervo','Acervo','Acervo','','SZ4'} )
	aAdd( aSXB, {'SZ4','2','01','07','Título+código','Título+código','Título+código','',''} )
	aAdd( aSXB, {'SZ4','3','01','01','Cadastra Novo','Incluye Nuevo','Add New','','01'} )
	aAdd( aSXB, {'SZ4','4','01','01','Código','Código','Código','','Z4_CODIGO'} )
	aAdd( aSXB, {'SZ4','4','01','02','Tipo','Tipo','Tipo','','Z4_TIPO'} )
	aAdd( aSXB, {'SZ4','4','01','03','Título','Título','Título','','Z4_TITULO'} )
	aAdd( aSXB, {'SZ4','4','01','04','Autor','Autor','Autor','','Z4_AUTOR'} )
	aAdd( aSXB, {'SZ4','4','01','05','Editora','Editora','Editora','','Z4_EDITORA'} )
	aAdd( aSXB, {'SZ4','4','01','06','Edição','Edição','Edição','','Z4_EDICAO'} )
	aAdd( aSXB, {'SZ4','4','01','07','Ano','Ano','Ano','','Z4_ANO'} )
	aAdd( aSXB, {'SZ4','4','01','08','ISBN','ISBN','ISBN','','Z4_ISBN'} )
	aAdd( aSXB, {'SZ4','5','01','','','','','','SZ4->Z4_CODIGO'} )
	aAdd( aSXB, {'SZ5','1','01','DB','Exemplar','Exemplar','Exemplar','','SZ5'} )
	aAdd( aSXB, {'SZ5','2','01','02','Código+cód. Acervo','Código+cód. Acervo','Código+cód. Acervo','',''} )
	aAdd( aSXB, {'SZ5','4','01','01','Código','Código','Código','','Z5_CODIGO'} )
	aAdd( aSXB, {'SZ5','4','01','02','Cód. acervo','Cód. acervo','Cód. acervo','','Z5_ACERVO'} )
	aAdd( aSXB, {'SZ5','5','01','','','','','','SZ5->Z5_CODIGO'} )
	aAdd( aSXB, {'SZ5','6','01','','','','','','SZ5->Z5_EMPREST!="S" .And. SZ5->Z5_MSBLQL!="1"'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSXB ) )

	dbSelectArea( "SXB" )
	dbSetOrder( 1 )

	For nI := 1 To Len( aSXB )

		If !Empty( aSXB[nI][1] )

			If !SXB->( dbSeek( PadR( aSXB[nI][1], Len( SXB->XB_ALIAS ) ) + aSXB[nI][2] + aSXB[nI][3] + aSXB[nI][4] ) )

				If !( aSXB[nI][1] $ cAlias )
					cAlias += aSXB[nI][1] + "/"
					AutoGrLog( "Foi incluída a consulta padrão " + aSXB[nI][1] )
				EndIf

				RecLock( "SXB", .T. )

				For nJ := 1 To Len( aSXB[nI] )
					If FieldPos( aEstrut[nJ] ) > 0
						FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
					EndIf
				Next nJ

				dbCommit()
				MsUnLock()

			Else

				//
				// Verifica todos os campos
				//
				For nJ := 1 To Len( aSXB[nI] )

					//
					// Se o campo estiver diferente da estrutura
					//
					If aEstrut[nJ] == SXB->( FieldName( nJ ) ) .AND. ;
					!StrTran( AllToChar( SXB->( FieldGet( nJ ) ) ), " ", "" ) == ;
					StrTran( AllToChar( aSXB[nI][nJ]            ), " ", "" )

						RecLock( "SXB", .F. )
						FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
						dbCommit()
						MsUnLock()

						If !( aSXB[nI][1] $ cAlias )
							cAlias += aSXB[nI][1] + "/"
							AutoGrLog( "Foi alterada a consulta padrão " + aSXB[nI][1] )
						EndIf

					EndIf

				Next

			EndIf

		EndIf

		oProcess:IncRegua2( "Atualizando Consultas Padrões (SXB)..." )

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX9
Função de processamento da gravação do SX9 - Relacionamento

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX9()
	Local aEstrut   := {}
	Local aSX9      := {}
	Local cAlias    := ""
	Local nI        := 0
	Local nJ        := 0
	Local nTamSeek  := Len( SX9->X9_DOM )

	AutoGrLog( "Ínicio da Atualização" + " SX9" + CRLF )

	aEstrut := { "X9_DOM"    , "X9_IDENT"  , "X9_CDOM"   , "X9_EXPDOM" , "X9_EXPCDOM", "X9_PROPRI" , "X9_LIGDOM" , ;
	"X9_LIGCDOM", "X9_CONDSQL", "X9_USEFIL" , "X9_VINFIL" , "X9_CHVFOR" , "X9_ENABLE" }


	aAdd( aSX9, {'SZ1','001','SZ6','Z1_CODIGO','Z6_USUARIO','N','1','N','','S','S','S','S'} )
	aAdd( aSX9, {'SZ2','001','SZ4','Z2_CODIGO','Z4_AUTOR','N','1','N','','S','S','S','S'} )
	aAdd( aSX9, {'SZ3','001','SZ4','Z3_CODIGO','Z4_EDITORA','N','1','N','','S','S','S','S'} )
	aAdd( aSX9, {'SZ4','001','SZ5','Z4_CODIGO','Z5_ACERVO','N','1','N','','S','S','S','S'} )
	aAdd( aSX9, {'SZ5','001','SZ7','Z5_CODIGO','Z7_EXEMPLA','N','1','N','','S','S','S','S'} )
	aAdd( aSX9, {'SZ6','001','SZ7','Z6_PROTOCO','Z7_PROTOCO','N','1','N','','S','S','S','S'} )
	//
	// Atualizando dicionário
	//
	oProcess:SetRegua2( Len( aSX9 ) )

	dbSelectArea( "SX9" )
	dbSetOrder( 2 )

	For nI := 1 To Len( aSX9 )

		If !SX9->( dbSeek( PadR( aSX9[nI][3], nTamSeek ) + PadR( aSX9[nI][1], nTamSeek ) ) )

			If !( aSX9[nI][1]+aSX9[nI][3] $ cAlias )
				cAlias += aSX9[nI][1]+aSX9[nI][3] + "/"
			EndIf

			RecLock( "SX9", .T. )
			For nJ := 1 To Len( aSX9[nI] )
				If FieldPos( aEstrut[nJ] ) > 0
					FieldPut( FieldPos( aEstrut[nJ] ), aSX9[nI][nJ] )
				EndIf
			Next nJ
			dbCommit()
			MsUnLock()

			AutoGrLog( "Foi incluído o relacionamento " + aSX9[nI][1] + "/" + aSX9[nI][3] )

			oProcess:IncRegua2( "Atualizando Arquivos (SX9)..." )

		EndIf

	Next nI

	AutoGrLog( CRLF + "Final da Atualização" + " SX9" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp
Função de processamento da gravação dos Helps de Campos

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
	Local aHlpPor   := {}
	Local aHlpEng   := {}
	Local aHlpSpa   := {}

	AutoGrLog( "Ínicio da Atualização" + " " + "Helps de Campos" + CRLF )


	oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial da' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ1_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código de identificação do funcionário' )
	aAdd( aHlpPor, 'usuário do módulo SigaSbi.' )

	PutHelp( "PZ1_CODIGO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_CODIGO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Nome do funcionário usuário do módulo' )
	aAdd( aHlpPor, 'SigaSbi.' )

	PutHelp( "PZ1_NOME   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_NOME" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Selecione o tipo do documento do' )
	aAdd( aHlpPor, 'usuário.' )

	PutHelp( "PZ1_TIPODOC", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_TIPODOC" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o número do documento de' )
	aAdd( aHlpPor, 'identidade' )

	PutHelp( "PZ1_DOC    ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_DOC" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o logradouro do usuário' )

	PutHelp( "PZ1_LOGRADO", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_LOGRADO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o número do logradouro do' )
	aAdd( aHlpPor, 'usuário' )

	PutHelp( "PZ1_NUMERO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_NUMERO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o complemento do logradouro do' )
	aAdd( aHlpPor, 'usuário' )

	PutHelp( "PZ1_COMPLE ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_COMPLE" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o bairro do usuário' )

	PutHelp( "PZ1_BAIRRO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_BAIRRO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o município do usuário' )

	PutHelp( "PZ1_MUNICIP", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_MUNICIP" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe a UF do usuário' )

	PutHelp( "PZ1_UF     ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_UF" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o CEP do usuário' )

	PutHelp( "PZ1_CEP    ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_CEP" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Selecione o gênero do usuário' )

	PutHelp( "PZ1_GENERO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_GENERO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe a data de nascimento do usuário' )

	PutHelp( "PZ1_NASCIME", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_NASCIME" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o e-mail do usuário' )

	PutHelp( "PZ1_EMAIL  ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_EMAIL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o CPF do usuário' )

	PutHelp( "PZ1_CPF    ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_CPF" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código DDD do telefone fixo' )
	aAdd( aHlpPor, 'dousuário' )

	PutHelp( "PZ1_DDDFIXO", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_DDDFIXO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o telefone fixo do usuário' )

	PutHelp( "PZ1_FIXO   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_FIXO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código DDD do telefone celular' )

	PutHelp( "PZ1_DDDCEL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_DDDCEL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o telefone celular' )

	PutHelp( "PZ1_CELULAR", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z1_CELULAR" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial de' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ2_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z2_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código de identificação da conta para' )
	aAdd( aHlpPor, 'apontamentos R.D.T.' )

	PutHelp( "PZ2_CODIGO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z2_CODIGO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Selecione o tipo do autor' )

	PutHelp( "PZ2_TIPO   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z2_TIPO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o nome do autor' )

	PutHelp( "PZ2_NOME   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z2_NOME" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial da' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ3_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z3_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código das funçöes dos funcionários' )
	aAdd( aHlpPor, 'usu-ários do SigaSbi.' )

	PutHelp( "PZ3_CODIGO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z3_CODIGO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o nome da editora' )

	PutHelp( "PZ3_NOME   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z3_NOME" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o CNPJ da editora' )

	PutHelp( "PZ3_CNPJ   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z3_CNPJ" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o nome do contato na editora' )

	PutHelp( "PZ3_CONTATO", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z3_CONTATO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial da' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ4_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código do processo ou programa que' )
	aAdd( aHlpPor, 'permitirá o apontamento automático' )
	aAdd( aHlpPor, 'durante a leitura do arquivo de Log.' )

	PutHelp( "PZ4_CODIGO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_CODIGO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Selecione o tipo do exemplar' )

	PutHelp( "PZ4_TIPO   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_TIPO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o título do exemplar' )

	PutHelp( "PZ4_TITULO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_TITULO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código do autor do exemplar' )

	PutHelp( "PZ4_AUTOR  ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_AUTOR" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código da editora do exemplar' )

	PutHelp( "PZ4_EDITORA", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_EDITORA" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe a edição do exemplar' )

	PutHelp( "PZ4_EDICAO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_EDICAO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o ano de publicação do exemplar' )

	PutHelp( "PZ4_ANO    ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_ANO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código ISBN do exemplar' )

	PutHelp( "PZ4_ISBN   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_ISBN" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o número de págias do exemplar' )

	PutHelp( "PZ4_PAGINAS", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_PAGINAS" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe a quantidade de dias para o' )
	aAdd( aHlpPor, 'cálculo da devolução prevista' )

	PutHelp( "PZ4_DEVPREV", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z4_DEVPREV" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código do funcionário para o' )
	aAdd( aHlpPor, 'apontamentoR.D.T.' )

	PutHelp( "PZ5_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z5_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código do exemplar' )

	PutHelp( "PZ5_CODIGO ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z5_CODIGO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Indica se o exemplar está emprestado.' )

	PutHelp( "PZ5_EMPREST", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z5_EMPREST" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial da' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ6_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z6_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Número do protocolo de identificação do' )
	aAdd( aHlpPor, 'empréstimo' )

	PutHelp( "PZ6_PROTOCO", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z6_PROTOCO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código do usuário locatário' )

	PutHelp( "PZ6_USUARIO", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z6_USUARIO" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe a data de realização do' )
	aAdd( aHlpPor, 'empréstimo' )

	PutHelp( "PZ6_DATA   ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z6_DATA" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Código que identifica a filial da' )
	aAdd( aHlpPor, 'empre-sa usuária do sistema.' )

	PutHelp( "PZ7_FILIAL ", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z7_FILIAL" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Informe o código do exemplar do item do' )
	aAdd( aHlpPor, 'empréstimo' )

	PutHelp( "PZ7_EXEMPLA", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z7_EXEMPLA" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Data prevista para a devolução do' )
	aAdd( aHlpPor, 'exemplar' )

	PutHelp( "PZ7_DEVPREV", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z7_DEVPREV" )

	aHlpPor := {}
	aAdd( aHlpPor, 'Data da devolução do exemplar' )

	PutHelp( "PZ7_DEVREAL", aHlpPor, {}, {}, .T. )
	AutoGrLog( "Atualizado o Help do campo " + "Z7_DEVREAL" )

	AutoGrLog( CRLF + "Final da Atualização" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

	//---------------------------------------------
	// Parâmetro  nTipo
	// 1 - Monta com Todas Empresas/Filiais
	// 2 - Monta só com Empresas
	// 3 - Monta só com Filiais de uma Empresa
	//
	// Parâmetro  aMarcadas
	// Vetor com Empresas/Filiais pré marcadas
	//
	// Parâmetro  cEmpSel
	// Empresa que será usada para montar seleção
	//---------------------------------------------
	Local   aRet      := {}
	Local   aSalvAmb  := GetArea()
	Local   aSalvSM0  := {}
	Local   aVetor    := {}
	Local   cMascEmp  := "??"
	Local   cVar      := ""
	Local   lChk      := .F.
	Local   lOk       := .F.
	Local   lTeveMarc := .F.
	Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
	Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
	Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
	Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

	Local   aMarcadas := {}


	If !MyOpenSm0(.F.)
		Return aRet
	EndIf


	dbSelectArea( "SM0" )
	aSalvSM0 := SM0->( GetArea() )
	dbSetOrder( 1 )
	dbGoTop()

	While !SM0->( EOF() )

		If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
			aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
		EndIf

		dbSkip()
	End

	RestArea( aSalvSM0 )

	Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

	oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

	oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

	@ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
	oLbx:SetArray(  aVetor )
	oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
	aVetor[oLbx:nAt, 2], ;
	aVetor[oLbx:nAt, 4]}}
	oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
	oLbx:cToolTip   :=  oDlg:cTitle
	oLbx:lHScroll   := .F. // NoScroll

	@ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
	on Click MarcaTodos( lChk, @aVetor, oLbx )

	// Marca/Desmarca por mascara
	@ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
	@ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
	Message "Máscara Empresa ( ?? )"  Of oDlg
	oSay:cToolTip := oMascEmp:cToolTip

	@ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Inverter Seleção" Of oDlg
	oButInv:SetCss( CSSBOTAO )
	@ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
	oButMarc:SetCss( CSSBOTAO )
	@ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
	Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
	oButDMar:SetCss( CSSBOTAO )
	@ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), oDlg:End()  ) ;
	Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
	oButOk:SetCss( CSSBOTAO )
	@ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
	Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
	oButCanc:SetCss( CSSBOTAO )

	Activate MSDialog  oDlg Center

	RestArea( aSalvAmb )
	dbSelectArea( "SM0" )
	dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := lMarca
	Next nI

	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
	Local  nI := 0

	For nI := 1 To Len( aVetor )
		aVetor[nI][1] := !aVetor[nI][1]
	Next nI

	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
	Local  nI    := 0

	aRet := {}
	For nI := 1 To Len( aVetor )
		If aVetor[nI][1]
			aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
		EndIf
	Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
	Local cPos1 := SubStr( cMascEmp, 1, 1 )
	Local cPos2 := SubStr( cMascEmp, 2, 1 )
	Local nPos  := oLbx:nAt
	Local nZ    := 0

	For nZ := 1 To Len( aVetor )
		If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
			If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
				aVetor[nZ][1] := lMarDes
			EndIf
		EndIf
	Next

	oLbx:nAt := nPos
	oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
	Local lTTrue := .T.
	Local nI     := 0

	For nI := 1 To Len( aVetor )
		lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
	Next nI

	lChk := IIf( lTTrue, .T., .F. )
	oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)

	Local lOpen := .F.
	Local nLoop := 0

	For nLoop := 1 To 20
		dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

		If !Empty( Select( "SM0" ) )
			lOpen := .T.
			dbSetIndex( "SIGAMAT.IND" )
			Exit
		EndIf

		Sleep( 500 )

	Next nLoop

	If !lOpen
		MsgStop( "Não foi possível a abertura da tabela " + ;
		IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
	EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  22/01/2017
@obs    Gerado por EXPORDIC - V.5.2.1.0 EFS / Upd. V.4.20.15 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
	Local cRet  := ""
	Local cFile := NomeAutoLog()
	Local cAux  := ""

	FT_FUSE( cFile )
	FT_FGOTOP()

	While !FT_FEOF()

		cAux := FT_FREADLN()

		If Len( cRet ) + Len( cAux ) < 1048000
			cRet += cAux + CRLF
		Else
			cRet += CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
			cRet += "LOG Completo no arquivo " + cFile + CRLF
			cRet += Replicate( "=" , 128 ) + CRLF
			Exit
		EndIf

		FT_FSKIP()
	End

	FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
