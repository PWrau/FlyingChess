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
;棋子位置结构体
PiecePosition STRUCT
	Player BYTE 0
	Id BYTE 0
	Lane BYTE 0
	Position BYTE 0 
PiecePosition ENDS

;初始化
init PROTO
;解析发来的指令
parseCommand PROTO				
;随机数
iRand PROTO first:DWORD,second:DWORD
;飞机的移动
moveOneStep PROTO currentPiece:DWORD
moveOut PROTO currentPiece:DWORD
jumpAndShortCut PROTO currentPiece:DWORD
outerKillOtherPlane PROTO currentPiece:DWORD
shortCutKillOtherPlane PROTO currentPiece:DWORD
secureNotOnBlock PROTO currentPiece:DWORD
;测试能不能进行跳跃和飞跃
testShortCut PROTO currentPiece:DWORD
testJump PROTO currentPiece:DWORD
;测试有无子可以走
testCanMove PROTO
;转换移动的方向
changeDirection PROTO
;查看当前位置是不是有墙		
checkBlock PROTO currentPiece:DWORD
;查看当前操作飞机是不是走到了终点
checkIntoDestination PROTO currentPiece:DWORD
;放下当前位置的飞机
setCurrentPlane PROTO currentPiece:DWORD
;拿起当前位置的飞机
pickCurrentPlane PROTO currentPiece:DWORD
;组织返回的信息
composeBuffer PROTO currentPiece:DWORD
;处理信息的主函数
processCommand PROTO
;换成下一个玩家
nextPlayer PROTO
;检查是不是一方是不是已经胜利 dl = 1 当前玩家胜利 dl = 0 当前玩家尚未胜利
testWin PROTO currentPiece:DWORD
;组织胜利的信息
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
;接收的消息和发送的消息
;buffer BYTE 50 DUP(0)

;一次操作的指令和操作数
verb BYTE 0
operand BYTE 0

;棋盘信息记录
chessBoard PiecePosition 16 DUP(<>)		;棋盘上所有飞机的信息
currentPlayer DWORD 0					;当前操作的玩家号 
currentPlane DWORD 0					;当前操作的飞机号
currentStep DWORD 0						;当前扔出的骰子数
currentDirection DWORD 0				;当前方向 0 向前 1 向后
outerLanePlaneCount BYTE 52 DUP(0)		;当前外圈的每个格子有多少架飞机
outerLanePlanePlayer BYTE 52 DUP(-1)	;当前外圈每个格子的所属玩家号
innerLanePlaneCount BYTE 24 DUP(0)		;当前内圈的每个格子有多少架飞机
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
	;当前的玩家号(k)
	mov al,0
	;当前的飞机号()
	mov bl,0

	;当前操作的结构体序号
	mov esi,OFFSET chessBoard
L1:
	mov [esi].PiecePosition.Player,al
	mov [esi].PiecePosition.Id,bl
	mov [esi].PiecePosition.Lane,0
	;当前位置=4k~4k+3
	mov [esi].PiecePosition.Position,al
	mov ecx,3
AddLoop:
	add [esi].PiecePosition.Position,al
	loop AddLoop
	add [esi].PiecePosition.Position,bl

	;下一个结构体
	add esi,SIZEOF PiecePosition
	;al,bl的更新
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

;eax为最后的随机数
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

;前进一步
moveOneStep PROC USES eax esi currentPiece:DWORD
	mov esi,currentPiece
	.if ([esi].PiecePosition.Lane == 1)
		;走到自己的第一个格子中
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
				;该走入内圈
				mov [esi].PiecePosition.Lane,3
				mov [esi].PiecePosition.Position,0
			.else
				;在外圈前进一格
				add [esi].PiecePosition.Position,1
				.if ([esi].PiecePosition.Position >= 52)
					sub [esi].PiecePosition.Position,52
				.endif
			.endif
		.else
			;在外圈后退一格
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
	;组织buffer的信息
	invoke composeBuffer,currentPiece
	ret
moveOneStep ENDP

;移出港区
moveOut PROC USES eax esi currentPiece:DWORD
	mov esi,currentPiece
	mov [esi].PiecePosition.Lane,1
	mov al,[esi].PiecePosition.Player
	mov [esi].PiecePosition.Position,al
	;组织buffer的信息
	invoke composeBuffer, currentPiece
	ret 
moveOut ENDP

;测试有没有飞机可以走 dl = 1 有的可以走 dl = 0 无可走
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
    
    ;esi为当前玩家第一个飞机的位置
    mov ecx,4
checkLoop:
    .if ([esi].PiecePosition.Lane != 0 && [esi].PiecePosition.Lane != 4)
        mov dl,1
        jmp Quit
    .endif
    add esi,SIZEOF PiecePosition
    ;下一个飞机
    loop checkLoop

Quit:
    ret
testCanMove ENDP

;测试是不是可以进行飞跃 可以飞跃 dl = 1 不可以飞跃 dl = 0
testShortCut PROC USES eax ebx ecx esi edi currentPiece:DWORD
	mov esi,currentPiece	
	mov dl,1

	;eax为外圈飞跃到的index
	mov edi,OFFSET outerLanePlaneCount
	mov ebx,OFFSET outerLanePlanePlayer
	mov eax,0
	mov al,[esi].PiecePosition.Position	
	add al,12

	.if al >= 52
		sub al,52
	.endif

	;edi外圈对应位置飞机个数 ebx外圈对应位置玩家颜色
	add edi,eax
	add ebx,eax


	;cl为当前操作飞机的颜色
	mov cl,[esi].PiecePosition.Player
	.if (BYTE PTR [edi] >= 2 && cl != BYTE PTR [ebx]) 
		mov dl,0
		jmp Quit
	.endif

	;eax为飞跃过程中经过的内圈index
	mov edi,OFFSET innerLanePlaneCount
	mov eax,0
	mov al,[esi].PiecePosition.Player
	add al,2
	.if al >= 4
		sub al,4
	.endif
	add al,8
	
	;edi内圈对应位置飞机个数 
	add edi,eax


	.if (BYTE PTR [edi] >= 2) 
		mov dl,0
		jmp Quit
	.endif

Quit:
	ret 
testShortCut ENDP

;测试是不是进行跳跃4格 可以跳跃 dl = 1 不可以跳跃 dl = 0
testJump PROC USES eax ebx ecx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov dl,1

	mov ecx,4	;检查4个格	
	;eax为外圈跳跃时 遍历到的index
	mov eax,0
	mov al,[esi].PiecePosition.Position	
L1: 
	add al,1

	.if al >= 52
		sub al,52
	.endif

	mov edi,OFFSET outerLanePlaneCount
	mov ebx,OFFSET outerLanePlanePlayer
	;edi外圈对应位置飞机个数 ebx外圈对应位置玩家颜色
	add edi,eax
	add ebx,eax

	mov dl,1
	;cl为当前操作飞机的颜色
	mov dh,[esi].PiecePosition.Player
	.if (BYTE PTR [edi] >= 2 && dh != BYTE PTR [ebx]) 
		mov dl,0
		jmp QL1
	.endif

	loop L1
QL1:
	ret 
testJump ENDP



;测试跳跃或者飞跃
jumpAndShortCut PROC USES eax ebx ecx edx esi currentPiece:DWORD
	mov esi,currentPiece

	;[ebp - 4] == jumpFlag
	enter 4,0
	mov DWORD PTR[ebp - 4],0

    .if [esi].PiecePosition.Lane != 2
        jmp Quit
    .endif

	;bl = (13*玩家号 + 20) % 52
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

	;踩踏外圈的飞机
	invoke outerKillOtherPlane,esi
L1:
	.if (bl == [esi].PiecePosition.Position)
		;测试能不能飞跃
		invoke testShortCut,esi
		.if dl == 0
			jmp Quit
		.endif
		;飞跃12格
		add [esi].PiecePosition.Position,12
		.if [esi].PiecePosition.Position >= 52 
			sub [esi].PiecePosition.Position,52
		.endif

		;组织buffer的信息 
		invoke composeBuffer,esi
		;飞跃摧毁飞机
		invoke shortCutKillOtherPlane,esi
		;踩踏外圈的飞机
		invoke outerKillOtherPlane,esi
	.elseif (bh == 0 && DWORD PTR [ebp - 4] == 0 && cl!=[esi].PiecePosition.Position)
		mov DWORD PTR [ebp - 4],1
		;测试能不能跳跃
		invoke testJump,esi
		.if dl == 0
			jmp Quit
		.endif
		;跳跃4格
		add [esi].PiecePosition.Position,4
		.if ([esi].PiecePosition.Position >= 52)
			sub [esi].PiecePosition.Position,52
		.endif

		;组织buffer的信息 
		invoke composeBuffer,esi
		;踩踏外圈的飞机
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


	;如果这个位置不是外圈 直接退出
	.if [esi].PiecePosition.Lane != 2
		jmp Quit
	.endif

	;eax为外圈的index
	mov eax,0
	mov al,[esi].PiecePosition.Position
	;edi外圈对应位置飞机个数 edx外圈对应位置玩家颜色
	add edi,eax
	add edx,eax

	.if (BYTE PTR [edi] >= 2 || BYTE PTR [edi] == 0)	;如果对应位置飞机个数为0 或者 个数多于2 没有踩到其他飞机
		jmp Quit 
	.elseif ;BYTE PTR [edi] == 1
		;操作飞机的玩家颜色
		mov bl,[esi].PiecePosition.Player
		.if bl != BYTE PTR [edx]
			mov ecx,0
			;如果是别的颜色的1架飞机 它需要退回家
			mov cl,BYTE PTR [edx]
			;遍历这个棋盘棋子信息来找到这个棋子
			mov esi,OFFSET chessBoard

			;找到这个颜色的位置
			.if ecx > 0 
L1:
				add esi,SIZEOF PiecePosition * 4
				loop L1
			.endif

			;遍历这个玩家的所有飞机
			mov ecx,4
Lcheck:
			.if ([esi].PiecePosition.Lane == 2 && al == [esi].PiecePosition.Position)
				mov [esi].PiecePosition.Lane,0
				mov bl,[esi].PiecePosition.Player
				;这个飞机的位置是 4 Player + Id
				mov [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl

				mov bl,[esi].PiecePosition.Id
				add [esi].PiecePosition.Position,bl

				;组织并发出信息
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
	;al为飞跃的玩家的颜色
	mov eax,0
	mov al,[esi].PiecePosition.Player

	add al,2
	.if(al >= 4)
		sub al,4
	.endif

	add al,8
	
	;对面玩家内圈位置的飞机个数
	add edi,eax
	.if BYTE PTR [edi] == 1
		;如果只有一架飞机，退回家
		
		;al为那个玩家的颜色
		sub al,8

		mov ecx,0
		mov cl,al

		mov esi,OFFSET chessBoard
		.if ecx > 0
L1:
			add esi,SIZEOF PiecePosition * 4
			loop L1
		.endif

		;遍历这个玩家的所有飞机
		mov ecx,4
		;al为那个格子的位置
		add al,8
		checkLoop:
			.if ([esi].PiecePosition.Lane == 3 && al == [esi].PiecePosition.Position)
				;将这个飞机退回基地
				mov [esi].PiecePosition.Lane,0
				mov bl,[esi].PiecePosition.Player
				;这个飞机的位置是 4 Player + Id
				mov [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl
				add [esi].PiecePosition.Position,bl

				mov bl,[esi].PiecePosition.Id
				add [esi].PiecePosition.Position,bl

				;组织并发出信息
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
	;edi为外圈的飞机个数 edx为外圈的飞机的颜色
	mov edi,OFFSET outerLanePlaneCount
	mov edx,OFFSET outerLanePlanePlayer

	mov eax,0
	mov al,[esi].PiecePosition.Position

	;edi为外圈对应位置的飞机个数 edx为外圈对应位置的飞机的颜色
	add edi,eax
	add edx,eax

	.if [esi].PiecePosition.Lane == 2
		;遇到其他玩家的墙
		mov bl,[esi].PiecePosition.Player
		.if (BYTE PTR [edi] >= 2 && bl != BYTE PTR [edx])
			;移动一步，从墙上走下来
			invoke moveOneStep,esi
		.endif
	.endif
	ret 
secureNotOnBlock ENDP

checkBlock PROC USES eax ebx ecx edx edi esi currentPiece:DWORD
	mov esi,currentPiece
	;edi为外圈的飞机个数 edx为外圈的飞机的颜色
	mov edi,OFFSET outerLanePlaneCount
	mov edx,OFFSET outerLanePlanePlayer

	mov eax,0
	mov al,[esi].PiecePosition.Position

	;edi为外圈对应位置的飞机个数 edx为外圈对应位置的飞机的颜色
	add edi,eax
	add edx,eax

	.if [esi].PiecePosition.Lane == 2
		;遇到其他玩家的墙
		mov bl,[esi].PiecePosition.Player
		.if (BYTE PTR [edi] >= 2 && bl != BYTE PTR [edx])
			call changeDirection	;转换方向
		.endif
	.endif
	ret 
checkBlock ENDP

checkIntoDestination PROC USES eax esi currentPiece:DWORD
	mov esi, currentPiece

	mov al,[esi].PiecePosition.Player
	add al,20

	.if (al==[esi].PiecePosition.Position && [esi].PiecePosition.Lane == 3)
		; 当前飞机的航道类别 = 4
		mov [esi].PiecePosition.Lane,4
		; 当前飞机的位置 = 玩家号
		sub [esi].PiecePosition.Position,20

        ;发送消息
        invoke composeBuffer,esi
	.endif

	ret
checkIntoDestination ENDP

pickCurrentPlane PROC USES eax edx edi esi currentPiece:DWORD
	mov esi,currentPiece
	.if ([esi].PiecePosition.Lane == 2)	
		mov edi,OFFSET outerLanePlaneCount
		mov edx,OFFSET outerLanePlanePlayer
		;加载当前飞机的Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;edi为外圈记录的对应位置 edx为那个位置的颜色
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
		;加载当前飞机的Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;edi为外圈记录的对应位置 edx为那个位置的颜色
		add edi,eax

		;对应位置个数-1
		sub BYTE PTR [edi],1	
	.endif
	ret 
pickCurrentPlane ENDP

setCurrentPlane PROC USES eax edx edi esi currentPiece:DWORD
	mov esi,currentPiece

	.if ([esi].PiecePosition.Lane == 2)	
		mov edi,OFFSET outerLanePlaneCount
		mov edx,OFFSET outerLanePlanePlayer
		;加载当前飞机的Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;edi为外圈记录的对应位置的个数 edx为那个位置的颜色
		add edi,eax
		add edx,eax
		.if (BYTE PTR [edi] == 0)
			;个数变为1
			mov BYTE PTR[edi],1
			;玩家序号置为当前玩家的序号
			mov ah,[esi].PiecePosition.Player
			mov BYTE PTR[edx],ah
		.else ;BYTE PTR [edi] >= 1
			add BYTE PTR[edi],1
		.endif
	.elseif ([esi].PiecePosition.Lane == 3)
		mov edi,OFFSET innerLanePlaneCount
		;加载当前飞机的Position
		mov eax,0
		mov al,[esi].PiecePosition.Position
		;edi为外圈记录的对应位置 edx为那个位置的颜色
		add edi,eax

		;对应位置个数+1
		add BYTE PTR [edi],1	
	.endif
	ret
setCurrentPlane ENDP

composeBuffer PROC USES eax ecx esi currentPiece:DWORD
    invoke Sleep, 500
	mov esi,currentPiece

	;组织buffer的信息
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

	;发送
    invoke _Broadcast

	ret
composeBuffer ENDP

nextPlayer PROC
	.if (currentPlayer == MAX_SOCK - 1)
		mov currentPlayer,0
	.else
		add currentPlayer,1
	.endif		
	
	;重置当前的骰子数
	mov currentStep,0
	ret 
nextPlayer ENDP

testWin PROC USES eax ecx esi edi currentPiece:DWORD
	mov esi,currentPiece
	mov edi,OFFSET chessBoard

	;循环玩家序号次
	mov ecx,0
	mov cl,[esi].PiecePosition.Player

	.if (ecx > 0)
	L1:
		add edi,SIZEOF PiecePosition * 4
		loop L1
	.endif
	
	mov dl,1
	;edi为当前玩家第一个飞机的位置

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

	;发送
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
	;扔骰子
	.if (verb=='R')
		mov eax,0
		;随机数生成在eax中
		invoke iRand,1,6
        ;mov eax, 6
        push eax

        .if eax == 6
            mov _rollAgain, 1
        .else
            mov _rollAgain, 0
        .endif

		;组织回复语句
		invoke _ClearS

	    mov _sbuf[0], 'D'
	    mov _sbuf[1], ' '
	    mov ebx, currentPlayer
	    mov _sbuf[2], bl
	    mov _sbuf[3], ' '
	    mov _sbuf[4], al

        invoke _Broadcast

		;记录当前的步数
        pop currentStep
		;mov currentStep,eax

		;判断一下当前玩家有没有能走的 dl = 1有的能走 dl = 0没有能走的
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

	;移动	
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
		;找到当前操作的玩家
		mov ecx,currentPlayer
		.if (ecx > 0)
L1:
			add esi,(SIZEOF PiecePosition) * 4 
			loop L1
		.endif 

		;找到该玩家操作的棋子
		mov ecx,currentPlane
		.if (ecx > 0)
L2:
			add esi,(SIZEOF PiecePosition)
			loop L2
		.endif

		mov al,[esi].PiecePosition.Lane
		.if ([esi].PiecePosition.Lane > 0 && [esi].PiecePosition.Lane <= 3) ;在游戏区内部
			;把这个飞机拿起
			invoke pickCurrentPlane,esi

			;循环移动飞机
			mov ecx,remainStep
			MoveStep:
				;向前移动一步
				invoke moveOneStep,esi
				;检查是不是走到了墙上
				invoke checkBlock,esi
				loop MoveStep
			;测试是不是走到终点
			invoke checkIntoDestination,esi
			;保证不是走到了墙上 (移动一步)
			invoke secureNotOnBlock,esi

			;击杀其他的飞机 跳跃和捷径
			invoke jumpAndShortCut,esi
			
			;把这个飞机放下
			invoke setCurrentPlane,esi

			;检查是不是已经胜利 dl = 1 已经胜利 dl = 0 尚未胜利
			invoke testWin,esi
			
			.if (dl == 1)
				invoke composeWinBuffer
			.endif

		.elseif ([esi].PiecePosition.Lane == 0 && currentStep == 6)
			;移出到准备区
			invoke moveOut,esi
		.endif
		
		;重置当前的方向
		mov currentDirection,0
        mov canMoveFlag,1

		;移动完成，下一个玩家进行操作
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