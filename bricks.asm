.286
.model small
.stack 100h
.data
	studentID db "260985200$" ; change the content of the string to your studentID (do not remove the $ at the end)
	ball_x dw 160	 ; Default value: 160
	ball_y dw 144	 ; Default value: 144
	ball_x_vel dw 0	 ; Default value: 0
	ball_y_vel dw -1 ; Default value: -1 
	paddle_x dw 144  ; Default value: 144
	paddle_length dw 32 ; Default value: 32
	last_power dw 0
	power1_active dw 0
	power2_active dw 0
	power_timer dw 0
	laser_x dw 0
	laser_y dw 0

.code

; get the functions from the util_br.obj file (needs to be linked)
EXTRN setupGame:PROC, drawBricks:PROC, checkBrickCollision:PROC, sleep:PROC, decreaseLives:PROC, getScore:PROC, clearPaddleZone:PROC


; draw a single pixel specific to Mode 13h (320x200 with 1 byte per color)
drawPixel:
	color EQU ss:[bp+4]
	x1 EQU ss:[bp+6]
	y1 EQU ss:[bp+8]

	push	bp
	mov	bp, sp

	push	bx
	push	cx
	push	dx
	push	es

	; set ES as segment of graphics frame buffer
	mov	ax, 0A000h
	mov	es, ax


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1
	mov	cx, 320
	xor	dx, dx
	mov	ax, y1
	mul	cx
	add	bx, ax

	; DX = color
	mov	dx, color

	; plot the pixel in the graphics frame buffer
	mov	BYTE PTR es:[bx], dl

	pop	es
	pop	dx
	pop	cx
	pop	bx

	pop	bp

	ret	6

drawBall:

	push bx
	push cx

	mov bx, [ball_x]
	mov cx, [ball_y]
	
	push [ball_y]
	push [ball_x]
	push 00h
	call drawPixel
	
	;Update ball x value
	mov ax, bx
	mov bx, [ball_x_vel]
	add ax, bx
	mov [ball_x], ax
	
	;Update ball y value
	mov ax, cx
	mov cx, [ball_y_vel]
	add ax, cx
	mov [ball_y], ax
	
	;Draw Ball
	push [ball_y]
	push [ball_x]
	push 0Fh
	call drawPixel
	
	pop cx
	pop bx
	
	ret
	

checkWallCollision:
    push bp
    mov bp, sp
    mov bx, [bp+4] 
    mov cx, [bp+6] 

    mov ax, 0       ; Default return value (no collision)

    cmp bx, 16
    je LeftOrCorner
    cmp bx, 303
    je   RightOrCorner
    jmp  CheckTop

LeftOrCorner:
    cmp cx, 32
    je   CornerCase
    cmp cx, 33
    jge  VerticalWall
    jmp  NoCollision

RightOrCorner:
    cmp cx, 32
    je   CornerCase
    cmp cx, 33
    jge  VerticalWall
    jmp  NoCollision

CornerCase:
    mov ax, 3       
    jmp  NoCollision

VerticalWall:
    mov ax, 1      
    jmp  NoCollision

CheckTop:
    cmp cx, 32
    jne  NoCollision
    cmp bx, 17
    jl   NoCollision
    cmp bx, 302
    jg   NoCollision
    mov ax, 2       ; Top wall collision

NoCollision:
    pop bp
    ret 4           


handleCollisions:
	push ax
    push bx
    push cx
	
	; Check for collision with the wall
    mov bx, [ball_x] 
    mov cx, [ball_y]
    push cx          
    push bx          
    call checkWallCollision

    cmp ax, 1
    je   InvertX
    cmp ax, 2
    je   InvertY
    cmp ax, 3
    je   InvertBoth
	
	; Check for collision with the paddle
	call checkPaddleCollision
	cmp ax, 1
    je   leftCollision
    cmp ax, 2
    je   midCollision
    cmp ax, 3
    je   rightCollision
	
	;Check for collision with bricks
	push [ball_y_vel]
	push [ball_x_vel]
	push [ball_y]
	push [ball_x]
	call checkBrickCollision
	
	cmp ax, 1
    je   InvertX
    cmp ax, 2
    je   InvertY
    cmp ax, 3
    je   InvertBoth
	
    jmp  EndCollision

InvertX:
    neg [ball_x_vel] ; Invert x velocity
    jmp  EndCollision

InvertY:
    neg [ball_y_vel] ; Invert y velocity
    jmp  EndCollision

InvertBoth:
    neg [ball_x_vel] ; Invert both velocities
    neg [ball_y_vel]
	jmp EndCollision

leftCollision:
	mov [ball_x_vel], -1
	mov [ball_y_vel], -1
	jmp EndCollision
	
midCollision:
	mov [ball_x_vel], 0
	mov [ball_y_vel], -1
	jmp EndCollision

rightCollision:
	mov [ball_x_vel],  1
	mov [ball_y_vel], -1
	jmp EndCollision
	
EndCollision:
    pop cx
    pop bx
	pop ax
	
    ret


resetAfterBallLoss:
	
	;reset values
	mov [ball_x], 160
	mov [ball_y], 144
	mov [ball_x_vel], 0
	mov [ball_y_vel], -1
	
	;Draw ball
	push [ball_y]
	push [ball_x]
	push 0Fh
	call drawPixel
	
	mov [paddle_x], 144
	mov [paddle_length], 32
	
	call drawPaddle
	
	;decrease lives
	call decreaseLives
		
	ret
	
; Made From Draw line function lab 5
drawRec:
    color EQU ss:[bp+4] ; Color of the line
    x1 EQU ss:[bp+6]    ; Starting X coordinate
    y1 EQU ss:[bp+8]    ; starting Y coordinate 
    x2 EQU ss:[bp+10]   ; Ending X coordinate
	y2 EQU ss:[bp+12]	; Ending Y coordinate

    push    bp          ; Save base pointer
    mov     bp, sp      ; Set base pointer to current stack pointer

    push    cx          ; Save CX register (used for loop counter or data)
    push    bx          ; Save BX register (used for X coordinate)
	push	dx
   
    mov     cx, y1      ; Initialize CX with Y coordinate
    mov     dx, x2      ; DX used to store ending X coordinate for comparison
	
	dec cx

	drawRec_loop1:
	
		mov     bx, x1      ; Initialize BX with starting X coordinate
		inc cx	
	
		drawRec_loop2:
			push    cx          ; Push Y coordinate onto stack for drawPixel
			push    bx          ; Push current X coordinate for drawPixel
			push    color       ; Push color for drawPixel
			call    drawPixel   ; Call drawPixel function to color the pixel

			inc     bx          ; Increment X coordinate	
			cmp     bx, dx      ; Compare current X with ending X coordinate
			jle     drawRec_loop2     ; Loop back if current X <= ending X

			cmp cx, y2
			jl drawRec_loop1

			pop		dx
			pop     bx          ; Restore BX register
			pop     cx          ; Restore CX register
			pop     bp          ; Restore base pointer
			ret     10           ; Return and clean up arguments from stack	


drawPaddle:

	push bx
	push cx
	push dx

	mov bx, [paddle_length]
	mov cx, [paddle_x]
	
	call clearPaddleZone
	
	; Bx = (bx-4)/2
	sub bx, 4
	sar bx, 1
	
	add cx, bx
	
	mov dx, [paddle_x]
	
	;Draw left Segment
	push 187
	push cx
	push 184
	push dx
	push 2Ch
	call drawRec
	
	mov dx, cx
	add cx, 4
	inc dx
	
	; Draw middle segment
	push 187
	push cx
	push 184
	push dx
	push 2Dh
	call drawRec
	
	mov dx, cx
	add cx, bx
	inc dx
	
	; Draw right segment
	push 187
	push cx
	push 184
	push dx
	push 2Eh
	call drawRec
	
	pop dx
	pop cx
	pop bx
	
	ret

; Get color funnction from lab 7
getColor:
    x1 EQU ss:[bp+4] ; x coordinate
    y1 EQU ss:[bp+6] ; y coordinate

    	
	push	bp
	mov	bp, sp

	push	bx
	push	cx
	push	es

	; set ES as segment of graphics frame buffer
	mov	ax, 0A000h
	mov	es, ax


	; BX = ( y1 * 320 ) + x1
	mov	bx, x1
	mov	cx, 320
	xor	dx, dx
	mov	ax, y1
	mul	cx
	add	bx, ax


	; plot the pixel in the graphics frame buffer
	mov	dl, BYTE PTR es:[bx]

	pop	es
	pop	cx
	pop	bx

	pop	bp
    ret 4

checkPaddleCollision:
	
	push dx
	
	cmp [ball_y], 183
	jne noPaddleCollision
	
	mov ax, [ball_y]
	inc ax
	
	push ax
	push [ball_x]
	call getColor
	
	cmp dl, 0
	je noPaddleCollision
	
	cmp dl, 2Ch
	je leftPaddleCollision
	
	cmp dl, 2Dh
	je midPaddleCollision
	
	cmp dl, 2Eh
	je rightPaddleCollision
	
	leftPaddleCollision:
		mov ax, 1
		jmp endPaddleCollision
	
	midPaddleCollision:
		mov ax, 2
		jmp endPaddleCollision
	
	rightPaddleCollision:
		mov ax, 3
		jmp endPaddleCollision
	
	noPaddleCollision:
		mov ax, 0
	
	endPaddleCollision:
	
	pop dx
	
	ret 
	
activatePower1:
	call getScore
	
	; Skip if not met the score requirement (50)
	sub ax, [last_power]
	cmp ax, 50
	jl noPower1
	
	call getScore
	mov [last_power], ax
	
	;Change paddle size
	mov [paddle_length], 64
	mov [power1_active], 1
	
	noPower1:
	
	ret
	
resetPower1:
	
	mov [power_timer], 0
	mov [power1_active], 0
	
	mov [paddle_length], 32 
	
	ret

activatePower2:
	call getScore
	
	; Skip if not met the score requirement (50)
	sub ax, [last_power]
	cmp ax, 50
	jl noPower2
	
	call getScore
	mov [last_power], ax
	
	;Init laser position
	mov ax, [paddle_length]
	sar ax, 1
	add ax, [paddle_x]
	mov [laser_x], ax
	mov [laser_y], 183
	
	;Init power up active global vars
	mov [power2_active], 1
	
	
	noPower2:
	
	ret
	
drawLaser:
	
	push bx
	push cx

	mov bx, [laser_x]
	mov cx, [laser_y]
	
	push [laser_y]
	push [laser_x]
	push 00h
	call drawPixel
	
	;Update laser y value
	mov ax, cx
	mov cx, -1
	add ax, cx
	mov [laser_y], ax
	
	;Draw laser
	push [laser_y]
	push [laser_x]
	push 3Eh
	call drawPixel
	
	pop cx
	pop bx
	
	ret
	
handleLaserCollisions:
	push ax
    push bx
    push cx
	
	; Check for collision with the wall
    mov bx, [laser_x] 
    mov cx, [laser_y]
    push cx          
    push bx          
    call checkWallCollision

    cmp ax, 1
    je   stopLaser
    cmp ax, 2
    je   stopLaser
    cmp ax, 3
    je   stopLaser
	
	;Check for collision with bricks
	push -1
	push 0
	push [laser_y]
	push [laser_x]
	call checkBrickCollision
	
	cmp ax, 1
    je   stopLaser
    cmp ax, 2
    je   stopLaser
    cmp ax, 3
    je   stopLaser
	
    jmp  EndLaserCollision
	
stopLaser:
	mov [power2_active], 0
	
	push [laser_y]
	push [laser_x]
	push 00h
	call drawPixel
	
EndLaserCollision:
    pop cx
    pop bx
	pop ax
	
    ret
	

start:
        mov ax, @data
        mov ds, ax
	
	push OFFSET studentID ; do not change this, change the string in the data section only
	push ds
	call setupGame ; change video mode, draw walls & write score, studentID and lives
	call drawBricks
	
	
main_loop:

	call sleep
	
	;Power up main loop code
	;Check if power 1 is active
	cmp [power1_active], 1
	jne skip_increment1
	
	inc [power_timer]
	
	skip_increment1:
	
	; Check if need to draw Laser
	cmp [power2_active], 1
	jne skip_drawLaser
	
	call drawLaser
	call handleLaserCollisions
	
	skip_drawLaser:
	
	;Check if power 1 time is complete
	cmp [power_timer], 500
	jl skip_deactivate

	call resetPower1
	
	skip_deactivate:

	; Draw Paddle
	call drawPaddle
	
	;Draw Ball
	call drawBall
	
	; Handle collision with wall
	call handleCollisions
	
	; Check for ball out of bounds
	mov bx, [ball_y]
	cmp bx, 199
	jle keypressCheck
	
	call resetAfterBallLoss
	
	cmp ax, 0
	jge keyboardInput
	
	
keypressCheck:
	mov ah, 01h ; check if keyboard is being pressed
	int 16h ; zero flag (zf) is set to 1 if no key pressed
	jz main_loop ; if zero flag set to 1 (no key pressed), loop back
keyboardInput:
	; else get the keyboard input
	mov ah, 00h
	int 16h

	; Check for a/A key press
	cmp al, 41h
	je moveLeft
	cmp al, 61h
	je moveLeft
	
	; Check for d/D key press
	cmp al, 44h
	je moveRight
	cmp al, 64h
	je moveRight

	cmp al, 31h
	jne power1KeySkip
	
	call activatePower1
	
	power1KeySkip:
	
	cmp al, 32h
	jne power2KeySkip
	
	call activatePower2
	
	power2KeySkip:

	cmp al, 1bh
	je exit

	jmp main_loop

moveLeft:
	sub [paddle_x], 8
	jmp main_loop

moveRight:
	add [paddle_x], 8
	jmp main_loop
	

	


exit:
        mov ax, 4f02h	; change video mode back to text
        mov bx, 3
        int 10h

        mov ax, 4c00h	; exit
        int 21h

END start

