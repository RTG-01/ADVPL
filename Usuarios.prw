#include 'protheus.ch'
#include 'parmtype.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} Usuarios
Rotina de cadastro dos usu�rios

@author Renan Guedes
@since 12/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Usuarios()
	local bOK			:= {|| fOk()}		//Fun��o executada ao confirmar
	local bTTS			:= {|| fTTS()}		//Fun��o executada ap�s a confirma��o e dentro da transa��o

	private lTran		:= .F.

	BEGIN SEQUENCE

		//Verifica se as tabelas necess�rias existem no dicion�rio de dados
		if !AliasInDic("SZ1")
			ShowHelpDlg("SX",{"Dicion�rio de dados desatualizado."},5,{"Atualize o dicion�rio de dados para usar esta rotina."},5)
			BREAK
		endif
		
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1))		//Z1_CODIGO+Z1_NOME

		AxCadastro("SZ1","Usu�rio",,,,,bOK,bTTS)		//Fun��o padr�o de cadastro

		//Atualiza as reservas
			If lTran
				ConfirmSx8()		//Confirma as reservas
			Else
				RollBackSX8()		//Desfaz as reservas
			EndIf

	END SEQUENCE

return


//--------------------------------------------------------------------
/*/{Protheus.doc} fOk
Fun��o executada ao clicar no bot�o OK do di�logo de inclus�o, altera��o ou exclus�o.

@author Renan Guedes
@since 12/12/2017
@version 1

@return lRet,Indica se a confirma��o � v�lida
/*/
//--------------------------------------------------------------------
static function fOk()
	local lRet		:= .F.
	local aArea		:= GetArea()
	local aAreaSZ6	:= {}

	BEGIN SEQUENCE

		if !INCLUI .And. !ALTERA		//Exclus�o
			//Verifica se o usu�rio n�o possui empr�stimos registrados
			if AliasInDic("SZ6")
				dbSelectArea("SZ6")
				aAreaSZ6 := SZ6->(GetArea())
				SZ6->(dbSetOrder(3))	//Z6_USUARIO+Z6_DATA+Z6_PROTOCO

				if SZ6->(MsSeek(SZ1->Z1_CODIGO))
					ShowHelpDlg("Empr�stimo",{"N�o � poss�vel excluir usu�rio com empr�stimo realizado."},5,{"Somente usu�rios sem empr�stimos realizados podem ser exclu�dos."},5)
					BREAK
				endif

				RestArea(aAreaSZ6)
			endif
		endif

		lRet := .T.

	END SEQUENCE

	RestArea(aArea)

return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} fTTS
Fun��o executada durante a transa��o de inclus�o, altera��o ou exclus�o.

@author Renan Guedes
@since 12/12/2017
@version 1
/*/
//--------------------------------------------------------------------
static function fTTS()

	if INCLUI
		lTran := .T.		//Atualiza a vari�vel de controle de uso de reserva na inclus�o
	endif

return