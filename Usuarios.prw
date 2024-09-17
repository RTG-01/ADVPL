#include 'protheus.ch'
#include 'parmtype.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} Usuarios
Rotina de cadastro dos usuários

@author Renan Guedes
@since 12/12/2017
@version 1
/*/
//--------------------------------------------------------------------
user function Usuarios()
	local bOK			:= {|| fOk()}		//Função executada ao confirmar
	local bTTS			:= {|| fTTS()}		//Função executada após a confirmação e dentro da transação

	private lTran		:= .F.

	BEGIN SEQUENCE

		//Verifica se as tabelas necessárias existem no dicionário de dados
		if !AliasInDic("SZ1")
			ShowHelpDlg("SX",{"Dicionário de dados desatualizado."},5,{"Atualize o dicionário de dados para usar esta rotina."},5)
			BREAK
		endif
		
		dbSelectArea("SZ1")
		SZ1->(dbSetOrder(1))		//Z1_CODIGO+Z1_NOME

		AxCadastro("SZ1","Usuário",,,,,bOK,bTTS)		//Função padrão de cadastro

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
Função executada ao clicar no botão OK do diálogo de inclusão, alteração ou exclusão.

@author Renan Guedes
@since 12/12/2017
@version 1

@return lRet,Indica se a confirmação é válida
/*/
//--------------------------------------------------------------------
static function fOk()
	local lRet		:= .F.
	local aArea		:= GetArea()
	local aAreaSZ6	:= {}

	BEGIN SEQUENCE

		if !INCLUI .And. !ALTERA		//Exclusão
			//Verifica se o usuário não possui empréstimos registrados
			if AliasInDic("SZ6")
				dbSelectArea("SZ6")
				aAreaSZ6 := SZ6->(GetArea())
				SZ6->(dbSetOrder(3))	//Z6_USUARIO+Z6_DATA+Z6_PROTOCO

				if SZ6->(MsSeek(SZ1->Z1_CODIGO))
					ShowHelpDlg("Empréstimo",{"Não é possível excluir usuário com empréstimo realizado."},5,{"Somente usuários sem empréstimos realizados podem ser excluídos."},5)
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
Função executada durante a transação de inclusão, alteração ou exclusão.

@author Renan Guedes
@since 12/12/2017
@version 1
/*/
//--------------------------------------------------------------------
static function fTTS()

	if INCLUI
		lTran := .T.		//Atualiza a variável de controle de uso de reserva na inclusão
	endif

return