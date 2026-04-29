// ============================================================================
// TEST: tests/common/error_macro_recursion.s
// Suite: Common Preprocessor Error
// Purpose: Verify detection of infinite macro recursion.
// Expected: EXIT_MACRO_RECURSION.
// ============================================================================

%macro infinite 0
    infinite
%endmacro

[SECTION .text]
    infinite
