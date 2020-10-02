.386P
.MODEL FLAT, STDCALL

extrn ExitProcess      :PROC
extrn MessageBoxA      :PROC

.data

idt     df 0
int1    dq 0
int3    dq 0

mbcap     db 0
mbtxt     db "Softice is Hidden! Click OK",0
mbcapNT   db "Arrgh!",0
mbtxtNT   db "Are you stupid?",0
mbcap10h  db "Arrgh!",0
mbtxt10h  db "Softice is already hidden, or not running",0

.code

main:
    mov ax,ds
    test al, 4
    je exitNT     ;) detect winNT/2k ??? ??

    sidt fword ptr [idt]
    mov     eax, dword ptr [idt+2]
    lea ebx, [eax+8]    ;address of int1 handler
    lea ecx, [eax+8*3]  ;address if int3 handler
    
    cli    
    mov esi,ebx     ; save int1
    lea edi, int1
    movsd
    movsd
    mov esi, ecx    ; save int3
    movsd
    movsd


    mov eax, dword ptr [int1+4]
    mov ax, word ptr [int1]
    mov edx, dword ptr [int3+4]
    mov dx, word ptr [int3]

    push edx
    sub edx,eax ; little check before we seriously screw up
    cmp dl,10h  ; dl==10h == winice isnt here? or already patched?
    je  exit10h
    pop edx
    

    mov edi, dword ptr [idt+2]
    add edi, 0b00h  ; gonna be horrid to your PC . 
                    ; and stamp two jumps into your IDT
    
    lea esi, [edi+5]
    mov byte ptr [edi],0e9h    
    sub eax, esi   
    mov dword ptr [edi+1],eax

    mov byte ptr [edi+10h],0e9h
    lea esi, [edi+15h]
    sub edx, esi
    mov dword ptr [edi+11h],edx
    ; maybe edi points to jmp int1
    ; & edi+10h points to jmp int3


    mov eax, edi    ; eax==newint1 , edx==newint3 (10h bytes apart..)
    lea edx, [eax+10h]

    cli             ;? dunno how often im supposed to use this
    mov [ebx], ax   ; stamp new int handler into idt
    shr eax,10h
    mov [ebx+6],ax
   
    mov [ecx],dx
    shr edx,10h
    mov [ecx+6],dx
    pushad
cheater:    
    call MessageBoxA,0,offset mbtxt, offset mbcap, 0
    popad
    
    jmp exit
    
    cli
    lea esi, int1   ; restore old int1/3 handlers
    mov edi, ebx    
    movsd
    movsd
    mov edi,ecx
    movsd
    movsd
    
exit:
    call ExitProcess, 0

exitNT:
    call MessageBoxA,0,offset mbtxtNT, offset mbcapNT, 0
    jmp exit
exit10h:
    call MessageBoxA,0,offset mbtxt10h, offset mbcap10h, 0
    jmp exit
end main
