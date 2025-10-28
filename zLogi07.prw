//Bibliotecas
#Include "Totvs.ch"

/*/{Protheus.doc} zLogi07
Demonstrando tipos de dados em AdvPL
@author Atilio
@since 15/02/2020
@version 1.0
@type function
@see https://tdn.totvs.com/display/tec/Tipagem+de+Dados
/*/

User Function zLogi07()
Local aArea := GetArea()

//Declarando da forma antiga
fFormaAnt()

//Declarando da forma nova
fFormaNov()

RestArea(aArea)
Return


/*/{Protheus.doc} fFormaAnt
    Função que demonstra a tipagem de dados da forma antiga
    @type  Static Function
    @author user
    @since 20/10/2025
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fFormaAnt(param_name)

    Local cName 

    cName    := "Rafael" + CRLF + 'Pereira'
    MsgInfo(cName)
    
   //Bloco de codigo  usasdo para validar codigo ou botãoa
bAoQuadrado := { | nValor | nQuadrado := nValor * nValor, Alert("Valor ao quadrado: " + cValToChar(nQuadrado)) }

Eval( bAoQuadrado, 5)
Eval( bAoQuadrado, 7)

    /*
    Local cName     := ""
    Local nIdade    := 0 (15 casa numerica)
    Local lCurso    := .T.
    Local dDataNasc := stoD("")
    Local xVariavel := Nil  
    Local oFont     := TFont():New() 
    Local bBloco    := { ||  } 
    Local aDados    := {} 
    */

Return return_var






/*/{Protheus.doc} fFormaNov
Função que demonstra a tipagem de dados da forma nova
@author Atilio
@since 15/02/2020
@version 1.0
@type function
@see https://tdn.totvs.com/display/tec/Tipagem+de+Dados
/*/


Static Function fFormaNov()


Local cNome AS Character

cNome := "Daniel"
cNome := Date()

Alert(cNome)
/*
 AS Character
Local nIdade AS Numeric
Local dDataNasc AS Date
Local 1Curso AS Logical
Local oFont AS Object
Local bBloco AS CodeBlock
Local aDados AS Array
*/


Return
