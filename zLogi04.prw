#include "PROTHEUS.CH"
#include PRTOPDEF.CH
/*/
{Protheus.doc} zLogi04
(long_description)
@type user function
@author user
@since 15/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
@obs 0 tipo User Function pode ser chamado em qualquer lugar do Protheus com
o prefixo U_ (letra U com underscore/underline), por exemplo, u_zLogi04()

As nomenclaturas utilizadas, geralmente são:
AABBBXNN, onde:
AA - Sigla da empresa
BBB - Módulo da Função
X - Tipo (Atualização, Consulta, Relatório, Miscelanea, Job, etc)
NN - Sequência, por exemplo:
ASFATR87 -> Atilio Sistemas, FATuramento, Relatório,

Ou se for um fonte genérico, de uma lib por exemplo, iniciamos a funcão de usuario com a letra "z"

Já as funções estáticas não tem limitação de tamanho de caracteres (até 10)
Para seguir um padrão, tentamos começar com elas, utilizando a letra "f"

sequência 87
/*/
User Function zLogi04()
    Local aArea := GetArea()
   
   //Mostrar a mensagem de que está na User Function zLogi04
    Msinfo("Estou na User Function zlogi04", "Atenção")

    //Chamar a função estática Funcão A
    fFuncA()

    //Chamar a função estática Funcão B
    fFuncB()

    //Chamar a função estática Funcão Teste
    fFuncaoTst()

    RestArea(aArea)
Return 


/*/{Protheus.doc} fFuncA
    (long_description)
    @type  Static Function
    @author user
    @since 15/10/2025
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fFuncA()
    Msinfo("Estou na Static Function Função A", "Atenção")
    
Return 

/*/{Protheus.doc} fFuncB
    (long_description)
    @type  Static Function
    @author user
    @since 15/10/2025
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fFuncB()
    Msinfo("Estou na Static Function Função B", "Atenção")
    
Return 

/*/{Protheus.doc} fFuncaoTst
    (long_description)
    @type  Static Function
    @author user
    @since 15/10/2025
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fFuncaoTst()
    Msinfo("Estou na Static Function fFuncaoTst", "Atenção")
    
Return 
