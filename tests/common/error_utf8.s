// ============================================================================
// TEST: tests/common/error_utf8.s
// Suite: Common Lexer Error
// Purpose: Verify detection of malformed UTF-8 sequences.
// Expected: EXIT_ERROR (Malformed UTF-8).
// ============================================================================

[SECTION .text]
    // Invalid 2-byte sequence (missing second byte)
    db 0xC2, 0x20
    
    // Invalid 3-byte sequence (missing second/third byte)
    db 0xE2, 0x20, 0x20
    
    // Invalid 4-byte sequence
    db 0xF0, 0x20, 0x20, 0x20
