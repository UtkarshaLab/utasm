/*
 ============================================================================
 File        : include/syscall.s
 Project     : utasm
 Version     : 0.1.0
 Description : Standard System Call Numbers (AMD64).
 ============================================================================
*/

%def SYS_READ               0
%def SYS_WRITE              1
%def SYS_OPEN               2
%def SYS_CLOSE              3
%def SYS_STAT               4
%def SYS_FSTAT              5
%def SYS_LSEEK              8
%def SYS_MMAP               9
%def SYS_MPROTECT           10
%def SYS_MUNMAP             11
%def SYS_BRK                12
%def SYS_RT_SIGACTION       13
%def SYS_RT_SIGPROCMASK     14
%def SYS_IOCTL              16
%def SYS_PREAD64            17
%def SYS_PWRITE64           18
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
