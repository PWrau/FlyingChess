;include F:\asmlib\Irvine\Irvine32.inc

;����λ�ýṹ��
PiecePosition STRUCT
	Player BYTE 0
	Id BYTE 0
	Lane BYTE 0
	Position BYTE 0 
PiecePosition ENDS

.386
.model flat,stdcall
.stack 4096
ExitProcess PROTO,dwExitCode:dword

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


.data
endl EQU <0dh,0ah>
;���յ���Ϣ�ͷ��͵���Ϣ
buffer BYTE 50 DUP(0)

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
	mov al,buffer[0]
	mov verb,al
	
	.if (buffer[1]==' ')
		mov al,buffer[2]
		mov operand,al
		mov currentPlane,eax
		sub currentPlane,'0'
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
jumpAndShortCut PROC USES eax ebx esi currentPiece:DWORD
	mov esi,currentPiece

	;[ebp - 4] == jumpFlag
	enter 4,0
	mov DWORD PTR[ebp - 4],0

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

outerKillOtherPlane PROC USES eax ebx esi edi currentPiece:DWORD
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
		mov al,[esi].PiecePosition.Player
		.if al != BYTE PTR [edx]
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

shortCutKillOtherPlane PROC USES esi edi currentPiece:DWORD
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

checkBlock PROC USES eax edx edi esi currentPiece:DWORD
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

composeBuffer PROC USES eax esi currentPiece:DWORD
	mov esi,currentPiece

	;��֯buffer����Ϣ
	mov buffer[0],'U'
	mov buffer[1],' '
	mov al,[esi].PiecePosition.Player
	mov buffer[2],al
	mov buffer[3],' '
	mov al,[esi].PiecePosition.Id
	mov buffer[4],al
	mov buffer[5],' '
	mov al,[esi].PiecePosition.Lane
	mov buffer[6],al
	mov buffer[7],' '
	mov al,[esi].PiecePosition.Position
	mov buffer[8],al
	
	ret
composeBuffer ENDP

processCommand PROC
	;������
	.if (verb=='R')
		mov eax,0
		;�����������eax��
		invoke iRand,1,6

		;��֯�ظ����
		mov buffer[0],'D'
		mov buffer[1],' '
		mov ebx,currentPlayer
		mov buffer[2],bl
		mov buffer[3],' '
		mov buffer[4],al

		;��¼��ǰ�Ĳ���
		mov currentStep,eax

		;������Ϣ

	;�ƶ�	
	.elseif (verb=='M')
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

			;��Ծ�ͽݾ�
			invoke jumpAndShortCut,esi
			
			;������ɻ�����
			invoke setCurrentPlane,esi

		.elseif ([esi].PiecePosition.Lane == 0 );&& currentStep == 6)
			;�Ƴ���׼����
			invoke moveOut,esi
		.endif


		;�ƶ���ɣ���һ����ҽ��в���
		;call nextPlayer
	.endif

	ret
processCommand ENDP

nextPlayer PROC
	.if (currentPlayer == 3)
		mov currentPlayer,0
	.else
		add currentPlayer,1
	.endif

	mov currentDirection,0
	mov currentStep,0
	ret 
nextPlayer ENDP

fmain PROC

	;��ʼ�����ӵ�λ��
	call init

CommandLoop:
	;����һ������
	mov edx,OFFSET buffer
	mov ecx,SIZEOF buffer
	;call ReadString

	;�����������
	call parseCommand

	;�����������
	call processCommand

	;whileѭ��
	jmp CommandLoop

	;invoke ExitProcess,0
    ret
fmain ENDP
