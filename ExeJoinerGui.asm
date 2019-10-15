; GUI for ExeJoiner

.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include \masm32\include\comdlg32.inc
includelib \masm32\lib\comdlg32.lib
include \masm32\include\shell32.inc
includelib \masm32\lib\shell32.lib

include \masm32\include\windows.inc
include structs.inc

.const
IDD_DLG         equ 101
ID_OK           equ 1000
ID_CANCEL       equ 1001
ID_FIRSTFILE    equ 1002
ID_SECONDFILE   equ 1004
ID_SELFIRST     equ 1005
ID_SELSECOND    equ 1006
ID_SELICON      equ 1007
ID_ICONPATH     equ 1008
ID_ICONIMAGE    equ 5000
ID_MAINICON     equ 6000

LOADERSIZE      equ 1000h
LOADERICONOFF   equ 0CA0h
DATASIZE        equ 010h
GOODICONSIZE    equ 766
ICONDATASIZE    equ 02E8h
ICONDATAOFFSET  equ 016h

szOfnTitle1    db "Choose the first file...",0
szOfnTitle2    db "Choose the second file...",0
szOfnTitleIcon db "Choose an icon file...",0
szOfnSave      db "Save merged files to...",0
szOfnFilter    db "ExE files",0,"*.exe",0,"All files",0,"*.*",0,0
szOfnIconFil   db "Ico files",0,"*.ico",0,0
szMerged       db "Merged.exe",0
szOfnInitDir   db ".\",0

szMissing      db "Please choose the 2 files !",0
szIOError      db "File I/O-Error !",0
szCreateError  db "Couldn't create file :(",0
szBadSize      db "File with a filesize of 0 aren't allowed !",0
szMapError     db "Error while mapping file !",0
szNoMem        db "Not enough memory !",0
szBadIcon      db "Error while grabbing Icon :(",0
szBadIconSize  db "This Icon is not supported !",10,13
               db "Only icon files with a filesize of 766 bytes are supported.",10,13
               db "(32 x 32 pixel and 16 colors)",0
szNoIcon       db "Icon file not found !",10,13
 	       db "The standard icon will be pasted !",0
szNoLoader     db "Couldn't find my loader image :(",0 	 
szDone         db "Done !",0
szSmile        db ":D",0
szError        db "Error",0

szLoaderName   db "DATA_LOADER",0
szLoaderType   db "ID_LOADER",0


.data
ofn            OPENFILENAME <>
sMergeInfo     Infos <>
sRect          RECT <>
sPoint         POINT <>
cFirstFile     db MAX_PATH dup (0)
cSecondFile    db MAX_PATH dup (0)
cNewFilePath   db MAX_PATH dup (0)
cIconPath      db MAX_PATH dup (0)
hInst          dd 0
hDlg_          dd 0
hNewFile       dd 0
dwBytesWritten dd 0
dwBytesRead    dd 0
hMap           dd 0
pMap           dd 0
hIconFile      dd 0
hIcon          dd 0


.code
main:	invoke GetModuleHandle,NULL
	mov [hInst],eax

	; initialize the ofn struct
	mov ofn.lStructSize, sizeof ofn
	mov eax,OFN_PATHMUSTEXIST + OFN_FILEMUSTEXIST + OFN_HIDEREADONLY
	mov ofn.Flags,eax
	mov ofn.lpstrInitialDir,offset szOfnInitDir
	mov ofn.nMaxFile,MAX_PATH
		
	; create a dialogbox
	mov ebx,offset DlgProc
	invoke DialogBoxParam,[hInst],IDD_DLG,0,ebx,0
Exit:
	invoke ExitProcess,eax

; Dialog procedure
DlgProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	pushad
	.IF uMsg == WM_CLOSE
	    invoke DestroyIcon,[hIcon]
	    invoke EndDialog,hDlg,0
	.ELSEIF uMsg == WM_INITDIALOG
            mov ebx,hDlg
            mov ofn.hWndOwner,ebx		
            mov [hDlg_],ebx
            ; set the standard icon
            invoke LoadIcon,[hInst],ID_MAINICON
            mov [hIcon],eax
            invoke SendDlgItemMessageA,[hDlg],ID_ICONIMAGE,STM_SETICON,eax,0
	.ELSEIF uMsg == WM_COMMAND
            mov eax,wParam
            .IF ax == ID_OK
		call ProcessMerge
	    .ELSEIF ax == ID_CANCEL
                invoke SendMessage,hDlg,WM_CLOSE,NULL,NULL
            .ELSEIF ax == ID_SELFIRST
            	mov ofn.lpstrFilter,offset szOfnFilter
        	mov ofn.lpstrTitle,offset szOfnTitle1
            	mov ofn.lpstrFile,offset cFirstFile
                invoke GetOpenFileNameA,offset ofn
                cmp eax,FALSE
                jz @@ExitDlgProc
                ; show the selected filename
                push offset cFirstFile
                call ExtractFilename
                invoke SetDlgItemText,hDlg,ID_FIRSTFILE,eax
             .ELSEIF ax == ID_SELSECOND
             	mov ofn.lpstrFilter,offset szOfnFilter
        	mov ofn.lpstrTitle,offset szOfnTitle2
                mov ofn.lpstrFile,offset cSecondFile
                invoke GetOpenFileNameA,offset ofn
                cmp eax,FALSE
                jz @@ExitDlgProc
                ; show the selected filename
                push offset cSecondFile
                call ExtractFilename
                invoke SetDlgItemText,hDlg,ID_SECONDFILE,eax
            .ELSEIF ax == ID_SELICON
            	mov ofn.lpstrFilter,offset szOfnIconFil
            	mov [ofn].lpstrTitle,offset szOfnTitleIcon
                mov [ofn].lpstrFile,offset cIconPath
                invoke GetOpenFileNameA,offset ofn
                cmp eax,FALSE
                jz @@ExitDlgProc
                call DoIconShowStuff
                jmp @@ExitDlgProc
	    .ENDIF
	.ENDIF
@@ExitDlgProc:
	popad
	xor eax,eax
	ret
DlgProc endp

; does the same as it's called
ExtractFilename proc szPath:DWORD
	invoke lstrlen,szPath
	mov ebx,szPath
	add ebx,eax
	.REPEAT
	   dec ebx
	.UNTIL byte ptr [ebx] == '\'
	inc ebx
	mov eax,ebx
	ret
ExtractFilename endp

; does the main work
ProcessMerge proc
	; check if 2 files were selected
	mov eax,offset cFirstFile
	cmp byte ptr [eax],0
	jz @@DataMissing
	mov eax,offset cSecondFile
	cmp byte ptr [eax],0
	jz @@DataMissing
	
	; get some infos about the files
	; process the first file
	invoke CreateFileA,offset cFirstFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	cmp eax,INVALID_HANDLE_VALUE
	jz @@FileIOError
	mov [sMergeInfo].hFile1,eax
	invoke GetFileSize,[sMergeInfo.hFile1],0
	.IF eax==0
	   invoke CloseHandle,[sMergeInfo].hFile1
	   jz @@BadSize
	.ENDIF
	mov [sMergeInfo].dwFsize1,eax
	
	; process the second file
	invoke CreateFileA,offset cSecondFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.IF eax==INVALID_HANDLE_VALUE
	   invoke CloseHandle,[sMergeInfo.hFile1]
	   jz @@FileIOError
	.ENDIF
	mov [sMergeInfo].hFile2,eax
	invoke GetFileSize,[sMergeInfo].hFile2,0
	.IF eax==0
	   invoke CloseHandle,[sMergeInfo.hFile1]
	   invoke CloseHandle,[sMergeInfo.hFile2]
	   jz @@BadSize
	.ENDIF	
	mov [sMergeInfo].dwFsize2,eax
	
	; Merge the files with our loader
	mov [ofn].lpstrFile,offset cNewFilePath
	mov [ofn].lpstrTitle,offset szOfnSave
	invoke lstrcpy,offset cNewFilePath,offset szMerged
	invoke GetSaveFileName,offset ofn
	cmp eax,0
	jz @@ExitProc
	; create the new file
	invoke CreateFileA,offset cNewFilePath,GENERIC_WRITE + GENERIC_READ,FILE_SHARE_WRITE + FILE_SHARE_READ,\
	                   NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.IF eax==INVALID_HANDLE_VALUE
	   invoke MessageBoxA,[hDlg_],offset szCreateError,offset szError,MB_ICONERROR
	   jmp @@ExitProc
	.ENDIF
	mov [hNewFile],eax
	invoke FindResourceA,NULL,offset szLoaderName,offset szLoaderType   ; get a pointer to the loader image
	invoke LoadResource,0,eax
	invoke LockResource,eax
	.IF eax==0
	   invoke CloseHandle,[hNewFile]
	   invoke MessageBoxA,[hDlg_],offset szNoLoader,offset szError,MB_ICONERROR
	   jmp @@ExitProc
	.ENDIF
	invoke WriteFile,[hNewFile],eax,LOADERSIZE,offset dwBytesWritten,NULL
	
	; write the first selected file into the new one
	invoke SetFilePointer,[hNewFile],LOADERSIZE,0,FILE_BEGIN
	invoke GlobalAlloc,GMEM_ZEROINIT + GMEM_FIXED,[sMergeInfo.dwFsize1]
	.IF eax==0
	   invoke MessageBoxA,[hDlg_],offset szNoMem,offset szError,MB_ICONERROR
	   invoke CloseHandle,[hNewFile]
	   jmp @@ExitProc
	.ENDIF
	mov [pMap],eax
	invoke ReadFile,[sMergeInfo.hFile1],pMap,[sMergeInfo.dwFsize1],offset dwBytesRead,NULL
	invoke WriteFile,[hNewFile],pMap,[sMergeInfo.dwFsize1],offset dwBytesWritten,NULL
	invoke GlobalFree,pMap
	
	;write the second file into the new one
	mov ecx,LOADERSIZE
	add ecx,[sMergeInfo].dwFsize1
	invoke SetFilePointer,[hNewFile],ecx,0,FILE_BEGIN
	invoke GlobalAlloc,GMEM_ZEROINIT + GMEM_FIXED,[sMergeInfo.dwFsize2]
	.IF eax==0
	   invoke MessageBoxA,[hDlg_],offset szNoMem,offset szError,MB_ICONERROR
	   invoke CloseHandle,[hNewFile]
	   jmp @@ExitProc
	.ENDIF
	mov [pMap],eax
	invoke ReadFile,[sMergeInfo.hFile2],pMap,[sMergeInfo.dwFsize2],offset dwBytesRead,NULL
	invoke WriteFile,[hNewFile],pMap,[sMergeInfo.dwFsize2],offset dwBytesWritten,NULL
	invoke GlobalFree,pMap
	
	; make room for the split infos
	invoke GlobalAlloc,GMEM_FIXED + GMEM_ZEROINIT,[DATASIZE]
	mov [pMap],eax
	invoke WriteFile,[hNewFile],eax,[DATASIZE],offset dwBytesWritten,NULL
	invoke GlobalFree,[pMap]

	; if selected paste a new icon into the loader image
	mov eax,offset cIconPath
	.IF byte ptr [eax] != 0
	   invoke CreateFileA,offset cIconPath,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	   .IF eax == INVALID_HANDLE_VALUE
	      invoke MessageBoxA,[hDlg_],offset szNoIcon,offset szError,MB_ICONWARNING
	      jmp DONT_PASTE_ICON
	   .ENDIF
	   mov [hIconFile],eax
	   invoke GlobalAlloc,GMEM_FIXED,ICONDATASIZE
           .IF eax==0
	      invoke MessageBoxA,[hDlg_],offset szNoMem,offset szError,MB_ICONERROR
	      invoke CloseHandle,[hIconFile]
	      jmp @@ExitProc
	   .ENDIF
           mov [pMap],eax
           ; start the pasting progress
           invoke SetFilePointer,[hIconFile],ICONDATAOFFSET,0,FILE_BEGIN
           invoke ReadFile,[hIconFile],pMap,ICONDATASIZE,offset dwBytesRead,NULL
           invoke SetFilePointer,[hNewFile],LOADERICONOFF,0,FILE_BEGIN
           invoke WriteFile,[hNewFile],pMap,ICONDATASIZE,offset dwBytesWritten,NULL
           ; clean up	   
	   invoke GlobalFree,pMap
	   invoke CloseHandle,[hIconFile]
	.ENDIF
	DONT_PASTE_ICON:

	; map the file to write the split infos in it (this way is reverse order friendly :)
	invoke CreateFileMappingA,hNewFile,NULL,PAGE_READWRITE,0,0,NULL
	.IF eax==0
	   invoke MessageBoxA,hDlg_,offset szMapError,offset szError,MB_ICONERROR
	   invoke CloseHandle,hNewFile
	   jmp @@ExitProc
	.ENDIF
	mov [hMap],eax
	invoke MapViewOfFile,eax,FILE_MAP_WRITE + FILE_MAP_READ,0,0,0
	mov pMap,eax
	invoke CloseHandle,hMap
	.IF [pMap]==0
	   invoke MessageBoxA,hDlg_,offset szMapError,offset szError,MB_ICONERROR
	   invoke CloseHandle,hNewFile
	   jmp @@ExitProc
	.ENDIF

	;write the split infos
	mov eax,[pMap]
	add eax,[LOADERSIZE]
	add eax,[sMergeInfo].dwFsize1
	add eax,[sMergeInfo].dwFsize2
	mov ecx,LOADERSIZE
	mov [eax],ecx                  ; write the offset of the first file
	add eax,4
	mov ecx,[sMergeInfo].dwFsize1
	mov [eax],ecx                  ; write the size of the first file
	add eax,4
	mov ecx,LOADERSIZE
	add ecx,[sMergeInfo].dwFsize1
	mov [eax],ecx                  ; write the offset of the second file
	add eax,4
	mov ecx,[sMergeInfo].dwFsize2
	mov [eax],ecx                  ; write the size of the second file
	
	; clean up
	invoke UnmapViewOfFile,pMap
	invoke CloseHandle,hNewFile
	
	invoke MessageBoxA,[hDlg_],offset szDone,offset szSmile,MB_ICONINFORMATION

 @@ExitProc:
   	
	; clean up
	invoke CloseHandle,[sMergeInfo.hFile1]
	invoke CloseHandle,[sMergeInfo.hFile2]
	ret
 @@BadSize:
	invoke MessageBoxA,hDlg_,offset szBadSize,offset szError,MB_ICONERROR
	ret
 @@FileIOError:
	invoke MessageBoxA,hDlg_,offset szIOError,offset szError,MB_ICONERROR
	ret
 @@DataMissing:
        invoke MessageBoxA,hDlg_,offset szMissing,offset szError,MB_ICONERROR	
	ret
ProcessMerge endp

; shows a specified icon
DoIconShowStuff proc
	; check the filesize
	invoke CreateFileA,offset cIconPath,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.IF eax==INVALID_HANDLE_VALUE
           invoke MessageBoxA,[hDlg_],offset szBadIcon,offset szError,MB_ICONERROR
           jz @@ExitProc
        .ENDIF
        mov [hIconFile],eax
        invoke GetFileSize,eax,0
        .IF eax!=GOODICONSIZE
           invoke CloseHandle,[hIconFile]
           invoke MessageBoxA,[hDlg_],offset szBadIconSize,offset szError,MB_ICONERROR
           jmp @@ExitProc
        .ENDIF
        invoke CloseHandle,[hIconFile]
        
        ; get the icon handle      
        invoke DestroyIcon,[hIcon]
        invoke ExtractIcon,[hInst],offset cIconPath,0
        .IF eax==NULL
           invoke MessageBoxA,[hDlg_],offset szBadIcon,offset szError,MB_ICONERROR
           jz @@ExitProc
        .ENDIF
        mov [hIcon],eax
        invoke SendDlgItemMessageA,[hDlg_],ID_ICONIMAGE,STM_SETICON,eax,0

	; show the icon filename
        push offset cIconPath
        call ExtractFilename
        invoke SetDlgItemText,[hDlg_],ID_ICONPATH,eax
        
   @@ExitProc:
	ret
DoIconShowStuff endp

end main
