%ifndef ARCHIVE_S
%define ARCHIVE_S

;
; ============================================================================
; File        : include/archive.s
; Project     : utasm
; Description : Unix Archive (.a) format definitions and constants.
;                Used for reading static libraries.
; ============================================================================
;


; ---- Archive Magic -----------------------
%define AR_MAG             "!<arch>\n"
%define AR_MAG_LEN         8
%define AR_HDR_MAG         "`\n"

; ---- Header Field Offsets (ASCII) --------
%define AR_HDR_SIZE        60

struc ARHDR
    field name,  16     ; Name (ends with '/')
    field date,  12     ; Timestamp
    field uid,   6      ; UID
    field gid,   6      ; GID
    field mode,  8      ; Mode (octal)
    field size,  10     ; Size (bytes)
    field fmag,  2      ; End of header marker ("` \n")
endstruc

; ---- Special Member Names ----------------
%define AR_SYM_TABLE       "/"     ; System V symbol table
%define AR_LONG_NAMES      ";"    ; Long filename table

%endif
