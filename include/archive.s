/*
 ============================================================================
 File        : include/archive.s
 Project     : utasm
 Description : Unix Archive (.a) format definitions and constants.
               Used for reading static libraries.
 ============================================================================
*/

%ifndef ARCHIVE_S
%def ARCHIVE_S

// ---- Archive Magic -----------------------
%def AR_MAG             "!<arch>\n"
%def AR_MAG_LEN         8
%def AR_HDR_MAG         "`\n"

// ---- Header Field Offsets (ASCII) --------
%def AR_HDR_SIZE        60

struc ARHDR
    field name,  16     // Name (ends with '/')
    field date,  12     // Timestamp
    field uid,   6      // UID
    field gid,   6      // GID
    field mode,  8      // Mode (octal)
    field size,  10     // Size (bytes)
    field fmag,  2      // End of header marker ("` \n")
endstruc

// ---- Special Member Names ----------------
%def AR_SYM_TABLE       "/"     // System V symbol table
%def AR_LONG_NAMES      "//"    // Long filename table

%endif
