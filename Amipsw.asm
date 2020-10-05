CODE    SEGMENT 
        ORG     100h
        ASSUME  CS:CODE,DS:CODE

Start:
; <-=-> THiS ONE READS THE ENCRYPTED PASSWORD FROM CMOS <-=->        

        mov     cl,0b7h
        lea     di,Password
    Read_Password:
        mov     al,cl
        out     70h,al
        jmp     $+2
        in      al,71h
        mov     [di],al
        inc     di
        inc     cl
        cmp     cl,0b7h+7
        jnz     Read_Password

; <-=-> NOW, WE HAVE TO DECRYPT CHAR BY CHAR <-=->        
        
        lea     di,Password
        and     byte ptr [di],0f0h   
        inc     di
    Decrypt_Next:
        cmp     di,Offset Password+7
        jnl     Completed
        cmp     byte ptr [di],0 
        jz      Completed
        xor     cl,cl                   
        mov     ch,byte ptr [di-1]
    Decrypt:
        inc     cl
        mov     ah,ch
        xor     dx,dx
        test    ah,10000000b
        jz      NotSet7
        inc     dh
      NotSet7:
        test    ah,01000000b
        jz      NotSet6
        inc     dh
      NotSet6:
        test    ah,00000010b
        jz      NotSet2
        inc     dh
      NotSet2:
        test    ah,00000001b
        jz      NotSet1
        inc     dh
      NotSet1:
        add     dl,2
        cmp     dl,dh
        jl      NotSet1
        sub     dl,dh
        shr     ch,1
        cmp     dl,1
        jnz     $+5
        add     ch,80h
        cmp     ch,byte ptr [di]
        jnz     Decrypt

; <-=-> AND FiNALLY, WE HAVE TO OUTPUT OUR DECRYPTED CHAR <-=->        
        
        mov     ah,2
        mov     dl,cl
        int     21h

        inc     di
        jmp     Decrypt_Next
      
; <-=-> THAT'S ALL? WELL, THAN LET'S QUiT DiZ SH**! :-) <-=->      
      
    Completed:
        mov     ax,4c00h
        int     21h

Password        DB 6 DUP (?)

