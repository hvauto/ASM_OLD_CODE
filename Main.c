#include <stdint.h>
 
int32_t main (int32_t arg_8h, int32_t arg_ch) {
    int32_t var_1ch;
    int32_t var_18h;
    int32_t var_14h;
    int32_t var_10h;
    uint32_t var_ch;
    int32_t var_8h;
    int32_t var_4h;
    fcn_0040144f ();
    SetDllDirectoryW (0x422538);
    edi = arg_8h;
    ecx = 0;
    edx = 4;
    eax = edi + 1;
    edx:eax = eax * edx;
    __asm ("seto cl");
    ecx = -ecx;
    ecx |= eax;
    eax = moz_xmalloc (ecx, 4);
    ebx = eax;
    if (ebx == 0) {
label_1:
        eax = 0x7f;
        goto label_2;
    }
    eax = 0;
    var_ch = eax;
    var_8h = eax;
    if (edi <= 0) {
        goto label_3;
    }
    ecx = arg_ch;
    eax = ebx;
    ecx -= ebx;
    var_4h = eax;
    arg_ch = ecx;
label_0:
    esi = *((ecx + eax));
    ecx = *((ecx + eax));
    edx = ecx + 2;
    do {
        ax = *(ecx);
        ecx += 2;
    } while (ax != var_ch);
    ecx -= edx;
    ecx >>= 1;
    eax = ecx * 3;
    eax++;
    eax = moz_xmalloc (eax, ecx);
    var_14h = eax;
    if (eax != 0) {
        ecx = &var_1ch;
        var_1ch = eax;
        fcn_00401706 (esi, eax);
        eax = var_18h;
        ecx = 0;
        edx = var_8h;
        edx++;
        *(eax) = cl;
        eax = var_4h;
        ecx = var_14h;
        var_8h = edx;
        *(eax) = ecx;
        ecx = 4;
        eax += ecx;
        var_4h = eax;
        if (edx >= edi) {
            goto label_4;
        }
        ecx = arg_ch;
        goto label_0;
    }
    eax = var_4h;
    ecx = 0;
    *(eax) = ecx;
    goto label_1;
label_4:
    eax = 0;
label_3:
    *((ebx + edi*4)) = eax;
    ecx = 0;
    edx = 4;
    eax = edi + 1;
    edx:eax = eax * edx;
    __asm ("seto cl");
    ecx = -ecx;
    ecx |= eax;
    eax = moz_xmalloc (ecx, 4);
    var_14h = eax;
    if (eax == 0) {
        eax = fcn_004010bc (edi, ebx);
        goto label_1;
    }
    if (edi <= 0) {
        goto label_5;
    }
    edx = ebx;
    esi = edi;
    ecx = eax;
    edx -= eax;
    edi = 4;
    do {
        eax = *((edx + ecx));
        *(ecx) = eax;
        ecx += edi;
        esi--;
    } while (esi != 0);
label_5:
    getenv (arg_8h);
    eax = _p_environ ();
    eax = fcn_004012a7 (edi, ebx, *(eax));
    esi = eax;
    free (ebx);
    fcn_004010bc (edi, var_14h);
    eax = esi;
label_2:
    return eax;
}
