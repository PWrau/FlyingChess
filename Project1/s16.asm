;
.386
.model flat, stdcall
option casemap: none

include     C:\masm32\include\windows.inc
include     C:\masm32\include\wsock32.inc
include     C:\masm32\include\user32.inc
include     C:\masm32\include\kernel32.inc
include     C:\masm32\include\msvcrt.inc
includelib  C:\masm32\lib\wsock32.lib
includelib  C:\masm32\lib\user32.lib
includelib  C:\masm32\lib\kernel32.lib
includelib  C:\masm32\lib\msvcrt.lib
;include     xyw.asm

;============================xyw
;����λ�ýṹ��
PiecePosition STRUCT
	Player BYTE 0
	Id BYTE 0
	Lane BYTE 0
	Position BYTE 0 
PiecePosition ENDS

;��ʼ��
init PROTO
;����������ָ��
parseCommand PROTO				
;�����
iRand PROTO first:DWORD,second:DWORD
;�ɻ����ƶ�
moveOneStep PROTO currentPiece:DWORD
moveOut PROTO currentPiece:DWORD
jumpAndShortCut PROTO currentPiece:DWORD
outerKillOtherPlane PROTO currentPiece:DWORD
shortCutKillOtherPlane PROTO currentPiece:DWORD
secureNotOnBlock PROTO currentPiece:DWORD
;�����ܲ��ܽ�����Ծ�ͷ�Ծ
testShortCut PROTO currentPiece:DWORD
testJump PROTO currentPiece:DWORD
;���������ӿ�����
testCanMove PROTO
;ת���ƶ��ķ���
changeDirection PROTO
;�鿴��ǰλ���ǲ�����ǽ		
checkBlock PROTO currentPiece:DWORD
;�鿴��ǰ�����ɻ��ǲ����ߵ����յ�
checkIntoDestination PROTO currentPiece:DWORD
;���µ�ǰλ�õķɻ�
setCurrentPlane PROTO currentPiece:DWORD
;����ǰλ�õķɻ�
pickCurrentPlane PROTO currentPiece:DWORD
;��֯���ص���Ϣ
composeBuffer PROTO currentPiece:DWORD
;������Ϣ��������
processCommand PROTO
;������һ�����
nextPlayer PROTO
;����ǲ���һ���ǲ����Ѿ�ʤ�� dl = 1 ��ǰ���ʤ�� dl = 0 ��ǰ�����δʤ��
testWin PROTO currentPiece:DWORD
;��֯ʤ������Ϣ
composeWinBuffer PROTO 	
;============================xyw

;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy
_ClearR PROTO
_ClearS PROTO
_Encode PROTO
_Decode PROTO
_RecvData PROTO, sock: DWORD
_Broadcast PROTO
_HandleBegin PROTO
_InitServer PROTO
_Prepare PROTO
_ConsoleMain PROTO

_wsaVersion         EQU 0101h ; 0101h for Ver 1.1, or 0002h for Ver 2.0
PORT                EQU 9999
MAX_SOCK            EQU 1
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy

.data

;============================xyw
endl EQU <0dh,0ah>
;���յ���Ϣ�ͷ��͵���Ϣ
;buffer BYTE 50 DUP(0)

;һ�β�����ָ��Ͳ�����
verb BYTE 0
operand BYTE 0

;������Ϣ��¼
chessBoard PiecePosition 16 DUP(<>)		;���������зɻ�����Ϣ
currentPlayer DWORD 0					;��ǰ��������Һ� 
currentPlane DWORD 0					;��ǰ�����ķɻ���
currentStep DWORD 0						;��ǰ�ӳ���������
currentDirection DWORD 0				;��ǰ���� 0 ��ǰ 1 ���
outerLanePlaneCount BYTE 52 DUP(0)		;��ǰ��Ȧ��ÿ�������ж��ټܷɻ�
outerLanePlanePlayer BYTE 52 DUP(-1)	;��ǰ��Ȧÿ�����ӵ�������Һ�
innerLanePlaneCount BYTE 24 DUP(0)		;��ǰ��Ȧ��ÿ�������ж��ټܷɻ�
;============================xyw


;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy
_wsaData WSADATA <>
_sockAddr sockaddr_in <>
_hListenSock DWORD ?
_sockList DWORD 4 DUP(0)
_sbuf BYTE 10 DUP(0)
_rbuf BYTE 10 DUP(0)
_rollAgain BYTE 0
_prepareFormat BYTE "Player [%d] ready.", 0dh, 0ah, 0
_connectFormat BYTE "Player [%d] connected.", 0dh, 0ah, 0
_sendDisplayFormat BYTE "Send [%s]", 0dh, 0ah, 0
_recvDisplayFormat BYTE "Receive [%s]", 0dh, 0ah, 0

;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy

canMoveFlag BYTE 1
.code
init PROC USES ecx eax ebx esi
	;��ǰ����Һ�(k)
	mov al,0
	;��ǰ�ķɻ���()
	mov bl,0

	;��ǰ�����Ľṹ�����
	mov esi,OFFSET chessBoard
L1:
	mov [esi].PiecePosition.Player,al
	mov [esi].PiecePosition.Id,bl
	mov [esi].PiecePosition.Lane,0
	;��ǰλ��=4k~4k+3
	mov [esi].PiecePosition.Position,al
	mov ecx,3
AddLoop:
	add [esi].PiecePosition.Position,al
	loop AddLoop
	add [esi].PiecePosition.Position,bl

	;��һ���ṹ��
	add esi,SIZEOF PiecePosition
	;al,bl�ĸ���
	.if (bl == 3)
		.if (al == 3)
			jmp QL1
		.else
			add al,1
			mov bl,0
			jmp L1
		.endif
	.else
		add bl,1
		jmp L1
	.endif
QL1:
	ret
init ENDP

parseCommand PROC USES eax
	mov eax,0
	mov al, _rbuf[0]
	mov verb,al
	
	.if (_rbuf[1]==' ')
		mov al,_rbuf[2]
		mov operand,al
		mov currentPlane,eax
		;sub currentPlane,'0'
	.else
		mov operand,0
	.endif
	ret
parseCommand ENDP

;eaxΪ���������
iRand PROC USES ecx edx first:DWORD,second:DWORD
	invoke GetTickCount
	mov ecx,13
	mul ecx
	add eax,7
	mov ecx,second
	sub ecx,first
	inc ecx
	mov edx,0
	div ecx
	add edx,first
	mov eax,edx

	ret
iRand ENDP

;ǰ��һ��
moveOneStep PROC USES eax esi currentPiece:DWORD
	mov esi,currentPiece
	.if ([esi].PiecePosition.Lane == 1)
		;�ߵ��Լ��ĵ�һ��������
		mov [esi].PiecePosition.Lane,2
		mov al,13
		mul [esi].PiecePosition.Player
		mov [esi].PiecePosition.Position,al
		add [esi].PiecePosition.Position,3
	.elseif ([esi].PiecePosition.Lane == 2)
		.if (currentDirection == 0)
			mov al,13
			mul [esi].PiecePosition.Player
			.if ([esi].PiecePosition.Position == al)
				;��������Ȧ
				mov [esi].PiecePosition.Lane,3
				mov [esi].PiecePosition.Position,0
			.else
				;����Ȧǰ��һ��
				add [esi].PiecePosition.Position,1
				.if ([esi].PiecePosition.Position >= 52)
					sub [esi].PiecePosition.Position,52
				.endif
			.endif
		.else
			;����Ȧ����һ��
			sub [esi].PiecePosition.Position,1
			.if ([esi].PiecePosition.Position >= 200) ;<0
				add [esi].PiecePosition.Position,52
			.endif
		.endif
	.else ;[esi].PiecePosition.Lane == 3
		.if (currentDirection == 0)
			add [esi].PiecePosition.Position,4
			mov al,[esi].PiecePosition.Player
			add al,20
			.if ([esi].PiecePosition.Position == al)
				call changeDirection
			.endif
		.else
			sub [esi].PiecePosition.Position,4
		.endif
	.endif
	;��֯buffer����Ϣ
	invoke composeBuffer,currentPiece
	ret
moveOneStep ENDP

;�Ƴ�����
moveOut PROC USES eax esi currentPiece:DWORD
	mov esi,currentPiece
	mov [esi].PiecePosition.Lane,1
	mov al,[esi].PiecePosition.Player
	mov [esi].PiecePosition.Position,al
	;��֯buffer����Ϣ
	invoke composeBuffer, currentPiece
	ret 
moveOut ENDP

;������û�зɻ������� dl = 1 �еĿ����� dl = 0 �޿���
testCanMove PROC USES ecx esi
    mov dl,0
    .if currentStep == 6
        mov dl,1
        jmp Quit
    .endif
    mov esi,OFFSET chessBoard

    mov ecx,currentPlayer
    .if ecx > 0
    L1:
        add esi,SIZEOF PiecePosition
        loop L1
    .endif
    
    ;esiΪ��ǰ��ҵ�һ���ɻ���λ��
    mov ecx,4
checkLoop:
    .if ([esi].PiecePosition.Lane != 0 && [esi].PiecePosition.Lane != 4)
        mov dl,1
        jmp Quit
    .endif
    add esi,SIZEOF PiecePosition
    ;��һ���ɻ�
    loop checkLoop

Quit:
    ret
testCanMove ENDP

;�����ǲ��ǿ��Խ��з�Ծ ���Է�Ծ dl = 1 �����Է�Ծ dl = 0
testShortCut PROC USES eax ebx ecx esi edi currentPiece:DWORD
	mov esi,currentPiece	
	mov dl,1

	;eaxΪ��Ȧ��Ծ����index
	mov edi,OFFSET outerLanePlaneCount
	mov ebx,OFFSET outerLanePlanePlayer
	mov eax,0
	mov al,[esi].PiecePosition.Position	
	add al,12

	.if al >= 52
		sub al,52
	.endif

	;edi��Ȧ��Ӧλ�÷ɻ����� ebx��Ȧ��Ӧλ�������ɫ
	add edi,eax
	add ebx,eax


	;clΪ��ǰ�����ɻ�����ɫ
	mov cl,[esi].PiecePosition.Player
	.if (BYTE PTR [edi] >= 2 && cl != BYTE PTR [ebx]) 
		mov dl,0
		jmp Quit
	.endif

	;eaxΪ��Ծ�����о�������Ȧindex
	mov edi,OFFSET innerLanePlaneCount
	mov eax,0
	mov al,[esi].PiecePosition.Player
	add al,2
	.if al >= 4
		sub al,4
	.endif
	add al,8
	
	;edi��Ȧ��Ӧλ�÷ɻ����� 
	add edi,eax


	.if (BYTE PTR [edi] >= 2) 
		mov dl,0
		jmp Quit
	.endif

Quit:
	ret 
testShortCut ENDP

;�����ǲ��ǽ�����Ծ4�� ������Ծ dl = 1 ��������Ծ dl = 0
testJump PROC USES eax ebx ecx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov dl,1

	mov ecx,4	;���4����	
	;eaxΪ��Ȧ��Ծʱ ��������index
	mov eax,0
	mov al,[esi].PiecePosition.Position	
L1: 
	add al,1

	.if al >= 52
		sub al,52
	.endif

	mov edi,OFFSET outerLanePlaneCount
	mov ebx,OFFSET outerLanePlanePlayer
	;edi��Ȧ��Ӧλ�÷ɻ����� ebx��Ȧ��Ӧλ�������ɫ
	add edi,eax
	add ebx,eax

	mov dl,1
	;clΪ��ǰ�����ɻ�����ɫ
	mov dh,[esi].PiecePosition.Player
	.if (BYTE PTR [edi] >= 2 && dh != BYTE PTR [ebx]) 
		mov dl,0
		jmp QL1
	.endif

	loop L1
QL1:
	ret 
testJump ENDP



;������Ծ���߷�Ծ
jumpAndShortCut PROC USES eax ebx ecx edx esi currentPiece:DWORD
	mov esi,currentPiece

	;[ebp - 4] == jumpFlag
	enter 4,0
	mov DWORD PTR[ebp - 4],0

    .if [esi].PiecePosition.Lane != 2
        jmp Quit
    .endif

	;bl = (13*��Һ� + 20) % 52
	mov al,13
	mul [esi].PiecePosition.Player
	add al,20
	.if (al >= 52)
		sub al,52
	.endif
	mov bl,al

	;bh = (Position - k) % 4
	mov ax,0
	mov al,[esi].PiecePosition.Position
	sub al,[esi].PiecePosition.Player
	.if (al < 0)
		add al,4
	.endif
	mov cl,4
	div cl
	mov bh,ah
	
	;cl = 13*k
	mov al,13
	mov cl,[esi].PiecePosition.Player
	mul cl
	
	mov cl,al

	;��̤��Ȧ�ķɻ�
	invoke outerKillOtherPlane,esi
L1:
	.if (bl == [esi].PiecePosition.Position)
		;�����ܲ��ܷ�Ծ
		invoke testShortCut,esi
		.if dl == 0
			jmp Quit
		.endif
		;��Ծ12��
		add [esi].PiecePosition.Position,12
		.if [esi].PiecePosition.Position >= 52 
			sub [esi].PiecePosition.Position,52
		.endif

		;��֯buffer����Ϣ 
		invoke composeBuffer,esi
		;��Ծ�ݻٷɻ�
		invoke shortCutKillOtherPlane,esi
		;��̤��Ȧ�ķɻ�
		invoke outerKillOtherPlane,esi
	.elseif (bh == 0 && DWORD PTR [ebp - 4] == 0 && cl!=[esi].PiecePosition.Position)
		mov DWORD PTR [ebp - 4],1
		;�����ܲ�����Ծ
		invoke testJump,esi
		.if dl == 0
			jmp Quit
		.endif
		;��Ծ4��
		add [esi].PiecePosition.Position,4
		.if ([esi].PiecePosition.Position >= 52)
			sub [esi].PiecePosition.Position,52
		.endif

		;��֯buffer����Ϣ 
		invoke composeBuffer,esi
		;��̤��Ȧ�ķɻ�
		invoke outerKillOtherPlane,esi
	.else
		jmp Quit
	.endif		

	jmp L1
Quit:

	leave
	ret
jumpAndShortCut ENDP

outerKillOtherPlane PROC USES eax ebx edx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov edi,OFFSET outerLanePlaneCount
	mov edx,OFFSET outerLanePlanePlayer


	;������λ�ò�����Ȧ ֱ���˳�
	.if [esi].PiecePosition.Lane != 2
		jmp Quit
	.endif

	;eaxΪ��Ȧ��index
	mov eax,0
	mov al,[esi].PiecePosition.Position
	;edi��Ȧ��Ӧλ�÷ɻ����� edx��Ȧ��Ӧλ�������ɫ
	add edi,eax
	add edx,eax

	.if (BYTE PTR [edi] >= 2 || BYTE PTR [edi] == 0)	;�����Ӧλ�÷ɻ�����Ϊ0 ���� ��������2 û�вȵ������ɻ�
		jmp Quit 
	.elseif ;BYTE PTR [edi] == 1
		;�����ɻ��������ɫ
		mov bl,[esi].PiecePosition.Player
		.if bl != BYTE PTR [edx]
			mov ecx,0
			;����Ǳ����ɫ��1�ܷɻ� ����Ҫ�˻ؼ�
			mov cl,BYTE PTR [edx]
			;�����������������Ϣ���ҵ��������
			mov esi,OFFSET chessBoard

			;�ҵ������ɫ��λ��
			.if ecx > 0 
L1:
				add esi,SIZEOF PiecePosition * 4
				loop L1
			.endif

			;���������ҵ����зɻ�
			mov ecx,4
Lcheck:
			.if ([esi].PiecePosition.Lane == 2 && al == [esi].PiecePosition.Position)
				mov [esi].PiecePosition.Lane,0
				mov bl,[esi].PiecePosition.Player
				;����ɻ���λ���� 4 Player + Id
				mov [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl

				mov bl,[esi].PiecePosition.Id
				add [esi].PiecePosition.Position,bl

				;��֯��������Ϣ
				invoke composeBuffer,esi

				jmp Quit
			.endif
			loop Lcheck


		.endif
	.endif

Quit:
	ret
outerKillOtherPlane ENDP

shortCutKillOtherPlane PROC USES eax ebx ecx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov edi,OFFSET innerLanePlaneCount
	;alΪ��Ծ����ҵ���ɫ
	mov eax,0
	mov al,[esi].PiecePosition.Player

	add al,2
	.if(al >= 4)
		sub al,4
	.endif

	add al,8
	
	;���������Ȧλ�õķɻ�����
	add edi,eax
	.if BYTE PTR [edi] == 1
		;���ֻ��һ�ܷɻ����˻ؼ�
		
		;alΪ�Ǹ���ҵ���ɫ
		sub al,8

		mov ecx,0
		mov cl,al

		mov esi,OFFSET chessBoard
		.if ecx > 0
L1:
			add esi,SIZEOF PiecePosition * 4
			loop L1
		.endif

		;���������ҵ����зɻ�
		mov ecx,4
		;alΪ�Ǹ����ӵ�λ��
		add al,8
		checkLoop:
			.if ([esi].PiecePosition.Lane == 3 && al == [esi].PiecePosition.Position)
				;������ɻ��˻ػ���
				mov [esi].PiecePosition.Lane,0
				mov bl,[esi].PiecePosition.Player
				;����ɻ���λ���� 4 Player + Id
				mov [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl

				mov bl,[esi].PiecePosition.Id
				add [esi].PiecePosition.Position,bl

				;��֯��������Ϣ
				invoke composeBuffer,esi

				jmp Quit
			.endif
			add esi,SIZEOF PiecePosition
			loop checkLoop

	.endif

Quit:
	ret
shortCutKillOtherPlane ENDP

changeDirection PROC
	.if currentDirection == 0
		mov currentDirection,1
	.else ;currentDirection == 1
		mov currentDirection,0
	.endif
	ret
changeDirection ENDP

secureNotOnBlock PROC USES eax ebx edx edi esi currentPiece:DWORD
	mov esi,currentPiece
	;ediΪ��Ȧ�ķɻ����� edxΪ��Ȧ�ķɻ�����ɫ
	mov edi,OFFSET outerLanePlaneCount
	mov edx,OFFSET outerLanePlanePlayer

	mov eax,0
	mov al,[esi].PiecePosition.Position

	;ediΪ��Ȧ��Ӧλ�õķɻ����� edxΪ��Ȧ��Ӧλ�õķɻ�����ɫ
	add edi,eax
	add edx,eax

	.if [esi].PiecePosition.Lane == 2
		;����������ҵ�ǽ
		mov bl,[esi].PiecePosition.Player
		.if (BYTE PTR [edi] >= 2 && bl != BYTE PTR [edx])
			;�ƶ�һ������ǽ��������
			invoke moveOneStep,esi
		.endif
	.endif
	ret 
secureNotOnBlock ENDP

checkBlock PROC USES eax ebx ecx edx edi esi currentPiece:DWORD
	mov esi,currentPiece
	;ediΪ��Ȧ�ķɻ����� edxΪ��Ȧ�ķɻ�����ɫ
	mov edi,OFFSET outerLanePlaneCount
	mov edx,OFFSET outerLanePlanePlayer

	mov eax,0
	mov al,[esi].PiecePosition.Position

	;ediΪ��Ȧ��Ӧλ�õķɻ����� edxΪ��Ȧ��Ӧλ�õķɻ�����ɫ
	add edi,eax
	add edx,eax

	.if [esi].PiecePosition.Lane == 2
		;����������ҵ�ǽ
		mov bl,[esi].PiecePosition.Player
		.if (BYTE PTR [edi] >= 2 && bl != BYTE PTR [edx])
			call changeDirection	;ת������
		.endif
	.endif
	ret 
checkBlock ENDP

checkIntoDestination PROC USES eax esi currentPiece:DWORD
	mov esi, currentPiece

	mov al,[esi].PiecePosition.Player
	add al,20

	.if (al==[esi].PiecePosition.Position && [esi].PiecePosition.Lane == 3)
		; ��ǰ�ɻ��ĺ������ = 4
		mov [esi].PiecePosition.Lane,4
		; ��ǰ�ɻ���λ�� = ��Һ�
		sub [esi].PiecePosition.Position,20

        ;������Ϣ
        invoke composeBuffer,esi
	.endif

	ret
checkIntoDestination ENDP

pickCurrentPlane PROC USES eax edx edi esi currentPiece:DWORD
	mov esi,currentPiece
	.if ([esi].PiecePosition.Lane == 2)	
		mov edi,OFFSET outerLanePlaneCount
		mov edx,OFFSET outerLanePlanePlayer
		;���ص�ǰ�ɻ���Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;ediΪ��Ȧ��¼�Ķ�Ӧλ�� edxΪ�Ǹ�λ�õ���ɫ
		add edi,eax
		add edx,eax
		.if (BYTE PTR [edi] == 1)
			mov BYTE PTR[edi],0
			mov BYTE PTR[edx],-1
		.else ;BYTE PTR [edi] >= 2
			sub BYTE PTR[edi],1
		.endif
	.elseif ([esi].PiecePosition.Lane == 3)
		mov edi,OFFSET innerLanePlaneCount
		;���ص�ǰ�ɻ���Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;ediΪ��Ȧ��¼�Ķ�Ӧλ�� edxΪ�Ǹ�λ�õ���ɫ
		add edi,eax

		;��Ӧλ�ø���-1
		sub BYTE PTR [edi],1	
	.endif
	ret 
pickCurrentPlane ENDP

setCurrentPlane PROC USES eax edx edi esi currentPiece:DWORD
	mov esi,currentPiece

	.if ([esi].PiecePosition.Lane == 2)	
		mov edi,OFFSET outerLanePlaneCount
		mov edx,OFFSET outerLanePlanePlayer
		;���ص�ǰ�ɻ���Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;ediΪ��Ȧ��¼�Ķ�Ӧλ�õĸ��� edxΪ�Ǹ�λ�õ���ɫ
		add edi,eax
		add edx,eax
		.if (BYTE PTR [edi] == 0)
			;������Ϊ1
			mov BYTE PTR[edi],1
			;��������Ϊ��ǰ��ҵ����
			mov ah,[esi].PiecePosition.Player
			mov BYTE PTR[edx],ah
		.else ;BYTE PTR [edi] >= 1
			add BYTE PTR[edi],1
		.endif
	.elseif ([esi].PiecePosition.Lane == 3)
		mov edi,OFFSET innerLanePlaneCount
		;���ص�ǰ�ɻ���Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;ediΪ��Ȧ��¼�Ķ�Ӧλ�� edxΪ�Ǹ�λ�õ���ɫ
		add edi,eax

		;��Ӧλ�ø���+1
		add BYTE PTR [edi],1	
	.endif
	ret
setCurrentPlane ENDP

composeBuffer PROC USES eax ecx esi currentPiece:DWORD
    invoke Sleep, 500
	mov esi,currentPiece

	;��֯buffer����Ϣ
	mov _sbuf[0],'U'
	mov _sbuf[1],' '
	mov al,[esi].PiecePosition.Player
	mov _sbuf[2],al
	mov _sbuf[3],' '
	mov al,[esi].PiecePosition.Id
	mov _sbuf[4],al
	mov _sbuf[5],' '
	mov al,[esi].PiecePosition.Lane
	mov _sbuf[6],al
	mov _sbuf[7],' '
	mov al,[esi].PiecePosition.Position
	mov _sbuf[8],al

    push ecx
    invoke crt_printf, addr _sendDisplayFormat, addr _sbuf
	pop ecx

	;����
    invoke _Broadcast

	ret
composeBuffer ENDP

nextPlayer PROC
	.if (currentPlayer == MAX_SOCK - 1)
		mov currentPlayer,0
	.else
		add currentPlayer,1
	.endif		
	
	;���õ�ǰ��������
	mov currentStep,0
	ret 
nextPlayer ENDP

testWin PROC USES eax ecx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov edi,OFFSET chessBoard

	;ѭ�������Ŵ�
	mov ecx,0
	mov cl,[esi].PiecePosition.Player

	.if (ecx > 0)
	L1:
		add edi,SIZEOF PiecePosition * 4
		loop L1
	.endif
	
	mov dl,1
	;ediΪ��ǰ��ҵ�һ���ɻ���λ��

	mov ecx,4
checkLoop:
	.if ([edi].PiecePosition.Lane != 4)
		mov dl,0
		jmp Quit
	.endif		
	add edi,SIZEOF PiecePosition
	loop checkLoop
Quit:
	ret
testWin ENDP

composeWinBuffer PROC USES eax
	mov eax,currentPlayer
 
	mov _sbuf[0],'W'
	mov _sbuf[1],' '
	mov _sbuf[2],al

	;����
    invoke _Broadcast

	ret
composeWinBuffer ENDP

;============================xyw


;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy

_ClearR PROC uses ecx
    xor ecx, ecx
    .while ecx < 10
        mov _rbuf[ecx], 0
        inc ecx
    .endw
    ret
_ClearR ENDP

_ClearS PROC uses ecx
    xor ecx, ecx
    .while ecx < 10
        mov _sbuf[ecx], 0
        inc ecx
    .endw
    ret
_ClearS ENDP

_Encode PROC uses ecx
    mov ecx, 2
    .while ecx <= 8
        .if _sbuf[ecx] != 0
            inc _sbuf[ecx]
        .endif
        add ecx, 2
    .endw
    ret
_Encode ENDP

_Decode PROC
    .if _rbuf[2] != 0
        dec _rbuf[2]
    .endif
    ret
_Decode ENDP

_RecvData PROC, sock
    invoke _ClearR
    invoke recv, sock, addr _rbuf, sizeof _rbuf, NULL
    invoke _Decode
    invoke crt_printf, addr _recvDisplayFormat, addr _rbuf
    invoke parseCommand
    invoke Sleep, 500
    ret
_RecvData ENDP

_Broadcast PROC uses ebx ecx
    invoke _Encode
    xor ebx, ebx
    .while bl < MAX_SOCK
        invoke send, _sockList[ebx * 4], addr _sbuf, sizeof _sbuf, 0
        inc bl
    .endw
    invoke _ClearS
    ret
_Broadcast ENDP


_HandleBegin PROC uses eax ebx
    invoke _ClearS
    mov _sbuf[0], 'R'
    mov _sbuf[1], ' '
    mov bl, BYTE PTR currentPlayer
    mov _sbuf[2], bl

    invoke _Broadcast
    ret
_HandleBegin ENDP

processCommand PROC USES eax ebx ecx edx esi 
	;������
	.if (verb=='R')
		mov eax,0
		;�����������eax��
		invoke iRand,1,6
        ;mov eax, 6
        push eax

        .if eax == 6
            mov _rollAgain, 1
        .else
            mov _rollAgain, 0
        .endif

		;��֯�ظ����
		invoke _ClearS

	    mov _sbuf[0], 'D'
	    mov _sbuf[1], ' '
	    mov ebx, currentPlayer
	    mov _sbuf[2], bl
	    mov _sbuf[3], ' '
	    mov _sbuf[4], al

        invoke _Broadcast

		;��¼��ǰ�Ĳ���
        pop currentStep
		;mov currentStep,eax

		;�ж�һ�µ�ǰ�����û�����ߵ� dl = 1�е����� dl = 0û�����ߵ�
        invoke testCanMove

        .if (dl == 1)
            mov _sbuf[0], 'S'
	        mov _sbuf[1], ' '
	        mov ebx, currentPlayer
	        mov _sbuf[2], bl

            mov canMoveFlag,1
            invoke _Broadcast
        .else
            mov canMoveFlag,0
        .endif

	;�ƶ�	
	.elseif (verb=='M')
        ; reply
        ;mov _sbuf[0], 'M'
        ;mov _sbuf[1], ' '
        ;mov _sbuf[3], ' '
        ;push eax
        ;mov al, BYTE PTR currentPlayer
        ;mov _sbuf[2], al
        ;mov al, operand
        ;mov _sbuf[4], al
        ;pop eax
        ;invoke _Broadcast

		remainStep = currentStep

		mov esi,OFFSET chessBoard
		;�ҵ���ǰ���������
		mov ecx,currentPlayer
		.if (ecx > 0)
L1:
			add esi,(SIZEOF PiecePosition) * 4 
			loop L1
		.endif 

		;�ҵ�����Ҳ���������
		mov ecx,currentPlane
		.if (ecx > 0)
L2:
			add esi,(SIZEOF PiecePosition)
			loop L2
		.endif

		mov al,[esi].PiecePosition.Lane
		.if ([esi].PiecePosition.Lane > 0 && [esi].PiecePosition.Lane <= 3) ;����Ϸ���ڲ�
			;������ɻ�����
			invoke pickCurrentPlane,esi

			;ѭ���ƶ��ɻ�
			mov ecx,remainStep
			MoveStep:
				;��ǰ�ƶ�һ��
				invoke moveOneStep,esi
				;����ǲ����ߵ���ǽ��
				invoke checkBlock,esi
				loop MoveStep
			;�����ǲ����ߵ��յ�
			invoke checkIntoDestination,esi
			;��֤�����ߵ���ǽ�� (�ƶ�һ��)
			invoke secureNotOnBlock,esi

			;��ɱ�����ķɻ� ��Ծ�ͽݾ�
			invoke jumpAndShortCut,esi
			
			;������ɻ�����
			invoke setCurrentPlane,esi

			;����ǲ����Ѿ�ʤ�� dl = 1 �Ѿ�ʤ�� dl = 0 ��δʤ��
			invoke testWin,esi
			
			.if (dl == 1)
				invoke composeWinBuffer
			.endif

		.elseif ([esi].PiecePosition.Lane == 0 && currentStep == 6)
			;�Ƴ���׼����
			invoke moveOut,esi
		.endif
		
		;���õ�ǰ�ķ���
		mov currentDirection,0
        mov canMoveFlag,1

		;�ƶ���ɣ���һ����ҽ��в���
		;call nextPlayer
	.endif
Quit:
	ret
processCommand ENDP

_InitServer PROC USES eax ebx esi
    invoke WSAStartup, _wsaVersion, addr _wsaData
    .if eax
        invoke ExitProcess, 0
    .endif

    invoke socket, AF_INET, SOCK_STREAM, 0
    .if eax != INVALID_SOCKET
        mov _hListenSock, eax
    .endif

    invoke RtlZeroMemory, addr _sockAddr, sizeof _sockAddr
    invoke htons, PORT
    mov _sockAddr.sin_port, ax
    mov _sockAddr.sin_family, AF_INET
    mov _sockAddr.sin_addr, INADDR_ANY

    invoke bind, _hListenSock, addr _sockAddr, sizeof _sockAddr
    .if eax == SOCKET_ERROR
        invoke ExitProcess, 0
    .else 
        invoke listen, _hListenSock, 5
    .endif
    
    ;invoke crt_printf, addr _msgAfterInit

    ; connect
    mov ebx, 0
    .while ebx < MAX_SOCK
        invoke accept, _hListenSock, NULL, NULL
        .continue .if eax == INVALID_SOCKET
        mov _sockList[ebx * 4], eax

        invoke crt_printf, addr _connectFormat, ebx
        inc ebx
    .endw
    
    ;invoke crt_printf, addr _msgAfterConnect
    ret
_InitServer ENDP

_Prepare PROC USES eax ebx esi
    mov ebx, 0
    xor esi, esi
    .while ebx < MAX_SOCK
        ; send(P i)
        invoke RtlZeroMemory, addr _sbuf, sizeof _sbuf
        
        mov _sbuf[0], 'P'
        mov _sbuf[1], ' '
        mov _sbuf[2], bl
        inc _sbuf[2]
        invoke send, _sockList[ebx * 4], addr _sbuf, sizeof _sbuf, 0

        invoke _RecvData, _sockList[ebx * 4]
        invoke crt_printf, addr _prepareFormat, ebx

        inc ebx
    .endw

    ;invoke crt_printf, addr _msgAfterPrepare
    ret
_Prepare ENDP

_ConsoleMain PROC USES eax ebx edx esi edi

    ;invoke crt_printf, addr _msgBeforeInit

    invoke _InitServer

    invoke _Prepare

    invoke init

    ; main loop
    .while TRUE
        

        xor ebx, ebx
        ;xor edi, edi
        .while bl < MAX_SOCK

            invoke Sleep, 500
            
            ; send("R i")
            invoke _HandleBegin
            

            ; recv() = "R"
            invoke _RecvData, _sockList[ebx * 4]

            ; send("D i m")
            ;invoke _HandleRoll
            invoke processCommand

            .if canMoveFlag == 0
                jmp PNextPlayer
            .endif
           
            ; recv() = "M k"
            invoke _RecvData, _sockList[ebx * 4]

            ; send("M i k")
            ; send("U")
            ; send("W i")
            ;invoke _HandleMove
            invoke processCommand

PNextPlayer:
            ;.if _rollAgain == 0
                invoke nextPlayer
                inc bl
            ;.endif
        .endw

        ;.break ; for test
    .endw
    ret

_ConsoleMain ENDP

main PROC
    ; test
    ;invoke init

    ; test parsecommand
    ;mov currentPlayer, 1
    ;mov al, BYTE PTR currentPlayer

    ;;.
    
    invoke _ConsoleMain
    invoke ExitProcess, NULL
main ENDP
end main


;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<sgy

; ===============20==================40==================60==================80