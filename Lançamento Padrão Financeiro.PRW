




520        
001        
BX CTA RECEBER DNI                       
112010003                                                                                          
SA1->A1_CONTA                                                  
IF(SE1->E1_SITUACA = '0' .AND. "DEP " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_VALLIQ,0)                                
SUBSTR("VR DNI "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" LQ DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)


520        
002        
BX CTA RECEBER DESC                      
312050003                                
SA1->A1_CONTA                                 
IF(!(" CD " $ SE5->E5_HISTOR .OR. " AC " $ SE5->E5_HISTOR)  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_DESCONT,0)                                
SUBSTR("VR DESC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)  

520        
003        
BX CTA RECEBER DESC AC                   
312020029                              
SA1->A1_CONTA                                 
IF(" CD " $ SE5->E5_HISTOR .OR. " AC " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_DESCONT,0)                         
SUBSTR("VR AC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)    

520        
004        
BX CTA RECEBER JUROS                     
112010003                                                            
412010003                                     
IF(SE1->E1_SITUACA = '0' .AND. !(" RA " $ SE5->E5_HISTOR)  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_JUROS,0)                                   
SUBSTR("VR JRS "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)   

520        
005        
BX CTA RECEBER RAPPEL                    
112010003                                              
312020029                                                 
IF(SE1->E1_SITUACA = '0' .AND. " RA " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX .AND. SE1->E1_JUROS > 0, SE1->E1_JUROS,0)                            
SUBSTR("DEV RA S/DEV VENDAS "+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" "+alltrim(SA1->A1_NOME),1,40)                                                                                  

520        
006        
BX CTA RECEBER DACAO                     
312060001                                 
SA1->A1_CONTA                                                                                            
IF("DAC" $ SE5->E5_MOTBX, SE1->E1_VALLIQ,0)                                                      
SUBSTR("VR DAC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" "+alltrim(SA1->A1_NOME),1,40)                               

521        
001        
BAIXA A REC BANCO CNAB                   
111020006                                                 
SA1->A1_CONTA                                                  
SE1->E1_VALLIQ                                                          
SUBSTR("REC TIT/"+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+ALLTRIM(DTOC(SE1->E1_BAIXA))+" "+alltrim(SA1->A1_NOME),1,40) 

521        
002        
BAIXA A REC JUROS CNAB                   
112010001                                                   
412010003                                                  
SE1->E1_JUROS                                                
SUBSTR("REC JRS TIT/"+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+ALLTRIM(DTOC(SE1->E1_BAIXA))+" "+alltrim(SA1->A1_NOME),1,40)

527        
001        
EXCLUSAO CTA RECEBER DNI                 
SA1->A1_CONTA                                                                                                                                                                                            
112010003                                                                                                                                                                                                
IF(SE1->E1_SITUACA = '0' .AND. "DEP " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_VALLIQ,0)                                    
SUBSTR("Exc DNI "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)

527        
002        
EXCLUSAO CTA RECEBER DESC                
SA1->A1_CONTA                                                                                                                                                                                            
312050003                                                                                                                                                                                                
IF(!(" CD " $ SE5->E5_HISTOR .OR. " AC " $ SE5->E5_HISTOR)  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_DESCONT,0)                                                                                              
SUBSTR("Exc DESC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40) 

527        
003        
EXCLUSAO CTA RECEBER DESC AC             
SA1->A1_CONTA                                                            
312020029                                                                   
IF(" CD " $ SE5->E5_HISTOR .OR. " AC " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_DESCONT,0)                                     
SUBSTR("Exc AC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)   

527        
004        
EXCLUSAO CTA RECEBER JUROS               
412010003                                                                                                                                                                                                
112010003                                                                                                                                                                                                
IF(SE1->E1_SITUACA = '0' .AND. !(" RA " $ SE5->E5_HISTOR)  .AND. "NOR" $ SE5->E5_MOTBX, SE1->E1_JUROS,0)                                                                                                 
SUBSTR("Exc JRS "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+alltrim(SA1->A1_NOME),1,40)  

527        
005        
EXCLUSAO CTA RECEBER RAPPEL              
312020029                                                                                                                                                                                                
112010003                                                                                                                                                                                                
IF(SE1->E1_SITUACA = '0' .AND. " RA " $ SE5->E5_HISTOR  .AND. "NOR" $ SE5->E5_MOTBX .AND. SE1->E1_JUROS > 0, SE1->E1_JUROS,0)                                                                            
SUBSTR("Exc DEV RA S/DV VDAS DP "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" "+alltrim(SA1->A1_NOME),1,40)                                                                                     

527        
006        
EXCLUSAO BAIXA A REC BANCO CNAB          
SA1->A1_CONTA                                                                                                                                                                                            
111020006                                                                                                                                                                                                
IF(SE1->E1_SITUACA = '1', SE1->E1_VALLIQ,0)                                                                                                                                                              
SUBSTR("Exc REC TIT/"+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+ALLTRIM(DTOC(SE1->E1_BAIXA))+" "+alltrim(SA1->A1_NOME),1,40)                                       

527        
007        
EXCLUSAO BAIXA A REC JUROS CNAB          
412010003                                                                                                                                                                                                
112010001                                                                                                                                                                                                
IF(SE1->E1_SITUACA = '1', SE1->E1_JUROS,0)                                                                                                                                                               
SUBSTR("Exc REC JRS TIT/"+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+ALLTRIM(SE1->E1_PARCELA)+" "+ALLTRIM(DTOC(SE1->E1_BAIXA))+" "+alltrim(SA1->A1_NOME),1,40)                                   

527        
008        
EXCLUSAO BX CTA RECEBER DACAO            
SA1->A1_CONTA                                                                                                                                                                                            
312060001                                                                                                                                                                                                
IF("DAC" $ SE5->E5_MOTBX, SE1->E1_VALLIQ,0)                                                                                                                                                              
SUBSTR("Exc VR DAC "+ALLTRIM(SUBSTR(CMONTH(date()),1,3))+"/"+alltrim(STR(YEAR(date())))+" "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" "+alltrim(SA1->A1_NOME),1,40)                           

588        
001        
EXCLUSAO COMP CTA RECEBER NCC            
SA1->A1_CONTA                                                                                                                                                                                            
112010007                                                                                                                                                                                                
SE5->E5_VALOR                                                                                                                                                                                            
SUBSTR("Exc VR NCC "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" DP "+ALLTRIM(SE5->E5_PREFIXO)+" "+ALLTRIM(SE5->E5_NUMERO)+" "+alltrim(SA1->A1_NOME),1,40)                                      

596        
001        
BX CTA RECEBER NCC                       
112010007                                                                                                                                                                                                
SA1->A1_CONTA                                                                                                                                                                                            
SE5->E5_VALOR                                                                                                                                                                                            
SUBSTR("VR NCC "+ALLTRIM(SE1->E1_PREFIXO)+" "+ALLTRIM(SE1->E1_NUM)+" DP "+SUBSTR(ALLTRIM(SE5->E5_DOCUMEN),1,10)+alltrim(SA1->A1_NOME),1,40)                                                             
