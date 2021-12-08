*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

;First my implementation takes the following strategies:
;(a) Let A0 point to the top address of a given jump table
;(b) Let A5 point to the current machine code.
;(c) Use D0 to keep the 1st instruction word
    
    
    ; NOTE TO SELF : Focus testing on getting A5 to a certain number, say 1010, which should be A000, or A00 (because 3*4)
    
    MOVEA.L #$0400, A5 
    LEA     buffer, A2          
    ; load the next instruction and jump to the opcode table entry
    LEA     OP_TABLE, A0
    CLR.L   D0
    MOVE.W  (A5)+, D0           ; load the current instruction word to D0
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
    JMP     code1010            ;     (unassigned)
    JMP     code1011            ; CMP.bwl /CMPA.wl /EOR.bwl
    JMP     code1100            ; MULS    /MULU    /AND.bwl
    JMP     code1101            ; ADD.bwl /ADDA.wl /ADDX.bwl
    JMP     code1110            ; ASL.bwl/ASR.bwl/LSL.bwl /LSR.bwl /ROL.bwl /ROR.bwl
    JMP     code1111            ;     (unassigned)
code0000:
    
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
     MOVE.B (A5)+,D5       ;CLEAR ZEROS
     CLR D5
     BRA DONE             ;after adding size character go to routine to add immediate data (CONVERT HEX TO ASCII)
WORD:
     MOVE.B  #'W',(A2)+
     MOVE.B #2,D1        ;Make loop counter 2 for the the 4 HEX VALUES that make up 16 bits, 4 bytes
     BRA DONE
LONG:
     MOVE.B  #'L',(A2)+
     MOVE.B #3,D1          ;COUNTER
     MOVE.B (A5)+,D5       ;CLEAR ZEROS
     CLR D5
     BRA DONE
DONE:
     MOVE.B  #$9,(A2)+
     MOVE.B  #'#',(A2)+
     MOVE.B  #'$',(A2)+
     CLR D3
     
     JSR ITOA                 ;RETURNS HERE AFTER CONVERSION
     MOVE.B  #$9,(A2)+
     MOVE.B  #',',(A2)+

     CLR D5
     MOVE.B D4,D5
     JSR EFFECTIVE_ADDRESS_3_5
     BRA PRINT                       
        ;JMP     END
code0001: ;MOVEA and MOVE
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
     JSR EFFECTIVE_ADDRESS_6_8
     BRA PRINT    
  

        JMP     END
code0010:
        JMP     END
code0011:                     ;MOVEA AND MOVE
        
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
     MOVE.B  #'W',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.B  #',',(A2)+
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
     MOVE.B  #'W',(A2)+
     MOVE.B  #$9,(A2)+
     JSR EFFECTIVE_ADDRESS_3_5
     MOVE.B  #',',(A2)+
     JSR EFFECTIVE_ADDRESS_6_8
     BRA DONE2                                ;DO DESTINATION  Instruction in D5 right now
          
     
DONE2:
    BRA PRINT
    JMP     END
code0100:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code0101:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code0110:
    MOVEA   #FALSE, A1 ;TRUE
    TRAP    #15
    JMP     END
code0111:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1000:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1001:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1010:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1011:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1100:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1101:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1110:
    MOVEA   #FALSE, A1 
    TRAP    #15
    JMP     END
code1111:
    MOVEA.L   #TRUE, A1 
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
     BEQ ABSOLUTE_ADDRESS      ;Go to absolute addressing
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

ABSOLUTE_ADDRESS:
        MOVE.B  #'$',(A2)+
        ANDI.W #%00000111, D5
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
     BEQ ABSOLUTE_ADDRESS2      ;Go to absolute addressing
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

ABSOLUTE_ADDRESS2:
        MOVE.B  #'$',(A2)+
        ANDI.W #%111000000000, D5
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
    
LOOPFORASCII: 
     MOVE.B (A5)+,D5 ;get two hex values
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

 
TRUE: DC.B    'True',0 ;64 bytes
FALSE: DC.B    'False',0 ;64 bytes
ENDING: DC.B    'Ending',0 ;64 bytes


bufsize	EQU	64	; 64 characters would be good enough
buffer	DS.B	bufsize	; a line of decoded data to print to screen

END:
;    MOVEA   #ending, A1 
;    TRAP    #15
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source
    






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
