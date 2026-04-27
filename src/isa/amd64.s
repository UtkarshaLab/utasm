/*
 ============================================================================
 File        : src/arch/amd64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AMD64 Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%inc "include/arch/amd64.s"

[SECTION .rodata]
align 8

global amd64_mnemonic_table
amd64_mnemonic_table:
    // Generated from user-provided intel.txt
    mnemonic_entry "aaa", 0, 1000
    mnemonic_entry "aad", 0, 1001
    mnemonic_entry "aam", 0, 1002
    mnemonic_entry "aas", 0, 1003
    mnemonic_entry "adc", 0, 1004
    mnemonic_entry "adcx", 0, 1005
    mnemonic_entry "add", 0, 1006
    mnemonic_entry "addpd", 0, 1007
    mnemonic_entry "addps", 0, 1008
    mnemonic_entry "addsd", 0, 1009
    mnemonic_entry "addss", 0, 1010
    mnemonic_entry "addsubpd", 0, 1011
    mnemonic_entry "addsubps", 0, 1012
    mnemonic_entry "adox", 0, 1013
    mnemonic_entry "aesdec", 0, 1014
    mnemonic_entry "aesdec128kl", 0, 1015
    mnemonic_entry "aesdec256kl", 0, 1016
    mnemonic_entry "aesdeclast", 0, 1017
    mnemonic_entry "aesdecwide128kl", 0, 1018
    mnemonic_entry "aesdecwide256kl", 0, 1019
    mnemonic_entry "aesenc", 0, 1020
    mnemonic_entry "aesenc128kl", 0, 1021
    mnemonic_entry "aesenc256kl", 0, 1022
    mnemonic_entry "aesenclast", 0, 1023
    mnemonic_entry "aesencwide128kl", 0, 1024
    mnemonic_entry "aesencwide256kl", 0, 1025
    mnemonic_entry "aesimc", 0, 1026
    mnemonic_entry "aeskeygenassist", 0, 1027
    mnemonic_entry "and", 0, 1028
    mnemonic_entry "andn", 0, 1029
    mnemonic_entry "andnpd", 0, 1030
    mnemonic_entry "andnps", 0, 1031
    mnemonic_entry "andpd", 0, 1032
    mnemonic_entry "andps", 0, 1033
    mnemonic_entry "arpl", 0, 1034
    mnemonic_entry "bextr", 0, 1035
    mnemonic_entry "blendpd", 0, 1036
    mnemonic_entry "blendps", 0, 1037
    mnemonic_entry "blendvpd", 0, 1038
    mnemonic_entry "blendvps", 0, 1039
    mnemonic_entry "blsi", 0, 1040
    mnemonic_entry "blsmsk", 0, 1041
    mnemonic_entry "blsr", 0, 1042
    mnemonic_entry "bndcl", 0, 1043
    mnemonic_entry "bndcn", 0, 1044
    mnemonic_entry "bndcu", 0, 1045
    mnemonic_entry "bndldx", 0, 1046
    mnemonic_entry "bndmk", 0, 1047
    mnemonic_entry "bndmov", 0, 1048
    mnemonic_entry "bndstx", 0, 1049
    mnemonic_entry "bound", 0, 1050
    mnemonic_entry "bsf", 0, 1051
    mnemonic_entry "bsr", 0, 1052
    mnemonic_entry "bswap", 0, 1053
    mnemonic_entry "bt", 0, 1054
    mnemonic_entry "btc", 0, 1055
    mnemonic_entry "btr", 0, 1056
    mnemonic_entry "bts", 0, 1057
    mnemonic_entry "bzhi", 0, 1058
    mnemonic_entry "call", 0, 1059
    mnemonic_entry "cbw", 0, 1060
    mnemonic_entry "cdq", 0, 1061
    mnemonic_entry "cdqe", 0, 1062
    mnemonic_entry "clac", 0, 1063
    mnemonic_entry "clc", 0, 1064
    mnemonic_entry "cld", 0, 1065
    mnemonic_entry "cldemote", 0, 1066
    mnemonic_entry "clflush", 0, 1067
    mnemonic_entry "clflushopt", 0, 1068
    mnemonic_entry "cli", 0, 1069
    mnemonic_entry "clrssbsy", 0, 1070
    mnemonic_entry "clts", 0, 1071
    mnemonic_entry "clui", 0, 1072
    mnemonic_entry "clwb", 0, 1073
    mnemonic_entry "cmc", 0, 1074
    mnemonic_entry "cmp", 0, 1075
    mnemonic_entry "cmppd", 0, 1076
    mnemonic_entry "cmpps", 0, 1077
    mnemonic_entry "cmps", 0, 1078
    mnemonic_entry "cmpsb", 0, 1079
    mnemonic_entry "cmpsd", 0, 1080
    mnemonic_entry "cmpsq", 0, 1081
    mnemonic_entry "cmpss", 0, 1082
    mnemonic_entry "cmpsw", 0, 1083
    mnemonic_entry "cmpxchg", 0, 1084
    mnemonic_entry "cmpxchg16b", 0, 1085
    mnemonic_entry "cmpxchg8b", 0, 1086
    mnemonic_entry "comisd", 0, 1087
    mnemonic_entry "comiss", 0, 1088
    mnemonic_entry "cpuid", 0, 1089
    mnemonic_entry "cqo", 0, 1090
    mnemonic_entry "crc32", 0, 1091
    mnemonic_entry "cvtdq2pd", 0, 1092
    mnemonic_entry "cvtdq2ps", 0, 1093
    mnemonic_entry "cvtpd2dq", 0, 1094
    mnemonic_entry "cvtpd2pi", 0, 1095
    mnemonic_entry "cvtpd2ps", 0, 1096
    mnemonic_entry "cvtpi2pd", 0, 1097
    mnemonic_entry "cvtpi2ps", 0, 1098
    mnemonic_entry "cvtps2dq", 0, 1099
    mnemonic_entry "cvtps2pd", 0, 1100
    mnemonic_entry "cvtps2pi", 0, 1101
    mnemonic_entry "cvtsd2si", 0, 1102
    mnemonic_entry "cvtsd2ss", 0, 1103
    mnemonic_entry "cvtsi2sd", 0, 1104
    mnemonic_entry "cvtsi2ss", 0, 1105
    mnemonic_entry "cvtss2sd", 0, 1106
    mnemonic_entry "cvtss2si", 0, 1107
    mnemonic_entry "cvttpd2dq", 0, 1108
    mnemonic_entry "cvttpd2pi", 0, 1109
    mnemonic_entry "cvttps2dq", 0, 1110
    mnemonic_entry "cvttps2pi", 0, 1111
    mnemonic_entry "cvttsd2si", 0, 1112
    mnemonic_entry "cvttss2si", 0, 1113
    mnemonic_entry "cwd", 0, 1114
    mnemonic_entry "cwde", 0, 1115
    mnemonic_entry "daa", 0, 1116
    mnemonic_entry "das", 0, 1117
    mnemonic_entry "dec", 0, 1118
    mnemonic_entry "div", 0, 1119
    mnemonic_entry "divpd", 0, 1120
    mnemonic_entry "divps", 0, 1121
    mnemonic_entry "divsd", 0, 1122
    mnemonic_entry "divss", 0, 1123
    mnemonic_entry "dppd", 0, 1124
    mnemonic_entry "dpps", 0, 1125
    mnemonic_entry "emms", 0, 1126
    mnemonic_entry "encls", 0, 1127
    mnemonic_entry "encls[eadd]", 0, 1128
    mnemonic_entry "encls[eaug]", 0, 1129
    mnemonic_entry "encls[eblock]", 0, 1130
    mnemonic_entry "encls[ecreate]", 0, 1131
    mnemonic_entry "encls[edbgrd]", 0, 1132
    mnemonic_entry "encls[edbgwr]", 0, 1133
    mnemonic_entry "encls[eextend]", 0, 1134
    mnemonic_entry "encls[einit]", 0, 1135
    mnemonic_entry "encls[eldb]", 0, 1136
    mnemonic_entry "encls[eldbc]", 0, 1137
    mnemonic_entry "encls[eldu]", 0, 1138
    mnemonic_entry "encls[elduc]", 0, 1139
    mnemonic_entry "encls[emodpr]", 0, 1140
    mnemonic_entry "encls[emodt]", 0, 1141
    mnemonic_entry "encls[epa]", 0, 1142
    mnemonic_entry "encls[erdinfo]", 0, 1143
    mnemonic_entry "encls[eremove]", 0, 1144
    mnemonic_entry "encls[etrack]", 0, 1145
    mnemonic_entry "encls[etrackc]", 0, 1146
    mnemonic_entry "encls[ewb]", 0, 1147
    mnemonic_entry "enclu", 0, 1148
    mnemonic_entry "enclu[eaccept]", 0, 1149
    mnemonic_entry "enclu[eacceptcopy]", 0, 1150
    mnemonic_entry "enclu[edeccssa]", 0, 1151
    mnemonic_entry "enclu[eenter]", 0, 1152
    mnemonic_entry "enclu[eexit]", 0, 1153
    mnemonic_entry "enclu[egetkey]", 0, 1154
    mnemonic_entry "enclu[emodpe]", 0, 1155
    mnemonic_entry "enclu[ereport]", 0, 1156
    mnemonic_entry "enclu[eresume]", 0, 1157
    mnemonic_entry "enclv", 0, 1158
    mnemonic_entry "enclv[edecvirtchild]", 0, 1159
    mnemonic_entry "enclv[eincvirtchild]", 0, 1160
    mnemonic_entry "enclv[esetcontext]", 0, 1161
    mnemonic_entry "encodekey128", 0, 1162
    mnemonic_entry "encodekey256", 0, 1163
    mnemonic_entry "endbr32", 0, 1164
    mnemonic_entry "endbr64", 0, 1165
    mnemonic_entry "enqcmd", 0, 1166
    mnemonic_entry "enqcmds", 0, 1167
    mnemonic_entry "enter", 0, 1168
    mnemonic_entry "extractps", 0, 1169
    mnemonic_entry "f2xm1", 0, 1170
    mnemonic_entry "fabs", 0, 1171
    mnemonic_entry "fadd", 0, 1172
    mnemonic_entry "faddp", 0, 1173
    mnemonic_entry "fbld", 0, 1174
    mnemonic_entry "fbstp", 0, 1175
    mnemonic_entry "fchs", 0, 1176
    mnemonic_entry "fclex", 0, 1177
    mnemonic_entry "fcmovcc", 0, 1178
    mnemonic_entry "fcom", 0, 1179
    mnemonic_entry "fcomi", 0, 1180
    mnemonic_entry "fcomip", 0, 1181
    mnemonic_entry "fcomp", 0, 1182
    mnemonic_entry "fcompp", 0, 1183
    mnemonic_entry "fcos", 0, 1184
    mnemonic_entry "fdecstp", 0, 1185
    mnemonic_entry "fdiv", 0, 1186
    mnemonic_entry "fdivp", 0, 1187
    mnemonic_entry "fdivr", 0, 1188
    mnemonic_entry "fdivrp", 0, 1189
    mnemonic_entry "ffree", 0, 1190
    mnemonic_entry "fiadd", 0, 1191
    mnemonic_entry "ficom", 0, 1192
    mnemonic_entry "ficomp", 0, 1193
    mnemonic_entry "fidiv", 0, 1194
    mnemonic_entry "fidivr", 0, 1195
    mnemonic_entry "fild", 0, 1196
    mnemonic_entry "fimul", 0, 1197
    mnemonic_entry "fincstp", 0, 1198
    mnemonic_entry "finit", 0, 1199
    mnemonic_entry "fist", 0, 1200
    mnemonic_entry "fistp", 0, 1201
    mnemonic_entry "fisttp", 0, 1202
    mnemonic_entry "fisub", 0, 1203
    mnemonic_entry "fisubr", 0, 1204
    mnemonic_entry "fld", 0, 1205
    mnemonic_entry "fld1", 0, 1206
    mnemonic_entry "fldcw", 0, 1207
    mnemonic_entry "fldenv", 0, 1208
    mnemonic_entry "fldl2e", 0, 1209
    mnemonic_entry "fldl2t", 0, 1210
    mnemonic_entry "fldlg2", 0, 1211
    mnemonic_entry "fldln2", 0, 1212
    mnemonic_entry "fldpi", 0, 1213
    mnemonic_entry "fldz", 0, 1214
    mnemonic_entry "fmul", 0, 1215
    mnemonic_entry "fmulp", 0, 1216
    mnemonic_entry "fnclex", 0, 1217
    mnemonic_entry "fninit", 0, 1218
    mnemonic_entry "fnop", 0, 1219
    mnemonic_entry "fnsave", 0, 1220
    mnemonic_entry "fnstcw", 0, 1221
    mnemonic_entry "fnstenv", 0, 1222
    mnemonic_entry "fnstsw", 0, 1223
    mnemonic_entry "fpatan", 0, 1224
    mnemonic_entry "fprem", 0, 1225
    mnemonic_entry "fprem1", 0, 1226
    mnemonic_entry "fptan", 0, 1227
    mnemonic_entry "frndint", 0, 1228
    mnemonic_entry "frstor", 0, 1229
    mnemonic_entry "fsave", 0, 1230
    mnemonic_entry "fscale", 0, 1231
    mnemonic_entry "fsin", 0, 1232
    mnemonic_entry "fsincos", 0, 1233
    mnemonic_entry "fsqrt", 0, 1234
    mnemonic_entry "fst", 0, 1235
    mnemonic_entry "fstcw", 0, 1236
    mnemonic_entry "fstenv", 0, 1237
    mnemonic_entry "fstp", 0, 1238
    mnemonic_entry "fstsw", 0, 1239
    mnemonic_entry "fsub", 0, 1240
    mnemonic_entry "fsubp", 0, 1241
    mnemonic_entry "fsubr", 0, 1242
    mnemonic_entry "fsubrp", 0, 1243
    mnemonic_entry "ftst", 0, 1244
    mnemonic_entry "fucom", 0, 1245
    mnemonic_entry "fucomi", 0, 1246
    mnemonic_entry "fucomip", 0, 1247
    mnemonic_entry "fucomp", 0, 1248
    mnemonic_entry "fucompp", 0, 1249
    mnemonic_entry "fwait", 0, 1250
    mnemonic_entry "fxam", 0, 1251
    mnemonic_entry "fxch", 0, 1252
    mnemonic_entry "fxrstor", 0, 1253
    mnemonic_entry "fxsave", 0, 1254
    mnemonic_entry "fxtract", 0, 1255
    mnemonic_entry "fyl2x", 0, 1256
    mnemonic_entry "fyl2xp1", 0, 1257
    mnemonic_entry "getsec[capabilities]", 0, 1258
    mnemonic_entry "getsec[enteraccs]", 0, 1259
    mnemonic_entry "getsec[exitac]", 0, 1260
    mnemonic_entry "getsec[parameters]", 0, 1261
    mnemonic_entry "getsec[senter]", 0, 1262
    mnemonic_entry "getsec[sexit]", 0, 1263
    mnemonic_entry "getsec[smctrl]", 0, 1264
    mnemonic_entry "getsec[wakeup]", 0, 1265
    mnemonic_entry "gf2p8affineinvqb", 0, 1266
    mnemonic_entry "gf2p8affineqb", 0, 1267
    mnemonic_entry "gf2p8mulb", 0, 1268
    mnemonic_entry "haddpd", 0, 1269
    mnemonic_entry "haddps", 0, 1270
    mnemonic_entry "hlt", 0, 1271
    mnemonic_entry "hreset", 0, 1272
    mnemonic_entry "hsubpd", 0, 1273
    mnemonic_entry "hsubps", 0, 1274
    mnemonic_entry "idiv", 0, 1275
    mnemonic_entry "imul", 0, 1276
    mnemonic_entry "in", 0, 1277
    mnemonic_entry "inc", 0, 1278
    mnemonic_entry "incsspd", 0, 1279
    mnemonic_entry "incsspq", 0, 1280
    mnemonic_entry "ins", 0, 1281
    mnemonic_entry "insb", 0, 1282
    mnemonic_entry "insd", 0, 1283
    mnemonic_entry "insertps", 0, 1284
    mnemonic_entry "insw", 0, 1285
    mnemonic_entry "int", 0, 1286
    mnemonic_entry "int1", 0, 1287
    mnemonic_entry "int3", 0, 1288
    mnemonic_entry "into", 0, 1289
    mnemonic_entry "invd", 0, 1290
    mnemonic_entry "invept", 0, 1291
    mnemonic_entry "invlpg", 0, 1292
    mnemonic_entry "invpcid", 0, 1293
    mnemonic_entry "invvpid", 0, 1294
    mnemonic_entry "iret", 0, 1295
    mnemonic_entry "iretd", 0, 1296
    mnemonic_entry "iretq", 0, 1297
    mnemonic_entry "ja", 0, 3000
    mnemonic_entry "jae", 0, 3001
    mnemonic_entry "jb", 0, 3002
    mnemonic_entry "jbe", 0, 3003
    mnemonic_entry "jc", 0, 3004
    mnemonic_entry "je", 0, 3005
    mnemonic_entry "jg", 0, 3006
    mnemonic_entry "jge", 0, 3007
    mnemonic_entry "jl", 0, 3008
    mnemonic_entry "jle", 0, 3009
    mnemonic_entry "jna", 0, 3010
    mnemonic_entry "jnae", 0, 3011
    mnemonic_entry "jnb", 0, 3012
    mnemonic_entry "jnbe", 0, 3013
    mnemonic_entry "jnc", 0, 3014
    mnemonic_entry "jne", 0, 3015
    mnemonic_entry "jng", 0, 3016
    mnemonic_entry "jnge", 0, 3017
    mnemonic_entry "jnl", 0, 3018
    mnemonic_entry "jnle", 0, 3019
    mnemonic_entry "jno", 0, 3020
    mnemonic_entry "jnp", 0, 3021
    mnemonic_entry "jns", 0, 3022
    mnemonic_entry "jnz", 0, 3023
    mnemonic_entry "jo", 0, 3024
    mnemonic_entry "jp", 0, 3025
    mnemonic_entry "jpe", 0, 3026
    mnemonic_entry "jpo", 0, 3027
    mnemonic_entry "js", 0, 3028
    mnemonic_entry "jz", 0, 3029
    mnemonic_entry "cmovo", 0, 4000
    mnemonic_entry "cmovno", 0, 4001
    mnemonic_entry "cmovb", 0, 4002
    mnemonic_entry "cmovc", 0, 4002
    mnemonic_entry "cmovnae", 0, 4002
    mnemonic_entry "cmovae", 0, 4003
    mnemonic_entry "cmovnb", 0, 4003
    mnemonic_entry "cmovnc", 0, 4003
    mnemonic_entry "cmove", 0, 4004
    mnemonic_entry "cmovz", 0, 4004
    mnemonic_entry "cmovne", 0, 4005
    mnemonic_entry "cmovnz", 0, 4005
    mnemonic_entry "cmovbe", 0, 4006
    mnemonic_entry "cmovna", 0, 4006
    mnemonic_entry "cmova", 0, 4007
    mnemonic_entry "cmovnbe", 0, 4007
    mnemonic_entry "cmovs", 0, 4008
    mnemonic_entry "cmovns", 0, 4009
    mnemonic_entry "cmovp", 0, 4010
    mnemonic_entry "cmovpe", 0, 4010
    mnemonic_entry "cmovnp", 0, 4011
    mnemonic_entry "cmovpo", 0, 4011
    mnemonic_entry "cmovl", 0, 4012
    mnemonic_entry "cmovnge", 0, 4012
    mnemonic_entry "cmovge", 0, 4013
    mnemonic_entry "cmovnl", 0, 4013
    mnemonic_entry "cmovle", 0, 4014
    mnemonic_entry "cmovng", 0, 4014
    mnemonic_entry "cmovg", 0, 4015
    mnemonic_entry "cmovnle", 0, 4015
    mnemonic_entry "seto", 0, 4016
    mnemonic_entry "setno", 0, 4017
    mnemonic_entry "setb", 0, 4018
    mnemonic_entry "setc", 0, 4018
    mnemonic_entry "setnae", 0, 4018
    mnemonic_entry "setae", 0, 4019
    mnemonic_entry "setnb", 0, 4019
    mnemonic_entry "setnc", 0, 4019
    mnemonic_entry "sete", 0, 4020
    mnemonic_entry "setz", 0, 4020
    mnemonic_entry "setne", 0, 4021
    mnemonic_entry "setnz", 0, 4021
    mnemonic_entry "setbe", 0, 4022
    mnemonic_entry "setna", 0, 4022
    mnemonic_entry "seta", 0, 4023
    mnemonic_entry "setnbe", 0, 4023
    mnemonic_entry "sets", 0, 4024
    mnemonic_entry "setns", 0, 4025
    mnemonic_entry "setp", 0, 4026
    mnemonic_entry "setpe", 0, 4026
    mnemonic_entry "setnp", 0, 4027
    mnemonic_entry "setpo", 0, 4027
    mnemonic_entry "setl", 0, 4028
    mnemonic_entry "setnge", 0, 4028
    mnemonic_entry "setge", 0, 4029
    mnemonic_entry "setnl", 0, 4029
    mnemonic_entry "setle", 0, 4030
    mnemonic_entry "setng", 0, 4030
    mnemonic_entry "setg", 0, 4031
    mnemonic_entry "setnle", 0, 4031
    mnemonic_entry "jmp", 0, 1298
    mnemonic_entry "kaddb", 0, 1299
    mnemonic_entry "kaddd", 0, 1300
    mnemonic_entry "kaddq", 0, 1301
    mnemonic_entry "kaddw", 0, 1302
    mnemonic_entry "kandb", 0, 1303
    mnemonic_entry "kandd", 0, 1304
    mnemonic_entry "kandnb", 0, 1305
    mnemonic_entry "kandnd", 0, 1306
    mnemonic_entry "kandnq", 0, 1307
    mnemonic_entry "kandnw", 0, 1308
    mnemonic_entry "kandq", 0, 1309
    mnemonic_entry "kandw", 0, 1310
    mnemonic_entry "kmovb", 0, 1311
    mnemonic_entry "kmovd", 0, 1312
    mnemonic_entry "kmovq", 0, 1313
    mnemonic_entry "kmovw", 0, 1314
    mnemonic_entry "knotb", 0, 1315
    mnemonic_entry "knotd", 0, 1316
    mnemonic_entry "knotq", 0, 1317
    mnemonic_entry "knotw", 0, 1318
    mnemonic_entry "korb", 0, 1319
    mnemonic_entry "kord", 0, 1320
    mnemonic_entry "korq", 0, 1321
    mnemonic_entry "kortestb", 0, 1322
    mnemonic_entry "kortestd", 0, 1323
    mnemonic_entry "kortestq", 0, 1324
    mnemonic_entry "kortestw", 0, 1325
    mnemonic_entry "korw", 0, 1326
    mnemonic_entry "kshiftlb", 0, 1327
    mnemonic_entry "kshiftld", 0, 1328
    mnemonic_entry "kshiftlq", 0, 1329
    mnemonic_entry "kshiftlw", 0, 1330
    mnemonic_entry "kshiftrb", 0, 1331
    mnemonic_entry "kshiftrd", 0, 1332
    mnemonic_entry "kshiftrq", 0, 1333
    mnemonic_entry "kshiftrw", 0, 1334
    mnemonic_entry "ktestb", 0, 1335
    mnemonic_entry "ktestd", 0, 1336
    mnemonic_entry "ktestq", 0, 1337
    mnemonic_entry "ktestw", 0, 1338
    mnemonic_entry "kunpckbw", 0, 1339
    mnemonic_entry "kunpckdq", 0, 1340
    mnemonic_entry "kunpckwd", 0, 1341
    mnemonic_entry "kxnorb", 0, 1342
    mnemonic_entry "kxnord", 0, 1343
    mnemonic_entry "kxnorq", 0, 1344
    mnemonic_entry "kxnorw", 0, 1345
    mnemonic_entry "kxorb", 0, 1346
    mnemonic_entry "kxord", 0, 1347
    mnemonic_entry "kxorq", 0, 1348
    mnemonic_entry "kxorw", 0, 1349
    mnemonic_entry "lahf", 0, 1350
    mnemonic_entry "lar", 0, 1351
    mnemonic_entry "lddqu", 0, 1352
    mnemonic_entry "ldmxcsr", 0, 1353
    mnemonic_entry "lds", 0, 1354
    mnemonic_entry "ldtilecfg", 0, 1355
    mnemonic_entry "lea", 0, 1356
    mnemonic_entry "leave", 0, 1357
    mnemonic_entry "les", 0, 1358
    mnemonic_entry "lfence", 0, 1359
    mnemonic_entry "lfs", 0, 1360
    mnemonic_entry "lgdt", 0, 1361
    mnemonic_entry "lgs", 0, 1362
    mnemonic_entry "lidt", 0, 1363
    mnemonic_entry "lldt", 0, 1364
    mnemonic_entry "lmsw", 0, 1365
    mnemonic_entry "loadiwkey", 0, 1366
    mnemonic_entry "lock", 0, 1367
    mnemonic_entry "lods", 0, 1368
    mnemonic_entry "lodsb", 0, 1369
    mnemonic_entry "lodsd", 0, 1370
    mnemonic_entry "lodsq", 0, 1371
    mnemonic_entry "lodsw", 0, 1372
    mnemonic_entry "loop", 0, 1373
    mnemonic_entry "loopcc", 0, 1374
    mnemonic_entry "lsl", 0, 1375
    mnemonic_entry "lss", 0, 1376
    mnemonic_entry "ltr", 0, 1377
    mnemonic_entry "lzcnt", 0, 1378
    mnemonic_entry "maskmovdqu", 0, 1379
    mnemonic_entry "maskmovq", 0, 1380
    mnemonic_entry "maxpd", 0, 1381
    mnemonic_entry "maxps", 0, 1382
    mnemonic_entry "maxsd", 0, 1383
    mnemonic_entry "maxss", 0, 1384
    mnemonic_entry "mfence", 0, 1385
    mnemonic_entry "minpd", 0, 1386
    mnemonic_entry "minps", 0, 1387
    mnemonic_entry "minsd", 0, 1388
    mnemonic_entry "minss", 0, 1389
    mnemonic_entry "monitor", 0, 1390
    mnemonic_entry "mov", 0, 1391
    mnemonic_entry "movapd", 0, 1392
    mnemonic_entry "movaps", 0, 1393
    mnemonic_entry "movbe", 0, 1394
    mnemonic_entry "movd", 0, 1395
    mnemonic_entry "movddup", 0, 1396
    mnemonic_entry "movdir64b", 0, 1397
    mnemonic_entry "movdiri", 0, 1398
    mnemonic_entry "movdq2q", 0, 1399
    mnemonic_entry "movdqa", 0, 1400
    mnemonic_entry "movdqu", 0, 1401
    mnemonic_entry "movhlps", 0, 1402
    mnemonic_entry "movhpd", 0, 1403
    mnemonic_entry "movhps", 0, 1404
    mnemonic_entry "movlhps", 0, 1405
    mnemonic_entry "movlpd", 0, 1406
    mnemonic_entry "movlps", 0, 1407
    mnemonic_entry "movmskpd", 0, 1408
    mnemonic_entry "movmskps", 0, 1409
    mnemonic_entry "movntdq", 0, 1410
    mnemonic_entry "movntdqa", 0, 1411
    mnemonic_entry "movnti", 0, 1412
    mnemonic_entry "movntpd", 0, 1413
    mnemonic_entry "movntps", 0, 1414
    mnemonic_entry "movntq", 0, 1415
    mnemonic_entry "movq", 0, 1416
    mnemonic_entry "movq2dq", 0, 1417
    mnemonic_entry "movs", 0, 1418
    mnemonic_entry "movsb", 0, 1419
    mnemonic_entry "movsd", 0, 1420
    mnemonic_entry "movshdup", 0, 1421
    mnemonic_entry "movsldup", 0, 1422
    mnemonic_entry "movsq", 0, 1423
    mnemonic_entry "movss", 0, 1424
    mnemonic_entry "movsw", 0, 1425
    mnemonic_entry "movsx", 0, 1426
    mnemonic_entry "movsxd", 0, 1427
    mnemonic_entry "movupd", 0, 1428
    mnemonic_entry "movups", 0, 1429
    mnemonic_entry "movzx", 0, 1430
    mnemonic_entry "mpsadbw", 0, 1431
    mnemonic_entry "mul", 0, 1432
    mnemonic_entry "mulpd", 0, 1433
    mnemonic_entry "mulps", 0, 1434
    mnemonic_entry "mulsd", 0, 1435
    mnemonic_entry "mulss", 0, 1436
    mnemonic_entry "mulx", 0, 1437
    mnemonic_entry "mwait", 0, 1438
    mnemonic_entry "neg", 0, 1439
    mnemonic_entry "nop", 0, 1440
    mnemonic_entry "not", 0, 1441
    mnemonic_entry "or", 0, 1442
    mnemonic_entry "orpd", 0, 1443
    mnemonic_entry "orps", 0, 1444
    mnemonic_entry "out", 0, 1445
    mnemonic_entry "outs", 0, 1446
    mnemonic_entry "outsb", 0, 1447
    mnemonic_entry "outsd", 0, 1448
    mnemonic_entry "outsw", 0, 1449
    mnemonic_entry "pabsb", 0, 1450
    mnemonic_entry "pabsd", 0, 1451
    mnemonic_entry "pabsq", 0, 1452
    mnemonic_entry "pabsw", 0, 1453
    mnemonic_entry "packssdw", 0, 1454
    mnemonic_entry "packsswb", 0, 1455
    mnemonic_entry "packusdw", 0, 1456
    mnemonic_entry "packuswb", 0, 1457
    mnemonic_entry "paddb", 0, 1458
    mnemonic_entry "paddd", 0, 1459
    mnemonic_entry "paddq", 0, 1460
    mnemonic_entry "paddsb", 0, 1461
    mnemonic_entry "paddsw", 0, 1462
    mnemonic_entry "paddusb", 0, 1463
    mnemonic_entry "paddusw", 0, 1464
    mnemonic_entry "paddw", 0, 1465
    mnemonic_entry "palignr", 0, 1466
    mnemonic_entry "pand", 0, 1467
    mnemonic_entry "pandn", 0, 1468
    mnemonic_entry "pause", 0, 1469
    mnemonic_entry "pavgb", 0, 1470
    mnemonic_entry "pavgw", 0, 1471
    mnemonic_entry "pblendvb", 0, 1472
    mnemonic_entry "pblendw", 0, 1473
    mnemonic_entry "pclmulqdq", 0, 1474
    mnemonic_entry "pcmpeqb", 0, 1475
    mnemonic_entry "pcmpeqd", 0, 1476
    mnemonic_entry "pcmpeqq", 0, 1477
    mnemonic_entry "pcmpeqw", 0, 1478
    mnemonic_entry "pcmpestri", 0, 1479
    mnemonic_entry "pcmpestrm", 0, 1480
    mnemonic_entry "pcmpgtb", 0, 1481
    mnemonic_entry "pcmpgtd", 0, 1482
    mnemonic_entry "pcmpgtq", 0, 1483
    mnemonic_entry "pcmpgtw", 0, 1484
    mnemonic_entry "pcmpistri", 0, 1485
    mnemonic_entry "pcmpistrm", 0, 1486
    mnemonic_entry "pconfig", 0, 1487
    mnemonic_entry "pdep", 0, 1488
    mnemonic_entry "pext", 0, 1489
    mnemonic_entry "pextrb", 0, 1490
    mnemonic_entry "pextrd", 0, 1491
    mnemonic_entry "pextrq", 0, 1492
    mnemonic_entry "pextrw", 0, 1493
    mnemonic_entry "phaddd", 0, 1494
    mnemonic_entry "phaddsw", 0, 1495
    mnemonic_entry "phaddw", 0, 1496
    mnemonic_entry "phminposuw", 0, 1497
    mnemonic_entry "phsubd", 0, 1498
    mnemonic_entry "phsubsw", 0, 1499
    mnemonic_entry "phsubw", 0, 1500
    mnemonic_entry "pinsrb", 0, 1501
    mnemonic_entry "pinsrd", 0, 1502
    mnemonic_entry "pinsrq", 0, 1503
    mnemonic_entry "pinsrw", 0, 1504
    mnemonic_entry "pmaddubsw", 0, 1505
    mnemonic_entry "pmaddwd", 0, 1506
    mnemonic_entry "pmaxsb", 0, 1507
    mnemonic_entry "pmaxsd", 0, 1508
    mnemonic_entry "pmaxsq", 0, 1509
    mnemonic_entry "pmaxsw", 0, 1510
    mnemonic_entry "pmaxub", 0, 1511
    mnemonic_entry "pmaxud", 0, 1512
    mnemonic_entry "pmaxuq", 0, 1513
    mnemonic_entry "pmaxuw", 0, 1514
    mnemonic_entry "pminsb", 0, 1515
    mnemonic_entry "pminsd", 0, 1516
    mnemonic_entry "pminsq", 0, 1517
    mnemonic_entry "pminsw", 0, 1518
    mnemonic_entry "pminub", 0, 1519
    mnemonic_entry "pminud", 0, 1520
    mnemonic_entry "pminuq", 0, 1521
    mnemonic_entry "pminuw", 0, 1522
    mnemonic_entry "pmovmskb", 0, 1523
    mnemonic_entry "pmovsx", 0, 1524
    mnemonic_entry "pmovzx", 0, 1525
    mnemonic_entry "pmuldq", 0, 1526
    mnemonic_entry "pmulhrsw", 0, 1527
    mnemonic_entry "pmulhuw", 0, 1528
    mnemonic_entry "pmulhw", 0, 1529
    mnemonic_entry "pmulld", 0, 1530
    mnemonic_entry "pmullq", 0, 1531
    mnemonic_entry "pmullw", 0, 1532
    mnemonic_entry "pmuludq", 0, 1533
    mnemonic_entry "pop", 0, 1534
    mnemonic_entry "popa", 0, 1535
    mnemonic_entry "popad", 0, 1536
    mnemonic_entry "popcnt", 0, 1537
    mnemonic_entry "popf", 0, 1538
    mnemonic_entry "popfd", 0, 1539
    mnemonic_entry "popfq", 0, 1540
    mnemonic_entry "por", 0, 1541
    mnemonic_entry "prefetchh", 0, 1542
    mnemonic_entry "prefetchw", 0, 1543
    mnemonic_entry "prefetchwt1", 0, 1544
    mnemonic_entry "psadbw", 0, 1545
    mnemonic_entry "pshufb", 0, 1546
    mnemonic_entry "pshufd", 0, 1547
    mnemonic_entry "pshufhw", 0, 1548
    mnemonic_entry "pshuflw", 0, 1549
    mnemonic_entry "pshufw", 0, 1550
    mnemonic_entry "psignb", 0, 1551
    mnemonic_entry "psignd", 0, 1552
    mnemonic_entry "psignw", 0, 1553
    mnemonic_entry "pslld", 0, 1554
    mnemonic_entry "pslldq", 0, 1555
    mnemonic_entry "psllq", 0, 1556
    mnemonic_entry "psllw", 0, 1557
    mnemonic_entry "psrad", 0, 1558
    mnemonic_entry "psraq", 0, 1559
    mnemonic_entry "psraw", 0, 1560
    mnemonic_entry "psrld", 0, 1561
    mnemonic_entry "psrldq", 0, 1562
    mnemonic_entry "psrlq", 0, 1563
    mnemonic_entry "psrlw", 0, 1564
    mnemonic_entry "psubb", 0, 1565
    mnemonic_entry "psubd", 0, 1566
    mnemonic_entry "psubq", 0, 1567
    mnemonic_entry "psubsb", 0, 1568
    mnemonic_entry "psubsw", 0, 1569
    mnemonic_entry "psubusb", 0, 1570
    mnemonic_entry "psubusw", 0, 1571
    mnemonic_entry "psubw", 0, 1572
    mnemonic_entry "ptest", 0, 1573
    mnemonic_entry "ptwrite", 0, 1574
    mnemonic_entry "punpckhbw", 0, 1575
    mnemonic_entry "punpckhdq", 0, 1576
    mnemonic_entry "punpckhqdq", 0, 1577
    mnemonic_entry "punpckhwd", 0, 1578
    mnemonic_entry "punpcklbw", 0, 1579
    mnemonic_entry "punpckldq", 0, 1580
    mnemonic_entry "punpcklqdq", 0, 1581
    mnemonic_entry "punpcklwd", 0, 1582
    mnemonic_entry "push", 0, 1583
    mnemonic_entry "pusha", 0, 1584
    mnemonic_entry "pushad", 0, 1585
    mnemonic_entry "pushf", 0, 1586
    mnemonic_entry "pushfd", 0, 1587
    mnemonic_entry "pushfq", 0, 1588
    mnemonic_entry "pxor", 0, 1589
    mnemonic_entry "rcl", 0, 1590
    mnemonic_entry "rcpps", 0, 1591
    mnemonic_entry "rcpss", 0, 1592
    mnemonic_entry "rcr", 0, 1593
    mnemonic_entry "rdfsbase", 0, 1594
    mnemonic_entry "rdgsbase", 0, 1595
    mnemonic_entry "rdmsr", 0, 1596
    mnemonic_entry "rdpid", 0, 1597
    mnemonic_entry "rdpkru", 0, 1598
    mnemonic_entry "rdpmc", 0, 1599
    mnemonic_entry "rdrand", 0, 1600
    mnemonic_entry "rdseed", 0, 1601
    mnemonic_entry "rdsspd", 0, 1602
    mnemonic_entry "rdsspq", 0, 1603
    mnemonic_entry "rdtsc", 0, 1604
    mnemonic_entry "rdtscp", 0, 1605
    mnemonic_entry "rep", 0, 1606
    mnemonic_entry "repe", 0, 1607
    mnemonic_entry "repne", 0, 1608
    mnemonic_entry "repnz", 0, 1609
    mnemonic_entry "repz", 0, 1610
    mnemonic_entry "ret", 0, 1611
    mnemonic_entry "rol", 0, 1612
    mnemonic_entry "ror", 0, 1613
    mnemonic_entry "rorx", 0, 1614
    mnemonic_entry "roundpd", 0, 1615
    mnemonic_entry "roundps", 0, 1616
    mnemonic_entry "roundsd", 0, 1617
    mnemonic_entry "roundss", 0, 1618
    mnemonic_entry "rsm", 0, 1619
    mnemonic_entry "rsqrtps", 0, 1620
    mnemonic_entry "rsqrtss", 0, 1621
    mnemonic_entry "rstorssp", 0, 1622
    mnemonic_entry "sahf", 0, 1623
    mnemonic_entry "sal", 0, 1624
    mnemonic_entry "sar", 0, 1625
    mnemonic_entry "sarx", 0, 1626
    mnemonic_entry "saveprevssp", 0, 1627
    mnemonic_entry "sbb", 0, 1628
    mnemonic_entry "scas", 0, 1629
    mnemonic_entry "scasb", 0, 1630
    mnemonic_entry "scasd", 0, 1631
    mnemonic_entry "scasw", 0, 1632
    mnemonic_entry "senduipi", 0, 1633
    mnemonic_entry "serialize", 0, 1634
    mnemonic_entry "setcc", 0, 1635
    mnemonic_entry "setssbsy", 0, 1636
    mnemonic_entry "sfence", 0, 1637
    mnemonic_entry "sgdt", 0, 1638
    mnemonic_entry "sgx", 0, 1639
    mnemonic_entry "sha1msg1", 0, 1640
    mnemonic_entry "sha1msg2", 0, 1641
    mnemonic_entry "sha1nexte", 0, 1642
    mnemonic_entry "sha1rnds4", 0, 1643
    mnemonic_entry "sha256msg1", 0, 1644
    mnemonic_entry "sha256msg2", 0, 1645
    mnemonic_entry "sha256rnds2", 0, 1646
    mnemonic_entry "shl", 0, 1647
    mnemonic_entry "shld", 0, 1648
    mnemonic_entry "shlx", 0, 1649
    mnemonic_entry "shr", 0, 1650
    mnemonic_entry "shrd", 0, 1651
    mnemonic_entry "shrx", 0, 1652
    mnemonic_entry "shufpd", 0, 1653
    mnemonic_entry "shufps", 0, 1654
    mnemonic_entry "sidt", 0, 1655
    mnemonic_entry "sldt", 0, 1656
    mnemonic_entry "smsw", 0, 1657
    mnemonic_entry "smx", 0, 1658
    mnemonic_entry "sqrtpd", 0, 1659
    mnemonic_entry "sqrtps", 0, 1660
    mnemonic_entry "sqrtsd", 0, 1661
    mnemonic_entry "sqrtss", 0, 1662
    mnemonic_entry "stac", 0, 1663
    mnemonic_entry "stc", 0, 1664
    mnemonic_entry "std", 0, 1665
    mnemonic_entry "sti", 0, 1666
    mnemonic_entry "stmxcsr", 0, 1667
    mnemonic_entry "stos", 0, 1668
    mnemonic_entry "stosb", 0, 1669
    mnemonic_entry "stosd", 0, 1670
    mnemonic_entry "stosq", 0, 1671
    mnemonic_entry "stosw", 0, 1672
    mnemonic_entry "str", 0, 1673
    mnemonic_entry "sttilecfg", 0, 1674
    mnemonic_entry "stui", 0, 1675
    mnemonic_entry "sub", 0, 1676
    mnemonic_entry "subpd", 0, 1677
    mnemonic_entry "subps", 0, 1678
    mnemonic_entry "subsd", 0, 1679
    mnemonic_entry "subss", 0, 1680
    mnemonic_entry "swapgs", 0, 1681
    mnemonic_entry "syscall", 0, 1682
    mnemonic_entry "sysenter", 0, 1683
    mnemonic_entry "sysexit", 0, 1684
    mnemonic_entry "sysret", 0, 1685
    mnemonic_entry "tdpbf16ps", 0, 1686
    mnemonic_entry "tdpbssd", 0, 1687
    mnemonic_entry "tdpbsud", 0, 1688
    mnemonic_entry "tdpbusd", 0, 1689
    mnemonic_entry "tdpbuud", 0, 1690
    mnemonic_entry "test", 0, 1691
    mnemonic_entry "testui", 0, 1692
    mnemonic_entry "tileloadd", 0, 1693
    mnemonic_entry "tileloaddt1", 0, 1694
    mnemonic_entry "tilerelease", 0, 1695
    mnemonic_entry "tilestored", 0, 1696
    mnemonic_entry "tilezero", 0, 1697
    mnemonic_entry "tpause", 0, 1698
    mnemonic_entry "tzcnt", 0, 1699
    mnemonic_entry "ucomisd", 0, 1700
    mnemonic_entry "ucomiss", 0, 1701
    mnemonic_entry "ud", 0, 1702
    mnemonic_entry "uiret", 0, 1703
    mnemonic_entry "umonitor", 0, 1704
    mnemonic_entry "umwait", 0, 1705
    mnemonic_entry "unpckhpd", 0, 1706
    mnemonic_entry "unpckhps", 0, 1707
    mnemonic_entry "unpcklpd", 0, 1708
    mnemonic_entry "unpcklps", 0, 1709
    mnemonic_entry "v4fmaddps", 0, 1710
    mnemonic_entry "v4fmaddss", 0, 1711
    mnemonic_entry "v4fnmaddps", 0, 1712
    mnemonic_entry "v4fnmaddss", 0, 1713
    mnemonic_entry "vaddph", 0, 1714
    mnemonic_entry "vaddsh", 0, 1715
    mnemonic_entry "valignd", 0, 1716
    mnemonic_entry "valignq", 0, 1717
    mnemonic_entry "vblendmpd", 0, 1718
    mnemonic_entry "vblendmps", 0, 1719
    mnemonic_entry "vbroadcast", 0, 1720
    mnemonic_entry "vcmpph", 0, 1721
    mnemonic_entry "vcmpsh", 0, 1722
    mnemonic_entry "vcomish", 0, 1723
    mnemonic_entry "vcompresspd", 0, 1724
    mnemonic_entry "vcompressps", 0, 1725
    mnemonic_entry "vcompressw", 0, 1726
    mnemonic_entry "vcvtdq2ph", 0, 1727
    mnemonic_entry "vcvtne2ps2bf16", 0, 1728
    mnemonic_entry "vcvtneps2bf16", 0, 1729
    mnemonic_entry "vcvtpd2ph", 0, 1730
    mnemonic_entry "vcvtpd2qq", 0, 1731
    mnemonic_entry "vcvtpd2udq", 0, 1732
    mnemonic_entry "vcvtpd2uqq", 0, 1733
    mnemonic_entry "vcvtph2dq", 0, 1734
    mnemonic_entry "vcvtph2pd", 0, 1735
    mnemonic_entry "vcvtph2ps", 0, 1736
    mnemonic_entry "vcvtph2psx", 0, 1737
    mnemonic_entry "vcvtph2qq", 0, 1738
    mnemonic_entry "vcvtph2udq", 0, 1739
    mnemonic_entry "vcvtph2uqq", 0, 1740
    mnemonic_entry "vcvtph2uw", 0, 1741
    mnemonic_entry "vcvtph2w", 0, 1742
    mnemonic_entry "vcvtps2ph", 0, 1743
    mnemonic_entry "vcvtps2phx", 0, 1744
    mnemonic_entry "vcvtps2qq", 0, 1745
    mnemonic_entry "vcvtps2udq", 0, 1746
    mnemonic_entry "vcvtps2uqq", 0, 1747
    mnemonic_entry "vcvtqq2pd", 0, 1748
    mnemonic_entry "vcvtqq2ph", 0, 1749
    mnemonic_entry "vcvtqq2ps", 0, 1750
    mnemonic_entry "vcvtsd2sh", 0, 1751
    mnemonic_entry "vcvtsd2usi", 0, 1752
    mnemonic_entry "vcvtsh2sd", 0, 1753
    mnemonic_entry "vcvtsh2si", 0, 1754
    mnemonic_entry "vcvtsh2ss", 0, 1755
    mnemonic_entry "vcvtsh2usi", 0, 1756
    mnemonic_entry "vcvtsi2sh", 0, 1757
    mnemonic_entry "vcvtss2sh", 0, 1758
    mnemonic_entry "vcvtss2usi", 0, 1759
    mnemonic_entry "vcvttpd2qq", 0, 1760
    mnemonic_entry "vcvttpd2udq", 0, 1761
    mnemonic_entry "vcvttpd2uqq", 0, 1762
    mnemonic_entry "vcvttph2dq", 0, 1763
    mnemonic_entry "vcvttph2qq", 0, 1764
    mnemonic_entry "vcvttph2udq", 0, 1765
    mnemonic_entry "vcvttph2uqq", 0, 1766
    mnemonic_entry "vcvttph2uw", 0, 1767
    mnemonic_entry "vcvttph2w", 0, 1768
    mnemonic_entry "vcvttps2qq", 0, 1769
    mnemonic_entry "vcvttps2udq", 0, 1770
    mnemonic_entry "vcvttps2uqq", 0, 1771
    mnemonic_entry "vcvttsd2usi", 0, 1772
    mnemonic_entry "vcvttsh2si", 0, 1773
    mnemonic_entry "vcvttsh2usi", 0, 1774
    mnemonic_entry "vcvttss2usi", 0, 1775
    mnemonic_entry "vcvtudq2pd", 0, 1776
    mnemonic_entry "vcvtudq2ph", 0, 1777
    mnemonic_entry "vcvtudq2ps", 0, 1778
    mnemonic_entry "vcvtuqq2pd", 0, 1779
    mnemonic_entry "vcvtuqq2ph", 0, 1780
    mnemonic_entry "vcvtuqq2ps", 0, 1781
    mnemonic_entry "vcvtusi2sd", 0, 1782
    mnemonic_entry "vcvtusi2sh", 0, 1783
    mnemonic_entry "vcvtusi2ss", 0, 1784
    mnemonic_entry "vcvtuw2ph", 0, 1785
    mnemonic_entry "vcvtw2ph", 0, 1786
    mnemonic_entry "vdbpsadbw", 0, 1787
    mnemonic_entry "vdivph", 0, 1788
    mnemonic_entry "vdivsh", 0, 1789
    mnemonic_entry "vdpbf16ps", 0, 1790
    mnemonic_entry "verr", 0, 1791
    mnemonic_entry "verw", 0, 1792
    mnemonic_entry "vexp2pd", 0, 1793
    mnemonic_entry "vexp2ps", 0, 1794
    mnemonic_entry "vexpandpd", 0, 1795
    mnemonic_entry "vexpandps", 0, 1796
    mnemonic_entry "vextractf128", 0, 1797
    mnemonic_entry "vextractf32x4", 0, 1798
    mnemonic_entry "vextractf32x8", 0, 1799
    mnemonic_entry "vextractf64x2", 0, 1800
    mnemonic_entry "vextractf64x4", 0, 1801
    mnemonic_entry "vextracti128", 0, 1802
    mnemonic_entry "vextracti32x4", 0, 1803
    mnemonic_entry "vextracti32x8", 0, 1804
    mnemonic_entry "vextracti64x2", 0, 1805
    mnemonic_entry "vextracti64x4", 0, 1806
    mnemonic_entry "vfcmaddcph", 0, 1807
    mnemonic_entry "vfcmaddcsh", 0, 1808
    mnemonic_entry "vfcmulcph", 0, 1809
    mnemonic_entry "vfcmulcsh", 0, 1810
    mnemonic_entry "vfixupimmpd", 0, 1811
    mnemonic_entry "vfixupimmps", 0, 1812
    mnemonic_entry "vfixupimmsd", 0, 1813
    mnemonic_entry "vfixupimmss", 0, 1814
    mnemonic_entry "vfmadd132pd", 0, 1815
    mnemonic_entry "vfmadd132ph", 0, 1816
    mnemonic_entry "vfmadd132ps", 0, 1817
    mnemonic_entry "vfmadd132sd", 0, 1818
    mnemonic_entry "vfmadd132sh", 0, 1819
    mnemonic_entry "vfmadd132ss", 0, 1820
    mnemonic_entry "vfmadd213pd", 0, 1821
    mnemonic_entry "vfmadd213ph", 0, 1822
    mnemonic_entry "vfmadd213ps", 0, 1823
    mnemonic_entry "vfmadd213sd", 0, 1824
    mnemonic_entry "vfmadd213sh", 0, 1825
    mnemonic_entry "vfmadd213ss", 0, 1826
    mnemonic_entry "vfmadd231pd", 0, 1827
    mnemonic_entry "vfmadd231ph", 0, 1828
    mnemonic_entry "vfmadd231ps", 0, 1829
    mnemonic_entry "vfmadd231sd", 0, 1830
    mnemonic_entry "vfmadd231sh", 0, 1831
    mnemonic_entry "vfmadd231ss", 0, 1832
    mnemonic_entry "vfmaddcph", 0, 1833
    mnemonic_entry "vfmaddcsh", 0, 1834
    mnemonic_entry "vfmaddrnd231pd", 0, 1835
    mnemonic_entry "vfmadsub132pd", 0, 1836
    mnemonic_entry "vfmadsub132ph", 0, 1837
    mnemonic_entry "vfmadsub132ps", 0, 1838
    mnemonic_entry "vfmadsub213pd", 0, 1839
    mnemonic_entry "vfmadsub213ph", 0, 1840
    mnemonic_entry "vfmadsub213ps", 0, 1841
    mnemonic_entry "vfmadsub231pd", 0, 1842
    mnemonic_entry "vfmadsub231ph", 0, 1843
    mnemonic_entry "vfmadsub231ps", 0, 1844
    mnemonic_entry "vfmsub132pd", 0, 1845
    mnemonic_entry "vfmsub132ph", 0, 1846
    mnemonic_entry "vfmsub132ps", 0, 1847
    mnemonic_entry "vfmsub132sd", 0, 1848
    mnemonic_entry "vfmsub132sh", 0, 1849
    mnemonic_entry "vfmsub132ss", 0, 1850
    mnemonic_entry "vfmsub213pd", 0, 1851
    mnemonic_entry "vfmsub213ph", 0, 1852
    mnemonic_entry "vfmsub213ps", 0, 1853
    mnemonic_entry "vfmsub213sd", 0, 1854
    mnemonic_entry "vfmsub213sh", 0, 1855
    mnemonic_entry "vfmsub213ss", 0, 1856
    mnemonic_entry "vfmsub231pd", 0, 1857
    mnemonic_entry "vfmsub231ph", 0, 1858
    mnemonic_entry "vfmsub231ps", 0, 1859
    mnemonic_entry "vfmsub231sd", 0, 1860
    mnemonic_entry "vfmsub231sh", 0, 1861
    mnemonic_entry "vfmsub231ss", 0, 1862
    mnemonic_entry "vfmsubadd132pd", 0, 1863
    mnemonic_entry "vfmsubadd132ph", 0, 1864
    mnemonic_entry "vfmsubadd132ps", 0, 1865
    mnemonic_entry "vfmsubadd213pd", 0, 1866
    mnemonic_entry "vfmsubadd213ph", 0, 1867
    mnemonic_entry "vfmsubadd213ps", 0, 1868
    mnemonic_entry "vfmsubadd231pd", 0, 1869
    mnemonic_entry "vfmsubadd231ph", 0, 1870
    mnemonic_entry "vfmsubadd231ps", 0, 1871
    mnemonic_entry "vfmulcph", 0, 1872
    mnemonic_entry "vfmulcsh", 0, 1873
    mnemonic_entry "vfnmadd132pd", 0, 1874
    mnemonic_entry "vfnmadd132ph", 0, 1875
    mnemonic_entry "vfnmadd132ps", 0, 1876
    mnemonic_entry "vfnmadd132sd", 0, 1877
    mnemonic_entry "vfnmadd132sh", 0, 1878
    mnemonic_entry "vfnmadd132ss", 0, 1879
    mnemonic_entry "vfnmadd213pd", 0, 1880
    mnemonic_entry "vfnmadd213ph", 0, 1881
    mnemonic_entry "vfnmadd213ps", 0, 1882
    mnemonic_entry "vfnmadd213sd", 0, 1883
    mnemonic_entry "vfnmadd213sh", 0, 1884
    mnemonic_entry "vfnmadd213ss", 0, 1885
    mnemonic_entry "vfnmadd231pd", 0, 1886
    mnemonic_entry "vfnmadd231ph", 0, 1887
    mnemonic_entry "vfnmadd231ps", 0, 1888
    mnemonic_entry "vfnmadd231sd", 0, 1889
    mnemonic_entry "vfnmadd231sh", 0, 1890
    mnemonic_entry "vfnmadd231ss", 0, 1891
    mnemonic_entry "vfnmsub132pd", 0, 1892
    mnemonic_entry "vfnmsub132ph", 0, 1893
    mnemonic_entry "vfnmsub132ps", 0, 1894
    mnemonic_entry "vfnmsub132sd", 0, 1895
    mnemonic_entry "vfnmsub132sh", 0, 1896
    mnemonic_entry "vfnmsub132ss", 0, 1897
    mnemonic_entry "vfnmsub213pd", 0, 1898
    mnemonic_entry "vfnmsub213ph", 0, 1899
    mnemonic_entry "vfnmsub213ps", 0, 1900
    mnemonic_entry "vfnmsub213sd", 0, 1901
    mnemonic_entry "vfnmsub213sh", 0, 1902
    mnemonic_entry "vfnmsub213ss", 0, 1903
    mnemonic_entry "vfnmsub231pd", 0, 1904
    mnemonic_entry "vfnmsub231ph", 0, 1905
    mnemonic_entry "vfnmsub231ps", 0, 1906
    mnemonic_entry "vfnmsub231sd", 0, 1907
    mnemonic_entry "vfnmsub231sh", 0, 1908
    mnemonic_entry "vfnmsub231ss", 0, 1909
    mnemonic_entry "vfpclasspd", 0, 1910
    mnemonic_entry "vfpclassph", 0, 1911
    mnemonic_entry "vfpclassps", 0, 1912
    mnemonic_entry "vfpclasssd", 0, 1913
    mnemonic_entry "vfpclasssh", 0, 1914
    mnemonic_entry "vfpclassss", 0, 1915
    mnemonic_entry "vgatherdpd", 0, 1916
    mnemonic_entry "vgatherdps", 0, 1917
    mnemonic_entry "vgatherqpd", 0, 1918
    mnemonic_entry "vgatherqps", 0, 1919
    mnemonic_entry "vgetexppd", 0, 1920
    mnemonic_entry "vgetexpph", 0, 1921
    mnemonic_entry "vgetexpps", 0, 1922
    mnemonic_entry "vgetexpsd", 0, 1923
    mnemonic_entry "vgetexpsh", 0, 1924
    mnemonic_entry "vgetexpss", 0, 1925
    mnemonic_entry "vgetmantpd", 0, 1926
    mnemonic_entry "vgetmantph", 0, 1927
    mnemonic_entry "vgetmantps", 0, 1928
    mnemonic_entry "vgetmantsd", 0, 1929
    mnemonic_entry "vgetmantsh", 0, 1930
    mnemonic_entry "vgetmantss", 0, 1931
    mnemonic_entry "vinsertf128", 0, 1932
    mnemonic_entry "vinsertf32x4", 0, 1933
    mnemonic_entry "vinsertf32x8", 0, 1934
    mnemonic_entry "vinsertf64x2", 0, 1935
    mnemonic_entry "vinsertf64x4", 0, 1936
    mnemonic_entry "vinserti128", 0, 1937
    mnemonic_entry "vinserti32x4", 0, 1938
    mnemonic_entry "vinserti32x8", 0, 1939
    mnemonic_entry "vinserti64x2", 0, 1940
    mnemonic_entry "vinserti64x4", 0, 1941
    mnemonic_entry "vmaskmov", 0, 1942
    mnemonic_entry "vmaxph", 0, 1943
    mnemonic_entry "vmaxsh", 0, 1944
    mnemonic_entry "vminph", 0, 1945
    mnemonic_entry "vminsh", 0, 1946
    mnemonic_entry "vmovdqa32", 0, 1947
    mnemonic_entry "vmovdqa64", 0, 1948
    mnemonic_entry "vmovdqu16", 0, 1949
    mnemonic_entry "vmovdqu32", 0, 1950
    mnemonic_entry "vmovdqu64", 0, 1951
    mnemonic_entry "vmovdqu8", 0, 1952
    mnemonic_entry "vmovsh", 0, 1953
    mnemonic_entry "vmovw", 0, 1954
    mnemonic_entry "vmulph", 0, 1955
    mnemonic_entry "vmulsh", 0, 1956
    mnemonic_entry "vp2intersectd", 0, 1957
    mnemonic_entry "vp2intersectq", 0, 1958
    mnemonic_entry "vpblendd", 0, 1959
    mnemonic_entry "vpblendmb", 0, 1960
    mnemonic_entry "vpblendmd", 0, 1961
    mnemonic_entry "vpblendmq", 0, 1962
    mnemonic_entry "vpblendmw", 0, 1963
    mnemonic_entry "vpbroadcast", 0, 1964
    mnemonic_entry "vpbroadcastb", 0, 1965
    mnemonic_entry "vpbroadcastd", 0, 1966
    mnemonic_entry "vpbroadcastm", 0, 1967
    mnemonic_entry "vpbroadcastq", 0, 1968
    mnemonic_entry "vpbroadcastw", 0, 1969
    mnemonic_entry "vpcmpb", 0, 1970
    mnemonic_entry "vpcmpd", 0, 1971
    mnemonic_entry "vpcmpq", 0, 1972
    mnemonic_entry "vpcmpub", 0, 1973
    mnemonic_entry "vpcmpud", 0, 1974
    mnemonic_entry "vpcmpuq", 0, 1975
    mnemonic_entry "vpcmpuw", 0, 1976
    mnemonic_entry "vpcmpw", 0, 1977
    mnemonic_entry "vpcompressb", 0, 1978
    mnemonic_entry "vpcompressd", 0, 1979
    mnemonic_entry "vpcompressq", 0, 1980
    mnemonic_entry "vpconflictd", 0, 1981
    mnemonic_entry "vpconflictq", 0, 1982
    mnemonic_entry "vpdpbusd", 0, 1983
    mnemonic_entry "vpdpbusds", 0, 1984
    mnemonic_entry "vpdpwssd", 0, 1985
    mnemonic_entry "vpdpwssds", 0, 1986
    mnemonic_entry "vperm2f128", 0, 1987
    mnemonic_entry "vperm2i128", 0, 1988
    mnemonic_entry "vpermb", 0, 1989
    mnemonic_entry "vpermd", 0, 1990
    mnemonic_entry "vpermi2b", 0, 1991
    mnemonic_entry "vpermi2d", 0, 1992
    mnemonic_entry "vpermi2pd", 0, 1993
    mnemonic_entry "vpermi2ps", 0, 1994
    mnemonic_entry "vpermi2q", 0, 1995
    mnemonic_entry "vpermi2w", 0, 1996
    mnemonic_entry "vpermilpd", 0, 1997
    mnemonic_entry "vpermilps", 0, 1998
    mnemonic_entry "vpermpd", 0, 1999
    mnemonic_entry "vpermps", 0, 2000
    mnemonic_entry "vpermq", 0, 2001
    mnemonic_entry "vpermt2b", 0, 2002
    mnemonic_entry "vpermt2d", 0, 2003
    mnemonic_entry "vpermt2pd", 0, 2004
    mnemonic_entry "vpermt2ps", 0, 2005
    mnemonic_entry "vpermt2q", 0, 2006
    mnemonic_entry "vpermt2w", 0, 2007
    mnemonic_entry "vpermw", 0, 2008
    mnemonic_entry "vpexpandb", 0, 2009
    mnemonic_entry "vpexpandd", 0, 2010
    mnemonic_entry "vpexpandq", 0, 2011
    mnemonic_entry "vpexpandw", 0, 2012
    mnemonic_entry "vpgatherdd", 0, 2013
    mnemonic_entry "vpgatherdq", 0, 2014
    mnemonic_entry "vpgatherqd", 0, 2015
    mnemonic_entry "vpgatherqq", 0, 2016
    mnemonic_entry "vplzcntd", 0, 2017
    mnemonic_entry "vplzcntq", 0, 2018
    mnemonic_entry "vpmadd52huq", 0, 2019
    mnemonic_entry "vpmadd52luq", 0, 2020
    mnemonic_entry "vpmaskmov", 0, 2021
    mnemonic_entry "vpmovb2m", 0, 2022
    mnemonic_entry "vpmovd2m", 0, 2023
    mnemonic_entry "vpmovdb", 0, 2024
    mnemonic_entry "vpmovdw", 0, 2025
    mnemonic_entry "vpmovm2b", 0, 2026
    mnemonic_entry "vpmovm2d", 0, 2027
    mnemonic_entry "vpmovm2q", 0, 2028
    mnemonic_entry "vpmovm2w", 0, 2029
    mnemonic_entry "vpmovq2m", 0, 2030
    mnemonic_entry "vpmovqb", 0, 2031
    mnemonic_entry "vpmovqd", 0, 2032
    mnemonic_entry "vpmovqw", 0, 2033
    mnemonic_entry "vpmovsdb", 0, 2034
    mnemonic_entry "vpmovsdw", 0, 2035
    mnemonic_entry "vpmovsqb", 0, 2036
    mnemonic_entry "vpmovsqd", 0, 2037
    mnemonic_entry "vpmovsqw", 0, 2038
    mnemonic_entry "vpmovswb", 0, 2039
    mnemonic_entry "vpmovusdb", 0, 2040
    mnemonic_entry "vpmovusdw", 0, 2041
    mnemonic_entry "vpmovusqb", 0, 2042
    mnemonic_entry "vpmovusqd", 0, 2043
    mnemonic_entry "vpmovusqw", 0, 2044
    mnemonic_entry "vpmovuswb", 0, 2045
    mnemonic_entry "vpmovw2m", 0, 2046
    mnemonic_entry "vpmovwb", 0, 2047
    mnemonic_entry "vpmultishiftqb", 0, 2048
    mnemonic_entry "vpopcnt", 0, 2049
    mnemonic_entry "vprold", 0, 2050
    mnemonic_entry "vprolq", 0, 2051
    mnemonic_entry "vprolvd", 0, 2052
    mnemonic_entry "vprolvq", 0, 2053
    mnemonic_entry "vprord", 0, 2054
    mnemonic_entry "vprorq", 0, 2055
    mnemonic_entry "vprorvd", 0, 2056
    mnemonic_entry "vprorvq", 0, 2057
    mnemonic_entry "vpscatterdd", 0, 2058
    mnemonic_entry "vpscatterdq", 0, 2059
    mnemonic_entry "vpscatterqd", 0, 2060
    mnemonic_entry "vpscatterqq", 0, 2061
    mnemonic_entry "vpshld", 0, 2062
    mnemonic_entry "vpshldv", 0, 2063
    mnemonic_entry "vpshrd", 0, 2064
    mnemonic_entry "vpshrdv", 0, 2065
    mnemonic_entry "vpshufbitqmb", 0, 2066
    mnemonic_entry "vpsllvd", 0, 2067
    mnemonic_entry "vpsllvq", 0, 2068
    mnemonic_entry "vpsllvw", 0, 2069
    mnemonic_entry "vpsravd", 0, 2070
    mnemonic_entry "vpsravq", 0, 2071
    mnemonic_entry "vpsravw", 0, 2072
    mnemonic_entry "vpsrlvd", 0, 2073
    mnemonic_entry "vpsrlvq", 0, 2074
    mnemonic_entry "vpsrlvw", 0, 2075
    mnemonic_entry "vpternlogd", 0, 2076
    mnemonic_entry "vpternlogq", 0, 2077
    mnemonic_entry "vptestmb", 0, 2078
    mnemonic_entry "vptestmd", 0, 2079
    mnemonic_entry "vptestmq", 0, 2080
    mnemonic_entry "vptestmw", 0, 2081
    mnemonic_entry "vptestnmb", 0, 2082
    mnemonic_entry "vptestnmd", 0, 2083
    mnemonic_entry "vptestnmq", 0, 2084
    mnemonic_entry "vptestnmw", 0, 2085
    mnemonic_entry "vrangepd", 0, 2086
    mnemonic_entry "vrangeps", 0, 2087
    mnemonic_entry "vrangesd", 0, 2088
    mnemonic_entry "vrangess", 0, 2089
    mnemonic_entry "vrcp14pd", 0, 2090
    mnemonic_entry "vrcp14ps", 0, 2091
    mnemonic_entry "vrcp14sd", 0, 2092
    mnemonic_entry "vrcp14ss", 0, 2093
    mnemonic_entry "vrcpph", 0, 2094
    mnemonic_entry "vrcpsh", 0, 2095
    mnemonic_entry "vreducepd", 0, 2096
    mnemonic_entry "vreduceph", 0, 2097
    mnemonic_entry "vreduceps", 0, 2098
    mnemonic_entry "vreducesd", 0, 2099
    mnemonic_entry "vreducesh", 0, 2100
    mnemonic_entry "vreducess", 0, 2101
    mnemonic_entry "vrndscalepd", 0, 2102
    mnemonic_entry "vrndscaleph", 0, 2103
    mnemonic_entry "vrndscaleps", 0, 2104
    mnemonic_entry "vrndscalesd", 0, 2105
    mnemonic_entry "vrndscalesh", 0, 2106
    mnemonic_entry "vrndscaless", 0, 2107
    mnemonic_entry "vrsqrt14pd", 0, 2108
    mnemonic_entry "vrsqrt14ps", 0, 2109
    mnemonic_entry "vrsqrt14sd", 0, 2110
    mnemonic_entry "vrsqrt14ss", 0, 2111
    mnemonic_entry "vrsqrtph", 0, 2112
    mnemonic_entry "vrsqrtsh", 0, 2113
    mnemonic_entry "vscalefpd", 0, 2114
    mnemonic_entry "vscalefph", 0, 2115
    mnemonic_entry "vscalefps", 0, 2116
    mnemonic_entry "vscalefsd", 0, 2117
    mnemonic_entry "vscalefsh", 0, 2118
    mnemonic_entry "vscalefss", 0, 2119
    mnemonic_entry "vscatterdpd", 0, 2120
    mnemonic_entry "vscatterdps", 0, 2121
    mnemonic_entry "vscatterqpd", 0, 2122
    mnemonic_entry "vscatterqps", 0, 2123
    mnemonic_entry "vshuff32x4", 0, 2124
    mnemonic_entry "vshuff64x2", 0, 2125
    mnemonic_entry "vshufi32x4", 0, 2126
    mnemonic_entry "vshufi64x2", 0, 2127
    mnemonic_entry "vsqrtph", 0, 2128
    mnemonic_entry "vsqrtsh", 0, 2129
    mnemonic_entry "vsubph", 0, 2130
    mnemonic_entry "vsubsh", 0, 2131
    mnemonic_entry "vtestpd", 0, 2132
    mnemonic_entry "vtestps", 0, 2133
    mnemonic_entry "vucomish", 0, 2134
    mnemonic_entry "vzeroall", 0, 2135
    mnemonic_entry "vzeroupper", 0, 2136
    mnemonic_entry "wait", 0, 2137
    mnemonic_entry "wbinvd", 0, 2138
    mnemonic_entry "wbnoinvd", 0, 2139
    mnemonic_entry "wrfsbase", 0, 2140
    mnemonic_entry "wrgsbase", 0, 2141
    mnemonic_entry "wrmsr", 0, 2142
    mnemonic_entry "wrpkru", 0, 2143
    mnemonic_entry "wrssd", 0, 2144
    mnemonic_entry "wrssq", 0, 2145
    mnemonic_entry "wrussd", 0, 2146
    mnemonic_entry "wrussq", 0, 2147
    mnemonic_entry "xabort", 0, 2148
    mnemonic_entry "xacquire", 0, 2149
    mnemonic_entry "xadd", 0, 2150
    mnemonic_entry "xbegin", 0, 2151
    mnemonic_entry "xchg", 0, 2152
    mnemonic_entry "xend", 0, 2153
    mnemonic_entry "xgetbv", 0, 2154
    mnemonic_entry "xlat", 0, 2155
    mnemonic_entry "xlatb", 0, 2156
    mnemonic_entry "xor", 0, 2157
    mnemonic_entry "xorpd", 0, 2158
    mnemonic_entry "xorps", 0, 2159
    mnemonic_entry "xrelease", 0, 2160
    mnemonic_entry "xresldtrk", 0, 2161
    mnemonic_entry "xrstor", 0, 2162
    mnemonic_entry "xrstors", 0, 2163
    mnemonic_entry "xsave", 0, 2164
    mnemonic_entry "xsavec", 0, 2165
    mnemonic_entry "xsaveopt", 0, 2166
    mnemonic_entry "xsaves", 0, 2167
    mnemonic_entry "xsetbv", 0, 2168
    mnemonic_entry "xsusldtrk", 0, 2169
    mnemonic_entry "xtest", 0, 2170
    
    // ---- VMX / SVM Suite (Custom IDs) ----
    mnemonic_entry "vmcall", 0, 5000
    mnemonic_entry "vmlaunch", 0, 5001
    mnemonic_entry "vmresume", 0, 5002
    mnemonic_entry "vmxoff", 0, 5003
    mnemonic_entry "vmxon", 0, 5004
    mnemonic_entry "vmptrld", 0, 5005
    mnemonic_entry "vmptrst", 0, 5006
    mnemonic_entry "vmclear", 0, 5007
    mnemonic_entry "vmread", 0, 5008
    mnemonic_entry "vmwrite", 0, 5009
    mnemonic_entry "invept", 0, 5010
    mnemonic_entry "invvpid", 0, 5011
    
    // AMD-V (SVM) Suite
    mnemonic_entry "vmrun", 0, 5012
    mnemonic_entry "vmmcall", 0, 5013
    mnemonic_entry "vmload", 0, 5014
    mnemonic_entry "vmsave", 0, 5015
    mnemonic_entry "clgi", 0, 5016
    mnemonic_entry "stgi", 0, 5017
    mnemonic_entry "invlpga", 0, 5018
    mnemonic_entry "skinit", 0, 5019
    mnemonic_entry "clzero", 0, 5020

    // ---- Step 3 & 4: FMA3 & 8087 (Custom IDs) ----
    mnemonic_entry "fsin", 0, 5300
    mnemonic_entry "fcos", 0, 5301
    mnemonic_entry "fsincos", 0, 5302
    mnemonic_entry "fpatan", 0, 5303
    mnemonic_entry "fld1", 0, 5305
    mnemonic_entry "fldz", 0, 5306
    mnemonic_entry "fldpi", 0, 5307
    mnemonic_entry "fldln2", 0, 5308
    mnemonic_entry "fsave", 0, 5309
    mnemonic_entry "frstor", 0, 5310
    mnemonic_entry "fldenv", 0, 5311
    mnemonic_entry "fstenv", 0, 5312
    mnemonic_entry "flcw", 0, 5313
    mnemonic_entry "fstsw", 0, 5314
    mnemonic_entry "fucom", 0, 5315
    mnemonic_entry "fucompp", 0, 5316
    mnemonic_entry "fxtract", 0, 5317
    mnemonic_entry "fscale", 0, 5318
    
    // ---- AVX-512 Suite (Custom IDs) ----
    mnemonic_entry "vaesenc", 0, 5100
    mnemonic_entry "vaesdec", 0, 5101
    mnemonic_entry "vaesenclast", 0, 5102
    mnemonic_entry "vaesdeclast", 0, 5103
    mnemonic_entry "vpclmulqdq", 0, 5104
    mnemonic_entry "vmovdqa64", 0, 5105
    mnemonic_entry "vaddpd", 0, 5106

    // ---- Step 5: AVX-512 (Custom IDs) ----
    mnemonic_entry "kaddw", 0, 5400
    mnemonic_entry "kandw", 0, 5401
    mnemonic_entry "korw", 0, 5402
    mnemonic_entry "kxorw", 0, 5403
    mnemonic_entry "kmovw", 0, 5404
    mnemonic_entry "kunpckbw", 0, 5405
    mnemonic_entry "vgatherdpd", 0, 5406
    mnemonic_entry "vscatterdps", 0, 5407
    mnemonic_entry "vpconflictd", 0, 5408
    mnemonic_entry "vpconflictq", 0, 5409
    mnemonic_entry "vreducess", 0, 5410
    mnemonic_entry "vexp2ps", 0, 5411
    mnemonic_entry "vrcp14ps", 0, 5412

    // ---- Step 6: VNNI & BF16 (Custom IDs) ----
    mnemonic_entry "vpdpbusd", 0, 5500
    mnemonic_entry "vpdpwssd", 0, 5501
    mnemonic_entry "vdpbf16ps", 0, 5502
    mnemonic_entry "vcvtne2ps2bf16", 0, 5503

    // ---- Step 7: 3DNow! & XOP (Custom IDs) ----
    mnemonic_entry "femms", 0, 5600
    mnemonic_entry "pfadd", 0, 5601
    mnemonic_entry "pfcmpeq", 0, 5602
    mnemonic_entry "pfmax", 0, 5603
    mnemonic_entry "pfmin", 0, 5604
    mnemonic_entry "pfrcp", 0, 5605
    mnemonic_entry "pfrsqrt", 0, 5606
    mnemonic_entry "pi2fd", 0, 5607
    mnemonic_entry "vpmacssww", 0, 5608
    mnemonic_entry "vpmadcsswd", 0, 5609
    mnemonic_entry "vpperm", 0, 5610
    mnemonic_entry "vprotb", 0, 5611
    mnemonic_entry "vpshab", 0, 5612

    // ---- Step 8: SGX Sub-Leafs (Custom IDs) ----
    mnemonic_entry "eadd", 0, 5700
    mnemonic_entry "eblock", 0, 5701
    mnemonic_entry "ecreate", 0, 5702
    mnemonic_entry "einit", 0, 5703
    mnemonic_entry "eenter", 0, 5704
    mnemonic_entry "eresume", 0, 5705
    mnemonic_entry "egetkey", 0, 5706

    dq 0

global amd64_register_table
amd64_register_table:
    // ---- 64-bit GPRs ----
    compile_time_hash "rax", H_RAX
    dq H_RAX, (8 << 8) | REG_RAX
    compile_time_hash "rcx", H_RCX
    dq H_RCX, (8 << 8) | REG_RCX
    compile_time_hash "rdx", H_RDX
    dq H_RDX, (8 << 8) | REG_RDX
    compile_time_hash "rbx", H_RBX
    dq H_RBX, (8 << 8) | REG_RBX
    compile_time_hash "rsp", H_RSP
    dq H_RSP, (8 << 8) | REG_RSP
    compile_time_hash "rbp", H_RBP
    dq H_RBP, (8 << 8) | REG_RBP
    compile_time_hash "rsi", H_RSI
    dq H_RSI, (8 << 8) | REG_RSI
    compile_time_hash "rdi", H_RDI
    dq H_RDI, (8 << 8) | REG_RDI
    compile_time_hash "r8",  H_R8
    dq H_R8,  (8 << 8) | REG_R8
    compile_time_hash "r9",  H_R9
    dq H_R9,  (8 << 8) | REG_R9
    compile_time_hash "r10", H_R10
    dq H_R10, (8 << 8) | REG_R10
    compile_time_hash "r11", H_R11
    dq H_R11, (8 << 8) | REG_R11
    compile_time_hash "r12", H_R12
    dq H_R12, (8 << 8) | REG_R12
    compile_time_hash "r13", H_R13
    dq H_R13, (8 << 8) | REG_R13
    compile_time_hash "r14", H_R14
    dq H_R14, (8 << 8) | REG_R14
    compile_time_hash "r15", H_R15
    dq H_R15, (8 << 8) | REG_R15

    // ---- 32-bit GPRs ----
    compile_time_hash "eax", H_EAX
    dq H_EAX, (4 << 8) | REG_RAX
    compile_time_hash "ecx", H_ECX
    dq H_ECX, (4 << 8) | REG_RCX
    compile_time_hash "edx", H_EDX
    dq H_EDX, (4 << 8) | REG_RDX
    compile_time_hash "ebx", H_EBX
    dq H_EBX, (4 << 8) | REG_RBX
    compile_time_hash "esi", H_ESI
    dq H_ESI, (4 << 8) | REG_RSI
    compile_time_hash "edi", H_EDI
    dq H_EDI, (4 << 8) | REG_RDI
    compile_time_hash "esp", H_ESP
    dq H_ESP, (4 << 8) | REG_RSP
    compile_time_hash "ebp", H_EBP
    dq H_EBP, (4 << 8) | REG_RBP
    %assign i 8
    %rep 8
        compile_time_hash "r%[i]d", H_R%[i]D
        dq H_R%[i]D, (4 << 8) | %[i]
        %assign i i+1
    %endrep

    // ---- 16-bit GPRs ----
    compile_time_hash "ax", H_AX
    dq H_AX, (2 << 8) | REG_RAX
    compile_time_hash "cx", H_CX
    dq H_CX, (2 << 8) | REG_RCX
    compile_time_hash "dx", H_DX
    dq H_DX, (2 << 8) | REG_RDX
    compile_time_hash "bx", H_BX
    dq H_BX, (2 << 8) | REG_RBX
    compile_time_hash "si", H_SI
    dq H_SI, (2 << 8) | REG_RSI
    compile_time_hash "di", H_DI
    dq H_DI, (2 << 8) | REG_RDI
    compile_time_hash "sp", H_SP
    dq H_SP, (2 << 8) | REG_RSP
    compile_time_hash "bp", H_BP
    dq H_BP, (2 << 8) | REG_RBP
    %assign i 8
    %rep 8
        compile_time_hash "r%[i]w", H_R%[i]W
        dq H_R%[i]W, (2 << 8) | %[i]
        %assign i i+1
    %endrep

    // ---- 8-bit GPRs (Low) ----
    compile_time_hash "al", H_AL
    dq H_AL, (1 << 8) | REG_RAX
    compile_time_hash "cl", H_CL
    dq H_CL, (1 << 8) | REG_RCX
    compile_time_hash "dl", H_DL
    dq H_DL, (1 << 8) | REG_RDX
    compile_time_hash "bl", H_BL
    dq H_BL, (1 << 8) | REG_RBX
    compile_time_hash "sil", H_SIL
    dq H_SIL, (1 << 8) | REG_RSI
    compile_time_hash "dil", H_DIL
    dq H_DIL, (1 << 8) | REG_RDI
    compile_time_hash "spl", H_SPL
    dq H_SPL, (1 << 8) | REG_RSP
    compile_time_hash "bpl", H_BPL
    dq H_BPL, (1 << 8) | REG_RBP
    %assign i 8
    %rep 8
        compile_time_hash "r%[i]b", H_R%[i]B
        dq H_R%[i]B, (1 << 8) | %[i]
        %assign i i+1
    %endrep

    // ---- 8-bit GPRs (High) ----
    compile_time_hash "ah", H_AH
    dq H_AH, (1 << 16) | (1 << 8) | 4  ; is_high=1, size=1, ID=4
    compile_time_hash "ch", H_CH
    dq H_CH, (1 << 16) | (1 << 8) | 5  ; is_high=1, size=1, ID=5
    compile_time_hash "dh", H_DH
    dq H_DH, (1 << 16) | (1 << 8) | 6  ; is_high=1, size=1, ID=6
    compile_time_hash "bh", H_BH
    dq H_BH, (1 << 16) | (1 << 8) | 7  ; is_high=1, size=1, ID=7

    // ---- SIMD (XMM) ----
    %assign i 0
    // ---- SIMD (XMM/YMM/ZMM) ----
    %assign i 0
    %rep 32
        compile_time_hash "xmm%[i]", H_XMM%[i]
        dq H_XMM%[i], (16 << 8) | (80 + %[i])
        compile_time_hash "ymm%[i]", H_YMM%[i]
        dq H_YMM%[i], (32 << 8) | (80 + %[i])
        compile_time_hash "zmm%[i]", H_ZMM%[i]
        dq H_ZMM%[i], (64 << 8) | (80 + %[i])
        %assign i i+1
    %endrep

    // ---- Opmask (K0-K7) ----
    %assign i 0
    %rep 8
        compile_time_hash "k%[i]", H_K%[i]
        dq H_K%[i], (8 << 8) | (72 + %[i])
        %assign i i+1
    %endrep

    // ---- Control Registers (CR0-CR15) ----
    %assign i 0
    %rep 16
        compile_time_hash "cr%[i]", H_CR%[i]
        dq H_CR%[i], (8 << 8) | (32 + %[i])
        %assign i i+1
    %endrep

    // ---- Debug Registers (DR0-DR15) ----
    %assign i 0
    %rep 16
        compile_time_hash "dr%[i]", H_DR%[i]
        dq H_DR%[i], (8 << 8) | (48 + %[i])
        %assign i i+1
    %endrep

    // ---- Segments ----
    compile_time_hash "cs", H_CS
    dq H_CS, (2 << 8) | REG_CS
    compile_time_hash "ds", H_DS
    dq H_DS, (2 << 8) | REG_DS
    compile_time_hash "fs", H_FS
    dq H_FS, (2 << 8) | REG_FS
    compile_time_hash "gs", H_GS
    dq H_GS, (2 << 8) | REG_GS
    compile_time_hash "ss", H_SS
    dq H_SS, (2 << 8) | REG_SS

    dq 0
