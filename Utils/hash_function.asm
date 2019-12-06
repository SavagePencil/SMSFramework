.IFNDEF __HASH_FUNCTION_ASM__
.DEFINE __HASH_FUNCTION_ASM__

.SECTION "Pearson Hash Lookup Table - Ruby" ALIGN 256 FREE
; Pearson lookup hash table as used by Ruby module "PearsonHashing"
; https://www.rubydoc.info/gems/pearson-hashing/PearsonHashing

Ruby_PearsonHashBegin:
    .db 49, 118,  63, 252,  13, 155, 114, 130, 137,  40, 210,  62, 219, 246, 136, 221
    .db 174, 106,  37, 227, 166,  25, 139,  19, 204, 212,  64, 176,  70,  11, 170,  58
    .db 146,  24, 123,  77, 184, 248, 108, 251,  43, 171,  12, 141, 126,  41,  95, 142
    .db 167,  46, 178, 235,  30,  75,  45, 208, 110, 230, 226,  50,  32, 112, 156, 180
    .db 205,  68, 202, 203,  82,   7, 247, 217, 223,  71, 116,  76,   6,  31, 194, 183
    .db  15, 102,  97, 215, 234, 240,  53, 119,  52,  47, 179,  99, 199,   8, 101,  35
    .db  65, 132, 154, 239, 148,  51, 216,  74,  93, 192,  42,  86, 165, 113,  89,  48
    .db 100, 195,  29, 211, 169,  38,  57, 214, 127, 117,  59,  39, 209,  88,   1, 134
    .db  92, 163,   0,  66, 237,  22, 164, 200,  85,   9, 190, 129, 111, 172, 231,  14
    .db 181, 206, 128,  23, 187,  73, 149, 193, 241, 236, 197, 159,  55, 125, 196,  60
    .db 161, 238, 245,  94,  87, 157, 122, 158, 115, 207,  17,  20, 145, 232, 107,  16
    .db  21, 185,  33, 225, 175, 253,  81, 182,  67, 243,  69, 220, 153,   5, 143,   3
    .db  26, 213, 147, 222, 105, 188, 229, 191,  72, 177, 250, 135, 152, 121, 218,  44
    .db 120, 140, 138,  28,  84, 186, 198, 131,  54,   2,  56,  78, 173, 151,  83,  27
    .db 255, 144, 249, 189, 104,   4, 168,  98, 162, 150, 254, 242, 109,  34, 133, 224
    .db 228,  79, 103, 201, 160,  90,  18,  61,  10, 233,  91,  80, 124,  96, 244,  36
Ruby_PearsonHashEnd:
.ENDS

.SECTION "Pearson Hash Lookup Table - Pearson Paper" ALIGN 256 FREE
; From the original paper by Peter Pearson
Pearson_PearsonHashBegin:
    .db 1,87,49,12,176,178,102,166,121,193,6,84,249,230,44,163
    .db 14,197,213,181,161,85,218,80,64,239,24,226,236,142,38,200
    .db 110,177,104,103,141,253,255,50,77,101,81,18,45,96,31,222
    .db 25,107,190,70,86,237,240,34,72,242,20,214,244,227,149,235
    .db 97,234,57,22,60,250,82,175,208,5,127,199,111,62,135,248
    .db 174,169,211,58,66,154,106,195,245,171,17,187,182,179,0,243
    .db 132,56,148,75,128,133,158,100,130,126,91,13,153,246,216,219
    .db 119,68,223,78,83,88,201,99,122,11,92,32,136,114,52,10
    .db 138,30,48,183,156,35,61,26,143,74,251,94,129,162,63,152
    .db 170,7,115,167,241,206,3,150,55,59,151,220,90,53,23,131
    .db 125,173,15,238,79,95,89,16,105,137,225,224,217,160,37,123
    .db 118,73,2,157,46,116,9,145,134,228,207,212,202,215,69,229
    .db 27,188,67,124,168,252,42,4,29,108,21,247,19,205,39,203
    .db 233,40,186,147,198,192,155,33,164,191,98,204,165,180,117,76
    .db 140,36,210,172,41,54,159,8,185,232,113,196,231,47,146,120
    .db 51,65,28,144,254,221,93,189,194,139,112,43,71,109,184,209
Pearson_PearsonHashEnd:
.ENDS

.SECTION "Pearson Hash Lookup Table - RFC 3074" ALIGN 256 FREE
; From RFC 3074, a Load Balancing Algorithm
; https://tools.ietf.org/html/rfc3074
Pearson_RFC3074Begin:
    .db 251, 175, 119, 215, 81, 14, 79, 191, 103, 49, 181, 143, 186, 157,  0
    .db 232, 31, 32, 55, 60, 152, 58, 17, 237, 174, 70, 160, 144, 220, 90, 57
    .db 223, 59,  3, 18, 140, 111, 166, 203, 196, 134, 243, 124, 95, 222, 179
    .db 197, 65, 180, 48, 36, 15, 107, 46, 233, 130, 165, 30, 123, 161, 209, 23
    .db 97, 16, 40, 91, 219, 61, 100, 10, 210, 109, 250, 127, 22, 138, 29, 108
    .db 244, 67, 207,  9, 178, 204, 74, 98, 126, 249, 167, 116, 34, 77, 193
    .db 200, 121,  5, 20, 113, 71, 35, 128, 13, 182, 94, 25, 226, 227, 199, 75
    .db 27, 41, 245, 230, 224, 43, 225, 177, 26, 155, 150, 212, 142, 218, 115
    .db 241, 73, 88, 105, 39, 114, 62, 255, 192, 201, 145, 214, 168, 158, 221
    .db 148, 154, 122, 12, 84, 82, 163, 44, 139, 228, 236, 205, 242, 217, 11
    .db 187, 146, 159, 64, 86, 239, 195, 42, 106, 198, 118, 112, 184, 172, 87
    .db 2, 173, 117, 176, 229, 247, 253, 137, 185, 99, 164, 102, 147, 45, 66
    .db 231, 52, 141, 211, 194, 206, 246, 238, 56, 110, 78, 248, 63, 240, 189
    .db 93, 92, 51, 53, 183, 19, 171, 72, 50, 33, 104, 101, 69, 8, 252, 83, 120
    .db 76, 135, 85, 54, 202, 125, 188, 213, 96, 235, 136, 208, 162, 129, 190
    .db 132, 156, 38, 47, 1, 7, 254, 24, 4, 216, 131, 89, 21, 28, 133, 37, 153
    .db 149, 80, 170, 68, 6, 169, 234, 151
Pearson_RFC3074End:
.ENDS

.SECTION "Pearson Hash Lookup Table - Wikipedia" ALIGN 256 FREE
; From Wikipedia.
; https://en.m.wikipedia.org/wiki/Pearson_hashing
Pearson_WikipediaBegin:
    .db 98,  6, 85,150, 36, 23,112,164,135,207,169,  5, 26, 64,165,219
    .db 61, 20, 68, 89,130, 63, 52,102, 24,229,132,245, 80,216,195,115
    .db 90,168,156,203,177,120,  2,190,188,  7,100,185,174,243,162, 10
    .db 237, 18,253,225,  8,208,172,244,255,126,101, 79,145,235,228,121
    .db 123,251, 67,250,161,  0,107, 97,241,111,181, 82,249, 33, 69, 55
    .db 59,153, 29,  9,213,167, 84, 93, 30, 46, 94, 75,151,114, 73,222
    .db 197, 96,210, 45, 16,227,248,202, 51,152,252,125, 81,206,215,186
    .db 39,158,178,187,131,136,  1, 49, 50, 17,141, 91, 47,129, 60, 99
    .db 154, 35, 86,171,105, 34, 38,200,147, 58, 77,118,173,246, 76,254
    .db 133,232,196,144,198,124, 53,  4,108, 74,223,234,134,230,157,139
    .db 189,205,199,128,176, 19,211,236,127,192,231, 70,233, 88,146, 44
    .db 183,201, 22, 83, 13,214,116,109,159, 32, 95,226,140,220, 57, 12
    .db 221, 31,209,182,143, 92,149,184,148, 62,113, 65, 37, 27,106,166
    .db 3, 14,204, 72, 21, 41, 56, 66, 28,193, 40,217, 25, 54,179,117
    .db 238, 87,240,155,180,170,242,212,191,163, 78,218,137,194,175,110
    .db 43,119,224, 71,122,142, 42,160,104, 48,247,103, 15, 11,138,239
Pearson_WikipediaEnd:
.ENDS

.SECTION "Calc Pearson Hash 8-bit - Table Aligned" FREE
;==============================================================================
; CalcPearsonHash_8bit
; Calculates an 8-bit hash value from a sequence of bytes by referencing
; a lookup table.  The table is aligned on a 256-byte memory boundary.
; INPUTS:  HL: Pointer to byte sequence
;          DE: Pointer to table at 256-byte boundary
;           B: #/bytes in sequence
; OUTPUTS:  A: Hash value
;          HL: Points to byte after the end of the sequence
;           B: 0
; Destroys DE
;==============================================================================
CalcPearsonHash_8bit:
    xor a
-:
    xor (hl)    ; Get current hash XOR'd with next byte in the sequence.
    ld  e, a
    ld  a, (de)
    inc hl      ; Next byte in sequence
    djnz -
    ret

.ENDS

.SECTION "Calc Pearson Hash 16-bit - Table Aligned" FREE
;==============================================================================
; CalcPearsonHash_16bit
; Calculates two 8-bit hash values from a sequence of bytes by referencing
; a lookup table.  The table is aligned on a 256-byte memory boundary.
; INPUTS:  HL: Pointer to byte sequence
;          DE: Pointer to table at 256-byte boundary
;           B: #/bytes in sequence
; OUTPUTS:  A: 1st hash value (same as calling the 8-bit variant)
;           C: 2nd hash value (same as getting the value from 1st byte of seq.)
;          HL: Points to byte after the end of the sequence
;           B: 0
; Destroys DE
;==============================================================================
CalcPearsonHash_16bit:
    xor a
    xor (hl)
    ld  e, a
    ld  a, (de)
    ld  c, a    ; Store this in C
    jp  CalcPearsonHash_8bit

.ENDS

.ENDIF  ;__HASH_FUNCTION_ASM__