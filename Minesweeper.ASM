format PE64 CONSOLE
entry main
use64

section '.code' code readable executable
;takes rcx in
getStringLength:
        xor rax, rax

.loopStart:
        mov dl, [rcx + rax]
        cmp dl, 0
        je .end

        inc rax
        jmp .loopStart
.end:
        ret

print:
        sub rsp, 40

        call getStringLength
        mov r8, rax
        mov rdx, rcx

        mov rcx, -11
        call [GetStdHandle]
        mov rcx, rax

        xor r9d, r9d
        mov qword[rsp+32], 0
        call [WriteFile]

        add rsp, 40
        ret

readConsole:
        sub rsp, 40

        mov rdx, rcx

        mov ecx, -10
        call [GetStdHandle]
        mov rcx, rax

        mov r8d, 40
        xor r9d, r9d
        mov qword[rsp+32], 0
        call [ReadFile]

        add rsp, 40
        ret

resetConsoleCursor:
        sub rsp, 48

        mov dword[rsp+40], ecx

        mov ecx, -11
        call [GetStdHandle]
        mov rcx, rax

        mov edx, dword[rsp+40]
        call [SetConsoleCursorPosition]

        add rsp, 48
        ret

clearScreen:
        sub rsp, 40
        mov qword [rsp+32], 0

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        mov rdi, 0
.pushLine:
        lea rcx, [emt]
        call print

        mov rdi, qword[rsp+32]
        add rdi, 1
        cmp rdi, 4096
        mov qword[rsp+32], rdi
        jl .pushLine

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        add rsp, 40
        ret

handleInput:
        sub rsp, 40

        movzx rdx, word[W_KEY]
        cmp rcx, rdx
        je .isW

        movzx rdx, word[A_KEY]
        cmp rcx, rdx
        je .isA

        movzx rdx, word[S_KEY]
        cmp rcx, rdx
        je .isS

        movzx rdx, word[D_KEY]
        cmp rcx, rdx
        je .isD

        movzx rdx, word[E_KEY]
        cmp rcx, rdx
        je .isE

        movzx rdx, word[F_KEY]
        cmp rcx, rdx
        je .isF

        jmp .default

.isW:
        movzx rcx, word [cursor]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .jumpDown
        je .jumpDown
        jg .shiftUp

.jumpDown:
        mov rax, qword [mapDimen]
        mov rcx, rax
        sub rcx, 1
        mul rcx

        movzx rcx, word [cursor]
        add rax, rcx
        mov [cursor], ax

        jmp .default

.shiftUp:
        movzx rcx, word [cursor]
        mov rdx, qword [mapDimen]
        sub rcx, rdx
        mov [cursor], cx

        jmp .default
.isA:
        movzx rax, word [cursor]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx ; moves remainder to rax

        cmp rax, 0
        je .jumpRight
        jne .shiftLeft

.jumpRight:
        movzx rcx, word [cursor]
        mov rax, qword [mapDimen]
        sub rax, 1
        add rcx, rax
        mov [cursor], cx

        jmp .default

.shiftLeft:
        movzx rcx, word [cursor]
        sub rcx, 1
        mov [cursor], cx

        jmp .default
.isS:
        movzx rcx, word [cursor]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        jl .shiftDown
        je .jumpUp
        jg .jumpUp

.jumpUp:
        mov rax, qword [mapDimen]
        mov rcx, rax
        sub rcx, 1
        mul rcx

        movzx rcx, word [cursor]
        sub rcx, rax
        mov [cursor], cx

        jmp .default

.shiftDown:
        movzx rcx, word [cursor]
        mov rdx, qword [mapDimen]
        add rcx, rdx
        mov [cursor], cx

        jmp .default
.isD:
        movzx rax, word [cursor]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .jumpLeft
        jne .shiftRight


.jumpLeft:
        movzx rcx, word [cursor]
        mov rax, qword [mapDimen]
        sub rax, 1
        sub rcx, rax
        mov [cursor], cx

        jmp .default

.shiftRight:
        movzx rcx, word [cursor]
        add rcx, 1
        mov [cursor], cx

        jmp .default
.isE:
        movzx rax, word[cursor]
        movzx rcx, byte[map+rax]
        cmp [playerMap+rax], 9
        je .block
        mov [playerMap+rax], cl
.block:
        jmp .default
.isF:
        movzx rax, word[cursor]

        cmp [playerMap+rax], 11
        je .place

        cmp [playerMap+rax], 9
        je .remove

        jne .default

.place:
        mov [playerMap+rax], 9
        jmp .default
.remove:
        mov [playerMap+rax], 11

.default:

        add rsp, 40
        ret


clearMaps:
        mov rdi, 0
.loop:
        mov [map+rdi], 0
        mov [playerMap+rdi], 11

        add rdi, 1
        cmp rdi, [mapSize]
        jl .loop

        ret

generateDebugMap:
        mov [map+1], 1
        mov [map+2], 2
        mov [map+3], 3
        mov [map+4], 4
        mov [map+5], 5
        mov [map+6], 6
        mov [map+7], 7
        mov [map+8], 8
        mov [map+9], 9
        mov [map+10], 10
        mov [map+11], 11

        ret

generateMap:
        sub rsp, 48
        mov rax, [bombNum]
        mov qword[rsp+32], rax
        mov qword[rsp+40], 0

.bombLoopStart:

.retry:
        rdrand rax
        jnc .retry

        xor rdx, rdx
        mov rdx, qword[rsp+40]
        mov rcx, [mapSize]
        sub rcx, 1
        sub rcx, rdx

        cmp rdx, qword[rsp+32]
        je .placeBomb

        cmp rcx, 0
        je .noPlace

        xor rdx, rdx
        div rcx
        mov rax, rdx

        cmp rax, qword[rsp+32]
        jl .placeBomb
        jmp .noPlace

.placeBomb:
        mov rax, [safeSpot]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [leftSub]
        sub rax, [topSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [topSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [rightSub]
        sub rax, [topSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [leftSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [rightSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [leftSub]
        sub rax, [bottomSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [bottomSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, [safeSpot]
        sub rax, [rightSub]
        sub rax, [bottomSub]
        cmp rax, qword[rsp+40]
        je .noPlace

        mov rax, qword[rsp+40]
        mov [map+rax], 10

        mov rax, qword[rsp+32]
        sub rax, 1
        mov qword[rsp+32], rax

.noPlace:
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

        cmp rax, [mapSize]
        je .bombEnd
        jg .bombEnd

        mov rax, qword[rsp+40]
        cmp rax, 0
        je .bombEnd

        jmp .bombLoopStart
.bombEnd:

        mov qword[rsp+32], 0
.numStartLoop:
        mov qword[rsp+40], 0

        mov rax, qword[rsp+32]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        je .noNum

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkLeft
        je .checkLeft
        jg .checkUp

.checkUp:
        mov rax, qword[rsp+32]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkTopLeft

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkTopLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkTopLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkBottomLeft

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkBottomLeft
        je .checkBottomLeft

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkBottomLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkBottomLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkDown

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .checkDown
        jg .checkDown

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkDown
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkDown:
        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .checkRight
        jg .checkRight

        mov rax, qword[rsp+32]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkTopRight

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkTopRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkTopRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkBottomRight

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkBottomRight
        je .checkBottomRight

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .checkBottomRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkBottomRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .noNum

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .noNum
        jg .noNum

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]

        cmp rcx, 10
        jne .noNum
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.noNum:
        mov rax, qword[rsp+40]
        mov rcx, qword[rsp+32]
        cmp rax, 0
        je .skip
        mov [map+rcx], al
.skip:

        mov rax, qword[rsp+32]
        add rax, 1
        mov qword[rsp+32], rax

        cmp rax, [mapSize]
        je .numEnd
        jg .numEnd

        jmp .numStartLoop
.numEnd:
        add rsp, 48
        ret

;Takes rcx map
displayMap:
        sub rsp, 88

        mov qword[rsp+56], 0
        mov qword[rsp+64], rcx

        xor rax, rax

        lea rcx, [msg]
        call print

        lea rcx, [newLine]
        call print

        mov qword[rsp+80], 0
.loopTopLine:
        mov rdx, qword[rsp+80]
        cmp rdx, [mapDimen]
        je .endTopLine
        jg .endTopLine

        lea rcx, [topLine]
        call print

        mov rdx, qword[rsp+80]
        add rdx, 1
        mov qword[rsp+80], rdx
        jmp .loopTopLine
.endTopLine:

        lea rcx, [newLine]
        call print

.loopStart:
        mov rax, qword[rsp+56]
        mov rdx, qword[rsp+64]
        movzx rcx, byte [rax+rdx]
        mov qword[rsp+72], rcx

        movzx rdx, word[cursor]
        cmp rax, rdx
        jne .noCursor
        lea rcx, [curs]
        call print

.noCursor:
        cmp qword[rsp+72], 0
        lea rcx, [emt]
        je .print

        cmp qword[rsp+72], 1
        lea rcx, [num1]
        je .print

        cmp qword[rsp+72], 2
        lea rcx, [num2]
        je .print

        cmp qword[rsp+72], 3
        lea rcx, [num3]
        je .print

        cmp qword[rsp+72], 4
        lea rcx, [num4]
        je .print

        cmp qword[rsp+72], 5
        lea rcx, [num5]
        je .print

        cmp qword[rsp+72], 6
        lea rcx, [num6]
        je .print

        cmp qword[rsp+72], 7
        lea rcx, [num7]
        je .print

        cmp qword[rsp+72], 8
        lea rcx, [num8]
        je .print

        cmp qword[rsp+72], 9
        lea rcx, [flag]
        je .print

        cmp qword[rsp+72], 10
        lea rcx, [bomb]
        je .print

        cmp qword[rsp+72], 11
        lea rcx, [hidd]
        je .print

.print:
        call print

        add qword[rsp+56], 1

        mov rax, qword[rsp+56]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx ; moves remainder to rax

        cmp rax, 0
        jne .notNewLine
        lea rcx, [endLine]
        call print
        lea rcx, [newLine]
        call print
.notNewLine:

        mov rax, qword[rsp+56]
        cmp rax, [mapSize]
        je .end

        jmp .loopStart

.end:
        mov qword[rsp+80], 0
.loopBotLine:
        mov rdx, qword[rsp+80]
        cmp rdx, [mapDimen]
        je .endBotLine
        jg .endBotLine

        lea rcx, [topLine]
        call print

        mov rdx, qword[rsp+80]
        add rdx, 1
        mov qword[rsp+80], rdx
        jmp .loopBotLine
.endBotLine:

        lea rcx, [newLine]
        call print

        add rsp, 88
        ret


checkStatus:
        xor rcx, rcx
.lossLoop:
        cmp rcx, [mapSize]
        je .lossEnd
        jg .lossEnd

        movzx rax, byte[playerMap+rcx]
        add rcx, 1
        cmp rax, 10
        jne .lossLoop

        mov rax, 0
        ret

.lossEnd:
        xor rcx, rcx
.wonLoop:
        cmp rcx, [mapSize]
        je .wonEnd
        jg .wonEnd

        movzx rax, byte[playerMap+rcx]
        add rcx, 1
        cmp rax, 11
        jne .wonFlag

        mov rax, 1
        ret

.wonFlag:
       movzx rax, byte[playerMap+rcx-1]
       movzx rdx, byte[map+rcx-1]

       cmp rax, 9
       jne .wonLoop

       cmp rdx, 10
       je .wonLoop

       mov rax, 1
       ret

.wonEnd:
        mov rax, 2
        ret

autoClear:
        sub rsp, 48
        mov qword[rsp+32], 0
        mov qword[rsp+40], 0
.loopStart:
        mov rax, qword[rsp+32]
        movzx rcx, byte[playerMap+rax]

        cmp rcx, 0
        jne .noNum

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkLeft
        je .checkLeft
        jg .checkUp

.checkUp:
        mov rax, qword[rsp+32]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkLeft

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkTopLeft

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkTopLeft

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkTopLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkTopLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkBottomLeft

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkBottomLeft
        je .checkBottomLeft

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkBottomLeft

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkBottomLeft
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkBottomLeft:
        mov rax, qword[rsp+32]
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkDown

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .checkDown
        jg .checkDown

        mov rax, qword[rsp+32]
        sub rax, [leftSub]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkDown

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkDown
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkDown:
        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .checkRight
        jg .checkRight

        mov rax, qword[rsp+32]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkRight

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkTopRight

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkTopRight

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkTopRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkTopRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .checkBottomRight

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        sub rdx, 1
        sub rcx, rdx

        cmp rcx, 0
        jl .checkBottomRight
        je .checkBottomRight

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        sub rax, [topSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .checkBottomRight

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .checkBottomRight
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.checkBottomRight:
        mov rax, qword[rsp+32]
        add rax, 1
        xor rdx, rdx
        div qword[mapDimen]
        mov rax, rdx

        cmp rax, 0
        je .noNum

        mov rcx, qword[rsp+32]
        mov rdx, qword [mapDimen]
        add rcx, rdx

        mov rdx, qword [mapSize]
        cmp rcx, rdx
        je .noNum
        jg .noNum

        mov rax, qword[rsp+32]
        sub rax, [rightSub]
        sub rax, [bottomSub]
        movzx rcx, byte[map+rax]
        cmp cl, byte[playerMap+rax]
        je .noNum

        mov [playerMap+rax], cl

        cmp rcx, 0
        jne .noNum
        mov rax, qword[rsp+40]
        add rax, 1
        mov qword[rsp+40], rax

.noNum:
        mov rax, qword[rsp+32]
        add rax, 1
        mov qword[rsp+32], rax

        cmp rax, [mapSize]
        je .end
        jg .end

        jmp .loopStart
.end:
        mov rax, qword[rsp+40]
        cmp rax, 0
        je .done

        call autoClear
.done:

        add rsp, 48
        ret


main:
        sub rsp, 48

        mov rcx, -11
        call [GetStdHandle]
        mov rcx, rax
        mov edx, 0x0007
        call [SetConsoleMode]

.playLoop:
        call clearMaps
        call clearScreen

.getInitial:
        lea rcx, [playerMap]
        call displayMap

        lea rcx, [startIns]
        call print

        lea rcx, [input]
        call readConsole

        movzx rcx, byte [input]
        movzx rdx, byte [endVal]
        cmp rcx, rdx
        je .end

        call handleInput

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        movzx rcx, word[E_KEY]
        movzx rdx, byte[input]
        cmp rdx, rcx
        je .gotInitial
        jmp .getInitial

.gotInitial:
        mov ax, [cursor]
        mov [safeSpot], rax
        call generateMap

.loopStart:
        lea rcx, [playerMap]
        call displayMap

        lea rcx, [inst]
        call print

        lea rcx, [input]
        call readConsole

        movzx rcx, byte [input]
        movzx rdx, byte [endVal]
        cmp rcx, rdx
        je .end

        call handleInput

        call checkStatus
        cmp rax, 0
        je .lost
        cmp rax, 2
        je .won

        call autoClear

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        jmp .loopStart
.lost:
        call clearScreen

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        lea rcx, [playerMap]
        call displayMap

        lea rcx, [map]
        call displayMap

        lea rcx, [lostMsg]
        call print

        lea rcx, [input]
        call readConsole
        jmp .playLoop

.won:
        call clearScreen

        xor rcx, rcx
        mov ecx, 0x00000000
        call resetConsoleCursor

        lea rcx, [playerMap]
        call displayMap

        lea rcx, [wonMsg]
        call print

        lea rcx, [input]
        call readConsole
        jmp .playLoop
.end:

        xor rcx, rcx
        call [ExitProcess]
        add rsp, 48
        ret


section '.data' data readable writeable
msg db '~Minesweeper~', 10, 0
startIns db 'Use WASD to move the cursor and use e select a spot:', 10, 0
inst db 'Use WASD to move, e to reveal, f to flag/unflag, and l to leave:', 10, 0
lostMsg db 'You Lost!', 10, 0
wonMsg db 'You Won!', 10, 0
input rb 64
W_KEY db 'w', 0
A_KEY db 'a', 0
S_KEY db 's', 0
D_KEY db 'd', 0
E_KEY db 'e', 0
F_KEY db 'f', 0

map       rb 400
playerMap db 400 dup(11)
mapDimen  dq 20
mapSize   dq 400
bombNum   dq 80

emt      db '   ', 27, '[0m', 0
num1     db 27, '[34m', ' 1 ', 27, '[0m', 0
num2     db 27, '[32m', ' 2 ', 27, '[0m', 0
num3     db 27, '[31m', ' 3 ', 27, '[0m', 0
num4     db 27, '[35m', ' 4 ', 27, '[0m', 0
num5     db 27, '[33m', ' 5 ', 27, '[0m', 0
num6     db 27, '[36m', ' 6 ', 27, '[0m', 0
num7     db 27, '[37m', ' 7 ', 27, '[0m', 0
num8     db 27, '[90m', ' 8 ', 27, '[0m', 0
flag     db 27, '[91m', '<| ', 27, '[0m', 0
bomb     db 27, '[91m', '*o ', 27, '[0m', 0
hidd     db '[ ]', 27, '[0m', 0
curs     db 27, '[103m', 0

newLine  db 10, 0
endLine  db '|', 0
topLine  db '---', 0

cursor   dw 0
safeSpot dq 0

topSub        dq 20
leftSub       dq 1
bottomSub     dq -20
rightSub      dq -1

endVal   db 'l', 0
emptyCh  db ' ', 0

section '.idata' import data readable writeable

        dd 0, 0, 0, rva kernel32_name, rva kernel32_table
        dd 0, 0, 0, 0, 0

        kernel32_table:
                GetStdHandle             dq rva _GetStdHandle
                WriteFile                dq rva _WriteFile
                ReadFile                 dq rva _ReadFile
                SetConsoleMode           dq rva _SetConsoleMode
                SetConsoleCursorPosition dq rva _SetConsoleCursorPosition
                ExitProcess              dq rva _ExitProcess
                dq 0

        kernel32_name db 'KERNEL32.DLL', 0

        _GetStdHandle               dw 0
                                    db 'GetStdHandle', 0
        _WriteFile                  dw 0
                                    db 'WriteFile', 0
        _ReadFile                   dw 0
                                    db 'ReadFile', 0
        _SetConsoleMode             dw 0
                                    db 'SetConsoleMode',  0
        _SetConsoleCursorPosition   dw 0
                                    db 'SetConsoleCursorPosition',  0
        _ExitProcess                dw 0
                                    db 'ExitProcess', 0