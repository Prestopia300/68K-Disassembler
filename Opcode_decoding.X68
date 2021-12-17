*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*----------------------------------------------------------- LOOP FOR ASCII USES A5
STACK   ;EQU     $2000   
     ORG    $1000
START:                 ; first instruction of program      
    MOVEA   #INTRO, A1   
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
      * write to the display
    TRAP    #15 
    JSR TAKE_INPUT                ;AFTER THIS END ADDRESS IN D7
 
VERIFY:
    CMP A6, D7
    BLE FOUND_ERROR
    
    JMP DECODE

FOUND_ERROR
    MOVEA   #ERRORMESSAGE, A1   
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
      * write to the display
    TRAP    #15 
    JSR TAKE_INPUT


DECODE ;STARTING ADDRESS IN D2, ENDING ADDRESS IN D3
          ;intialize buffer     
    ; load the next instruction and jump to the opcode table entry
    LEA     OP_TABLE, A0
    CLR.L   D0
    CLR D1
    CLR D5
    CLR D4
    CLR D0
Loop2
   
   LEA     buffer, A2   ;PUT BUFFER IN A2
   MOVE.W A6, D0  ;ADDRESS KEPT IN A5 FOR USE IT ITOA FUNCTION
   MOVE.W #8, D3
LOOP_ASCII3:
   MOVE.L D0,D1     ;MOVE ADDRESS TO D1
   ANDI.L #$F0000000, D1   ;GET FOUR MSB BITS
   SUB.L D1,D0              ;REMOVE THOSE FOUR BITS FROM D0 SO THEY ARENT READ AGAIN
   ROL.L #4,D1              ;ROTATE LEFT SO FOUR MSB ARE NOW LSB AND CAN BE READ AS A SINGLE NUMBER
   ROL.L #$4, D0            ;ROTATE D0 LEFT SO THAT THE NEXT HEX NUMBER IS READ IN NEXT LOOP ITERATION
   CMP.B #10, D1            ;IF LESS THAN 10 IT CAN BE ADDED AS NUMBER
   BLT NUM_ASCII3
   BRA HEX_ASCII3           ;ELSE IT IS LETTER VALUE IN HEX
NUM_ASCII3:
   ADD.B #48,D1             
   MOVE.B  D1,(A2)+       ;ADD TO BUFFER
   BRA NEXT_ASCII3
HEX_ASCII3:
   ADD.B #55,D1
   MOVE.B  D1,(A2)+ 
NEXT_ASCII3:   
   SUBQ.B #1, D3
   BNE LOOP_ASCII3

   MOVE.B #$9, (A2)+
 
   CLR D0
   CLR D1
   MOVE.W (A6)+,D0
                       ;----------------------------------------DECODING 
      
   MOVE.L  D0, D1    ; D1 = D0 (current instruction word)
    MOVE.B  #12, D2        ; D2 = 12 (hex is 4 chars long)
    LSR.W   D2, D1              ; extract the opcode in D1
    MULU    #6, D1              ; compute the opcode jump displacement
    JMP     0(A0, D1) ;(A0, D1)           ; jump to the opcode table entry    
    

OP_TABLE:
    JMP     code0000            ; ADDI.bwl/ANDI.bwl/CMPI.bwl/EORI.bwl/ORI.bwl etc.
    JMP     code0001            ; MOVE.b
    JMP     code0010            ; MOVE.l  /MOVEA.l
    JMP     code0011            ; MOVE.w  /MOVEA.w
    JMP     code0100            ; CLR.bwl /JMP/JSR/LEA/MOVEM.wl/NOP, etc
    JMP     code0101            ; ADDQ.bwl/SUBQ.bwl/Scc     /DBcc
    JMP     code0110            ; BRA.bw  /BSR.bw  /Bcc.bw
    JMP     code0111            ; MOVEQ
    JMP     code1000            ; DIVS    /DIVU    /OR.bwl
    JMP     code1001            ; SUB.bwl /SUBA.wl
    ;JMP     code1010            ;     (unassigned)
    JMP     code1011            ; CMP.bwl /CMPA.wl /EOR.bwl
    JMP     code1100            ; MULS    /MULU    /AND.bwl
    JMP     code1101            ; ADD.bwl /ADDA.wl /ADDX.bwl
    JMP     code1110            ; ASL.bwl/ASR.bwl/LSL.bwl /LSR.bwl /ROL.bwl /ROR.bwl
    ;JMP     code1111            ;     (unassigned)
    ;BRA FOUND_ERROR

code0000:   ;---------------ORI
    
    MOVE.B  #'O',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'R',(A2)+
    MOVE.B  #'I',(A2)+
    MOVE.B  #'.',(A2)+
                ;ISOLATE TWO BITS USING AND
     MOVE.B D0,D3
     MOVE.B D0, D4        ;For effective address
     ANDI.B #%11000000, D3
     CMP.B #$00,D3       ;If statements to check if byte or word or long
     BEQ BYTE      
     CMP.B #$40,D3
     BEQ WORD
     CMP.B #$80,D3
     BEQ LONG
    
BYTE:                     ;ADD ASCII VALUES TO BUFFER
     MOVE.B  #'B',(A2)+
     MOVE.B #1,D1
     MOVE.B (A6)+,D7       ;CLEAR ZEROS
     CLR D5
     BRA DONE             ;after adding size character go to routine to add immediate data (CONVERT HEX TO ASCII)
WORD:
     MOVE.B  #'W',(A2)+
     MOVE.B #2,D1        ;Make loop counter 2 for the the 4 HEX VALUES that make up 16 bits, 4 bytes
     BRA DONE
LONG:
     MOVE.B  #'L',(A2)+
     MOVE.B #3,D1          ;COUNTER
     MOVE.B (A6)+,D5       ;CLEAR ZEROS
     CLR D5
     BRA DONE
DONE:
     MOVE.B  #$9,(A2)+
     MOVE.B  #'#',(A2)+
     MOVE.B  #'$',(A2)+
     CLR D3
     
     JSR ITOA                 ;RETURNS HERE AFTER CONVERSION
    
     MOVE.B  #',',(A2)+
     MOVE.B  #32,(A2)+
     CLR D5
     MOVE.B D4,D5
     JSR EFFECTIVE_ADDRESS_3_5
     BRA PRINT                       
        ;JMP     END
code0001: ;MOVEA and MOVE
     MOVE #1,D1                 ;IN CASE OF IMMEDIATE DATA 
     MOVE.B  #'M',(A2)+
     MOVE.B  #'O',(A2)+
     MOVE.B  #'V',(A2)+
     MOVE.B  #'E',(A2)+
     MOVE.B  #'.',(A2)+
     MOVE.B  #'B',(A2)+
     MOVE.B  #$9,(A2)+
     MOVE.W D0, D5
     MOVE.W D0, D4
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.W D0, D5
     MOVE.W D0, D4
     MOVE.B  #',',(A2)+
     MOVE.B  #32,(A2)+
     JSR EFFECTIVE_ADDRESS_6_8
     BRA PRINT    
  

        JMP     END
code0010:
     MOVE.B #4,D1                 ;IN CASE OF IMMEDIATE DATA
     MOVE.B D0,D3         ;
     MOVE.B D0, D4        ;For effective address
     MOVE.B D0, D5
     MOVE.W D0, D6
     ANDI.W #%0000000111000000,D3
     CMP.W  #%0000000001000000,D3       ;CHECK IF IT IS MOVEA
     BEQ MOVEA      
     BRA MOVE     
MOVEA:
     MOVE.B  #'M',(A2)+
     MOVE.B  #'O',(A2)+
     MOVE.B  #'V',(A2)+
     MOVE.B  #'E',(A2)+
     MOVE.B  #'A',(A2)+
     MOVE.B  #'.',(A2)+
     MOVE.B  #'L',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.B  #',',(A2)+
     MOVE.B #32, (A2)+
     MOVE.W D6, D4
     MOVE.W D6, D5
     JSR ADDRESS_REGISTER_DIRECT2       ;WE KNOW DESTINATION IS ADDRESS REGISTER
     BRA DONE2
MOVE: ;CHECK BITS 8-6 to see if INSTRUCTION IS MOVEA
     MOVE.B  #'M',(A2)+
     MOVE.B  #'O',(A2)+
     MOVE.B  #'V',(A2)+
     MOVE.B  #'E',(A2)+
     MOVE.B  #'.',(A2)+
     MOVE.B  #'L',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.B  #',',(A2)+
     MOVE.B  #32, (A2)+
     MOVE.W D0,D4
     MOVE.W D0,D5
     JSR EFFECTIVE_ADDRESS_6_8
     BRA DONE2                                ;DO DESTINATION  Instruction in D5 right now
        



       JMP     END
code0011:                     ;MOVEA AND MOVE
     MOVE #2,D1                 ;IN CASE OF IMMEDIATE DATA   
     MOVE.B D0,D3         ;
     MOVE.B D0, D4        ;For effective address
     MOVE.B D0, D5
     MOVE.W D0, D6
     ANDI.W #%0000000111000000,D3
     CMP.W  #%0000000001000000,D3       ;CHECK IF IT IS MOVEA
     BEQ MOVEA2      
     BRA MOVE2     
MOVEA2:
     MOVE.B  #'M',(A2)+
     MOVE.B  #'O',(A2)+
     MOVE.B  #'V',(A2)+
     MOVE.B  #'E',(A2)+
     MOVE.B  #'A',(A2)+
     MOVE.B  #'.',(A2)+
     MOVE.B  #'W',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.B  #',',(A2)+
     MOVE.B #32, (A2)+
     MOVE.W D6, D4
     MOVE.W D6, D5
     JSR ADDRESS_REGISTER_DIRECT2       ;WE KNOW DESTINATION IS ADDRESS REGISTER
     BRA DONE2
MOVE2: ;CHECK BITS 8-6 to see if INSTRUCTION IS MOVEA
     MOVE.B  #'M',(A2)+
     MOVE.B  #'O',(A2)+
     MOVE.B  #'V',(A2)+
     MOVE.B  #'E',(A2)+
     MOVE.B  #'.',(A2)+
     MOVE.B  #'W',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.W D0,D4
     MOVE.W D0,D5
     MOVE.B  #',',(A2)+
     MOVE.B  #32, (A2)+
     JSR EFFECTIVE_ADDRESS_6_8
     BRA DONE2                                ;DO DESTINATION  Instruction in D5 right now
          
     
DONE2:
    BRA PRINT
    JMP     END
code0100:
    ; MOVEM, NOP, LEA
    MOVE.W D0,D3 ; D3 used for bits 9-7
     MOVE.W D0,D4 ; D4 used for bits 8-6
     MOVE.W D0,D5 ; D5 used for effective addressing
     ANDI.W #%0000001110000000, D3    ; bits 7-9 0000 0011 1000 0000 = #$0380
     ANDI.W #%0000000111000000, D4    ; bits 6-8 0000 0001 1100 0000 = #$01C0

     CMP.W #$0200,D3      ; bits 9-7 = 100 :  0000 0010 0000 0000 = #$0200
     BEQ NOP      
     CMP.W #$0080,D3      ; bits 9-7 = 001 :  0000 0000 1000 0000 = #$0080
     BEQ MOVEM
     CMP.W #$01C0,D4      ; bits 8-6 = 111 :  0000 0001 1100 0000 = #$01C0
     BEQ LEA
NOP:
    MOVE.B  #'N',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'O',(A2)+
    MOVE.B  #'P',(A2)+
    BRA PRINT
LEA:
    MOVE.B  #'L',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'E',(A2)+
    MOVE.B  #'A',(A2)+
    
    MOVE.B  #$9,(A2)+ ; space

    
    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    JSR EFFECTIVE_ADDRESS_3_5  
    
    MOVE.B  #',',(A2)+
    MOVE.B  #32, (A2)+

    MOVE.L D0, D5 ; done again, incase mode 111 changes D5
    LSR.W   #1, D5 ; register num
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR ADDRESS_REGISTER_DIRECT
    
    BRA PRINT
MOVEM:    
    MOVE.B  #'M',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'O',(A2)+
    MOVE.B  #'V',(A2)+
    MOVE.B  #'E',(A2)+
    MOVE.B  #'M',(A2)+
    MOVE.B  #'.',(A2)+

    CLR D3                        ;If statements to check if word or long
    CLR D4
    MOVE.B D0,D3
    ANDI.B #%01000000, D3                         
    CMP.B #$00,D3       
    BEQ WORD_SIMPLE
    CMP.B #$40,D3
    BEQ LONG_SIMPLE
    
WORD_SIMPLE:
    MOVE.B  #'W',(A2)+
    ;MOVE.B #2,D1        
    BRA MOVEM_DONE
LONG_SIMPLE:
    MOVE.B  #'L',(A2)+
    ;MOVE.B #3,D1        
    BRA MOVEM_DONE
MOVEM_DONE:
     MOVE.B  #$9,(A2)+
     CLR D3
     CLR D4
     
    MOVE.W D5, D3 ; D3 used to check dr
    ANDI.W #%0000010000000000, D3 ; 0000 0100 0000 0000 = #$0400
    CMP.W #$0000,D3 
    BEQ REGISTER_TO_MEMORY
    CMP.W #$0400,D3
    BEQ MEMORY_TO_REGISTER 

REGISTER_TO_MEMORY: 
    MOVE.B  #$9,(A2)+ ; space
    
    CLR D4
    MOVE.B D0, D4 ; mode
    ANDI.B #%00111000, D4
    
    ;REGISTER
    MOVE.W (A6)+, D1 ; D1 : register opcode   
    JSR ADD_REGISTER ; must know mode (in D4)
    MOVE.B  #',',(A2)+
    MOVE.B  #32, (A2)+

    CLR D5
    MOVE.B D0, D5 ; register
    ANDI.B #%00000111, D5
    
    ;MEMORY
    JSR EFFECTIVE_ADDRESS_3_5    
    JMP PRINT

MEMORY_TO_REGISTER:
    MOVE.B  #$9,(A2)+ ; space
    ;MEMORY
    CLR D3
    CLR D4
    MOVE.B D0, D4 ; mode
    ANDI.B #%00111000, D4
    
    MOVE.B D0, D3 ; register
    ANDI.B #%00000111, D3
    
    CMP #%00111000, D4
    BEQ ADDRESS_TO_REGISTER
    
    MOVE.B D3, D5 ; D5 is register
    JSR EFFECTIVE_ADDRESS_3_5
    
    MOVE.B  #',',(A2)+
    MOVE.W (A6)+, D1 ; D3 used for register index
    
    ;REGISTER
    JSR ADD_REGISTER
    JMP PRINT
    
ADDRESS_TO_REGISTER: ; special case for mode 111
    MOVE.W (A6)+, D6 ; pop here (D1 used in ITOA and ADDRESS. temporarally use )
     
    MOVE.B D3, D5 ; D5 is register
    JSR EFFECTIVE_ADDRESS_3_5
    
    MOVE.B  #',',(A2)+
    MOVE.W D6, D1 ; no pop here, instead move register from temp D6 to D1
    CLR D6    
    ;REGISTER
    JSR ADD_REGISTER
    JMP PRINT

;---add register start
ADD_REGISTER:
    MOVE.W #0, D2 ; D2 : index num, used to find register num
    MOVE.W D1,D6 ; Check first index
    ANDI.W #$0000000000000001, D6
    CMP #%0000000000000001, D6
    BEQ ADD_THE_FOUND_REGISTER
             
LOOPFORREGISTER:     
    LSR.W   #1, D1 ; shift right               
    ADD.B #1, D2 ; index +1
    CLR D6
    MOVE.W D1,D6 ; isolate least sig. bit
    ANDI.W #$0000000000000001, D6
    
    CMP #16, D2 ; stop loop if index > 15
    BEQ ADD_REGISTER_END 
    
    CMP #%0000000000000001, D6
    BEQ ADD_THE_FOUND_REGISTER
    BNE LOOPFORREGISTER

ADD_THE_FOUND_REGISTER
    JSR CHECK_IF_PREDEC   
    
    ANDI.W #%1111111111111110, D1 ; Handles Slashes
    CMP #$0000, D1
    BEQ CHECK_IF_CONTINUE_LOOP
    BNE CHECK_IF_CONTINUE_LOOP_SLASH
CHECK_IF_CONTINUE_LOOP:
    CMP #16, D2
    BNE LOOPFORREGISTER
    BEQ ADD_REGISTER_END
CHECK_IF_CONTINUE_LOOP_SLASH
    MOVE.B  #'/',(A2)+
    CMP #16, D2
    BNE LOOPFORREGISTER
    BEQ ADD_REGISTER_END
    
CHECK_IF_PREDEC:
    CMP #%00100000, D4 ; if (mode 100)
    BEQ LOOPFORREGISTER_END_PREDECRIMENT
    CMP #%00100000, D4      
    BNE LOOPFORREGISTER_END
LOOPFORREGISTER_END:
    MOVE.W D2, D5
    CMP #$0007, D2
    BLE DATA_REGISTER_DIRECT
    BGT ADD_ADDRESS_REGISTER
ADD_DATA_REGISTER:
    JSR DATA_REGISTER_DIRECT    
    RTS
ADD_ADDRESS_REGISTER:
    SUB.B #8, D5
    JSR ADDRESS_REGISTER_DIRECT
    RTS

LOOPFORREGISTER_END_PREDECRIMENT:
    CLR D3
    CLR D5
    MOVE.W D2, D3 ; D3 : register index
    CMP #$0007, D2
    BLE ADD_ADDRESS_REGISTER_DIR
    BGT ADD_DATA_REGISTER_DIR
ADD_ADDRESS_REGISTER_DIR
    MOVE.B #7, D5 ; D5 = 7-D3
    SUB.B  D3, D5 
    JSR ADDRESS_REGISTER_DIRECT  
    RTS 
ADD_DATA_REGISTER_DIR:
    MOVE.W D2, D5 ; D5 -= (D3-8)*2
    SUB.B #8, D3  
    MULU  #2, D3
    ADD.B #1, D3
    SUB.B D3, D5
    JSR DATA_REGISTER_DIRECT
    RTS
    
ADD_REGISTER_END:
    RTS
;---add register finish

code0101:
    MOVE.B  #'A',(A2)+            ;ADD INSTRUCT NAME TO BUFFER   ;ADDQ             ADDQ
    MOVE.B  #'D',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  #'Q',(A2)+
    MOVE.B  #'.',(A2)+
                ;ISOLATE TWO BITS USING AND
     MOVE.B D0,D3
     MOVE.B D0, D4        ;For effective address
     ANDI.B #%11000000, D3
     CMP.B #$00,D3       ;If statements to check if byte or word or long
     BEQ BYTE_ADDQ      
     CMP.B #$40,D3
     BEQ WORD_ADDQ
     CMP.B #$80,D3
     BEQ LONG_ADDQ
    
BYTE_ADDQ:                     ;ADD ASCII VALUES TO BUFFER
     MOVE.B  #'B',(A2)+
     BRA NEXT_ADDQ             
WORD_ADDQ:
     MOVE.B  #'W',(A2)+
     BRA NEXT_ADDQ
LONG_ADDQ:
     MOVE.B  #'L',(A2)+
     
    
NEXT_ADDQ:
     MOVE.B  #$9,(A2)+
     MOVE.B  #'#',(A2)+
     MOVE.B  #'$',(A2)+
     CLR D3
     
     MOVE.W D0, D2
     MOVE.B #3 , D3                ;COUNTER
     ANDI.W #%0000111000000000, D2 ;ISOLATE DATA
     ROR.W #8, D2
     ROR.W #1, D2

    
     ADD.W #48, D2
     MOVE.B D2, (A2)+
     MOVE.B  #',',(A2)+
     MOVE.B  #32, (A2)+

    
     CLR D5
     MOVE.B D4,D5
     JSR EFFECTIVE_ADDRESS_3_5
     BRA PRINT       
code0110:                           ;----------BAR BSR--------------
    MOVE.W D0,D1
    ANDI.W #%1111110000000000, D1
    CMP    #%0110000000000000, D1
    BEQ BSR_CODE
    BRA BRA_CODE
BSR_CODE:
   MOVE.B  #'B',(A2)+
   MOVE.B  #'S',(A2)+
   MOVE.B  #'R',(A2)+
   BRA GET_TWOS_COMP
BRA_CODE:  
   MOVE.B  #'B',(A2)+
   MOVE.B  #'A',(A2)+
   MOVE.B  #'R',(A2)+

GET_TWOS_COMP:
   MOVE.B  #32,(A2)+
   
   ANDI.W #%0000000011111111 ,D0
   CMP    #%0000000000000000 ,D0
   BEQ    WORD_DISPLACE
   
   
   BRA BYTE_DISPLACE
   
BYTE_DISPLACE:
   MOVE #2, D3 ;COUNTER
   NOT.W D0                ;ONE BYTE
   ADD.W #1,D0                 ;twos complement
   ROR.W #4,D0
   BRA LOOP_ASCII


WORD_DISPLACE: 
   MOVE #4, D3 ;COUNTER
   MOVE.W #4,D1
   MOVE.W (A6)+ ,D0         
   NOT.W D0                ;ONE BYTE
   ADD.W #1,D0                 ;twos complement
   ROR.W #8,D0
   ROR.W #4,D0
   BRA LOOP_ASCII

  
LOOP_ASCII
   MOVE.W D0, D1
   ANDI.W #$000F, D1
   ROL.W #4, D0
   CMP.B #10, D1
   BLT NUM_ASCII
   BRA HEX_ASCII
NUM_ASCII:
   ADD.B #48,D1
   MOVE.B  D1,(A2)+ 
   BRA NEXT_ASCII
HEX_ASCII:
   ADD.B #55,D1
   MOVE.B  D1,(A2)+ 
NEXT_ASCII:   
   SUBQ.B #1, D3
   BNE LOOP_ASCII
   BRA PRINT   
    
code0111:           ;MOVEQ
    MOVE.B  #'M',(A2)+            ;ADD INSTRUCT NAME TO BUFFER    MOVEQ        MOVEQ
    MOVE.B  #'O',(A2)+
    MOVE.B  #'V',(A2)+
    MOVE.B  #'E',(A2)+
    MOVE.B  #'Q',(A2)+
    MOVE.B  #9,(A2)+
    MOVE.B  #'#',(A2)+
    MOVE.B  #'$',(A2)+
    
    MOVE.W D0, D5
    MOVE #2, D3 ;COUNTER
    ANDI.W #$00FF, D0
    
LOOP_ASCII_2:
   MOVE.W D0, D1
   ANDI.W #$00F0, D1
   ROL.L #4, D0
   ROR.L #4, D1
   CMP.B #10, D1
   BLT NUM_ASCII_2
   BRA HEX_ASCII_2
NUM_ASCII_2:
   ADD.B #48,D1
   MOVE.B  D1,(A2)+ 
   BRA NEXT_ASCII_2
HEX_ASCII_2:
   ADD.B #55,D1
   MOVE.B  D1,(A2)+ 
NEXT_ASCII_2:   
   SUBQ.B #1, D3
   BNE LOOP_ASCII_2
  
   MOVE.B  #',',(A2)+
   MOVE.B  #32,(A2)+
   JSR DATA_REGISTER_DIRECT2
   BRA PRINT


   
code1000:
    ; DIVU
    MOVE.B  #'D',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'I',(A2)+
    MOVE.B  #'V',(A2)+
    MOVE.B  #'U',(A2)+
    MOVE.B  #$9,(A2)+ ; space

    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    JSR EFFECTIVE_ADDRESS_3_5  
    
    MOVE.B  #',',(A2)+
    MOVE.B  #32, (A2)+

    MOVE.L D0, D5 ; done again, incase mode 111 changes D5
    LSR.W   #1, D5 ; register num
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT
    
    BRA PRINT

code1001:
    ; SUB
    MOVE.B  #'S',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'U',(A2)+
    MOVE.B  #'B',(A2)+
    MOVE.B  #'.',(A2)+
    
    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    
    MOVE.L D0, D3 ; opmode
    LSR.L   #6, D3 
    ANDI.W #%00000111, D3
    
    CMP #%00000100, D3
    BLT DESTINATION_MINUS_SOURCE
    BGE SOURCE_MINUS_DESTINATION
    
    
DESTINATION_MINUS_SOURCE:
    CMP #%00000000, D3
    BEQ OP_BYTE_SUB
    CMP #%00000001, D3
    BEQ OP_WORD_SUB
    CMP #%00000010, D3
    BEQ OP_LONG_SUB
    
OP_BYTE_SUB:
    MOVE.B  #'B',(A2)+
    JMP D_M_S_END
OP_WORD_SUB:
    MOVE.B  #'W',(A2)+
    JMP D_M_S_END
OP_LONG_SUB:
    MOVE.B  #'L',(A2)+
    JMP D_M_S_END
    
D_M_S_END:
    MOVE.B  #$9,(A2)+ ; space

    JSR EFFECTIVE_ADDRESS_3_5  
    MOVE.B  #',',(A2)+

    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT
    
    BRA PRINT

SOURCE_MINUS_DESTINATION:
    CMP #%00000100, D3
    BEQ OP_BYTE2_SUB
    CMP #%00000101, D3
    BEQ OP_WORD2_SUB
    CMP #%00000110, D3
    BEQ OP_LONG2_SUB
    
OP_BYTE2_SUB:
    MOVE.B  #'B',(A2)+
    JMP S_M_D_END
OP_WORD2_SUB:
    MOVE.B  #'W',(A2)+
    JMP S_M_D_END
OP_LONG2_SUB:
    MOVE.B  #'L',(A2)+
    JMP S_M_D_END

S_M_D_END:
    MOVE.B  #$9,(A2)+ ; space
    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT

    MOVE.B  #',',(A2)+

    MOVE.L D0, D5 ;register num
    JSR EFFECTIVE_ADDRESS_3_5  
    
    BRA PRINT


code1010:
   ; MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1011:
    ; -------------------------------------------------------------------------------------
    MOVE.B  #'C',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'M',(A2)+
    MOVE.B  #'P',(A2)+
     
    MOVE.B  #'.',(A2)+
    
    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    
    MOVE.L D0, D3 ; opmode
    LSR.L   #6, D3 
    ANDI.W #%00000111, D3
    
    CMP #%00000000, D3 ; byte word or long
    BEQ OP_BYTE_CMP
    CMP #%00000001, D3 
    BEQ OP_WORD_CMP
    CMP #%00000010, D3
    BEQ OP_LONG_CMP

OP_BYTE_CMP:
    MOVE.B  #'B',(A2)+
    JMP CMP_END
OP_WORD_CMP:
    MOVE.B  #'W',(A2)+
    JMP CMP_END
OP_LONG_CMP:
    MOVE.B  #'L',(A2)+
    JMP CMP_END
    
CMP_END:
    MOVE.B  #$9,(A2)+ ; space

    JSR EFFECTIVE_ADDRESS_3_5  
    
    MOVE.B  #',',(A2)+
    
    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT
        
    BRA PRINT
; ------------------------------------------------------------------------------------


code1100:            ;MULU
    MOVE.B  #'M',(A2)+
    MOVE.B  #'U',(A2)+
    MOVE.B  #'L',(A2)+
    MOVE.B  #'U',(A2)+
    MOVE.B  #'.',(A2)+
    MOVE.B  #'W',(A2)+
 
   MOVE.B #9, (A2)+
   JSR EFFECTIVE_ADDRESS_3_5
   MOVE.B  #',',(A2)+
   MOVE.B #32, (A2)+
   JSR DATA_REGISTER_DIRECT2
   BRA PRINT





code1101:
    ; ADD, ADDA ; -------------------------------------------------------------------------------------
    MOVE.L D0, D3 ; opmode
    LSR.L   #6, D3 
    ANDI.W #%00000111, D3
    
    CMP #%00000011, D3 ; if opmode - 011 or 111, do ADDA, else do ADD
    BEQ ADDA
    CMP #%00000111, D3
    BEQ ADDA
    
    JMP ADD

ADD:
    MOVE.B  #'A',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'D',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  #'.',(A2)+
    
    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    
    MOVE.L D0, D3 ; opmode
    LSR.L   #6, D3 
    ANDI.W #%00000111, D3
    
    CMP #%00000100, D3
    BLT DESTINATION_PLUS_SOURCE
    BGE SOURCE_PLUS_DESTINATION
    
    
DESTINATION_PLUS_SOURCE:
    CMP #%00000000, D3
    BEQ OP_BYTE_ADD
    CMP #%00000001, D3
    BEQ OP_WORD_ADD
    CMP #%00000010, D3
    BEQ OP_LONG_ADD
    
OP_BYTE_ADD:
    MOVE.B  #'B',(A2)+
    JMP D_P_S_END
OP_WORD_ADD:
    MOVE.B  #'W',(A2)+
    JMP D_P_S_END
OP_LONG_ADD:
    MOVE.B  #'L',(A2)+
    JMP D_P_S_END
    
D_P_S_END:
    MOVE.B  #$9,(A2)+ ; space

    JSR EFFECTIVE_ADDRESS_3_5  
    MOVE.B  #',',(A2)+

    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT
    
    BRA PRINT

SOURCE_PLUS_DESTINATION:
    CMP #%00000100, D3
    BEQ OP_BYTE2_ADD
    CMP #%00000101, D3
    BEQ OP_WORD2_ADD
    CMP #%00000110, D3
    BEQ OP_LONG2_ADD
    
OP_BYTE2_ADD:
    MOVE.B  #'B',(A2)+
    JMP S_P_D_END
OP_WORD2_ADD:
    MOVE.B  #'W',(A2)+
    JMP S_P_D_END
OP_LONG2_ADD:
    MOVE.B  #'L',(A2)+
    JMP S_P_D_END

S_P_D_END:
    MOVE.B  #$9,(A2)+ ; space
    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR DATA_REGISTER_DIRECT

    MOVE.B  #',',(A2)+
    MOVE.B  #32, (A2)+

    MOVE.L D0, D5 ;register num
    JSR EFFECTIVE_ADDRESS_3_5  
    
    BRA PRINT
; -------------------------------------------------------------------------------------
    
ADDA:
    MOVE.B  #'A',(A2)+            ;ADD INSTRUCT NAME TO BUFFER
    MOVE.B  #'D',(A2)+
    MOVE.B  #'D',(A2)+
    MOVE.B  #'A',(A2)+

    MOVE.B  #'.',(A2)+
    
    MOVE.W D0, D4 ;mode
    MOVE.L D0, D5 ;register num
    
    MOVE.L D0, D3 ; opmode
    LSR.L   #6, D3 
    ANDI.W #%00000111, D3
    
    CMP #%00000011, D3 ; word or long
    BEQ OP_WORD_ADDA
    CMP #%00000111, D3
    BEQ OP_LONG_ADDA
    
OP_WORD_ADDA:
    MOVE.B  #'W',(A2)+
    JMP ADDA_END
OP_LONG_ADDA:
    MOVE.B  #'L',(A2)+
    JMP ADDA_END
    
ADDA_END:
    MOVE.B  #$9,(A2)+ ; space

    JSR EFFECTIVE_ADDRESS_3_5  
    MOVE.B  #',',(A2)+

    MOVE.L D0, D5 ; register2 // done again just incase
    LSR.W   #1, D5
    LSR.L   #8, D5 
    ANDI.W #%00000111, D5
    JSR ADDRESS_REGISTER_DIRECT
    
    BRA PRINT
; -------------------------------------------------------------------------------------
    

code1110:   ;--------------ASL ASR
    MOVE.W D0,D5
    MOVE.W D0, D4
    MOVE.W D0, D1
    MOVE.B  #'A',(A2)+
    MOVE.B  #'S',(A2)+
    ANDI.W #%0000000100000000, D1
    CMP #%0000000000000000,D1
    BEQ SHIFT_RIGHT
    BRA SHIFT_LEFT
SHIFT_RIGHT:
    MOVE.B  #'R',(A2)+
    BRA SIZE_1110
SHIFT_LEFT:
    MOVE.B  #'L',(A2)+

SIZE_1110:
    MOVE.B  #'.',(A2)+

    MOVE D0, D1
    ANDI.W #%1111111011000000, D1
    CMP    #%1110000011000000, D1
    BEQ MEMORY_SHIFT
    MOVE.W D0, D1
    ANDI.W #%0000000011000000,D1  ;;ISOLATE SIZE
    CMP    #%0000000000000000, D1
    BEQ BYTE_1110
    CMP    #%0000000001000000, D1
    BEQ WORD_1110
    BRA LONG_1110
BYTE_1110:                            ;SIZE
    MOVE.B  #'B',(A2)+
    BRA REG_TO_REG_OR_DATA_TO_REG
WORD_1110:
    MOVE.B  #'W',(A2)+
    BRA REG_TO_REG_OR_DATA_TO_REG
LONG_1110:
    MOVE.B  #'L',(A2)+

REG_TO_REG_OR_DATA_TO_REG:    ;CHECK IF REGISTER TO REGISTER OR IMMEDIATE DATA TO REGISTER
    MOVE.B  #9,(A2)+
    MOVE.W D0,D1
    ANDI.W #%0000000000100000,D1
    CMP    #%0000000000000000,D1
    BEQ IMMEDIATE_SHIFT        ;IMMEDIATE DATA SHIFT
    BRA REGISTER_TO_REGISTER   ;REGISTER WITH SHIFT VALUE
IMMEDIATE_SHIFT:   
    MOVE.B  #'#',(A2)+
    MOVE.W D0,D1
    ANDI.W #%0000111000000000, D1
    CMP    #%0000000000000000,D1
    BEQ EIGHT_1110         ;WHEN SHIFT VALUE IS EIGHT
    ROR.W #8, D1
    ROR.W #1, D1
    ADD.W #48, D1
    MOVE.B D1, (A2)+     ;ADD SHIFT COUNT
    MOVE.B  #',',(A2)+     ;COMMA
    MOVE.B  #32,(A2)+    ;SPACE
    JSR DATA_REGISTER_DIRECT
    BRA PRINT
EIGHT_1110:
    MOVE.B  #56,(A2)+
    MOVE.B  #',',(A2)+
    MOVE.B  #32,(A2)+
    JSR DATA_REGISTER_DIRECT
    BRA PRINT
REGISTER_TO_REGISTER:
    JSR DATA_REGISTER_DIRECT2
    MOVE.B  #',',(A2)+
    MOVE.B  #32,(A2)+
    MOVE.W D0,D5
    JSR DATA_REGISTER_DIRECT
    BRA PRINT

MEMORY_SHIFT:
     MOVE.B  #'W',(A2)+
     MOVE.B  #9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5    
     BRA PRINT


code1111:
    ;MOVEA.L   #TRUE, A1 
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
    TRAP    #15
    JMP     END

EFFECTIVE_ADDRESS_3_5: ;BITS 3-5 EA CALCULATION
                             
     ANDI.W #%0000000000111000,D4                        ;;DO SOURCE IS EQUAL FOR BOTH
     CMP #%00010000, D4
     BEQ ADDRESS_REGISTER_INDIRECT               ;ADDRESS REGISTER INDIRECT
     CMP #%00000000, D4
     BEQ DATA_REGISTER_DIRECT           ;Data register direct
     CMP #%00011000, D4
     BEQ ADDRESS_REGISTER_INCREMENT           ;Go to post increment
     CMP #%00100000, D4
     BEQ ADDRESS_REGISTER_DECREMENT             ;Go to address register decrement
     CMP #%00111000, D4
     BEQ ABSOLUTE_ADDRESS_OR_IMMED_DATA      ;Go to absolute addressing
     CMP #%00001000, D4
     BEQ ADDRESS_REGISTER_DIRECT

DATA_REGISTER_DIRECT:
        MOVE.B  #'D',(A2)+   ;D4 has value
        ANDI.B #%00000111, D5  
        ADD.B #48, D5        ;ADD FOR ASCII
        MOVE.B  D5,(A2)+
        RTS
ADDRESS_REGISTER_DIRECT:
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.B #%00000111, D5    ;ISOLATE REGISTER VALUE
        ADD.B #48, D5         ;ADD FOR ASCII
        MOVE.B  D5,(A2)+     ;NUmber
        RTS

ADDRESS_REGISTER_INDIRECT:
        MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.B #%00000111, D5  ;ISOLATE REGISTER VALUE
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        RTS

ADDRESS_REGISTER_INCREMENT:
         MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.B #%00000111, D5  
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        MOVE.B  #'+',(A2)+
        RTS

ADDRESS_REGISTER_DECREMENT:
        MOVE.B  #'-',(A2)+
        MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.B #%00000111, D5  
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        RTS

ABSOLUTE_ADDRESS_OR_IMMED_DATA:
        ANDI.W #%00000111, D5
        CMP.B  #%00000100, D5 ;IF IMMEDIATE DATA
        BEQ IMMEDIATE_DATA
        BRA ADDRESS
IMMEDIATE_DATA:         
        MOVE.B  #'#',(A2)+
        MOVE.B  #'$',(A2)+
        ;CMP #1,D1
        ;BEQ REMOVE1
       ; CMP #3, D1
        ;BEQ REMOVE2
        ;BRA FIXED    ;BRANCH TO FIXED IF WORD
;REMOVE1:              ;BYTE
    ;   MOVE.B (A6)+,D7  ;REMOVE ZEROS
      ; BRA FIXED
;REMOVE2:
      ; MOVE.B (A6)+,D7
       ;BRA FIXED
;FIXED:        

        JSR ITOA
        MOVE.W D6, D5
        RTS
ADDRESS:       
        MOVE.B  #'$',(A2)+       ;IS ADDRESS
        CMP.B #%00000000, D5    ;ABSOLUTE ADDRESS IS WORD LENGTH
        BEQ WORD_LENGTH
        CMP.B #%00000001, D5
        BEQ LONG_LENGTH
WORD_LENGTH:        
        MOVE.B #2,D1
        JSR ITOA
        RTS
LONG_LENGTH:
        MOVE.B #4,D1
        JSR ITOA
        RTS

EFFECTIVE_ADDRESS_6_8:                                  ;BITS 6-8
     ANDI.L #%0000000000111000000,D4                        ;;DO SOURCE IS EQUAL FOR BOTH
     CMP #%010000000, D4
     BEQ ADDRESS_REGISTER_INDIRECT2               ;ADDRESS REGISTER INDIRECT
     CMP #%000000000, D4
     BEQ DATA_REGISTER_DIRECT2           ;Data register direct
     CMP #%011000000, D4
     BEQ ADDRESS_REGISTER_INCREMENT2           ;Go to post increment
     CMP #%100000000, D4
     BEQ ADDRESS_REGISTER_DECREMENT2             ;Go to address register decrement
     CMP #%111000000, D4
     BEQ ABSOLUTE_ADDRESS_OR_IMMED_DATA2      ;Go to absolute addressing
     CMP #%001000000, D4
     BEQ ADDRESS_REGISTER_DIRECT2
        
DATA_REGISTER_DIRECT2:
        MOVE.B  #'D',(A2)+   ;D5 has value
        ANDI.W #%111000000000, D5  ;ISOLATE REGISTER 
        DIVU.W #512, D5      ;DIVIDE BY 512 TO GET IT SO THOSE THREE BITS ARE LEAST SIGNIFICANT BITS
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        RTS
ADDRESS_REGISTER_DIRECT2:
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.W #%111000000000, D5  
        DIVU.W #512, D5 
        ADD.B #48, D5
        MOVE.B  D5,(A2)+     ;NUmber
        RTS

ADDRESS_REGISTER_INDIRECT2:
        MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.W #%111000000000, D5 
        DIVU.W #512, D5 
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        RTS

ADDRESS_REGISTER_INCREMENT2:
         MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.W #%111000000000, D5  
        DIVU.W #512, D5 
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        MOVE.B  #'+',(A2)+
        RTS

ADDRESS_REGISTER_DECREMENT2:
        MOVE.B  #'-',(A2)+
        MOVE.B  #'(',(A2)+   ;D4 has value
        MOVE.B  #'A',(A2)+   ;D4 has value
        ANDI.W #%111000000000, D5  
        DIVU.W #512, D5 
        ADD.B #48, D5
        MOVE.B  D5,(A2)+
        MOVE.B  #')',(A2)+   ;D4 has value
        RTS

ABSOLUTE_ADDRESS_OR_IMMED_DATA2:        MOVE.B  #'$',(A2)+
        ANDI.W #%111000000000, D5
        CMP    #%100000000000, D5
        BEQ IMMEDIATE_DATA2
        BRA ADDRESS2
IMMEDIATE_DATA2:
        MOVE.B  #'#',(A2)+
        MOVE.B  #'$',(A2)+
        ;CMP #1,D1       ;REMOVE ZEROS
       ; BEQ REMOVE3
        ;CMP #3, D1
        ;;BEQ REMOVE4
        ;BRA FIXED2
;REMOVE3:
      ; MOVE.B (A6)+,D7
      ; BRA FIXED2
;REMOVE4:
    ;  MOVE.B (A6)+,D7
       ;BRA FIXED2
;FIXED2:        
        JSR ITOA
        MOVE.W D6, D5
        RTS
ADDRESS2:        
        CMP #%000000000000, D5    ;ABSOLUTE ADDRESS IS WORD LENGTH
        BEQ WORD_LENGTH2
         CMP #%001000000000, D5 
        BEQ LONG_LENGTH2
WORD_LENGTH2:        
        MOVE.B #2,D1
        JSR ITOA
        RTS
LONG_LENGTH2:
        MOVE.B #4,D1
        JSR ITOA
        RTS

        
        
ITOA:
    CLR D5
LOOPFORASCII: 
     MOVE.B (A6)+,D5 ;get two hex values
     MOVE.W D5,D2     ; put it in a word so rotating works
     ROR.W #4, D2     ;ROTATE four bits so they end up on far left side, and isolates other 4 bits
     
     CMP.B #10, D2
     BLT NUMBER
     BRA HEX
NUMBER:
     ADD.B #48, D2    
     BRA NEXT 
HEX:     
     ADD.B #55, D2    ;Add the the four least significant bits
     BRA NEXT
NEXT:     
     MOVE.B  D2,(A2)+ ;MOVE ASCII VALUE TO BUFFER
     SUB.B D2,D2 ;Get rid of value already read
     ROL.W #4, D2     ;ROTATE FOUR BITS BACK TO FRONT
     
     CMP.B #10, D2
     BLT NUMBER2
     BRA HEX2
NUMBER2:
     ADD.B #48, D2    
     BRA NEXT2 
HEX2:     
     ADD.B #55, D2    ;Add the the four least significant bits
     BRA NEXT2
NEXT2:     
      MOVE.B  D2,(A2)+   ;ADD to BUFFER
     SUB.B D2,D2        ;REMOVE BITS
     SUBQ.B #1, D1      ;DECREMENT LOOP
     BNE LOOPFORASCII
     RTS

PRINT:
     MOVE.B #0, (A2)+         ;ADD NULL TERMINATER
     MOVE.B  #13, D0         ; PRINT BUFFER
     LEA     buffer, A1
     TRAP    #15

OP_DATA_CLR:
        CLR.L   D3
        MOVE.B  #bufsize, D3        ; D3 = bufsize as a counter
                ; for ( int D3 = 64; D3 > 0; D3--)
OP_DATA_CLR_LOOP:
        MOVE.B  #0, (A1)+           ;   (An)++ = $0;
        SUBI    #1, D3
        BGT     OP_DATA_CLR_LOOP
     
     CMP.L A6,D7        ;------------------------------------------CHECK IF ENDED A6 CURRENT ADDRESS D7 END ADDRESS
     BGT Loop2
     BRA CONTINUE_OR_QUIT
   
   
CONTINUE_OR_QUIT:
    
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
    MOVEA   #CONTINUEPROMPT, A1    ;GET y n or empty
    TRAP    #15                    :PRINT IT
    MOVEA $0000, A1
    MOVE.L  #2, D0      * read from the keyboard
    CLR D1
    TRAP    #15  
    
    CLR D7
    MOVE.B (A1)+,D7  ;GETS Y or N
 
    CMP #'Y',D7
    BEQ TAKE_INPUT
    CMP #'N',D7 
    BEQ EXIT_MESSAGE
EXIT_MESSAGE:
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
    MOVEA   #EXITMESSAGE, A1    ;GET y n or empty
    TRAP    #15                    :PRINT IT


    BRA END         
   

  
  
TAKE_INPUT:
    CLR D7
    MOVE.W #$00,(A6)
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
    MOVEA   #PROMPT, A1
    TRAP    #15
    LEA     START_ADDRESS, A1  ; address to store address
    MOVE.L  #2, D0      * read from the keyboard
    CLR D1
    TRAP    #15         ;address now in A1
    
    JSR ATOI                        ;FOR THE START ADDRESS       
    
    MOVE.L D7,A6
    CLR D7                   ;MOVE START ADDRESS TO D2            
    MOVE.W  #0, D0    
    MOVE.W  #64, D1
    MOVEA   #ENDPROMPT, A1    ;GET END ADDRESS
    TRAP    #15                     ;PRINT PROMPT 
    LEA     END_ADDRESS, A1         ; address to store address
    MOVE.L  #2, D0                  * read from the keyboard
    CLR D1
    TRAP    #15                        ;address now in A1
    JSR ATOI                  ;END ADDRESS in D7
    BRA DECODE
    BRA VERIFY

ATOI:   
     CLR D3
     MOVEA.L A1, A3      ; A2 = string pointer to next character to capitalize
     MOVE.L #256, D6     ;Use to convert to HEX
; -48 loop
Loop1
    CLR D5
    MOVE.B (A3)+,D5  ; make number (-48; -00110000)
    SUBI.L #48, D5   ;Get decimal value by subtracting 48
    MULS.W D6, D5     ; multiply it by D5 to get the answer in hex
    ADD.L D5,D7       ;Add the result to D7 eventualy add up to the full hex value
    DIVS.W #16, D6     ; Divide D6 so that the value is converted to its position in hex
    SUBQ.L #1, D1       ; decriment loop counter
    BNE Loop1           ; loops untill D2 reaches 0
    RTS                  
   


    SIMHALT             ; halt simulator

* Put variables and constants here
   INTRO: DC.B    'Welcome to 68K disassembler',0 ;64 bytes
   ENDPROMPT: DC.B 'Enter end address: ',0 ;64 bytes
   CONTINUEPROMPT: DC.B    'Enter Y or N to restart or stop the dissasembler',0 ;64 bytes
   EXITMESSAGE: DC.B    'Thanks for using this 68K disassemble, goodbye',0 ;64 bytes
   ERRORMESSAGE: DC.B    'Error : start address is greater than end address',0 ;64 bytes

PROMPT:
   DC.B    'Enter start address: ',0 ;64 bytes
START_ADDRESS:
    DS    64
END_ADDRESS:
    DS    64

         ; last line of source





bufsize	EQU	64	; 64 characters would be good enough
buffer	DS.B	bufsize	; a line of decoded data to print to screen

END
      END  START 







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
