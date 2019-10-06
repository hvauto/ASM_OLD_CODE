;
;
;       myUPXpatcher (beta)
;       par SyntaxError
;                   ce type de soft a déjà du exister... ailleurs... ça explique le "my" :-§
;
;       Ce programme permet d'automatiser la chiante tâche que
;       le patching d'un exe UPXé représente... Il dispose
;       d'une modeste interface graphique et est d'ores et dejà
;       fonctionnel. Pourtant il y a fort à parier que de nombreux
;       bugs se cachent encore...
;
;       Limitations: (dues à la phase 'beta')
;           * détection du 'popad / jmp progentrypoint' pas fiable
;             du tout...
;           * on ne peut pas mettre une valeure egale à zero sinon...
;           * ne cherche pas à savoir si l'exe fourni est UPXé ou non
;           * ne cherche pas à savoir si l'exe fourni a déja été patché
;             (si oui le résultat est... pas beau à voir...:)
;           * ne remplace que des suites de 4 octets et veut des chaines
;             de 8 caractères en entrée... 
;           * détecte mal les conneries de l'utilisateur.
;           * le prog vous fait confiance: aucune vérif n'est faite pour
;             savoir si l'adresse précisée appartient bien au soft UPXé.
;           * testé uniquement avec la dernière version d'UPX.
;
;       Et puis merci aux membres les plus actifs de la scene francophone
;       sans qui je n'aurais jamais pu m'arreter de jouer à Q3..
;                                           merci donc pour vos tuts !!!!
; ***********************************************************************
;  myUPXpatcher source code (MASM)
;
;       Attention: Etant donné l'ultime bordélisme méthodologique de son
;                  auteur, ce source code est réservé à un public averti.
;
;       >> je vais tacher de clarifier ce bordel :o) <<
; ***********************************************************************

.386
.model flat,stdcall
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\shell32.inc
include \masm32\include\comdlg32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\shell32.lib
includelib \masm32\lib\comdlg32.lib

.data
ClassName db "DLGCLASS",0
MenuName db "MyMenu",0
DlgName db "MyDialog",0
fmt db ">> %s: %s <<",0

titre       db "myUPXpatcher beta",0
body        db "N'utilisez pas ce programme",10,
               "si vous ne savez pas pourquoi !!",10,10,
               "Son but est d'automatiser le patching",10,
               "d'un exe packé avec UPX.",10,
               "Si vous trouvez les bugs contactez-moi :o)",10,
               "ATTENTION: la détection de problèmes est",10,
               "quasi-inexistante. Utilisez à vos risques",0

infoplus    db "* Une adresse (ou valeur) fait 4 octets",10,
               "  donc 8 caractères !!",10,10,
               "* Les valeurs sont entrées à l'~endroit~",10,
               "  (pas au format Intel comme sous SoftIce)",10,
               "  et en hexadécimale",10,10,
               "* Si la liste des patches a effectuer est",10,
               "  vide, y a rien à faire ! ahemm..",10,10,10,
               "                En vous remerciant :)",0

zer         db "0",0

FilterString   db "Tous",0,"*.*",0,0
fsize       dd ?
hname       db "boyboy",0
fmap        dd ?
faddr       dd ?

haddr       dd ?
hval        dd ?
cursel      dd ?

hDlg dd ?
cdc dd ?
taille  dd 0
nser dd 0

backjmp dd ?

; patch dd 00401C65h,1b909090h,0        exemple de patchlist au format: addr1, val1, addr2, val2,..,..,addrn, valn,0
patchsz dd 0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hfile dd ?
buffer db 512 dup(?)
ofn   OPENFILENAME <>
fname db 512 dup(?)
straddr db 50 dup(?)
strval db 50 dup(?)
item db 50 dup (?)

patch dd 30 dup(?)

.const
IDC_EDIT        equ 3000
IDC_EDIT2       equ 3003
IDC_BUTTON      equ 3001
IDC_BUTTON2     equ 3004
IDC_BUTTON3     equ 3005
IDC_EXIT        equ 3002
IDM_EXIT        equ 32002
IDC_LIST1       equ 1000


.code
start:
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	invoke GetCommandLine
	mov CommandLine,eax
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,DLGWINDOWEXTRA
	push  hInst
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_WINDOW         ;BTNFACE+1
	mov   wc.lpszClassName,OFFSET ClassName

	mov   wc.hIcon,NULL
      mov   wc.hIconSm,NULL

	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax

	invoke RegisterClassEx, addr wc

      invoke MessageBox,NULL,addr body,addr titre,NULL

	invoke CreateDialogParam,hInstance,ADDR DlgName,NULL,NULL,NULL
	mov   hDlg,eax
	INVOKE ShowWindow, hDlg,SW_SHOWNORMAL
	INVOKE UpdateWindow, hDlg

	.WHILE TRUE
                INVOKE GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke IsDialogMessage, hDlg, ADDR msg
                .if eax==FALSE
                        INVOKE TranslateMessage, ADDR msg
                        INVOKE DispatchMessage, ADDR msg
                .endif
	.ENDW
	mov     eax,msg.wParam
	ret
WinMain endp

getaddr:
    mov edx, [esp+4]
    mov ecx, [esp+8]   
refais:
    mov     ax,word ptr [edx]
    test    ah,ah
    jz degag
    sub     al,30h
    sub     ah,30h
    cmp     ah,-30h
    jz      degag
    cmp     ah,10
    jb      noprob
    cmp     ah,16h
    jg      versfoutage             ; bahh c pas bo de taper n'importe koi !!!
    sub     ah,7
noprob:
    shl     al,4
    mov     bl,al
    cmp     bl,ah
    mov     [ecx], bl
    inc     ecx
    inc     edx
    inc     edx
    jmp refais
degag:    
    sub ecx,4


    mov eax,[esp+8]         ; change l'ordre du DWORD
    mov eax,[eax]
    mov ebx,eax
    xchg al,ah
    shl eax,10h
    shr ebx,10h
    xchg bl,bh
    add eax,ebx
    add ebx,[esp+8]
    mov [ebx],eax
ret

versfoutage:
    xor ecx,ecx              ; da foutage flag :)
ret

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.if uMsg==WM_CREATE



	.ELSEIF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.ELSEIF uMsg==WM_COMMAND
		mov eax,wParam
		mov edx,wParam
		shr edx,16
	          .IF ax==IDC_EDIT
                .ELSEIF ax==IDC_EDIT

                .ELSEIF ax==IDC_EDIT2
               
                .ELSEIF ax==IDC_BUTTON              ; ADD
                    invoke GetDlgItemText,hWnd,IDC_EDIT,addr straddr,50
                    test eax,eax
                    jz foutage
                    cmp eax,8
                    jnz foutage

                    invoke GetDlgItemText,hWnd,IDC_EDIT2,addr strval,50
                    test eax,eax
                    jz foutage
                    cmp eax,8
                    jnz foutage

                    invoke CharUpper,addr straddr
                    invoke CharUpper,addr strval

                    push offset haddr
                    push offset straddr
                    call getaddr
                    add esp,8
                    test ecx,ecx
                    jz foutage
                    
                    push offset hval
                    push offset strval
                    call getaddr
                    add esp,8
                    test ecx,ecx
                    jz foutage
                    
                    lea eax,patch
                    add eax,patchsz
                    mov ebx,[haddr]
                    mov dword ptr [eax],ebx
                    add eax,4
                    mov ebx,[hval]
                    mov dword ptr [eax],ebx
                    add patchsz,8

                    invoke wsprintf,addr item,addr fmt,addr straddr,addr strval

                    invoke GetDlgItem,hWnd,IDC_LIST1
                    invoke SendMessage,eax,LB_ADDSTRING,0,ADDR item
                    jmp endit
foutage:  ; de gueule...
                    invoke MessageBox,NULL,addr infoplus, addr titre,NULL
                .ELSEIF ax==IDC_BUTTON2         ; REMOVE

                    invoke GetDlgItem,hWnd,IDC_LIST1
                    invoke SendMessage,eax,LB_GETCURSEL,0,0
                    cmp eax,-1
                    jz nosel
                    push eax
                    invoke GetDlgItem,hWnd,IDC_LIST1
                    pop ebx
                    invoke SendMessage,eax,LB_DELETESTRING,ebx,0 
                    
                    imul ebx,8                ; decaler la patch liste
                    lea eax,patch
                    add eax,ebx               ; patch ptr

contb:
                    mov ecx,[eax+8]           ; ecrase les valeurs supprimées
                    test ecx,ecx
                    jz finb
                    mov dword ptr [eax],ecx
                    mov ecx,[eax+12]
                    mov dword ptr [eax+4],ecx
                    add eax,8
                    jmp contb
finb:
;                    sub eax,8
                    mov dword ptr [eax],0
                    mov dword ptr [eax+4],0
                    sub patchsz,8
nosel:                    
                .ELSEIF ax==IDC_BUTTON3         ; Go, go, go !!!
                    mov eax,[patch]
                    test eax,eax
                    jz foutage

mov ofn.lStructSize,SIZEOF ofn
	mov  ofn.lpstrFilter, OFFSET FilterString
	mov  ofn.lpstrFile, OFFSET fname
	mov  ofn.nMaxFile,512
	mov  ofn.Flags, OFN_FILEMUSTEXIST or \
                       OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                       OFN_EXPLORER or OFN_HIDEREADONLY
	invoke GetOpenFileName, ADDR ofn
	.if eax==TRUE

               invoke  CreateFileA,addr fname,\
                    GENERIC_READ+GENERIC_WRITE,\
                    FILE_SHARE_READ+FILE_SHARE_WRITE,\
                    0, OPEN_EXISTING,\
                    FILE_ATTRIBUTE_NORMAL,0
               cmp     eax,-1
               jz      fail
               mov     hfile,eax

    invoke  CreateFileMapping,hfile,0,PAGE_READWRITE,0,0,addr hname
    test    eax,eax
    jz      fail
    mov     fmap,eax
    invoke  MapViewOfFile,fmap,FILE_MAP_WRITE,0,0,0
    test    eax,eax
    jz      fail
    mov     faddr,eax          ;  On a notre pointeur !!!
    mov     edx,eax

    cmp     word ptr ds:[edx],'ZM'          ; c'est un .exe ?
    jnz     umap

    mov     eax,dword ptr ds:[edx+3ch]      
    add     eax,faddr
    cmp     word ptr ds:[eax],'EP'          ; au bon format ?
    jnz     umap

					mov eax,faddr
retry:
					cmp word ptr [eax], 0E961h
					jz found
					add eax,2
					jmp retry
found:
					xor edx,edx
					add	eax,6
rezer:
					mov ebx,[eax+edx]
					test ebx,ebx
					jnz prout
;					mov byte ptr [eax+edx],90h
					inc edx
					cmp edx,100h
					jng	rezer
prout:
					sub eax,4
					mov ebx, [eax]
					sub ebx,eax
                              mov [backjmp],ebx
                              
					sub eax,2
					lea ecx,patch
lordagain:
					mov byte ptr [eax], 0B8h
					inc eax
					mov ebx,[ecx]
					mov dword ptr [eax],ebx
					add ecx,4
					add eax,4
					mov word ptr [eax],00C7h
					add eax,2
					mov ebx, [ecx]
					mov dword ptr [eax],ebx
					add ecx,4
					add eax,4
					mov ebx,[ecx]
					test ebx,ebx
					jnz lordagain
					mov byte ptr [eax],61h
                              inc eax

                              mov byte ptr [eax],0e9h   ; 0bbh
                              add eax,1
                              mov ebx, [backjmp]
                              add ebx,eax
                              mov [eax], ebx

degage:

    invoke UnmapViewOfFile,faddr
    invoke CloseHandle,hfile
    jmp endit
umap:
    invoke UnmapViewOfFile,faddr
    invoke CloseHandle,hfile
    jmp endit
fail:
    invoke CloseHandle,hfile
endit:
                .ENDIF
                jmp endproc
		.ENDIF
      .ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.ENDIF
endproc:
	xor    eax,eax
	ret
WndProc endp
end start
