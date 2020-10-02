push 0xffffffffffffffff
push 0x494140      ; '@AI'
mov eax, dword fs:[0]
push eax
sub esp, 0x474
mov eax, dword [0x4c730c]
xor eax, ebp
mov dword [var_10h], eax
push ebx
push esi
push edi
push eax
lea eax, [var_ch]
mov dword fs:[0], eax
mov eax, dword [arg_10h]
mov ebx, dword [arg_8h]
push 0x118         ; 280 ; int32_t arg_ch
mov dword [var_42ch], eax
lea eax, [var_168h]
push 0             ; int32_t arg_8h
push eax           ; int32_t arg_4h
mov dword [hInstance], ebx
call fcn.00471f00
add esp, 0xc
mov dword [lpVersionInformation], 0x11c ; 284
lea eax, [lpVersionInformation]
push eax           ; LPOSVERSIONINFOW lpVersionInformation
call dword [GetVersionExW] ; 0x49736c ; BOOL GetVersionExW(LPOSVERSIONINFOW lpVersionInformation)
lea eax, [phkResult]
push eax           ; PHKEY phkResult
push 1             ; 1 ; REGSAM samDesired
push 0             ; DWORD ulOptions
push 0x4af5d0      ; LPCWSTR lpSubKey
push reloc.WS2_32.dll_bind ; reloc.OLEAUT32.dll_SysReAllocString
                   ; 0x80000002 ; HKEY hKey
call dword [RegOpenKeyExW] ; 0x497054 ; LSTATUS RegOpenKeyExW(HKEY hKey, LPCWSTR lpSubKey, DWORD ulOptions, REGSAM samDesired, PHKEY phkResult)
test eax, eax
jne 0x4606ba
