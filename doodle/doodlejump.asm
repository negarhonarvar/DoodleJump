; commands for dosbox:
; mount c "LOCATION"
; c:
; dir to access directory
; masm /a "CODE FILE NAME"
; link "FILE NAME"
; write  ";" as run file to skip 3 following enters , then we have 
; access to runnable file and execute it
; the command to do the above is simply writing the file name
STACK SEGMENT para STACK
   DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT para 'DATA'
    TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ;text with the game over menu title
	SCORE_TITLE DB 'SCORE : ','$' 
	SCORE DW 0h
	COLOR DB 0dh
                           ; definning screen dimension variables
	WINDOW_WIDTH DW 140H   ; the width of the window (320 pixels)
	WINDOW_HIGHT DW 0C8H   ; the hight of the window (200 pixels)
	WINDOW_BOUNDS DW 6     ; variable used to check collisions early
                           ; definning time variables 
	TIME_AUX DB 0          ; variable used when checking if the time has changed
	                       ; variables used for balls initial position
	BALL_ORIGINAL_X DW 0A0h
	BALL_ORIGINAL_Y DW 15h
                           ; defining ball variables ( DW: define word (16 bits)):
    BALL_X DW 0A0h         ; X position (column) of the ball
    BALL_Y DW 15h          ; Y position (line) of the ball
    BALL_SIZE DW 04h       ; it indicates the size of ball , it draws a ball with radius 4 => s=16
	BALL_VELOCITY_X DW 05H ; horizontal velocity of the ball 
	BALL_VELOCITY_Y DW 02H ; vertical velocity of the ball
	                       ; creating platform variables
	PLATFORM_X DW 07Ah
	PLATFORM_Y DW 03Ah
	PLATFORM_WIDTH DW 1fh
	PLATFORM_HEIGHT DW 06h
	
	BROKEN_PLATFORM_X DW 0EAh
	BROKEN_PLATFORM_Y DW 0FAh
	BROKEN_PLATFORM_WIDTH DW 20h
	BROKEN_PLATFORM_HEIGHT DW 06h
	
	BUG_X DW 03Ah	
	BUG_WIDTH DW 04h
	BUG_HEIGHT DW 06h
	BUG_Y DW 08Ah

DATA ENDS

CODE SEGMENT para 'CODE'
    MAIN PROC FAR
	               ; we need to declare the segments in order to correctly use the variable defined in DS segment
	               ; telling the code to assume following segments as respective registers
    ASSUME CS:CODE, DS:DATA, SS:STACK 
	PUSH DS        ; push to the stack the DS SEGMENT
	SUB AX,AX      ; clean th AX register
	PUSH AX        ; push AX to the stack 
	MOV AX,DATA    ; save on the AX register the contents of DATA segment
	MOV DS,AX      ; save on the DS segment the contents of AX 
	POP AX         ; release the top item from the stack to the AX register
	POP AX         ; doing it twice to avoid our game from crashing
	
                                      ;for drawing pixels we use INT 10H interrupt
		
	    CALL CLEAR_SCREEN
		
		                              ;implementing time
		CHECK_TIME:
		     MOV AH,2CH               ; interruption to get system time
		     INT 21H                  ; CH = hour CL = minute DH = second DL = 1/100 seconds
		     CMP DL,TIME_AUX		  ; is the current time=prevoius time ?(TIME_AUX)
		     JE CHECK_TIME            ; jump to the lable if its equal to get new time and check again
			 
			                          ;if the time has changed we proceed with the drawing
			 MOV TIME_AUX,DL          ; update time
		
		     CALL CLEAR_SCREEN        ; calling this proc to clear the ball trail		     
			 
			 CALL MOVE_BALL
				
			 CALL MOVE_BALL_WITH_KEYS ; calling the procedure to move ball
			 
			 CALL CHECK_FOR_BUG       ; calling the procedure to check for collosion with bugs
			 
		     CALL DRAW_BALL           ;calling the DRAW_BALL PROC
			 
			 CALL DRAW_PLATFORM       ; calling the procedure to draw the platforms
			 
			 CALL DRAW_BROKEN_PLATFORM; calling the procedure to draw the platforms
			 
		     JMP CHECK_TIME           ; checks time again
		
        RET                           ; return from this proc 
    MAIN ENDP                         ; p is for proc 

    CHECK_FOR_BUG proc near 
			 MOV AX, BALL_X           ; to check the collision of ball with the bug we need to check this conditions:
			 MOV BX, BUG_X            ; if BALL_X=< BUG_X+BUG_WIDTH
			 ADD BX, BUG_WIDTH
			 CMP AX, BX
			 JG RET_                  ; whenever each part of the condition is not happening , we exit the condition through ret_ label    
                            		  ; now we need to check if the second part of the condition is true
			 
			 MOV AX, BALL_X           ; && BALL_X+BALL_SIZE>= BUG_X => first two parts of the condition is satisfied
			 ADD AX, BALL_SIZE
			 MOV BX, BUG_X
			 CMP AX, BX
			 JL RET_
			 
			 MOV AX, BALL_Y           ; check if ball_y ~ bug_y => collosion
			 MOV BX,BUG_Y
			 SUB BX, AX
			 CMP BX, 03H
			 JNL RET_
			 
			 GAME_OVER:
			  CALL DRAW_GAME_OVER_MENU
			 
			 RET_:
				RET
			

    CHECK_FOR_BUG ENDP
 
	
	SHOW_SCORE PROC NEAR   ;print Score
	    
		MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, " "
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, "S"
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, "C"
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, "O"
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, "R"
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, "E"
        INT     10H
		
		MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, " "
        INT     10H

        MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, ":"
        INT     10H
		
		MOV BX, 000FH
        MOV     AH, 0EH
        MOV     AL, " "
        INT     10H

        CALL PRINT_NUMBER
    RET
	
    SHOW_SCORE ENDP


    PRINT_NUMBER PROC NEAR     ;print the score digit by digit
				               ;mov bx, 000Fh
			 MOV CX,0
			 MOV BX,0AH        ;bx=10 for dividing
			 
			 
			 MOV AH,00H 
			 MOV AX,SCORE     ; PRINT

    DIVIDER:
			 DIV BL    
			 INC CX 
			 MOV BH ,0
			 MOV BL,AH
			 PUSH BX
			 MOV BL,0AH 
			 MOV AH,0
			 CMP AL ,0               
			 JE PRINT_IN_CONSOLE     
			 JMP DIVIDER
			RET
			
    PRINT_NUMBER ENDP

	PRINT_IN_CONSOLE PROC NEAR
			
		  PRINT:   
			
			POP AX 
			MOV BX , 000FH
			MOV AH , 0EH
		 
			ADD AL , 030H
			INT 10H
			
			LOOP PRINT 

		 RET
    
    PRINT_IN_CONSOLE ENDP
	
	DRAW_BALL PROC NEAR 
	

	    CALL SHOW_SCORE
		MOV CX,BALL_X                ; set the initial column (x) 
		MOV DX,BALL_Y                ; set the initial line (y) 
		
		                             ; initializing the loops:
		DRAW_BALL_HORIZONTAL:
		MOV AH,0Ch                   ; set the configuration to writing a pixel
		MOV AL,COLOR                 ; choosing color white for pixel , 0fh is code for color white
		MOV BH,00H                   ; setting the page number to 0 since we only have 1 Page
		INT 10h                      ; execute the configuration
        INC CX                       ; cx = cx + 1
		
		                             ; now we need to implemnt the command to indicate the loop end
		                             ; loop end condition :cx-BALL_X>BALL_SIZE (T:end the loop , F:continue)
		MOV AX,CX                    ; AX as temp register
        SUB AX,BALL_X                ; CX - BALL_X
        CMP AX,BALL_SIZE             ; cx-BALL_X>BALL_SIZE
        JNG DRAW_BALL_HORIZONTAL 	 ; JUMP NOT GREATER	
		MOV CX,BALL_X                ; setting the cx to its initial value
		INC DX                       ; going to the next line and drawing ball vertically
		
		                             ; vertical drawing condition :
                                     ; cx-BALL_Y>BALL_SIZE (T:exit the proc , F:continue from the DRAW_BALL_HORIZONTAL lable)
		MOV AX,DX   		         ; AX as temp register  
		SUB AX,BALL_Y                ; CX - BALL_Y
		CMP AX,BALL_SIZE             ; cx-BALL_Y>BALL_SIZE
		JNG DRAW_BALL_HORIZONTAL
		
		CALL FIX_BALL

		MOV CX,BUG_X                 ; SET THE INITIAL COLUMN (X) 
		MOV DX,BUG_Y                 ; set the initial line (y) 
		
		                             ; initializing the loops:
		DRAW_BUG_HORIZONTAL:
		MOV AH,0Ch                   ; set the configuration to writing a pixel
		MOV AL,78H                   ; choosing color white for pixel , 0fh is code for color white
		MOV BH,00H                   ; setting the page number to 0 since we only have 1 Page
		INT 10h                      ; execute the configuration
        INC CX                       ; cx = cx + 1
		
		                             ; now we need to implemnt the command to indicate the loop end
		                             ; loop end condition :cx-BALL_X>BALL_SIZE (T:end the loop , F:continue)
		MOV AX,CX                    ; AX AS TEMP REGISTER
        SUB AX,BUG_X                 ; CX - BALL_X
        CMP AX,BUG_WIDTH             ; CX-BALL_X>BALL_SIZE
        JNG DRAW_BUG_HORIZONTAL 	 ; JUMP NOT GREATER	
		MOV CX,BUG_X                 ; SETTING THE CX TO ITS INITIAL VALUE
		INC DX                       ; GOING TO THE NEXT LINE AND DRAWING BALL VERTICALLY
		
		                             ; VERTICAL DRAWING CONDITION : 
		                             ; CX-BALL_Y>BALL_SIZE (T:EXIT THE PROC , F:CONTINUE FROM THE DRAW_BALL_HORIZONTAL LABLE)
		MOV AX,DX   		         ; AX AS TEMP REGISTER  
		SUB AX,BUG_Y                 ; CX - BALL_Y
		CMP AX,BUG_HEIGHT            ; CX-BALL_Y>BALL_SIZE
		JNG DRAW_BUG_HORIZONTAL
        RET
    DRAW_BALL ENDP	
	
	FIX_BALL PROC  NEAR

    

		  MOV CX,BALL_X                
		  MOV DX,BALL_Y  
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H
		  
		  MOV CX,BALL_X      
		  INC CX
		  MOV DX,BALL_Y               
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H  

		  MOV CX,BALL_X       
		  MOV DX,BALL_Y
		  INC DX 
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H  

		  MOV CX,BALL_X                
		  MOV DX,BALL_Y                     
		  ADD DX,BALL_SIZE
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H       
		  INT 10H

		  MOV CX,BALL_X    
		  INC CX
		  MOV DX,BALL_Y                     
		  ADD DX,BALL_SIZE
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H       
		  INT 10H

		  MOV CX,BALL_X    
		  MOV DX,BALL_Y                     
		  ADD DX,BALL_SIZE
		  DEC DX
		  MOV AH,0CH                   
		  MOV AL,0      
		  MOV BH,00H       
		  INT 10H

		  MOV CX,BALL_X                 
		  ADD CX,BALL_SIZE
		  MOV DX,BALL_Y                  
		  MOV AH,0CH                  
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H  

		  MOV CX,BALL_X                 
		  ADD CX,BALL_SIZE
		  DEC CX
		  MOV DX,BALL_Y                  
		  MOV AH,0CH                  
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H    

		 
		  MOV CX,BALL_X                 
		  ADD CX,BALL_SIZE
		  MOV DX,BALL_Y 
		  INC DX
		  MOV AH,0CH                  
		  MOV AL,0      
		  MOV BH,00H      
		  INT 10H    

		  MOV CX,BALL_X                    
		  MOV DX,BALL_Y                    
		  ADD CX,BALL_SIZE
		  ADD DX,BALL_SIZE 
		  MOV AH,0CH                   
		  MOV AL,0     
		  MOV BH,00H      
		  INT 10H  

		  MOV CX,BALL_X                    
		  MOV DX,BALL_Y                    
		  ADD CX,BALL_SIZE
		  ADD DX,BALL_SIZE 
		  DEC CX
		  MOV AH,0CH                   
		  MOV AL,0     
		  MOV BH,00H      
		  INT 10H  

		  MOV CX,BALL_X                    
		  MOV DX,BALL_Y                    
		  ADD CX,BALL_SIZE
		  ADD DX,BALL_SIZE 
		  DEC DX
		  MOV AH,0CH                   
		  MOV AL,0     
		  MOV BH,00H      
		  INT 10H 

		  RET    

		 FIX_BALL ENDP
	
	RANDOM_POSITION PROC NEAR


		CREATE_X_RANDOM:
	
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H
			JG CREATE_X_RANDOM
			MOV PLATFORM_X,AX 

	                            ; checking for collision
	                            ; platform width , if PLATFORM_X>WINDOW_WIDTH-PLATFORM_WIDTH -> collision
	
		CREATE_Y_RANDOM:
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H	    ; BEGIN SOMEWHERE BELOW THAT , SO WE ADD IT TO 15H

			CMP AX ,0C8H
			JG  CREATE_Y_RANDOM
			MOV PLATFORM_Y,AX	
			RET

	RANDOM_POSITION ENDP
	
	RANDOM_BUG_POSITION PROC NEAR


		X_RANDOM:
	
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H
			JG  X_RANDOM
			ADD BUG_X,AX 

	                            ; checking for collision
	                            ; platform width , if PLATFORM_X>WINDOW_WIDTH-PLATFORM_WIDTH -> collision
	
		Y_RANDOM:
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H	    ; BEGIN SOMEWHERE BELOW THAT , SO WE ADD IT TO 15H

			CMP AX ,0C8H
			JG  Y_RANDOM
			ADD BUG_Y,AX	
			RET

	RANDOM_BUG_POSITION ENDP
	
	RANDOM_BROKEN_PLATFORM_POSITION PROC NEAR


		RANDOM_X:
	
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H
			JG  RANDOM_X
			ADD BROKEN_PLATFORM_X,AX 

	                            ; checking for collision
	                            ; platform width , if PLATFORM_X>WINDOW_WIDTH-PLATFORM_WIDTH -> collision
	
		RANDOM_Y:
			MOV AH,2CH          ; GET THE SYSTEM TIME
			INT 21H
			MOV AL,DL
			ADD AL,DH
			MOV AH ,00H         ; THE REMINDER IS STORED IN DX 
			CMP AX , 140H	    ; BEGIN SOMEWHERE BELOW THAT , SO WE ADD IT TO 15H

			CMP AX ,0C8H
			JG  Y_RANDOM
			ADD BROKEN_PLATFORM_Y,AX	
			RET

	RANDOM_BROKEN_PLATFORM_POSITION ENDP
	
	CHECK_POSITION_OUT_PAGE proc near 
	
			 MOV AX,WINDOW_BOUNDS						    
			 CMP BALL_X,AX          ; BALL_X <0+WINDOW_BOUNDS : Y->collided
			 JL RESET_POSITION
			 
             MOV AX, WINDOW_WIDTH
             SUB AX, BALL_SIZE		
             SUB AX,WINDOW_BOUNDS			 
			 CMP BALL_X,AX            ; BALL_X >WINDOW_WIDTH - BALL_SIZE : Y->collided
			 JG RESET_POSITION
			 
			 MOV AX, BALL_VELOCITY_Y  ; move the ball vertically
			 ADD BALL_Y, AX
			                          ; check for collisions:
			 MOV AX,WINDOW_BOUNDS
             CMP BALL_Y,AX            ; BALL_Y <0 +WINDOW_BOUNDS : Y->collided
			 JL RESET_POSITION
			 
			 MOV AX, WINDOW_HIGHT	
             SUB AX, BALL_SIZE
             SUB AX, WINDOW_BOUNDS			 
			 CMP BALL_Y,AX            ; BALL_Y >WINDOW_HIGHT - BALL_SIZE: Y->collided
			 JG  RESET_POSITION  
			 ret
			
			 RESET_POSITION:
                 MOV  AX, 0H
				 CMP  BALL_VELOCITY_Y, AX
				 JL   RESET_SPEED
			     CALL RESET_BALL_POSITION   ; back to middle of the screen
				 CALL RANDOM_POSITION
				 CALL RANDOM_BROKEN_PLATFORM_POSITION
				 ;CALL RANDOM_BUG_POSITION   ; calling the procedure to create random position for the bug
				 RET
	
	CHECK_POSITION_OUT_PAGE endp

    
	MOVE_BALL PROC NEAR
	
	                                   ; incresing the ball speed
			 ;MOV AX, BALL_VELOCITY_X  ; move the ball horizontally
			 ;ADD BALL_X,AX            ; we should do it in 2 commands since we cant have 2 variables in 1 operation
			                           ; check for collisions:
			 CALL CHECK_POSITION_OUT_PAGE
			
									 ; CALL CHECK_FOR_BALLCOLLISION
									 ; check if the ball is colliding with the platform
									 ; if PLATFORM_X=<BALL_X+BALL_SIZE=<PLATFORM_X + PLATFORM_WIDTH
									 ; and if PLATFORM_Y <= BALL_Y+BALL_SIZE<= PLATFORM_Y+PLATFORM_HEIGHT -- also we can only check 
									 ; if PLATFORM_Y=BALL_Y
									 ; then the ball has hit the platform
			 
			 MOV AX, BALL_X
			 MOV BX, PLATFORM_X
			 ADD BX, PLATFORM_WIDTH
			 CMP AX, BX
			 JG RETURN               ; NOW WE NEED TO CHECK IF THE SECOND PART OF THE CONDITION IS TRUE
			 
			 MOV AX , BALL_X
			 ADD AX , BALL_SIZE
			 MOV BX , PLATFORM_X
			 CMP AX , BX
			 JL RETURN
			 
			 MOV AX, BALL_Y
			 ; ADD AX, BALL_SIZE
			 MOV BX ,PLATFORM_Y
			 SUB BX , AX
			 CMP BX, 03H
			 JNL RETURN
			 
			 INC SCORE
			                
			 
			                           ; if it reaches this point it means the ball is collindong with the platform
			 
			 NEG BALL_VELOCITY_Y       ; reverse the ball vertical
			 CALL RANDOM_POSITION
			 CALL RANDOM_BROKEN_PLATFORM_POSITION
			 ; CALL RANDOM_BUG_POSITION
	         
			                           ; if the BALL_VELOCITY_Y is negative then it may never come back down
			                           ; we need to set condition to check if the ball speed in negative and 
									   ; its Y position is equal to a specific number then we set the 
									   ; BALL_VELOCITY_Y back to positive 
			 
			 MOV COLOR, 0FH
			 MOV AX, 10H
             CMP BALL_Y, AX
			 JL RESET_SPEED
			 RET

			 RESET_SPEED:
			      NEG BALL_VELOCITY_Y
				  RET

			 RETURN :
				 RET
			 RET
			 
	MOVE_BALL ENDP
	
	RESET_BALL_POSITION PROC NEAR
	
	        MOV AX, BALL_ORIGINAL_X
			MOV BALL_X,AX
			
		    MOV AX,BALL_ORIGINAL_Y
			MOV BALL_Y,AX
	        RET
			
	RESET_BALL_POSITION ENDP
	
	MOVE_BALL_WITH_KEYS PROC NEAR
	
	                          ; we want to move the ball in order to help it hit the platform
	                          ; in order to do so , we use keys 'J' or 'j' for moving left
	                          ; and 'k' or 'K' for moving right
	                          ; we use int 16 system call and zf flag to define getting inputs from keyboard
	MOV AH,01H
	INT 16H                   ; calling the system call to read from keyboard
	JZ EXIT_BALL_MOVEMENT     ; JZ CHECKS ZF , if ZF=0 then jump to label
	                          ; now we need to check which key is pressed
                              ; AH = keyboard scan code , AL=ASCII character or zero	
	MOV AH,00H
	INT 16H
	                          ; ASCII codes for J=4ah , K=4bh, j=6ah, k=6bh 
	                          ; we need to check for each one :
	CMP AL,4AH                ; J is pressed
	JE MOVE_BALL_LEFT
	CMP AL,6AH                ; j is pressed
	JE MOVE_BALL_LEFT
	
	CMP AL,4BH                ; K is pressed
	JE MOVE_BALL_RIGHT
	CMP AL,6BH                ; k is pressed
	JE MOVE_BALL_RIGHT
	
	MOVE_BALL_LEFT:
	    MOV AX,BALL_VELOCITY_X
		SUB BALL_X,AX
		JMP MOVE_BALL_WITH_KEYS
	
	MOVE_BALL_RIGHT:
	    MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX
		JMP MOVE_BALL_WITH_KEYS
	EXIT_BALL_MOVEMENT:
	    RET
	MOVE_BALL_WITH_KEYS ENDP
	
	
	DRAW_PLATFORM PROC NEAR
	
	                         ; drawing the platform
	MOV CX,PLATFORM_X        ; set the initial column (x)
	MOV DX,PLATFORM_Y        ; set the initial line (y)
	
	
	DRAW_PLATFORM_VERTICAL :
	   MOV AH,0Ch                  ; set the configuration to draw a pixel
	   MOV AL,0fh                  ; choose white as color
	   MOV BH,00H                  ; set the page number (we only have one page => set it to 0)
	   INT 10H                     ; execute the configuration by calling the relevant system CALL
	   
	   INC CX                      ; cx = cx + 1
	   MOV AX,CX                   ; AX as temp register
       SUB AX,PLATFORM_X           ; CX - PLATFORM_X
       CMP AX,PLATFORM_WIDTH       ; cx-PLATFORM_X>PLATFORM_WIDTH
       JNG DRAW_PLATFORM_VERTICAL
	   
	   MOV CX,PLATFORM_X
	   INC DX
	   
	   MOV AX,DX
	   SUB AX,PLATFORM_Y
	   CMP AX,PLATFORM_HEIGHT
	   JNG DRAW_PLATFORM_VERTICAL
	   
	RET
	DRAW_PLATFORM ENDP	
	
	DRAW_BROKEN_PLATFORM PROC NEAR
	
	                                     ; drawing the platform
	MOV CX,BROKEN_PLATFORM_X             ; set the initial column (x)
	MOV DX,BROKEN_PLATFORM_Y             ; set the initial line (y)
	
	
	DRAW_BROKEN_PLATFORM_VERTICAL :
	   MOV AH,0Ch                         ; set the configuration to draw a pixel
	   MOV AL,04h                         ; choose white as color
	   MOV BH,00H                         ; set the page number (we only have one page => set it to 0)
	   INT 10H                            ; execute the configuration by calling the relevant system CALL
	    
	   INC CX                             ; cx = cx + 1
	   MOV AX,CX                          ; AX as temp register
       SUB AX,BROKEN_PLATFORM_X           ; CX - PLATFORM_X
       CMP AX,BROKEN_PLATFORM_WIDTH       ; cx-PLATFORM_X>PLATFORM_WIDTH
       JNG DRAW_BROKEN_PLATFORM_VERTICAL
	   
	   MOV CX,BROKEN_PLATFORM_X
	   INC DX
	   
	   MOV AX,DX
	   SUB AX,BROKEN_PLATFORM_Y
	   CMP AX,BROKEN_PLATFORM_HEIGHT
	   JNG DRAW_BROKEN_PLATFORM_VERTICAL
	   
	RET
	DRAW_BROKEN_PLATFORM ENDP	
	                            ; in order to avoid repitation we create the clear screen proc 
    CLEAR_SCREEN PROC NEAR
	                            ; in order to improve the games quality , we can only remove ball not the whole screen
	                            ; cleaning the screen with setting the background again
			 
			                    ; setting in initials of video mode
	         MOV AH,00H         ; set the configuration to  video mode 
	                            ; video mode 13  320x200 256 color graphics (MCGA,VGA):
	         MOV AL,13H         ; choose the video mode
		                        ; command above is the video mode we chose among INT 10h-0 video modes
             INT 10H            ; execute the configuration 
		                        ; command above is for calling the interrupt to execute
			 
		     MOV AH,0Bh         ; set the configuration
		     MOV BH,00h         ; to the backgroung color 
		     MOV BL,00h         ; we choose the black as background ,00h is the code for color black
		     INT 10h            ; we use the interrupt to set the background
			 
			 RET 
	CLEAR_SCREEN ENDP
    	
    DRAW_GAME_OVER_MENU PROC NEAR        ; draw the game over menu
		
	    CALL CLEAR_SCREEN                ; clear the screen before displaying the menu
                                         ; print Score
	                                     ; Shows the menu title
		MOV AH,02h                       ; set cursor position
		MOV BH,00h                       ; set page number
		MOV DH,08h                       ; set row 
		MOV DL,04h						 ; set column
		INT 10h		 
		
		MOV AH,09h                       ; WRITE STRING TO STANDARD OUTPUT
		LEA DX,SCORE_TITLE               ; give DX a pointer 
		INT 21h                          ; print the string
		
        JMP PRINT_NUMBER_


    PRINT_NUMBER_ :            ; print the score digit by digit
				               ; mov bx, 000Fh
			 MOV CX,0
			 MOV BX,0AH        ; bx=10 for dividing
			 
			 
			 MOV AH,00H 
			 MOV AX,SCORE     ; PRINT

    DIVIDER_:
			 DIV BL    
			 INC CX 
			 MOV BH,0
			 MOV BL,AH
			 PUSH BX
			 MOV BL,0AH 
			 MOV AH,0
			 CMP AL,0               
			 JE PRINT_IN_CONSOLE_     
			 JMP DIVIDER_
			
    

	PRINT_IN_CONSOLE_ :
			
		  PRINT_:   
			
			POP AX 
			MOV BX , 000FH
			MOV AH , 0EH
		 
			ADD AL , 030H
			INT 10H
			
			LOOP PRINT_
                                         ; Shows the menu title
		MOV AH,02h                       ; set cursor position
		MOV BH,00h                       ; set page number
		MOV DH,04h                       ; set row 
		MOV DL,04h					     ; set column
		INT 10h							 
		
		MOV AH,09h                       ; WRITE STRING TO STANDARD OUTPUT
		LEA DX,TEXT_GAME_OVER_TITLE      ; give DX a pointer 
		INT 21h                          ; print the string
			
	DRAW_GAME_OVER_MENU ENDP
	
CODE ENDS
END