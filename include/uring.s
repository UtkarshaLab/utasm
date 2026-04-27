/*
 ============================================================================
 File        : include/uring.s
 Project     : utasm
 Description : Linux io_uring architectural definitions and syscall maps.
               Used for hyper-fast, asynchronous, zero-copy file I/O operations.
 ============================================================================
*/

// ============================================================================
// SYSTEM CALLS (AMD64)
// ============================================================================
%def SYS_IO_URING_SETUP      425
%def SYS_IO_URING_ENTER      426
%def SYS_IO_URING_REGISTER   427

// ============================================================================
// OPCODES (io_uring_sqe->opcode)
// ============================================================================
%def IORING_OP_NOP           0
%def IORING_OP_READV         1
%def IORING_OP_WRITEV        2
%def IORING_OP_FSYNC         3
%def IORING_OP_READ_FIXED    4
%def IORING_OP_WRITE_FIXED   5
%def IORING_OP_POLL_ADD      6
%def IORING_OP_POLL_REMOVE   7
%def IORING_OP_SYNC_FILE_RANGE 8
%def IORING_OP_SENDMSG       9
%def IORING_OP_RECVMSG       10
%def IORING_OP_TIMEOUT       11
%def IORING_OP_TIMEOUT_REMOVE 12
%def IORING_OP_ACCEPT        13
%def IORING_OP_ASYNC_CANCEL  14
%def IORING_OP_LINK_TIMEOUT  15
%def IORING_OP_CONNECT       16
%def IORING_OP_FALLOCATE     17
%def IORING_OP_OPENAT        18
%def IORING_OP_CLOSE         19
%def IORING_OP_FILES_UPDATE  20
%def IORING_OP_STATX         21
%def IORING_OP_READ          22
%def IORING_OP_WRITE         23

// ============================================================================
// SUBMISSION QUEUE ENTRY (io_uring_sqe)
// ============================================================================
// Total Size: 64 bytes
%def URING_SQE_SIZE          64

%def SQE_OPCODE              0   // u8: opcode
%def SQE_FLAGS               1   // u8: IOSQE_ flags
%def SQE_IOPRIO              2   // u16: ioprio
%def SQE_FD                  4   // i32: file descriptor
%def SQE_OFF                 8   // u64: offset into file
%def SQE_ADDR                16  // u64: pointer to buffer or iovecs
%def SQE_LEN                 24  // u32: buffer size or number of iovecs
%def SQE_RW_FLAGS            28  // u32: rw flags (e.g., RWF_DSYNC)
%def SQE_USER_DATA           32  // u64: opaque data for completion (cqe)
%def SQE_BUF_INDEX           40  // u16: index into fixed buffers (if used)
%def SQE_PERSONALITY         42  // u16: personality index
%def SQE_SPLICE_FD_IN        44  // i32: fd_in for splice/tee
%def SQE_PAD_1               48  // padding

// ============================================================================
// COMPLETION QUEUE ENTRY (io_uring_cqe)
// ============================================================================
// Total Size: 16 bytes
%def URING_CQE_SIZE          16

%def CQE_USER_DATA           0   // u64: opaque data passed in sqe
%def CQE_RES                 8   // i32: result code for this event
%def CQE_FLAGS               12  // u32: IORING_CQE_F_* flags

// ============================================================================
// io_uring_params STRUCT
// ============================================================================
// Total Size: 120 bytes
%def URING_PARAMS_SIZE       120

%def UPAR_SQ_ENTRIES         0   // u32: sq entries
%def UPAR_CQ_ENTRIES         4   // u32: cq entries
%def UPAR_FLAGS              8   // u32: setup flags
%def UPAR_SQ_THREAD_CPU      12  // u32
%def UPAR_SQ_THREAD_IDLE     16  // u32
%def UPAR_FEATURES           20  // u32: features kernel supports
%def UPAR_WQ_FD              24  // u32

// SQ Ring Offsets
%def UPAR_SQ_OFF_HEAD        40
%def UPAR_SQ_OFF_TAIL        44
%def UPAR_SQ_OFF_RING_MASK   48
%def UPAR_SQ_OFF_RING_ENTRIES 52
%def UPAR_SQ_OFF_FLAGS       56
%def UPAR_SQ_OFF_DROPPED     60
%def UPAR_SQ_OFF_ARRAY       64

// CQ Ring Offsets
%def UPAR_CQ_OFF_HEAD        80
%def UPAR_CQ_OFF_TAIL        84
%def UPAR_CQ_OFF_RING_MASK   88
%def UPAR_CQ_OFF_RING_ENTRIES 92
%def UPAR_CQ_OFF_FLAGS       96
%def UPAR_CQ_OFF_OVERFLOW    100
%def UPAR_CQ_OFF_CQES        104

// ============================================================================
// IORING MAGIC OFFSETS (mmap offsets)
// ============================================================================
%def IORING_OFF_SQ_RING      0
%def IORING_OFF_CQ_RING      0x8000000
%def IORING_OFF_SQES         0x10000000
