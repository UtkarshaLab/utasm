/*
 ============================================================================
 File        : include/syscall.s
 Project     : utasm
 Version     : 0.1.0
 Description : Complete Linux AMD64 system call numbers (syscall table).
               Covers all entries in the Linux x86_64 syscall ABI up to
               kernel 6.x. Usage: mov rax, SYS_xxx  then  syscall
 ============================================================================
*/

// ============================================================================
// FILE & I/O
// ============================================================================
%def SYS_READ               0
%def SYS_WRITE              1
%def SYS_OPEN               2
%def SYS_CLOSE              3
%def SYS_STAT               4
%def SYS_FSTAT              5
%def SYS_LSTAT              6
%def SYS_POLL               7
%def SYS_LSEEK              8
%def SYS_MMAP               9
%def SYS_MPROTECT           10
%def SYS_MUNMAP             11
%def SYS_BRK                12
%def SYS_RT_SIGACTION       13
%def SYS_RT_SIGPROCMASK     14
%def SYS_RT_SIGRETURN       15
%def SYS_IOCTL              16
%def SYS_PREAD64            17
%def SYS_PWRITE64           18
%def SYS_READV              19
%def SYS_WRITEV             20
%def SYS_ACCESS             21
%def SYS_PIPE               22
%def SYS_SELECT             23
%def SYS_SCHED_YIELD        24
%def SYS_MREMAP             25
%def SYS_MSYNC              26
%def SYS_MINCORE            27
%def SYS_MADVISE            28
%def SYS_SHMGET             29
%def SYS_SHMAT              30
%def SYS_SHMCTL             31
%def SYS_DUP                32
%def SYS_DUP2               33
%def SYS_PAUSE              34
%def SYS_NANOSLEEP          35
%def SYS_GETITIMER          36
%def SYS_ALARM              37
%def SYS_SETITIMER          38
%def SYS_GETPID             39
%def SYS_SENDFILE           40
%def SYS_SOCKET             41
%def SYS_CONNECT            42
%def SYS_ACCEPT             43
%def SYS_SENDTO             44
%def SYS_RECVFROM           45
%def SYS_SENDMSG            46
%def SYS_RECVMSG            47
%def SYS_SHUTDOWN           48
%def SYS_BIND               49
%def SYS_LISTEN             50
%def SYS_GETSOCKNAME        51
%def SYS_GETPEERNAME        52
%def SYS_SOCKETPAIR         53
%def SYS_SETSOCKOPT         54
%def SYS_GETSOCKOPT         55
%def SYS_CLONE              56
%def SYS_FORK               57
%def SYS_VFORK              58
%def SYS_EXECVE             59
%def SYS_EXIT               60
%def SYS_WAIT4              61
%def SYS_KILL               62
%def SYS_UNAME              63

// ============================================================================
// FILE SYSTEM
// ============================================================================
%def SYS_SEMGET             64
%def SYS_SEMOP              65
%def SYS_SEMCTL             66
%def SYS_SHMDT              67
%def SYS_MSGGET             68
%def SYS_MSGSND             69
%def SYS_MSGRCV             70
%def SYS_MSGCTL             71
%def SYS_FCNTL              72
%def SYS_FLOCK              73
%def SYS_FSYNC              74
%def SYS_FDATASYNC          75
%def SYS_TRUNCATE           76
%def SYS_FTRUNCATE          77
%def SYS_GETDENTS           78
%def SYS_GETCWD             79
%def SYS_CHDIR              80
%def SYS_FCHDIR             81
%def SYS_RENAME             82
%def SYS_MKDIR              83
%def SYS_RMDIR              84
%def SYS_CREAT              85
%def SYS_LINK               86
%def SYS_UNLINK             87
%def SYS_SYMLINK            88
%def SYS_READLINK           89
%def SYS_CHMOD              90
%def SYS_FCHMOD             91
%def SYS_CHOWN              92
%def SYS_FCHOWN             93
%def SYS_LCHOWN             94
%def SYS_UMASK              95
%def SYS_GETTIMEOFDAY       96
%def SYS_GETRLIMIT          97
%def SYS_GETRUSAGE          98
%def SYS_SYSINFO            99
%def SYS_TIMES              100
%def SYS_PTRACE             101
%def SYS_GETUID             102
%def SYS_SYSLOG             103
%def SYS_GETGID             104
%def SYS_SETUID             105
%def SYS_SETGID             106
%def SYS_GETEUID            107
%def SYS_GETEGID            108
%def SYS_SETPGID            109
%def SYS_GETPPID            110
%def SYS_GETPGRP            111
%def SYS_SETSID             112
%def SYS_SETREUID           113
%def SYS_SETREGID           114
%def SYS_GETGROUPS          115
%def SYS_SETGROUPS          116
%def SYS_SETRESUID          117
%def SYS_GETRESUID          118
%def SYS_SETRESGID          119
%def SYS_GETRESGID          120
%def SYS_GETPGID            121
%def SYS_SETFSUID           122
%def SYS_SETFSGID           123
%def SYS_GETSID             124
%def SYS_CAPGET             125
%def SYS_CAPSET             126

// ============================================================================
// SIGNALS
// ============================================================================
%def SYS_RT_SIGPENDING      127
%def SYS_RT_SIGTIMEDWAIT    128
%def SYS_RT_SIGQUEUEINFO    129
%def SYS_RT_SIGSUSPEND      130
%def SYS_SIGALTSTACK        131
%def SYS_UTIME              132
%def SYS_MKNOD              133
%def SYS_USELIB             134
%def SYS_PERSONALITY        135
%def SYS_USTAT              136
%def SYS_STATFS             137
%def SYS_FSTATFS            138
%def SYS_SYSFS              139
%def SYS_GETPRIORITY        140
%def SYS_SETPRIORITY        141
%def SYS_SCHED_SETPARAM     142
%def SYS_SCHED_GETPARAM     143
%def SYS_SCHED_SETSCHEDULER 144
%def SYS_SCHED_GETSCHEDULER 145
%def SYS_SCHED_GET_PRIORITY_MAX 146
%def SYS_SCHED_GET_PRIORITY_MIN 147
%def SYS_SCHED_RR_GET_INTERVAL 148
%def SYS_MLOCK              149
%def SYS_MUNLOCK            150
%def SYS_MLOCKALL           151
%def SYS_MUNLOCKALL         152
%def SYS_VHANGUP            153
%def SYS_MODIFY_LDT         154
%def SYS_PIVOT_ROOT         155
%def SYS__SYSCTL            156
%def SYS_PRCTL              157
%def SYS_ARCH_PRCTL         158
%def SYS_ADJTIMEX           159
%def SYS_SETRLIMIT          160
%def SYS_CHROOT             161
%def SYS_SYNC               162
%def SYS_ACCT               163
%def SYS_SETTIMEOFDAY       164
%def SYS_MOUNT              165
%def SYS_UMOUNT2            166
%def SYS_SWAPON             167
%def SYS_SWAPOFF            168
%def SYS_REBOOT             169
%def SYS_SETHOSTNAME        170
%def SYS_SETDOMAINNAME      171
%def SYS_IOPL               172
%def SYS_IOPERM             173
%def SYS_CREATE_MODULE      174
%def SYS_INIT_MODULE        175
%def SYS_DELETE_MODULE      176
%def SYS_GET_KERNEL_SYMS    177
%def SYS_QUERY_MODULE       178
%def SYS_QUOTACTL           179
%def SYS_NFSSERVCTL         180
%def SYS_GETPMSG            181
%def SYS_PUTPMSG            182
%def SYS_AFS_SYSCALL        183
%def SYS_TUXCALL            184
%def SYS_SECURITY           185
%def SYS_GETTID             186
%def SYS_READAHEAD          187
%def SYS_SETXATTR           188
%def SYS_LSETXATTR          189
%def SYS_FSETXATTR          190
%def SYS_GETXATTR           191
%def SYS_LGETXATTR          192
%def SYS_FGETXATTR          193
%def SYS_LISTXATTR          194
%def SYS_LLISTXATTR         195
%def SYS_FLISTXATTR         196
%def SYS_REMOVEXATTR        197
%def SYS_LREMOVEXATTR       198
%def SYS_FREMOVEXATTR       199

// ============================================================================
// THREADING & ASYNC I/O
// ============================================================================
%def SYS_TKILL              200
%def SYS_TIME               201
%def SYS_FUTEX              202
%def SYS_SCHED_SETAFFINITY  203
%def SYS_SCHED_GETAFFINITY  204
%def SYS_SET_THREAD_AREA    205
%def SYS_IO_SETUP           206
%def SYS_IO_DESTROY         207
%def SYS_IO_GETEVENTS       208
%def SYS_IO_SUBMIT          209
%def SYS_IO_CANCEL          210
%def SYS_GET_THREAD_AREA    211
%def SYS_LOOKUP_DCOOKIE     212
%def SYS_EPOLL_CREATE       213
%def SYS_EPOLL_CTL_OLD      214
%def SYS_EPOLL_WAIT_OLD     215
%def SYS_REMAP_FILE_PAGES   216
%def SYS_GETDENTS64         217
%def SYS_SET_TID_ADDRESS    218
%def SYS_RESTART_SYSCALL    219
%def SYS_SEMTIMEDOP         220
%def SYS_FADVISE64          221
%def SYS_TIMER_CREATE       222
%def SYS_TIMER_SETTIME      223
%def SYS_TIMER_GETTIME      224
%def SYS_TIMER_GETOVERRUN   225
%def SYS_TIMER_DELETE       226
%def SYS_CLOCK_SETTIME      227
%def SYS_CLOCK_GETTIME      228
%def SYS_CLOCK_GETRES       229
%def SYS_CLOCK_NANOSLEEP    230
%def SYS_EXIT_GROUP         231
%def SYS_EPOLL_WAIT         232
%def SYS_EPOLL_CTL          233
%def SYS_TGKILL             234
%def SYS_UTIMES             235
%def SYS_VSERVER            236
%def SYS_MBIND              237
%def SYS_SET_MEMPOLICY      238
%def SYS_GET_MEMPOLICY      239
%def SYS_MQ_OPEN            240
%def SYS_MQ_UNLINK          241
%def SYS_MQ_TIMEDSEND       242
%def SYS_MQ_TIMEDRECEIVE    243
%def SYS_MQ_NOTIFY          244
%def SYS_MQ_GETSETATTR      245
%def SYS_KEXEC_LOAD         246
%def SYS_WAITID             247
%def SYS_ADD_KEY            248
%def SYS_REQUEST_KEY        249
%def SYS_KEYCTL             250
%def SYS_IOPRIO_SET         251
%def SYS_IOPRIO_GET         252
%def SYS_INOTIFY_INIT       253
%def SYS_INOTIFY_ADD_WATCH  254
%def SYS_INOTIFY_RM_WATCH   255
%def SYS_MIGRATE_PAGES      256
%def SYS_OPENAT             257
%def SYS_MKDIRAT            258
%def SYS_MKNODAT            259
%def SYS_FCHOWNAT           260
%def SYS_FUTIMESAT          261
%def SYS_NEWFSTATAT         262
%def SYS_UNLINKAT           263
%def SYS_RENAMEAT           264
%def SYS_LINKAT             265
%def SYS_SYMLINKAT          266
%def SYS_READLINKAT         267
%def SYS_FCHMODAT           268
%def SYS_FACCESSAT          269
%def SYS_PSELECT6           270
%def SYS_PPOLL              271
%def SYS_UNSHARE            272
%def SYS_SET_ROBUST_LIST    273
%def SYS_GET_ROBUST_LIST    274
%def SYS_SPLICE             275
%def SYS_TEE               276
%def SYS_SYNC_FILE_RANGE    277
%def SYS_VMSPLICE           278
%def SYS_MOVE_PAGES         279
%def SYS_UTIMENSAT          280
%def SYS_EPOLL_PWAIT        281
%def SYS_SIGNALFD           282
%def SYS_TIMERFD_CREATE     283
%def SYS_EVENTFD            284
%def SYS_FALLOCATE          285
%def SYS_TIMERFD_SETTIME    286
%def SYS_TIMERFD_GETTIME    287
%def SYS_ACCEPT4            288
%def SYS_SIGNALFD4          289
%def SYS_EVENTFD2           290
%def SYS_EPOLL_CREATE1      291
%def SYS_DUP3               292
%def SYS_PIPE2              293
%def SYS_INOTIFY_INIT1      294
%def SYS_PREADV             295
%def SYS_PWRITEV            296
%def SYS_RT_TGSIGQUEUEINFO  297
%def SYS_PERF_EVENT_OPEN    298
%def SYS_RECVMMSG           299

// ============================================================================
// MODERN KERNEL (3.x – 6.x)
// ============================================================================
%def SYS_FANOTIFY_INIT      300
%def SYS_FANOTIFY_MARK      301
%def SYS_PRLIMIT64          302
%def SYS_NAME_TO_HANDLE_AT  303
%def SYS_OPEN_BY_HANDLE_AT  304
%def SYS_CLOCK_ADJTIME      305
%def SYS_SYNCFS             306
%def SYS_SENDMMSG           307
%def SYS_SETNS              308
%def SYS_GETCPU             309
%def SYS_PROCESS_VM_READV   310
%def SYS_PROCESS_VM_WRITEV  311
%def SYS_KCMP               312
%def SYS_FINIT_MODULE       313
%def SYS_SCHED_SETATTR      314
%def SYS_SCHED_GETATTR      315
%def SYS_RENAMEAT2          316
%def SYS_SECCOMP            317
%def SYS_GETRANDOM          318
%def SYS_MEMFD_CREATE       319
%def SYS_KEXEC_FILE_LOAD    320
%def SYS_BPF                321
%def SYS_EXECVEAT           322
%def SYS_USERFAULTFD        323
%def SYS_MEMBARRIER         324
%def SYS_MLOCK2             325
%def SYS_COPY_FILE_RANGE    326
%def SYS_PREADV2            327
%def SYS_PWRITEV2           328
%def SYS_PKEY_MPROTECT      329
%def SYS_PKEY_ALLOC         330
%def SYS_PKEY_FREE          331
%def SYS_STATX              332
%def SYS_IO_PGETEVENTS      333
%def SYS_RSEQ               334

// ---- io_uring (Linux 5.1+) ----
%def SYS_IO_URING_SETUP     425
%def SYS_IO_URING_ENTER     426
%def SYS_IO_URING_REGISTER  427

// ---- Misc newer calls ----
%def SYS_OPEN_TREE          428
%def SYS_MOVE_MOUNT         429
%def SYS_FSOPEN             430
%def SYS_FSCONFIG           431
%def SYS_FSMOUNT            432
%def SYS_FSPICK             433
%def SYS_PIDFD_OPEN         434
%def SYS_CLONE3             435
%def SYS_CLOSE_RANGE        436
%def SYS_OPENAT2            437
%def SYS_PIDFD_GETFD        438
%def SYS_FACCESSAT2         439
%def SYS_PROCESS_MADVISE    440
%def SYS_EPOLL_PWAIT2       441
%def SYS_MOUNT_SETATTR      442
%def SYS_QUOTACTL_FD        443
%def SYS_LANDLOCK_CREATE_RULESET 444
%def SYS_LANDLOCK_ADD_RULE  445
%def SYS_LANDLOCK_RESTRICT_SELF 446
%def SYS_MEMFD_SECRET       447
%def SYS_PROCESS_MRELEASE   448
%def SYS_FUTEX_WAITV        449
%def SYS_SET_MEMPOLICY_HOME_NODE 450
%def SYS_CACHESTAT          451
%def SYS_FCHMODAT2          452
%def SYS_MAP_SHADOW_STACK   453
%def SYS_FUTEX2             454
%def SYS_LISTMOUNT          455
%def SYS_STATMOUNT          456

// ============================================================================
// SYSCALL HELPER MACROS
// ============================================================================
// Quick single-line invocations for common patterns.
// These are thin wrappers; arguments must already be loaded per ABI.

%macro sys0 1
    mov     rax, %1
    syscall
%endmacro

%macro sys1 2
    mov     rax, %1
    mov     rdi, %2
    syscall
%endmacro

%macro sys2 3
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    syscall
%endmacro

%macro sys3 4
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    syscall
%endmacro
