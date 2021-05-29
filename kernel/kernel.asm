
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	72c78793          	addi	a5,a5,1836 # 80006790 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	a08080e7          	jalr	-1528(ra) # 80002b26 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	d98080e7          	jalr	-616(ra) # 80001f4a <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	554080e7          	jalr	1364(ra) # 80002716 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00003097          	auipc	ra,0x3
    80000202:	8d2080e7          	jalr	-1838(ra) # 80002ad0 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00003097          	auipc	ra,0x3
    800002e2:	89e080e7          	jalr	-1890(ra) # 80002b7c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	470080e7          	jalr	1136(ra) # 800028a2 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00031797          	auipc	a5,0x31
    80000468:	4b478793          	addi	a5,a5,1204 # 80031918 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	024080e7          	jalr	36(ra) # 800028a2 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	e0c080e7          	jalr	-500(ra) # 80002716 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00035797          	auipc	a5,0x35
    800009ee:	61678793          	addi	a5,a5,1558 # 80036000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00035517          	auipc	a0,0x35
    80000abe:	54650513          	addi	a0,a0,1350 # 80036000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	3d2080e7          	jalr	978(ra) # 80001f2e <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	3a0080e7          	jalr	928(ra) # 80001f2e <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	394080e7          	jalr	916(ra) # 80001f2e <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	37c080e7          	jalr	892(ra) # 80001f2e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	33c080e7          	jalr	828(ra) # 80001f2e <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	310080e7          	jalr	784(ra) # 80001f2e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	0aa080e7          	jalr	170(ra) # 80001f1e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	08e080e7          	jalr	142(ra) # 80001f1e <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	e0c080e7          	jalr	-500(ra) # 80002cbe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	916080e7          	jalr	-1770(ra) # 800067d0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	6a2080e7          	jalr	1698(ra) # 80002564 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	f4c080e7          	jalr	-180(ra) # 80001e6e <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	d6c080e7          	jalr	-660(ra) # 80002c96 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	d8c080e7          	jalr	-628(ra) # 80002cbe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	880080e7          	jalr	-1920(ra) # 800067ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	88e080e7          	jalr	-1906(ra) # 800067d0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	4ca080e7          	jalr	1226(ra) # 80003414 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	b5c080e7          	jalr	-1188(ra) # 80003aae <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	e1c080e7          	jalr	-484(ra) # 80004d76 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	990080e7          	jalr	-1648(ra) # 800068f2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	30e080e7          	jalr	782(ra) # 80002278 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00001097          	auipc	ra,0x1
    80001210:	bcc080e7          	jalr	-1076(ra) # 80001dd8 <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	e062                	sd	s8,0(sp)
    80001258:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000125a:	03459793          	slli	a5,a1,0x34
    8000125e:	eb85                	bnez	a5,8000128e <uvmunmap+0x4c>
    80001260:	89aa                	mv	s3,a0
    80001262:	892e                	mv	s2,a1
    80001264:	8c36                	mv	s8,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001266:	0632                	slli	a2,a2,0xc
    80001268:	00b60a33          	add	s4,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126c:	4b85                	li	s7,1
    }
    #ifndef NONE
    struct proc *p = myproc();
    struct page_metadata *pg;
    //unmap adress a: if it is in memory delete it from memory 
    if(p->pid > 2 && pagetable == p->pagetable && (*pte & PTE_V) && do_free){
    8000126e:	4a89                	li	s5,2
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001270:	6b05                	lui	s6,0x1
    80001272:	0745ed63          	bltu	a1,s4,800012ec <uvmunmap+0xaa>
      }
    } 
    #endif
    *pte = 0;
  }
}
    80001276:	60a6                	ld	ra,72(sp)
    80001278:	6406                	ld	s0,64(sp)
    8000127a:	74e2                	ld	s1,56(sp)
    8000127c:	7942                	ld	s2,48(sp)
    8000127e:	79a2                	ld	s3,40(sp)
    80001280:	7a02                	ld	s4,32(sp)
    80001282:	6ae2                	ld	s5,24(sp)
    80001284:	6b42                	ld	s6,16(sp)
    80001286:	6ba2                	ld	s7,8(sp)
    80001288:	6c02                	ld	s8,0(sp)
    8000128a:	6161                	addi	sp,sp,80
    8000128c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e5a50513          	addi	a0,a0,-422 # 800080e8 <digits+0xa8>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	294080e7          	jalr	660(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	e6250513          	addi	a0,a0,-414 # 80008100 <digits+0xc0>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	284080e7          	jalr	644(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ae:	00007517          	auipc	a0,0x7
    800012b2:	e6250513          	addi	a0,a0,-414 # 80008110 <digits+0xd0>
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	274080e7          	jalr	628(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012be:	00007517          	auipc	a0,0x7
    800012c2:	e6a50513          	addi	a0,a0,-406 # 80008128 <digits+0xe8>
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	264080e7          	jalr	612(ra) # 8000052a <panic>
    struct proc *p = myproc();
    800012ce:	00001097          	auipc	ra,0x1
    800012d2:	c7c080e7          	jalr	-900(ra) # 80001f4a <myproc>
    if(p->pid > 2 && pagetable == p->pagetable && (*pte & PTE_V) && do_free){
    800012d6:	591c                	lw	a5,48(a0)
    800012d8:	00fad563          	bge	s5,a5,800012e2 <uvmunmap+0xa0>
    800012dc:	693c                	ld	a5,80(a0)
    800012de:	05378563          	beq	a5,s3,80001328 <uvmunmap+0xe6>
    *pte = 0;
    800012e2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	995a                	add	s2,s2,s6
    800012e8:	f94977e3          	bgeu	s2,s4,80001276 <uvmunmap+0x34>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ec:	4601                	li	a2,0
    800012ee:	85ca                	mv	a1,s2
    800012f0:	854e                	mv	a0,s3
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	cb4080e7          	jalr	-844(ra) # 80000fa6 <walk>
    800012fa:	84aa                	mv	s1,a0
    800012fc:	d14d                	beqz	a0,8000129e <uvmunmap+0x5c>
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
    800012fe:	611c                	ld	a5,0(a0)
    80001300:	2017f713          	andi	a4,a5,513
    80001304:	d74d                	beqz	a4,800012ae <uvmunmap+0x6c>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001306:	3ff7f713          	andi	a4,a5,1023
    8000130a:	fb770ae3          	beq	a4,s7,800012be <uvmunmap+0x7c>
    if((*pte & PTE_V) && do_free){
    8000130e:	0017f713          	andi	a4,a5,1
    80001312:	df55                	beqz	a4,800012ce <uvmunmap+0x8c>
    80001314:	fa0c0de3          	beqz	s8,800012ce <uvmunmap+0x8c>
      uint64 pa = PTE2PA(*pte);
    80001318:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000131a:	00c79513          	slli	a0,a5,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6b8080e7          	jalr	1720(ra) # 800009d6 <kfree>
    80001326:	b765                	j	800012ce <uvmunmap+0x8c>
    if(p->pid > 2 && pagetable == p->pagetable && (*pte & PTE_V) && do_free){
    80001328:	609c                	ld	a5,0(s1)
    8000132a:	8b85                	andi	a5,a5,1
    8000132c:	c399                	beqz	a5,80001332 <uvmunmap+0xf0>
    8000132e:	020c1263          	bnez	s8,80001352 <uvmunmap+0x110>
    if(p->pid > 2 && pagetable == p->pagetable && (*pte & PTE_PG)){
    80001332:	609c                	ld	a5,0(s1)
    80001334:	2007f793          	andi	a5,a5,512
    80001338:	d7cd                	beqz	a5,800012e2 <uvmunmap+0xa0>
      for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000133a:	37050793          	addi	a5,a0,880
    8000133e:	57050693          	addi	a3,a0,1392
        if(pg->va == a){
    80001342:	6398                	ld	a4,0(a5)
    80001344:	05270563          	beq	a4,s2,8000138e <uvmunmap+0x14c>
      for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001348:	02078793          	addi	a5,a5,32
    8000134c:	fef69be3          	bne	a3,a5,80001342 <uvmunmap+0x100>
    80001350:	bf49                	j	800012e2 <uvmunmap+0xa0>
      for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001352:	17050793          	addi	a5,a0,368
    80001356:	37050693          	addi	a3,a0,880
        if(pg->va == a){
    8000135a:	6398                	ld	a4,0(a5)
    8000135c:	01270763          	beq	a4,s2,8000136a <uvmunmap+0x128>
      for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001360:	02078793          	addi	a5,a5,32
    80001364:	fef69be3          	bne	a3,a5,8000135a <uvmunmap+0x118>
    80001368:	b7e9                	j	80001332 <uvmunmap+0xf0>
          pg->state = 0;
    8000136a:	0007a423          	sw	zero,8(a5)
          pg->va = 0;
    8000136e:	0007b023          	sd	zero,0(a5)
          pg->age = 0;
    80001372:	0007b823          	sd	zero,16(a5)
          p->num_pages_in_psyc--;
    80001376:	57052783          	lw	a5,1392(a0)
    8000137a:	37fd                	addiw	a5,a5,-1
    8000137c:	56f52823          	sw	a5,1392(a0)
    if(p->pid > 2 && pagetable == p->pagetable && (*pte & PTE_PG)){
    80001380:	591c                	lw	a5,48(a0)
    80001382:	f6fad0e3          	bge	s5,a5,800012e2 <uvmunmap+0xa0>
    80001386:	693c                	ld	a5,80(a0)
    80001388:	fb3785e3          	beq	a5,s3,80001332 <uvmunmap+0xf0>
    8000138c:	bf99                	j	800012e2 <uvmunmap+0xa0>
          pg->state = 0;
    8000138e:	0007a423          	sw	zero,8(a5)
          pg->va = 0;
    80001392:	0007b023          	sd	zero,0(a5)
          pg->age = 0;
    80001396:	0007b823          	sd	zero,16(a5)
          p->num_pages_in_swapfile--;
    8000139a:	57452783          	lw	a5,1396(a0)
    8000139e:	37fd                	addiw	a5,a5,-1
    800013a0:	56f52a23          	sw	a5,1396(a0)
          break;
    800013a4:	bf3d                	j	800012e2 <uvmunmap+0xa0>

00000000800013a6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	722080e7          	jalr	1826(ra) # 80000ad2 <kalloc>
    800013b8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ba:	c519                	beqz	a0,800013c8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013bc:	6605                	lui	a2,0x1
    800013be:	4581                	li	a1,0
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	8fe080e7          	jalr	-1794(ra) # 80000cbe <memset>
  return pagetable;
}
    800013c8:	8526                	mv	a0,s1
    800013ca:	60e2                	ld	ra,24(sp)
    800013cc:	6442                	ld	s0,16(sp)
    800013ce:	64a2                	ld	s1,8(sp)
    800013d0:	6105                	addi	sp,sp,32
    800013d2:	8082                	ret

00000000800013d4 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d4:	7179                	addi	sp,sp,-48
    800013d6:	f406                	sd	ra,40(sp)
    800013d8:	f022                	sd	s0,32(sp)
    800013da:	ec26                	sd	s1,24(sp)
    800013dc:	e84a                	sd	s2,16(sp)
    800013de:	e44e                	sd	s3,8(sp)
    800013e0:	e052                	sd	s4,0(sp)
    800013e2:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e4:	6785                	lui	a5,0x1
    800013e6:	04f67863          	bgeu	a2,a5,80001436 <uvminit+0x62>
    800013ea:	8a2a                	mv	s4,a0
    800013ec:	89ae                	mv	s3,a1
    800013ee:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	6e2080e7          	jalr	1762(ra) # 80000ad2 <kalloc>
    800013f8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	8c0080e7          	jalr	-1856(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001406:	4779                	li	a4,30
    80001408:	86ca                	mv	a3,s2
    8000140a:	6605                	lui	a2,0x1
    8000140c:	4581                	li	a1,0
    8000140e:	8552                	mv	a0,s4
    80001410:	00000097          	auipc	ra,0x0
    80001414:	c7e080e7          	jalr	-898(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001418:	8626                	mv	a2,s1
    8000141a:	85ce                	mv	a1,s3
    8000141c:	854a                	mv	a0,s2
    8000141e:	00000097          	auipc	ra,0x0
    80001422:	8fc080e7          	jalr	-1796(ra) # 80000d1a <memmove>
}
    80001426:	70a2                	ld	ra,40(sp)
    80001428:	7402                	ld	s0,32(sp)
    8000142a:	64e2                	ld	s1,24(sp)
    8000142c:	6942                	ld	s2,16(sp)
    8000142e:	69a2                	ld	s3,8(sp)
    80001430:	6a02                	ld	s4,0(sp)
    80001432:	6145                	addi	sp,sp,48
    80001434:	8082                	ret
    panic("inituvm: more than a page");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d0a50513          	addi	a0,a0,-758 # 80008140 <digits+0x100>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	0ec080e7          	jalr	236(ra) # 8000052a <panic>

0000000080001446 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001446:	1101                	addi	sp,sp,-32
    80001448:	ec06                	sd	ra,24(sp)
    8000144a:	e822                	sd	s0,16(sp)
    8000144c:	e426                	sd	s1,8(sp)
    8000144e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001450:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001452:	00b67d63          	bgeu	a2,a1,8000146c <uvmdealloc+0x26>
    80001456:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001458:	6785                	lui	a5,0x1
    8000145a:	17fd                	addi	a5,a5,-1
    8000145c:	00f60733          	add	a4,a2,a5
    80001460:	767d                	lui	a2,0xfffff
    80001462:	8f71                	and	a4,a4,a2
    80001464:	97ae                	add	a5,a5,a1
    80001466:	8ff1                	and	a5,a5,a2
    80001468:	00f76863          	bltu	a4,a5,80001478 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000146c:	8526                	mv	a0,s1
    8000146e:	60e2                	ld	ra,24(sp)
    80001470:	6442                	ld	s0,16(sp)
    80001472:	64a2                	ld	s1,8(sp)
    80001474:	6105                	addi	sp,sp,32
    80001476:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001478:	8f99                	sub	a5,a5,a4
    8000147a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000147c:	4685                	li	a3,1
    8000147e:	0007861b          	sext.w	a2,a5
    80001482:	85ba                	mv	a1,a4
    80001484:	00000097          	auipc	ra,0x0
    80001488:	dbe080e7          	jalr	-578(ra) # 80001242 <uvmunmap>
    8000148c:	b7c5                	j	8000146c <uvmdealloc+0x26>

000000008000148e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000148e:	7179                	addi	sp,sp,-48
    80001490:	f406                	sd	ra,40(sp)
    80001492:	f022                	sd	s0,32(sp)
    80001494:	ec26                	sd	s1,24(sp)
    80001496:	e84a                	sd	s2,16(sp)
    80001498:	e44e                	sd	s3,8(sp)
    8000149a:	e052                	sd	s4,0(sp)
    8000149c:	1800                	addi	s0,sp,48
    8000149e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014a0:	84aa                	mv	s1,a0
    800014a2:	6905                	lui	s2,0x1
    800014a4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014a6:	4985                	li	s3,1
    800014a8:	a821                	j	800014c0 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014aa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ac:	0532                	slli	a0,a0,0xc
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	fe0080e7          	jalr	-32(ra) # 8000148e <freewalk>
      pagetable[i] = 0;
    800014b6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ba:	04a1                	addi	s1,s1,8
    800014bc:	03248163          	beq	s1,s2,800014de <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014c0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c2:	00f57793          	andi	a5,a0,15
    800014c6:	ff3782e3          	beq	a5,s3,800014aa <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ca:	8905                	andi	a0,a0,1
    800014cc:	d57d                	beqz	a0,800014ba <freewalk+0x2c>
      panic("freewalk: leaf");
    800014ce:	00007517          	auipc	a0,0x7
    800014d2:	c9250513          	addi	a0,a0,-878 # 80008160 <digits+0x120>
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	054080e7          	jalr	84(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014de:	8552                	mv	a0,s4
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	4f6080e7          	jalr	1270(ra) # 800009d6 <kfree>
}
    800014e8:	70a2                	ld	ra,40(sp)
    800014ea:	7402                	ld	s0,32(sp)
    800014ec:	64e2                	ld	s1,24(sp)
    800014ee:	6942                	ld	s2,16(sp)
    800014f0:	69a2                	ld	s3,8(sp)
    800014f2:	6a02                	ld	s4,0(sp)
    800014f4:	6145                	addi	sp,sp,48
    800014f6:	8082                	ret

00000000800014f8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014f8:	1101                	addi	sp,sp,-32
    800014fa:	ec06                	sd	ra,24(sp)
    800014fc:	e822                	sd	s0,16(sp)
    800014fe:	e426                	sd	s1,8(sp)
    80001500:	1000                	addi	s0,sp,32
    80001502:	84aa                	mv	s1,a0
  if(sz > 0)
    80001504:	e999                	bnez	a1,8000151a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001506:	8526                	mv	a0,s1
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	f86080e7          	jalr	-122(ra) # 8000148e <freewalk>
}
    80001510:	60e2                	ld	ra,24(sp)
    80001512:	6442                	ld	s0,16(sp)
    80001514:	64a2                	ld	s1,8(sp)
    80001516:	6105                	addi	sp,sp,32
    80001518:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000151a:	6605                	lui	a2,0x1
    8000151c:	167d                	addi	a2,a2,-1
    8000151e:	962e                	add	a2,a2,a1
    80001520:	4685                	li	a3,1
    80001522:	8231                	srli	a2,a2,0xc
    80001524:	4581                	li	a1,0
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	d1c080e7          	jalr	-740(ra) # 80001242 <uvmunmap>
    8000152e:	bfe1                	j	80001506 <uvmfree+0xe>

0000000080001530 <uvmcopy>:
  pte_t *npte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001530:	10060163          	beqz	a2,80001632 <uvmcopy+0x102>
{
    80001534:	715d                	addi	sp,sp,-80
    80001536:	e486                	sd	ra,72(sp)
    80001538:	e0a2                	sd	s0,64(sp)
    8000153a:	fc26                	sd	s1,56(sp)
    8000153c:	f84a                	sd	s2,48(sp)
    8000153e:	f44e                	sd	s3,40(sp)
    80001540:	f052                	sd	s4,32(sp)
    80001542:	ec56                	sd	s5,24(sp)
    80001544:	e85a                	sd	s6,16(sp)
    80001546:	e45e                	sd	s7,8(sp)
    80001548:	e062                	sd	s8,0(sp)
    8000154a:	0880                	addi	s0,sp,80
    8000154c:	8aaa                	mv	s5,a0
    8000154e:	8bae                	mv	s7,a1
    80001550:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001552:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if(!(*pte & PTE_V) && !(*pte & PTE_PG))
      panic("uvmcopy: page not present");
    if(!(*pte & PTE_V) && *pte & PTE_PG){
    80001554:	20000b13          	li	s6,512
    80001558:	a091                	j	8000159c <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    8000155a:	00007517          	auipc	a0,0x7
    8000155e:	c1650513          	addi	a0,a0,-1002 # 80008170 <digits+0x130>
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	fc8080e7          	jalr	-56(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    8000156a:	00007517          	auipc	a0,0x7
    8000156e:	c2650513          	addi	a0,a0,-986 # 80008190 <digits+0x150>
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	fb8080e7          	jalr	-72(ra) # 8000052a <panic>
      npte = walk(new, i, 1);
    8000157a:	4605                	li	a2,1
    8000157c:	85ca                	mv	a1,s2
    8000157e:	855e                	mv	a0,s7
    80001580:	00000097          	auipc	ra,0x0
    80001584:	a26080e7          	jalr	-1498(ra) # 80000fa6 <walk>
      *npte |= PTE_FLAGS(*pte);
    80001588:	609c                	ld	a5,0(s1)
    8000158a:	3ff7f713          	andi	a4,a5,1023
    8000158e:	611c                	ld	a5,0(a0)
    80001590:	8fd9                	or	a5,a5,a4
    80001592:	e11c                	sd	a5,0(a0)
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	6785                	lui	a5,0x1
    80001596:	993e                	add	s2,s2,a5
    80001598:	09497063          	bgeu	s2,s4,80001618 <uvmcopy+0xe8>
    if((pte = walk(old, i, 0)) == 0)
    8000159c:	4601                	li	a2,0
    8000159e:	85ca                	mv	a1,s2
    800015a0:	8556                	mv	a0,s5
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	a04080e7          	jalr	-1532(ra) # 80000fa6 <walk>
    800015aa:	84aa                	mv	s1,a0
    800015ac:	d55d                	beqz	a0,8000155a <uvmcopy+0x2a>
    if(!(*pte & PTE_V) && !(*pte & PTE_PG))
    800015ae:	6118                	ld	a4,0(a0)
    800015b0:	20177793          	andi	a5,a4,513
    800015b4:	dbdd                	beqz	a5,8000156a <uvmcopy+0x3a>
    if(!(*pte & PTE_V) && *pte & PTE_PG){
    800015b6:	fd6782e3          	beq	a5,s6,8000157a <uvmcopy+0x4a>
      continue; //if the page was swaped to file continue
    }
    if(!(*pte & PTE_V)) continue;
    800015ba:	00177793          	andi	a5,a4,1
    800015be:	dbf9                	beqz	a5,80001594 <uvmcopy+0x64>
    //if the page in memory do this:
    pa = PTE2PA(*pte);
    800015c0:	00a75593          	srli	a1,a4,0xa
    800015c4:	00c59c13          	slli	s8,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	506080e7          	jalr	1286(ra) # 80000ad2 <kalloc>
    800015d4:	89aa                	mv	s3,a0
    800015d6:	c515                	beqz	a0,80001602 <uvmcopy+0xd2>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d8:	6605                	lui	a2,0x1
    800015da:	85e2                	mv	a1,s8
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	73e080e7          	jalr	1854(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e4:	8726                	mv	a4,s1
    800015e6:	86ce                	mv	a3,s3
    800015e8:	6605                	lui	a2,0x1
    800015ea:	85ca                	mv	a1,s2
    800015ec:	855e                	mv	a0,s7
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	aa0080e7          	jalr	-1376(ra) # 8000108e <mappages>
    800015f6:	dd59                	beqz	a0,80001594 <uvmcopy+0x64>
      kfree(mem);
    800015f8:	854e                	mv	a0,s3
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	3dc080e7          	jalr	988(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001602:	4685                	li	a3,1
    80001604:	00c95613          	srli	a2,s2,0xc
    80001608:	4581                	li	a1,0
    8000160a:	855e                	mv	a0,s7
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	c36080e7          	jalr	-970(ra) # 80001242 <uvmunmap>
  return -1;
    80001614:	557d                	li	a0,-1
    80001616:	a011                	j	8000161a <uvmcopy+0xea>
  return 0;
    80001618:	4501                	li	a0,0
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6c02                	ld	s8,0(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	966080e7          	jalr	-1690(ra) # 80000fa6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b5850513          	addi	a0,a0,-1192 # 800081b0 <digits+0x170>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	eca080e7          	jalr	-310(ra) # 8000052a <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	67e080e7          	jalr	1662(ra) # 80000d1a <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	992080e7          	jalr	-1646(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	5f0080e7          	jalr	1520(ra) # 80000d1a <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	904080e7          	jalr	-1788(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	872080e7          	jalr	-1934(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffc9000>
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <find_free_index_in_memory_array>:

int find_free_index_in_memory_array(){
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e406                	sd	ra,8(sp)
    8000183a:	e022                	sd	s0,0(sp)
    8000183c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	70c080e7          	jalr	1804(ra) # 80001f4a <myproc>
  struct page_metadata *pg;
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001846:	17050613          	addi	a2,a0,368
    8000184a:	37050693          	addi	a3,a0,880
    8000184e:	87b2                	mv	a5,a2
    if(!pg->state){
    80001850:	4798                	lw	a4,8(a5)
    80001852:	cb11                	beqz	a4,80001866 <find_free_index_in_memory_array+0x30>
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001854:	02078793          	addi	a5,a5,32
    80001858:	fed79ce3          	bne	a5,a3,80001850 <find_free_index_in_memory_array+0x1a>
      return (int)(pg - p->pages_in_memory);
    }
  }
  return -1;
    8000185c:	557d                	li	a0,-1
}
    8000185e:	60a2                	ld	ra,8(sp)
    80001860:	6402                	ld	s0,0(sp)
    80001862:	0141                	addi	sp,sp,16
    80001864:	8082                	ret
      return (int)(pg - p->pages_in_memory);
    80001866:	40c78533          	sub	a0,a5,a2
    8000186a:	8515                	srai	a0,a0,0x5
    8000186c:	2501                	sext.w	a0,a0
    8000186e:	bfc5                	j	8000185e <find_free_index_in_memory_array+0x28>

0000000080001870 <update_age>:


void update_age(struct proc* p){
    80001870:	7179                	addi	sp,sp,-48
    80001872:	f406                	sd	ra,40(sp)
    80001874:	f022                	sd	s0,32(sp)
    80001876:	ec26                	sd	s1,24(sp)
    80001878:	e84a                	sd	s2,16(sp)
    8000187a:	e44e                	sd	s3,8(sp)
    8000187c:	e052                	sd	s4,0(sp)
    8000187e:	1800                	addi	s0,sp,48
    80001880:	89aa                	mv	s3,a0
  struct page_metadata *pg;
  pte_t* pte;
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001882:	17050493          	addi	s1,a0,368
    80001886:	37050913          	addi	s2,a0,880
      if(*pte & PTE_A){
        //When a page got accessed (check the status of the PTE_A), 
        //the counter isshifted right by one bit, 
        //and then the digit 1 is added to the most significant bit
        pg->age = (pg->age >> 1);
        pg->age |= (0x8000000000000000);
    8000188a:	5a7d                	li	s4,-1
    8000188c:	1a7e                	slli	s4,s4,0x3f
    8000188e:	a821                	j	800018a6 <update_age+0x36>
      }
      else{
        //If a page remained without visits, the counter is just shifted right by one bit 
        pg->age = (pg->age >> 1); 
    80001890:	689c                	ld	a5,16(s1)
    80001892:	8385                	srli	a5,a5,0x1
    80001894:	e89c                	sd	a5,16(s1)
      }
      #ifdef YES
      //printf("cleared pte_A for page num =%d\n",(pg - p->pages_in_memory));
      #endif
      *pte &= ~ PTE_A; //turn off pte_a bit
    80001896:	611c                	ld	a5,0(a0)
    80001898:	fbf7f793          	andi	a5,a5,-65
    8000189c:	e11c                	sd	a5,0(a0)
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    8000189e:	02048493          	addi	s1,s1,32
    800018a2:	02990563          	beq	s2,s1,800018cc <update_age+0x5c>
    if(pg->state){
    800018a6:	449c                	lw	a5,8(s1)
    800018a8:	dbfd                	beqz	a5,8000189e <update_age+0x2e>
      pte = walk(p->pagetable, pg->va, 0);
    800018aa:	4601                	li	a2,0
    800018ac:	608c                	ld	a1,0(s1)
    800018ae:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	6f4080e7          	jalr	1780(ra) # 80000fa6 <walk>
      if(*pte & PTE_A){
    800018ba:	611c                	ld	a5,0(a0)
    800018bc:	0407f793          	andi	a5,a5,64
    800018c0:	dbe1                	beqz	a5,80001890 <update_age+0x20>
        pg->age = (pg->age >> 1);
    800018c2:	689c                	ld	a5,16(s1)
    800018c4:	8385                	srli	a5,a5,0x1
        pg->age |= (0x8000000000000000);
    800018c6:	0147e7b3          	or	a5,a5,s4
    800018ca:	b7e9                	j	80001894 <update_age+0x24>
    }
  }
}
    800018cc:	70a2                	ld	ra,40(sp)
    800018ce:	7402                	ld	s0,32(sp)
    800018d0:	64e2                	ld	s1,24(sp)
    800018d2:	6942                	ld	s2,16(sp)
    800018d4:	69a2                	ld	s3,8(sp)
    800018d6:	6a02                	ld	s4,0(sp)
    800018d8:	6145                	addi	sp,sp,48
    800018da:	8082                	ret

00000000800018dc <get_page_nfua>:

int get_page_nfua(){
    800018dc:	1141                	addi	sp,sp,-16
    800018de:	e406                	sd	ra,8(sp)
    800018e0:	e022                	sd	s0,0(sp)
    800018e2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800018e4:	00000097          	auipc	ra,0x0
    800018e8:	666080e7          	jalr	1638(ra) # 80001f4a <myproc>
    800018ec:	85aa                	mv	a1,a0
  struct page_metadata *pg;
  uint64 min_age = ~0;
  int min_age_index = 1;
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800018ee:	19050793          	addi	a5,a0,400
    800018f2:	37050693          	addi	a3,a0,880
  int min_age_index = 1;
    800018f6:	4505                	li	a0,1
  uint64 min_age = ~0;
    800018f8:	567d                	li	a2,-1
    if(pg->state && pg->age < min_age){
      #ifdef YES
      printf("min_age was = %p, now= %p, array index = %d\n", min_age, pg->age, (pg - p->pages_in_memory));
      #endif
      min_age = pg->age;
      min_age_index = (int)(pg - p->pages_in_memory);
    800018fa:	17058593          	addi	a1,a1,368 # 4000170 <_entry-0x7bfffe90>
    800018fe:	a029                	j	80001908 <get_page_nfua+0x2c>
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001900:	02078793          	addi	a5,a5,32
    80001904:	00f68d63          	beq	a3,a5,8000191e <get_page_nfua+0x42>
    if(pg->state && pg->age < min_age){
    80001908:	4798                	lw	a4,8(a5)
    8000190a:	db7d                	beqz	a4,80001900 <get_page_nfua+0x24>
    8000190c:	6b98                	ld	a4,16(a5)
    8000190e:	fec779e3          	bgeu	a4,a2,80001900 <get_page_nfua+0x24>
      min_age_index = (int)(pg - p->pages_in_memory);
    80001912:	40b78533          	sub	a0,a5,a1
    80001916:	8515                	srai	a0,a0,0x5
    80001918:	2501                	sext.w	a0,a0
      min_age = pg->age;
    8000191a:	863a                	mv	a2,a4
    8000191c:	b7d5                	j	80001900 <get_page_nfua+0x24>
    }
  }
  return min_age_index;
}
    8000191e:	60a2                	ld	ra,8(sp)
    80001920:	6402                	ld	s0,0(sp)
    80001922:	0141                	addi	sp,sp,16
    80001924:	8082                	ret

0000000080001926 <get_page_scfifo>:

int get_page_scfifo(){
    80001926:	7139                	addi	sp,sp,-64
    80001928:	fc06                	sd	ra,56(sp)
    8000192a:	f822                	sd	s0,48(sp)
    8000192c:	f426                	sd	s1,40(sp)
    8000192e:	f04a                	sd	s2,32(sp)
    80001930:	ec4e                	sd	s3,24(sp)
    80001932:	e852                	sd	s4,16(sp)
    80001934:	e456                	sd	s5,8(sp)
    80001936:	e05a                	sd	s6,0(sp)
    80001938:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000193a:	00000097          	auipc	ra,0x0
    8000193e:	610080e7          	jalr	1552(ra) # 80001f4a <myproc>
    80001942:	89aa                	mv	s3,a0
  struct page_metadata *pg;
  uint64 min_creation_time = (uint64)~0;
  int min_creation_index = 1;
    80001944:	37050913          	addi	s2,a0,880

  findIndex:
  min_creation_time = (uint64)~0;
  min_creation_index = 1;
    80001948:	4b05                	li	s6,1
  min_creation_time = (uint64)~0;
    8000194a:	5afd                	li	s5,-1


  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    if(pg->state && pg->creationOrder<= min_creation_time){
      min_creation_index=(int)(pg - p->pages_in_memory);
    8000194c:	17050a13          	addi	s4,a0,368
    80001950:	a8b1                	j	800019ac <get_page_scfifo+0x86>
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    80001952:	02078793          	addi	a5,a5,32
    80001956:	00f90e63          	beq	s2,a5,80001972 <get_page_scfifo+0x4c>
    if(pg->state && pg->creationOrder<= min_creation_time){
    8000195a:	4798                	lw	a4,8(a5)
    8000195c:	db7d                	beqz	a4,80001952 <get_page_scfifo+0x2c>
    8000195e:	6f98                	ld	a4,24(a5)
    80001960:	fee6e9e3          	bltu	a3,a4,80001952 <get_page_scfifo+0x2c>
      min_creation_index=(int)(pg - p->pages_in_memory);
    80001964:	414786b3          	sub	a3,a5,s4
    80001968:	8695                	srai	a3,a3,0x5
    8000196a:	0006849b          	sext.w	s1,a3
      min_creation_time=pg->creationOrder;
    8000196e:	86ba                	mv	a3,a4
    80001970:	b7cd                	j	80001952 <get_page_scfifo+0x2c>
    }
  }
  pte_t* pte=walk(p->pagetable,p->pages_in_memory[min_creation_index].va,0); // return addr
    80001972:	00549793          	slli	a5,s1,0x5
    80001976:	97ce                	add	a5,a5,s3
    80001978:	4601                	li	a2,0
    8000197a:	1707b583          	ld	a1,368(a5)
    8000197e:	0509b503          	ld	a0,80(s3)
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	624080e7          	jalr	1572(ra) # 80000fa6 <walk>
  if((*pte & PTE_A)!=0){ // give second chance 
    8000198a:	611c                	ld	a5,0(a0)
    8000198c:	0407f713          	andi	a4,a5,64
    80001990:	c31d                	beqz	a4,800019b6 <get_page_scfifo+0x90>
    *pte &=~ PTE_A; // trun off the access flag
    80001992:	fbf7f793          	andi	a5,a5,-65
    80001996:	e11c                	sd	a5,0(a0)
    p->pages_in_memory[min_creation_index].creationOrder= ++p->creationTimeGenerator; // first ++ generator then update the pg creation time  
    80001998:	5789b703          	ld	a4,1400(s3)
    8000199c:	0705                	addi	a4,a4,1
    8000199e:	56e9bc23          	sd	a4,1400(s3)
    800019a2:	00c48793          	addi	a5,s1,12
    800019a6:	0796                	slli	a5,a5,0x5
    800019a8:	97ce                	add	a5,a5,s3
    800019aa:	e798                	sd	a4,8(a5)
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    800019ac:	19098793          	addi	a5,s3,400
  min_creation_index = 1;
    800019b0:	84da                	mv	s1,s6
  min_creation_time = (uint64)~0;
    800019b2:	86d6                	mv	a3,s5
    800019b4:	b75d                	j	8000195a <get_page_scfifo+0x34>
    goto findIndex; // find again 
  }
  // if got here then we found pg with min time that PTE_A is turned off
  return min_creation_index;
}
    800019b6:	8526                	mv	a0,s1
    800019b8:	70e2                	ld	ra,56(sp)
    800019ba:	7442                	ld	s0,48(sp)
    800019bc:	74a2                	ld	s1,40(sp)
    800019be:	7902                	ld	s2,32(sp)
    800019c0:	69e2                	ld	s3,24(sp)
    800019c2:	6a42                	ld	s4,16(sp)
    800019c4:	6aa2                	ld	s5,8(sp)
    800019c6:	6b02                	ld	s6,0(sp)
    800019c8:	6121                	addi	sp,sp,64
    800019ca:	8082                	ret

00000000800019cc <get_page_lapa>:

int get_page_lapa(){
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e406                	sd	ra,8(sp)
    800019d0:	e022                	sd	s0,0(sp)
    800019d2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	576080e7          	jalr	1398(ra) # 80001f4a <myproc>
    800019dc:	87aa                	mv	a5,a0
  struct page_metadata *pg;
  int min_number_of_1=64;
  int index_with_min_1=-1;
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800019de:	19050613          	addi	a2,a0,400
    800019e2:	37050e13          	addi	t3,a0,880
  int index_with_min_1=-1;
    800019e6:	557d                	li	a0,-1
  int min_number_of_1=64;
    800019e8:	04000593          	li	a1,64
    int counter=0,stoploop=0;
    if(pg->state){
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    800019ec:	4f01                	li	t5,0
          uint64 mask = 1 << i;
    800019ee:	4885                	li	a7,1
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    800019f0:	04000313          	li	t1,64
          if(counter>min_number_of_1) // in case count is bigger than current min 
            stoploop=1;           // stop counting and break from loop
        }
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
          min_number_of_1=counter;
          index_with_min_1=(int)(pg - p->pages_in_memory);
    800019f4:	17078e93          	addi	t4,a5,368
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    800019f8:	5ffd                	li	t6,-1
    800019fa:	a805                	j	80001a2a <get_page_lapa+0x5e>
          if(counter>min_number_of_1) // in case count is bigger than current min 
    800019fc:	02d5ce63          	blt	a1,a3,80001a38 <get_page_lapa+0x6c>
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001a00:	2705                	addiw	a4,a4,1
    80001a02:	00670963          	beq	a4,t1,80001a14 <get_page_lapa+0x48>
          uint64 mask = 1 << i;
    80001a06:	00e897bb          	sllw	a5,a7,a4
          if((pg->age & mask)!=0)// if 1 is found 
    80001a0a:	0107f7b3          	and	a5,a5,a6
    80001a0e:	d7fd                	beqz	a5,800019fc <get_page_lapa+0x30>
              counter++;
    80001a10:	2685                	addiw	a3,a3,1
    80001a12:	b7ed                	j	800019fc <get_page_lapa+0x30>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001a14:	02b6d263          	bge	a3,a1,80001a38 <get_page_lapa+0x6c>
          index_with_min_1=(int)(pg - p->pages_in_memory);
    80001a18:	41d60533          	sub	a0,a2,t4
    80001a1c:	8515                	srai	a0,a0,0x5
    80001a1e:	2501                	sext.w	a0,a0
    80001a20:	85b6                	mv	a1,a3
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001a22:	02060613          	addi	a2,a2,32 # 1020 <_entry-0x7fffefe0>
    80001a26:	01c60e63          	beq	a2,t3,80001a42 <get_page_lapa+0x76>
    if(pg->state){
    80001a2a:	461c                	lw	a5,8(a2)
    80001a2c:	dbfd                	beqz	a5,80001a22 <get_page_lapa+0x56>
          if((pg->age & mask)!=0)// if 1 is found 
    80001a2e:	01063803          	ld	a6,16(a2)
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001a32:	877a                	mv	a4,t5
    int counter=0,stoploop=0;
    80001a34:	86fa                	mv	a3,t5
    80001a36:	bfc1                	j	80001a06 <get_page_lapa+0x3a>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001a38:	fff515e3          	bne	a0,t6,80001a22 <get_page_lapa+0x56>
    80001a3c:	feb693e3          	bne	a3,a1,80001a22 <get_page_lapa+0x56>
    80001a40:	bfe1                	j	80001a18 <get_page_lapa+0x4c>
        }
      }
    }
    return index_with_min_1;
}
    80001a42:	60a2                	ld	ra,8(sp)
    80001a44:	6402                	ld	s0,0(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <get_page_by_alg>:
// get page that will be swaped out (Task 2)
// Returns page index in pages_in_memory array, this page will be swapped out
int get_page_by_alg(){
    80001a4a:	1141                	addi	sp,sp,-16
    80001a4c:	e406                	sd	ra,8(sp)
    80001a4e:	e022                	sd	s0,0(sp)
    80001a50:	0800                	addi	s0,sp,16
  #ifdef SCFIFO
  return get_page_scfifo();
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	ed4080e7          	jalr	-300(ra) # 80001926 <get_page_scfifo>
  return get_page_lapa();
  #endif
  #ifdef NONE
  return 1; //will never got here
  #endif
}
    80001a5a:	60a2                	ld	ra,8(sp)
    80001a5c:	6402                	ld	s0,0(sp)
    80001a5e:	0141                	addi	sp,sp,16
    80001a60:	8082                	ret

0000000080001a62 <swap_into_file>:


//Chose page to remove from main memory (using one of task2 algorithms) 
//and swap this page into file
void swap_into_file(pagetable_t pagetable){
    80001a62:	7139                	addi	sp,sp,-64
    80001a64:	fc06                	sd	ra,56(sp)
    80001a66:	f822                	sd	s0,48(sp)
    80001a68:	f426                	sd	s1,40(sp)
    80001a6a:	f04a                	sd	s2,32(sp)
    80001a6c:	ec4e                	sd	s3,24(sp)
    80001a6e:	e852                	sd	s4,16(sp)
    80001a70:	e456                	sd	s5,8(sp)
    80001a72:	e05a                	sd	s6,0(sp)
    80001a74:	0080                	addi	s0,sp,64
    80001a76:	8a2a                	mv	s4,a0
  #ifdef YES
  printf("too much psyc pages: lets swap into file page\n");
  #endif

  struct proc *p = myproc();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	4d2080e7          	jalr	1234(ra) # 80001f4a <myproc>
  if(p->num_pages_in_psyc + p->num_pages_in_swapfile == MAX_TOTAL_PAGES){
    80001a80:	57052783          	lw	a5,1392(a0)
    80001a84:	57452703          	lw	a4,1396(a0)
    80001a88:	9fb9                	addw	a5,a5,a4
    80001a8a:	02000713          	li	a4,32
    80001a8e:	02e78c63          	beq	a5,a4,80001ac6 <swap_into_file+0x64>
    80001a92:	892a                	mv	s2,a0
  return get_page_scfifo();
    80001a94:	00000097          	auipc	ra,0x0
    80001a98:	e92080e7          	jalr	-366(ra) # 80001926 <get_page_scfifo>

  //find free space in swaped pages array,
  //add selected to swap out page to this array 
  //and write this page to swapfile.
  struct page_metadata *pg;
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001a9c:	37090a93          	addi	s5,s2,880 # 1370 <_entry-0x7fffec90>
    80001aa0:	57090713          	addi	a4,s2,1392
    80001aa4:	84d6                	mv	s1,s5
    if(!pg->state){
    80001aa6:	449c                	lw	a5,8(s1)
    80001aa8:	c79d                	beqz	a5,80001ad6 <swap_into_file+0x74>
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001aaa:	02048493          	addi	s1,s1,32
    80001aae:	fee49ce3          	bne	s1,a4,80001aa6 <swap_into_file+0x44>
      sfence_vma(); 
      break;
    }
  }

}
    80001ab2:	70e2                	ld	ra,56(sp)
    80001ab4:	7442                	ld	s0,48(sp)
    80001ab6:	74a2                	ld	s1,40(sp)
    80001ab8:	7902                	ld	s2,32(sp)
    80001aba:	69e2                	ld	s3,24(sp)
    80001abc:	6a42                	ld	s4,16(sp)
    80001abe:	6aa2                	ld	s5,8(sp)
    80001ac0:	6b02                	ld	s6,0(sp)
    80001ac2:	6121                	addi	sp,sp,64
    80001ac4:	8082                	ret
    panic("more than 32 pages per proccess");
    80001ac6:	00006517          	auipc	a0,0x6
    80001aca:	6fa50513          	addi	a0,a0,1786 # 800081c0 <digits+0x180>
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	a5c080e7          	jalr	-1444(ra) # 8000052a <panic>
      pg->state = 1;
    80001ad6:	4785                	li	a5,1
    80001ad8:	c49c                	sw	a5,8(s1)
      pg->va = pg_to_swap->va;
    80001ada:	00551993          	slli	s3,a0,0x5
    80001ade:	99ca                	add	s3,s3,s2
    80001ae0:	1709b583          	ld	a1,368(s3)
    80001ae4:	e08c                	sd	a1,0(s1)
      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
    80001ae6:	4601                	li	a2,0
    80001ae8:	8552                	mv	a0,s4
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	4bc080e7          	jalr	1212(ra) # 80000fa6 <walk>
    80001af2:	8b2a                	mv	s6,a0
      uint64 pa = PTE2PA(*pte);
    80001af4:	00053a03          	ld	s4,0(a0)
    80001af8:	00aa5a13          	srli	s4,s4,0xa
    80001afc:	0a32                	slli	s4,s4,0xc
      int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001afe:	41548633          	sub	a2,s1,s5
      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 
    80001b02:	6685                	lui	a3,0x1
    80001b04:	0076161b          	slliw	a2,a2,0x7
    80001b08:	85d2                	mv	a1,s4
    80001b0a:	854a                	mv	a0,s2
    80001b0c:	00003097          	auipc	ra,0x3
    80001b10:	c54080e7          	jalr	-940(ra) # 80004760 <writeToSwapFile>
      p->num_pages_in_swapfile++;
    80001b14:	57492783          	lw	a5,1396(s2)
    80001b18:	2785                	addiw	a5,a5,1
    80001b1a:	56f92a23          	sw	a5,1396(s2)
      kfree((void*)pa); 
    80001b1e:	8552                	mv	a0,s4
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	eb6080e7          	jalr	-330(ra) # 800009d6 <kfree>
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
    80001b28:	000b3783          	ld	a5,0(s6) # 1000 <_entry-0x7ffff000>
    80001b2c:	9bf9                	andi	a5,a5,-2
    80001b2e:	2007e793          	ori	a5,a5,512
    80001b32:	00fb3023          	sd	a5,0(s6)
      pg_to_swap->state = 0;
    80001b36:	1609ac23          	sw	zero,376(s3)
      pg_to_swap->va = 0;
    80001b3a:	1609b823          	sd	zero,368(s3)
      p->num_pages_in_psyc--;
    80001b3e:	57092783          	lw	a5,1392(s2)
    80001b42:	37fd                	addiw	a5,a5,-1
    80001b44:	56f92823          	sw	a5,1392(s2)
    80001b48:	12000073          	sfence.vma
}
    80001b4c:	b79d                	j	80001ab2 <swap_into_file+0x50>

0000000080001b4e <add_to_memory>:

//Adding new page created by uvmalloc() to proccess pages
void add_to_memory(uint64 a, pagetable_t pagetable){
    80001b4e:	7179                	addi	sp,sp,-48
    80001b50:	f406                	sd	ra,40(sp)
    80001b52:	f022                	sd	s0,32(sp)
    80001b54:	ec26                	sd	s1,24(sp)
    80001b56:	e84a                	sd	s2,16(sp)
    80001b58:	e44e                	sd	s3,8(sp)
    80001b5a:	1800                	addi	s0,sp,48
    80001b5c:	892a                	mv	s2,a0
    80001b5e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80001b60:	00000097          	auipc	ra,0x0
    80001b64:	3ea080e7          	jalr	1002(ra) # 80001f4a <myproc>
    80001b68:	84aa                	mv	s1,a0
  //No free space in the psyc memory,
  //Chose page to remove from main memory (using one of task2 algorithms) 
  //and swap this page into file
  if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001b6a:	57052703          	lw	a4,1392(a0)
    80001b6e:	47c1                	li	a5,16
    80001b70:	06f70163          	beq	a4,a5,80001bd2 <add_to_memory+0x84>
    swap_into_file(pagetable);
  }

  //Now we have free space in psyc memory (maybe we had free space before too):
  //just add all page information to pages_in_memory array:
  int free_index_memory_array = find_free_index_in_memory_array();
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	cc2080e7          	jalr	-830(ra) # 80001836 <find_free_index_in_memory_array>
  
  #ifdef YES
  printf("add to file: adding va= %p\n", a);
  #endif

  pg->state = 1;
    80001b7c:	00551713          	slli	a4,a0,0x5
    80001b80:	9726                	add	a4,a4,s1
    80001b82:	4685                	li	a3,1
    80001b84:	16d72c23          	sw	a3,376(a4)
  pg->va = a;
    80001b88:	17273823          	sd	s2,368(a4)
  #endif
  #ifdef LAPA
  pg->age = (uint64)~0;
  #endif
  #ifdef SCFIFO
  pg->creationOrder=++p->creationTimeGenerator;
    80001b8c:	5784b703          	ld	a4,1400(s1)
    80001b90:	0705                	addi	a4,a4,1
    80001b92:	56e4bc23          	sd	a4,1400(s1)
    80001b96:	00c50793          	addi	a5,a0,12
    80001b9a:	0796                	slli	a5,a5,0x5
    80001b9c:	97a6                	add	a5,a5,s1
    80001b9e:	e798                	sd	a4,8(a5)
  #endif

  p->num_pages_in_psyc++;
    80001ba0:	5704a783          	lw	a5,1392(s1)
    80001ba4:	2785                	addiw	a5,a5,1
    80001ba6:	56f4a823          	sw	a5,1392(s1)

  pte_t* pte = walk(pagetable, pg->va, 0);
    80001baa:	4601                	li	a2,0
    80001bac:	85ca                	mv	a1,s2
    80001bae:	854e                	mv	a0,s3
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	3f6080e7          	jalr	1014(ra) # 80000fa6 <walk>
  //set pte flags:
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001bb8:	611c                	ld	a5,0(a0)
    80001bba:	dff7f793          	andi	a5,a5,-513
  *pte |= PTE_V;
    80001bbe:	0017e793          	ori	a5,a5,1
    80001bc2:	e11c                	sd	a5,0(a0)
  #ifdef YES
  printf("finish add to memory: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
  #endif
}
    80001bc4:	70a2                	ld	ra,40(sp)
    80001bc6:	7402                	ld	s0,32(sp)
    80001bc8:	64e2                	ld	s1,24(sp)
    80001bca:	6942                	ld	s2,16(sp)
    80001bcc:	69a2                	ld	s3,8(sp)
    80001bce:	6145                	addi	sp,sp,48
    80001bd0:	8082                	ret
    swap_into_file(pagetable);
    80001bd2:	854e                	mv	a0,s3
    80001bd4:	00000097          	auipc	ra,0x0
    80001bd8:	e8e080e7          	jalr	-370(ra) # 80001a62 <swap_into_file>
    80001bdc:	bf61                	j	80001b74 <add_to_memory+0x26>

0000000080001bde <uvmalloc>:
  if(newsz < oldsz)
    80001bde:	0cb66363          	bltu	a2,a1,80001ca4 <uvmalloc+0xc6>
{
    80001be2:	7139                	addi	sp,sp,-64
    80001be4:	fc06                	sd	ra,56(sp)
    80001be6:	f822                	sd	s0,48(sp)
    80001be8:	f426                	sd	s1,40(sp)
    80001bea:	f04a                	sd	s2,32(sp)
    80001bec:	ec4e                	sd	s3,24(sp)
    80001bee:	e852                	sd	s4,16(sp)
    80001bf0:	e456                	sd	s5,8(sp)
    80001bf2:	e05a                	sd	s6,0(sp)
    80001bf4:	0080                	addi	s0,sp,64
    80001bf6:	89aa                	mv	s3,a0
    80001bf8:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    80001bfa:	6a05                	lui	s4,0x1
    80001bfc:	1a7d                	addi	s4,s4,-1
    80001bfe:	95d2                	add	a1,a1,s4
    80001c00:	7a7d                	lui	s4,0xfffff
    80001c02:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001c06:	0aca7163          	bgeu	s4,a2,80001ca8 <uvmalloc+0xca>
    80001c0a:	8952                	mv	s2,s4
    if(myproc()->pid > 2){
    80001c0c:	4b09                	li	s6,2
    80001c0e:	a0a9                	j	80001c58 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001c10:	8652                	mv	a2,s4
    80001c12:	85ca                	mv	a1,s2
    80001c14:	854e                	mv	a0,s3
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	830080e7          	jalr	-2000(ra) # 80001446 <uvmdealloc>
      return 0;
    80001c1e:	4501                	li	a0,0
}
    80001c20:	70e2                	ld	ra,56(sp)
    80001c22:	7442                	ld	s0,48(sp)
    80001c24:	74a2                	ld	s1,40(sp)
    80001c26:	7902                	ld	s2,32(sp)
    80001c28:	69e2                	ld	s3,24(sp)
    80001c2a:	6a42                	ld	s4,16(sp)
    80001c2c:	6aa2                	ld	s5,8(sp)
    80001c2e:	6b02                	ld	s6,0(sp)
    80001c30:	6121                	addi	sp,sp,64
    80001c32:	8082                	ret
      kfree(mem);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	da0080e7          	jalr	-608(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001c3e:	8652                	mv	a2,s4
    80001c40:	85ca                	mv	a1,s2
    80001c42:	854e                	mv	a0,s3
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	802080e7          	jalr	-2046(ra) # 80001446 <uvmdealloc>
      return 0;
    80001c4c:	4501                	li	a0,0
    80001c4e:	bfc9                	j	80001c20 <uvmalloc+0x42>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001c50:	6785                	lui	a5,0x1
    80001c52:	993e                	add	s2,s2,a5
    80001c54:	05597663          	bgeu	s2,s5,80001ca0 <uvmalloc+0xc2>
    mem = kalloc();
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	e7a080e7          	jalr	-390(ra) # 80000ad2 <kalloc>
    80001c60:	84aa                	mv	s1,a0
    if(mem == 0){
    80001c62:	d55d                	beqz	a0,80001c10 <uvmalloc+0x32>
    memset(mem, 0, PGSIZE);
    80001c64:	6605                	lui	a2,0x1
    80001c66:	4581                	li	a1,0
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	056080e7          	jalr	86(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001c70:	4779                	li	a4,30
    80001c72:	86a6                	mv	a3,s1
    80001c74:	6605                	lui	a2,0x1
    80001c76:	85ca                	mv	a1,s2
    80001c78:	854e                	mv	a0,s3
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	414080e7          	jalr	1044(ra) # 8000108e <mappages>
    80001c82:	f94d                	bnez	a0,80001c34 <uvmalloc+0x56>
    if(myproc()->pid > 2){
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	2c6080e7          	jalr	710(ra) # 80001f4a <myproc>
    80001c8c:	591c                	lw	a5,48(a0)
    80001c8e:	fcfb51e3          	bge	s6,a5,80001c50 <uvmalloc+0x72>
      add_to_memory(a, pagetable);
    80001c92:	85ce                	mv	a1,s3
    80001c94:	854a                	mv	a0,s2
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	eb8080e7          	jalr	-328(ra) # 80001b4e <add_to_memory>
    80001c9e:	bf4d                	j	80001c50 <uvmalloc+0x72>
  return newsz;
    80001ca0:	8556                	mv	a0,s5
    80001ca2:	bfbd                	j	80001c20 <uvmalloc+0x42>
    return oldsz;
    80001ca4:	852e                	mv	a0,a1
}
    80001ca6:	8082                	ret
  return newsz;
    80001ca8:	8532                	mv	a0,a2
    80001caa:	bf9d                	j	80001c20 <uvmalloc+0x42>

0000000080001cac <handle_pagefault>:

//Handle page fault - called from trap.c
int handle_pagefault(){
    80001cac:	7139                	addi	sp,sp,-64
    80001cae:	fc06                	sd	ra,56(sp)
    80001cb0:	f822                	sd	s0,48(sp)
    80001cb2:	f426                	sd	s1,40(sp)
    80001cb4:	f04a                	sd	s2,32(sp)
    80001cb6:	ec4e                	sd	s3,24(sp)
    80001cb8:	e852                	sd	s4,16(sp)
    80001cba:	e456                	sd	s5,8(sp)
    80001cbc:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	28c080e7          	jalr	652(ra) # 80001f4a <myproc>
    80001cc6:	892a                	mv	s2,a0
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001cc8:	143029f3          	csrr	s3,stval
  uint64 va = r_stval();
  
  pte_t* pte = walk(p->pagetable, va, 0);
    80001ccc:	4601                	li	a2,0
    80001cce:	85ce                	mv	a1,s3
    80001cd0:	6928                	ld	a0,80(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	2d4080e7          	jalr	724(ra) # 80000fa6 <walk>
  //If the page was swaped out, we should bring it back to memory
  if(*pte & PTE_PG){
    80001cda:	610c                	ld	a1,0(a0)
    80001cdc:	2005f793          	andi	a5,a1,512
    80001ce0:	c3f5                	beqz	a5,80001dc4 <handle_pagefault+0x118>
    //If no place in memory - swap out page
    if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001ce2:	57092703          	lw	a4,1392(s2)
    80001ce6:	47c1                	li	a5,16
    80001ce8:	04f70263          	beq	a4,a5,80001d2c <handle_pagefault+0x80>
      swap_into_file(p->pagetable);
    }

    //Now we have free space in psyc memory (maybe we had free space before too):
    //bring page from swapFile and put it into physic memory
    uint64 va1 = PGROUNDDOWN(va);
    80001cec:	77fd                	lui	a5,0xfffff
    80001cee:	00f9f9b3          	and	s3,s3,a5
    char *mem = kalloc();
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	de0080e7          	jalr	-544(ra) # 80000ad2 <kalloc>
    80001cfa:	8a2a                	mv	s4,a0
    
    struct page_metadata *pg;
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001cfc:	37090a93          	addi	s5,s2,880
    80001d00:	57090713          	addi	a4,s2,1392
    80001d04:	84d6                	mv	s1,s5
      if(pg->va == va1){
    80001d06:	609c                	ld	a5,0(s1)
    80001d08:	03378963          	beq	a5,s3,80001d3a <handle_pagefault+0x8e>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001d0c:	02048493          	addi	s1,s1,32
    80001d10:	fee49be3          	bne	s1,a4,80001d06 <handle_pagefault+0x5a>
  asm volatile("sfence.vma zero, zero");
    80001d14:	12000073          	sfence.vma
    }
    sfence_vma();
    #ifdef YES
    printf("finish handle_page\n");
    #endif
    return 3;
    80001d18:	450d                	li	a0,3
  }else{
    printf("segfault: pte: %p\n", *pte);
    return 0; //this is segfault
  }
    80001d1a:	70e2                	ld	ra,56(sp)
    80001d1c:	7442                	ld	s0,48(sp)
    80001d1e:	74a2                	ld	s1,40(sp)
    80001d20:	7902                	ld	s2,32(sp)
    80001d22:	69e2                	ld	s3,24(sp)
    80001d24:	6a42                	ld	s4,16(sp)
    80001d26:	6aa2                	ld	s5,8(sp)
    80001d28:	6121                	addi	sp,sp,64
    80001d2a:	8082                	ret
      swap_into_file(p->pagetable);
    80001d2c:	05093503          	ld	a0,80(s2)
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	d32080e7          	jalr	-718(ra) # 80001a62 <swap_into_file>
    80001d38:	bf55                	j	80001cec <handle_pagefault+0x40>
        pte_t* pte = walk(p->pagetable, va1, 0);
    80001d3a:	4601                	li	a2,0
    80001d3c:	85ce                	mv	a1,s3
    80001d3e:	05093503          	ld	a0,80(s2)
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	264080e7          	jalr	612(ra) # 80000fa6 <walk>
    80001d4a:	89aa                	mv	s3,a0
        int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001d4c:	41548633          	sub	a2,s1,s5
        readFromSwapFile(p, mem, offset, PGSIZE);
    80001d50:	6685                	lui	a3,0x1
    80001d52:	0076161b          	slliw	a2,a2,0x7
    80001d56:	85d2                	mv	a1,s4
    80001d58:	854a                	mv	a0,s2
    80001d5a:	00003097          	auipc	ra,0x3
    80001d5e:	a2a080e7          	jalr	-1494(ra) # 80004784 <readFromSwapFile>
        int free_index_memory_array = find_free_index_in_memory_array();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	ad4080e7          	jalr	-1324(ra) # 80001836 <find_free_index_in_memory_array>
        free_memory_page->state = 1;
    80001d6a:	00551793          	slli	a5,a0,0x5
    80001d6e:	97ca                	add	a5,a5,s2
    80001d70:	4705                	li	a4,1
    80001d72:	16e7ac23          	sw	a4,376(a5) # fffffffffffff178 <end+0xffffffff7ffc9178>
        free_memory_page->va = pg->va;
    80001d76:	6098                	ld	a4,0(s1)
    80001d78:	16e7b823          	sd	a4,368(a5)
        pg->creationOrder=++p->creationTimeGenerator;
    80001d7c:	57893783          	ld	a5,1400(s2)
    80001d80:	0785                	addi	a5,a5,1
    80001d82:	56f93c23          	sd	a5,1400(s2)
    80001d86:	ec9c                	sd	a5,24(s1)
        p->num_pages_in_swapfile--;
    80001d88:	57492783          	lw	a5,1396(s2)
    80001d8c:	37fd                	addiw	a5,a5,-1
    80001d8e:	56f92a23          	sw	a5,1396(s2)
        pg->state = 0;
    80001d92:	0004a423          	sw	zero,8(s1)
        pg->va = 0;
    80001d96:	0004b023          	sd	zero,0(s1)
        pg->age = 0;
    80001d9a:	0004b823          	sd	zero,16(s1)
        p->num_pages_in_psyc++;
    80001d9e:	57092783          	lw	a5,1392(s2)
    80001da2:	2785                	addiw	a5,a5,1
    80001da4:	56f92823          	sw	a5,1392(s2)
        *pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress 
    80001da8:	00ca5a13          	srli	s4,s4,0xc
    80001dac:	0a2a                	slli	s4,s4,0xa
    80001dae:	0009b783          	ld	a5,0(s3)
    80001db2:	1ff7f793          	andi	a5,a5,511
        *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001db6:	0147ea33          	or	s4,a5,s4
        *pte |= PTE_V;
    80001dba:	001a6a13          	ori	s4,s4,1
    80001dbe:	0149b023          	sd	s4,0(s3)
        break;
    80001dc2:	bf89                	j	80001d14 <handle_pagefault+0x68>
    printf("segfault: pte: %p\n", *pte);
    80001dc4:	00006517          	auipc	a0,0x6
    80001dc8:	41c50513          	addi	a0,a0,1052 # 800081e0 <digits+0x1a0>
    80001dcc:	ffffe097          	auipc	ra,0xffffe
    80001dd0:	7a8080e7          	jalr	1960(ra) # 80000574 <printf>
    return 0; //this is segfault
    80001dd4:	4501                	li	a0,0
    80001dd6:	b791                	j	80001d1a <handle_pagefault+0x6e>

0000000080001dd8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001dd8:	7139                	addi	sp,sp,-64
    80001dda:	fc06                	sd	ra,56(sp)
    80001ddc:	f822                	sd	s0,48(sp)
    80001dde:	f426                	sd	s1,40(sp)
    80001de0:	f04a                	sd	s2,32(sp)
    80001de2:	ec4e                	sd	s3,24(sp)
    80001de4:	e852                	sd	s4,16(sp)
    80001de6:	e456                	sd	s5,8(sp)
    80001de8:	e05a                	sd	s6,0(sp)
    80001dea:	0080                	addi	s0,sp,64
    80001dec:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dee:	00010497          	auipc	s1,0x10
    80001df2:	8e248493          	addi	s1,s1,-1822 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001df6:	8b26                	mv	s6,s1
    80001df8:	00006a97          	auipc	s5,0x6
    80001dfc:	208a8a93          	addi	s5,s5,520 # 80008000 <etext>
    80001e00:	04000937          	lui	s2,0x4000
    80001e04:	197d                	addi	s2,s2,-1
    80001e06:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e08:	00026a17          	auipc	s4,0x26
    80001e0c:	8c8a0a13          	addi	s4,s4,-1848 # 800276d0 <tickslock>
    char *pa = kalloc();
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	cc2080e7          	jalr	-830(ra) # 80000ad2 <kalloc>
    80001e18:	862a                	mv	a2,a0
    if(pa == 0)
    80001e1a:	c131                	beqz	a0,80001e5e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001e1c:	416485b3          	sub	a1,s1,s6
    80001e20:	859d                	srai	a1,a1,0x7
    80001e22:	000ab783          	ld	a5,0(s5)
    80001e26:	02f585b3          	mul	a1,a1,a5
    80001e2a:	2585                	addiw	a1,a1,1
    80001e2c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e30:	4719                	li	a4,6
    80001e32:	6685                	lui	a3,0x1
    80001e34:	40b905b3          	sub	a1,s2,a1
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	2e2080e7          	jalr	738(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e42:	58048493          	addi	s1,s1,1408
    80001e46:	fd4495e3          	bne	s1,s4,80001e10 <proc_mapstacks+0x38>
  }
}
    80001e4a:	70e2                	ld	ra,56(sp)
    80001e4c:	7442                	ld	s0,48(sp)
    80001e4e:	74a2                	ld	s1,40(sp)
    80001e50:	7902                	ld	s2,32(sp)
    80001e52:	69e2                	ld	s3,24(sp)
    80001e54:	6a42                	ld	s4,16(sp)
    80001e56:	6aa2                	ld	s5,8(sp)
    80001e58:	6b02                	ld	s6,0(sp)
    80001e5a:	6121                	addi	sp,sp,64
    80001e5c:	8082                	ret
      panic("kalloc");
    80001e5e:	00006517          	auipc	a0,0x6
    80001e62:	39a50513          	addi	a0,a0,922 # 800081f8 <digits+0x1b8>
    80001e66:	ffffe097          	auipc	ra,0xffffe
    80001e6a:	6c4080e7          	jalr	1732(ra) # 8000052a <panic>

0000000080001e6e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e6e:	7139                	addi	sp,sp,-64
    80001e70:	fc06                	sd	ra,56(sp)
    80001e72:	f822                	sd	s0,48(sp)
    80001e74:	f426                	sd	s1,40(sp)
    80001e76:	f04a                	sd	s2,32(sp)
    80001e78:	ec4e                	sd	s3,24(sp)
    80001e7a:	e852                	sd	s4,16(sp)
    80001e7c:	e456                	sd	s5,8(sp)
    80001e7e:	e05a                	sd	s6,0(sp)
    80001e80:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001e82:	00006597          	auipc	a1,0x6
    80001e86:	37e58593          	addi	a1,a1,894 # 80008200 <digits+0x1c0>
    80001e8a:	0000f517          	auipc	a0,0xf
    80001e8e:	41650513          	addi	a0,a0,1046 # 800112a0 <pid_lock>
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	ca0080e7          	jalr	-864(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e9a:	00006597          	auipc	a1,0x6
    80001e9e:	36e58593          	addi	a1,a1,878 # 80008208 <digits+0x1c8>
    80001ea2:	0000f517          	auipc	a0,0xf
    80001ea6:	41650513          	addi	a0,a0,1046 # 800112b8 <wait_lock>
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	c88080e7          	jalr	-888(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb2:	00010497          	auipc	s1,0x10
    80001eb6:	81e48493          	addi	s1,s1,-2018 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001eba:	00006b17          	auipc	s6,0x6
    80001ebe:	35eb0b13          	addi	s6,s6,862 # 80008218 <digits+0x1d8>
      p->kstack = KSTACK((int) (p - proc));
    80001ec2:	8aa6                	mv	s5,s1
    80001ec4:	00006a17          	auipc	s4,0x6
    80001ec8:	13ca0a13          	addi	s4,s4,316 # 80008000 <etext>
    80001ecc:	04000937          	lui	s2,0x4000
    80001ed0:	197d                	addi	s2,s2,-1
    80001ed2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ed4:	00025997          	auipc	s3,0x25
    80001ed8:	7fc98993          	addi	s3,s3,2044 # 800276d0 <tickslock>
      initlock(&p->lock, "proc");
    80001edc:	85da                	mv	a1,s6
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	c52080e7          	jalr	-942(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ee8:	415487b3          	sub	a5,s1,s5
    80001eec:	879d                	srai	a5,a5,0x7
    80001eee:	000a3703          	ld	a4,0(s4)
    80001ef2:	02e787b3          	mul	a5,a5,a4
    80001ef6:	2785                	addiw	a5,a5,1
    80001ef8:	00d7979b          	slliw	a5,a5,0xd
    80001efc:	40f907b3          	sub	a5,s2,a5
    80001f00:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f02:	58048493          	addi	s1,s1,1408
    80001f06:	fd349be3          	bne	s1,s3,80001edc <procinit+0x6e>
  }
}
    80001f0a:	70e2                	ld	ra,56(sp)
    80001f0c:	7442                	ld	s0,48(sp)
    80001f0e:	74a2                	ld	s1,40(sp)
    80001f10:	7902                	ld	s2,32(sp)
    80001f12:	69e2                	ld	s3,24(sp)
    80001f14:	6a42                	ld	s4,16(sp)
    80001f16:	6aa2                	ld	s5,8(sp)
    80001f18:	6b02                	ld	s6,0(sp)
    80001f1a:	6121                	addi	sp,sp,64
    80001f1c:	8082                	ret

0000000080001f1e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f1e:	1141                	addi	sp,sp,-16
    80001f20:	e422                	sd	s0,8(sp)
    80001f22:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f24:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f26:	2501                	sext.w	a0,a0
    80001f28:	6422                	ld	s0,8(sp)
    80001f2a:	0141                	addi	sp,sp,16
    80001f2c:	8082                	ret

0000000080001f2e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001f2e:	1141                	addi	sp,sp,-16
    80001f30:	e422                	sd	s0,8(sp)
    80001f32:	0800                	addi	s0,sp,16
    80001f34:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f36:	2781                	sext.w	a5,a5
    80001f38:	079e                	slli	a5,a5,0x7
  return c;
}
    80001f3a:	0000f517          	auipc	a0,0xf
    80001f3e:	39650513          	addi	a0,a0,918 # 800112d0 <cpus>
    80001f42:	953e                	add	a0,a0,a5
    80001f44:	6422                	ld	s0,8(sp)
    80001f46:	0141                	addi	sp,sp,16
    80001f48:	8082                	ret

0000000080001f4a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001f4a:	1101                	addi	sp,sp,-32
    80001f4c:	ec06                	sd	ra,24(sp)
    80001f4e:	e822                	sd	s0,16(sp)
    80001f50:	e426                	sd	s1,8(sp)
    80001f52:	1000                	addi	s0,sp,32
  push_off();
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c22080e7          	jalr	-990(ra) # 80000b76 <push_off>
    80001f5c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f5e:	2781                	sext.w	a5,a5
    80001f60:	079e                	slli	a5,a5,0x7
    80001f62:	0000f717          	auipc	a4,0xf
    80001f66:	33e70713          	addi	a4,a4,830 # 800112a0 <pid_lock>
    80001f6a:	97ba                	add	a5,a5,a4
    80001f6c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	ca8080e7          	jalr	-856(ra) # 80000c16 <pop_off>
  return p;
}
    80001f76:	8526                	mv	a0,s1
    80001f78:	60e2                	ld	ra,24(sp)
    80001f7a:	6442                	ld	s0,16(sp)
    80001f7c:	64a2                	ld	s1,8(sp)
    80001f7e:	6105                	addi	sp,sp,32
    80001f80:	8082                	ret

0000000080001f82 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f82:	1141                	addi	sp,sp,-16
    80001f84:	e406                	sd	ra,8(sp)
    80001f86:	e022                	sd	s0,0(sp)
    80001f88:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	fc0080e7          	jalr	-64(ra) # 80001f4a <myproc>
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	ce4080e7          	jalr	-796(ra) # 80000c76 <release>

  if (first) {
    80001f9a:	00007797          	auipc	a5,0x7
    80001f9e:	8d67a783          	lw	a5,-1834(a5) # 80008870 <first.1>
    80001fa2:	eb89                	bnez	a5,80001fb4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001fa4:	00001097          	auipc	ra,0x1
    80001fa8:	d32080e7          	jalr	-718(ra) # 80002cd6 <usertrapret>
}
    80001fac:	60a2                	ld	ra,8(sp)
    80001fae:	6402                	ld	s0,0(sp)
    80001fb0:	0141                	addi	sp,sp,16
    80001fb2:	8082                	ret
    first = 0;
    80001fb4:	00007797          	auipc	a5,0x7
    80001fb8:	8a07ae23          	sw	zero,-1860(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001fbc:	4505                	li	a0,1
    80001fbe:	00002097          	auipc	ra,0x2
    80001fc2:	a70080e7          	jalr	-1424(ra) # 80003a2e <fsinit>
    80001fc6:	bff9                	j	80001fa4 <forkret+0x22>

0000000080001fc8 <allocpid>:
allocpid() {
    80001fc8:	1101                	addi	sp,sp,-32
    80001fca:	ec06                	sd	ra,24(sp)
    80001fcc:	e822                	sd	s0,16(sp)
    80001fce:	e426                	sd	s1,8(sp)
    80001fd0:	e04a                	sd	s2,0(sp)
    80001fd2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001fd4:	0000f917          	auipc	s2,0xf
    80001fd8:	2cc90913          	addi	s2,s2,716 # 800112a0 <pid_lock>
    80001fdc:	854a                	mv	a0,s2
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	be4080e7          	jalr	-1052(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001fe6:	00007797          	auipc	a5,0x7
    80001fea:	88e78793          	addi	a5,a5,-1906 # 80008874 <nextpid>
    80001fee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ff0:	0014871b          	addiw	a4,s1,1
    80001ff4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ff6:	854a                	mv	a0,s2
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	c7e080e7          	jalr	-898(ra) # 80000c76 <release>
}
    80002000:	8526                	mv	a0,s1
    80002002:	60e2                	ld	ra,24(sp)
    80002004:	6442                	ld	s0,16(sp)
    80002006:	64a2                	ld	s1,8(sp)
    80002008:	6902                	ld	s2,0(sp)
    8000200a:	6105                	addi	sp,sp,32
    8000200c:	8082                	ret

000000008000200e <proc_pagetable>:
{
    8000200e:	1101                	addi	sp,sp,-32
    80002010:	ec06                	sd	ra,24(sp)
    80002012:	e822                	sd	s0,16(sp)
    80002014:	e426                	sd	s1,8(sp)
    80002016:	e04a                	sd	s2,0(sp)
    80002018:	1000                	addi	s0,sp,32
    8000201a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	38a080e7          	jalr	906(ra) # 800013a6 <uvmcreate>
    80002024:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002026:	c121                	beqz	a0,80002066 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002028:	4729                	li	a4,10
    8000202a:	00005697          	auipc	a3,0x5
    8000202e:	fd668693          	addi	a3,a3,-42 # 80007000 <_trampoline>
    80002032:	6605                	lui	a2,0x1
    80002034:	040005b7          	lui	a1,0x4000
    80002038:	15fd                	addi	a1,a1,-1
    8000203a:	05b2                	slli	a1,a1,0xc
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	052080e7          	jalr	82(ra) # 8000108e <mappages>
    80002044:	02054863          	bltz	a0,80002074 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002048:	4719                	li	a4,6
    8000204a:	05893683          	ld	a3,88(s2)
    8000204e:	6605                	lui	a2,0x1
    80002050:	020005b7          	lui	a1,0x2000
    80002054:	15fd                	addi	a1,a1,-1
    80002056:	05b6                	slli	a1,a1,0xd
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	034080e7          	jalr	52(ra) # 8000108e <mappages>
    80002062:	02054163          	bltz	a0,80002084 <proc_pagetable+0x76>
}
    80002066:	8526                	mv	a0,s1
    80002068:	60e2                	ld	ra,24(sp)
    8000206a:	6442                	ld	s0,16(sp)
    8000206c:	64a2                	ld	s1,8(sp)
    8000206e:	6902                	ld	s2,0(sp)
    80002070:	6105                	addi	sp,sp,32
    80002072:	8082                	ret
    uvmfree(pagetable, 0);
    80002074:	4581                	li	a1,0
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	480080e7          	jalr	1152(ra) # 800014f8 <uvmfree>
    return 0;
    80002080:	4481                	li	s1,0
    80002082:	b7d5                	j	80002066 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002084:	4681                	li	a3,0
    80002086:	4605                	li	a2,1
    80002088:	040005b7          	lui	a1,0x4000
    8000208c:	15fd                	addi	a1,a1,-1
    8000208e:	05b2                	slli	a1,a1,0xc
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	1b0080e7          	jalr	432(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    8000209a:	4581                	li	a1,0
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	45a080e7          	jalr	1114(ra) # 800014f8 <uvmfree>
    return 0;
    800020a6:	4481                	li	s1,0
    800020a8:	bf7d                	j	80002066 <proc_pagetable+0x58>

00000000800020aa <proc_freepagetable>:
{
    800020aa:	1101                	addi	sp,sp,-32
    800020ac:	ec06                	sd	ra,24(sp)
    800020ae:	e822                	sd	s0,16(sp)
    800020b0:	e426                	sd	s1,8(sp)
    800020b2:	e04a                	sd	s2,0(sp)
    800020b4:	1000                	addi	s0,sp,32
    800020b6:	84aa                	mv	s1,a0
    800020b8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020ba:	4681                	li	a3,0
    800020bc:	4605                	li	a2,1
    800020be:	040005b7          	lui	a1,0x4000
    800020c2:	15fd                	addi	a1,a1,-1
    800020c4:	05b2                	slli	a1,a1,0xc
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	17c080e7          	jalr	380(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020ce:	4681                	li	a3,0
    800020d0:	4605                	li	a2,1
    800020d2:	020005b7          	lui	a1,0x2000
    800020d6:	15fd                	addi	a1,a1,-1
    800020d8:	05b6                	slli	a1,a1,0xd
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	166080e7          	jalr	358(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    800020e4:	85ca                	mv	a1,s2
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	410080e7          	jalr	1040(ra) # 800014f8 <uvmfree>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6902                	ld	s2,0(sp)
    800020f8:	6105                	addi	sp,sp,32
    800020fa:	8082                	ret

00000000800020fc <freeproc>:
{
    800020fc:	1101                	addi	sp,sp,-32
    800020fe:	ec06                	sd	ra,24(sp)
    80002100:	e822                	sd	s0,16(sp)
    80002102:	e426                	sd	s1,8(sp)
    80002104:	1000                	addi	s0,sp,32
    80002106:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002108:	6d28                	ld	a0,88(a0)
    8000210a:	c509                	beqz	a0,80002114 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	8ca080e7          	jalr	-1846(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80002114:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002118:	68a8                	ld	a0,80(s1)
    8000211a:	c511                	beqz	a0,80002126 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000211c:	64ac                	ld	a1,72(s1)
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	f8c080e7          	jalr	-116(ra) # 800020aa <proc_freepagetable>
  if(p->pid > 2){
    80002126:	5898                	lw	a4,48(s1)
    80002128:	4789                	li	a5,2
    8000212a:	04e7d163          	bge	a5,a4,8000216c <freeproc+0x70>
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    8000212e:	17048713          	addi	a4,s1,368
    80002132:	37048793          	addi	a5,s1,880
    80002136:	86be                	mv	a3,a5
      pg->state = 0;
    80002138:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    8000213c:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    80002140:	00073823          	sd	zero,16(a4)
      pg->creationOrder=0;
    80002144:	00073c23          	sd	zero,24(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80002148:	02070713          	addi	a4,a4,32
    8000214c:	fed716e3          	bne	a4,a3,80002138 <freeproc+0x3c>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80002150:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    80002154:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    80002158:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    8000215c:	0007b823          	sd	zero,16(a5)
      pg->creationOrder=0;
    80002160:	0007bc23          	sd	zero,24(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80002164:	02078793          	addi	a5,a5,32
    80002168:	fee796e3          	bne	a5,a4,80002154 <freeproc+0x58>
  p->pagetable = 0;
    8000216c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002170:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002174:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002178:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    8000217c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002180:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002184:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002188:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000218c:	0004ac23          	sw	zero,24(s1)
  p->num_pages_in_swapfile = 0;
    80002190:	5604aa23          	sw	zero,1396(s1)
  p->num_pages_in_psyc = 0;
    80002194:	5604a823          	sw	zero,1392(s1)
  p->creationTimeGenerator=0;
    80002198:	5604bc23          	sd	zero,1400(s1)
}
    8000219c:	60e2                	ld	ra,24(sp)
    8000219e:	6442                	ld	s0,16(sp)
    800021a0:	64a2                	ld	s1,8(sp)
    800021a2:	6105                	addi	sp,sp,32
    800021a4:	8082                	ret

00000000800021a6 <allocproc>:
{
    800021a6:	1101                	addi	sp,sp,-32
    800021a8:	ec06                	sd	ra,24(sp)
    800021aa:	e822                	sd	s0,16(sp)
    800021ac:	e426                	sd	s1,8(sp)
    800021ae:	e04a                	sd	s2,0(sp)
    800021b0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800021b2:	0000f497          	auipc	s1,0xf
    800021b6:	51e48493          	addi	s1,s1,1310 # 800116d0 <proc>
    800021ba:	00025917          	auipc	s2,0x25
    800021be:	51690913          	addi	s2,s2,1302 # 800276d0 <tickslock>
    acquire(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	9fe080e7          	jalr	-1538(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    800021cc:	4c9c                	lw	a5,24(s1)
    800021ce:	cf81                	beqz	a5,800021e6 <allocproc+0x40>
      release(&p->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	aa4080e7          	jalr	-1372(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	58048493          	addi	s1,s1,1408
    800021de:	ff2492e3          	bne	s1,s2,800021c2 <allocproc+0x1c>
  return 0;
    800021e2:	4481                	li	s1,0
    800021e4:	a899                	j	8000223a <allocproc+0x94>
  p->pid = allocpid();
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	de2080e7          	jalr	-542(ra) # 80001fc8 <allocpid>
    800021ee:	d888                	sw	a0,48(s1)
  p->state = USED;
    800021f0:	4785                	li	a5,1
    800021f2:	cc9c                	sw	a5,24(s1)
  p->creationTimeGenerator=0;
    800021f4:	5604bc23          	sd	zero,1400(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	8da080e7          	jalr	-1830(ra) # 80000ad2 <kalloc>
    80002200:	892a                	mv	s2,a0
    80002202:	eca8                	sd	a0,88(s1)
    80002204:	c131                	beqz	a0,80002248 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80002206:	8526                	mv	a0,s1
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	e06080e7          	jalr	-506(ra) # 8000200e <proc_pagetable>
    80002210:	892a                	mv	s2,a0
    80002212:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002214:	c531                	beqz	a0,80002260 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80002216:	07000613          	li	a2,112
    8000221a:	4581                	li	a1,0
    8000221c:	06048513          	addi	a0,s1,96
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a9e080e7          	jalr	-1378(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80002228:	00000797          	auipc	a5,0x0
    8000222c:	d5a78793          	addi	a5,a5,-678 # 80001f82 <forkret>
    80002230:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002232:	60bc                	ld	a5,64(s1)
    80002234:	6705                	lui	a4,0x1
    80002236:	97ba                	add	a5,a5,a4
    80002238:	f4bc                	sd	a5,104(s1)
}
    8000223a:	8526                	mv	a0,s1
    8000223c:	60e2                	ld	ra,24(sp)
    8000223e:	6442                	ld	s0,16(sp)
    80002240:	64a2                	ld	s1,8(sp)
    80002242:	6902                	ld	s2,0(sp)
    80002244:	6105                	addi	sp,sp,32
    80002246:	8082                	ret
    freeproc(p);
    80002248:	8526                	mv	a0,s1
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	eb2080e7          	jalr	-334(ra) # 800020fc <freeproc>
    release(&p->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a22080e7          	jalr	-1502(ra) # 80000c76 <release>
    return 0;
    8000225c:	84ca                	mv	s1,s2
    8000225e:	bff1                	j	8000223a <allocproc+0x94>
    freeproc(p);
    80002260:	8526                	mv	a0,s1
    80002262:	00000097          	auipc	ra,0x0
    80002266:	e9a080e7          	jalr	-358(ra) # 800020fc <freeproc>
    release(&p->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a0a080e7          	jalr	-1526(ra) # 80000c76 <release>
    return 0;
    80002274:	84ca                	mv	s1,s2
    80002276:	b7d1                	j	8000223a <allocproc+0x94>

0000000080002278 <userinit>:
{
    80002278:	1101                	addi	sp,sp,-32
    8000227a:	ec06                	sd	ra,24(sp)
    8000227c:	e822                	sd	s0,16(sp)
    8000227e:	e426                	sd	s1,8(sp)
    80002280:	1000                	addi	s0,sp,32
  p = allocproc();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	f24080e7          	jalr	-220(ra) # 800021a6 <allocproc>
    8000228a:	84aa                	mv	s1,a0
  initproc = p;
    8000228c:	00007797          	auipc	a5,0x7
    80002290:	d8a7be23          	sd	a0,-612(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002294:	03400613          	li	a2,52
    80002298:	00006597          	auipc	a1,0x6
    8000229c:	5e858593          	addi	a1,a1,1512 # 80008880 <initcode>
    800022a0:	6928                	ld	a0,80(a0)
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	132080e7          	jalr	306(ra) # 800013d4 <uvminit>
  p->sz = PGSIZE;
    800022aa:	6785                	lui	a5,0x1
    800022ac:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800022ae:	6cb8                	ld	a4,88(s1)
    800022b0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800022b4:	6cb8                	ld	a4,88(s1)
    800022b6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800022b8:	4641                	li	a2,16
    800022ba:	00006597          	auipc	a1,0x6
    800022be:	f6658593          	addi	a1,a1,-154 # 80008220 <digits+0x1e0>
    800022c2:	15848513          	addi	a0,s1,344
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	b4a080e7          	jalr	-1206(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    800022ce:	00006517          	auipc	a0,0x6
    800022d2:	f6250513          	addi	a0,a0,-158 # 80008230 <digits+0x1f0>
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	186080e7          	jalr	390(ra) # 8000445c <namei>
    800022de:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800022e2:	478d                	li	a5,3
    800022e4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	98e080e7          	jalr	-1650(ra) # 80000c76 <release>
}
    800022f0:	60e2                	ld	ra,24(sp)
    800022f2:	6442                	ld	s0,16(sp)
    800022f4:	64a2                	ld	s1,8(sp)
    800022f6:	6105                	addi	sp,sp,32
    800022f8:	8082                	ret

00000000800022fa <growproc>:
{
    800022fa:	1101                	addi	sp,sp,-32
    800022fc:	ec06                	sd	ra,24(sp)
    800022fe:	e822                	sd	s0,16(sp)
    80002300:	e426                	sd	s1,8(sp)
    80002302:	e04a                	sd	s2,0(sp)
    80002304:	1000                	addi	s0,sp,32
    80002306:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	c42080e7          	jalr	-958(ra) # 80001f4a <myproc>
    80002310:	892a                	mv	s2,a0
  sz = p->sz;
    80002312:	652c                	ld	a1,72(a0)
    80002314:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002318:	00904f63          	bgtz	s1,80002336 <growproc+0x3c>
  } else if(n < 0){
    8000231c:	0204cc63          	bltz	s1,80002354 <growproc+0x5a>
  p->sz = sz;
    80002320:	1602                	slli	a2,a2,0x20
    80002322:	9201                	srli	a2,a2,0x20
    80002324:	04c93423          	sd	a2,72(s2)
  return 0;
    80002328:	4501                	li	a0,0
}
    8000232a:	60e2                	ld	ra,24(sp)
    8000232c:	6442                	ld	s0,16(sp)
    8000232e:	64a2                	ld	s1,8(sp)
    80002330:	6902                	ld	s2,0(sp)
    80002332:	6105                	addi	sp,sp,32
    80002334:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002336:	9e25                	addw	a2,a2,s1
    80002338:	1602                	slli	a2,a2,0x20
    8000233a:	9201                	srli	a2,a2,0x20
    8000233c:	1582                	slli	a1,a1,0x20
    8000233e:	9181                	srli	a1,a1,0x20
    80002340:	6928                	ld	a0,80(a0)
    80002342:	00000097          	auipc	ra,0x0
    80002346:	89c080e7          	jalr	-1892(ra) # 80001bde <uvmalloc>
    8000234a:	0005061b          	sext.w	a2,a0
    8000234e:	fa69                	bnez	a2,80002320 <growproc+0x26>
      return -1;
    80002350:	557d                	li	a0,-1
    80002352:	bfe1                	j	8000232a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002354:	9e25                	addw	a2,a2,s1
    80002356:	1602                	slli	a2,a2,0x20
    80002358:	9201                	srli	a2,a2,0x20
    8000235a:	1582                	slli	a1,a1,0x20
    8000235c:	9181                	srli	a1,a1,0x20
    8000235e:	6928                	ld	a0,80(a0)
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	0e6080e7          	jalr	230(ra) # 80001446 <uvmdealloc>
    80002368:	0005061b          	sext.w	a2,a0
    8000236c:	bf55                	j	80002320 <growproc+0x26>

000000008000236e <fork>:
{
    8000236e:	715d                	addi	sp,sp,-80
    80002370:	e486                	sd	ra,72(sp)
    80002372:	e0a2                	sd	s0,64(sp)
    80002374:	fc26                	sd	s1,56(sp)
    80002376:	f84a                	sd	s2,48(sp)
    80002378:	f44e                	sd	s3,40(sp)
    8000237a:	f052                	sd	s4,32(sp)
    8000237c:	ec56                	sd	s5,24(sp)
    8000237e:	e85a                	sd	s6,16(sp)
    80002380:	e45e                	sd	s7,8(sp)
    80002382:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002384:	00000097          	auipc	ra,0x0
    80002388:	bc6080e7          	jalr	-1082(ra) # 80001f4a <myproc>
    8000238c:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	e18080e7          	jalr	-488(ra) # 800021a6 <allocproc>
    80002396:	1c050563          	beqz	a0,80002560 <fork+0x1f2>
    8000239a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000239c:	048a3603          	ld	a2,72(s4)
    800023a0:	692c                	ld	a1,80(a0)
    800023a2:	050a3503          	ld	a0,80(s4)
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	18a080e7          	jalr	394(ra) # 80001530 <uvmcopy>
    800023ae:	04054863          	bltz	a0,800023fe <fork+0x90>
  np->sz = p->sz;
    800023b2:	048a3783          	ld	a5,72(s4)
    800023b6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800023ba:	058a3683          	ld	a3,88(s4)
    800023be:	87b6                	mv	a5,a3
    800023c0:	0589b703          	ld	a4,88(s3)
    800023c4:	12068693          	addi	a3,a3,288
    800023c8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800023cc:	6788                	ld	a0,8(a5)
    800023ce:	6b8c                	ld	a1,16(a5)
    800023d0:	6f90                	ld	a2,24(a5)
    800023d2:	01073023          	sd	a6,0(a4)
    800023d6:	e708                	sd	a0,8(a4)
    800023d8:	eb0c                	sd	a1,16(a4)
    800023da:	ef10                	sd	a2,24(a4)
    800023dc:	02078793          	addi	a5,a5,32
    800023e0:	02070713          	addi	a4,a4,32
    800023e4:	fed792e3          	bne	a5,a3,800023c8 <fork+0x5a>
  np->trapframe->a0 = 0;
    800023e8:	0589b783          	ld	a5,88(s3)
    800023ec:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800023f0:	0d0a0493          	addi	s1,s4,208
    800023f4:	0d098913          	addi	s2,s3,208
    800023f8:	150a0a93          	addi	s5,s4,336
    800023fc:	a00d                	j	8000241e <fork+0xb0>
    freeproc(np);
    800023fe:	854e                	mv	a0,s3
    80002400:	00000097          	auipc	ra,0x0
    80002404:	cfc080e7          	jalr	-772(ra) # 800020fc <freeproc>
    release(&np->lock);
    80002408:	854e                	mv	a0,s3
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
    return -1;
    80002412:	5afd                	li	s5,-1
    80002414:	a225                	j	8000253c <fork+0x1ce>
  for(i = 0; i < NOFILE; i++)
    80002416:	04a1                	addi	s1,s1,8
    80002418:	0921                	addi	s2,s2,8
    8000241a:	01548b63          	beq	s1,s5,80002430 <fork+0xc2>
    if(p->ofile[i])
    8000241e:	6088                	ld	a0,0(s1)
    80002420:	d97d                	beqz	a0,80002416 <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80002422:	00003097          	auipc	ra,0x3
    80002426:	9e6080e7          	jalr	-1562(ra) # 80004e08 <filedup>
    8000242a:	00a93023          	sd	a0,0(s2)
    8000242e:	b7e5                	j	80002416 <fork+0xa8>
  np->cwd = idup(p->cwd);
    80002430:	150a3503          	ld	a0,336(s4)
    80002434:	00002097          	auipc	ra,0x2
    80002438:	834080e7          	jalr	-1996(ra) # 80003c68 <idup>
    8000243c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002440:	4641                	li	a2,16
    80002442:	158a0593          	addi	a1,s4,344
    80002446:	15898513          	addi	a0,s3,344
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	9c6080e7          	jalr	-1594(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002452:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002456:	854e                	mv	a0,s3
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	81e080e7          	jalr	-2018(ra) # 80000c76 <release>
if(np->pid > 2){
    80002460:	0309a703          	lw	a4,48(s3)
    80002464:	4789                	li	a5,2
    80002466:	0ee7c763          	blt	a5,a4,80002554 <fork+0x1e6>
if(p->pid > 2){
    8000246a:	030a2703          	lw	a4,48(s4)
    8000246e:	4789                	li	a5,2
    80002470:	08e7d963          	bge	a5,a4,80002502 <fork+0x194>
    80002474:	170a0793          	addi	a5,s4,368
    80002478:	17098713          	addi	a4,s3,368
    8000247c:	370a0613          	addi	a2,s4,880
    np->pages_in_memory[i].state = p->pages_in_memory[i].state;
    80002480:	4794                	lw	a3,8(a5)
    80002482:	c714                	sw	a3,8(a4)
    np->pages_in_memory[i].va = p->pages_in_memory[i].va;
    80002484:	6394                	ld	a3,0(a5)
    80002486:	e314                	sd	a3,0(a4)
    np->pages_in_memory[i].age = p->pages_in_memory[i].age;
    80002488:	6b94                	ld	a3,16(a5)
    8000248a:	eb14                	sd	a3,16(a4)
    np->pages_in_swapfile[i].state = p->pages_in_swapfile[i].state;
    8000248c:	2087a683          	lw	a3,520(a5)
    80002490:	20d72423          	sw	a3,520(a4)
    np->pages_in_swapfile[i].va = p->pages_in_swapfile[i].va;
    80002494:	2007b683          	ld	a3,512(a5)
    80002498:	20d73023          	sd	a3,512(a4)
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    8000249c:	02078793          	addi	a5,a5,32
    800024a0:	02070713          	addi	a4,a4,32
    800024a4:	fcc79ee3          	bne	a5,a2,80002480 <fork+0x112>
  np->num_pages_in_psyc = p->num_pages_in_psyc;
    800024a8:	570a2783          	lw	a5,1392(s4)
    800024ac:	56f9a823          	sw	a5,1392(s3)
  np->num_pages_in_swapfile = p->num_pages_in_swapfile;
    800024b0:	574a2783          	lw	a5,1396(s4)
    800024b4:	56f9aa23          	sw	a5,1396(s3)
  np->creationTimeGenerator=p->creationTimeGenerator;
    800024b8:	578a3783          	ld	a5,1400(s4)
    800024bc:	56f9bc23          	sd	a5,1400(s3)
  char* buffer = kalloc();
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	612080e7          	jalr	1554(ra) # 80000ad2 <kalloc>
    800024c8:	892a                	mv	s2,a0
    800024ca:	4481                	li	s1,0
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    800024cc:	6b85                	lui	s7,0x1
    800024ce:	6b41                	lui	s6,0x10
    readFromSwapFile(p, buffer, i*PGSIZE, PGSIZE);
    800024d0:	6685                	lui	a3,0x1
    800024d2:	8626                	mv	a2,s1
    800024d4:	85ca                	mv	a1,s2
    800024d6:	8552                	mv	a0,s4
    800024d8:	00002097          	auipc	ra,0x2
    800024dc:	2ac080e7          	jalr	684(ra) # 80004784 <readFromSwapFile>
    writeToSwapFile(np, buffer, i*PGSIZE, PGSIZE);
    800024e0:	6685                	lui	a3,0x1
    800024e2:	8626                	mv	a2,s1
    800024e4:	85ca                	mv	a1,s2
    800024e6:	854e                	mv	a0,s3
    800024e8:	00002097          	auipc	ra,0x2
    800024ec:	278080e7          	jalr	632(ra) # 80004760 <writeToSwapFile>
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    800024f0:	009b84bb          	addw	s1,s7,s1
    800024f4:	fd649ee3          	bne	s1,s6,800024d0 <fork+0x162>
  kfree(buffer);
    800024f8:	854a                	mv	a0,s2
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	4dc080e7          	jalr	1244(ra) # 800009d6 <kfree>
  acquire(&wait_lock);
    80002502:	0000f497          	auipc	s1,0xf
    80002506:	db648493          	addi	s1,s1,-586 # 800112b8 <wait_lock>
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	6b6080e7          	jalr	1718(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002514:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	75c080e7          	jalr	1884(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002522:	854e                	mv	a0,s3
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	69e080e7          	jalr	1694(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    8000252c:	478d                	li	a5,3
    8000252e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002532:	854e                	mv	a0,s3
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	742080e7          	jalr	1858(ra) # 80000c76 <release>
}
    8000253c:	8556                	mv	a0,s5
    8000253e:	60a6                	ld	ra,72(sp)
    80002540:	6406                	ld	s0,64(sp)
    80002542:	74e2                	ld	s1,56(sp)
    80002544:	7942                	ld	s2,48(sp)
    80002546:	79a2                	ld	s3,40(sp)
    80002548:	7a02                	ld	s4,32(sp)
    8000254a:	6ae2                	ld	s5,24(sp)
    8000254c:	6b42                	ld	s6,16(sp)
    8000254e:	6ba2                	ld	s7,8(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret
  createSwapFile(np);
    80002554:	854e                	mv	a0,s3
    80002556:	00002097          	auipc	ra,0x2
    8000255a:	15a080e7          	jalr	346(ra) # 800046b0 <createSwapFile>
    8000255e:	b731                	j	8000246a <fork+0xfc>
    return -1;
    80002560:	5afd                	li	s5,-1
    80002562:	bfe9                	j	8000253c <fork+0x1ce>

0000000080002564 <scheduler>:
{
    80002564:	7139                	addi	sp,sp,-64
    80002566:	fc06                	sd	ra,56(sp)
    80002568:	f822                	sd	s0,48(sp)
    8000256a:	f426                	sd	s1,40(sp)
    8000256c:	f04a                	sd	s2,32(sp)
    8000256e:	ec4e                	sd	s3,24(sp)
    80002570:	e852                	sd	s4,16(sp)
    80002572:	e456                	sd	s5,8(sp)
    80002574:	e05a                	sd	s6,0(sp)
    80002576:	0080                	addi	s0,sp,64
    80002578:	8792                	mv	a5,tp
  int id = r_tp();
    8000257a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000257c:	00779a93          	slli	s5,a5,0x7
    80002580:	0000f717          	auipc	a4,0xf
    80002584:	d2070713          	addi	a4,a4,-736 # 800112a0 <pid_lock>
    80002588:	9756                	add	a4,a4,s5
    8000258a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000258e:	0000f717          	auipc	a4,0xf
    80002592:	d4a70713          	addi	a4,a4,-694 # 800112d8 <cpus+0x8>
    80002596:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002598:	498d                	li	s3,3
        p->state = RUNNING;
    8000259a:	4b11                	li	s6,4
        c->proc = p;
    8000259c:	079e                	slli	a5,a5,0x7
    8000259e:	0000fa17          	auipc	s4,0xf
    800025a2:	d02a0a13          	addi	s4,s4,-766 # 800112a0 <pid_lock>
    800025a6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800025a8:	00025917          	auipc	s2,0x25
    800025ac:	12890913          	addi	s2,s2,296 # 800276d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025b4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025b8:	10079073          	csrw	sstatus,a5
    800025bc:	0000f497          	auipc	s1,0xf
    800025c0:	11448493          	addi	s1,s1,276 # 800116d0 <proc>
    800025c4:	a811                	j	800025d8 <scheduler+0x74>
      release(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6ae080e7          	jalr	1710(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800025d0:	58048493          	addi	s1,s1,1408
    800025d4:	fd248ee3          	beq	s1,s2,800025b0 <scheduler+0x4c>
      acquire(&p->lock);
    800025d8:	8526                	mv	a0,s1
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	5e8080e7          	jalr	1512(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800025e2:	4c9c                	lw	a5,24(s1)
    800025e4:	ff3791e3          	bne	a5,s3,800025c6 <scheduler+0x62>
        p->state = RUNNING;
    800025e8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800025ec:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800025f0:	06048593          	addi	a1,s1,96
    800025f4:	8556                	mv	a0,s5
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	636080e7          	jalr	1590(ra) # 80002c2c <swtch>
        c->proc = 0;
    800025fe:	020a3823          	sd	zero,48(s4)
    80002602:	b7d1                	j	800025c6 <scheduler+0x62>

0000000080002604 <sched>:
{
    80002604:	7179                	addi	sp,sp,-48
    80002606:	f406                	sd	ra,40(sp)
    80002608:	f022                	sd	s0,32(sp)
    8000260a:	ec26                	sd	s1,24(sp)
    8000260c:	e84a                	sd	s2,16(sp)
    8000260e:	e44e                	sd	s3,8(sp)
    80002610:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002612:	00000097          	auipc	ra,0x0
    80002616:	938080e7          	jalr	-1736(ra) # 80001f4a <myproc>
    8000261a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	52c080e7          	jalr	1324(ra) # 80000b48 <holding>
    80002624:	c93d                	beqz	a0,8000269a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002626:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002628:	2781                	sext.w	a5,a5
    8000262a:	079e                	slli	a5,a5,0x7
    8000262c:	0000f717          	auipc	a4,0xf
    80002630:	c7470713          	addi	a4,a4,-908 # 800112a0 <pid_lock>
    80002634:	97ba                	add	a5,a5,a4
    80002636:	0a87a703          	lw	a4,168(a5)
    8000263a:	4785                	li	a5,1
    8000263c:	06f71763          	bne	a4,a5,800026aa <sched+0xa6>
  if(p->state == RUNNING)
    80002640:	4c98                	lw	a4,24(s1)
    80002642:	4791                	li	a5,4
    80002644:	06f70b63          	beq	a4,a5,800026ba <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002648:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000264c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000264e:	efb5                	bnez	a5,800026ca <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002650:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002652:	0000f917          	auipc	s2,0xf
    80002656:	c4e90913          	addi	s2,s2,-946 # 800112a0 <pid_lock>
    8000265a:	2781                	sext.w	a5,a5
    8000265c:	079e                	slli	a5,a5,0x7
    8000265e:	97ca                	add	a5,a5,s2
    80002660:	0ac7a983          	lw	s3,172(a5)
    80002664:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002666:	2781                	sext.w	a5,a5
    80002668:	079e                	slli	a5,a5,0x7
    8000266a:	0000f597          	auipc	a1,0xf
    8000266e:	c6e58593          	addi	a1,a1,-914 # 800112d8 <cpus+0x8>
    80002672:	95be                	add	a1,a1,a5
    80002674:	06048513          	addi	a0,s1,96
    80002678:	00000097          	auipc	ra,0x0
    8000267c:	5b4080e7          	jalr	1460(ra) # 80002c2c <swtch>
    80002680:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002682:	2781                	sext.w	a5,a5
    80002684:	079e                	slli	a5,a5,0x7
    80002686:	97ca                	add	a5,a5,s2
    80002688:	0b37a623          	sw	s3,172(a5)
}
    8000268c:	70a2                	ld	ra,40(sp)
    8000268e:	7402                	ld	s0,32(sp)
    80002690:	64e2                	ld	s1,24(sp)
    80002692:	6942                	ld	s2,16(sp)
    80002694:	69a2                	ld	s3,8(sp)
    80002696:	6145                	addi	sp,sp,48
    80002698:	8082                	ret
    panic("sched p->lock");
    8000269a:	00006517          	auipc	a0,0x6
    8000269e:	b9e50513          	addi	a0,a0,-1122 # 80008238 <digits+0x1f8>
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	e88080e7          	jalr	-376(ra) # 8000052a <panic>
    panic("sched locks");
    800026aa:	00006517          	auipc	a0,0x6
    800026ae:	b9e50513          	addi	a0,a0,-1122 # 80008248 <digits+0x208>
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	e78080e7          	jalr	-392(ra) # 8000052a <panic>
    panic("sched running");
    800026ba:	00006517          	auipc	a0,0x6
    800026be:	b9e50513          	addi	a0,a0,-1122 # 80008258 <digits+0x218>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	e68080e7          	jalr	-408(ra) # 8000052a <panic>
    panic("sched interruptible");
    800026ca:	00006517          	auipc	a0,0x6
    800026ce:	b9e50513          	addi	a0,a0,-1122 # 80008268 <digits+0x228>
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	e58080e7          	jalr	-424(ra) # 8000052a <panic>

00000000800026da <yield>:
{
    800026da:	1101                	addi	sp,sp,-32
    800026dc:	ec06                	sd	ra,24(sp)
    800026de:	e822                	sd	s0,16(sp)
    800026e0:	e426                	sd	s1,8(sp)
    800026e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026e4:	00000097          	auipc	ra,0x0
    800026e8:	866080e7          	jalr	-1946(ra) # 80001f4a <myproc>
    800026ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800026f6:	478d                	li	a5,3
    800026f8:	cc9c                	sw	a5,24(s1)
  sched();
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	f0a080e7          	jalr	-246(ra) # 80002604 <sched>
  release(&p->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	572080e7          	jalr	1394(ra) # 80000c76 <release>
}
    8000270c:	60e2                	ld	ra,24(sp)
    8000270e:	6442                	ld	s0,16(sp)
    80002710:	64a2                	ld	s1,8(sp)
    80002712:	6105                	addi	sp,sp,32
    80002714:	8082                	ret

0000000080002716 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002716:	7179                	addi	sp,sp,-48
    80002718:	f406                	sd	ra,40(sp)
    8000271a:	f022                	sd	s0,32(sp)
    8000271c:	ec26                	sd	s1,24(sp)
    8000271e:	e84a                	sd	s2,16(sp)
    80002720:	e44e                	sd	s3,8(sp)
    80002722:	1800                	addi	s0,sp,48
    80002724:	89aa                	mv	s3,a0
    80002726:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	822080e7          	jalr	-2014(ra) # 80001f4a <myproc>
    80002730:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	490080e7          	jalr	1168(ra) # 80000bc2 <acquire>
  release(lk);
    8000273a:	854a                	mv	a0,s2
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	53a080e7          	jalr	1338(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002744:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002748:	4789                	li	a5,2
    8000274a:	cc9c                	sw	a5,24(s1)

  sched();
    8000274c:	00000097          	auipc	ra,0x0
    80002750:	eb8080e7          	jalr	-328(ra) # 80002604 <sched>

  // Tidy up.
  p->chan = 0;
    80002754:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	51c080e7          	jalr	1308(ra) # 80000c76 <release>
  acquire(lk);
    80002762:	854a                	mv	a0,s2
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	45e080e7          	jalr	1118(ra) # 80000bc2 <acquire>
}
    8000276c:	70a2                	ld	ra,40(sp)
    8000276e:	7402                	ld	s0,32(sp)
    80002770:	64e2                	ld	s1,24(sp)
    80002772:	6942                	ld	s2,16(sp)
    80002774:	69a2                	ld	s3,8(sp)
    80002776:	6145                	addi	sp,sp,48
    80002778:	8082                	ret

000000008000277a <wait>:
{
    8000277a:	715d                	addi	sp,sp,-80
    8000277c:	e486                	sd	ra,72(sp)
    8000277e:	e0a2                	sd	s0,64(sp)
    80002780:	fc26                	sd	s1,56(sp)
    80002782:	f84a                	sd	s2,48(sp)
    80002784:	f44e                	sd	s3,40(sp)
    80002786:	f052                	sd	s4,32(sp)
    80002788:	ec56                	sd	s5,24(sp)
    8000278a:	e85a                	sd	s6,16(sp)
    8000278c:	e45e                	sd	s7,8(sp)
    8000278e:	e062                	sd	s8,0(sp)
    80002790:	0880                	addi	s0,sp,80
    80002792:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002794:	fffff097          	auipc	ra,0xfffff
    80002798:	7b6080e7          	jalr	1974(ra) # 80001f4a <myproc>
    8000279c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000279e:	0000f517          	auipc	a0,0xf
    800027a2:	b1a50513          	addi	a0,a0,-1254 # 800112b8 <wait_lock>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	41c080e7          	jalr	1052(ra) # 80000bc2 <acquire>
    havekids = 0;
    800027ae:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027b0:	4a15                	li	s4,5
        havekids = 1;
    800027b2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800027b4:	00025997          	auipc	s3,0x25
    800027b8:	f1c98993          	addi	s3,s3,-228 # 800276d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027bc:	0000fc17          	auipc	s8,0xf
    800027c0:	afcc0c13          	addi	s8,s8,-1284 # 800112b8 <wait_lock>
    havekids = 0;
    800027c4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027c6:	0000f497          	auipc	s1,0xf
    800027ca:	f0a48493          	addi	s1,s1,-246 # 800116d0 <proc>
    800027ce:	a0bd                	j	8000283c <wait+0xc2>
          pid = np->pid;
    800027d0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027d4:	000b0e63          	beqz	s6,800027f0 <wait+0x76>
    800027d8:	4691                	li	a3,4
    800027da:	02c48613          	addi	a2,s1,44
    800027de:	85da                	mv	a1,s6
    800027e0:	05093503          	ld	a0,80(s2)
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	e84080e7          	jalr	-380(ra) # 80001668 <copyout>
    800027ec:	02054563          	bltz	a0,80002816 <wait+0x9c>
          freeproc(np);
    800027f0:	8526                	mv	a0,s1
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	90a080e7          	jalr	-1782(ra) # 800020fc <freeproc>
          release(&np->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	47a080e7          	jalr	1146(ra) # 80000c76 <release>
          release(&wait_lock);
    80002804:	0000f517          	auipc	a0,0xf
    80002808:	ab450513          	addi	a0,a0,-1356 # 800112b8 <wait_lock>
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	46a080e7          	jalr	1130(ra) # 80000c76 <release>
          return pid;
    80002814:	a09d                	j	8000287a <wait+0x100>
            release(&np->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	45e080e7          	jalr	1118(ra) # 80000c76 <release>
            release(&wait_lock);
    80002820:	0000f517          	auipc	a0,0xf
    80002824:	a9850513          	addi	a0,a0,-1384 # 800112b8 <wait_lock>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	44e080e7          	jalr	1102(ra) # 80000c76 <release>
            return -1;
    80002830:	59fd                	li	s3,-1
    80002832:	a0a1                	j	8000287a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002834:	58048493          	addi	s1,s1,1408
    80002838:	03348463          	beq	s1,s3,80002860 <wait+0xe6>
      if(np->parent == p){
    8000283c:	7c9c                	ld	a5,56(s1)
    8000283e:	ff279be3          	bne	a5,s2,80002834 <wait+0xba>
        acquire(&np->lock);
    80002842:	8526                	mv	a0,s1
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	37e080e7          	jalr	894(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000284c:	4c9c                	lw	a5,24(s1)
    8000284e:	f94781e3          	beq	a5,s4,800027d0 <wait+0x56>
        release(&np->lock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	422080e7          	jalr	1058(ra) # 80000c76 <release>
        havekids = 1;
    8000285c:	8756                	mv	a4,s5
    8000285e:	bfd9                	j	80002834 <wait+0xba>
    if(!havekids || p->killed){
    80002860:	c701                	beqz	a4,80002868 <wait+0xee>
    80002862:	02892783          	lw	a5,40(s2)
    80002866:	c79d                	beqz	a5,80002894 <wait+0x11a>
      release(&wait_lock);
    80002868:	0000f517          	auipc	a0,0xf
    8000286c:	a5050513          	addi	a0,a0,-1456 # 800112b8 <wait_lock>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	406080e7          	jalr	1030(ra) # 80000c76 <release>
      return -1;
    80002878:	59fd                	li	s3,-1
}
    8000287a:	854e                	mv	a0,s3
    8000287c:	60a6                	ld	ra,72(sp)
    8000287e:	6406                	ld	s0,64(sp)
    80002880:	74e2                	ld	s1,56(sp)
    80002882:	7942                	ld	s2,48(sp)
    80002884:	79a2                	ld	s3,40(sp)
    80002886:	7a02                	ld	s4,32(sp)
    80002888:	6ae2                	ld	s5,24(sp)
    8000288a:	6b42                	ld	s6,16(sp)
    8000288c:	6ba2                	ld	s7,8(sp)
    8000288e:	6c02                	ld	s8,0(sp)
    80002890:	6161                	addi	sp,sp,80
    80002892:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002894:	85e2                	mv	a1,s8
    80002896:	854a                	mv	a0,s2
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	e7e080e7          	jalr	-386(ra) # 80002716 <sleep>
    havekids = 0;
    800028a0:	b715                	j	800027c4 <wait+0x4a>

00000000800028a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028a2:	7139                	addi	sp,sp,-64
    800028a4:	fc06                	sd	ra,56(sp)
    800028a6:	f822                	sd	s0,48(sp)
    800028a8:	f426                	sd	s1,40(sp)
    800028aa:	f04a                	sd	s2,32(sp)
    800028ac:	ec4e                	sd	s3,24(sp)
    800028ae:	e852                	sd	s4,16(sp)
    800028b0:	e456                	sd	s5,8(sp)
    800028b2:	0080                	addi	s0,sp,64
    800028b4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800028b6:	0000f497          	auipc	s1,0xf
    800028ba:	e1a48493          	addi	s1,s1,-486 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800028be:	4989                	li	s3,2
        p->state = RUNNABLE;
    800028c0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800028c2:	00025917          	auipc	s2,0x25
    800028c6:	e0e90913          	addi	s2,s2,-498 # 800276d0 <tickslock>
    800028ca:	a811                	j	800028de <wakeup+0x3c>
      }
      release(&p->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	3a8080e7          	jalr	936(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028d6:	58048493          	addi	s1,s1,1408
    800028da:	03248663          	beq	s1,s2,80002906 <wakeup+0x64>
    if(p != myproc()){
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	66c080e7          	jalr	1644(ra) # 80001f4a <myproc>
    800028e6:	fea488e3          	beq	s1,a0,800028d6 <wakeup+0x34>
      acquire(&p->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	2d6080e7          	jalr	726(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800028f4:	4c9c                	lw	a5,24(s1)
    800028f6:	fd379be3          	bne	a5,s3,800028cc <wakeup+0x2a>
    800028fa:	709c                	ld	a5,32(s1)
    800028fc:	fd4798e3          	bne	a5,s4,800028cc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002900:	0154ac23          	sw	s5,24(s1)
    80002904:	b7e1                	j	800028cc <wakeup+0x2a>
    }
  }
}
    80002906:	70e2                	ld	ra,56(sp)
    80002908:	7442                	ld	s0,48(sp)
    8000290a:	74a2                	ld	s1,40(sp)
    8000290c:	7902                	ld	s2,32(sp)
    8000290e:	69e2                	ld	s3,24(sp)
    80002910:	6a42                	ld	s4,16(sp)
    80002912:	6aa2                	ld	s5,8(sp)
    80002914:	6121                	addi	sp,sp,64
    80002916:	8082                	ret

0000000080002918 <reparent>:
{
    80002918:	7179                	addi	sp,sp,-48
    8000291a:	f406                	sd	ra,40(sp)
    8000291c:	f022                	sd	s0,32(sp)
    8000291e:	ec26                	sd	s1,24(sp)
    80002920:	e84a                	sd	s2,16(sp)
    80002922:	e44e                	sd	s3,8(sp)
    80002924:	e052                	sd	s4,0(sp)
    80002926:	1800                	addi	s0,sp,48
    80002928:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000292a:	0000f497          	auipc	s1,0xf
    8000292e:	da648493          	addi	s1,s1,-602 # 800116d0 <proc>
      pp->parent = initproc;
    80002932:	00006a17          	auipc	s4,0x6
    80002936:	6f6a0a13          	addi	s4,s4,1782 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000293a:	00025997          	auipc	s3,0x25
    8000293e:	d9698993          	addi	s3,s3,-618 # 800276d0 <tickslock>
    80002942:	a029                	j	8000294c <reparent+0x34>
    80002944:	58048493          	addi	s1,s1,1408
    80002948:	01348d63          	beq	s1,s3,80002962 <reparent+0x4a>
    if(pp->parent == p){
    8000294c:	7c9c                	ld	a5,56(s1)
    8000294e:	ff279be3          	bne	a5,s2,80002944 <reparent+0x2c>
      pp->parent = initproc;
    80002952:	000a3503          	ld	a0,0(s4)
    80002956:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	f4a080e7          	jalr	-182(ra) # 800028a2 <wakeup>
    80002960:	b7d5                	j	80002944 <reparent+0x2c>
}
    80002962:	70a2                	ld	ra,40(sp)
    80002964:	7402                	ld	s0,32(sp)
    80002966:	64e2                	ld	s1,24(sp)
    80002968:	6942                	ld	s2,16(sp)
    8000296a:	69a2                	ld	s3,8(sp)
    8000296c:	6a02                	ld	s4,0(sp)
    8000296e:	6145                	addi	sp,sp,48
    80002970:	8082                	ret

0000000080002972 <exit>:
{
    80002972:	7179                	addi	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	e052                	sd	s4,0(sp)
    80002980:	1800                	addi	s0,sp,48
    80002982:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	5c6080e7          	jalr	1478(ra) # 80001f4a <myproc>
    8000298c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000298e:	00006797          	auipc	a5,0x6
    80002992:	69a7b783          	ld	a5,1690(a5) # 80009028 <initproc>
    80002996:	0d050493          	addi	s1,a0,208
    8000299a:	15050913          	addi	s2,a0,336
    8000299e:	02a79363          	bne	a5,a0,800029c4 <exit+0x52>
    panic("init exiting");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	8de50513          	addi	a0,a0,-1826 # 80008280 <digits+0x240>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b80080e7          	jalr	-1152(ra) # 8000052a <panic>
      fileclose(f);
    800029b2:	00002097          	auipc	ra,0x2
    800029b6:	4a8080e7          	jalr	1192(ra) # 80004e5a <fileclose>
      p->ofile[fd] = 0;
    800029ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029be:	04a1                	addi	s1,s1,8
    800029c0:	01248563          	beq	s1,s2,800029ca <exit+0x58>
    if(p->ofile[fd]){
    800029c4:	6088                	ld	a0,0(s1)
    800029c6:	f575                	bnez	a0,800029b2 <exit+0x40>
    800029c8:	bfdd                	j	800029be <exit+0x4c>
  if(p->pid > 2) removeSwapFile(p);
    800029ca:	0309a703          	lw	a4,48(s3)
    800029ce:	4789                	li	a5,2
    800029d0:	08e7c163          	blt	a5,a4,80002a52 <exit+0xe0>
  begin_op();
    800029d4:	00002097          	auipc	ra,0x2
    800029d8:	fba080e7          	jalr	-70(ra) # 8000498e <begin_op>
  iput(p->cwd);
    800029dc:	1509b503          	ld	a0,336(s3)
    800029e0:	00001097          	auipc	ra,0x1
    800029e4:	480080e7          	jalr	1152(ra) # 80003e60 <iput>
  end_op();
    800029e8:	00002097          	auipc	ra,0x2
    800029ec:	026080e7          	jalr	38(ra) # 80004a0e <end_op>
  p->cwd = 0;
    800029f0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800029f4:	0000f497          	auipc	s1,0xf
    800029f8:	8c448493          	addi	s1,s1,-1852 # 800112b8 <wait_lock>
    800029fc:	8526                	mv	a0,s1
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	1c4080e7          	jalr	452(ra) # 80000bc2 <acquire>
  reparent(p);
    80002a06:	854e                	mv	a0,s3
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	f10080e7          	jalr	-240(ra) # 80002918 <reparent>
  wakeup(p->parent);
    80002a10:	0389b503          	ld	a0,56(s3)
    80002a14:	00000097          	auipc	ra,0x0
    80002a18:	e8e080e7          	jalr	-370(ra) # 800028a2 <wakeup>
  acquire(&p->lock);
    80002a1c:	854e                	mv	a0,s3
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	1a4080e7          	jalr	420(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002a26:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a2a:	4795                	li	a5,5
    80002a2c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002a30:	8526                	mv	a0,s1
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	244080e7          	jalr	580(ra) # 80000c76 <release>
  sched();
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	bca080e7          	jalr	-1078(ra) # 80002604 <sched>
  panic("zombie exit");
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	84e50513          	addi	a0,a0,-1970 # 80008290 <digits+0x250>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	ae0080e7          	jalr	-1312(ra) # 8000052a <panic>
  if(p->pid > 2) removeSwapFile(p);
    80002a52:	854e                	mv	a0,s3
    80002a54:	00002097          	auipc	ra,0x2
    80002a58:	ab4080e7          	jalr	-1356(ra) # 80004508 <removeSwapFile>
    80002a5c:	bfa5                	j	800029d4 <exit+0x62>

0000000080002a5e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a5e:	7179                	addi	sp,sp,-48
    80002a60:	f406                	sd	ra,40(sp)
    80002a62:	f022                	sd	s0,32(sp)
    80002a64:	ec26                	sd	s1,24(sp)
    80002a66:	e84a                	sd	s2,16(sp)
    80002a68:	e44e                	sd	s3,8(sp)
    80002a6a:	1800                	addi	s0,sp,48
    80002a6c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a6e:	0000f497          	auipc	s1,0xf
    80002a72:	c6248493          	addi	s1,s1,-926 # 800116d0 <proc>
    80002a76:	00025997          	auipc	s3,0x25
    80002a7a:	c5a98993          	addi	s3,s3,-934 # 800276d0 <tickslock>
    acquire(&p->lock);
    80002a7e:	8526                	mv	a0,s1
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	142080e7          	jalr	322(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002a88:	589c                	lw	a5,48(s1)
    80002a8a:	01278d63          	beq	a5,s2,80002aa4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a8e:	8526                	mv	a0,s1
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	1e6080e7          	jalr	486(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a98:	58048493          	addi	s1,s1,1408
    80002a9c:	ff3491e3          	bne	s1,s3,80002a7e <kill+0x20>
  }
  return -1;
    80002aa0:	557d                	li	a0,-1
    80002aa2:	a829                	j	80002abc <kill+0x5e>
      p->killed = 1;
    80002aa4:	4785                	li	a5,1
    80002aa6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002aa8:	4c98                	lw	a4,24(s1)
    80002aaa:	4789                	li	a5,2
    80002aac:	00f70f63          	beq	a4,a5,80002aca <kill+0x6c>
      release(&p->lock);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	1c4080e7          	jalr	452(ra) # 80000c76 <release>
      return 0;
    80002aba:	4501                	li	a0,0
}
    80002abc:	70a2                	ld	ra,40(sp)
    80002abe:	7402                	ld	s0,32(sp)
    80002ac0:	64e2                	ld	s1,24(sp)
    80002ac2:	6942                	ld	s2,16(sp)
    80002ac4:	69a2                	ld	s3,8(sp)
    80002ac6:	6145                	addi	sp,sp,48
    80002ac8:	8082                	ret
        p->state = RUNNABLE;
    80002aca:	478d                	li	a5,3
    80002acc:	cc9c                	sw	a5,24(s1)
    80002ace:	b7cd                	j	80002ab0 <kill+0x52>

0000000080002ad0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002ad0:	7179                	addi	sp,sp,-48
    80002ad2:	f406                	sd	ra,40(sp)
    80002ad4:	f022                	sd	s0,32(sp)
    80002ad6:	ec26                	sd	s1,24(sp)
    80002ad8:	e84a                	sd	s2,16(sp)
    80002ada:	e44e                	sd	s3,8(sp)
    80002adc:	e052                	sd	s4,0(sp)
    80002ade:	1800                	addi	s0,sp,48
    80002ae0:	84aa                	mv	s1,a0
    80002ae2:	892e                	mv	s2,a1
    80002ae4:	89b2                	mv	s3,a2
    80002ae6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	462080e7          	jalr	1122(ra) # 80001f4a <myproc>
  if(user_dst){
    80002af0:	c08d                	beqz	s1,80002b12 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002af2:	86d2                	mv	a3,s4
    80002af4:	864e                	mv	a2,s3
    80002af6:	85ca                	mv	a1,s2
    80002af8:	6928                	ld	a0,80(a0)
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	b6e080e7          	jalr	-1170(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b02:	70a2                	ld	ra,40(sp)
    80002b04:	7402                	ld	s0,32(sp)
    80002b06:	64e2                	ld	s1,24(sp)
    80002b08:	6942                	ld	s2,16(sp)
    80002b0a:	69a2                	ld	s3,8(sp)
    80002b0c:	6a02                	ld	s4,0(sp)
    80002b0e:	6145                	addi	sp,sp,48
    80002b10:	8082                	ret
    memmove((char *)dst, src, len);
    80002b12:	000a061b          	sext.w	a2,s4
    80002b16:	85ce                	mv	a1,s3
    80002b18:	854a                	mv	a0,s2
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	200080e7          	jalr	512(ra) # 80000d1a <memmove>
    return 0;
    80002b22:	8526                	mv	a0,s1
    80002b24:	bff9                	j	80002b02 <either_copyout+0x32>

0000000080002b26 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b26:	7179                	addi	sp,sp,-48
    80002b28:	f406                	sd	ra,40(sp)
    80002b2a:	f022                	sd	s0,32(sp)
    80002b2c:	ec26                	sd	s1,24(sp)
    80002b2e:	e84a                	sd	s2,16(sp)
    80002b30:	e44e                	sd	s3,8(sp)
    80002b32:	e052                	sd	s4,0(sp)
    80002b34:	1800                	addi	s0,sp,48
    80002b36:	892a                	mv	s2,a0
    80002b38:	84ae                	mv	s1,a1
    80002b3a:	89b2                	mv	s3,a2
    80002b3c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	40c080e7          	jalr	1036(ra) # 80001f4a <myproc>
  if(user_src){
    80002b46:	c08d                	beqz	s1,80002b68 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b48:	86d2                	mv	a3,s4
    80002b4a:	864e                	mv	a2,s3
    80002b4c:	85ca                	mv	a1,s2
    80002b4e:	6928                	ld	a0,80(a0)
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	ba4080e7          	jalr	-1116(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b58:	70a2                	ld	ra,40(sp)
    80002b5a:	7402                	ld	s0,32(sp)
    80002b5c:	64e2                	ld	s1,24(sp)
    80002b5e:	6942                	ld	s2,16(sp)
    80002b60:	69a2                	ld	s3,8(sp)
    80002b62:	6a02                	ld	s4,0(sp)
    80002b64:	6145                	addi	sp,sp,48
    80002b66:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b68:	000a061b          	sext.w	a2,s4
    80002b6c:	85ce                	mv	a1,s3
    80002b6e:	854a                	mv	a0,s2
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	1aa080e7          	jalr	426(ra) # 80000d1a <memmove>
    return 0;
    80002b78:	8526                	mv	a0,s1
    80002b7a:	bff9                	j	80002b58 <either_copyin+0x32>

0000000080002b7c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b7c:	715d                	addi	sp,sp,-80
    80002b7e:	e486                	sd	ra,72(sp)
    80002b80:	e0a2                	sd	s0,64(sp)
    80002b82:	fc26                	sd	s1,56(sp)
    80002b84:	f84a                	sd	s2,48(sp)
    80002b86:	f44e                	sd	s3,40(sp)
    80002b88:	f052                	sd	s4,32(sp)
    80002b8a:	ec56                	sd	s5,24(sp)
    80002b8c:	e85a                	sd	s6,16(sp)
    80002b8e:	e45e                	sd	s7,8(sp)
    80002b90:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b92:	00005517          	auipc	a0,0x5
    80002b96:	53650513          	addi	a0,a0,1334 # 800080c8 <digits+0x88>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9da080e7          	jalr	-1574(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ba2:	0000f497          	auipc	s1,0xf
    80002ba6:	c8648493          	addi	s1,s1,-890 # 80011828 <proc+0x158>
    80002baa:	00025917          	auipc	s2,0x25
    80002bae:	c7e90913          	addi	s2,s2,-898 # 80027828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bb2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002bb4:	00005997          	auipc	s3,0x5
    80002bb8:	6ec98993          	addi	s3,s3,1772 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002bbc:	00005a97          	auipc	s5,0x5
    80002bc0:	6eca8a93          	addi	s5,s5,1772 # 800082a8 <digits+0x268>
    printf("\n");
    80002bc4:	00005a17          	auipc	s4,0x5
    80002bc8:	504a0a13          	addi	s4,s4,1284 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bcc:	00005b97          	auipc	s7,0x5
    80002bd0:	714b8b93          	addi	s7,s7,1812 # 800082e0 <states.0>
    80002bd4:	a00d                	j	80002bf6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bd6:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002bda:	8556                	mv	a0,s5
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	998080e7          	jalr	-1640(ra) # 80000574 <printf>
    printf("\n");
    80002be4:	8552                	mv	a0,s4
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	98e080e7          	jalr	-1650(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bee:	58048493          	addi	s1,s1,1408
    80002bf2:	03248263          	beq	s1,s2,80002c16 <procdump+0x9a>
    if(p->state == UNUSED)
    80002bf6:	86a6                	mv	a3,s1
    80002bf8:	ec04a783          	lw	a5,-320(s1)
    80002bfc:	dbed                	beqz	a5,80002bee <procdump+0x72>
      state = "???";
    80002bfe:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c00:	fcfb6be3          	bltu	s6,a5,80002bd6 <procdump+0x5a>
    80002c04:	02079713          	slli	a4,a5,0x20
    80002c08:	01d75793          	srli	a5,a4,0x1d
    80002c0c:	97de                	add	a5,a5,s7
    80002c0e:	6390                	ld	a2,0(a5)
    80002c10:	f279                	bnez	a2,80002bd6 <procdump+0x5a>
      state = "???";
    80002c12:	864e                	mv	a2,s3
    80002c14:	b7c9                	j	80002bd6 <procdump+0x5a>
  }
}
    80002c16:	60a6                	ld	ra,72(sp)
    80002c18:	6406                	ld	s0,64(sp)
    80002c1a:	74e2                	ld	s1,56(sp)
    80002c1c:	7942                	ld	s2,48(sp)
    80002c1e:	79a2                	ld	s3,40(sp)
    80002c20:	7a02                	ld	s4,32(sp)
    80002c22:	6ae2                	ld	s5,24(sp)
    80002c24:	6b42                	ld	s6,16(sp)
    80002c26:	6ba2                	ld	s7,8(sp)
    80002c28:	6161                	addi	sp,sp,80
    80002c2a:	8082                	ret

0000000080002c2c <swtch>:
    80002c2c:	00153023          	sd	ra,0(a0)
    80002c30:	00253423          	sd	sp,8(a0)
    80002c34:	e900                	sd	s0,16(a0)
    80002c36:	ed04                	sd	s1,24(a0)
    80002c38:	03253023          	sd	s2,32(a0)
    80002c3c:	03353423          	sd	s3,40(a0)
    80002c40:	03453823          	sd	s4,48(a0)
    80002c44:	03553c23          	sd	s5,56(a0)
    80002c48:	05653023          	sd	s6,64(a0)
    80002c4c:	05753423          	sd	s7,72(a0)
    80002c50:	05853823          	sd	s8,80(a0)
    80002c54:	05953c23          	sd	s9,88(a0)
    80002c58:	07a53023          	sd	s10,96(a0)
    80002c5c:	07b53423          	sd	s11,104(a0)
    80002c60:	0005b083          	ld	ra,0(a1)
    80002c64:	0085b103          	ld	sp,8(a1)
    80002c68:	6980                	ld	s0,16(a1)
    80002c6a:	6d84                	ld	s1,24(a1)
    80002c6c:	0205b903          	ld	s2,32(a1)
    80002c70:	0285b983          	ld	s3,40(a1)
    80002c74:	0305ba03          	ld	s4,48(a1)
    80002c78:	0385ba83          	ld	s5,56(a1)
    80002c7c:	0405bb03          	ld	s6,64(a1)
    80002c80:	0485bb83          	ld	s7,72(a1)
    80002c84:	0505bc03          	ld	s8,80(a1)
    80002c88:	0585bc83          	ld	s9,88(a1)
    80002c8c:	0605bd03          	ld	s10,96(a1)
    80002c90:	0685bd83          	ld	s11,104(a1)
    80002c94:	8082                	ret

0000000080002c96 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c96:	1141                	addi	sp,sp,-16
    80002c98:	e406                	sd	ra,8(sp)
    80002c9a:	e022                	sd	s0,0(sp)
    80002c9c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c9e:	00005597          	auipc	a1,0x5
    80002ca2:	67258593          	addi	a1,a1,1650 # 80008310 <states.0+0x30>
    80002ca6:	00025517          	auipc	a0,0x25
    80002caa:	a2a50513          	addi	a0,a0,-1494 # 800276d0 <tickslock>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	e84080e7          	jalr	-380(ra) # 80000b32 <initlock>
}
    80002cb6:	60a2                	ld	ra,8(sp)
    80002cb8:	6402                	ld	s0,0(sp)
    80002cba:	0141                	addi	sp,sp,16
    80002cbc:	8082                	ret

0000000080002cbe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cbe:	1141                	addi	sp,sp,-16
    80002cc0:	e422                	sd	s0,8(sp)
    80002cc2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cc4:	00004797          	auipc	a5,0x4
    80002cc8:	a3c78793          	addi	a5,a5,-1476 # 80006700 <kernelvec>
    80002ccc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cd0:	6422                	ld	s0,8(sp)
    80002cd2:	0141                	addi	sp,sp,16
    80002cd4:	8082                	ret

0000000080002cd6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cd6:	1141                	addi	sp,sp,-16
    80002cd8:	e406                	sd	ra,8(sp)
    80002cda:	e022                	sd	s0,0(sp)
    80002cdc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	26c080e7          	jalr	620(ra) # 80001f4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cec:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cf0:	00004617          	auipc	a2,0x4
    80002cf4:	31060613          	addi	a2,a2,784 # 80007000 <_trampoline>
    80002cf8:	00004697          	auipc	a3,0x4
    80002cfc:	30868693          	addi	a3,a3,776 # 80007000 <_trampoline>
    80002d00:	8e91                	sub	a3,a3,a2
    80002d02:	040007b7          	lui	a5,0x4000
    80002d06:	17fd                	addi	a5,a5,-1
    80002d08:	07b2                	slli	a5,a5,0xc
    80002d0a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d0c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d10:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d12:	180026f3          	csrr	a3,satp
    80002d16:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d18:	6d38                	ld	a4,88(a0)
    80002d1a:	6134                	ld	a3,64(a0)
    80002d1c:	6585                	lui	a1,0x1
    80002d1e:	96ae                	add	a3,a3,a1
    80002d20:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d22:	6d38                	ld	a4,88(a0)
    80002d24:	00000697          	auipc	a3,0x0
    80002d28:	14e68693          	addi	a3,a3,334 # 80002e72 <usertrap>
    80002d2c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d2e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d30:	8692                	mv	a3,tp
    80002d32:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d34:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d38:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d3c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d40:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d44:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d46:	6f18                	ld	a4,24(a4)
    80002d48:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d4c:	692c                	ld	a1,80(a0)
    80002d4e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d50:	00004717          	auipc	a4,0x4
    80002d54:	34070713          	addi	a4,a4,832 # 80007090 <userret>
    80002d58:	8f11                	sub	a4,a4,a2
    80002d5a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d5c:	577d                	li	a4,-1
    80002d5e:	177e                	slli	a4,a4,0x3f
    80002d60:	8dd9                	or	a1,a1,a4
    80002d62:	02000537          	lui	a0,0x2000
    80002d66:	157d                	addi	a0,a0,-1
    80002d68:	0536                	slli	a0,a0,0xd
    80002d6a:	9782                	jalr	a5
}
    80002d6c:	60a2                	ld	ra,8(sp)
    80002d6e:	6402                	ld	s0,0(sp)
    80002d70:	0141                	addi	sp,sp,16
    80002d72:	8082                	ret

0000000080002d74 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	e426                	sd	s1,8(sp)
    80002d7c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d7e:	00025497          	auipc	s1,0x25
    80002d82:	95248493          	addi	s1,s1,-1710 # 800276d0 <tickslock>
    80002d86:	8526                	mv	a0,s1
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	e3a080e7          	jalr	-454(ra) # 80000bc2 <acquire>
  ticks++;
    80002d90:	00006517          	auipc	a0,0x6
    80002d94:	2a050513          	addi	a0,a0,672 # 80009030 <ticks>
    80002d98:	411c                	lw	a5,0(a0)
    80002d9a:	2785                	addiw	a5,a5,1
    80002d9c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	b04080e7          	jalr	-1276(ra) # 800028a2 <wakeup>
  release(&tickslock);
    80002da6:	8526                	mv	a0,s1
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	ece080e7          	jalr	-306(ra) # 80000c76 <release>
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc4:	142027f3          	csrr	a5,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dc8:	0007cc63          	bltz	a5,80002de0 <devintr+0x26>
    w_sip(r_sip() & ~2);

    return 2;
  }
  #ifndef NONE
  else if (scause == 13 || scause == 15){
    80002dcc:	9bf5                	andi	a5,a5,-3
    80002dce:	4735                	li	a4,13
    #endif
    return handle_pagefault();
  }
  #endif
  else {
    return 0;
    80002dd0:	4501                	li	a0,0
  else if (scause == 13 || scause == 15){
    80002dd2:	08e78b63          	beq	a5,a4,80002e68 <devintr+0xae>
  }
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	64a2                	ld	s1,8(sp)
    80002ddc:	6105                	addi	sp,sp,32
    80002dde:	8082                	ret
     (scause & 0xff) == 9){
    80002de0:	0ff7f713          	andi	a4,a5,255
  if((scause & 0x8000000000000000L) &&
    80002de4:	46a5                	li	a3,9
    80002de6:	00d70963          	beq	a4,a3,80002df8 <devintr+0x3e>
  } else if(scause == 0x8000000000000001L){
    80002dea:	577d                	li	a4,-1
    80002dec:	177e                	slli	a4,a4,0x3f
    80002dee:	0705                	addi	a4,a4,1
    80002df0:	04e78b63          	beq	a5,a4,80002e46 <devintr+0x8c>
    return 0;
    80002df4:	4501                	li	a0,0
    80002df6:	b7c5                	j	80002dd6 <devintr+0x1c>
    int irq = plic_claim();
    80002df8:	00004097          	auipc	ra,0x4
    80002dfc:	a10080e7          	jalr	-1520(ra) # 80006808 <plic_claim>
    80002e00:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e02:	47a9                	li	a5,10
    80002e04:	02f50763          	beq	a0,a5,80002e32 <devintr+0x78>
    } else if(irq == VIRTIO0_IRQ){
    80002e08:	4785                	li	a5,1
    80002e0a:	02f50963          	beq	a0,a5,80002e3c <devintr+0x82>
    return 1;
    80002e0e:	4505                	li	a0,1
    } else if(irq){
    80002e10:	d0f9                	beqz	s1,80002dd6 <devintr+0x1c>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e12:	85a6                	mv	a1,s1
    80002e14:	00005517          	auipc	a0,0x5
    80002e18:	50450513          	addi	a0,a0,1284 # 80008318 <states.0+0x38>
    80002e1c:	ffffd097          	auipc	ra,0xffffd
    80002e20:	758080e7          	jalr	1880(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e24:	8526                	mv	a0,s1
    80002e26:	00004097          	auipc	ra,0x4
    80002e2a:	a06080e7          	jalr	-1530(ra) # 8000682c <plic_complete>
    return 1;
    80002e2e:	4505                	li	a0,1
    80002e30:	b75d                	j	80002dd6 <devintr+0x1c>
      uartintr();
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	b54080e7          	jalr	-1196(ra) # 80000986 <uartintr>
    80002e3a:	b7ed                	j	80002e24 <devintr+0x6a>
      virtio_disk_intr();
    80002e3c:	00004097          	auipc	ra,0x4
    80002e40:	e82080e7          	jalr	-382(ra) # 80006cbe <virtio_disk_intr>
    80002e44:	b7c5                	j	80002e24 <devintr+0x6a>
    if(cpuid() == 0){
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	0d8080e7          	jalr	216(ra) # 80001f1e <cpuid>
    80002e4e:	c901                	beqz	a0,80002e5e <devintr+0xa4>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e50:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e54:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e56:	14479073          	csrw	sip,a5
    return 2;
    80002e5a:	4509                	li	a0,2
    80002e5c:	bfad                	j	80002dd6 <devintr+0x1c>
      clockintr();
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	f16080e7          	jalr	-234(ra) # 80002d74 <clockintr>
    80002e66:	b7ed                	j	80002e50 <devintr+0x96>
    return handle_pagefault();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	e44080e7          	jalr	-444(ra) # 80001cac <handle_pagefault>
    80002e70:	b79d                	j	80002dd6 <devintr+0x1c>

0000000080002e72 <usertrap>:
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	e426                	sd	s1,8(sp)
    80002e7a:	e04a                	sd	s2,0(sp)
    80002e7c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e7e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e82:	1007f793          	andi	a5,a5,256
    80002e86:	e3ad                	bnez	a5,80002ee8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e88:	00004797          	auipc	a5,0x4
    80002e8c:	87878793          	addi	a5,a5,-1928 # 80006700 <kernelvec>
    80002e90:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	0b6080e7          	jalr	182(ra) # 80001f4a <myproc>
    80002e9c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e9e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea0:	14102773          	csrr	a4,sepc
    80002ea4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ea6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002eaa:	47a1                	li	a5,8
    80002eac:	04f71c63          	bne	a4,a5,80002f04 <usertrap+0x92>
    if(p->killed)
    80002eb0:	551c                	lw	a5,40(a0)
    80002eb2:	e3b9                	bnez	a5,80002ef8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002eb4:	6cb8                	ld	a4,88(s1)
    80002eb6:	6f1c                	ld	a5,24(a4)
    80002eb8:	0791                	addi	a5,a5,4
    80002eba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ebc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ec0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ec4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	2e0080e7          	jalr	736(ra) # 800031a8 <syscall>
  if(p->killed)
    80002ed0:	549c                	lw	a5,40(s1)
    80002ed2:	ebc1                	bnez	a5,80002f62 <usertrap+0xf0>
  usertrapret();
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	e02080e7          	jalr	-510(ra) # 80002cd6 <usertrapret>
}
    80002edc:	60e2                	ld	ra,24(sp)
    80002ede:	6442                	ld	s0,16(sp)
    80002ee0:	64a2                	ld	s1,8(sp)
    80002ee2:	6902                	ld	s2,0(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	45050513          	addi	a0,a0,1104 # 80008338 <states.0+0x58>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	63a080e7          	jalr	1594(ra) # 8000052a <panic>
      exit(-1);
    80002ef8:	557d                	li	a0,-1
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	a78080e7          	jalr	-1416(ra) # 80002972 <exit>
    80002f02:	bf4d                	j	80002eb4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	eb6080e7          	jalr	-330(ra) # 80002dba <devintr>
    80002f0c:	892a                	mv	s2,a0
    80002f0e:	c501                	beqz	a0,80002f16 <usertrap+0xa4>
  if(p->killed)
    80002f10:	549c                	lw	a5,40(s1)
    80002f12:	c3a1                	beqz	a5,80002f52 <usertrap+0xe0>
    80002f14:	a815                	j	80002f48 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f16:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f1a:	5890                	lw	a2,48(s1)
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	43c50513          	addi	a0,a0,1084 # 80008358 <states.0+0x78>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	650080e7          	jalr	1616(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f30:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f34:	00005517          	auipc	a0,0x5
    80002f38:	45450513          	addi	a0,a0,1108 # 80008388 <states.0+0xa8>
    80002f3c:	ffffd097          	auipc	ra,0xffffd
    80002f40:	638080e7          	jalr	1592(ra) # 80000574 <printf>
    p->killed = 1;
    80002f44:	4785                	li	a5,1
    80002f46:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f48:	557d                	li	a0,-1
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	a28080e7          	jalr	-1496(ra) # 80002972 <exit>
  if(which_dev == 2)
    80002f52:	4789                	li	a5,2
    80002f54:	f8f910e3          	bne	s2,a5,80002ed4 <usertrap+0x62>
    yield();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	782080e7          	jalr	1922(ra) # 800026da <yield>
    80002f60:	bf95                	j	80002ed4 <usertrap+0x62>
  int which_dev = 0;
    80002f62:	4901                	li	s2,0
    80002f64:	b7d5                	j	80002f48 <usertrap+0xd6>

0000000080002f66 <kerneltrap>:
{
    80002f66:	7179                	addi	sp,sp,-48
    80002f68:	f406                	sd	ra,40(sp)
    80002f6a:	f022                	sd	s0,32(sp)
    80002f6c:	ec26                	sd	s1,24(sp)
    80002f6e:	e84a                	sd	s2,16(sp)
    80002f70:	e44e                	sd	s3,8(sp)
    80002f72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f80:	1004f793          	andi	a5,s1,256
    80002f84:	cb85                	beqz	a5,80002fb4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f8c:	ef85                	bnez	a5,80002fc4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f8e:	00000097          	auipc	ra,0x0
    80002f92:	e2c080e7          	jalr	-468(ra) # 80002dba <devintr>
    80002f96:	cd1d                	beqz	a0,80002fd4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f98:	4789                	li	a5,2
    80002f9a:	06f50a63          	beq	a0,a5,8000300e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa2:	10049073          	csrw	sstatus,s1
}
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6942                	ld	s2,16(sp)
    80002fae:	69a2                	ld	s3,8(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fb4:	00005517          	auipc	a0,0x5
    80002fb8:	3f450513          	addi	a0,a0,1012 # 800083a8 <states.0+0xc8>
    80002fbc:	ffffd097          	auipc	ra,0xffffd
    80002fc0:	56e080e7          	jalr	1390(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002fc4:	00005517          	auipc	a0,0x5
    80002fc8:	40c50513          	addi	a0,a0,1036 # 800083d0 <states.0+0xf0>
    80002fcc:	ffffd097          	auipc	ra,0xffffd
    80002fd0:	55e080e7          	jalr	1374(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002fd4:	85ce                	mv	a1,s3
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	41a50513          	addi	a0,a0,1050 # 800083f0 <states.0+0x110>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	596080e7          	jalr	1430(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fe6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fee:	00005517          	auipc	a0,0x5
    80002ff2:	41250513          	addi	a0,a0,1042 # 80008400 <states.0+0x120>
    80002ff6:	ffffd097          	auipc	ra,0xffffd
    80002ffa:	57e080e7          	jalr	1406(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	41a50513          	addi	a0,a0,1050 # 80008418 <states.0+0x138>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	524080e7          	jalr	1316(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	f3c080e7          	jalr	-196(ra) # 80001f4a <myproc>
    80003016:	d541                	beqz	a0,80002f9e <kerneltrap+0x38>
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	f32080e7          	jalr	-206(ra) # 80001f4a <myproc>
    80003020:	4d18                	lw	a4,24(a0)
    80003022:	4791                	li	a5,4
    80003024:	f6f71de3          	bne	a4,a5,80002f9e <kerneltrap+0x38>
    yield();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	6b2080e7          	jalr	1714(ra) # 800026da <yield>
    80003030:	b7bd                	j	80002f9e <kerneltrap+0x38>

0000000080003032 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	1000                	addi	s0,sp,32
    8000303c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	f0c080e7          	jalr	-244(ra) # 80001f4a <myproc>
  switch (n) {
    80003046:	4795                	li	a5,5
    80003048:	0497e163          	bltu	a5,s1,8000308a <argraw+0x58>
    8000304c:	048a                	slli	s1,s1,0x2
    8000304e:	00005717          	auipc	a4,0x5
    80003052:	40270713          	addi	a4,a4,1026 # 80008450 <states.0+0x170>
    80003056:	94ba                	add	s1,s1,a4
    80003058:	409c                	lw	a5,0(s1)
    8000305a:	97ba                	add	a5,a5,a4
    8000305c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000305e:	6d3c                	ld	a5,88(a0)
    80003060:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	64a2                	ld	s1,8(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret
    return p->trapframe->a1;
    8000306c:	6d3c                	ld	a5,88(a0)
    8000306e:	7fa8                	ld	a0,120(a5)
    80003070:	bfcd                	j	80003062 <argraw+0x30>
    return p->trapframe->a2;
    80003072:	6d3c                	ld	a5,88(a0)
    80003074:	63c8                	ld	a0,128(a5)
    80003076:	b7f5                	j	80003062 <argraw+0x30>
    return p->trapframe->a3;
    80003078:	6d3c                	ld	a5,88(a0)
    8000307a:	67c8                	ld	a0,136(a5)
    8000307c:	b7dd                	j	80003062 <argraw+0x30>
    return p->trapframe->a4;
    8000307e:	6d3c                	ld	a5,88(a0)
    80003080:	6bc8                	ld	a0,144(a5)
    80003082:	b7c5                	j	80003062 <argraw+0x30>
    return p->trapframe->a5;
    80003084:	6d3c                	ld	a5,88(a0)
    80003086:	6fc8                	ld	a0,152(a5)
    80003088:	bfe9                	j	80003062 <argraw+0x30>
  panic("argraw");
    8000308a:	00005517          	auipc	a0,0x5
    8000308e:	39e50513          	addi	a0,a0,926 # 80008428 <states.0+0x148>
    80003092:	ffffd097          	auipc	ra,0xffffd
    80003096:	498080e7          	jalr	1176(ra) # 8000052a <panic>

000000008000309a <fetchaddr>:
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	e04a                	sd	s2,0(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
    800030a8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	ea0080e7          	jalr	-352(ra) # 80001f4a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030b2:	653c                	ld	a5,72(a0)
    800030b4:	02f4f863          	bgeu	s1,a5,800030e4 <fetchaddr+0x4a>
    800030b8:	00848713          	addi	a4,s1,8
    800030bc:	02e7e663          	bltu	a5,a4,800030e8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030c0:	46a1                	li	a3,8
    800030c2:	8626                	mv	a2,s1
    800030c4:	85ca                	mv	a1,s2
    800030c6:	6928                	ld	a0,80(a0)
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	62c080e7          	jalr	1580(ra) # 800016f4 <copyin>
    800030d0:	00a03533          	snez	a0,a0
    800030d4:	40a00533          	neg	a0,a0
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6902                	ld	s2,0(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret
    return -1;
    800030e4:	557d                	li	a0,-1
    800030e6:	bfcd                	j	800030d8 <fetchaddr+0x3e>
    800030e8:	557d                	li	a0,-1
    800030ea:	b7fd                	j	800030d8 <fetchaddr+0x3e>

00000000800030ec <fetchstr>:
{
    800030ec:	7179                	addi	sp,sp,-48
    800030ee:	f406                	sd	ra,40(sp)
    800030f0:	f022                	sd	s0,32(sp)
    800030f2:	ec26                	sd	s1,24(sp)
    800030f4:	e84a                	sd	s2,16(sp)
    800030f6:	e44e                	sd	s3,8(sp)
    800030f8:	1800                	addi	s0,sp,48
    800030fa:	892a                	mv	s2,a0
    800030fc:	84ae                	mv	s1,a1
    800030fe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	e4a080e7          	jalr	-438(ra) # 80001f4a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003108:	86ce                	mv	a3,s3
    8000310a:	864a                	mv	a2,s2
    8000310c:	85a6                	mv	a1,s1
    8000310e:	6928                	ld	a0,80(a0)
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	672080e7          	jalr	1650(ra) # 80001782 <copyinstr>
  if(err < 0)
    80003118:	00054763          	bltz	a0,80003126 <fetchstr+0x3a>
  return strlen(buf);
    8000311c:	8526                	mv	a0,s1
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	d24080e7          	jalr	-732(ra) # 80000e42 <strlen>
}
    80003126:	70a2                	ld	ra,40(sp)
    80003128:	7402                	ld	s0,32(sp)
    8000312a:	64e2                	ld	s1,24(sp)
    8000312c:	6942                	ld	s2,16(sp)
    8000312e:	69a2                	ld	s3,8(sp)
    80003130:	6145                	addi	sp,sp,48
    80003132:	8082                	ret

0000000080003134 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	1000                	addi	s0,sp,32
    8000313e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003140:	00000097          	auipc	ra,0x0
    80003144:	ef2080e7          	jalr	-270(ra) # 80003032 <argraw>
    80003148:	c088                	sw	a0,0(s1)
  return 0;
}
    8000314a:	4501                	li	a0,0
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003162:	00000097          	auipc	ra,0x0
    80003166:	ed0080e7          	jalr	-304(ra) # 80003032 <argraw>
    8000316a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000316c:	4501                	li	a0,0
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	e04a                	sd	s2,0(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84ae                	mv	s1,a1
    80003186:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	eaa080e7          	jalr	-342(ra) # 80003032 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003190:	864a                	mv	a2,s2
    80003192:	85a6                	mv	a1,s1
    80003194:	00000097          	auipc	ra,0x0
    80003198:	f58080e7          	jalr	-168(ra) # 800030ec <fetchstr>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret

00000000800031a8 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	e426                	sd	s1,8(sp)
    800031b0:	e04a                	sd	s2,0(sp)
    800031b2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	d96080e7          	jalr	-618(ra) # 80001f4a <myproc>
    800031bc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031be:	05853903          	ld	s2,88(a0)
    800031c2:	0a893783          	ld	a5,168(s2)
    800031c6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031ca:	37fd                	addiw	a5,a5,-1
    800031cc:	4751                	li	a4,20
    800031ce:	00f76f63          	bltu	a4,a5,800031ec <syscall+0x44>
    800031d2:	00369713          	slli	a4,a3,0x3
    800031d6:	00005797          	auipc	a5,0x5
    800031da:	29278793          	addi	a5,a5,658 # 80008468 <syscalls>
    800031de:	97ba                	add	a5,a5,a4
    800031e0:	639c                	ld	a5,0(a5)
    800031e2:	c789                	beqz	a5,800031ec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031e4:	9782                	jalr	a5
    800031e6:	06a93823          	sd	a0,112(s2)
    800031ea:	a839                	j	80003208 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031ec:	15848613          	addi	a2,s1,344
    800031f0:	588c                	lw	a1,48(s1)
    800031f2:	00005517          	auipc	a0,0x5
    800031f6:	23e50513          	addi	a0,a0,574 # 80008430 <states.0+0x150>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	37a080e7          	jalr	890(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003202:	6cbc                	ld	a5,88(s1)
    80003204:	577d                	li	a4,-1
    80003206:	fbb8                	sd	a4,112(a5)
  }
}
    80003208:	60e2                	ld	ra,24(sp)
    8000320a:	6442                	ld	s0,16(sp)
    8000320c:	64a2                	ld	s1,8(sp)
    8000320e:	6902                	ld	s2,0(sp)
    80003210:	6105                	addi	sp,sp,32
    80003212:	8082                	ret

0000000080003214 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003214:	1101                	addi	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000321c:	fec40593          	addi	a1,s0,-20
    80003220:	4501                	li	a0,0
    80003222:	00000097          	auipc	ra,0x0
    80003226:	f12080e7          	jalr	-238(ra) # 80003134 <argint>
    return -1;
    8000322a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000322c:	00054963          	bltz	a0,8000323e <sys_exit+0x2a>
  exit(n);
    80003230:	fec42503          	lw	a0,-20(s0)
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	73e080e7          	jalr	1854(ra) # 80002972 <exit>
  return 0;  // not reached
    8000323c:	4781                	li	a5,0
}
    8000323e:	853e                	mv	a0,a5
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003248:	1141                	addi	sp,sp,-16
    8000324a:	e406                	sd	ra,8(sp)
    8000324c:	e022                	sd	s0,0(sp)
    8000324e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	cfa080e7          	jalr	-774(ra) # 80001f4a <myproc>
}
    80003258:	5908                	lw	a0,48(a0)
    8000325a:	60a2                	ld	ra,8(sp)
    8000325c:	6402                	ld	s0,0(sp)
    8000325e:	0141                	addi	sp,sp,16
    80003260:	8082                	ret

0000000080003262 <sys_fork>:

uint64
sys_fork(void)
{
    80003262:	1141                	addi	sp,sp,-16
    80003264:	e406                	sd	ra,8(sp)
    80003266:	e022                	sd	s0,0(sp)
    80003268:	0800                	addi	s0,sp,16
  return fork();
    8000326a:	fffff097          	auipc	ra,0xfffff
    8000326e:	104080e7          	jalr	260(ra) # 8000236e <fork>
}
    80003272:	60a2                	ld	ra,8(sp)
    80003274:	6402                	ld	s0,0(sp)
    80003276:	0141                	addi	sp,sp,16
    80003278:	8082                	ret

000000008000327a <sys_wait>:

uint64
sys_wait(void)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003282:	fe840593          	addi	a1,s0,-24
    80003286:	4501                	li	a0,0
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	ece080e7          	jalr	-306(ra) # 80003156 <argaddr>
    80003290:	87aa                	mv	a5,a0
    return -1;
    80003292:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003294:	0007c863          	bltz	a5,800032a4 <sys_wait+0x2a>
  return wait(p);
    80003298:	fe843503          	ld	a0,-24(s0)
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	4de080e7          	jalr	1246(ra) # 8000277a <wait>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032ac:	7179                	addi	sp,sp,-48
    800032ae:	f406                	sd	ra,40(sp)
    800032b0:	f022                	sd	s0,32(sp)
    800032b2:	ec26                	sd	s1,24(sp)
    800032b4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032b6:	fdc40593          	addi	a1,s0,-36
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e78080e7          	jalr	-392(ra) # 80003134 <argint>
    return -1;
    800032c4:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800032c6:	00054f63          	bltz	a0,800032e4 <sys_sbrk+0x38>
  addr = myproc()->sz;
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	c80080e7          	jalr	-896(ra) # 80001f4a <myproc>
    800032d2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032d4:	fdc42503          	lw	a0,-36(s0)
    800032d8:	fffff097          	auipc	ra,0xfffff
    800032dc:	022080e7          	jalr	34(ra) # 800022fa <growproc>
    800032e0:	00054863          	bltz	a0,800032f0 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800032e4:	8526                	mv	a0,s1
    800032e6:	70a2                	ld	ra,40(sp)
    800032e8:	7402                	ld	s0,32(sp)
    800032ea:	64e2                	ld	s1,24(sp)
    800032ec:	6145                	addi	sp,sp,48
    800032ee:	8082                	ret
    return -1;
    800032f0:	54fd                	li	s1,-1
    800032f2:	bfcd                	j	800032e4 <sys_sbrk+0x38>

00000000800032f4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032f4:	7139                	addi	sp,sp,-64
    800032f6:	fc06                	sd	ra,56(sp)
    800032f8:	f822                	sd	s0,48(sp)
    800032fa:	f426                	sd	s1,40(sp)
    800032fc:	f04a                	sd	s2,32(sp)
    800032fe:	ec4e                	sd	s3,24(sp)
    80003300:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003302:	fcc40593          	addi	a1,s0,-52
    80003306:	4501                	li	a0,0
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	e2c080e7          	jalr	-468(ra) # 80003134 <argint>
    return -1;
    80003310:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003312:	06054563          	bltz	a0,8000337c <sys_sleep+0x88>
  acquire(&tickslock);
    80003316:	00024517          	auipc	a0,0x24
    8000331a:	3ba50513          	addi	a0,a0,954 # 800276d0 <tickslock>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	8a4080e7          	jalr	-1884(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003326:	00006917          	auipc	s2,0x6
    8000332a:	d0a92903          	lw	s2,-758(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000332e:	fcc42783          	lw	a5,-52(s0)
    80003332:	cf85                	beqz	a5,8000336a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003334:	00024997          	auipc	s3,0x24
    80003338:	39c98993          	addi	s3,s3,924 # 800276d0 <tickslock>
    8000333c:	00006497          	auipc	s1,0x6
    80003340:	cf448493          	addi	s1,s1,-780 # 80009030 <ticks>
    if(myproc()->killed){
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	c06080e7          	jalr	-1018(ra) # 80001f4a <myproc>
    8000334c:	551c                	lw	a5,40(a0)
    8000334e:	ef9d                	bnez	a5,8000338c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003350:	85ce                	mv	a1,s3
    80003352:	8526                	mv	a0,s1
    80003354:	fffff097          	auipc	ra,0xfffff
    80003358:	3c2080e7          	jalr	962(ra) # 80002716 <sleep>
  while(ticks - ticks0 < n){
    8000335c:	409c                	lw	a5,0(s1)
    8000335e:	412787bb          	subw	a5,a5,s2
    80003362:	fcc42703          	lw	a4,-52(s0)
    80003366:	fce7efe3          	bltu	a5,a4,80003344 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000336a:	00024517          	auipc	a0,0x24
    8000336e:	36650513          	addi	a0,a0,870 # 800276d0 <tickslock>
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	904080e7          	jalr	-1788(ra) # 80000c76 <release>
  return 0;
    8000337a:	4781                	li	a5,0
}
    8000337c:	853e                	mv	a0,a5
    8000337e:	70e2                	ld	ra,56(sp)
    80003380:	7442                	ld	s0,48(sp)
    80003382:	74a2                	ld	s1,40(sp)
    80003384:	7902                	ld	s2,32(sp)
    80003386:	69e2                	ld	s3,24(sp)
    80003388:	6121                	addi	sp,sp,64
    8000338a:	8082                	ret
      release(&tickslock);
    8000338c:	00024517          	auipc	a0,0x24
    80003390:	34450513          	addi	a0,a0,836 # 800276d0 <tickslock>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	8e2080e7          	jalr	-1822(ra) # 80000c76 <release>
      return -1;
    8000339c:	57fd                	li	a5,-1
    8000339e:	bff9                	j	8000337c <sys_sleep+0x88>

00000000800033a0 <sys_kill>:

uint64
sys_kill(void)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033a8:	fec40593          	addi	a1,s0,-20
    800033ac:	4501                	li	a0,0
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	d86080e7          	jalr	-634(ra) # 80003134 <argint>
    800033b6:	87aa                	mv	a5,a0
    return -1;
    800033b8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033ba:	0007c863          	bltz	a5,800033ca <sys_kill+0x2a>
  return kill(pid);
    800033be:	fec42503          	lw	a0,-20(s0)
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	69c080e7          	jalr	1692(ra) # 80002a5e <kill>
}
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	6105                	addi	sp,sp,32
    800033d0:	8082                	ret

00000000800033d2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033dc:	00024517          	auipc	a0,0x24
    800033e0:	2f450513          	addi	a0,a0,756 # 800276d0 <tickslock>
    800033e4:	ffffd097          	auipc	ra,0xffffd
    800033e8:	7de080e7          	jalr	2014(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800033ec:	00006497          	auipc	s1,0x6
    800033f0:	c444a483          	lw	s1,-956(s1) # 80009030 <ticks>
  release(&tickslock);
    800033f4:	00024517          	auipc	a0,0x24
    800033f8:	2dc50513          	addi	a0,a0,732 # 800276d0 <tickslock>
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	87a080e7          	jalr	-1926(ra) # 80000c76 <release>
  return xticks;
}
    80003404:	02049513          	slli	a0,s1,0x20
    80003408:	9101                	srli	a0,a0,0x20
    8000340a:	60e2                	ld	ra,24(sp)
    8000340c:	6442                	ld	s0,16(sp)
    8000340e:	64a2                	ld	s1,8(sp)
    80003410:	6105                	addi	sp,sp,32
    80003412:	8082                	ret

0000000080003414 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003414:	7179                	addi	sp,sp,-48
    80003416:	f406                	sd	ra,40(sp)
    80003418:	f022                	sd	s0,32(sp)
    8000341a:	ec26                	sd	s1,24(sp)
    8000341c:	e84a                	sd	s2,16(sp)
    8000341e:	e44e                	sd	s3,8(sp)
    80003420:	e052                	sd	s4,0(sp)
    80003422:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003424:	00005597          	auipc	a1,0x5
    80003428:	0f458593          	addi	a1,a1,244 # 80008518 <syscalls+0xb0>
    8000342c:	00024517          	auipc	a0,0x24
    80003430:	2bc50513          	addi	a0,a0,700 # 800276e8 <bcache>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	6fe080e7          	jalr	1790(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000343c:	0002c797          	auipc	a5,0x2c
    80003440:	2ac78793          	addi	a5,a5,684 # 8002f6e8 <bcache+0x8000>
    80003444:	0002c717          	auipc	a4,0x2c
    80003448:	50c70713          	addi	a4,a4,1292 # 8002f950 <bcache+0x8268>
    8000344c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003450:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003454:	00024497          	auipc	s1,0x24
    80003458:	2ac48493          	addi	s1,s1,684 # 80027700 <bcache+0x18>
    b->next = bcache.head.next;
    8000345c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000345e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003460:	00005a17          	auipc	s4,0x5
    80003464:	0c0a0a13          	addi	s4,s4,192 # 80008520 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003468:	2b893783          	ld	a5,696(s2)
    8000346c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000346e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003472:	85d2                	mv	a1,s4
    80003474:	01048513          	addi	a0,s1,16
    80003478:	00001097          	auipc	ra,0x1
    8000347c:	7d4080e7          	jalr	2004(ra) # 80004c4c <initsleeplock>
    bcache.head.next->prev = b;
    80003480:	2b893783          	ld	a5,696(s2)
    80003484:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003486:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000348a:	45848493          	addi	s1,s1,1112
    8000348e:	fd349de3          	bne	s1,s3,80003468 <binit+0x54>
  }
}
    80003492:	70a2                	ld	ra,40(sp)
    80003494:	7402                	ld	s0,32(sp)
    80003496:	64e2                	ld	s1,24(sp)
    80003498:	6942                	ld	s2,16(sp)
    8000349a:	69a2                	ld	s3,8(sp)
    8000349c:	6a02                	ld	s4,0(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret

00000000800034a2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034a2:	7179                	addi	sp,sp,-48
    800034a4:	f406                	sd	ra,40(sp)
    800034a6:	f022                	sd	s0,32(sp)
    800034a8:	ec26                	sd	s1,24(sp)
    800034aa:	e84a                	sd	s2,16(sp)
    800034ac:	e44e                	sd	s3,8(sp)
    800034ae:	1800                	addi	s0,sp,48
    800034b0:	892a                	mv	s2,a0
    800034b2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034b4:	00024517          	auipc	a0,0x24
    800034b8:	23450513          	addi	a0,a0,564 # 800276e8 <bcache>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	706080e7          	jalr	1798(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034c4:	0002c497          	auipc	s1,0x2c
    800034c8:	4dc4b483          	ld	s1,1244(s1) # 8002f9a0 <bcache+0x82b8>
    800034cc:	0002c797          	auipc	a5,0x2c
    800034d0:	48478793          	addi	a5,a5,1156 # 8002f950 <bcache+0x8268>
    800034d4:	02f48f63          	beq	s1,a5,80003512 <bread+0x70>
    800034d8:	873e                	mv	a4,a5
    800034da:	a021                	j	800034e2 <bread+0x40>
    800034dc:	68a4                	ld	s1,80(s1)
    800034de:	02e48a63          	beq	s1,a4,80003512 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034e2:	449c                	lw	a5,8(s1)
    800034e4:	ff279ce3          	bne	a5,s2,800034dc <bread+0x3a>
    800034e8:	44dc                	lw	a5,12(s1)
    800034ea:	ff3799e3          	bne	a5,s3,800034dc <bread+0x3a>
      b->refcnt++;
    800034ee:	40bc                	lw	a5,64(s1)
    800034f0:	2785                	addiw	a5,a5,1
    800034f2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034f4:	00024517          	auipc	a0,0x24
    800034f8:	1f450513          	addi	a0,a0,500 # 800276e8 <bcache>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	77a080e7          	jalr	1914(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003504:	01048513          	addi	a0,s1,16
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	77e080e7          	jalr	1918(ra) # 80004c86 <acquiresleep>
      return b;
    80003510:	a8b9                	j	8000356e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003512:	0002c497          	auipc	s1,0x2c
    80003516:	4864b483          	ld	s1,1158(s1) # 8002f998 <bcache+0x82b0>
    8000351a:	0002c797          	auipc	a5,0x2c
    8000351e:	43678793          	addi	a5,a5,1078 # 8002f950 <bcache+0x8268>
    80003522:	00f48863          	beq	s1,a5,80003532 <bread+0x90>
    80003526:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003528:	40bc                	lw	a5,64(s1)
    8000352a:	cf81                	beqz	a5,80003542 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000352c:	64a4                	ld	s1,72(s1)
    8000352e:	fee49de3          	bne	s1,a4,80003528 <bread+0x86>
  panic("bget: no buffers");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	ff650513          	addi	a0,a0,-10 # 80008528 <syscalls+0xc0>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	ff0080e7          	jalr	-16(ra) # 8000052a <panic>
      b->dev = dev;
    80003542:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003546:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000354a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000354e:	4785                	li	a5,1
    80003550:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003552:	00024517          	auipc	a0,0x24
    80003556:	19650513          	addi	a0,a0,406 # 800276e8 <bcache>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	71c080e7          	jalr	1820(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003562:	01048513          	addi	a0,s1,16
    80003566:	00001097          	auipc	ra,0x1
    8000356a:	720080e7          	jalr	1824(ra) # 80004c86 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000356e:	409c                	lw	a5,0(s1)
    80003570:	cb89                	beqz	a5,80003582 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003572:	8526                	mv	a0,s1
    80003574:	70a2                	ld	ra,40(sp)
    80003576:	7402                	ld	s0,32(sp)
    80003578:	64e2                	ld	s1,24(sp)
    8000357a:	6942                	ld	s2,16(sp)
    8000357c:	69a2                	ld	s3,8(sp)
    8000357e:	6145                	addi	sp,sp,48
    80003580:	8082                	ret
    virtio_disk_rw(b, 0);
    80003582:	4581                	li	a1,0
    80003584:	8526                	mv	a0,s1
    80003586:	00003097          	auipc	ra,0x3
    8000358a:	4b0080e7          	jalr	1200(ra) # 80006a36 <virtio_disk_rw>
    b->valid = 1;
    8000358e:	4785                	li	a5,1
    80003590:	c09c                	sw	a5,0(s1)
  return b;
    80003592:	b7c5                	j	80003572 <bread+0xd0>

0000000080003594 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003594:	1101                	addi	sp,sp,-32
    80003596:	ec06                	sd	ra,24(sp)
    80003598:	e822                	sd	s0,16(sp)
    8000359a:	e426                	sd	s1,8(sp)
    8000359c:	1000                	addi	s0,sp,32
    8000359e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035a0:	0541                	addi	a0,a0,16
    800035a2:	00001097          	auipc	ra,0x1
    800035a6:	77e080e7          	jalr	1918(ra) # 80004d20 <holdingsleep>
    800035aa:	cd01                	beqz	a0,800035c2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035ac:	4585                	li	a1,1
    800035ae:	8526                	mv	a0,s1
    800035b0:	00003097          	auipc	ra,0x3
    800035b4:	486080e7          	jalr	1158(ra) # 80006a36 <virtio_disk_rw>
}
    800035b8:	60e2                	ld	ra,24(sp)
    800035ba:	6442                	ld	s0,16(sp)
    800035bc:	64a2                	ld	s1,8(sp)
    800035be:	6105                	addi	sp,sp,32
    800035c0:	8082                	ret
    panic("bwrite");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	f7e50513          	addi	a0,a0,-130 # 80008540 <syscalls+0xd8>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f60080e7          	jalr	-160(ra) # 8000052a <panic>

00000000800035d2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035d2:	1101                	addi	sp,sp,-32
    800035d4:	ec06                	sd	ra,24(sp)
    800035d6:	e822                	sd	s0,16(sp)
    800035d8:	e426                	sd	s1,8(sp)
    800035da:	e04a                	sd	s2,0(sp)
    800035dc:	1000                	addi	s0,sp,32
    800035de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035e0:	01050913          	addi	s2,a0,16
    800035e4:	854a                	mv	a0,s2
    800035e6:	00001097          	auipc	ra,0x1
    800035ea:	73a080e7          	jalr	1850(ra) # 80004d20 <holdingsleep>
    800035ee:	c92d                	beqz	a0,80003660 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	6ea080e7          	jalr	1770(ra) # 80004cdc <releasesleep>

  acquire(&bcache.lock);
    800035fa:	00024517          	auipc	a0,0x24
    800035fe:	0ee50513          	addi	a0,a0,238 # 800276e8 <bcache>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	5c0080e7          	jalr	1472(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000360a:	40bc                	lw	a5,64(s1)
    8000360c:	37fd                	addiw	a5,a5,-1
    8000360e:	0007871b          	sext.w	a4,a5
    80003612:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003614:	eb05                	bnez	a4,80003644 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003616:	68bc                	ld	a5,80(s1)
    80003618:	64b8                	ld	a4,72(s1)
    8000361a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000361c:	64bc                	ld	a5,72(s1)
    8000361e:	68b8                	ld	a4,80(s1)
    80003620:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003622:	0002c797          	auipc	a5,0x2c
    80003626:	0c678793          	addi	a5,a5,198 # 8002f6e8 <bcache+0x8000>
    8000362a:	2b87b703          	ld	a4,696(a5)
    8000362e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003630:	0002c717          	auipc	a4,0x2c
    80003634:	32070713          	addi	a4,a4,800 # 8002f950 <bcache+0x8268>
    80003638:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000363a:	2b87b703          	ld	a4,696(a5)
    8000363e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003640:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003644:	00024517          	auipc	a0,0x24
    80003648:	0a450513          	addi	a0,a0,164 # 800276e8 <bcache>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	62a080e7          	jalr	1578(ra) # 80000c76 <release>
}
    80003654:	60e2                	ld	ra,24(sp)
    80003656:	6442                	ld	s0,16(sp)
    80003658:	64a2                	ld	s1,8(sp)
    8000365a:	6902                	ld	s2,0(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret
    panic("brelse");
    80003660:	00005517          	auipc	a0,0x5
    80003664:	ee850513          	addi	a0,a0,-280 # 80008548 <syscalls+0xe0>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	ec2080e7          	jalr	-318(ra) # 8000052a <panic>

0000000080003670 <bpin>:

void
bpin(struct buf *b) {
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000367c:	00024517          	auipc	a0,0x24
    80003680:	06c50513          	addi	a0,a0,108 # 800276e8 <bcache>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	53e080e7          	jalr	1342(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000368c:	40bc                	lw	a5,64(s1)
    8000368e:	2785                	addiw	a5,a5,1
    80003690:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003692:	00024517          	auipc	a0,0x24
    80003696:	05650513          	addi	a0,a0,86 # 800276e8 <bcache>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	5dc080e7          	jalr	1500(ra) # 80000c76 <release>
}
    800036a2:	60e2                	ld	ra,24(sp)
    800036a4:	6442                	ld	s0,16(sp)
    800036a6:	64a2                	ld	s1,8(sp)
    800036a8:	6105                	addi	sp,sp,32
    800036aa:	8082                	ret

00000000800036ac <bunpin>:

void
bunpin(struct buf *b) {
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	1000                	addi	s0,sp,32
    800036b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036b8:	00024517          	auipc	a0,0x24
    800036bc:	03050513          	addi	a0,a0,48 # 800276e8 <bcache>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	502080e7          	jalr	1282(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800036c8:	40bc                	lw	a5,64(s1)
    800036ca:	37fd                	addiw	a5,a5,-1
    800036cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ce:	00024517          	auipc	a0,0x24
    800036d2:	01a50513          	addi	a0,a0,26 # 800276e8 <bcache>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	5a0080e7          	jalr	1440(ra) # 80000c76 <release>
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret

00000000800036e8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036e8:	1101                	addi	sp,sp,-32
    800036ea:	ec06                	sd	ra,24(sp)
    800036ec:	e822                	sd	s0,16(sp)
    800036ee:	e426                	sd	s1,8(sp)
    800036f0:	e04a                	sd	s2,0(sp)
    800036f2:	1000                	addi	s0,sp,32
    800036f4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036f6:	00d5d59b          	srliw	a1,a1,0xd
    800036fa:	0002c797          	auipc	a5,0x2c
    800036fe:	6ca7a783          	lw	a5,1738(a5) # 8002fdc4 <sb+0x1c>
    80003702:	9dbd                	addw	a1,a1,a5
    80003704:	00000097          	auipc	ra,0x0
    80003708:	d9e080e7          	jalr	-610(ra) # 800034a2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000370c:	0074f713          	andi	a4,s1,7
    80003710:	4785                	li	a5,1
    80003712:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003716:	14ce                	slli	s1,s1,0x33
    80003718:	90d9                	srli	s1,s1,0x36
    8000371a:	00950733          	add	a4,a0,s1
    8000371e:	05874703          	lbu	a4,88(a4)
    80003722:	00e7f6b3          	and	a3,a5,a4
    80003726:	c69d                	beqz	a3,80003754 <bfree+0x6c>
    80003728:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000372a:	94aa                	add	s1,s1,a0
    8000372c:	fff7c793          	not	a5,a5
    80003730:	8ff9                	and	a5,a5,a4
    80003732:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	430080e7          	jalr	1072(ra) # 80004b66 <log_write>
  brelse(bp);
    8000373e:	854a                	mv	a0,s2
    80003740:	00000097          	auipc	ra,0x0
    80003744:	e92080e7          	jalr	-366(ra) # 800035d2 <brelse>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6902                	ld	s2,0(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret
    panic("freeing free block");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	dfc50513          	addi	a0,a0,-516 # 80008550 <syscalls+0xe8>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	dce080e7          	jalr	-562(ra) # 8000052a <panic>

0000000080003764 <balloc>:
{
    80003764:	711d                	addi	sp,sp,-96
    80003766:	ec86                	sd	ra,88(sp)
    80003768:	e8a2                	sd	s0,80(sp)
    8000376a:	e4a6                	sd	s1,72(sp)
    8000376c:	e0ca                	sd	s2,64(sp)
    8000376e:	fc4e                	sd	s3,56(sp)
    80003770:	f852                	sd	s4,48(sp)
    80003772:	f456                	sd	s5,40(sp)
    80003774:	f05a                	sd	s6,32(sp)
    80003776:	ec5e                	sd	s7,24(sp)
    80003778:	e862                	sd	s8,16(sp)
    8000377a:	e466                	sd	s9,8(sp)
    8000377c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000377e:	0002c797          	auipc	a5,0x2c
    80003782:	62e7a783          	lw	a5,1582(a5) # 8002fdac <sb+0x4>
    80003786:	cbd1                	beqz	a5,8000381a <balloc+0xb6>
    80003788:	8baa                	mv	s7,a0
    8000378a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000378c:	0002cb17          	auipc	s6,0x2c
    80003790:	61cb0b13          	addi	s6,s6,1564 # 8002fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003794:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003796:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003798:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000379a:	6c89                	lui	s9,0x2
    8000379c:	a831                	j	800037b8 <balloc+0x54>
    brelse(bp);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	e32080e7          	jalr	-462(ra) # 800035d2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037a8:	015c87bb          	addw	a5,s9,s5
    800037ac:	00078a9b          	sext.w	s5,a5
    800037b0:	004b2703          	lw	a4,4(s6)
    800037b4:	06eaf363          	bgeu	s5,a4,8000381a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037b8:	41fad79b          	sraiw	a5,s5,0x1f
    800037bc:	0137d79b          	srliw	a5,a5,0x13
    800037c0:	015787bb          	addw	a5,a5,s5
    800037c4:	40d7d79b          	sraiw	a5,a5,0xd
    800037c8:	01cb2583          	lw	a1,28(s6)
    800037cc:	9dbd                	addw	a1,a1,a5
    800037ce:	855e                	mv	a0,s7
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	cd2080e7          	jalr	-814(ra) # 800034a2 <bread>
    800037d8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037da:	004b2503          	lw	a0,4(s6)
    800037de:	000a849b          	sext.w	s1,s5
    800037e2:	8662                	mv	a2,s8
    800037e4:	faa4fde3          	bgeu	s1,a0,8000379e <balloc+0x3a>
      m = 1 << (bi % 8);
    800037e8:	41f6579b          	sraiw	a5,a2,0x1f
    800037ec:	01d7d69b          	srliw	a3,a5,0x1d
    800037f0:	00c6873b          	addw	a4,a3,a2
    800037f4:	00777793          	andi	a5,a4,7
    800037f8:	9f95                	subw	a5,a5,a3
    800037fa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037fe:	4037571b          	sraiw	a4,a4,0x3
    80003802:	00e906b3          	add	a3,s2,a4
    80003806:	0586c683          	lbu	a3,88(a3)
    8000380a:	00d7f5b3          	and	a1,a5,a3
    8000380e:	cd91                	beqz	a1,8000382a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003810:	2605                	addiw	a2,a2,1
    80003812:	2485                	addiw	s1,s1,1
    80003814:	fd4618e3          	bne	a2,s4,800037e4 <balloc+0x80>
    80003818:	b759                	j	8000379e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000381a:	00005517          	auipc	a0,0x5
    8000381e:	d4e50513          	addi	a0,a0,-690 # 80008568 <syscalls+0x100>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d08080e7          	jalr	-760(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000382a:	974a                	add	a4,a4,s2
    8000382c:	8fd5                	or	a5,a5,a3
    8000382e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	332080e7          	jalr	818(ra) # 80004b66 <log_write>
        brelse(bp);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	d94080e7          	jalr	-620(ra) # 800035d2 <brelse>
  bp = bread(dev, bno);
    80003846:	85a6                	mv	a1,s1
    80003848:	855e                	mv	a0,s7
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	c58080e7          	jalr	-936(ra) # 800034a2 <bread>
    80003852:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003854:	40000613          	li	a2,1024
    80003858:	4581                	li	a1,0
    8000385a:	05850513          	addi	a0,a0,88
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	460080e7          	jalr	1120(ra) # 80000cbe <memset>
  log_write(bp);
    80003866:	854a                	mv	a0,s2
    80003868:	00001097          	auipc	ra,0x1
    8000386c:	2fe080e7          	jalr	766(ra) # 80004b66 <log_write>
  brelse(bp);
    80003870:	854a                	mv	a0,s2
    80003872:	00000097          	auipc	ra,0x0
    80003876:	d60080e7          	jalr	-672(ra) # 800035d2 <brelse>
}
    8000387a:	8526                	mv	a0,s1
    8000387c:	60e6                	ld	ra,88(sp)
    8000387e:	6446                	ld	s0,80(sp)
    80003880:	64a6                	ld	s1,72(sp)
    80003882:	6906                	ld	s2,64(sp)
    80003884:	79e2                	ld	s3,56(sp)
    80003886:	7a42                	ld	s4,48(sp)
    80003888:	7aa2                	ld	s5,40(sp)
    8000388a:	7b02                	ld	s6,32(sp)
    8000388c:	6be2                	ld	s7,24(sp)
    8000388e:	6c42                	ld	s8,16(sp)
    80003890:	6ca2                	ld	s9,8(sp)
    80003892:	6125                	addi	sp,sp,96
    80003894:	8082                	ret

0000000080003896 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003896:	7179                	addi	sp,sp,-48
    80003898:	f406                	sd	ra,40(sp)
    8000389a:	f022                	sd	s0,32(sp)
    8000389c:	ec26                	sd	s1,24(sp)
    8000389e:	e84a                	sd	s2,16(sp)
    800038a0:	e44e                	sd	s3,8(sp)
    800038a2:	e052                	sd	s4,0(sp)
    800038a4:	1800                	addi	s0,sp,48
    800038a6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038a8:	47ad                	li	a5,11
    800038aa:	04b7fe63          	bgeu	a5,a1,80003906 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038ae:	ff45849b          	addiw	s1,a1,-12
    800038b2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038b6:	0ff00793          	li	a5,255
    800038ba:	0ae7e463          	bltu	a5,a4,80003962 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038be:	08052583          	lw	a1,128(a0)
    800038c2:	c5b5                	beqz	a1,8000392e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038c4:	00092503          	lw	a0,0(s2)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	bda080e7          	jalr	-1062(ra) # 800034a2 <bread>
    800038d0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038d2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038d6:	02049713          	slli	a4,s1,0x20
    800038da:	01e75593          	srli	a1,a4,0x1e
    800038de:	00b784b3          	add	s1,a5,a1
    800038e2:	0004a983          	lw	s3,0(s1)
    800038e6:	04098e63          	beqz	s3,80003942 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038ea:	8552                	mv	a0,s4
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	ce6080e7          	jalr	-794(ra) # 800035d2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038f4:	854e                	mv	a0,s3
    800038f6:	70a2                	ld	ra,40(sp)
    800038f8:	7402                	ld	s0,32(sp)
    800038fa:	64e2                	ld	s1,24(sp)
    800038fc:	6942                	ld	s2,16(sp)
    800038fe:	69a2                	ld	s3,8(sp)
    80003900:	6a02                	ld	s4,0(sp)
    80003902:	6145                	addi	sp,sp,48
    80003904:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003906:	02059793          	slli	a5,a1,0x20
    8000390a:	01e7d593          	srli	a1,a5,0x1e
    8000390e:	00b504b3          	add	s1,a0,a1
    80003912:	0504a983          	lw	s3,80(s1)
    80003916:	fc099fe3          	bnez	s3,800038f4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000391a:	4108                	lw	a0,0(a0)
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	e48080e7          	jalr	-440(ra) # 80003764 <balloc>
    80003924:	0005099b          	sext.w	s3,a0
    80003928:	0534a823          	sw	s3,80(s1)
    8000392c:	b7e1                	j	800038f4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000392e:	4108                	lw	a0,0(a0)
    80003930:	00000097          	auipc	ra,0x0
    80003934:	e34080e7          	jalr	-460(ra) # 80003764 <balloc>
    80003938:	0005059b          	sext.w	a1,a0
    8000393c:	08b92023          	sw	a1,128(s2)
    80003940:	b751                	j	800038c4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003942:	00092503          	lw	a0,0(s2)
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	e1e080e7          	jalr	-482(ra) # 80003764 <balloc>
    8000394e:	0005099b          	sext.w	s3,a0
    80003952:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003956:	8552                	mv	a0,s4
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	20e080e7          	jalr	526(ra) # 80004b66 <log_write>
    80003960:	b769                	j	800038ea <bmap+0x54>
  panic("bmap: out of range");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	c1e50513          	addi	a0,a0,-994 # 80008580 <syscalls+0x118>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	bc0080e7          	jalr	-1088(ra) # 8000052a <panic>

0000000080003972 <iget>:
{
    80003972:	7179                	addi	sp,sp,-48
    80003974:	f406                	sd	ra,40(sp)
    80003976:	f022                	sd	s0,32(sp)
    80003978:	ec26                	sd	s1,24(sp)
    8000397a:	e84a                	sd	s2,16(sp)
    8000397c:	e44e                	sd	s3,8(sp)
    8000397e:	e052                	sd	s4,0(sp)
    80003980:	1800                	addi	s0,sp,48
    80003982:	89aa                	mv	s3,a0
    80003984:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003986:	0002c517          	auipc	a0,0x2c
    8000398a:	44250513          	addi	a0,a0,1090 # 8002fdc8 <itable>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	234080e7          	jalr	564(ra) # 80000bc2 <acquire>
  empty = 0;
    80003996:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003998:	0002c497          	auipc	s1,0x2c
    8000399c:	44848493          	addi	s1,s1,1096 # 8002fde0 <itable+0x18>
    800039a0:	0002e697          	auipc	a3,0x2e
    800039a4:	ed068693          	addi	a3,a3,-304 # 80031870 <log>
    800039a8:	a039                	j	800039b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039aa:	02090b63          	beqz	s2,800039e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039ae:	08848493          	addi	s1,s1,136
    800039b2:	02d48a63          	beq	s1,a3,800039e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039b6:	449c                	lw	a5,8(s1)
    800039b8:	fef059e3          	blez	a5,800039aa <iget+0x38>
    800039bc:	4098                	lw	a4,0(s1)
    800039be:	ff3716e3          	bne	a4,s3,800039aa <iget+0x38>
    800039c2:	40d8                	lw	a4,4(s1)
    800039c4:	ff4713e3          	bne	a4,s4,800039aa <iget+0x38>
      ip->ref++;
    800039c8:	2785                	addiw	a5,a5,1
    800039ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039cc:	0002c517          	auipc	a0,0x2c
    800039d0:	3fc50513          	addi	a0,a0,1020 # 8002fdc8 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	2a2080e7          	jalr	674(ra) # 80000c76 <release>
      return ip;
    800039dc:	8926                	mv	s2,s1
    800039de:	a03d                	j	80003a0c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039e0:	f7f9                	bnez	a5,800039ae <iget+0x3c>
    800039e2:	8926                	mv	s2,s1
    800039e4:	b7e9                	j	800039ae <iget+0x3c>
  if(empty == 0)
    800039e6:	02090c63          	beqz	s2,80003a1e <iget+0xac>
  ip->dev = dev;
    800039ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039f2:	4785                	li	a5,1
    800039f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039fc:	0002c517          	auipc	a0,0x2c
    80003a00:	3cc50513          	addi	a0,a0,972 # 8002fdc8 <itable>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	272080e7          	jalr	626(ra) # 80000c76 <release>
}
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	70a2                	ld	ra,40(sp)
    80003a10:	7402                	ld	s0,32(sp)
    80003a12:	64e2                	ld	s1,24(sp)
    80003a14:	6942                	ld	s2,16(sp)
    80003a16:	69a2                	ld	s3,8(sp)
    80003a18:	6a02                	ld	s4,0(sp)
    80003a1a:	6145                	addi	sp,sp,48
    80003a1c:	8082                	ret
    panic("iget: no inodes");
    80003a1e:	00005517          	auipc	a0,0x5
    80003a22:	b7a50513          	addi	a0,a0,-1158 # 80008598 <syscalls+0x130>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	b04080e7          	jalr	-1276(ra) # 8000052a <panic>

0000000080003a2e <fsinit>:
fsinit(int dev) {
    80003a2e:	7179                	addi	sp,sp,-48
    80003a30:	f406                	sd	ra,40(sp)
    80003a32:	f022                	sd	s0,32(sp)
    80003a34:	ec26                	sd	s1,24(sp)
    80003a36:	e84a                	sd	s2,16(sp)
    80003a38:	e44e                	sd	s3,8(sp)
    80003a3a:	1800                	addi	s0,sp,48
    80003a3c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a3e:	4585                	li	a1,1
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	a62080e7          	jalr	-1438(ra) # 800034a2 <bread>
    80003a48:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a4a:	0002c997          	auipc	s3,0x2c
    80003a4e:	35e98993          	addi	s3,s3,862 # 8002fda8 <sb>
    80003a52:	02000613          	li	a2,32
    80003a56:	05850593          	addi	a1,a0,88
    80003a5a:	854e                	mv	a0,s3
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	2be080e7          	jalr	702(ra) # 80000d1a <memmove>
  brelse(bp);
    80003a64:	8526                	mv	a0,s1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	b6c080e7          	jalr	-1172(ra) # 800035d2 <brelse>
  if(sb.magic != FSMAGIC)
    80003a6e:	0009a703          	lw	a4,0(s3)
    80003a72:	102037b7          	lui	a5,0x10203
    80003a76:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a7a:	02f71263          	bne	a4,a5,80003a9e <fsinit+0x70>
  initlog(dev, &sb);
    80003a7e:	0002c597          	auipc	a1,0x2c
    80003a82:	32a58593          	addi	a1,a1,810 # 8002fda8 <sb>
    80003a86:	854a                	mv	a0,s2
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	e60080e7          	jalr	-416(ra) # 800048e8 <initlog>
}
    80003a90:	70a2                	ld	ra,40(sp)
    80003a92:	7402                	ld	s0,32(sp)
    80003a94:	64e2                	ld	s1,24(sp)
    80003a96:	6942                	ld	s2,16(sp)
    80003a98:	69a2                	ld	s3,8(sp)
    80003a9a:	6145                	addi	sp,sp,48
    80003a9c:	8082                	ret
    panic("invalid file system");
    80003a9e:	00005517          	auipc	a0,0x5
    80003aa2:	b0a50513          	addi	a0,a0,-1270 # 800085a8 <syscalls+0x140>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	a84080e7          	jalr	-1404(ra) # 8000052a <panic>

0000000080003aae <iinit>:
{
    80003aae:	7179                	addi	sp,sp,-48
    80003ab0:	f406                	sd	ra,40(sp)
    80003ab2:	f022                	sd	s0,32(sp)
    80003ab4:	ec26                	sd	s1,24(sp)
    80003ab6:	e84a                	sd	s2,16(sp)
    80003ab8:	e44e                	sd	s3,8(sp)
    80003aba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003abc:	00005597          	auipc	a1,0x5
    80003ac0:	b0458593          	addi	a1,a1,-1276 # 800085c0 <syscalls+0x158>
    80003ac4:	0002c517          	auipc	a0,0x2c
    80003ac8:	30450513          	addi	a0,a0,772 # 8002fdc8 <itable>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	066080e7          	jalr	102(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ad4:	0002c497          	auipc	s1,0x2c
    80003ad8:	31c48493          	addi	s1,s1,796 # 8002fdf0 <itable+0x28>
    80003adc:	0002e997          	auipc	s3,0x2e
    80003ae0:	da498993          	addi	s3,s3,-604 # 80031880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ae4:	00005917          	auipc	s2,0x5
    80003ae8:	ae490913          	addi	s2,s2,-1308 # 800085c8 <syscalls+0x160>
    80003aec:	85ca                	mv	a1,s2
    80003aee:	8526                	mv	a0,s1
    80003af0:	00001097          	auipc	ra,0x1
    80003af4:	15c080e7          	jalr	348(ra) # 80004c4c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003af8:	08848493          	addi	s1,s1,136
    80003afc:	ff3498e3          	bne	s1,s3,80003aec <iinit+0x3e>
}
    80003b00:	70a2                	ld	ra,40(sp)
    80003b02:	7402                	ld	s0,32(sp)
    80003b04:	64e2                	ld	s1,24(sp)
    80003b06:	6942                	ld	s2,16(sp)
    80003b08:	69a2                	ld	s3,8(sp)
    80003b0a:	6145                	addi	sp,sp,48
    80003b0c:	8082                	ret

0000000080003b0e <ialloc>:
{
    80003b0e:	715d                	addi	sp,sp,-80
    80003b10:	e486                	sd	ra,72(sp)
    80003b12:	e0a2                	sd	s0,64(sp)
    80003b14:	fc26                	sd	s1,56(sp)
    80003b16:	f84a                	sd	s2,48(sp)
    80003b18:	f44e                	sd	s3,40(sp)
    80003b1a:	f052                	sd	s4,32(sp)
    80003b1c:	ec56                	sd	s5,24(sp)
    80003b1e:	e85a                	sd	s6,16(sp)
    80003b20:	e45e                	sd	s7,8(sp)
    80003b22:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b24:	0002c717          	auipc	a4,0x2c
    80003b28:	29072703          	lw	a4,656(a4) # 8002fdb4 <sb+0xc>
    80003b2c:	4785                	li	a5,1
    80003b2e:	04e7fa63          	bgeu	a5,a4,80003b82 <ialloc+0x74>
    80003b32:	8aaa                	mv	s5,a0
    80003b34:	8bae                	mv	s7,a1
    80003b36:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b38:	0002ca17          	auipc	s4,0x2c
    80003b3c:	270a0a13          	addi	s4,s4,624 # 8002fda8 <sb>
    80003b40:	00048b1b          	sext.w	s6,s1
    80003b44:	0044d793          	srli	a5,s1,0x4
    80003b48:	018a2583          	lw	a1,24(s4)
    80003b4c:	9dbd                	addw	a1,a1,a5
    80003b4e:	8556                	mv	a0,s5
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	952080e7          	jalr	-1710(ra) # 800034a2 <bread>
    80003b58:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b5a:	05850993          	addi	s3,a0,88
    80003b5e:	00f4f793          	andi	a5,s1,15
    80003b62:	079a                	slli	a5,a5,0x6
    80003b64:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b66:	00099783          	lh	a5,0(s3)
    80003b6a:	c785                	beqz	a5,80003b92 <ialloc+0x84>
    brelse(bp);
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	a66080e7          	jalr	-1434(ra) # 800035d2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b74:	0485                	addi	s1,s1,1
    80003b76:	00ca2703          	lw	a4,12(s4)
    80003b7a:	0004879b          	sext.w	a5,s1
    80003b7e:	fce7e1e3          	bltu	a5,a4,80003b40 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b82:	00005517          	auipc	a0,0x5
    80003b86:	a4e50513          	addi	a0,a0,-1458 # 800085d0 <syscalls+0x168>
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	9a0080e7          	jalr	-1632(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003b92:	04000613          	li	a2,64
    80003b96:	4581                	li	a1,0
    80003b98:	854e                	mv	a0,s3
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	124080e7          	jalr	292(ra) # 80000cbe <memset>
      dip->type = type;
    80003ba2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	00001097          	auipc	ra,0x1
    80003bac:	fbe080e7          	jalr	-66(ra) # 80004b66 <log_write>
      brelse(bp);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	a20080e7          	jalr	-1504(ra) # 800035d2 <brelse>
      return iget(dev, inum);
    80003bba:	85da                	mv	a1,s6
    80003bbc:	8556                	mv	a0,s5
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	db4080e7          	jalr	-588(ra) # 80003972 <iget>
}
    80003bc6:	60a6                	ld	ra,72(sp)
    80003bc8:	6406                	ld	s0,64(sp)
    80003bca:	74e2                	ld	s1,56(sp)
    80003bcc:	7942                	ld	s2,48(sp)
    80003bce:	79a2                	ld	s3,40(sp)
    80003bd0:	7a02                	ld	s4,32(sp)
    80003bd2:	6ae2                	ld	s5,24(sp)
    80003bd4:	6b42                	ld	s6,16(sp)
    80003bd6:	6ba2                	ld	s7,8(sp)
    80003bd8:	6161                	addi	sp,sp,80
    80003bda:	8082                	ret

0000000080003bdc <iupdate>:
{
    80003bdc:	1101                	addi	sp,sp,-32
    80003bde:	ec06                	sd	ra,24(sp)
    80003be0:	e822                	sd	s0,16(sp)
    80003be2:	e426                	sd	s1,8(sp)
    80003be4:	e04a                	sd	s2,0(sp)
    80003be6:	1000                	addi	s0,sp,32
    80003be8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bea:	415c                	lw	a5,4(a0)
    80003bec:	0047d79b          	srliw	a5,a5,0x4
    80003bf0:	0002c597          	auipc	a1,0x2c
    80003bf4:	1d05a583          	lw	a1,464(a1) # 8002fdc0 <sb+0x18>
    80003bf8:	9dbd                	addw	a1,a1,a5
    80003bfa:	4108                	lw	a0,0(a0)
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	8a6080e7          	jalr	-1882(ra) # 800034a2 <bread>
    80003c04:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c06:	05850793          	addi	a5,a0,88
    80003c0a:	40c8                	lw	a0,4(s1)
    80003c0c:	893d                	andi	a0,a0,15
    80003c0e:	051a                	slli	a0,a0,0x6
    80003c10:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c12:	04449703          	lh	a4,68(s1)
    80003c16:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c1a:	04649703          	lh	a4,70(s1)
    80003c1e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c22:	04849703          	lh	a4,72(s1)
    80003c26:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c2a:	04a49703          	lh	a4,74(s1)
    80003c2e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c32:	44f8                	lw	a4,76(s1)
    80003c34:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c36:	03400613          	li	a2,52
    80003c3a:	05048593          	addi	a1,s1,80
    80003c3e:	0531                	addi	a0,a0,12
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	0da080e7          	jalr	218(ra) # 80000d1a <memmove>
  log_write(bp);
    80003c48:	854a                	mv	a0,s2
    80003c4a:	00001097          	auipc	ra,0x1
    80003c4e:	f1c080e7          	jalr	-228(ra) # 80004b66 <log_write>
  brelse(bp);
    80003c52:	854a                	mv	a0,s2
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	97e080e7          	jalr	-1666(ra) # 800035d2 <brelse>
}
    80003c5c:	60e2                	ld	ra,24(sp)
    80003c5e:	6442                	ld	s0,16(sp)
    80003c60:	64a2                	ld	s1,8(sp)
    80003c62:	6902                	ld	s2,0(sp)
    80003c64:	6105                	addi	sp,sp,32
    80003c66:	8082                	ret

0000000080003c68 <idup>:
{
    80003c68:	1101                	addi	sp,sp,-32
    80003c6a:	ec06                	sd	ra,24(sp)
    80003c6c:	e822                	sd	s0,16(sp)
    80003c6e:	e426                	sd	s1,8(sp)
    80003c70:	1000                	addi	s0,sp,32
    80003c72:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c74:	0002c517          	auipc	a0,0x2c
    80003c78:	15450513          	addi	a0,a0,340 # 8002fdc8 <itable>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	f46080e7          	jalr	-186(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003c84:	449c                	lw	a5,8(s1)
    80003c86:	2785                	addiw	a5,a5,1
    80003c88:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c8a:	0002c517          	auipc	a0,0x2c
    80003c8e:	13e50513          	addi	a0,a0,318 # 8002fdc8 <itable>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	fe4080e7          	jalr	-28(ra) # 80000c76 <release>
}
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	60e2                	ld	ra,24(sp)
    80003c9e:	6442                	ld	s0,16(sp)
    80003ca0:	64a2                	ld	s1,8(sp)
    80003ca2:	6105                	addi	sp,sp,32
    80003ca4:	8082                	ret

0000000080003ca6 <ilock>:
{
    80003ca6:	1101                	addi	sp,sp,-32
    80003ca8:	ec06                	sd	ra,24(sp)
    80003caa:	e822                	sd	s0,16(sp)
    80003cac:	e426                	sd	s1,8(sp)
    80003cae:	e04a                	sd	s2,0(sp)
    80003cb0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cb2:	c115                	beqz	a0,80003cd6 <ilock+0x30>
    80003cb4:	84aa                	mv	s1,a0
    80003cb6:	451c                	lw	a5,8(a0)
    80003cb8:	00f05f63          	blez	a5,80003cd6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cbc:	0541                	addi	a0,a0,16
    80003cbe:	00001097          	auipc	ra,0x1
    80003cc2:	fc8080e7          	jalr	-56(ra) # 80004c86 <acquiresleep>
  if(ip->valid == 0){
    80003cc6:	40bc                	lw	a5,64(s1)
    80003cc8:	cf99                	beqz	a5,80003ce6 <ilock+0x40>
}
    80003cca:	60e2                	ld	ra,24(sp)
    80003ccc:	6442                	ld	s0,16(sp)
    80003cce:	64a2                	ld	s1,8(sp)
    80003cd0:	6902                	ld	s2,0(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret
    panic("ilock");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	91250513          	addi	a0,a0,-1774 # 800085e8 <syscalls+0x180>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	84c080e7          	jalr	-1972(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ce6:	40dc                	lw	a5,4(s1)
    80003ce8:	0047d79b          	srliw	a5,a5,0x4
    80003cec:	0002c597          	auipc	a1,0x2c
    80003cf0:	0d45a583          	lw	a1,212(a1) # 8002fdc0 <sb+0x18>
    80003cf4:	9dbd                	addw	a1,a1,a5
    80003cf6:	4088                	lw	a0,0(s1)
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	7aa080e7          	jalr	1962(ra) # 800034a2 <bread>
    80003d00:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d02:	05850593          	addi	a1,a0,88
    80003d06:	40dc                	lw	a5,4(s1)
    80003d08:	8bbd                	andi	a5,a5,15
    80003d0a:	079a                	slli	a5,a5,0x6
    80003d0c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d0e:	00059783          	lh	a5,0(a1)
    80003d12:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d16:	00259783          	lh	a5,2(a1)
    80003d1a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d1e:	00459783          	lh	a5,4(a1)
    80003d22:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d26:	00659783          	lh	a5,6(a1)
    80003d2a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d2e:	459c                	lw	a5,8(a1)
    80003d30:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d32:	03400613          	li	a2,52
    80003d36:	05b1                	addi	a1,a1,12
    80003d38:	05048513          	addi	a0,s1,80
    80003d3c:	ffffd097          	auipc	ra,0xffffd
    80003d40:	fde080e7          	jalr	-34(ra) # 80000d1a <memmove>
    brelse(bp);
    80003d44:	854a                	mv	a0,s2
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	88c080e7          	jalr	-1908(ra) # 800035d2 <brelse>
    ip->valid = 1;
    80003d4e:	4785                	li	a5,1
    80003d50:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d52:	04449783          	lh	a5,68(s1)
    80003d56:	fbb5                	bnez	a5,80003cca <ilock+0x24>
      panic("ilock: no type");
    80003d58:	00005517          	auipc	a0,0x5
    80003d5c:	89850513          	addi	a0,a0,-1896 # 800085f0 <syscalls+0x188>
    80003d60:	ffffc097          	auipc	ra,0xffffc
    80003d64:	7ca080e7          	jalr	1994(ra) # 8000052a <panic>

0000000080003d68 <iunlock>:
{
    80003d68:	1101                	addi	sp,sp,-32
    80003d6a:	ec06                	sd	ra,24(sp)
    80003d6c:	e822                	sd	s0,16(sp)
    80003d6e:	e426                	sd	s1,8(sp)
    80003d70:	e04a                	sd	s2,0(sp)
    80003d72:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d74:	c905                	beqz	a0,80003da4 <iunlock+0x3c>
    80003d76:	84aa                	mv	s1,a0
    80003d78:	01050913          	addi	s2,a0,16
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	00001097          	auipc	ra,0x1
    80003d82:	fa2080e7          	jalr	-94(ra) # 80004d20 <holdingsleep>
    80003d86:	cd19                	beqz	a0,80003da4 <iunlock+0x3c>
    80003d88:	449c                	lw	a5,8(s1)
    80003d8a:	00f05d63          	blez	a5,80003da4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d8e:	854a                	mv	a0,s2
    80003d90:	00001097          	auipc	ra,0x1
    80003d94:	f4c080e7          	jalr	-180(ra) # 80004cdc <releasesleep>
}
    80003d98:	60e2                	ld	ra,24(sp)
    80003d9a:	6442                	ld	s0,16(sp)
    80003d9c:	64a2                	ld	s1,8(sp)
    80003d9e:	6902                	ld	s2,0(sp)
    80003da0:	6105                	addi	sp,sp,32
    80003da2:	8082                	ret
    panic("iunlock");
    80003da4:	00005517          	auipc	a0,0x5
    80003da8:	85c50513          	addi	a0,a0,-1956 # 80008600 <syscalls+0x198>
    80003dac:	ffffc097          	auipc	ra,0xffffc
    80003db0:	77e080e7          	jalr	1918(ra) # 8000052a <panic>

0000000080003db4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003db4:	7179                	addi	sp,sp,-48
    80003db6:	f406                	sd	ra,40(sp)
    80003db8:	f022                	sd	s0,32(sp)
    80003dba:	ec26                	sd	s1,24(sp)
    80003dbc:	e84a                	sd	s2,16(sp)
    80003dbe:	e44e                	sd	s3,8(sp)
    80003dc0:	e052                	sd	s4,0(sp)
    80003dc2:	1800                	addi	s0,sp,48
    80003dc4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dc6:	05050493          	addi	s1,a0,80
    80003dca:	08050913          	addi	s2,a0,128
    80003dce:	a021                	j	80003dd6 <itrunc+0x22>
    80003dd0:	0491                	addi	s1,s1,4
    80003dd2:	01248d63          	beq	s1,s2,80003dec <itrunc+0x38>
    if(ip->addrs[i]){
    80003dd6:	408c                	lw	a1,0(s1)
    80003dd8:	dde5                	beqz	a1,80003dd0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dda:	0009a503          	lw	a0,0(s3)
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	90a080e7          	jalr	-1782(ra) # 800036e8 <bfree>
      ip->addrs[i] = 0;
    80003de6:	0004a023          	sw	zero,0(s1)
    80003dea:	b7dd                	j	80003dd0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dec:	0809a583          	lw	a1,128(s3)
    80003df0:	e185                	bnez	a1,80003e10 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003df2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	de4080e7          	jalr	-540(ra) # 80003bdc <iupdate>
}
    80003e00:	70a2                	ld	ra,40(sp)
    80003e02:	7402                	ld	s0,32(sp)
    80003e04:	64e2                	ld	s1,24(sp)
    80003e06:	6942                	ld	s2,16(sp)
    80003e08:	69a2                	ld	s3,8(sp)
    80003e0a:	6a02                	ld	s4,0(sp)
    80003e0c:	6145                	addi	sp,sp,48
    80003e0e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e10:	0009a503          	lw	a0,0(s3)
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	68e080e7          	jalr	1678(ra) # 800034a2 <bread>
    80003e1c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e1e:	05850493          	addi	s1,a0,88
    80003e22:	45850913          	addi	s2,a0,1112
    80003e26:	a021                	j	80003e2e <itrunc+0x7a>
    80003e28:	0491                	addi	s1,s1,4
    80003e2a:	01248b63          	beq	s1,s2,80003e40 <itrunc+0x8c>
      if(a[j])
    80003e2e:	408c                	lw	a1,0(s1)
    80003e30:	dde5                	beqz	a1,80003e28 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e32:	0009a503          	lw	a0,0(s3)
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	8b2080e7          	jalr	-1870(ra) # 800036e8 <bfree>
    80003e3e:	b7ed                	j	80003e28 <itrunc+0x74>
    brelse(bp);
    80003e40:	8552                	mv	a0,s4
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	790080e7          	jalr	1936(ra) # 800035d2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e4a:	0809a583          	lw	a1,128(s3)
    80003e4e:	0009a503          	lw	a0,0(s3)
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	896080e7          	jalr	-1898(ra) # 800036e8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e5a:	0809a023          	sw	zero,128(s3)
    80003e5e:	bf51                	j	80003df2 <itrunc+0x3e>

0000000080003e60 <iput>:
{
    80003e60:	1101                	addi	sp,sp,-32
    80003e62:	ec06                	sd	ra,24(sp)
    80003e64:	e822                	sd	s0,16(sp)
    80003e66:	e426                	sd	s1,8(sp)
    80003e68:	e04a                	sd	s2,0(sp)
    80003e6a:	1000                	addi	s0,sp,32
    80003e6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e6e:	0002c517          	auipc	a0,0x2c
    80003e72:	f5a50513          	addi	a0,a0,-166 # 8002fdc8 <itable>
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	d4c080e7          	jalr	-692(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e7e:	4498                	lw	a4,8(s1)
    80003e80:	4785                	li	a5,1
    80003e82:	02f70363          	beq	a4,a5,80003ea8 <iput+0x48>
  ip->ref--;
    80003e86:	449c                	lw	a5,8(s1)
    80003e88:	37fd                	addiw	a5,a5,-1
    80003e8a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e8c:	0002c517          	auipc	a0,0x2c
    80003e90:	f3c50513          	addi	a0,a0,-196 # 8002fdc8 <itable>
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	de2080e7          	jalr	-542(ra) # 80000c76 <release>
}
    80003e9c:	60e2                	ld	ra,24(sp)
    80003e9e:	6442                	ld	s0,16(sp)
    80003ea0:	64a2                	ld	s1,8(sp)
    80003ea2:	6902                	ld	s2,0(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ea8:	40bc                	lw	a5,64(s1)
    80003eaa:	dff1                	beqz	a5,80003e86 <iput+0x26>
    80003eac:	04a49783          	lh	a5,74(s1)
    80003eb0:	fbf9                	bnez	a5,80003e86 <iput+0x26>
    acquiresleep(&ip->lock);
    80003eb2:	01048913          	addi	s2,s1,16
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	00001097          	auipc	ra,0x1
    80003ebc:	dce080e7          	jalr	-562(ra) # 80004c86 <acquiresleep>
    release(&itable.lock);
    80003ec0:	0002c517          	auipc	a0,0x2c
    80003ec4:	f0850513          	addi	a0,a0,-248 # 8002fdc8 <itable>
    80003ec8:	ffffd097          	auipc	ra,0xffffd
    80003ecc:	dae080e7          	jalr	-594(ra) # 80000c76 <release>
    itrunc(ip);
    80003ed0:	8526                	mv	a0,s1
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	ee2080e7          	jalr	-286(ra) # 80003db4 <itrunc>
    ip->type = 0;
    80003eda:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ede:	8526                	mv	a0,s1
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	cfc080e7          	jalr	-772(ra) # 80003bdc <iupdate>
    ip->valid = 0;
    80003ee8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003eec:	854a                	mv	a0,s2
    80003eee:	00001097          	auipc	ra,0x1
    80003ef2:	dee080e7          	jalr	-530(ra) # 80004cdc <releasesleep>
    acquire(&itable.lock);
    80003ef6:	0002c517          	auipc	a0,0x2c
    80003efa:	ed250513          	addi	a0,a0,-302 # 8002fdc8 <itable>
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	cc4080e7          	jalr	-828(ra) # 80000bc2 <acquire>
    80003f06:	b741                	j	80003e86 <iput+0x26>

0000000080003f08 <iunlockput>:
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	e426                	sd	s1,8(sp)
    80003f10:	1000                	addi	s0,sp,32
    80003f12:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	e54080e7          	jalr	-428(ra) # 80003d68 <iunlock>
  iput(ip);
    80003f1c:	8526                	mv	a0,s1
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	f42080e7          	jalr	-190(ra) # 80003e60 <iput>
}
    80003f26:	60e2                	ld	ra,24(sp)
    80003f28:	6442                	ld	s0,16(sp)
    80003f2a:	64a2                	ld	s1,8(sp)
    80003f2c:	6105                	addi	sp,sp,32
    80003f2e:	8082                	ret

0000000080003f30 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f30:	1141                	addi	sp,sp,-16
    80003f32:	e422                	sd	s0,8(sp)
    80003f34:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f36:	411c                	lw	a5,0(a0)
    80003f38:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f3a:	415c                	lw	a5,4(a0)
    80003f3c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f3e:	04451783          	lh	a5,68(a0)
    80003f42:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f46:	04a51783          	lh	a5,74(a0)
    80003f4a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f4e:	04c56783          	lwu	a5,76(a0)
    80003f52:	e99c                	sd	a5,16(a1)
}
    80003f54:	6422                	ld	s0,8(sp)
    80003f56:	0141                	addi	sp,sp,16
    80003f58:	8082                	ret

0000000080003f5a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f5a:	457c                	lw	a5,76(a0)
    80003f5c:	0ed7e963          	bltu	a5,a3,8000404e <readi+0xf4>
{
    80003f60:	7159                	addi	sp,sp,-112
    80003f62:	f486                	sd	ra,104(sp)
    80003f64:	f0a2                	sd	s0,96(sp)
    80003f66:	eca6                	sd	s1,88(sp)
    80003f68:	e8ca                	sd	s2,80(sp)
    80003f6a:	e4ce                	sd	s3,72(sp)
    80003f6c:	e0d2                	sd	s4,64(sp)
    80003f6e:	fc56                	sd	s5,56(sp)
    80003f70:	f85a                	sd	s6,48(sp)
    80003f72:	f45e                	sd	s7,40(sp)
    80003f74:	f062                	sd	s8,32(sp)
    80003f76:	ec66                	sd	s9,24(sp)
    80003f78:	e86a                	sd	s10,16(sp)
    80003f7a:	e46e                	sd	s11,8(sp)
    80003f7c:	1880                	addi	s0,sp,112
    80003f7e:	8baa                	mv	s7,a0
    80003f80:	8c2e                	mv	s8,a1
    80003f82:	8ab2                	mv	s5,a2
    80003f84:	84b6                	mv	s1,a3
    80003f86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f88:	9f35                	addw	a4,a4,a3
    return 0;
    80003f8a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f8c:	0ad76063          	bltu	a4,a3,8000402c <readi+0xd2>
  if(off + n > ip->size)
    80003f90:	00e7f463          	bgeu	a5,a4,80003f98 <readi+0x3e>
    n = ip->size - off;
    80003f94:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f98:	0a0b0963          	beqz	s6,8000404a <readi+0xf0>
    80003f9c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f9e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fa2:	5cfd                	li	s9,-1
    80003fa4:	a82d                	j	80003fde <readi+0x84>
    80003fa6:	020a1d93          	slli	s11,s4,0x20
    80003faa:	020ddd93          	srli	s11,s11,0x20
    80003fae:	05890793          	addi	a5,s2,88
    80003fb2:	86ee                	mv	a3,s11
    80003fb4:	963e                	add	a2,a2,a5
    80003fb6:	85d6                	mv	a1,s5
    80003fb8:	8562                	mv	a0,s8
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	b16080e7          	jalr	-1258(ra) # 80002ad0 <either_copyout>
    80003fc2:	05950d63          	beq	a0,s9,8000401c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	60a080e7          	jalr	1546(ra) # 800035d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd0:	013a09bb          	addw	s3,s4,s3
    80003fd4:	009a04bb          	addw	s1,s4,s1
    80003fd8:	9aee                	add	s5,s5,s11
    80003fda:	0569f763          	bgeu	s3,s6,80004028 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fde:	000ba903          	lw	s2,0(s7)
    80003fe2:	00a4d59b          	srliw	a1,s1,0xa
    80003fe6:	855e                	mv	a0,s7
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	8ae080e7          	jalr	-1874(ra) # 80003896 <bmap>
    80003ff0:	0005059b          	sext.w	a1,a0
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	4ac080e7          	jalr	1196(ra) # 800034a2 <bread>
    80003ffe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004000:	3ff4f613          	andi	a2,s1,1023
    80004004:	40cd07bb          	subw	a5,s10,a2
    80004008:	413b073b          	subw	a4,s6,s3
    8000400c:	8a3e                	mv	s4,a5
    8000400e:	2781                	sext.w	a5,a5
    80004010:	0007069b          	sext.w	a3,a4
    80004014:	f8f6f9e3          	bgeu	a3,a5,80003fa6 <readi+0x4c>
    80004018:	8a3a                	mv	s4,a4
    8000401a:	b771                	j	80003fa6 <readi+0x4c>
      brelse(bp);
    8000401c:	854a                	mv	a0,s2
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	5b4080e7          	jalr	1460(ra) # 800035d2 <brelse>
      tot = -1;
    80004026:	59fd                	li	s3,-1
  }
  return tot;
    80004028:	0009851b          	sext.w	a0,s3
}
    8000402c:	70a6                	ld	ra,104(sp)
    8000402e:	7406                	ld	s0,96(sp)
    80004030:	64e6                	ld	s1,88(sp)
    80004032:	6946                	ld	s2,80(sp)
    80004034:	69a6                	ld	s3,72(sp)
    80004036:	6a06                	ld	s4,64(sp)
    80004038:	7ae2                	ld	s5,56(sp)
    8000403a:	7b42                	ld	s6,48(sp)
    8000403c:	7ba2                	ld	s7,40(sp)
    8000403e:	7c02                	ld	s8,32(sp)
    80004040:	6ce2                	ld	s9,24(sp)
    80004042:	6d42                	ld	s10,16(sp)
    80004044:	6da2                	ld	s11,8(sp)
    80004046:	6165                	addi	sp,sp,112
    80004048:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000404a:	89da                	mv	s3,s6
    8000404c:	bff1                	j	80004028 <readi+0xce>
    return 0;
    8000404e:	4501                	li	a0,0
}
    80004050:	8082                	ret

0000000080004052 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004052:	457c                	lw	a5,76(a0)
    80004054:	10d7e863          	bltu	a5,a3,80004164 <writei+0x112>
{
    80004058:	7159                	addi	sp,sp,-112
    8000405a:	f486                	sd	ra,104(sp)
    8000405c:	f0a2                	sd	s0,96(sp)
    8000405e:	eca6                	sd	s1,88(sp)
    80004060:	e8ca                	sd	s2,80(sp)
    80004062:	e4ce                	sd	s3,72(sp)
    80004064:	e0d2                	sd	s4,64(sp)
    80004066:	fc56                	sd	s5,56(sp)
    80004068:	f85a                	sd	s6,48(sp)
    8000406a:	f45e                	sd	s7,40(sp)
    8000406c:	f062                	sd	s8,32(sp)
    8000406e:	ec66                	sd	s9,24(sp)
    80004070:	e86a                	sd	s10,16(sp)
    80004072:	e46e                	sd	s11,8(sp)
    80004074:	1880                	addi	s0,sp,112
    80004076:	8b2a                	mv	s6,a0
    80004078:	8c2e                	mv	s8,a1
    8000407a:	8ab2                	mv	s5,a2
    8000407c:	8936                	mv	s2,a3
    8000407e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004080:	00e687bb          	addw	a5,a3,a4
    80004084:	0ed7e263          	bltu	a5,a3,80004168 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004088:	00043737          	lui	a4,0x43
    8000408c:	0ef76063          	bltu	a4,a5,8000416c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004090:	0c0b8863          	beqz	s7,80004160 <writei+0x10e>
    80004094:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004096:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000409a:	5cfd                	li	s9,-1
    8000409c:	a091                	j	800040e0 <writei+0x8e>
    8000409e:	02099d93          	slli	s11,s3,0x20
    800040a2:	020ddd93          	srli	s11,s11,0x20
    800040a6:	05848793          	addi	a5,s1,88
    800040aa:	86ee                	mv	a3,s11
    800040ac:	8656                	mv	a2,s5
    800040ae:	85e2                	mv	a1,s8
    800040b0:	953e                	add	a0,a0,a5
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	a74080e7          	jalr	-1420(ra) # 80002b26 <either_copyin>
    800040ba:	07950263          	beq	a0,s9,8000411e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040be:	8526                	mv	a0,s1
    800040c0:	00001097          	auipc	ra,0x1
    800040c4:	aa6080e7          	jalr	-1370(ra) # 80004b66 <log_write>
    brelse(bp);
    800040c8:	8526                	mv	a0,s1
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	508080e7          	jalr	1288(ra) # 800035d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d2:	01498a3b          	addw	s4,s3,s4
    800040d6:	0129893b          	addw	s2,s3,s2
    800040da:	9aee                	add	s5,s5,s11
    800040dc:	057a7663          	bgeu	s4,s7,80004128 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040e0:	000b2483          	lw	s1,0(s6)
    800040e4:	00a9559b          	srliw	a1,s2,0xa
    800040e8:	855a                	mv	a0,s6
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	7ac080e7          	jalr	1964(ra) # 80003896 <bmap>
    800040f2:	0005059b          	sext.w	a1,a0
    800040f6:	8526                	mv	a0,s1
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	3aa080e7          	jalr	938(ra) # 800034a2 <bread>
    80004100:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004102:	3ff97513          	andi	a0,s2,1023
    80004106:	40ad07bb          	subw	a5,s10,a0
    8000410a:	414b873b          	subw	a4,s7,s4
    8000410e:	89be                	mv	s3,a5
    80004110:	2781                	sext.w	a5,a5
    80004112:	0007069b          	sext.w	a3,a4
    80004116:	f8f6f4e3          	bgeu	a3,a5,8000409e <writei+0x4c>
    8000411a:	89ba                	mv	s3,a4
    8000411c:	b749                	j	8000409e <writei+0x4c>
      brelse(bp);
    8000411e:	8526                	mv	a0,s1
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	4b2080e7          	jalr	1202(ra) # 800035d2 <brelse>
  }

  if(off > ip->size)
    80004128:	04cb2783          	lw	a5,76(s6)
    8000412c:	0127f463          	bgeu	a5,s2,80004134 <writei+0xe2>
    ip->size = off;
    80004130:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004134:	855a                	mv	a0,s6
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	aa6080e7          	jalr	-1370(ra) # 80003bdc <iupdate>

  return tot;
    8000413e:	000a051b          	sext.w	a0,s4
}
    80004142:	70a6                	ld	ra,104(sp)
    80004144:	7406                	ld	s0,96(sp)
    80004146:	64e6                	ld	s1,88(sp)
    80004148:	6946                	ld	s2,80(sp)
    8000414a:	69a6                	ld	s3,72(sp)
    8000414c:	6a06                	ld	s4,64(sp)
    8000414e:	7ae2                	ld	s5,56(sp)
    80004150:	7b42                	ld	s6,48(sp)
    80004152:	7ba2                	ld	s7,40(sp)
    80004154:	7c02                	ld	s8,32(sp)
    80004156:	6ce2                	ld	s9,24(sp)
    80004158:	6d42                	ld	s10,16(sp)
    8000415a:	6da2                	ld	s11,8(sp)
    8000415c:	6165                	addi	sp,sp,112
    8000415e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004160:	8a5e                	mv	s4,s7
    80004162:	bfc9                	j	80004134 <writei+0xe2>
    return -1;
    80004164:	557d                	li	a0,-1
}
    80004166:	8082                	ret
    return -1;
    80004168:	557d                	li	a0,-1
    8000416a:	bfe1                	j	80004142 <writei+0xf0>
    return -1;
    8000416c:	557d                	li	a0,-1
    8000416e:	bfd1                	j	80004142 <writei+0xf0>

0000000080004170 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004170:	1141                	addi	sp,sp,-16
    80004172:	e406                	sd	ra,8(sp)
    80004174:	e022                	sd	s0,0(sp)
    80004176:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004178:	4639                	li	a2,14
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	c1c080e7          	jalr	-996(ra) # 80000d96 <strncmp>
}
    80004182:	60a2                	ld	ra,8(sp)
    80004184:	6402                	ld	s0,0(sp)
    80004186:	0141                	addi	sp,sp,16
    80004188:	8082                	ret

000000008000418a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000418a:	7139                	addi	sp,sp,-64
    8000418c:	fc06                	sd	ra,56(sp)
    8000418e:	f822                	sd	s0,48(sp)
    80004190:	f426                	sd	s1,40(sp)
    80004192:	f04a                	sd	s2,32(sp)
    80004194:	ec4e                	sd	s3,24(sp)
    80004196:	e852                	sd	s4,16(sp)
    80004198:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000419a:	04451703          	lh	a4,68(a0)
    8000419e:	4785                	li	a5,1
    800041a0:	00f71a63          	bne	a4,a5,800041b4 <dirlookup+0x2a>
    800041a4:	892a                	mv	s2,a0
    800041a6:	89ae                	mv	s3,a1
    800041a8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041aa:	457c                	lw	a5,76(a0)
    800041ac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041ae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b0:	e79d                	bnez	a5,800041de <dirlookup+0x54>
    800041b2:	a8a5                	j	8000422a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041b4:	00004517          	auipc	a0,0x4
    800041b8:	45450513          	addi	a0,a0,1108 # 80008608 <syscalls+0x1a0>
    800041bc:	ffffc097          	auipc	ra,0xffffc
    800041c0:	36e080e7          	jalr	878(ra) # 8000052a <panic>
      panic("dirlookup read");
    800041c4:	00004517          	auipc	a0,0x4
    800041c8:	45c50513          	addi	a0,a0,1116 # 80008620 <syscalls+0x1b8>
    800041cc:	ffffc097          	auipc	ra,0xffffc
    800041d0:	35e080e7          	jalr	862(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d4:	24c1                	addiw	s1,s1,16
    800041d6:	04c92783          	lw	a5,76(s2)
    800041da:	04f4f763          	bgeu	s1,a5,80004228 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041de:	4741                	li	a4,16
    800041e0:	86a6                	mv	a3,s1
    800041e2:	fc040613          	addi	a2,s0,-64
    800041e6:	4581                	li	a1,0
    800041e8:	854a                	mv	a0,s2
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	d70080e7          	jalr	-656(ra) # 80003f5a <readi>
    800041f2:	47c1                	li	a5,16
    800041f4:	fcf518e3          	bne	a0,a5,800041c4 <dirlookup+0x3a>
    if(de.inum == 0)
    800041f8:	fc045783          	lhu	a5,-64(s0)
    800041fc:	dfe1                	beqz	a5,800041d4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041fe:	fc240593          	addi	a1,s0,-62
    80004202:	854e                	mv	a0,s3
    80004204:	00000097          	auipc	ra,0x0
    80004208:	f6c080e7          	jalr	-148(ra) # 80004170 <namecmp>
    8000420c:	f561                	bnez	a0,800041d4 <dirlookup+0x4a>
      if(poff)
    8000420e:	000a0463          	beqz	s4,80004216 <dirlookup+0x8c>
        *poff = off;
    80004212:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004216:	fc045583          	lhu	a1,-64(s0)
    8000421a:	00092503          	lw	a0,0(s2)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	754080e7          	jalr	1876(ra) # 80003972 <iget>
    80004226:	a011                	j	8000422a <dirlookup+0xa0>
  return 0;
    80004228:	4501                	li	a0,0
}
    8000422a:	70e2                	ld	ra,56(sp)
    8000422c:	7442                	ld	s0,48(sp)
    8000422e:	74a2                	ld	s1,40(sp)
    80004230:	7902                	ld	s2,32(sp)
    80004232:	69e2                	ld	s3,24(sp)
    80004234:	6a42                	ld	s4,16(sp)
    80004236:	6121                	addi	sp,sp,64
    80004238:	8082                	ret

000000008000423a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000423a:	711d                	addi	sp,sp,-96
    8000423c:	ec86                	sd	ra,88(sp)
    8000423e:	e8a2                	sd	s0,80(sp)
    80004240:	e4a6                	sd	s1,72(sp)
    80004242:	e0ca                	sd	s2,64(sp)
    80004244:	fc4e                	sd	s3,56(sp)
    80004246:	f852                	sd	s4,48(sp)
    80004248:	f456                	sd	s5,40(sp)
    8000424a:	f05a                	sd	s6,32(sp)
    8000424c:	ec5e                	sd	s7,24(sp)
    8000424e:	e862                	sd	s8,16(sp)
    80004250:	e466                	sd	s9,8(sp)
    80004252:	1080                	addi	s0,sp,96
    80004254:	84aa                	mv	s1,a0
    80004256:	8aae                	mv	s5,a1
    80004258:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000425a:	00054703          	lbu	a4,0(a0)
    8000425e:	02f00793          	li	a5,47
    80004262:	02f70363          	beq	a4,a5,80004288 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004266:	ffffe097          	auipc	ra,0xffffe
    8000426a:	ce4080e7          	jalr	-796(ra) # 80001f4a <myproc>
    8000426e:	15053503          	ld	a0,336(a0)
    80004272:	00000097          	auipc	ra,0x0
    80004276:	9f6080e7          	jalr	-1546(ra) # 80003c68 <idup>
    8000427a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000427c:	02f00913          	li	s2,47
  len = path - s;
    80004280:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004282:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004284:	4b85                	li	s7,1
    80004286:	a865                	j	8000433e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004288:	4585                	li	a1,1
    8000428a:	4505                	li	a0,1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	6e6080e7          	jalr	1766(ra) # 80003972 <iget>
    80004294:	89aa                	mv	s3,a0
    80004296:	b7dd                	j	8000427c <namex+0x42>
      iunlockput(ip);
    80004298:	854e                	mv	a0,s3
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	c6e080e7          	jalr	-914(ra) # 80003f08 <iunlockput>
      return 0;
    800042a2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042a4:	854e                	mv	a0,s3
    800042a6:	60e6                	ld	ra,88(sp)
    800042a8:	6446                	ld	s0,80(sp)
    800042aa:	64a6                	ld	s1,72(sp)
    800042ac:	6906                	ld	s2,64(sp)
    800042ae:	79e2                	ld	s3,56(sp)
    800042b0:	7a42                	ld	s4,48(sp)
    800042b2:	7aa2                	ld	s5,40(sp)
    800042b4:	7b02                	ld	s6,32(sp)
    800042b6:	6be2                	ld	s7,24(sp)
    800042b8:	6c42                	ld	s8,16(sp)
    800042ba:	6ca2                	ld	s9,8(sp)
    800042bc:	6125                	addi	sp,sp,96
    800042be:	8082                	ret
      iunlock(ip);
    800042c0:	854e                	mv	a0,s3
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	aa6080e7          	jalr	-1370(ra) # 80003d68 <iunlock>
      return ip;
    800042ca:	bfe9                	j	800042a4 <namex+0x6a>
      iunlockput(ip);
    800042cc:	854e                	mv	a0,s3
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c3a080e7          	jalr	-966(ra) # 80003f08 <iunlockput>
      return 0;
    800042d6:	89e6                	mv	s3,s9
    800042d8:	b7f1                	j	800042a4 <namex+0x6a>
  len = path - s;
    800042da:	40b48633          	sub	a2,s1,a1
    800042de:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800042e2:	099c5463          	bge	s8,s9,8000436a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042e6:	4639                	li	a2,14
    800042e8:	8552                	mv	a0,s4
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	a30080e7          	jalr	-1488(ra) # 80000d1a <memmove>
  while(*path == '/')
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	01279763          	bne	a5,s2,80004304 <namex+0xca>
    path++;
    800042fa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042fc:	0004c783          	lbu	a5,0(s1)
    80004300:	ff278de3          	beq	a5,s2,800042fa <namex+0xc0>
    ilock(ip);
    80004304:	854e                	mv	a0,s3
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	9a0080e7          	jalr	-1632(ra) # 80003ca6 <ilock>
    if(ip->type != T_DIR){
    8000430e:	04499783          	lh	a5,68(s3)
    80004312:	f97793e3          	bne	a5,s7,80004298 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004316:	000a8563          	beqz	s5,80004320 <namex+0xe6>
    8000431a:	0004c783          	lbu	a5,0(s1)
    8000431e:	d3cd                	beqz	a5,800042c0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004320:	865a                	mv	a2,s6
    80004322:	85d2                	mv	a1,s4
    80004324:	854e                	mv	a0,s3
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	e64080e7          	jalr	-412(ra) # 8000418a <dirlookup>
    8000432e:	8caa                	mv	s9,a0
    80004330:	dd51                	beqz	a0,800042cc <namex+0x92>
    iunlockput(ip);
    80004332:	854e                	mv	a0,s3
    80004334:	00000097          	auipc	ra,0x0
    80004338:	bd4080e7          	jalr	-1068(ra) # 80003f08 <iunlockput>
    ip = next;
    8000433c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000433e:	0004c783          	lbu	a5,0(s1)
    80004342:	05279763          	bne	a5,s2,80004390 <namex+0x156>
    path++;
    80004346:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004348:	0004c783          	lbu	a5,0(s1)
    8000434c:	ff278de3          	beq	a5,s2,80004346 <namex+0x10c>
  if(*path == 0)
    80004350:	c79d                	beqz	a5,8000437e <namex+0x144>
    path++;
    80004352:	85a6                	mv	a1,s1
  len = path - s;
    80004354:	8cda                	mv	s9,s6
    80004356:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004358:	01278963          	beq	a5,s2,8000436a <namex+0x130>
    8000435c:	dfbd                	beqz	a5,800042da <namex+0xa0>
    path++;
    8000435e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004360:	0004c783          	lbu	a5,0(s1)
    80004364:	ff279ce3          	bne	a5,s2,8000435c <namex+0x122>
    80004368:	bf8d                	j	800042da <namex+0xa0>
    memmove(name, s, len);
    8000436a:	2601                	sext.w	a2,a2
    8000436c:	8552                	mv	a0,s4
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	9ac080e7          	jalr	-1620(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004376:	9cd2                	add	s9,s9,s4
    80004378:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000437c:	bf9d                	j	800042f2 <namex+0xb8>
  if(nameiparent){
    8000437e:	f20a83e3          	beqz	s5,800042a4 <namex+0x6a>
    iput(ip);
    80004382:	854e                	mv	a0,s3
    80004384:	00000097          	auipc	ra,0x0
    80004388:	adc080e7          	jalr	-1316(ra) # 80003e60 <iput>
    return 0;
    8000438c:	4981                	li	s3,0
    8000438e:	bf19                	j	800042a4 <namex+0x6a>
  if(*path == 0)
    80004390:	d7fd                	beqz	a5,8000437e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004392:	0004c783          	lbu	a5,0(s1)
    80004396:	85a6                	mv	a1,s1
    80004398:	b7d1                	j	8000435c <namex+0x122>

000000008000439a <dirlink>:
{
    8000439a:	7139                	addi	sp,sp,-64
    8000439c:	fc06                	sd	ra,56(sp)
    8000439e:	f822                	sd	s0,48(sp)
    800043a0:	f426                	sd	s1,40(sp)
    800043a2:	f04a                	sd	s2,32(sp)
    800043a4:	ec4e                	sd	s3,24(sp)
    800043a6:	e852                	sd	s4,16(sp)
    800043a8:	0080                	addi	s0,sp,64
    800043aa:	892a                	mv	s2,a0
    800043ac:	8a2e                	mv	s4,a1
    800043ae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043b0:	4601                	li	a2,0
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	dd8080e7          	jalr	-552(ra) # 8000418a <dirlookup>
    800043ba:	e93d                	bnez	a0,80004430 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043bc:	04c92483          	lw	s1,76(s2)
    800043c0:	c49d                	beqz	s1,800043ee <dirlink+0x54>
    800043c2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c4:	4741                	li	a4,16
    800043c6:	86a6                	mv	a3,s1
    800043c8:	fc040613          	addi	a2,s0,-64
    800043cc:	4581                	li	a1,0
    800043ce:	854a                	mv	a0,s2
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	b8a080e7          	jalr	-1142(ra) # 80003f5a <readi>
    800043d8:	47c1                	li	a5,16
    800043da:	06f51163          	bne	a0,a5,8000443c <dirlink+0xa2>
    if(de.inum == 0)
    800043de:	fc045783          	lhu	a5,-64(s0)
    800043e2:	c791                	beqz	a5,800043ee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e4:	24c1                	addiw	s1,s1,16
    800043e6:	04c92783          	lw	a5,76(s2)
    800043ea:	fcf4ede3          	bltu	s1,a5,800043c4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043ee:	4639                	li	a2,14
    800043f0:	85d2                	mv	a1,s4
    800043f2:	fc240513          	addi	a0,s0,-62
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	9dc080e7          	jalr	-1572(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    800043fe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004402:	4741                	li	a4,16
    80004404:	86a6                	mv	a3,s1
    80004406:	fc040613          	addi	a2,s0,-64
    8000440a:	4581                	li	a1,0
    8000440c:	854a                	mv	a0,s2
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	c44080e7          	jalr	-956(ra) # 80004052 <writei>
    80004416:	872a                	mv	a4,a0
    80004418:	47c1                	li	a5,16
  return 0;
    8000441a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000441c:	02f71863          	bne	a4,a5,8000444c <dirlink+0xb2>
}
    80004420:	70e2                	ld	ra,56(sp)
    80004422:	7442                	ld	s0,48(sp)
    80004424:	74a2                	ld	s1,40(sp)
    80004426:	7902                	ld	s2,32(sp)
    80004428:	69e2                	ld	s3,24(sp)
    8000442a:	6a42                	ld	s4,16(sp)
    8000442c:	6121                	addi	sp,sp,64
    8000442e:	8082                	ret
    iput(ip);
    80004430:	00000097          	auipc	ra,0x0
    80004434:	a30080e7          	jalr	-1488(ra) # 80003e60 <iput>
    return -1;
    80004438:	557d                	li	a0,-1
    8000443a:	b7dd                	j	80004420 <dirlink+0x86>
      panic("dirlink read");
    8000443c:	00004517          	auipc	a0,0x4
    80004440:	1f450513          	addi	a0,a0,500 # 80008630 <syscalls+0x1c8>
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	0e6080e7          	jalr	230(ra) # 8000052a <panic>
    panic("dirlink");
    8000444c:	00004517          	auipc	a0,0x4
    80004450:	36c50513          	addi	a0,a0,876 # 800087b8 <syscalls+0x350>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	0d6080e7          	jalr	214(ra) # 8000052a <panic>

000000008000445c <namei>:

struct inode*
namei(char *path)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004464:	fe040613          	addi	a2,s0,-32
    80004468:	4581                	li	a1,0
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	dd0080e7          	jalr	-560(ra) # 8000423a <namex>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret

000000008000447a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000447a:	1141                	addi	sp,sp,-16
    8000447c:	e406                	sd	ra,8(sp)
    8000447e:	e022                	sd	s0,0(sp)
    80004480:	0800                	addi	s0,sp,16
    80004482:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004484:	4585                	li	a1,1
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	db4080e7          	jalr	-588(ra) # 8000423a <namex>
}
    8000448e:	60a2                	ld	ra,8(sp)
    80004490:	6402                	ld	s0,0(sp)
    80004492:	0141                	addi	sp,sp,16
    80004494:	8082                	ret

0000000080004496 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec22                	sd	s0,24(sp)
    8000449a:	1000                	addi	s0,sp,32
    8000449c:	872a                	mv	a4,a0
    8000449e:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800044a0:	00004797          	auipc	a5,0x4
    800044a4:	1a078793          	addi	a5,a5,416 # 80008640 <syscalls+0x1d8>
    800044a8:	6394                	ld	a3,0(a5)
    800044aa:	fed43023          	sd	a3,-32(s0)
    800044ae:	0087d683          	lhu	a3,8(a5)
    800044b2:	fed41423          	sh	a3,-24(s0)
    800044b6:	00a7c783          	lbu	a5,10(a5)
    800044ba:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800044be:	87ae                	mv	a5,a1
    if(i<0){
    800044c0:	02074b63          	bltz	a4,800044f6 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800044c4:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800044c6:	4629                	li	a2,10
        ++p;
    800044c8:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800044ca:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800044ce:	feed                	bnez	a3,800044c8 <itoa+0x32>
    *p = '\0';
    800044d0:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800044d4:	4629                	li	a2,10
    800044d6:	17fd                	addi	a5,a5,-1
    800044d8:	02c766bb          	remw	a3,a4,a2
    800044dc:	ff040593          	addi	a1,s0,-16
    800044e0:	96ae                	add	a3,a3,a1
    800044e2:	ff06c683          	lbu	a3,-16(a3)
    800044e6:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800044ea:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800044ee:	f765                	bnez	a4,800044d6 <itoa+0x40>
    return b;
}
    800044f0:	6462                	ld	s0,24(sp)
    800044f2:	6105                	addi	sp,sp,32
    800044f4:	8082                	ret
        *p++ = '-';
    800044f6:	00158793          	addi	a5,a1,1
    800044fa:	02d00693          	li	a3,45
    800044fe:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004502:	40e0073b          	negw	a4,a4
    80004506:	bf7d                	j	800044c4 <itoa+0x2e>

0000000080004508 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004508:	711d                	addi	sp,sp,-96
    8000450a:	ec86                	sd	ra,88(sp)
    8000450c:	e8a2                	sd	s0,80(sp)
    8000450e:	e4a6                	sd	s1,72(sp)
    80004510:	e0ca                	sd	s2,64(sp)
    80004512:	1080                	addi	s0,sp,96
    80004514:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004516:	4619                	li	a2,6
    80004518:	00004597          	auipc	a1,0x4
    8000451c:	13858593          	addi	a1,a1,312 # 80008650 <syscalls+0x1e8>
    80004520:	fd040513          	addi	a0,s0,-48
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	7f6080e7          	jalr	2038(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000452c:	fd640593          	addi	a1,s0,-42
    80004530:	5888                	lw	a0,48(s1)
    80004532:	00000097          	auipc	ra,0x0
    80004536:	f64080e7          	jalr	-156(ra) # 80004496 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    8000453a:	1684b503          	ld	a0,360(s1)
    8000453e:	16050763          	beqz	a0,800046ac <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004542:	00001097          	auipc	ra,0x1
    80004546:	918080e7          	jalr	-1768(ra) # 80004e5a <fileclose>

  begin_op();
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	444080e7          	jalr	1092(ra) # 8000498e <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004552:	fb040593          	addi	a1,s0,-80
    80004556:	fd040513          	addi	a0,s0,-48
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	f20080e7          	jalr	-224(ra) # 8000447a <nameiparent>
    80004562:	892a                	mv	s2,a0
    80004564:	cd69                	beqz	a0,8000463e <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	740080e7          	jalr	1856(ra) # 80003ca6 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000456e:	00004597          	auipc	a1,0x4
    80004572:	0ea58593          	addi	a1,a1,234 # 80008658 <syscalls+0x1f0>
    80004576:	fb040513          	addi	a0,s0,-80
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	bf6080e7          	jalr	-1034(ra) # 80004170 <namecmp>
    80004582:	c57d                	beqz	a0,80004670 <removeSwapFile+0x168>
    80004584:	00004597          	auipc	a1,0x4
    80004588:	0dc58593          	addi	a1,a1,220 # 80008660 <syscalls+0x1f8>
    8000458c:	fb040513          	addi	a0,s0,-80
    80004590:	00000097          	auipc	ra,0x0
    80004594:	be0080e7          	jalr	-1056(ra) # 80004170 <namecmp>
    80004598:	cd61                	beqz	a0,80004670 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    8000459a:	fac40613          	addi	a2,s0,-84
    8000459e:	fb040593          	addi	a1,s0,-80
    800045a2:	854a                	mv	a0,s2
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	be6080e7          	jalr	-1050(ra) # 8000418a <dirlookup>
    800045ac:	84aa                	mv	s1,a0
    800045ae:	c169                	beqz	a0,80004670 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	6f6080e7          	jalr	1782(ra) # 80003ca6 <ilock>

  if(ip->nlink < 1)
    800045b8:	04a49783          	lh	a5,74(s1)
    800045bc:	08f05763          	blez	a5,8000464a <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800045c0:	04449703          	lh	a4,68(s1)
    800045c4:	4785                	li	a5,1
    800045c6:	08f70a63          	beq	a4,a5,8000465a <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800045ca:	4641                	li	a2,16
    800045cc:	4581                	li	a1,0
    800045ce:	fc040513          	addi	a0,s0,-64
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6ec080e7          	jalr	1772(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045da:	4741                	li	a4,16
    800045dc:	fac42683          	lw	a3,-84(s0)
    800045e0:	fc040613          	addi	a2,s0,-64
    800045e4:	4581                	li	a1,0
    800045e6:	854a                	mv	a0,s2
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	a6a080e7          	jalr	-1430(ra) # 80004052 <writei>
    800045f0:	47c1                	li	a5,16
    800045f2:	08f51a63          	bne	a0,a5,80004686 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800045f6:	04449703          	lh	a4,68(s1)
    800045fa:	4785                	li	a5,1
    800045fc:	08f70d63          	beq	a4,a5,80004696 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004600:	854a                	mv	a0,s2
    80004602:	00000097          	auipc	ra,0x0
    80004606:	906080e7          	jalr	-1786(ra) # 80003f08 <iunlockput>

  ip->nlink--;
    8000460a:	04a4d783          	lhu	a5,74(s1)
    8000460e:	37fd                	addiw	a5,a5,-1
    80004610:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	5c6080e7          	jalr	1478(ra) # 80003bdc <iupdate>
  iunlockput(ip);
    8000461e:	8526                	mv	a0,s1
    80004620:	00000097          	auipc	ra,0x0
    80004624:	8e8080e7          	jalr	-1816(ra) # 80003f08 <iunlockput>

  end_op();
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	3e6080e7          	jalr	998(ra) # 80004a0e <end_op>

  return 0;
    80004630:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004632:	60e6                	ld	ra,88(sp)
    80004634:	6446                	ld	s0,80(sp)
    80004636:	64a6                	ld	s1,72(sp)
    80004638:	6906                	ld	s2,64(sp)
    8000463a:	6125                	addi	sp,sp,96
    8000463c:	8082                	ret
    end_op();
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	3d0080e7          	jalr	976(ra) # 80004a0e <end_op>
    return -1;
    80004646:	557d                	li	a0,-1
    80004648:	b7ed                	j	80004632 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    8000464a:	00004517          	auipc	a0,0x4
    8000464e:	01e50513          	addi	a0,a0,30 # 80008668 <syscalls+0x200>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000465a:	8526                	mv	a0,s1
    8000465c:	00001097          	auipc	ra,0x1
    80004660:	7fa080e7          	jalr	2042(ra) # 80005e56 <isdirempty>
    80004664:	f13d                	bnez	a0,800045ca <removeSwapFile+0xc2>
    iunlockput(ip);
    80004666:	8526                	mv	a0,s1
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	8a0080e7          	jalr	-1888(ra) # 80003f08 <iunlockput>
    iunlockput(dp);
    80004670:	854a                	mv	a0,s2
    80004672:	00000097          	auipc	ra,0x0
    80004676:	896080e7          	jalr	-1898(ra) # 80003f08 <iunlockput>
    end_op();
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	394080e7          	jalr	916(ra) # 80004a0e <end_op>
    return -1;
    80004682:	557d                	li	a0,-1
    80004684:	b77d                	j	80004632 <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004686:	00004517          	auipc	a0,0x4
    8000468a:	ffa50513          	addi	a0,a0,-6 # 80008680 <syscalls+0x218>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	e9c080e7          	jalr	-356(ra) # 8000052a <panic>
    dp->nlink--;
    80004696:	04a95783          	lhu	a5,74(s2)
    8000469a:	37fd                	addiw	a5,a5,-1
    8000469c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800046a0:	854a                	mv	a0,s2
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	53a080e7          	jalr	1338(ra) # 80003bdc <iupdate>
    800046aa:	bf99                	j	80004600 <removeSwapFile+0xf8>
    return -1;
    800046ac:	557d                	li	a0,-1
    800046ae:	b751                	j	80004632 <removeSwapFile+0x12a>

00000000800046b0 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800046b0:	7179                	addi	sp,sp,-48
    800046b2:	f406                	sd	ra,40(sp)
    800046b4:	f022                	sd	s0,32(sp)
    800046b6:	ec26                	sd	s1,24(sp)
    800046b8:	e84a                	sd	s2,16(sp)
    800046ba:	1800                	addi	s0,sp,48
    800046bc:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800046be:	4619                	li	a2,6
    800046c0:	00004597          	auipc	a1,0x4
    800046c4:	f9058593          	addi	a1,a1,-112 # 80008650 <syscalls+0x1e8>
    800046c8:	fd040513          	addi	a0,s0,-48
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	64e080e7          	jalr	1614(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800046d4:	fd640593          	addi	a1,s0,-42
    800046d8:	5888                	lw	a0,48(s1)
    800046da:	00000097          	auipc	ra,0x0
    800046de:	dbc080e7          	jalr	-580(ra) # 80004496 <itoa>

  begin_op();
    800046e2:	00000097          	auipc	ra,0x0
    800046e6:	2ac080e7          	jalr	684(ra) # 8000498e <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800046ea:	4681                	li	a3,0
    800046ec:	4601                	li	a2,0
    800046ee:	4589                	li	a1,2
    800046f0:	fd040513          	addi	a0,s0,-48
    800046f4:	00002097          	auipc	ra,0x2
    800046f8:	956080e7          	jalr	-1706(ra) # 8000604a <create>
    800046fc:	892a                	mv	s2,a0
  iunlock(in);
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	66a080e7          	jalr	1642(ra) # 80003d68 <iunlock>
  p->swapFile = filealloc();
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	698080e7          	jalr	1688(ra) # 80004d9e <filealloc>
    8000470e:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004712:	cd1d                	beqz	a0,80004750 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004714:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004718:	1684b703          	ld	a4,360(s1)
    8000471c:	4789                	li	a5,2
    8000471e:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004720:	1684b703          	ld	a4,360(s1)
    80004724:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004728:	1684b703          	ld	a4,360(s1)
    8000472c:	4685                	li	a3,1
    8000472e:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004732:	1684b703          	ld	a4,360(s1)
    80004736:	00f704a3          	sb	a5,9(a4)
    end_op();
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	2d4080e7          	jalr	724(ra) # 80004a0e <end_op>

    return 0;
}
    80004742:	4501                	li	a0,0
    80004744:	70a2                	ld	ra,40(sp)
    80004746:	7402                	ld	s0,32(sp)
    80004748:	64e2                	ld	s1,24(sp)
    8000474a:	6942                	ld	s2,16(sp)
    8000474c:	6145                	addi	sp,sp,48
    8000474e:	8082                	ret
    panic("no slot for files on /store");
    80004750:	00004517          	auipc	a0,0x4
    80004754:	f4050513          	addi	a0,a0,-192 # 80008690 <syscalls+0x228>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	dd2080e7          	jalr	-558(ra) # 8000052a <panic>

0000000080004760 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004760:	1141                	addi	sp,sp,-16
    80004762:	e406                	sd	ra,8(sp)
    80004764:	e022                	sd	s0,0(sp)
    80004766:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004768:	16853783          	ld	a5,360(a0)
    8000476c:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    8000476e:	8636                	mv	a2,a3
    80004770:	16853503          	ld	a0,360(a0)
    80004774:	00001097          	auipc	ra,0x1
    80004778:	ad8080e7          	jalr	-1320(ra) # 8000524c <kfilewrite>
}
    8000477c:	60a2                	ld	ra,8(sp)
    8000477e:	6402                	ld	s0,0(sp)
    80004780:	0141                	addi	sp,sp,16
    80004782:	8082                	ret

0000000080004784 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004784:	1141                	addi	sp,sp,-16
    80004786:	e406                	sd	ra,8(sp)
    80004788:	e022                	sd	s0,0(sp)
    8000478a:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000478c:	16853783          	ld	a5,360(a0)
    80004790:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004792:	8636                	mv	a2,a3
    80004794:	16853503          	ld	a0,360(a0)
    80004798:	00001097          	auipc	ra,0x1
    8000479c:	9f2080e7          	jalr	-1550(ra) # 8000518a <kfileread>
    800047a0:	60a2                	ld	ra,8(sp)
    800047a2:	6402                	ld	s0,0(sp)
    800047a4:	0141                	addi	sp,sp,16
    800047a6:	8082                	ret

00000000800047a8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047a8:	1101                	addi	sp,sp,-32
    800047aa:	ec06                	sd	ra,24(sp)
    800047ac:	e822                	sd	s0,16(sp)
    800047ae:	e426                	sd	s1,8(sp)
    800047b0:	e04a                	sd	s2,0(sp)
    800047b2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047b4:	0002d917          	auipc	s2,0x2d
    800047b8:	0bc90913          	addi	s2,s2,188 # 80031870 <log>
    800047bc:	01892583          	lw	a1,24(s2)
    800047c0:	02892503          	lw	a0,40(s2)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	cde080e7          	jalr	-802(ra) # 800034a2 <bread>
    800047cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047ce:	02c92683          	lw	a3,44(s2)
    800047d2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047d4:	02d05863          	blez	a3,80004804 <write_head+0x5c>
    800047d8:	0002d797          	auipc	a5,0x2d
    800047dc:	0c878793          	addi	a5,a5,200 # 800318a0 <log+0x30>
    800047e0:	05c50713          	addi	a4,a0,92
    800047e4:	36fd                	addiw	a3,a3,-1
    800047e6:	02069613          	slli	a2,a3,0x20
    800047ea:	01e65693          	srli	a3,a2,0x1e
    800047ee:	0002d617          	auipc	a2,0x2d
    800047f2:	0b660613          	addi	a2,a2,182 # 800318a4 <log+0x34>
    800047f6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047f8:	4390                	lw	a2,0(a5)
    800047fa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047fc:	0791                	addi	a5,a5,4
    800047fe:	0711                	addi	a4,a4,4
    80004800:	fed79ce3          	bne	a5,a3,800047f8 <write_head+0x50>
  }
  bwrite(buf);
    80004804:	8526                	mv	a0,s1
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	d8e080e7          	jalr	-626(ra) # 80003594 <bwrite>
  brelse(buf);
    8000480e:	8526                	mv	a0,s1
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	dc2080e7          	jalr	-574(ra) # 800035d2 <brelse>
}
    80004818:	60e2                	ld	ra,24(sp)
    8000481a:	6442                	ld	s0,16(sp)
    8000481c:	64a2                	ld	s1,8(sp)
    8000481e:	6902                	ld	s2,0(sp)
    80004820:	6105                	addi	sp,sp,32
    80004822:	8082                	ret

0000000080004824 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004824:	0002d797          	auipc	a5,0x2d
    80004828:	0787a783          	lw	a5,120(a5) # 8003189c <log+0x2c>
    8000482c:	0af05d63          	blez	a5,800048e6 <install_trans+0xc2>
{
    80004830:	7139                	addi	sp,sp,-64
    80004832:	fc06                	sd	ra,56(sp)
    80004834:	f822                	sd	s0,48(sp)
    80004836:	f426                	sd	s1,40(sp)
    80004838:	f04a                	sd	s2,32(sp)
    8000483a:	ec4e                	sd	s3,24(sp)
    8000483c:	e852                	sd	s4,16(sp)
    8000483e:	e456                	sd	s5,8(sp)
    80004840:	e05a                	sd	s6,0(sp)
    80004842:	0080                	addi	s0,sp,64
    80004844:	8b2a                	mv	s6,a0
    80004846:	0002da97          	auipc	s5,0x2d
    8000484a:	05aa8a93          	addi	s5,s5,90 # 800318a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000484e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004850:	0002d997          	auipc	s3,0x2d
    80004854:	02098993          	addi	s3,s3,32 # 80031870 <log>
    80004858:	a00d                	j	8000487a <install_trans+0x56>
    brelse(lbuf);
    8000485a:	854a                	mv	a0,s2
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	d76080e7          	jalr	-650(ra) # 800035d2 <brelse>
    brelse(dbuf);
    80004864:	8526                	mv	a0,s1
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	d6c080e7          	jalr	-660(ra) # 800035d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000486e:	2a05                	addiw	s4,s4,1
    80004870:	0a91                	addi	s5,s5,4
    80004872:	02c9a783          	lw	a5,44(s3)
    80004876:	04fa5e63          	bge	s4,a5,800048d2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000487a:	0189a583          	lw	a1,24(s3)
    8000487e:	014585bb          	addw	a1,a1,s4
    80004882:	2585                	addiw	a1,a1,1
    80004884:	0289a503          	lw	a0,40(s3)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	c1a080e7          	jalr	-998(ra) # 800034a2 <bread>
    80004890:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004892:	000aa583          	lw	a1,0(s5)
    80004896:	0289a503          	lw	a0,40(s3)
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	c08080e7          	jalr	-1016(ra) # 800034a2 <bread>
    800048a2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048a4:	40000613          	li	a2,1024
    800048a8:	05890593          	addi	a1,s2,88
    800048ac:	05850513          	addi	a0,a0,88
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	46a080e7          	jalr	1130(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800048b8:	8526                	mv	a0,s1
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	cda080e7          	jalr	-806(ra) # 80003594 <bwrite>
    if(recovering == 0)
    800048c2:	f80b1ce3          	bnez	s6,8000485a <install_trans+0x36>
      bunpin(dbuf);
    800048c6:	8526                	mv	a0,s1
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	de4080e7          	jalr	-540(ra) # 800036ac <bunpin>
    800048d0:	b769                	j	8000485a <install_trans+0x36>
}
    800048d2:	70e2                	ld	ra,56(sp)
    800048d4:	7442                	ld	s0,48(sp)
    800048d6:	74a2                	ld	s1,40(sp)
    800048d8:	7902                	ld	s2,32(sp)
    800048da:	69e2                	ld	s3,24(sp)
    800048dc:	6a42                	ld	s4,16(sp)
    800048de:	6aa2                	ld	s5,8(sp)
    800048e0:	6b02                	ld	s6,0(sp)
    800048e2:	6121                	addi	sp,sp,64
    800048e4:	8082                	ret
    800048e6:	8082                	ret

00000000800048e8 <initlog>:
{
    800048e8:	7179                	addi	sp,sp,-48
    800048ea:	f406                	sd	ra,40(sp)
    800048ec:	f022                	sd	s0,32(sp)
    800048ee:	ec26                	sd	s1,24(sp)
    800048f0:	e84a                	sd	s2,16(sp)
    800048f2:	e44e                	sd	s3,8(sp)
    800048f4:	1800                	addi	s0,sp,48
    800048f6:	892a                	mv	s2,a0
    800048f8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800048fa:	0002d497          	auipc	s1,0x2d
    800048fe:	f7648493          	addi	s1,s1,-138 # 80031870 <log>
    80004902:	00004597          	auipc	a1,0x4
    80004906:	dae58593          	addi	a1,a1,-594 # 800086b0 <syscalls+0x248>
    8000490a:	8526                	mv	a0,s1
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	226080e7          	jalr	550(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004914:	0149a583          	lw	a1,20(s3)
    80004918:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000491a:	0109a783          	lw	a5,16(s3)
    8000491e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004920:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004924:	854a                	mv	a0,s2
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	b7c080e7          	jalr	-1156(ra) # 800034a2 <bread>
  log.lh.n = lh->n;
    8000492e:	4d34                	lw	a3,88(a0)
    80004930:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004932:	02d05663          	blez	a3,8000495e <initlog+0x76>
    80004936:	05c50793          	addi	a5,a0,92
    8000493a:	0002d717          	auipc	a4,0x2d
    8000493e:	f6670713          	addi	a4,a4,-154 # 800318a0 <log+0x30>
    80004942:	36fd                	addiw	a3,a3,-1
    80004944:	02069613          	slli	a2,a3,0x20
    80004948:	01e65693          	srli	a3,a2,0x1e
    8000494c:	06050613          	addi	a2,a0,96
    80004950:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004952:	4390                	lw	a2,0(a5)
    80004954:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004956:	0791                	addi	a5,a5,4
    80004958:	0711                	addi	a4,a4,4
    8000495a:	fed79ce3          	bne	a5,a3,80004952 <initlog+0x6a>
  brelse(buf);
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	c74080e7          	jalr	-908(ra) # 800035d2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004966:	4505                	li	a0,1
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	ebc080e7          	jalr	-324(ra) # 80004824 <install_trans>
  log.lh.n = 0;
    80004970:	0002d797          	auipc	a5,0x2d
    80004974:	f207a623          	sw	zero,-212(a5) # 8003189c <log+0x2c>
  write_head(); // clear the log
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	e30080e7          	jalr	-464(ra) # 800047a8 <write_head>
}
    80004980:	70a2                	ld	ra,40(sp)
    80004982:	7402                	ld	s0,32(sp)
    80004984:	64e2                	ld	s1,24(sp)
    80004986:	6942                	ld	s2,16(sp)
    80004988:	69a2                	ld	s3,8(sp)
    8000498a:	6145                	addi	sp,sp,48
    8000498c:	8082                	ret

000000008000498e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000498e:	1101                	addi	sp,sp,-32
    80004990:	ec06                	sd	ra,24(sp)
    80004992:	e822                	sd	s0,16(sp)
    80004994:	e426                	sd	s1,8(sp)
    80004996:	e04a                	sd	s2,0(sp)
    80004998:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000499a:	0002d517          	auipc	a0,0x2d
    8000499e:	ed650513          	addi	a0,a0,-298 # 80031870 <log>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	220080e7          	jalr	544(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800049aa:	0002d497          	auipc	s1,0x2d
    800049ae:	ec648493          	addi	s1,s1,-314 # 80031870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049b2:	4979                	li	s2,30
    800049b4:	a039                	j	800049c2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800049b6:	85a6                	mv	a1,s1
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffe097          	auipc	ra,0xffffe
    800049be:	d5c080e7          	jalr	-676(ra) # 80002716 <sleep>
    if(log.committing){
    800049c2:	50dc                	lw	a5,36(s1)
    800049c4:	fbed                	bnez	a5,800049b6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049c6:	509c                	lw	a5,32(s1)
    800049c8:	0017871b          	addiw	a4,a5,1
    800049cc:	0007069b          	sext.w	a3,a4
    800049d0:	0027179b          	slliw	a5,a4,0x2
    800049d4:	9fb9                	addw	a5,a5,a4
    800049d6:	0017979b          	slliw	a5,a5,0x1
    800049da:	54d8                	lw	a4,44(s1)
    800049dc:	9fb9                	addw	a5,a5,a4
    800049de:	00f95963          	bge	s2,a5,800049f0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049e2:	85a6                	mv	a1,s1
    800049e4:	8526                	mv	a0,s1
    800049e6:	ffffe097          	auipc	ra,0xffffe
    800049ea:	d30080e7          	jalr	-720(ra) # 80002716 <sleep>
    800049ee:	bfd1                	j	800049c2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049f0:	0002d517          	auipc	a0,0x2d
    800049f4:	e8050513          	addi	a0,a0,-384 # 80031870 <log>
    800049f8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	27c080e7          	jalr	636(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004a02:	60e2                	ld	ra,24(sp)
    80004a04:	6442                	ld	s0,16(sp)
    80004a06:	64a2                	ld	s1,8(sp)
    80004a08:	6902                	ld	s2,0(sp)
    80004a0a:	6105                	addi	sp,sp,32
    80004a0c:	8082                	ret

0000000080004a0e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a0e:	7139                	addi	sp,sp,-64
    80004a10:	fc06                	sd	ra,56(sp)
    80004a12:	f822                	sd	s0,48(sp)
    80004a14:	f426                	sd	s1,40(sp)
    80004a16:	f04a                	sd	s2,32(sp)
    80004a18:	ec4e                	sd	s3,24(sp)
    80004a1a:	e852                	sd	s4,16(sp)
    80004a1c:	e456                	sd	s5,8(sp)
    80004a1e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a20:	0002d497          	auipc	s1,0x2d
    80004a24:	e5048493          	addi	s1,s1,-432 # 80031870 <log>
    80004a28:	8526                	mv	a0,s1
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	198080e7          	jalr	408(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004a32:	509c                	lw	a5,32(s1)
    80004a34:	37fd                	addiw	a5,a5,-1
    80004a36:	0007891b          	sext.w	s2,a5
    80004a3a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a3c:	50dc                	lw	a5,36(s1)
    80004a3e:	e7b9                	bnez	a5,80004a8c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a40:	04091e63          	bnez	s2,80004a9c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004a44:	0002d497          	auipc	s1,0x2d
    80004a48:	e2c48493          	addi	s1,s1,-468 # 80031870 <log>
    80004a4c:	4785                	li	a5,1
    80004a4e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	224080e7          	jalr	548(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a5a:	54dc                	lw	a5,44(s1)
    80004a5c:	06f04763          	bgtz	a5,80004aca <end_op+0xbc>
    acquire(&log.lock);
    80004a60:	0002d497          	auipc	s1,0x2d
    80004a64:	e1048493          	addi	s1,s1,-496 # 80031870 <log>
    80004a68:	8526                	mv	a0,s1
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	158080e7          	jalr	344(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004a72:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	e2a080e7          	jalr	-470(ra) # 800028a2 <wakeup>
    release(&log.lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	1f4080e7          	jalr	500(ra) # 80000c76 <release>
}
    80004a8a:	a03d                	j	80004ab8 <end_op+0xaa>
    panic("log.committing");
    80004a8c:	00004517          	auipc	a0,0x4
    80004a90:	c2c50513          	addi	a0,a0,-980 # 800086b8 <syscalls+0x250>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	a96080e7          	jalr	-1386(ra) # 8000052a <panic>
    wakeup(&log);
    80004a9c:	0002d497          	auipc	s1,0x2d
    80004aa0:	dd448493          	addi	s1,s1,-556 # 80031870 <log>
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffe097          	auipc	ra,0xffffe
    80004aaa:	dfc080e7          	jalr	-516(ra) # 800028a2 <wakeup>
  release(&log.lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1c6080e7          	jalr	454(ra) # 80000c76 <release>
}
    80004ab8:	70e2                	ld	ra,56(sp)
    80004aba:	7442                	ld	s0,48(sp)
    80004abc:	74a2                	ld	s1,40(sp)
    80004abe:	7902                	ld	s2,32(sp)
    80004ac0:	69e2                	ld	s3,24(sp)
    80004ac2:	6a42                	ld	s4,16(sp)
    80004ac4:	6aa2                	ld	s5,8(sp)
    80004ac6:	6121                	addi	sp,sp,64
    80004ac8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aca:	0002da97          	auipc	s5,0x2d
    80004ace:	dd6a8a93          	addi	s5,s5,-554 # 800318a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ad2:	0002da17          	auipc	s4,0x2d
    80004ad6:	d9ea0a13          	addi	s4,s4,-610 # 80031870 <log>
    80004ada:	018a2583          	lw	a1,24(s4)
    80004ade:	012585bb          	addw	a1,a1,s2
    80004ae2:	2585                	addiw	a1,a1,1
    80004ae4:	028a2503          	lw	a0,40(s4)
    80004ae8:	fffff097          	auipc	ra,0xfffff
    80004aec:	9ba080e7          	jalr	-1606(ra) # 800034a2 <bread>
    80004af0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004af2:	000aa583          	lw	a1,0(s5)
    80004af6:	028a2503          	lw	a0,40(s4)
    80004afa:	fffff097          	auipc	ra,0xfffff
    80004afe:	9a8080e7          	jalr	-1624(ra) # 800034a2 <bread>
    80004b02:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b04:	40000613          	li	a2,1024
    80004b08:	05850593          	addi	a1,a0,88
    80004b0c:	05848513          	addi	a0,s1,88
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	20a080e7          	jalr	522(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004b18:	8526                	mv	a0,s1
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	a7a080e7          	jalr	-1414(ra) # 80003594 <bwrite>
    brelse(from);
    80004b22:	854e                	mv	a0,s3
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	aae080e7          	jalr	-1362(ra) # 800035d2 <brelse>
    brelse(to);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	aa4080e7          	jalr	-1372(ra) # 800035d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b36:	2905                	addiw	s2,s2,1
    80004b38:	0a91                	addi	s5,s5,4
    80004b3a:	02ca2783          	lw	a5,44(s4)
    80004b3e:	f8f94ee3          	blt	s2,a5,80004ada <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	c66080e7          	jalr	-922(ra) # 800047a8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004b4a:	4501                	li	a0,0
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	cd8080e7          	jalr	-808(ra) # 80004824 <install_trans>
    log.lh.n = 0;
    80004b54:	0002d797          	auipc	a5,0x2d
    80004b58:	d407a423          	sw	zero,-696(a5) # 8003189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	c4c080e7          	jalr	-948(ra) # 800047a8 <write_head>
    80004b64:	bdf5                	j	80004a60 <end_op+0x52>

0000000080004b66 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b66:	1101                	addi	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	e04a                	sd	s2,0(sp)
    80004b70:	1000                	addi	s0,sp,32
    80004b72:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b74:	0002d917          	auipc	s2,0x2d
    80004b78:	cfc90913          	addi	s2,s2,-772 # 80031870 <log>
    80004b7c:	854a                	mv	a0,s2
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	044080e7          	jalr	68(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b86:	02c92603          	lw	a2,44(s2)
    80004b8a:	47f5                	li	a5,29
    80004b8c:	06c7c563          	blt	a5,a2,80004bf6 <log_write+0x90>
    80004b90:	0002d797          	auipc	a5,0x2d
    80004b94:	cfc7a783          	lw	a5,-772(a5) # 8003188c <log+0x1c>
    80004b98:	37fd                	addiw	a5,a5,-1
    80004b9a:	04f65e63          	bge	a2,a5,80004bf6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b9e:	0002d797          	auipc	a5,0x2d
    80004ba2:	cf27a783          	lw	a5,-782(a5) # 80031890 <log+0x20>
    80004ba6:	06f05063          	blez	a5,80004c06 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004baa:	4781                	li	a5,0
    80004bac:	06c05563          	blez	a2,80004c16 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bb0:	44cc                	lw	a1,12(s1)
    80004bb2:	0002d717          	auipc	a4,0x2d
    80004bb6:	cee70713          	addi	a4,a4,-786 # 800318a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bbc:	4314                	lw	a3,0(a4)
    80004bbe:	04b68c63          	beq	a3,a1,80004c16 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004bc2:	2785                	addiw	a5,a5,1
    80004bc4:	0711                	addi	a4,a4,4
    80004bc6:	fef61be3          	bne	a2,a5,80004bbc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bca:	0621                	addi	a2,a2,8
    80004bcc:	060a                	slli	a2,a2,0x2
    80004bce:	0002d797          	auipc	a5,0x2d
    80004bd2:	ca278793          	addi	a5,a5,-862 # 80031870 <log>
    80004bd6:	963e                	add	a2,a2,a5
    80004bd8:	44dc                	lw	a5,12(s1)
    80004bda:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	a92080e7          	jalr	-1390(ra) # 80003670 <bpin>
    log.lh.n++;
    80004be6:	0002d717          	auipc	a4,0x2d
    80004bea:	c8a70713          	addi	a4,a4,-886 # 80031870 <log>
    80004bee:	575c                	lw	a5,44(a4)
    80004bf0:	2785                	addiw	a5,a5,1
    80004bf2:	d75c                	sw	a5,44(a4)
    80004bf4:	a835                	j	80004c30 <log_write+0xca>
    panic("too big a transaction");
    80004bf6:	00004517          	auipc	a0,0x4
    80004bfa:	ad250513          	addi	a0,a0,-1326 # 800086c8 <syscalls+0x260>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	92c080e7          	jalr	-1748(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004c06:	00004517          	auipc	a0,0x4
    80004c0a:	ada50513          	addi	a0,a0,-1318 # 800086e0 <syscalls+0x278>
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004c16:	00878713          	addi	a4,a5,8
    80004c1a:	00271693          	slli	a3,a4,0x2
    80004c1e:	0002d717          	auipc	a4,0x2d
    80004c22:	c5270713          	addi	a4,a4,-942 # 80031870 <log>
    80004c26:	9736                	add	a4,a4,a3
    80004c28:	44d4                	lw	a3,12(s1)
    80004c2a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c2c:	faf608e3          	beq	a2,a5,80004bdc <log_write+0x76>
  }
  release(&log.lock);
    80004c30:	0002d517          	auipc	a0,0x2d
    80004c34:	c4050513          	addi	a0,a0,-960 # 80031870 <log>
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	03e080e7          	jalr	62(ra) # 80000c76 <release>
}
    80004c40:	60e2                	ld	ra,24(sp)
    80004c42:	6442                	ld	s0,16(sp)
    80004c44:	64a2                	ld	s1,8(sp)
    80004c46:	6902                	ld	s2,0(sp)
    80004c48:	6105                	addi	sp,sp,32
    80004c4a:	8082                	ret

0000000080004c4c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c4c:	1101                	addi	sp,sp,-32
    80004c4e:	ec06                	sd	ra,24(sp)
    80004c50:	e822                	sd	s0,16(sp)
    80004c52:	e426                	sd	s1,8(sp)
    80004c54:	e04a                	sd	s2,0(sp)
    80004c56:	1000                	addi	s0,sp,32
    80004c58:	84aa                	mv	s1,a0
    80004c5a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c5c:	00004597          	auipc	a1,0x4
    80004c60:	aa458593          	addi	a1,a1,-1372 # 80008700 <syscalls+0x298>
    80004c64:	0521                	addi	a0,a0,8
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	ecc080e7          	jalr	-308(ra) # 80000b32 <initlock>
  lk->name = name;
    80004c6e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c72:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c76:	0204a423          	sw	zero,40(s1)
}
    80004c7a:	60e2                	ld	ra,24(sp)
    80004c7c:	6442                	ld	s0,16(sp)
    80004c7e:	64a2                	ld	s1,8(sp)
    80004c80:	6902                	ld	s2,0(sp)
    80004c82:	6105                	addi	sp,sp,32
    80004c84:	8082                	ret

0000000080004c86 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c86:	1101                	addi	sp,sp,-32
    80004c88:	ec06                	sd	ra,24(sp)
    80004c8a:	e822                	sd	s0,16(sp)
    80004c8c:	e426                	sd	s1,8(sp)
    80004c8e:	e04a                	sd	s2,0(sp)
    80004c90:	1000                	addi	s0,sp,32
    80004c92:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c94:	00850913          	addi	s2,a0,8
    80004c98:	854a                	mv	a0,s2
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f28080e7          	jalr	-216(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004ca2:	409c                	lw	a5,0(s1)
    80004ca4:	cb89                	beqz	a5,80004cb6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ca6:	85ca                	mv	a1,s2
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffe097          	auipc	ra,0xffffe
    80004cae:	a6c080e7          	jalr	-1428(ra) # 80002716 <sleep>
  while (lk->locked) {
    80004cb2:	409c                	lw	a5,0(s1)
    80004cb4:	fbed                	bnez	a5,80004ca6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cb6:	4785                	li	a5,1
    80004cb8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	290080e7          	jalr	656(ra) # 80001f4a <myproc>
    80004cc2:	591c                	lw	a5,48(a0)
    80004cc4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004cc6:	854a                	mv	a0,s2
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	fae080e7          	jalr	-82(ra) # 80000c76 <release>
}
    80004cd0:	60e2                	ld	ra,24(sp)
    80004cd2:	6442                	ld	s0,16(sp)
    80004cd4:	64a2                	ld	s1,8(sp)
    80004cd6:	6902                	ld	s2,0(sp)
    80004cd8:	6105                	addi	sp,sp,32
    80004cda:	8082                	ret

0000000080004cdc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004cdc:	1101                	addi	sp,sp,-32
    80004cde:	ec06                	sd	ra,24(sp)
    80004ce0:	e822                	sd	s0,16(sp)
    80004ce2:	e426                	sd	s1,8(sp)
    80004ce4:	e04a                	sd	s2,0(sp)
    80004ce6:	1000                	addi	s0,sp,32
    80004ce8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cea:	00850913          	addi	s2,a0,8
    80004cee:	854a                	mv	a0,s2
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	ed2080e7          	jalr	-302(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004cf8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cfc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d00:	8526                	mv	a0,s1
    80004d02:	ffffe097          	auipc	ra,0xffffe
    80004d06:	ba0080e7          	jalr	-1120(ra) # 800028a2 <wakeup>
  release(&lk->lk);
    80004d0a:	854a                	mv	a0,s2
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	f6a080e7          	jalr	-150(ra) # 80000c76 <release>
}
    80004d14:	60e2                	ld	ra,24(sp)
    80004d16:	6442                	ld	s0,16(sp)
    80004d18:	64a2                	ld	s1,8(sp)
    80004d1a:	6902                	ld	s2,0(sp)
    80004d1c:	6105                	addi	sp,sp,32
    80004d1e:	8082                	ret

0000000080004d20 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d20:	7179                	addi	sp,sp,-48
    80004d22:	f406                	sd	ra,40(sp)
    80004d24:	f022                	sd	s0,32(sp)
    80004d26:	ec26                	sd	s1,24(sp)
    80004d28:	e84a                	sd	s2,16(sp)
    80004d2a:	e44e                	sd	s3,8(sp)
    80004d2c:	1800                	addi	s0,sp,48
    80004d2e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d30:	00850913          	addi	s2,a0,8
    80004d34:	854a                	mv	a0,s2
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	e8c080e7          	jalr	-372(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d3e:	409c                	lw	a5,0(s1)
    80004d40:	ef99                	bnez	a5,80004d5e <holdingsleep+0x3e>
    80004d42:	4481                	li	s1,0
  release(&lk->lk);
    80004d44:	854a                	mv	a0,s2
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f30080e7          	jalr	-208(ra) # 80000c76 <release>
  return r;
}
    80004d4e:	8526                	mv	a0,s1
    80004d50:	70a2                	ld	ra,40(sp)
    80004d52:	7402                	ld	s0,32(sp)
    80004d54:	64e2                	ld	s1,24(sp)
    80004d56:	6942                	ld	s2,16(sp)
    80004d58:	69a2                	ld	s3,8(sp)
    80004d5a:	6145                	addi	sp,sp,48
    80004d5c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d5e:	0284a983          	lw	s3,40(s1)
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	1e8080e7          	jalr	488(ra) # 80001f4a <myproc>
    80004d6a:	5904                	lw	s1,48(a0)
    80004d6c:	413484b3          	sub	s1,s1,s3
    80004d70:	0014b493          	seqz	s1,s1
    80004d74:	bfc1                	j	80004d44 <holdingsleep+0x24>

0000000080004d76 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d76:	1141                	addi	sp,sp,-16
    80004d78:	e406                	sd	ra,8(sp)
    80004d7a:	e022                	sd	s0,0(sp)
    80004d7c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d7e:	00004597          	auipc	a1,0x4
    80004d82:	99258593          	addi	a1,a1,-1646 # 80008710 <syscalls+0x2a8>
    80004d86:	0002d517          	auipc	a0,0x2d
    80004d8a:	c3250513          	addi	a0,a0,-974 # 800319b8 <ftable>
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	da4080e7          	jalr	-604(ra) # 80000b32 <initlock>
}
    80004d96:	60a2                	ld	ra,8(sp)
    80004d98:	6402                	ld	s0,0(sp)
    80004d9a:	0141                	addi	sp,sp,16
    80004d9c:	8082                	ret

0000000080004d9e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d9e:	1101                	addi	sp,sp,-32
    80004da0:	ec06                	sd	ra,24(sp)
    80004da2:	e822                	sd	s0,16(sp)
    80004da4:	e426                	sd	s1,8(sp)
    80004da6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004da8:	0002d517          	auipc	a0,0x2d
    80004dac:	c1050513          	addi	a0,a0,-1008 # 800319b8 <ftable>
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	e12080e7          	jalr	-494(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004db8:	0002d497          	auipc	s1,0x2d
    80004dbc:	c1848493          	addi	s1,s1,-1000 # 800319d0 <ftable+0x18>
    80004dc0:	0002e717          	auipc	a4,0x2e
    80004dc4:	bb070713          	addi	a4,a4,-1104 # 80032970 <ftable+0xfb8>
    if(f->ref == 0){
    80004dc8:	40dc                	lw	a5,4(s1)
    80004dca:	cf99                	beqz	a5,80004de8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dcc:	02848493          	addi	s1,s1,40
    80004dd0:	fee49ce3          	bne	s1,a4,80004dc8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004dd4:	0002d517          	auipc	a0,0x2d
    80004dd8:	be450513          	addi	a0,a0,-1052 # 800319b8 <ftable>
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	e9a080e7          	jalr	-358(ra) # 80000c76 <release>
  return 0;
    80004de4:	4481                	li	s1,0
    80004de6:	a819                	j	80004dfc <filealloc+0x5e>
      f->ref = 1;
    80004de8:	4785                	li	a5,1
    80004dea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004dec:	0002d517          	auipc	a0,0x2d
    80004df0:	bcc50513          	addi	a0,a0,-1076 # 800319b8 <ftable>
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	e82080e7          	jalr	-382(ra) # 80000c76 <release>
}
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	60e2                	ld	ra,24(sp)
    80004e00:	6442                	ld	s0,16(sp)
    80004e02:	64a2                	ld	s1,8(sp)
    80004e04:	6105                	addi	sp,sp,32
    80004e06:	8082                	ret

0000000080004e08 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e08:	1101                	addi	sp,sp,-32
    80004e0a:	ec06                	sd	ra,24(sp)
    80004e0c:	e822                	sd	s0,16(sp)
    80004e0e:	e426                	sd	s1,8(sp)
    80004e10:	1000                	addi	s0,sp,32
    80004e12:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e14:	0002d517          	auipc	a0,0x2d
    80004e18:	ba450513          	addi	a0,a0,-1116 # 800319b8 <ftable>
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	da6080e7          	jalr	-602(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004e24:	40dc                	lw	a5,4(s1)
    80004e26:	02f05263          	blez	a5,80004e4a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e2a:	2785                	addiw	a5,a5,1
    80004e2c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e2e:	0002d517          	auipc	a0,0x2d
    80004e32:	b8a50513          	addi	a0,a0,-1142 # 800319b8 <ftable>
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	e40080e7          	jalr	-448(ra) # 80000c76 <release>
  return f;
}
    80004e3e:	8526                	mv	a0,s1
    80004e40:	60e2                	ld	ra,24(sp)
    80004e42:	6442                	ld	s0,16(sp)
    80004e44:	64a2                	ld	s1,8(sp)
    80004e46:	6105                	addi	sp,sp,32
    80004e48:	8082                	ret
    panic("filedup");
    80004e4a:	00004517          	auipc	a0,0x4
    80004e4e:	8ce50513          	addi	a0,a0,-1842 # 80008718 <syscalls+0x2b0>
    80004e52:	ffffb097          	auipc	ra,0xffffb
    80004e56:	6d8080e7          	jalr	1752(ra) # 8000052a <panic>

0000000080004e5a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e5a:	7139                	addi	sp,sp,-64
    80004e5c:	fc06                	sd	ra,56(sp)
    80004e5e:	f822                	sd	s0,48(sp)
    80004e60:	f426                	sd	s1,40(sp)
    80004e62:	f04a                	sd	s2,32(sp)
    80004e64:	ec4e                	sd	s3,24(sp)
    80004e66:	e852                	sd	s4,16(sp)
    80004e68:	e456                	sd	s5,8(sp)
    80004e6a:	0080                	addi	s0,sp,64
    80004e6c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e6e:	0002d517          	auipc	a0,0x2d
    80004e72:	b4a50513          	addi	a0,a0,-1206 # 800319b8 <ftable>
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	d4c080e7          	jalr	-692(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004e7e:	40dc                	lw	a5,4(s1)
    80004e80:	06f05163          	blez	a5,80004ee2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e84:	37fd                	addiw	a5,a5,-1
    80004e86:	0007871b          	sext.w	a4,a5
    80004e8a:	c0dc                	sw	a5,4(s1)
    80004e8c:	06e04363          	bgtz	a4,80004ef2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e90:	0004a903          	lw	s2,0(s1)
    80004e94:	0094ca83          	lbu	s5,9(s1)
    80004e98:	0104ba03          	ld	s4,16(s1)
    80004e9c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ea0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ea4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ea8:	0002d517          	auipc	a0,0x2d
    80004eac:	b1050513          	addi	a0,a0,-1264 # 800319b8 <ftable>
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	dc6080e7          	jalr	-570(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004eb8:	4785                	li	a5,1
    80004eba:	04f90d63          	beq	s2,a5,80004f14 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ebe:	3979                	addiw	s2,s2,-2
    80004ec0:	4785                	li	a5,1
    80004ec2:	0527e063          	bltu	a5,s2,80004f02 <fileclose+0xa8>
    begin_op();
    80004ec6:	00000097          	auipc	ra,0x0
    80004eca:	ac8080e7          	jalr	-1336(ra) # 8000498e <begin_op>
    iput(ff.ip);
    80004ece:	854e                	mv	a0,s3
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	f90080e7          	jalr	-112(ra) # 80003e60 <iput>
    end_op();
    80004ed8:	00000097          	auipc	ra,0x0
    80004edc:	b36080e7          	jalr	-1226(ra) # 80004a0e <end_op>
    80004ee0:	a00d                	j	80004f02 <fileclose+0xa8>
    panic("fileclose");
    80004ee2:	00004517          	auipc	a0,0x4
    80004ee6:	83e50513          	addi	a0,a0,-1986 # 80008720 <syscalls+0x2b8>
    80004eea:	ffffb097          	auipc	ra,0xffffb
    80004eee:	640080e7          	jalr	1600(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004ef2:	0002d517          	auipc	a0,0x2d
    80004ef6:	ac650513          	addi	a0,a0,-1338 # 800319b8 <ftable>
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	d7c080e7          	jalr	-644(ra) # 80000c76 <release>
  }
}
    80004f02:	70e2                	ld	ra,56(sp)
    80004f04:	7442                	ld	s0,48(sp)
    80004f06:	74a2                	ld	s1,40(sp)
    80004f08:	7902                	ld	s2,32(sp)
    80004f0a:	69e2                	ld	s3,24(sp)
    80004f0c:	6a42                	ld	s4,16(sp)
    80004f0e:	6aa2                	ld	s5,8(sp)
    80004f10:	6121                	addi	sp,sp,64
    80004f12:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f14:	85d6                	mv	a1,s5
    80004f16:	8552                	mv	a0,s4
    80004f18:	00000097          	auipc	ra,0x0
    80004f1c:	542080e7          	jalr	1346(ra) # 8000545a <pipeclose>
    80004f20:	b7cd                	j	80004f02 <fileclose+0xa8>

0000000080004f22 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f22:	715d                	addi	sp,sp,-80
    80004f24:	e486                	sd	ra,72(sp)
    80004f26:	e0a2                	sd	s0,64(sp)
    80004f28:	fc26                	sd	s1,56(sp)
    80004f2a:	f84a                	sd	s2,48(sp)
    80004f2c:	f44e                	sd	s3,40(sp)
    80004f2e:	0880                	addi	s0,sp,80
    80004f30:	84aa                	mv	s1,a0
    80004f32:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	016080e7          	jalr	22(ra) # 80001f4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f3c:	409c                	lw	a5,0(s1)
    80004f3e:	37f9                	addiw	a5,a5,-2
    80004f40:	4705                	li	a4,1
    80004f42:	04f76763          	bltu	a4,a5,80004f90 <filestat+0x6e>
    80004f46:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f48:	6c88                	ld	a0,24(s1)
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	d5c080e7          	jalr	-676(ra) # 80003ca6 <ilock>
    stati(f->ip, &st);
    80004f52:	fb840593          	addi	a1,s0,-72
    80004f56:	6c88                	ld	a0,24(s1)
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	fd8080e7          	jalr	-40(ra) # 80003f30 <stati>
    iunlock(f->ip);
    80004f60:	6c88                	ld	a0,24(s1)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	e06080e7          	jalr	-506(ra) # 80003d68 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f6a:	46e1                	li	a3,24
    80004f6c:	fb840613          	addi	a2,s0,-72
    80004f70:	85ce                	mv	a1,s3
    80004f72:	05093503          	ld	a0,80(s2)
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	6f2080e7          	jalr	1778(ra) # 80001668 <copyout>
    80004f7e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f82:	60a6                	ld	ra,72(sp)
    80004f84:	6406                	ld	s0,64(sp)
    80004f86:	74e2                	ld	s1,56(sp)
    80004f88:	7942                	ld	s2,48(sp)
    80004f8a:	79a2                	ld	s3,40(sp)
    80004f8c:	6161                	addi	sp,sp,80
    80004f8e:	8082                	ret
  return -1;
    80004f90:	557d                	li	a0,-1
    80004f92:	bfc5                	j	80004f82 <filestat+0x60>

0000000080004f94 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f94:	7179                	addi	sp,sp,-48
    80004f96:	f406                	sd	ra,40(sp)
    80004f98:	f022                	sd	s0,32(sp)
    80004f9a:	ec26                	sd	s1,24(sp)
    80004f9c:	e84a                	sd	s2,16(sp)
    80004f9e:	e44e                	sd	s3,8(sp)
    80004fa0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fa2:	00854783          	lbu	a5,8(a0)
    80004fa6:	c3d5                	beqz	a5,8000504a <fileread+0xb6>
    80004fa8:	84aa                	mv	s1,a0
    80004faa:	89ae                	mv	s3,a1
    80004fac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fae:	411c                	lw	a5,0(a0)
    80004fb0:	4705                	li	a4,1
    80004fb2:	04e78963          	beq	a5,a4,80005004 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fb6:	470d                	li	a4,3
    80004fb8:	04e78d63          	beq	a5,a4,80005012 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fbc:	4709                	li	a4,2
    80004fbe:	06e79e63          	bne	a5,a4,8000503a <fileread+0xa6>
    ilock(f->ip);
    80004fc2:	6d08                	ld	a0,24(a0)
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	ce2080e7          	jalr	-798(ra) # 80003ca6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fcc:	874a                	mv	a4,s2
    80004fce:	5094                	lw	a3,32(s1)
    80004fd0:	864e                	mv	a2,s3
    80004fd2:	4585                	li	a1,1
    80004fd4:	6c88                	ld	a0,24(s1)
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	f84080e7          	jalr	-124(ra) # 80003f5a <readi>
    80004fde:	892a                	mv	s2,a0
    80004fe0:	00a05563          	blez	a0,80004fea <fileread+0x56>
      f->off += r;
    80004fe4:	509c                	lw	a5,32(s1)
    80004fe6:	9fa9                	addw	a5,a5,a0
    80004fe8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004fea:	6c88                	ld	a0,24(s1)
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	d7c080e7          	jalr	-644(ra) # 80003d68 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	70a2                	ld	ra,40(sp)
    80004ff8:	7402                	ld	s0,32(sp)
    80004ffa:	64e2                	ld	s1,24(sp)
    80004ffc:	6942                	ld	s2,16(sp)
    80004ffe:	69a2                	ld	s3,8(sp)
    80005000:	6145                	addi	sp,sp,48
    80005002:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005004:	6908                	ld	a0,16(a0)
    80005006:	00000097          	auipc	ra,0x0
    8000500a:	5b6080e7          	jalr	1462(ra) # 800055bc <piperead>
    8000500e:	892a                	mv	s2,a0
    80005010:	b7d5                	j	80004ff4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005012:	02451783          	lh	a5,36(a0)
    80005016:	03079693          	slli	a3,a5,0x30
    8000501a:	92c1                	srli	a3,a3,0x30
    8000501c:	4725                	li	a4,9
    8000501e:	02d76863          	bltu	a4,a3,8000504e <fileread+0xba>
    80005022:	0792                	slli	a5,a5,0x4
    80005024:	0002d717          	auipc	a4,0x2d
    80005028:	8f470713          	addi	a4,a4,-1804 # 80031918 <devsw>
    8000502c:	97ba                	add	a5,a5,a4
    8000502e:	639c                	ld	a5,0(a5)
    80005030:	c38d                	beqz	a5,80005052 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005032:	4505                	li	a0,1
    80005034:	9782                	jalr	a5
    80005036:	892a                	mv	s2,a0
    80005038:	bf75                	j	80004ff4 <fileread+0x60>
    panic("fileread");
    8000503a:	00003517          	auipc	a0,0x3
    8000503e:	6f650513          	addi	a0,a0,1782 # 80008730 <syscalls+0x2c8>
    80005042:	ffffb097          	auipc	ra,0xffffb
    80005046:	4e8080e7          	jalr	1256(ra) # 8000052a <panic>
    return -1;
    8000504a:	597d                	li	s2,-1
    8000504c:	b765                	j	80004ff4 <fileread+0x60>
      return -1;
    8000504e:	597d                	li	s2,-1
    80005050:	b755                	j	80004ff4 <fileread+0x60>
    80005052:	597d                	li	s2,-1
    80005054:	b745                	j	80004ff4 <fileread+0x60>

0000000080005056 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005056:	715d                	addi	sp,sp,-80
    80005058:	e486                	sd	ra,72(sp)
    8000505a:	e0a2                	sd	s0,64(sp)
    8000505c:	fc26                	sd	s1,56(sp)
    8000505e:	f84a                	sd	s2,48(sp)
    80005060:	f44e                	sd	s3,40(sp)
    80005062:	f052                	sd	s4,32(sp)
    80005064:	ec56                	sd	s5,24(sp)
    80005066:	e85a                	sd	s6,16(sp)
    80005068:	e45e                	sd	s7,8(sp)
    8000506a:	e062                	sd	s8,0(sp)
    8000506c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000506e:	00954783          	lbu	a5,9(a0)
    80005072:	10078663          	beqz	a5,8000517e <filewrite+0x128>
    80005076:	892a                	mv	s2,a0
    80005078:	8aae                	mv	s5,a1
    8000507a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000507c:	411c                	lw	a5,0(a0)
    8000507e:	4705                	li	a4,1
    80005080:	02e78263          	beq	a5,a4,800050a4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005084:	470d                	li	a4,3
    80005086:	02e78663          	beq	a5,a4,800050b2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000508a:	4709                	li	a4,2
    8000508c:	0ee79163          	bne	a5,a4,8000516e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005090:	0ac05d63          	blez	a2,8000514a <filewrite+0xf4>
    int i = 0;
    80005094:	4981                	li	s3,0
    80005096:	6b05                	lui	s6,0x1
    80005098:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000509c:	6b85                	lui	s7,0x1
    8000509e:	c00b8b9b          	addiw	s7,s7,-1024
    800050a2:	a861                	j	8000513a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050a4:	6908                	ld	a0,16(a0)
    800050a6:	00000097          	auipc	ra,0x0
    800050aa:	424080e7          	jalr	1060(ra) # 800054ca <pipewrite>
    800050ae:	8a2a                	mv	s4,a0
    800050b0:	a045                	j	80005150 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050b2:	02451783          	lh	a5,36(a0)
    800050b6:	03079693          	slli	a3,a5,0x30
    800050ba:	92c1                	srli	a3,a3,0x30
    800050bc:	4725                	li	a4,9
    800050be:	0cd76263          	bltu	a4,a3,80005182 <filewrite+0x12c>
    800050c2:	0792                	slli	a5,a5,0x4
    800050c4:	0002d717          	auipc	a4,0x2d
    800050c8:	85470713          	addi	a4,a4,-1964 # 80031918 <devsw>
    800050cc:	97ba                	add	a5,a5,a4
    800050ce:	679c                	ld	a5,8(a5)
    800050d0:	cbdd                	beqz	a5,80005186 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050d2:	4505                	li	a0,1
    800050d4:	9782                	jalr	a5
    800050d6:	8a2a                	mv	s4,a0
    800050d8:	a8a5                	j	80005150 <filewrite+0xfa>
    800050da:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	8b0080e7          	jalr	-1872(ra) # 8000498e <begin_op>
      ilock(f->ip);
    800050e6:	01893503          	ld	a0,24(s2)
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	bbc080e7          	jalr	-1092(ra) # 80003ca6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050f2:	8762                	mv	a4,s8
    800050f4:	02092683          	lw	a3,32(s2)
    800050f8:	01598633          	add	a2,s3,s5
    800050fc:	4585                	li	a1,1
    800050fe:	01893503          	ld	a0,24(s2)
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	f50080e7          	jalr	-176(ra) # 80004052 <writei>
    8000510a:	84aa                	mv	s1,a0
    8000510c:	00a05763          	blez	a0,8000511a <filewrite+0xc4>
        f->off += r;
    80005110:	02092783          	lw	a5,32(s2)
    80005114:	9fa9                	addw	a5,a5,a0
    80005116:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000511a:	01893503          	ld	a0,24(s2)
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	c4a080e7          	jalr	-950(ra) # 80003d68 <iunlock>
      end_op();
    80005126:	00000097          	auipc	ra,0x0
    8000512a:	8e8080e7          	jalr	-1816(ra) # 80004a0e <end_op>

      if(r != n1){
    8000512e:	009c1f63          	bne	s8,s1,8000514c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005132:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005136:	0149db63          	bge	s3,s4,8000514c <filewrite+0xf6>
      int n1 = n - i;
    8000513a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000513e:	84be                	mv	s1,a5
    80005140:	2781                	sext.w	a5,a5
    80005142:	f8fb5ce3          	bge	s6,a5,800050da <filewrite+0x84>
    80005146:	84de                	mv	s1,s7
    80005148:	bf49                	j	800050da <filewrite+0x84>
    int i = 0;
    8000514a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000514c:	013a1f63          	bne	s4,s3,8000516a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005150:	8552                	mv	a0,s4
    80005152:	60a6                	ld	ra,72(sp)
    80005154:	6406                	ld	s0,64(sp)
    80005156:	74e2                	ld	s1,56(sp)
    80005158:	7942                	ld	s2,48(sp)
    8000515a:	79a2                	ld	s3,40(sp)
    8000515c:	7a02                	ld	s4,32(sp)
    8000515e:	6ae2                	ld	s5,24(sp)
    80005160:	6b42                	ld	s6,16(sp)
    80005162:	6ba2                	ld	s7,8(sp)
    80005164:	6c02                	ld	s8,0(sp)
    80005166:	6161                	addi	sp,sp,80
    80005168:	8082                	ret
    ret = (i == n ? n : -1);
    8000516a:	5a7d                	li	s4,-1
    8000516c:	b7d5                	j	80005150 <filewrite+0xfa>
    panic("filewrite");
    8000516e:	00003517          	auipc	a0,0x3
    80005172:	5d250513          	addi	a0,a0,1490 # 80008740 <syscalls+0x2d8>
    80005176:	ffffb097          	auipc	ra,0xffffb
    8000517a:	3b4080e7          	jalr	948(ra) # 8000052a <panic>
    return -1;
    8000517e:	5a7d                	li	s4,-1
    80005180:	bfc1                	j	80005150 <filewrite+0xfa>
      return -1;
    80005182:	5a7d                	li	s4,-1
    80005184:	b7f1                	j	80005150 <filewrite+0xfa>
    80005186:	5a7d                	li	s4,-1
    80005188:	b7e1                	j	80005150 <filewrite+0xfa>

000000008000518a <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    8000518a:	7179                	addi	sp,sp,-48
    8000518c:	f406                	sd	ra,40(sp)
    8000518e:	f022                	sd	s0,32(sp)
    80005190:	ec26                	sd	s1,24(sp)
    80005192:	e84a                	sd	s2,16(sp)
    80005194:	e44e                	sd	s3,8(sp)
    80005196:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005198:	00854783          	lbu	a5,8(a0)
    8000519c:	c3d5                	beqz	a5,80005240 <kfileread+0xb6>
    8000519e:	84aa                	mv	s1,a0
    800051a0:	89ae                	mv	s3,a1
    800051a2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800051a4:	411c                	lw	a5,0(a0)
    800051a6:	4705                	li	a4,1
    800051a8:	04e78963          	beq	a5,a4,800051fa <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051ac:	470d                	li	a4,3
    800051ae:	04e78d63          	beq	a5,a4,80005208 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051b2:	4709                	li	a4,2
    800051b4:	06e79e63          	bne	a5,a4,80005230 <kfileread+0xa6>
    ilock(f->ip);
    800051b8:	6d08                	ld	a0,24(a0)
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	aec080e7          	jalr	-1300(ra) # 80003ca6 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800051c2:	874a                	mv	a4,s2
    800051c4:	5094                	lw	a3,32(s1)
    800051c6:	864e                	mv	a2,s3
    800051c8:	4581                	li	a1,0
    800051ca:	6c88                	ld	a0,24(s1)
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	d8e080e7          	jalr	-626(ra) # 80003f5a <readi>
    800051d4:	892a                	mv	s2,a0
    800051d6:	00a05563          	blez	a0,800051e0 <kfileread+0x56>
      f->off += r;
    800051da:	509c                	lw	a5,32(s1)
    800051dc:	9fa9                	addw	a5,a5,a0
    800051de:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051e0:	6c88                	ld	a0,24(s1)
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	b86080e7          	jalr	-1146(ra) # 80003d68 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051ea:	854a                	mv	a0,s2
    800051ec:	70a2                	ld	ra,40(sp)
    800051ee:	7402                	ld	s0,32(sp)
    800051f0:	64e2                	ld	s1,24(sp)
    800051f2:	6942                	ld	s2,16(sp)
    800051f4:	69a2                	ld	s3,8(sp)
    800051f6:	6145                	addi	sp,sp,48
    800051f8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800051fa:	6908                	ld	a0,16(a0)
    800051fc:	00000097          	auipc	ra,0x0
    80005200:	3c0080e7          	jalr	960(ra) # 800055bc <piperead>
    80005204:	892a                	mv	s2,a0
    80005206:	b7d5                	j	800051ea <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005208:	02451783          	lh	a5,36(a0)
    8000520c:	03079693          	slli	a3,a5,0x30
    80005210:	92c1                	srli	a3,a3,0x30
    80005212:	4725                	li	a4,9
    80005214:	02d76863          	bltu	a4,a3,80005244 <kfileread+0xba>
    80005218:	0792                	slli	a5,a5,0x4
    8000521a:	0002c717          	auipc	a4,0x2c
    8000521e:	6fe70713          	addi	a4,a4,1790 # 80031918 <devsw>
    80005222:	97ba                	add	a5,a5,a4
    80005224:	639c                	ld	a5,0(a5)
    80005226:	c38d                	beqz	a5,80005248 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005228:	4505                	li	a0,1
    8000522a:	9782                	jalr	a5
    8000522c:	892a                	mv	s2,a0
    8000522e:	bf75                	j	800051ea <kfileread+0x60>
    panic("fileread");
    80005230:	00003517          	auipc	a0,0x3
    80005234:	50050513          	addi	a0,a0,1280 # 80008730 <syscalls+0x2c8>
    80005238:	ffffb097          	auipc	ra,0xffffb
    8000523c:	2f2080e7          	jalr	754(ra) # 8000052a <panic>
    return -1;
    80005240:	597d                	li	s2,-1
    80005242:	b765                	j	800051ea <kfileread+0x60>
      return -1;
    80005244:	597d                	li	s2,-1
    80005246:	b755                	j	800051ea <kfileread+0x60>
    80005248:	597d                	li	s2,-1
    8000524a:	b745                	j	800051ea <kfileread+0x60>

000000008000524c <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    8000524c:	715d                	addi	sp,sp,-80
    8000524e:	e486                	sd	ra,72(sp)
    80005250:	e0a2                	sd	s0,64(sp)
    80005252:	fc26                	sd	s1,56(sp)
    80005254:	f84a                	sd	s2,48(sp)
    80005256:	f44e                	sd	s3,40(sp)
    80005258:	f052                	sd	s4,32(sp)
    8000525a:	ec56                	sd	s5,24(sp)
    8000525c:	e85a                	sd	s6,16(sp)
    8000525e:	e45e                	sd	s7,8(sp)
    80005260:	e062                	sd	s8,0(sp)
    80005262:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005264:	00954783          	lbu	a5,9(a0)
    80005268:	10078663          	beqz	a5,80005374 <kfilewrite+0x128>
    8000526c:	892a                	mv	s2,a0
    8000526e:	8aae                	mv	s5,a1
    80005270:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005272:	411c                	lw	a5,0(a0)
    80005274:	4705                	li	a4,1
    80005276:	02e78263          	beq	a5,a4,8000529a <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000527a:	470d                	li	a4,3
    8000527c:	02e78663          	beq	a5,a4,800052a8 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005280:	4709                	li	a4,2
    80005282:	0ee79163          	bne	a5,a4,80005364 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005286:	0ac05d63          	blez	a2,80005340 <kfilewrite+0xf4>
    int i = 0;
    8000528a:	4981                	li	s3,0
    8000528c:	6b05                	lui	s6,0x1
    8000528e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005292:	6b85                	lui	s7,0x1
    80005294:	c00b8b9b          	addiw	s7,s7,-1024
    80005298:	a861                	j	80005330 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000529a:	6908                	ld	a0,16(a0)
    8000529c:	00000097          	auipc	ra,0x0
    800052a0:	22e080e7          	jalr	558(ra) # 800054ca <pipewrite>
    800052a4:	8a2a                	mv	s4,a0
    800052a6:	a045                	j	80005346 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052a8:	02451783          	lh	a5,36(a0)
    800052ac:	03079693          	slli	a3,a5,0x30
    800052b0:	92c1                	srli	a3,a3,0x30
    800052b2:	4725                	li	a4,9
    800052b4:	0cd76263          	bltu	a4,a3,80005378 <kfilewrite+0x12c>
    800052b8:	0792                	slli	a5,a5,0x4
    800052ba:	0002c717          	auipc	a4,0x2c
    800052be:	65e70713          	addi	a4,a4,1630 # 80031918 <devsw>
    800052c2:	97ba                	add	a5,a5,a4
    800052c4:	679c                	ld	a5,8(a5)
    800052c6:	cbdd                	beqz	a5,8000537c <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800052c8:	4505                	li	a0,1
    800052ca:	9782                	jalr	a5
    800052cc:	8a2a                	mv	s4,a0
    800052ce:	a8a5                	j	80005346 <kfilewrite+0xfa>
    800052d0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	6ba080e7          	jalr	1722(ra) # 8000498e <begin_op>
      ilock(f->ip);
    800052dc:	01893503          	ld	a0,24(s2)
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	9c6080e7          	jalr	-1594(ra) # 80003ca6 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800052e8:	8762                	mv	a4,s8
    800052ea:	02092683          	lw	a3,32(s2)
    800052ee:	01598633          	add	a2,s3,s5
    800052f2:	4581                	li	a1,0
    800052f4:	01893503          	ld	a0,24(s2)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	d5a080e7          	jalr	-678(ra) # 80004052 <writei>
    80005300:	84aa                	mv	s1,a0
    80005302:	00a05763          	blez	a0,80005310 <kfilewrite+0xc4>
        f->off += r;
    80005306:	02092783          	lw	a5,32(s2)
    8000530a:	9fa9                	addw	a5,a5,a0
    8000530c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005310:	01893503          	ld	a0,24(s2)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	a54080e7          	jalr	-1452(ra) # 80003d68 <iunlock>
      end_op();
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	6f2080e7          	jalr	1778(ra) # 80004a0e <end_op>

      if(r != n1){
    80005324:	009c1f63          	bne	s8,s1,80005342 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005328:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000532c:	0149db63          	bge	s3,s4,80005342 <kfilewrite+0xf6>
      int n1 = n - i;
    80005330:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005334:	84be                	mv	s1,a5
    80005336:	2781                	sext.w	a5,a5
    80005338:	f8fb5ce3          	bge	s6,a5,800052d0 <kfilewrite+0x84>
    8000533c:	84de                	mv	s1,s7
    8000533e:	bf49                	j	800052d0 <kfilewrite+0x84>
    int i = 0;
    80005340:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005342:	013a1f63          	bne	s4,s3,80005360 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005346:	8552                	mv	a0,s4
    80005348:	60a6                	ld	ra,72(sp)
    8000534a:	6406                	ld	s0,64(sp)
    8000534c:	74e2                	ld	s1,56(sp)
    8000534e:	7942                	ld	s2,48(sp)
    80005350:	79a2                	ld	s3,40(sp)
    80005352:	7a02                	ld	s4,32(sp)
    80005354:	6ae2                	ld	s5,24(sp)
    80005356:	6b42                	ld	s6,16(sp)
    80005358:	6ba2                	ld	s7,8(sp)
    8000535a:	6c02                	ld	s8,0(sp)
    8000535c:	6161                	addi	sp,sp,80
    8000535e:	8082                	ret
    ret = (i == n ? n : -1);
    80005360:	5a7d                	li	s4,-1
    80005362:	b7d5                	j	80005346 <kfilewrite+0xfa>
    panic("filewrite");
    80005364:	00003517          	auipc	a0,0x3
    80005368:	3dc50513          	addi	a0,a0,988 # 80008740 <syscalls+0x2d8>
    8000536c:	ffffb097          	auipc	ra,0xffffb
    80005370:	1be080e7          	jalr	446(ra) # 8000052a <panic>
    return -1;
    80005374:	5a7d                	li	s4,-1
    80005376:	bfc1                	j	80005346 <kfilewrite+0xfa>
      return -1;
    80005378:	5a7d                	li	s4,-1
    8000537a:	b7f1                	j	80005346 <kfilewrite+0xfa>
    8000537c:	5a7d                	li	s4,-1
    8000537e:	b7e1                	j	80005346 <kfilewrite+0xfa>

0000000080005380 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005380:	7179                	addi	sp,sp,-48
    80005382:	f406                	sd	ra,40(sp)
    80005384:	f022                	sd	s0,32(sp)
    80005386:	ec26                	sd	s1,24(sp)
    80005388:	e84a                	sd	s2,16(sp)
    8000538a:	e44e                	sd	s3,8(sp)
    8000538c:	e052                	sd	s4,0(sp)
    8000538e:	1800                	addi	s0,sp,48
    80005390:	84aa                	mv	s1,a0
    80005392:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005394:	0005b023          	sd	zero,0(a1)
    80005398:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000539c:	00000097          	auipc	ra,0x0
    800053a0:	a02080e7          	jalr	-1534(ra) # 80004d9e <filealloc>
    800053a4:	e088                	sd	a0,0(s1)
    800053a6:	c551                	beqz	a0,80005432 <pipealloc+0xb2>
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	9f6080e7          	jalr	-1546(ra) # 80004d9e <filealloc>
    800053b0:	00aa3023          	sd	a0,0(s4)
    800053b4:	c92d                	beqz	a0,80005426 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	71c080e7          	jalr	1820(ra) # 80000ad2 <kalloc>
    800053be:	892a                	mv	s2,a0
    800053c0:	c125                	beqz	a0,80005420 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800053c2:	4985                	li	s3,1
    800053c4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800053c8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800053cc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800053d0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053d4:	00003597          	auipc	a1,0x3
    800053d8:	37c58593          	addi	a1,a1,892 # 80008750 <syscalls+0x2e8>
    800053dc:	ffffb097          	auipc	ra,0xffffb
    800053e0:	756080e7          	jalr	1878(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800053e4:	609c                	ld	a5,0(s1)
    800053e6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800053ea:	609c                	ld	a5,0(s1)
    800053ec:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800053f0:	609c                	ld	a5,0(s1)
    800053f2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800053f6:	609c                	ld	a5,0(s1)
    800053f8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800053fc:	000a3783          	ld	a5,0(s4)
    80005400:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005404:	000a3783          	ld	a5,0(s4)
    80005408:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000540c:	000a3783          	ld	a5,0(s4)
    80005410:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005414:	000a3783          	ld	a5,0(s4)
    80005418:	0127b823          	sd	s2,16(a5)
  return 0;
    8000541c:	4501                	li	a0,0
    8000541e:	a025                	j	80005446 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005420:	6088                	ld	a0,0(s1)
    80005422:	e501                	bnez	a0,8000542a <pipealloc+0xaa>
    80005424:	a039                	j	80005432 <pipealloc+0xb2>
    80005426:	6088                	ld	a0,0(s1)
    80005428:	c51d                	beqz	a0,80005456 <pipealloc+0xd6>
    fileclose(*f0);
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	a30080e7          	jalr	-1488(ra) # 80004e5a <fileclose>
  if(*f1)
    80005432:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005436:	557d                	li	a0,-1
  if(*f1)
    80005438:	c799                	beqz	a5,80005446 <pipealloc+0xc6>
    fileclose(*f1);
    8000543a:	853e                	mv	a0,a5
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	a1e080e7          	jalr	-1506(ra) # 80004e5a <fileclose>
  return -1;
    80005444:	557d                	li	a0,-1
}
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6942                	ld	s2,16(sp)
    8000544e:	69a2                	ld	s3,8(sp)
    80005450:	6a02                	ld	s4,0(sp)
    80005452:	6145                	addi	sp,sp,48
    80005454:	8082                	ret
  return -1;
    80005456:	557d                	li	a0,-1
    80005458:	b7fd                	j	80005446 <pipealloc+0xc6>

000000008000545a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000545a:	1101                	addi	sp,sp,-32
    8000545c:	ec06                	sd	ra,24(sp)
    8000545e:	e822                	sd	s0,16(sp)
    80005460:	e426                	sd	s1,8(sp)
    80005462:	e04a                	sd	s2,0(sp)
    80005464:	1000                	addi	s0,sp,32
    80005466:	84aa                	mv	s1,a0
    80005468:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000546a:	ffffb097          	auipc	ra,0xffffb
    8000546e:	758080e7          	jalr	1880(ra) # 80000bc2 <acquire>
  if(writable){
    80005472:	02090d63          	beqz	s2,800054ac <pipeclose+0x52>
    pi->writeopen = 0;
    80005476:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000547a:	21848513          	addi	a0,s1,536
    8000547e:	ffffd097          	auipc	ra,0xffffd
    80005482:	424080e7          	jalr	1060(ra) # 800028a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005486:	2204b783          	ld	a5,544(s1)
    8000548a:	eb95                	bnez	a5,800054be <pipeclose+0x64>
    release(&pi->lock);
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffb097          	auipc	ra,0xffffb
    80005492:	7e8080e7          	jalr	2024(ra) # 80000c76 <release>
    kfree((char*)pi);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffb097          	auipc	ra,0xffffb
    8000549c:	53e080e7          	jalr	1342(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800054a0:	60e2                	ld	ra,24(sp)
    800054a2:	6442                	ld	s0,16(sp)
    800054a4:	64a2                	ld	s1,8(sp)
    800054a6:	6902                	ld	s2,0(sp)
    800054a8:	6105                	addi	sp,sp,32
    800054aa:	8082                	ret
    pi->readopen = 0;
    800054ac:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800054b0:	21c48513          	addi	a0,s1,540
    800054b4:	ffffd097          	auipc	ra,0xffffd
    800054b8:	3ee080e7          	jalr	1006(ra) # 800028a2 <wakeup>
    800054bc:	b7e9                	j	80005486 <pipeclose+0x2c>
    release(&pi->lock);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffb097          	auipc	ra,0xffffb
    800054c4:	7b6080e7          	jalr	1974(ra) # 80000c76 <release>
}
    800054c8:	bfe1                	j	800054a0 <pipeclose+0x46>

00000000800054ca <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800054ca:	711d                	addi	sp,sp,-96
    800054cc:	ec86                	sd	ra,88(sp)
    800054ce:	e8a2                	sd	s0,80(sp)
    800054d0:	e4a6                	sd	s1,72(sp)
    800054d2:	e0ca                	sd	s2,64(sp)
    800054d4:	fc4e                	sd	s3,56(sp)
    800054d6:	f852                	sd	s4,48(sp)
    800054d8:	f456                	sd	s5,40(sp)
    800054da:	f05a                	sd	s6,32(sp)
    800054dc:	ec5e                	sd	s7,24(sp)
    800054de:	e862                	sd	s8,16(sp)
    800054e0:	1080                	addi	s0,sp,96
    800054e2:	84aa                	mv	s1,a0
    800054e4:	8aae                	mv	s5,a1
    800054e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800054e8:	ffffd097          	auipc	ra,0xffffd
    800054ec:	a62080e7          	jalr	-1438(ra) # 80001f4a <myproc>
    800054f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffb097          	auipc	ra,0xffffb
    800054f8:	6ce080e7          	jalr	1742(ra) # 80000bc2 <acquire>
  while(i < n){
    800054fc:	0b405363          	blez	s4,800055a2 <pipewrite+0xd8>
  int i = 0;
    80005500:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005502:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005504:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005508:	21c48b93          	addi	s7,s1,540
    8000550c:	a089                	j	8000554e <pipewrite+0x84>
      release(&pi->lock);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffb097          	auipc	ra,0xffffb
    80005514:	766080e7          	jalr	1894(ra) # 80000c76 <release>
      return -1;
    80005518:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000551a:	854a                	mv	a0,s2
    8000551c:	60e6                	ld	ra,88(sp)
    8000551e:	6446                	ld	s0,80(sp)
    80005520:	64a6                	ld	s1,72(sp)
    80005522:	6906                	ld	s2,64(sp)
    80005524:	79e2                	ld	s3,56(sp)
    80005526:	7a42                	ld	s4,48(sp)
    80005528:	7aa2                	ld	s5,40(sp)
    8000552a:	7b02                	ld	s6,32(sp)
    8000552c:	6be2                	ld	s7,24(sp)
    8000552e:	6c42                	ld	s8,16(sp)
    80005530:	6125                	addi	sp,sp,96
    80005532:	8082                	ret
      wakeup(&pi->nread);
    80005534:	8562                	mv	a0,s8
    80005536:	ffffd097          	auipc	ra,0xffffd
    8000553a:	36c080e7          	jalr	876(ra) # 800028a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000553e:	85a6                	mv	a1,s1
    80005540:	855e                	mv	a0,s7
    80005542:	ffffd097          	auipc	ra,0xffffd
    80005546:	1d4080e7          	jalr	468(ra) # 80002716 <sleep>
  while(i < n){
    8000554a:	05495d63          	bge	s2,s4,800055a4 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000554e:	2204a783          	lw	a5,544(s1)
    80005552:	dfd5                	beqz	a5,8000550e <pipewrite+0x44>
    80005554:	0289a783          	lw	a5,40(s3)
    80005558:	fbdd                	bnez	a5,8000550e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000555a:	2184a783          	lw	a5,536(s1)
    8000555e:	21c4a703          	lw	a4,540(s1)
    80005562:	2007879b          	addiw	a5,a5,512
    80005566:	fcf707e3          	beq	a4,a5,80005534 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000556a:	4685                	li	a3,1
    8000556c:	01590633          	add	a2,s2,s5
    80005570:	faf40593          	addi	a1,s0,-81
    80005574:	0509b503          	ld	a0,80(s3)
    80005578:	ffffc097          	auipc	ra,0xffffc
    8000557c:	17c080e7          	jalr	380(ra) # 800016f4 <copyin>
    80005580:	03650263          	beq	a0,s6,800055a4 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005584:	21c4a783          	lw	a5,540(s1)
    80005588:	0017871b          	addiw	a4,a5,1
    8000558c:	20e4ae23          	sw	a4,540(s1)
    80005590:	1ff7f793          	andi	a5,a5,511
    80005594:	97a6                	add	a5,a5,s1
    80005596:	faf44703          	lbu	a4,-81(s0)
    8000559a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000559e:	2905                	addiw	s2,s2,1
    800055a0:	b76d                	j	8000554a <pipewrite+0x80>
  int i = 0;
    800055a2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800055a4:	21848513          	addi	a0,s1,536
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	2fa080e7          	jalr	762(ra) # 800028a2 <wakeup>
  release(&pi->lock);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffb097          	auipc	ra,0xffffb
    800055b6:	6c4080e7          	jalr	1732(ra) # 80000c76 <release>
  return i;
    800055ba:	b785                	j	8000551a <pipewrite+0x50>

00000000800055bc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800055bc:	715d                	addi	sp,sp,-80
    800055be:	e486                	sd	ra,72(sp)
    800055c0:	e0a2                	sd	s0,64(sp)
    800055c2:	fc26                	sd	s1,56(sp)
    800055c4:	f84a                	sd	s2,48(sp)
    800055c6:	f44e                	sd	s3,40(sp)
    800055c8:	f052                	sd	s4,32(sp)
    800055ca:	ec56                	sd	s5,24(sp)
    800055cc:	e85a                	sd	s6,16(sp)
    800055ce:	0880                	addi	s0,sp,80
    800055d0:	84aa                	mv	s1,a0
    800055d2:	892e                	mv	s2,a1
    800055d4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	974080e7          	jalr	-1676(ra) # 80001f4a <myproc>
    800055de:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	5e0080e7          	jalr	1504(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055ea:	2184a703          	lw	a4,536(s1)
    800055ee:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055f2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055f6:	02f71463          	bne	a4,a5,8000561e <piperead+0x62>
    800055fa:	2244a783          	lw	a5,548(s1)
    800055fe:	c385                	beqz	a5,8000561e <piperead+0x62>
    if(pr->killed){
    80005600:	028a2783          	lw	a5,40(s4)
    80005604:	ebc1                	bnez	a5,80005694 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005606:	85a6                	mv	a1,s1
    80005608:	854e                	mv	a0,s3
    8000560a:	ffffd097          	auipc	ra,0xffffd
    8000560e:	10c080e7          	jalr	268(ra) # 80002716 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005612:	2184a703          	lw	a4,536(s1)
    80005616:	21c4a783          	lw	a5,540(s1)
    8000561a:	fef700e3          	beq	a4,a5,800055fa <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000561e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005620:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005622:	05505363          	blez	s5,80005668 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005626:	2184a783          	lw	a5,536(s1)
    8000562a:	21c4a703          	lw	a4,540(s1)
    8000562e:	02f70d63          	beq	a4,a5,80005668 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005632:	0017871b          	addiw	a4,a5,1
    80005636:	20e4ac23          	sw	a4,536(s1)
    8000563a:	1ff7f793          	andi	a5,a5,511
    8000563e:	97a6                	add	a5,a5,s1
    80005640:	0187c783          	lbu	a5,24(a5)
    80005644:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005648:	4685                	li	a3,1
    8000564a:	fbf40613          	addi	a2,s0,-65
    8000564e:	85ca                	mv	a1,s2
    80005650:	050a3503          	ld	a0,80(s4)
    80005654:	ffffc097          	auipc	ra,0xffffc
    80005658:	014080e7          	jalr	20(ra) # 80001668 <copyout>
    8000565c:	01650663          	beq	a0,s6,80005668 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005660:	2985                	addiw	s3,s3,1
    80005662:	0905                	addi	s2,s2,1
    80005664:	fd3a91e3          	bne	s5,s3,80005626 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005668:	21c48513          	addi	a0,s1,540
    8000566c:	ffffd097          	auipc	ra,0xffffd
    80005670:	236080e7          	jalr	566(ra) # 800028a2 <wakeup>
  release(&pi->lock);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffb097          	auipc	ra,0xffffb
    8000567a:	600080e7          	jalr	1536(ra) # 80000c76 <release>
  return i;
}
    8000567e:	854e                	mv	a0,s3
    80005680:	60a6                	ld	ra,72(sp)
    80005682:	6406                	ld	s0,64(sp)
    80005684:	74e2                	ld	s1,56(sp)
    80005686:	7942                	ld	s2,48(sp)
    80005688:	79a2                	ld	s3,40(sp)
    8000568a:	7a02                	ld	s4,32(sp)
    8000568c:	6ae2                	ld	s5,24(sp)
    8000568e:	6b42                	ld	s6,16(sp)
    80005690:	6161                	addi	sp,sp,80
    80005692:	8082                	ret
      release(&pi->lock);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	5e0080e7          	jalr	1504(ra) # 80000c76 <release>
      return -1;
    8000569e:	59fd                	li	s3,-1
    800056a0:	bff9                	j	8000567e <piperead+0xc2>

00000000800056a2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800056a2:	de010113          	addi	sp,sp,-544
    800056a6:	20113c23          	sd	ra,536(sp)
    800056aa:	20813823          	sd	s0,528(sp)
    800056ae:	20913423          	sd	s1,520(sp)
    800056b2:	21213023          	sd	s2,512(sp)
    800056b6:	ffce                	sd	s3,504(sp)
    800056b8:	fbd2                	sd	s4,496(sp)
    800056ba:	f7d6                	sd	s5,488(sp)
    800056bc:	f3da                	sd	s6,480(sp)
    800056be:	efde                	sd	s7,472(sp)
    800056c0:	ebe2                	sd	s8,464(sp)
    800056c2:	e7e6                	sd	s9,456(sp)
    800056c4:	e3ea                	sd	s10,448(sp)
    800056c6:	ff6e                	sd	s11,440(sp)
    800056c8:	1400                	addi	s0,sp,544
    800056ca:	dea43c23          	sd	a0,-520(s0)
    800056ce:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	878080e7          	jalr	-1928(ra) # 80001f4a <myproc>
    800056da:	84aa                	mv	s1,a0

  #ifndef NONE
  if(p->pid > 2){
    800056dc:	5918                	lw	a4,48(a0)
    800056de:	4789                	li	a5,2
    800056e0:	04e7df63          	bge	a5,a4,8000573e <exec+0x9c>
    struct page_metadata *pg;
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800056e4:	17050713          	addi	a4,a0,368
    800056e8:	37050793          	addi	a5,a0,880
    800056ec:	86be                	mv	a3,a5
      pg->state = 0;
    800056ee:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    800056f2:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    800056f6:	00073823          	sd	zero,16(a4)
      pg->creationOrder=0;
    800056fa:	00073c23          	sd	zero,24(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800056fe:	02070713          	addi	a4,a4,32
    80005702:	fed716e3          	bne	a4,a3,800056ee <exec+0x4c>
    }
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80005706:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    8000570a:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    8000570e:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    80005712:	0007b823          	sd	zero,16(a5)
      pg->creationOrder=0;
    80005716:	0007bc23          	sd	zero,24(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000571a:	02078793          	addi	a5,a5,32
    8000571e:	fee796e3          	bne	a5,a4,8000570a <exec+0x68>
    }
    p->num_pages_in_swapfile = 0;
    80005722:	5604aa23          	sw	zero,1396(s1)
    p->num_pages_in_psyc = 0;
    80005726:	5604a823          	sw	zero,1392(s1)
    removeSwapFile(p);
    8000572a:	8526                	mv	a0,s1
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	ddc080e7          	jalr	-548(ra) # 80004508 <removeSwapFile>
    createSwapFile(p);
    80005734:	8526                	mv	a0,s1
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	f7a080e7          	jalr	-134(ra) # 800046b0 <createSwapFile>
  }
  #endif

  begin_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	250080e7          	jalr	592(ra) # 8000498e <begin_op>

  if((ip = namei(path)) == 0){
    80005746:	df843503          	ld	a0,-520(s0)
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	d12080e7          	jalr	-750(ra) # 8000445c <namei>
    80005752:	8aaa                	mv	s5,a0
    80005754:	c935                	beqz	a0,800057c8 <exec+0x126>
    end_op();
    return -1;
  }
  ilock(ip);
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	550080e7          	jalr	1360(ra) # 80003ca6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000575e:	04000713          	li	a4,64
    80005762:	4681                	li	a3,0
    80005764:	e4840613          	addi	a2,s0,-440
    80005768:	4581                	li	a1,0
    8000576a:	8556                	mv	a0,s5
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	7ee080e7          	jalr	2030(ra) # 80003f5a <readi>
    80005774:	04000793          	li	a5,64
    80005778:	00f51a63          	bne	a0,a5,8000578c <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000577c:	e4842703          	lw	a4,-440(s0)
    80005780:	464c47b7          	lui	a5,0x464c4
    80005784:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005788:	04f70663          	beq	a4,a5,800057d4 <exec+0x132>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000578c:	8556                	mv	a0,s5
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	77a080e7          	jalr	1914(ra) # 80003f08 <iunlockput>
    end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	278080e7          	jalr	632(ra) # 80004a0e <end_op>
  }
  return -1;
    8000579e:	557d                	li	a0,-1
}
    800057a0:	21813083          	ld	ra,536(sp)
    800057a4:	21013403          	ld	s0,528(sp)
    800057a8:	20813483          	ld	s1,520(sp)
    800057ac:	20013903          	ld	s2,512(sp)
    800057b0:	79fe                	ld	s3,504(sp)
    800057b2:	7a5e                	ld	s4,496(sp)
    800057b4:	7abe                	ld	s5,488(sp)
    800057b6:	7b1e                	ld	s6,480(sp)
    800057b8:	6bfe                	ld	s7,472(sp)
    800057ba:	6c5e                	ld	s8,464(sp)
    800057bc:	6cbe                	ld	s9,456(sp)
    800057be:	6d1e                	ld	s10,448(sp)
    800057c0:	7dfa                	ld	s11,440(sp)
    800057c2:	22010113          	addi	sp,sp,544
    800057c6:	8082                	ret
    end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	246080e7          	jalr	582(ra) # 80004a0e <end_op>
    return -1;
    800057d0:	557d                	li	a0,-1
    800057d2:	b7f9                	j	800057a0 <exec+0xfe>
  if((pagetable = proc_pagetable(p)) == 0)
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	838080e7          	jalr	-1992(ra) # 8000200e <proc_pagetable>
    800057de:	8b2a                	mv	s6,a0
    800057e0:	d555                	beqz	a0,8000578c <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057e2:	e6842783          	lw	a5,-408(s0)
    800057e6:	e8045703          	lhu	a4,-384(s0)
    800057ea:	c735                	beqz	a4,80005856 <exec+0x1b4>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800057ec:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057ee:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800057f2:	6a05                	lui	s4,0x1
    800057f4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800057f8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800057fc:	6d85                	lui	s11,0x1
    800057fe:	7d7d                	lui	s10,0xfffff
    80005800:	ac1d                	j	80005a36 <exec+0x394>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005802:	00003517          	auipc	a0,0x3
    80005806:	f5650513          	addi	a0,a0,-170 # 80008758 <syscalls+0x2f0>
    8000580a:	ffffb097          	auipc	ra,0xffffb
    8000580e:	d20080e7          	jalr	-736(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005812:	874a                	mv	a4,s2
    80005814:	009c86bb          	addw	a3,s9,s1
    80005818:	4581                	li	a1,0
    8000581a:	8556                	mv	a0,s5
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	73e080e7          	jalr	1854(ra) # 80003f5a <readi>
    80005824:	2501                	sext.w	a0,a0
    80005826:	1aa91863          	bne	s2,a0,800059d6 <exec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    8000582a:	009d84bb          	addw	s1,s11,s1
    8000582e:	013d09bb          	addw	s3,s10,s3
    80005832:	1f74f263          	bgeu	s1,s7,80005a16 <exec+0x374>
    pa = walkaddr(pagetable, va + i);
    80005836:	02049593          	slli	a1,s1,0x20
    8000583a:	9181                	srli	a1,a1,0x20
    8000583c:	95e2                	add	a1,a1,s8
    8000583e:	855a                	mv	a0,s6
    80005840:	ffffc097          	auipc	ra,0xffffc
    80005844:	80c080e7          	jalr	-2036(ra) # 8000104c <walkaddr>
    80005848:	862a                	mv	a2,a0
    if(pa == 0)
    8000584a:	dd45                	beqz	a0,80005802 <exec+0x160>
      n = PGSIZE;
    8000584c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000584e:	fd49f2e3          	bgeu	s3,s4,80005812 <exec+0x170>
      n = sz - i;
    80005852:	894e                	mv	s2,s3
    80005854:	bf7d                	j	80005812 <exec+0x170>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005856:	4481                	li	s1,0
  iunlockput(ip);
    80005858:	8556                	mv	a0,s5
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	6ae080e7          	jalr	1710(ra) # 80003f08 <iunlockput>
  end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	1ac080e7          	jalr	428(ra) # 80004a0e <end_op>
  p = myproc();
    8000586a:	ffffc097          	auipc	ra,0xffffc
    8000586e:	6e0080e7          	jalr	1760(ra) # 80001f4a <myproc>
    80005872:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005874:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005878:	6785                	lui	a5,0x1
    8000587a:	17fd                	addi	a5,a5,-1
    8000587c:	94be                	add	s1,s1,a5
    8000587e:	77fd                	lui	a5,0xfffff
    80005880:	8fe5                	and	a5,a5,s1
    80005882:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005886:	6609                	lui	a2,0x2
    80005888:	963e                	add	a2,a2,a5
    8000588a:	85be                	mv	a1,a5
    8000588c:	855a                	mv	a0,s6
    8000588e:	ffffc097          	auipc	ra,0xffffc
    80005892:	350080e7          	jalr	848(ra) # 80001bde <uvmalloc>
    80005896:	8c2a                	mv	s8,a0
  ip = 0;
    80005898:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000589a:	12050e63          	beqz	a0,800059d6 <exec+0x334>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000589e:	75f9                	lui	a1,0xffffe
    800058a0:	95aa                	add	a1,a1,a0
    800058a2:	855a                	mv	a0,s6
    800058a4:	ffffc097          	auipc	ra,0xffffc
    800058a8:	d92080e7          	jalr	-622(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800058ac:	7afd                	lui	s5,0xfffff
    800058ae:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800058b0:	de843783          	ld	a5,-536(s0)
    800058b4:	6388                	ld	a0,0(a5)
    800058b6:	c925                	beqz	a0,80005926 <exec+0x284>
    800058b8:	e8840993          	addi	s3,s0,-376
    800058bc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800058c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058c2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	57e080e7          	jalr	1406(ra) # 80000e42 <strlen>
    800058cc:	0015079b          	addiw	a5,a0,1
    800058d0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058d4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800058d8:	13596363          	bltu	s2,s5,800059fe <exec+0x35c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058dc:	de843d83          	ld	s11,-536(s0)
    800058e0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800058e4:	8552                	mv	a0,s4
    800058e6:	ffffb097          	auipc	ra,0xffffb
    800058ea:	55c080e7          	jalr	1372(ra) # 80000e42 <strlen>
    800058ee:	0015069b          	addiw	a3,a0,1
    800058f2:	8652                	mv	a2,s4
    800058f4:	85ca                	mv	a1,s2
    800058f6:	855a                	mv	a0,s6
    800058f8:	ffffc097          	auipc	ra,0xffffc
    800058fc:	d70080e7          	jalr	-656(ra) # 80001668 <copyout>
    80005900:	10054363          	bltz	a0,80005a06 <exec+0x364>
    ustack[argc] = sp;
    80005904:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005908:	0485                	addi	s1,s1,1
    8000590a:	008d8793          	addi	a5,s11,8
    8000590e:	def43423          	sd	a5,-536(s0)
    80005912:	008db503          	ld	a0,8(s11)
    80005916:	c911                	beqz	a0,8000592a <exec+0x288>
    if(argc >= MAXARG)
    80005918:	09a1                	addi	s3,s3,8
    8000591a:	fb9995e3          	bne	s3,s9,800058c4 <exec+0x222>
  sz = sz1;
    8000591e:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005922:	4a81                	li	s5,0
    80005924:	a84d                	j	800059d6 <exec+0x334>
  sp = sz;
    80005926:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005928:	4481                	li	s1,0
  ustack[argc] = 0;
    8000592a:	00349793          	slli	a5,s1,0x3
    8000592e:	f9040713          	addi	a4,s0,-112
    80005932:	97ba                	add	a5,a5,a4
    80005934:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffc8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005938:	00148693          	addi	a3,s1,1
    8000593c:	068e                	slli	a3,a3,0x3
    8000593e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005942:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005946:	01597663          	bgeu	s2,s5,80005952 <exec+0x2b0>
  sz = sz1;
    8000594a:	df843823          	sd	s8,-528(s0)
  ip = 0;
    8000594e:	4a81                	li	s5,0
    80005950:	a059                	j	800059d6 <exec+0x334>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005952:	e8840613          	addi	a2,s0,-376
    80005956:	85ca                	mv	a1,s2
    80005958:	855a                	mv	a0,s6
    8000595a:	ffffc097          	auipc	ra,0xffffc
    8000595e:	d0e080e7          	jalr	-754(ra) # 80001668 <copyout>
    80005962:	0a054663          	bltz	a0,80005a0e <exec+0x36c>
  p->trapframe->a1 = sp;
    80005966:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000596a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000596e:	df843783          	ld	a5,-520(s0)
    80005972:	0007c703          	lbu	a4,0(a5)
    80005976:	cf11                	beqz	a4,80005992 <exec+0x2f0>
    80005978:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000597a:	02f00693          	li	a3,47
    8000597e:	a039                	j	8000598c <exec+0x2ea>
      last = s+1;
    80005980:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005984:	0785                	addi	a5,a5,1
    80005986:	fff7c703          	lbu	a4,-1(a5)
    8000598a:	c701                	beqz	a4,80005992 <exec+0x2f0>
    if(*s == '/')
    8000598c:	fed71ce3          	bne	a4,a3,80005984 <exec+0x2e2>
    80005990:	bfc5                	j	80005980 <exec+0x2de>
  safestrcpy(p->name, last, sizeof(p->name));
    80005992:	4641                	li	a2,16
    80005994:	df843583          	ld	a1,-520(s0)
    80005998:	158b8513          	addi	a0,s7,344
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	474080e7          	jalr	1140(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    800059a4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800059a8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800059ac:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800059b0:	058bb783          	ld	a5,88(s7)
    800059b4:	e6043703          	ld	a4,-416(s0)
    800059b8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800059ba:	058bb783          	ld	a5,88(s7)
    800059be:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059c2:	85ea                	mv	a1,s10
    800059c4:	ffffc097          	auipc	ra,0xffffc
    800059c8:	6e6080e7          	jalr	1766(ra) # 800020aa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059cc:	0004851b          	sext.w	a0,s1
    800059d0:	bbc1                	j	800057a0 <exec+0xfe>
    800059d2:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    800059d6:	df043583          	ld	a1,-528(s0)
    800059da:	855a                	mv	a0,s6
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	6ce080e7          	jalr	1742(ra) # 800020aa <proc_freepagetable>
  if(ip){
    800059e4:	da0a94e3          	bnez	s5,8000578c <exec+0xea>
  return -1;
    800059e8:	557d                	li	a0,-1
    800059ea:	bb5d                	j	800057a0 <exec+0xfe>
    800059ec:	de943823          	sd	s1,-528(s0)
    800059f0:	b7dd                	j	800059d6 <exec+0x334>
    800059f2:	de943823          	sd	s1,-528(s0)
    800059f6:	b7c5                	j	800059d6 <exec+0x334>
    800059f8:	de943823          	sd	s1,-528(s0)
    800059fc:	bfe9                	j	800059d6 <exec+0x334>
  sz = sz1;
    800059fe:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a02:	4a81                	li	s5,0
    80005a04:	bfc9                	j	800059d6 <exec+0x334>
  sz = sz1;
    80005a06:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a0a:	4a81                	li	s5,0
    80005a0c:	b7e9                	j	800059d6 <exec+0x334>
  sz = sz1;
    80005a0e:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a12:	4a81                	li	s5,0
    80005a14:	b7c9                	j	800059d6 <exec+0x334>
    sz = sz1;
    80005a16:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a1a:	e0843783          	ld	a5,-504(s0)
    80005a1e:	0017869b          	addiw	a3,a5,1
    80005a22:	e0d43423          	sd	a3,-504(s0)
    80005a26:	e0043783          	ld	a5,-512(s0)
    80005a2a:	0387879b          	addiw	a5,a5,56
    80005a2e:	e8045703          	lhu	a4,-384(s0)
    80005a32:	e2e6d3e3          	bge	a3,a4,80005858 <exec+0x1b6>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a36:	2781                	sext.w	a5,a5
    80005a38:	e0f43023          	sd	a5,-512(s0)
    80005a3c:	03800713          	li	a4,56
    80005a40:	86be                	mv	a3,a5
    80005a42:	e1040613          	addi	a2,s0,-496
    80005a46:	4581                	li	a1,0
    80005a48:	8556                	mv	a0,s5
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	510080e7          	jalr	1296(ra) # 80003f5a <readi>
    80005a52:	03800793          	li	a5,56
    80005a56:	f6f51ee3          	bne	a0,a5,800059d2 <exec+0x330>
    if(ph.type != ELF_PROG_LOAD)
    80005a5a:	e1042783          	lw	a5,-496(s0)
    80005a5e:	4705                	li	a4,1
    80005a60:	fae79de3          	bne	a5,a4,80005a1a <exec+0x378>
    if(ph.memsz < ph.filesz)
    80005a64:	e3843603          	ld	a2,-456(s0)
    80005a68:	e3043783          	ld	a5,-464(s0)
    80005a6c:	f8f660e3          	bltu	a2,a5,800059ec <exec+0x34a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a70:	e2043783          	ld	a5,-480(s0)
    80005a74:	963e                	add	a2,a2,a5
    80005a76:	f6f66ee3          	bltu	a2,a5,800059f2 <exec+0x350>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a7a:	85a6                	mv	a1,s1
    80005a7c:	855a                	mv	a0,s6
    80005a7e:	ffffc097          	auipc	ra,0xffffc
    80005a82:	160080e7          	jalr	352(ra) # 80001bde <uvmalloc>
    80005a86:	dea43823          	sd	a0,-528(s0)
    80005a8a:	d53d                	beqz	a0,800059f8 <exec+0x356>
    if(ph.vaddr % PGSIZE != 0)
    80005a8c:	e2043c03          	ld	s8,-480(s0)
    80005a90:	de043783          	ld	a5,-544(s0)
    80005a94:	00fc77b3          	and	a5,s8,a5
    80005a98:	ff9d                	bnez	a5,800059d6 <exec+0x334>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a9a:	e1842c83          	lw	s9,-488(s0)
    80005a9e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005aa2:	f60b8ae3          	beqz	s7,80005a16 <exec+0x374>
    80005aa6:	89de                	mv	s3,s7
    80005aa8:	4481                	li	s1,0
    80005aaa:	b371                	j	80005836 <exec+0x194>

0000000080005aac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005aac:	7179                	addi	sp,sp,-48
    80005aae:	f406                	sd	ra,40(sp)
    80005ab0:	f022                	sd	s0,32(sp)
    80005ab2:	ec26                	sd	s1,24(sp)
    80005ab4:	e84a                	sd	s2,16(sp)
    80005ab6:	1800                	addi	s0,sp,48
    80005ab8:	892e                	mv	s2,a1
    80005aba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005abc:	fdc40593          	addi	a1,s0,-36
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	674080e7          	jalr	1652(ra) # 80003134 <argint>
    80005ac8:	04054063          	bltz	a0,80005b08 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005acc:	fdc42703          	lw	a4,-36(s0)
    80005ad0:	47bd                	li	a5,15
    80005ad2:	02e7ed63          	bltu	a5,a4,80005b0c <argfd+0x60>
    80005ad6:	ffffc097          	auipc	ra,0xffffc
    80005ada:	474080e7          	jalr	1140(ra) # 80001f4a <myproc>
    80005ade:	fdc42703          	lw	a4,-36(s0)
    80005ae2:	01a70793          	addi	a5,a4,26
    80005ae6:	078e                	slli	a5,a5,0x3
    80005ae8:	953e                	add	a0,a0,a5
    80005aea:	611c                	ld	a5,0(a0)
    80005aec:	c395                	beqz	a5,80005b10 <argfd+0x64>
    return -1;
  if(pfd)
    80005aee:	00090463          	beqz	s2,80005af6 <argfd+0x4a>
    *pfd = fd;
    80005af2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005af6:	4501                	li	a0,0
  if(pf)
    80005af8:	c091                	beqz	s1,80005afc <argfd+0x50>
    *pf = f;
    80005afa:	e09c                	sd	a5,0(s1)
}
    80005afc:	70a2                	ld	ra,40(sp)
    80005afe:	7402                	ld	s0,32(sp)
    80005b00:	64e2                	ld	s1,24(sp)
    80005b02:	6942                	ld	s2,16(sp)
    80005b04:	6145                	addi	sp,sp,48
    80005b06:	8082                	ret
    return -1;
    80005b08:	557d                	li	a0,-1
    80005b0a:	bfcd                	j	80005afc <argfd+0x50>
    return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	b7fd                	j	80005afc <argfd+0x50>
    80005b10:	557d                	li	a0,-1
    80005b12:	b7ed                	j	80005afc <argfd+0x50>

0000000080005b14 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b14:	1101                	addi	sp,sp,-32
    80005b16:	ec06                	sd	ra,24(sp)
    80005b18:	e822                	sd	s0,16(sp)
    80005b1a:	e426                	sd	s1,8(sp)
    80005b1c:	1000                	addi	s0,sp,32
    80005b1e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b20:	ffffc097          	auipc	ra,0xffffc
    80005b24:	42a080e7          	jalr	1066(ra) # 80001f4a <myproc>
    80005b28:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b2a:	0d050793          	addi	a5,a0,208
    80005b2e:	4501                	li	a0,0
    80005b30:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b32:	6398                	ld	a4,0(a5)
    80005b34:	cb19                	beqz	a4,80005b4a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b36:	2505                	addiw	a0,a0,1
    80005b38:	07a1                	addi	a5,a5,8
    80005b3a:	fed51ce3          	bne	a0,a3,80005b32 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b3e:	557d                	li	a0,-1
}
    80005b40:	60e2                	ld	ra,24(sp)
    80005b42:	6442                	ld	s0,16(sp)
    80005b44:	64a2                	ld	s1,8(sp)
    80005b46:	6105                	addi	sp,sp,32
    80005b48:	8082                	ret
      p->ofile[fd] = f;
    80005b4a:	01a50793          	addi	a5,a0,26
    80005b4e:	078e                	slli	a5,a5,0x3
    80005b50:	963e                	add	a2,a2,a5
    80005b52:	e204                	sd	s1,0(a2)
      return fd;
    80005b54:	b7f5                	j	80005b40 <fdalloc+0x2c>

0000000080005b56 <sys_dup>:

uint64
sys_dup(void)
{
    80005b56:	7179                	addi	sp,sp,-48
    80005b58:	f406                	sd	ra,40(sp)
    80005b5a:	f022                	sd	s0,32(sp)
    80005b5c:	ec26                	sd	s1,24(sp)
    80005b5e:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005b60:	fd840613          	addi	a2,s0,-40
    80005b64:	4581                	li	a1,0
    80005b66:	4501                	li	a0,0
    80005b68:	00000097          	auipc	ra,0x0
    80005b6c:	f44080e7          	jalr	-188(ra) # 80005aac <argfd>
    return -1;
    80005b70:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b72:	02054363          	bltz	a0,80005b98 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b76:	fd843503          	ld	a0,-40(s0)
    80005b7a:	00000097          	auipc	ra,0x0
    80005b7e:	f9a080e7          	jalr	-102(ra) # 80005b14 <fdalloc>
    80005b82:	84aa                	mv	s1,a0
    return -1;
    80005b84:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b86:	00054963          	bltz	a0,80005b98 <sys_dup+0x42>
  filedup(f);
    80005b8a:	fd843503          	ld	a0,-40(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	27a080e7          	jalr	634(ra) # 80004e08 <filedup>
  return fd;
    80005b96:	87a6                	mv	a5,s1
}
    80005b98:	853e                	mv	a0,a5
    80005b9a:	70a2                	ld	ra,40(sp)
    80005b9c:	7402                	ld	s0,32(sp)
    80005b9e:	64e2                	ld	s1,24(sp)
    80005ba0:	6145                	addi	sp,sp,48
    80005ba2:	8082                	ret

0000000080005ba4 <sys_read>:

uint64
sys_read(void)
{
    80005ba4:	7179                	addi	sp,sp,-48
    80005ba6:	f406                	sd	ra,40(sp)
    80005ba8:	f022                	sd	s0,32(sp)
    80005baa:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bac:	fe840613          	addi	a2,s0,-24
    80005bb0:	4581                	li	a1,0
    80005bb2:	4501                	li	a0,0
    80005bb4:	00000097          	auipc	ra,0x0
    80005bb8:	ef8080e7          	jalr	-264(ra) # 80005aac <argfd>
    return -1;
    80005bbc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bbe:	04054163          	bltz	a0,80005c00 <sys_read+0x5c>
    80005bc2:	fe440593          	addi	a1,s0,-28
    80005bc6:	4509                	li	a0,2
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	56c080e7          	jalr	1388(ra) # 80003134 <argint>
    return -1;
    80005bd0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bd2:	02054763          	bltz	a0,80005c00 <sys_read+0x5c>
    80005bd6:	fd840593          	addi	a1,s0,-40
    80005bda:	4505                	li	a0,1
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	57a080e7          	jalr	1402(ra) # 80003156 <argaddr>
    return -1;
    80005be4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005be6:	00054d63          	bltz	a0,80005c00 <sys_read+0x5c>
  return fileread(f, p, n);
    80005bea:	fe442603          	lw	a2,-28(s0)
    80005bee:	fd843583          	ld	a1,-40(s0)
    80005bf2:	fe843503          	ld	a0,-24(s0)
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	39e080e7          	jalr	926(ra) # 80004f94 <fileread>
    80005bfe:	87aa                	mv	a5,a0
}
    80005c00:	853e                	mv	a0,a5
    80005c02:	70a2                	ld	ra,40(sp)
    80005c04:	7402                	ld	s0,32(sp)
    80005c06:	6145                	addi	sp,sp,48
    80005c08:	8082                	ret

0000000080005c0a <sys_write>:

uint64
sys_write(void)
{
    80005c0a:	7179                	addi	sp,sp,-48
    80005c0c:	f406                	sd	ra,40(sp)
    80005c0e:	f022                	sd	s0,32(sp)
    80005c10:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c12:	fe840613          	addi	a2,s0,-24
    80005c16:	4581                	li	a1,0
    80005c18:	4501                	li	a0,0
    80005c1a:	00000097          	auipc	ra,0x0
    80005c1e:	e92080e7          	jalr	-366(ra) # 80005aac <argfd>
    return -1;
    80005c22:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c24:	04054163          	bltz	a0,80005c66 <sys_write+0x5c>
    80005c28:	fe440593          	addi	a1,s0,-28
    80005c2c:	4509                	li	a0,2
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	506080e7          	jalr	1286(ra) # 80003134 <argint>
    return -1;
    80005c36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c38:	02054763          	bltz	a0,80005c66 <sys_write+0x5c>
    80005c3c:	fd840593          	addi	a1,s0,-40
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	514080e7          	jalr	1300(ra) # 80003156 <argaddr>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c4c:	00054d63          	bltz	a0,80005c66 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005c50:	fe442603          	lw	a2,-28(s0)
    80005c54:	fd843583          	ld	a1,-40(s0)
    80005c58:	fe843503          	ld	a0,-24(s0)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	3fa080e7          	jalr	1018(ra) # 80005056 <filewrite>
    80005c64:	87aa                	mv	a5,a0
}
    80005c66:	853e                	mv	a0,a5
    80005c68:	70a2                	ld	ra,40(sp)
    80005c6a:	7402                	ld	s0,32(sp)
    80005c6c:	6145                	addi	sp,sp,48
    80005c6e:	8082                	ret

0000000080005c70 <sys_close>:

uint64
sys_close(void)
{
    80005c70:	1101                	addi	sp,sp,-32
    80005c72:	ec06                	sd	ra,24(sp)
    80005c74:	e822                	sd	s0,16(sp)
    80005c76:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005c78:	fe040613          	addi	a2,s0,-32
    80005c7c:	fec40593          	addi	a1,s0,-20
    80005c80:	4501                	li	a0,0
    80005c82:	00000097          	auipc	ra,0x0
    80005c86:	e2a080e7          	jalr	-470(ra) # 80005aac <argfd>
    return -1;
    80005c8a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c8c:	02054463          	bltz	a0,80005cb4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	2ba080e7          	jalr	698(ra) # 80001f4a <myproc>
    80005c98:	fec42783          	lw	a5,-20(s0)
    80005c9c:	07e9                	addi	a5,a5,26
    80005c9e:	078e                	slli	a5,a5,0x3
    80005ca0:	97aa                	add	a5,a5,a0
    80005ca2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005ca6:	fe043503          	ld	a0,-32(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	1b0080e7          	jalr	432(ra) # 80004e5a <fileclose>
  return 0;
    80005cb2:	4781                	li	a5,0
}
    80005cb4:	853e                	mv	a0,a5
    80005cb6:	60e2                	ld	ra,24(sp)
    80005cb8:	6442                	ld	s0,16(sp)
    80005cba:	6105                	addi	sp,sp,32
    80005cbc:	8082                	ret

0000000080005cbe <sys_fstat>:

uint64
sys_fstat(void)
{
    80005cbe:	1101                	addi	sp,sp,-32
    80005cc0:	ec06                	sd	ra,24(sp)
    80005cc2:	e822                	sd	s0,16(sp)
    80005cc4:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cc6:	fe840613          	addi	a2,s0,-24
    80005cca:	4581                	li	a1,0
    80005ccc:	4501                	li	a0,0
    80005cce:	00000097          	auipc	ra,0x0
    80005cd2:	dde080e7          	jalr	-546(ra) # 80005aac <argfd>
    return -1;
    80005cd6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cd8:	02054563          	bltz	a0,80005d02 <sys_fstat+0x44>
    80005cdc:	fe040593          	addi	a1,s0,-32
    80005ce0:	4505                	li	a0,1
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	474080e7          	jalr	1140(ra) # 80003156 <argaddr>
    return -1;
    80005cea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cec:	00054b63          	bltz	a0,80005d02 <sys_fstat+0x44>
  return filestat(f, st);
    80005cf0:	fe043583          	ld	a1,-32(s0)
    80005cf4:	fe843503          	ld	a0,-24(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	22a080e7          	jalr	554(ra) # 80004f22 <filestat>
    80005d00:	87aa                	mv	a5,a0
}
    80005d02:	853e                	mv	a0,a5
    80005d04:	60e2                	ld	ra,24(sp)
    80005d06:	6442                	ld	s0,16(sp)
    80005d08:	6105                	addi	sp,sp,32
    80005d0a:	8082                	ret

0000000080005d0c <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005d0c:	7169                	addi	sp,sp,-304
    80005d0e:	f606                	sd	ra,296(sp)
    80005d10:	f222                	sd	s0,288(sp)
    80005d12:	ee26                	sd	s1,280(sp)
    80005d14:	ea4a                	sd	s2,272(sp)
    80005d16:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d18:	08000613          	li	a2,128
    80005d1c:	ed040593          	addi	a1,s0,-304
    80005d20:	4501                	li	a0,0
    80005d22:	ffffd097          	auipc	ra,0xffffd
    80005d26:	456080e7          	jalr	1110(ra) # 80003178 <argstr>
    return -1;
    80005d2a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d2c:	10054e63          	bltz	a0,80005e48 <sys_link+0x13c>
    80005d30:	08000613          	li	a2,128
    80005d34:	f5040593          	addi	a1,s0,-176
    80005d38:	4505                	li	a0,1
    80005d3a:	ffffd097          	auipc	ra,0xffffd
    80005d3e:	43e080e7          	jalr	1086(ra) # 80003178 <argstr>
    return -1;
    80005d42:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d44:	10054263          	bltz	a0,80005e48 <sys_link+0x13c>

  begin_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	c46080e7          	jalr	-954(ra) # 8000498e <begin_op>
  if((ip = namei(old)) == 0){
    80005d50:	ed040513          	addi	a0,s0,-304
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	708080e7          	jalr	1800(ra) # 8000445c <namei>
    80005d5c:	84aa                	mv	s1,a0
    80005d5e:	c551                	beqz	a0,80005dea <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	f46080e7          	jalr	-186(ra) # 80003ca6 <ilock>
  if(ip->type == T_DIR){
    80005d68:	04449703          	lh	a4,68(s1)
    80005d6c:	4785                	li	a5,1
    80005d6e:	08f70463          	beq	a4,a5,80005df6 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005d72:	04a4d783          	lhu	a5,74(s1)
    80005d76:	2785                	addiw	a5,a5,1
    80005d78:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d7c:	8526                	mv	a0,s1
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	e5e080e7          	jalr	-418(ra) # 80003bdc <iupdate>
  iunlock(ip);
    80005d86:	8526                	mv	a0,s1
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	fe0080e7          	jalr	-32(ra) # 80003d68 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005d90:	fd040593          	addi	a1,s0,-48
    80005d94:	f5040513          	addi	a0,s0,-176
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	6e2080e7          	jalr	1762(ra) # 8000447a <nameiparent>
    80005da0:	892a                	mv	s2,a0
    80005da2:	c935                	beqz	a0,80005e16 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	f02080e7          	jalr	-254(ra) # 80003ca6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005dac:	00092703          	lw	a4,0(s2)
    80005db0:	409c                	lw	a5,0(s1)
    80005db2:	04f71d63          	bne	a4,a5,80005e0c <sys_link+0x100>
    80005db6:	40d0                	lw	a2,4(s1)
    80005db8:	fd040593          	addi	a1,s0,-48
    80005dbc:	854a                	mv	a0,s2
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	5dc080e7          	jalr	1500(ra) # 8000439a <dirlink>
    80005dc6:	04054363          	bltz	a0,80005e0c <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005dca:	854a                	mv	a0,s2
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	13c080e7          	jalr	316(ra) # 80003f08 <iunlockput>
  iput(ip);
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	08a080e7          	jalr	138(ra) # 80003e60 <iput>

  end_op();
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	c30080e7          	jalr	-976(ra) # 80004a0e <end_op>

  return 0;
    80005de6:	4781                	li	a5,0
    80005de8:	a085                	j	80005e48 <sys_link+0x13c>
    end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	c24080e7          	jalr	-988(ra) # 80004a0e <end_op>
    return -1;
    80005df2:	57fd                	li	a5,-1
    80005df4:	a891                	j	80005e48 <sys_link+0x13c>
    iunlockput(ip);
    80005df6:	8526                	mv	a0,s1
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	110080e7          	jalr	272(ra) # 80003f08 <iunlockput>
    end_op();
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	c0e080e7          	jalr	-1010(ra) # 80004a0e <end_op>
    return -1;
    80005e08:	57fd                	li	a5,-1
    80005e0a:	a83d                	j	80005e48 <sys_link+0x13c>
    iunlockput(dp);
    80005e0c:	854a                	mv	a0,s2
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	0fa080e7          	jalr	250(ra) # 80003f08 <iunlockput>

bad:
  ilock(ip);
    80005e16:	8526                	mv	a0,s1
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	e8e080e7          	jalr	-370(ra) # 80003ca6 <ilock>
  ip->nlink--;
    80005e20:	04a4d783          	lhu	a5,74(s1)
    80005e24:	37fd                	addiw	a5,a5,-1
    80005e26:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e2a:	8526                	mv	a0,s1
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	db0080e7          	jalr	-592(ra) # 80003bdc <iupdate>
  iunlockput(ip);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	0d2080e7          	jalr	210(ra) # 80003f08 <iunlockput>
  end_op();
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	bd0080e7          	jalr	-1072(ra) # 80004a0e <end_op>
  return -1;
    80005e46:	57fd                	li	a5,-1
}
    80005e48:	853e                	mv	a0,a5
    80005e4a:	70b2                	ld	ra,296(sp)
    80005e4c:	7412                	ld	s0,288(sp)
    80005e4e:	64f2                	ld	s1,280(sp)
    80005e50:	6952                	ld	s2,272(sp)
    80005e52:	6155                	addi	sp,sp,304
    80005e54:	8082                	ret

0000000080005e56 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e56:	4578                	lw	a4,76(a0)
    80005e58:	02000793          	li	a5,32
    80005e5c:	04e7fa63          	bgeu	a5,a4,80005eb0 <isdirempty+0x5a>
{
    80005e60:	7179                	addi	sp,sp,-48
    80005e62:	f406                	sd	ra,40(sp)
    80005e64:	f022                	sd	s0,32(sp)
    80005e66:	ec26                	sd	s1,24(sp)
    80005e68:	e84a                	sd	s2,16(sp)
    80005e6a:	1800                	addi	s0,sp,48
    80005e6c:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e6e:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e72:	4741                	li	a4,16
    80005e74:	86a6                	mv	a3,s1
    80005e76:	fd040613          	addi	a2,s0,-48
    80005e7a:	4581                	li	a1,0
    80005e7c:	854a                	mv	a0,s2
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	0dc080e7          	jalr	220(ra) # 80003f5a <readi>
    80005e86:	47c1                	li	a5,16
    80005e88:	00f51c63          	bne	a0,a5,80005ea0 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005e8c:	fd045783          	lhu	a5,-48(s0)
    80005e90:	e395                	bnez	a5,80005eb4 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e92:	24c1                	addiw	s1,s1,16
    80005e94:	04c92783          	lw	a5,76(s2)
    80005e98:	fcf4ede3          	bltu	s1,a5,80005e72 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005e9c:	4505                	li	a0,1
    80005e9e:	a821                	j	80005eb6 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005ea0:	00003517          	auipc	a0,0x3
    80005ea4:	8d850513          	addi	a0,a0,-1832 # 80008778 <syscalls+0x310>
    80005ea8:	ffffa097          	auipc	ra,0xffffa
    80005eac:	682080e7          	jalr	1666(ra) # 8000052a <panic>
  return 1;
    80005eb0:	4505                	li	a0,1
}
    80005eb2:	8082                	ret
      return 0;
    80005eb4:	4501                	li	a0,0
}
    80005eb6:	70a2                	ld	ra,40(sp)
    80005eb8:	7402                	ld	s0,32(sp)
    80005eba:	64e2                	ld	s1,24(sp)
    80005ebc:	6942                	ld	s2,16(sp)
    80005ebe:	6145                	addi	sp,sp,48
    80005ec0:	8082                	ret

0000000080005ec2 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005ec2:	7155                	addi	sp,sp,-208
    80005ec4:	e586                	sd	ra,200(sp)
    80005ec6:	e1a2                	sd	s0,192(sp)
    80005ec8:	fd26                	sd	s1,184(sp)
    80005eca:	f94a                	sd	s2,176(sp)
    80005ecc:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005ece:	08000613          	li	a2,128
    80005ed2:	f4040593          	addi	a1,s0,-192
    80005ed6:	4501                	li	a0,0
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	2a0080e7          	jalr	672(ra) # 80003178 <argstr>
    80005ee0:	16054363          	bltz	a0,80006046 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	aaa080e7          	jalr	-1366(ra) # 8000498e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005eec:	fc040593          	addi	a1,s0,-64
    80005ef0:	f4040513          	addi	a0,s0,-192
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	586080e7          	jalr	1414(ra) # 8000447a <nameiparent>
    80005efc:	84aa                	mv	s1,a0
    80005efe:	c961                	beqz	a0,80005fce <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	da6080e7          	jalr	-602(ra) # 80003ca6 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f08:	00002597          	auipc	a1,0x2
    80005f0c:	75058593          	addi	a1,a1,1872 # 80008658 <syscalls+0x1f0>
    80005f10:	fc040513          	addi	a0,s0,-64
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	25c080e7          	jalr	604(ra) # 80004170 <namecmp>
    80005f1c:	c175                	beqz	a0,80006000 <sys_unlink+0x13e>
    80005f1e:	00002597          	auipc	a1,0x2
    80005f22:	74258593          	addi	a1,a1,1858 # 80008660 <syscalls+0x1f8>
    80005f26:	fc040513          	addi	a0,s0,-64
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	246080e7          	jalr	582(ra) # 80004170 <namecmp>
    80005f32:	c579                	beqz	a0,80006000 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f34:	f3c40613          	addi	a2,s0,-196
    80005f38:	fc040593          	addi	a1,s0,-64
    80005f3c:	8526                	mv	a0,s1
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	24c080e7          	jalr	588(ra) # 8000418a <dirlookup>
    80005f46:	892a                	mv	s2,a0
    80005f48:	cd45                	beqz	a0,80006000 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	d5c080e7          	jalr	-676(ra) # 80003ca6 <ilock>

  if(ip->nlink < 1)
    80005f52:	04a91783          	lh	a5,74(s2)
    80005f56:	08f05263          	blez	a5,80005fda <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f5a:	04491703          	lh	a4,68(s2)
    80005f5e:	4785                	li	a5,1
    80005f60:	08f70563          	beq	a4,a5,80005fea <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005f64:	4641                	li	a2,16
    80005f66:	4581                	li	a1,0
    80005f68:	fd040513          	addi	a0,s0,-48
    80005f6c:	ffffb097          	auipc	ra,0xffffb
    80005f70:	d52080e7          	jalr	-686(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f74:	4741                	li	a4,16
    80005f76:	f3c42683          	lw	a3,-196(s0)
    80005f7a:	fd040613          	addi	a2,s0,-48
    80005f7e:	4581                	li	a1,0
    80005f80:	8526                	mv	a0,s1
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	0d0080e7          	jalr	208(ra) # 80004052 <writei>
    80005f8a:	47c1                	li	a5,16
    80005f8c:	08f51a63          	bne	a0,a5,80006020 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005f90:	04491703          	lh	a4,68(s2)
    80005f94:	4785                	li	a5,1
    80005f96:	08f70d63          	beq	a4,a5,80006030 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	f6c080e7          	jalr	-148(ra) # 80003f08 <iunlockput>

  ip->nlink--;
    80005fa4:	04a95783          	lhu	a5,74(s2)
    80005fa8:	37fd                	addiw	a5,a5,-1
    80005faa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fae:	854a                	mv	a0,s2
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	c2c080e7          	jalr	-980(ra) # 80003bdc <iupdate>
  iunlockput(ip);
    80005fb8:	854a                	mv	a0,s2
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	f4e080e7          	jalr	-178(ra) # 80003f08 <iunlockput>

  end_op();
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	a4c080e7          	jalr	-1460(ra) # 80004a0e <end_op>

  return 0;
    80005fca:	4501                	li	a0,0
    80005fcc:	a0a1                	j	80006014 <sys_unlink+0x152>
    end_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	a40080e7          	jalr	-1472(ra) # 80004a0e <end_op>
    return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	a835                	j	80006014 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005fda:	00002517          	auipc	a0,0x2
    80005fde:	68e50513          	addi	a0,a0,1678 # 80008668 <syscalls+0x200>
    80005fe2:	ffffa097          	auipc	ra,0xffffa
    80005fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005fea:	854a                	mv	a0,s2
    80005fec:	00000097          	auipc	ra,0x0
    80005ff0:	e6a080e7          	jalr	-406(ra) # 80005e56 <isdirempty>
    80005ff4:	f925                	bnez	a0,80005f64 <sys_unlink+0xa2>
    iunlockput(ip);
    80005ff6:	854a                	mv	a0,s2
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	f10080e7          	jalr	-240(ra) # 80003f08 <iunlockput>

bad:
  iunlockput(dp);
    80006000:	8526                	mv	a0,s1
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	f06080e7          	jalr	-250(ra) # 80003f08 <iunlockput>
  end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	a04080e7          	jalr	-1532(ra) # 80004a0e <end_op>
  return -1;
    80006012:	557d                	li	a0,-1
}
    80006014:	60ae                	ld	ra,200(sp)
    80006016:	640e                	ld	s0,192(sp)
    80006018:	74ea                	ld	s1,184(sp)
    8000601a:	794a                	ld	s2,176(sp)
    8000601c:	6169                	addi	sp,sp,208
    8000601e:	8082                	ret
    panic("unlink: writei");
    80006020:	00002517          	auipc	a0,0x2
    80006024:	66050513          	addi	a0,a0,1632 # 80008680 <syscalls+0x218>
    80006028:	ffffa097          	auipc	ra,0xffffa
    8000602c:	502080e7          	jalr	1282(ra) # 8000052a <panic>
    dp->nlink--;
    80006030:	04a4d783          	lhu	a5,74(s1)
    80006034:	37fd                	addiw	a5,a5,-1
    80006036:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000603a:	8526                	mv	a0,s1
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	ba0080e7          	jalr	-1120(ra) # 80003bdc <iupdate>
    80006044:	bf99                	j	80005f9a <sys_unlink+0xd8>
    return -1;
    80006046:	557d                	li	a0,-1
    80006048:	b7f1                	j	80006014 <sys_unlink+0x152>

000000008000604a <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000604a:	715d                	addi	sp,sp,-80
    8000604c:	e486                	sd	ra,72(sp)
    8000604e:	e0a2                	sd	s0,64(sp)
    80006050:	fc26                	sd	s1,56(sp)
    80006052:	f84a                	sd	s2,48(sp)
    80006054:	f44e                	sd	s3,40(sp)
    80006056:	f052                	sd	s4,32(sp)
    80006058:	ec56                	sd	s5,24(sp)
    8000605a:	0880                	addi	s0,sp,80
    8000605c:	89ae                	mv	s3,a1
    8000605e:	8ab2                	mv	s5,a2
    80006060:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006062:	fb040593          	addi	a1,s0,-80
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	414080e7          	jalr	1044(ra) # 8000447a <nameiparent>
    8000606e:	892a                	mv	s2,a0
    80006070:	12050e63          	beqz	a0,800061ac <create+0x162>
    return 0;

  ilock(dp);
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	c32080e7          	jalr	-974(ra) # 80003ca6 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000607c:	4601                	li	a2,0
    8000607e:	fb040593          	addi	a1,s0,-80
    80006082:	854a                	mv	a0,s2
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	106080e7          	jalr	262(ra) # 8000418a <dirlookup>
    8000608c:	84aa                	mv	s1,a0
    8000608e:	c921                	beqz	a0,800060de <create+0x94>
    iunlockput(dp);
    80006090:	854a                	mv	a0,s2
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	e76080e7          	jalr	-394(ra) # 80003f08 <iunlockput>
    ilock(ip);
    8000609a:	8526                	mv	a0,s1
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	c0a080e7          	jalr	-1014(ra) # 80003ca6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800060a4:	2981                	sext.w	s3,s3
    800060a6:	4789                	li	a5,2
    800060a8:	02f99463          	bne	s3,a5,800060d0 <create+0x86>
    800060ac:	0444d783          	lhu	a5,68(s1)
    800060b0:	37f9                	addiw	a5,a5,-2
    800060b2:	17c2                	slli	a5,a5,0x30
    800060b4:	93c1                	srli	a5,a5,0x30
    800060b6:	4705                	li	a4,1
    800060b8:	00f76c63          	bltu	a4,a5,800060d0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800060bc:	8526                	mv	a0,s1
    800060be:	60a6                	ld	ra,72(sp)
    800060c0:	6406                	ld	s0,64(sp)
    800060c2:	74e2                	ld	s1,56(sp)
    800060c4:	7942                	ld	s2,48(sp)
    800060c6:	79a2                	ld	s3,40(sp)
    800060c8:	7a02                	ld	s4,32(sp)
    800060ca:	6ae2                	ld	s5,24(sp)
    800060cc:	6161                	addi	sp,sp,80
    800060ce:	8082                	ret
    iunlockput(ip);
    800060d0:	8526                	mv	a0,s1
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	e36080e7          	jalr	-458(ra) # 80003f08 <iunlockput>
    return 0;
    800060da:	4481                	li	s1,0
    800060dc:	b7c5                	j	800060bc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800060de:	85ce                	mv	a1,s3
    800060e0:	00092503          	lw	a0,0(s2)
    800060e4:	ffffe097          	auipc	ra,0xffffe
    800060e8:	a2a080e7          	jalr	-1494(ra) # 80003b0e <ialloc>
    800060ec:	84aa                	mv	s1,a0
    800060ee:	c521                	beqz	a0,80006136 <create+0xec>
  ilock(ip);
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	bb6080e7          	jalr	-1098(ra) # 80003ca6 <ilock>
  ip->major = major;
    800060f8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800060fc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006100:	4a05                	li	s4,1
    80006102:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	ad4080e7          	jalr	-1324(ra) # 80003bdc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006110:	2981                	sext.w	s3,s3
    80006112:	03498a63          	beq	s3,s4,80006146 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006116:	40d0                	lw	a2,4(s1)
    80006118:	fb040593          	addi	a1,s0,-80
    8000611c:	854a                	mv	a0,s2
    8000611e:	ffffe097          	auipc	ra,0xffffe
    80006122:	27c080e7          	jalr	636(ra) # 8000439a <dirlink>
    80006126:	06054b63          	bltz	a0,8000619c <create+0x152>
  iunlockput(dp);
    8000612a:	854a                	mv	a0,s2
    8000612c:	ffffe097          	auipc	ra,0xffffe
    80006130:	ddc080e7          	jalr	-548(ra) # 80003f08 <iunlockput>
  return ip;
    80006134:	b761                	j	800060bc <create+0x72>
    panic("create: ialloc");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	65a50513          	addi	a0,a0,1626 # 80008790 <syscalls+0x328>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	3ec080e7          	jalr	1004(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006146:	04a95783          	lhu	a5,74(s2)
    8000614a:	2785                	addiw	a5,a5,1
    8000614c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006150:	854a                	mv	a0,s2
    80006152:	ffffe097          	auipc	ra,0xffffe
    80006156:	a8a080e7          	jalr	-1398(ra) # 80003bdc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000615a:	40d0                	lw	a2,4(s1)
    8000615c:	00002597          	auipc	a1,0x2
    80006160:	4fc58593          	addi	a1,a1,1276 # 80008658 <syscalls+0x1f0>
    80006164:	8526                	mv	a0,s1
    80006166:	ffffe097          	auipc	ra,0xffffe
    8000616a:	234080e7          	jalr	564(ra) # 8000439a <dirlink>
    8000616e:	00054f63          	bltz	a0,8000618c <create+0x142>
    80006172:	00492603          	lw	a2,4(s2)
    80006176:	00002597          	auipc	a1,0x2
    8000617a:	4ea58593          	addi	a1,a1,1258 # 80008660 <syscalls+0x1f8>
    8000617e:	8526                	mv	a0,s1
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	21a080e7          	jalr	538(ra) # 8000439a <dirlink>
    80006188:	f80557e3          	bgez	a0,80006116 <create+0xcc>
      panic("create dots");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	61450513          	addi	a0,a0,1556 # 800087a0 <syscalls+0x338>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	396080e7          	jalr	918(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000619c:	00002517          	auipc	a0,0x2
    800061a0:	61450513          	addi	a0,a0,1556 # 800087b0 <syscalls+0x348>
    800061a4:	ffffa097          	auipc	ra,0xffffa
    800061a8:	386080e7          	jalr	902(ra) # 8000052a <panic>
    return 0;
    800061ac:	84aa                	mv	s1,a0
    800061ae:	b739                	j	800060bc <create+0x72>

00000000800061b0 <sys_open>:

uint64
sys_open(void)
{
    800061b0:	7131                	addi	sp,sp,-192
    800061b2:	fd06                	sd	ra,184(sp)
    800061b4:	f922                	sd	s0,176(sp)
    800061b6:	f526                	sd	s1,168(sp)
    800061b8:	f14a                	sd	s2,160(sp)
    800061ba:	ed4e                	sd	s3,152(sp)
    800061bc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061be:	08000613          	li	a2,128
    800061c2:	f5040593          	addi	a1,s0,-176
    800061c6:	4501                	li	a0,0
    800061c8:	ffffd097          	auipc	ra,0xffffd
    800061cc:	fb0080e7          	jalr	-80(ra) # 80003178 <argstr>
    return -1;
    800061d0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061d2:	0c054163          	bltz	a0,80006294 <sys_open+0xe4>
    800061d6:	f4c40593          	addi	a1,s0,-180
    800061da:	4505                	li	a0,1
    800061dc:	ffffd097          	auipc	ra,0xffffd
    800061e0:	f58080e7          	jalr	-168(ra) # 80003134 <argint>
    800061e4:	0a054863          	bltz	a0,80006294 <sys_open+0xe4>

  begin_op();
    800061e8:	ffffe097          	auipc	ra,0xffffe
    800061ec:	7a6080e7          	jalr	1958(ra) # 8000498e <begin_op>

  if(omode & O_CREATE){
    800061f0:	f4c42783          	lw	a5,-180(s0)
    800061f4:	2007f793          	andi	a5,a5,512
    800061f8:	cbdd                	beqz	a5,800062ae <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800061fa:	4681                	li	a3,0
    800061fc:	4601                	li	a2,0
    800061fe:	4589                	li	a1,2
    80006200:	f5040513          	addi	a0,s0,-176
    80006204:	00000097          	auipc	ra,0x0
    80006208:	e46080e7          	jalr	-442(ra) # 8000604a <create>
    8000620c:	892a                	mv	s2,a0
    if(ip == 0){
    8000620e:	c959                	beqz	a0,800062a4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006210:	04491703          	lh	a4,68(s2)
    80006214:	478d                	li	a5,3
    80006216:	00f71763          	bne	a4,a5,80006224 <sys_open+0x74>
    8000621a:	04695703          	lhu	a4,70(s2)
    8000621e:	47a5                	li	a5,9
    80006220:	0ce7ec63          	bltu	a5,a4,800062f8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	b7a080e7          	jalr	-1158(ra) # 80004d9e <filealloc>
    8000622c:	89aa                	mv	s3,a0
    8000622e:	10050263          	beqz	a0,80006332 <sys_open+0x182>
    80006232:	00000097          	auipc	ra,0x0
    80006236:	8e2080e7          	jalr	-1822(ra) # 80005b14 <fdalloc>
    8000623a:	84aa                	mv	s1,a0
    8000623c:	0e054663          	bltz	a0,80006328 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006240:	04491703          	lh	a4,68(s2)
    80006244:	478d                	li	a5,3
    80006246:	0cf70463          	beq	a4,a5,8000630e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000624a:	4789                	li	a5,2
    8000624c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006250:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006254:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006258:	f4c42783          	lw	a5,-180(s0)
    8000625c:	0017c713          	xori	a4,a5,1
    80006260:	8b05                	andi	a4,a4,1
    80006262:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006266:	0037f713          	andi	a4,a5,3
    8000626a:	00e03733          	snez	a4,a4
    8000626e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006272:	4007f793          	andi	a5,a5,1024
    80006276:	c791                	beqz	a5,80006282 <sys_open+0xd2>
    80006278:	04491703          	lh	a4,68(s2)
    8000627c:	4789                	li	a5,2
    8000627e:	08f70f63          	beq	a4,a5,8000631c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006282:	854a                	mv	a0,s2
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	ae4080e7          	jalr	-1308(ra) # 80003d68 <iunlock>
  end_op();
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	782080e7          	jalr	1922(ra) # 80004a0e <end_op>

  return fd;
}
    80006294:	8526                	mv	a0,s1
    80006296:	70ea                	ld	ra,184(sp)
    80006298:	744a                	ld	s0,176(sp)
    8000629a:	74aa                	ld	s1,168(sp)
    8000629c:	790a                	ld	s2,160(sp)
    8000629e:	69ea                	ld	s3,152(sp)
    800062a0:	6129                	addi	sp,sp,192
    800062a2:	8082                	ret
      end_op();
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	76a080e7          	jalr	1898(ra) # 80004a0e <end_op>
      return -1;
    800062ac:	b7e5                	j	80006294 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800062ae:	f5040513          	addi	a0,s0,-176
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	1aa080e7          	jalr	426(ra) # 8000445c <namei>
    800062ba:	892a                	mv	s2,a0
    800062bc:	c905                	beqz	a0,800062ec <sys_open+0x13c>
    ilock(ip);
    800062be:	ffffe097          	auipc	ra,0xffffe
    800062c2:	9e8080e7          	jalr	-1560(ra) # 80003ca6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062c6:	04491703          	lh	a4,68(s2)
    800062ca:	4785                	li	a5,1
    800062cc:	f4f712e3          	bne	a4,a5,80006210 <sys_open+0x60>
    800062d0:	f4c42783          	lw	a5,-180(s0)
    800062d4:	dba1                	beqz	a5,80006224 <sys_open+0x74>
      iunlockput(ip);
    800062d6:	854a                	mv	a0,s2
    800062d8:	ffffe097          	auipc	ra,0xffffe
    800062dc:	c30080e7          	jalr	-976(ra) # 80003f08 <iunlockput>
      end_op();
    800062e0:	ffffe097          	auipc	ra,0xffffe
    800062e4:	72e080e7          	jalr	1838(ra) # 80004a0e <end_op>
      return -1;
    800062e8:	54fd                	li	s1,-1
    800062ea:	b76d                	j	80006294 <sys_open+0xe4>
      end_op();
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	722080e7          	jalr	1826(ra) # 80004a0e <end_op>
      return -1;
    800062f4:	54fd                	li	s1,-1
    800062f6:	bf79                	j	80006294 <sys_open+0xe4>
    iunlockput(ip);
    800062f8:	854a                	mv	a0,s2
    800062fa:	ffffe097          	auipc	ra,0xffffe
    800062fe:	c0e080e7          	jalr	-1010(ra) # 80003f08 <iunlockput>
    end_op();
    80006302:	ffffe097          	auipc	ra,0xffffe
    80006306:	70c080e7          	jalr	1804(ra) # 80004a0e <end_op>
    return -1;
    8000630a:	54fd                	li	s1,-1
    8000630c:	b761                	j	80006294 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000630e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006312:	04691783          	lh	a5,70(s2)
    80006316:	02f99223          	sh	a5,36(s3)
    8000631a:	bf2d                	j	80006254 <sys_open+0xa4>
    itrunc(ip);
    8000631c:	854a                	mv	a0,s2
    8000631e:	ffffe097          	auipc	ra,0xffffe
    80006322:	a96080e7          	jalr	-1386(ra) # 80003db4 <itrunc>
    80006326:	bfb1                	j	80006282 <sys_open+0xd2>
      fileclose(f);
    80006328:	854e                	mv	a0,s3
    8000632a:	fffff097          	auipc	ra,0xfffff
    8000632e:	b30080e7          	jalr	-1232(ra) # 80004e5a <fileclose>
    iunlockput(ip);
    80006332:	854a                	mv	a0,s2
    80006334:	ffffe097          	auipc	ra,0xffffe
    80006338:	bd4080e7          	jalr	-1068(ra) # 80003f08 <iunlockput>
    end_op();
    8000633c:	ffffe097          	auipc	ra,0xffffe
    80006340:	6d2080e7          	jalr	1746(ra) # 80004a0e <end_op>
    return -1;
    80006344:	54fd                	li	s1,-1
    80006346:	b7b9                	j	80006294 <sys_open+0xe4>

0000000080006348 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006348:	7175                	addi	sp,sp,-144
    8000634a:	e506                	sd	ra,136(sp)
    8000634c:	e122                	sd	s0,128(sp)
    8000634e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006350:	ffffe097          	auipc	ra,0xffffe
    80006354:	63e080e7          	jalr	1598(ra) # 8000498e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006358:	08000613          	li	a2,128
    8000635c:	f7040593          	addi	a1,s0,-144
    80006360:	4501                	li	a0,0
    80006362:	ffffd097          	auipc	ra,0xffffd
    80006366:	e16080e7          	jalr	-490(ra) # 80003178 <argstr>
    8000636a:	02054963          	bltz	a0,8000639c <sys_mkdir+0x54>
    8000636e:	4681                	li	a3,0
    80006370:	4601                	li	a2,0
    80006372:	4585                	li	a1,1
    80006374:	f7040513          	addi	a0,s0,-144
    80006378:	00000097          	auipc	ra,0x0
    8000637c:	cd2080e7          	jalr	-814(ra) # 8000604a <create>
    80006380:	cd11                	beqz	a0,8000639c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006382:	ffffe097          	auipc	ra,0xffffe
    80006386:	b86080e7          	jalr	-1146(ra) # 80003f08 <iunlockput>
  end_op();
    8000638a:	ffffe097          	auipc	ra,0xffffe
    8000638e:	684080e7          	jalr	1668(ra) # 80004a0e <end_op>
  return 0;
    80006392:	4501                	li	a0,0
}
    80006394:	60aa                	ld	ra,136(sp)
    80006396:	640a                	ld	s0,128(sp)
    80006398:	6149                	addi	sp,sp,144
    8000639a:	8082                	ret
    end_op();
    8000639c:	ffffe097          	auipc	ra,0xffffe
    800063a0:	672080e7          	jalr	1650(ra) # 80004a0e <end_op>
    return -1;
    800063a4:	557d                	li	a0,-1
    800063a6:	b7fd                	j	80006394 <sys_mkdir+0x4c>

00000000800063a8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800063a8:	7135                	addi	sp,sp,-160
    800063aa:	ed06                	sd	ra,152(sp)
    800063ac:	e922                	sd	s0,144(sp)
    800063ae:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	5de080e7          	jalr	1502(ra) # 8000498e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063b8:	08000613          	li	a2,128
    800063bc:	f7040593          	addi	a1,s0,-144
    800063c0:	4501                	li	a0,0
    800063c2:	ffffd097          	auipc	ra,0xffffd
    800063c6:	db6080e7          	jalr	-586(ra) # 80003178 <argstr>
    800063ca:	04054a63          	bltz	a0,8000641e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800063ce:	f6c40593          	addi	a1,s0,-148
    800063d2:	4505                	li	a0,1
    800063d4:	ffffd097          	auipc	ra,0xffffd
    800063d8:	d60080e7          	jalr	-672(ra) # 80003134 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063dc:	04054163          	bltz	a0,8000641e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800063e0:	f6840593          	addi	a1,s0,-152
    800063e4:	4509                	li	a0,2
    800063e6:	ffffd097          	auipc	ra,0xffffd
    800063ea:	d4e080e7          	jalr	-690(ra) # 80003134 <argint>
     argint(1, &major) < 0 ||
    800063ee:	02054863          	bltz	a0,8000641e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800063f2:	f6841683          	lh	a3,-152(s0)
    800063f6:	f6c41603          	lh	a2,-148(s0)
    800063fa:	458d                	li	a1,3
    800063fc:	f7040513          	addi	a0,s0,-144
    80006400:	00000097          	auipc	ra,0x0
    80006404:	c4a080e7          	jalr	-950(ra) # 8000604a <create>
     argint(2, &minor) < 0 ||
    80006408:	c919                	beqz	a0,8000641e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000640a:	ffffe097          	auipc	ra,0xffffe
    8000640e:	afe080e7          	jalr	-1282(ra) # 80003f08 <iunlockput>
  end_op();
    80006412:	ffffe097          	auipc	ra,0xffffe
    80006416:	5fc080e7          	jalr	1532(ra) # 80004a0e <end_op>
  return 0;
    8000641a:	4501                	li	a0,0
    8000641c:	a031                	j	80006428 <sys_mknod+0x80>
    end_op();
    8000641e:	ffffe097          	auipc	ra,0xffffe
    80006422:	5f0080e7          	jalr	1520(ra) # 80004a0e <end_op>
    return -1;
    80006426:	557d                	li	a0,-1
}
    80006428:	60ea                	ld	ra,152(sp)
    8000642a:	644a                	ld	s0,144(sp)
    8000642c:	610d                	addi	sp,sp,160
    8000642e:	8082                	ret

0000000080006430 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006430:	7135                	addi	sp,sp,-160
    80006432:	ed06                	sd	ra,152(sp)
    80006434:	e922                	sd	s0,144(sp)
    80006436:	e526                	sd	s1,136(sp)
    80006438:	e14a                	sd	s2,128(sp)
    8000643a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000643c:	ffffc097          	auipc	ra,0xffffc
    80006440:	b0e080e7          	jalr	-1266(ra) # 80001f4a <myproc>
    80006444:	892a                	mv	s2,a0
  
  begin_op();
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	548080e7          	jalr	1352(ra) # 8000498e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000644e:	08000613          	li	a2,128
    80006452:	f6040593          	addi	a1,s0,-160
    80006456:	4501                	li	a0,0
    80006458:	ffffd097          	auipc	ra,0xffffd
    8000645c:	d20080e7          	jalr	-736(ra) # 80003178 <argstr>
    80006460:	04054b63          	bltz	a0,800064b6 <sys_chdir+0x86>
    80006464:	f6040513          	addi	a0,s0,-160
    80006468:	ffffe097          	auipc	ra,0xffffe
    8000646c:	ff4080e7          	jalr	-12(ra) # 8000445c <namei>
    80006470:	84aa                	mv	s1,a0
    80006472:	c131                	beqz	a0,800064b6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006474:	ffffe097          	auipc	ra,0xffffe
    80006478:	832080e7          	jalr	-1998(ra) # 80003ca6 <ilock>
  if(ip->type != T_DIR){
    8000647c:	04449703          	lh	a4,68(s1)
    80006480:	4785                	li	a5,1
    80006482:	04f71063          	bne	a4,a5,800064c2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006486:	8526                	mv	a0,s1
    80006488:	ffffe097          	auipc	ra,0xffffe
    8000648c:	8e0080e7          	jalr	-1824(ra) # 80003d68 <iunlock>
  iput(p->cwd);
    80006490:	15093503          	ld	a0,336(s2)
    80006494:	ffffe097          	auipc	ra,0xffffe
    80006498:	9cc080e7          	jalr	-1588(ra) # 80003e60 <iput>
  end_op();
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	572080e7          	jalr	1394(ra) # 80004a0e <end_op>
  p->cwd = ip;
    800064a4:	14993823          	sd	s1,336(s2)
  return 0;
    800064a8:	4501                	li	a0,0
}
    800064aa:	60ea                	ld	ra,152(sp)
    800064ac:	644a                	ld	s0,144(sp)
    800064ae:	64aa                	ld	s1,136(sp)
    800064b0:	690a                	ld	s2,128(sp)
    800064b2:	610d                	addi	sp,sp,160
    800064b4:	8082                	ret
    end_op();
    800064b6:	ffffe097          	auipc	ra,0xffffe
    800064ba:	558080e7          	jalr	1368(ra) # 80004a0e <end_op>
    return -1;
    800064be:	557d                	li	a0,-1
    800064c0:	b7ed                	j	800064aa <sys_chdir+0x7a>
    iunlockput(ip);
    800064c2:	8526                	mv	a0,s1
    800064c4:	ffffe097          	auipc	ra,0xffffe
    800064c8:	a44080e7          	jalr	-1468(ra) # 80003f08 <iunlockput>
    end_op();
    800064cc:	ffffe097          	auipc	ra,0xffffe
    800064d0:	542080e7          	jalr	1346(ra) # 80004a0e <end_op>
    return -1;
    800064d4:	557d                	li	a0,-1
    800064d6:	bfd1                	j	800064aa <sys_chdir+0x7a>

00000000800064d8 <sys_exec>:

uint64
sys_exec(void)
{
    800064d8:	7145                	addi	sp,sp,-464
    800064da:	e786                	sd	ra,456(sp)
    800064dc:	e3a2                	sd	s0,448(sp)
    800064de:	ff26                	sd	s1,440(sp)
    800064e0:	fb4a                	sd	s2,432(sp)
    800064e2:	f74e                	sd	s3,424(sp)
    800064e4:	f352                	sd	s4,416(sp)
    800064e6:	ef56                	sd	s5,408(sp)
    800064e8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800064ea:	08000613          	li	a2,128
    800064ee:	f4040593          	addi	a1,s0,-192
    800064f2:	4501                	li	a0,0
    800064f4:	ffffd097          	auipc	ra,0xffffd
    800064f8:	c84080e7          	jalr	-892(ra) # 80003178 <argstr>
    return -1;
    800064fc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800064fe:	0c054a63          	bltz	a0,800065d2 <sys_exec+0xfa>
    80006502:	e3840593          	addi	a1,s0,-456
    80006506:	4505                	li	a0,1
    80006508:	ffffd097          	auipc	ra,0xffffd
    8000650c:	c4e080e7          	jalr	-946(ra) # 80003156 <argaddr>
    80006510:	0c054163          	bltz	a0,800065d2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006514:	10000613          	li	a2,256
    80006518:	4581                	li	a1,0
    8000651a:	e4040513          	addi	a0,s0,-448
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	7a0080e7          	jalr	1952(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006526:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000652a:	89a6                	mv	s3,s1
    8000652c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000652e:	02000a13          	li	s4,32
    80006532:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006536:	00391793          	slli	a5,s2,0x3
    8000653a:	e3040593          	addi	a1,s0,-464
    8000653e:	e3843503          	ld	a0,-456(s0)
    80006542:	953e                	add	a0,a0,a5
    80006544:	ffffd097          	auipc	ra,0xffffd
    80006548:	b56080e7          	jalr	-1194(ra) # 8000309a <fetchaddr>
    8000654c:	02054a63          	bltz	a0,80006580 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006550:	e3043783          	ld	a5,-464(s0)
    80006554:	c3b9                	beqz	a5,8000659a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006556:	ffffa097          	auipc	ra,0xffffa
    8000655a:	57c080e7          	jalr	1404(ra) # 80000ad2 <kalloc>
    8000655e:	85aa                	mv	a1,a0
    80006560:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006564:	cd11                	beqz	a0,80006580 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006566:	6605                	lui	a2,0x1
    80006568:	e3043503          	ld	a0,-464(s0)
    8000656c:	ffffd097          	auipc	ra,0xffffd
    80006570:	b80080e7          	jalr	-1152(ra) # 800030ec <fetchstr>
    80006574:	00054663          	bltz	a0,80006580 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006578:	0905                	addi	s2,s2,1
    8000657a:	09a1                	addi	s3,s3,8
    8000657c:	fb491be3          	bne	s2,s4,80006532 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006580:	10048913          	addi	s2,s1,256
    80006584:	6088                	ld	a0,0(s1)
    80006586:	c529                	beqz	a0,800065d0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006588:	ffffa097          	auipc	ra,0xffffa
    8000658c:	44e080e7          	jalr	1102(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006590:	04a1                	addi	s1,s1,8
    80006592:	ff2499e3          	bne	s1,s2,80006584 <sys_exec+0xac>
  return -1;
    80006596:	597d                	li	s2,-1
    80006598:	a82d                	j	800065d2 <sys_exec+0xfa>
      argv[i] = 0;
    8000659a:	0a8e                	slli	s5,s5,0x3
    8000659c:	fc040793          	addi	a5,s0,-64
    800065a0:	9abe                	add	s5,s5,a5
    800065a2:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffc8e80>
  int ret = exec(path, argv);
    800065a6:	e4040593          	addi	a1,s0,-448
    800065aa:	f4040513          	addi	a0,s0,-192
    800065ae:	fffff097          	auipc	ra,0xfffff
    800065b2:	0f4080e7          	jalr	244(ra) # 800056a2 <exec>
    800065b6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065b8:	10048993          	addi	s3,s1,256
    800065bc:	6088                	ld	a0,0(s1)
    800065be:	c911                	beqz	a0,800065d2 <sys_exec+0xfa>
    kfree(argv[i]);
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	416080e7          	jalr	1046(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065c8:	04a1                	addi	s1,s1,8
    800065ca:	ff3499e3          	bne	s1,s3,800065bc <sys_exec+0xe4>
    800065ce:	a011                	j	800065d2 <sys_exec+0xfa>
  return -1;
    800065d0:	597d                	li	s2,-1
}
    800065d2:	854a                	mv	a0,s2
    800065d4:	60be                	ld	ra,456(sp)
    800065d6:	641e                	ld	s0,448(sp)
    800065d8:	74fa                	ld	s1,440(sp)
    800065da:	795a                	ld	s2,432(sp)
    800065dc:	79ba                	ld	s3,424(sp)
    800065de:	7a1a                	ld	s4,416(sp)
    800065e0:	6afa                	ld	s5,408(sp)
    800065e2:	6179                	addi	sp,sp,464
    800065e4:	8082                	ret

00000000800065e6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800065e6:	7139                	addi	sp,sp,-64
    800065e8:	fc06                	sd	ra,56(sp)
    800065ea:	f822                	sd	s0,48(sp)
    800065ec:	f426                	sd	s1,40(sp)
    800065ee:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800065f0:	ffffc097          	auipc	ra,0xffffc
    800065f4:	95a080e7          	jalr	-1702(ra) # 80001f4a <myproc>
    800065f8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800065fa:	fd840593          	addi	a1,s0,-40
    800065fe:	4501                	li	a0,0
    80006600:	ffffd097          	auipc	ra,0xffffd
    80006604:	b56080e7          	jalr	-1194(ra) # 80003156 <argaddr>
    return -1;
    80006608:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000660a:	0e054063          	bltz	a0,800066ea <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000660e:	fc840593          	addi	a1,s0,-56
    80006612:	fd040513          	addi	a0,s0,-48
    80006616:	fffff097          	auipc	ra,0xfffff
    8000661a:	d6a080e7          	jalr	-662(ra) # 80005380 <pipealloc>
    return -1;
    8000661e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006620:	0c054563          	bltz	a0,800066ea <sys_pipe+0x104>
  fd0 = -1;
    80006624:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006628:	fd043503          	ld	a0,-48(s0)
    8000662c:	fffff097          	auipc	ra,0xfffff
    80006630:	4e8080e7          	jalr	1256(ra) # 80005b14 <fdalloc>
    80006634:	fca42223          	sw	a0,-60(s0)
    80006638:	08054c63          	bltz	a0,800066d0 <sys_pipe+0xea>
    8000663c:	fc843503          	ld	a0,-56(s0)
    80006640:	fffff097          	auipc	ra,0xfffff
    80006644:	4d4080e7          	jalr	1236(ra) # 80005b14 <fdalloc>
    80006648:	fca42023          	sw	a0,-64(s0)
    8000664c:	06054863          	bltz	a0,800066bc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006650:	4691                	li	a3,4
    80006652:	fc440613          	addi	a2,s0,-60
    80006656:	fd843583          	ld	a1,-40(s0)
    8000665a:	68a8                	ld	a0,80(s1)
    8000665c:	ffffb097          	auipc	ra,0xffffb
    80006660:	00c080e7          	jalr	12(ra) # 80001668 <copyout>
    80006664:	02054063          	bltz	a0,80006684 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006668:	4691                	li	a3,4
    8000666a:	fc040613          	addi	a2,s0,-64
    8000666e:	fd843583          	ld	a1,-40(s0)
    80006672:	0591                	addi	a1,a1,4
    80006674:	68a8                	ld	a0,80(s1)
    80006676:	ffffb097          	auipc	ra,0xffffb
    8000667a:	ff2080e7          	jalr	-14(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000667e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006680:	06055563          	bgez	a0,800066ea <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006684:	fc442783          	lw	a5,-60(s0)
    80006688:	07e9                	addi	a5,a5,26
    8000668a:	078e                	slli	a5,a5,0x3
    8000668c:	97a6                	add	a5,a5,s1
    8000668e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006692:	fc042503          	lw	a0,-64(s0)
    80006696:	0569                	addi	a0,a0,26
    80006698:	050e                	slli	a0,a0,0x3
    8000669a:	9526                	add	a0,a0,s1
    8000669c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066a0:	fd043503          	ld	a0,-48(s0)
    800066a4:	ffffe097          	auipc	ra,0xffffe
    800066a8:	7b6080e7          	jalr	1974(ra) # 80004e5a <fileclose>
    fileclose(wf);
    800066ac:	fc843503          	ld	a0,-56(s0)
    800066b0:	ffffe097          	auipc	ra,0xffffe
    800066b4:	7aa080e7          	jalr	1962(ra) # 80004e5a <fileclose>
    return -1;
    800066b8:	57fd                	li	a5,-1
    800066ba:	a805                	j	800066ea <sys_pipe+0x104>
    if(fd0 >= 0)
    800066bc:	fc442783          	lw	a5,-60(s0)
    800066c0:	0007c863          	bltz	a5,800066d0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800066c4:	01a78513          	addi	a0,a5,26
    800066c8:	050e                	slli	a0,a0,0x3
    800066ca:	9526                	add	a0,a0,s1
    800066cc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066d0:	fd043503          	ld	a0,-48(s0)
    800066d4:	ffffe097          	auipc	ra,0xffffe
    800066d8:	786080e7          	jalr	1926(ra) # 80004e5a <fileclose>
    fileclose(wf);
    800066dc:	fc843503          	ld	a0,-56(s0)
    800066e0:	ffffe097          	auipc	ra,0xffffe
    800066e4:	77a080e7          	jalr	1914(ra) # 80004e5a <fileclose>
    return -1;
    800066e8:	57fd                	li	a5,-1
}
    800066ea:	853e                	mv	a0,a5
    800066ec:	70e2                	ld	ra,56(sp)
    800066ee:	7442                	ld	s0,48(sp)
    800066f0:	74a2                	ld	s1,40(sp)
    800066f2:	6121                	addi	sp,sp,64
    800066f4:	8082                	ret
	...

0000000080006700 <kernelvec>:
    80006700:	7111                	addi	sp,sp,-256
    80006702:	e006                	sd	ra,0(sp)
    80006704:	e40a                	sd	sp,8(sp)
    80006706:	e80e                	sd	gp,16(sp)
    80006708:	ec12                	sd	tp,24(sp)
    8000670a:	f016                	sd	t0,32(sp)
    8000670c:	f41a                	sd	t1,40(sp)
    8000670e:	f81e                	sd	t2,48(sp)
    80006710:	fc22                	sd	s0,56(sp)
    80006712:	e0a6                	sd	s1,64(sp)
    80006714:	e4aa                	sd	a0,72(sp)
    80006716:	e8ae                	sd	a1,80(sp)
    80006718:	ecb2                	sd	a2,88(sp)
    8000671a:	f0b6                	sd	a3,96(sp)
    8000671c:	f4ba                	sd	a4,104(sp)
    8000671e:	f8be                	sd	a5,112(sp)
    80006720:	fcc2                	sd	a6,120(sp)
    80006722:	e146                	sd	a7,128(sp)
    80006724:	e54a                	sd	s2,136(sp)
    80006726:	e94e                	sd	s3,144(sp)
    80006728:	ed52                	sd	s4,152(sp)
    8000672a:	f156                	sd	s5,160(sp)
    8000672c:	f55a                	sd	s6,168(sp)
    8000672e:	f95e                	sd	s7,176(sp)
    80006730:	fd62                	sd	s8,184(sp)
    80006732:	e1e6                	sd	s9,192(sp)
    80006734:	e5ea                	sd	s10,200(sp)
    80006736:	e9ee                	sd	s11,208(sp)
    80006738:	edf2                	sd	t3,216(sp)
    8000673a:	f1f6                	sd	t4,224(sp)
    8000673c:	f5fa                	sd	t5,232(sp)
    8000673e:	f9fe                	sd	t6,240(sp)
    80006740:	827fc0ef          	jal	ra,80002f66 <kerneltrap>
    80006744:	6082                	ld	ra,0(sp)
    80006746:	6122                	ld	sp,8(sp)
    80006748:	61c2                	ld	gp,16(sp)
    8000674a:	7282                	ld	t0,32(sp)
    8000674c:	7322                	ld	t1,40(sp)
    8000674e:	73c2                	ld	t2,48(sp)
    80006750:	7462                	ld	s0,56(sp)
    80006752:	6486                	ld	s1,64(sp)
    80006754:	6526                	ld	a0,72(sp)
    80006756:	65c6                	ld	a1,80(sp)
    80006758:	6666                	ld	a2,88(sp)
    8000675a:	7686                	ld	a3,96(sp)
    8000675c:	7726                	ld	a4,104(sp)
    8000675e:	77c6                	ld	a5,112(sp)
    80006760:	7866                	ld	a6,120(sp)
    80006762:	688a                	ld	a7,128(sp)
    80006764:	692a                	ld	s2,136(sp)
    80006766:	69ca                	ld	s3,144(sp)
    80006768:	6a6a                	ld	s4,152(sp)
    8000676a:	7a8a                	ld	s5,160(sp)
    8000676c:	7b2a                	ld	s6,168(sp)
    8000676e:	7bca                	ld	s7,176(sp)
    80006770:	7c6a                	ld	s8,184(sp)
    80006772:	6c8e                	ld	s9,192(sp)
    80006774:	6d2e                	ld	s10,200(sp)
    80006776:	6dce                	ld	s11,208(sp)
    80006778:	6e6e                	ld	t3,216(sp)
    8000677a:	7e8e                	ld	t4,224(sp)
    8000677c:	7f2e                	ld	t5,232(sp)
    8000677e:	7fce                	ld	t6,240(sp)
    80006780:	6111                	addi	sp,sp,256
    80006782:	10200073          	sret
    80006786:	00000013          	nop
    8000678a:	00000013          	nop
    8000678e:	0001                	nop

0000000080006790 <timervec>:
    80006790:	34051573          	csrrw	a0,mscratch,a0
    80006794:	e10c                	sd	a1,0(a0)
    80006796:	e510                	sd	a2,8(a0)
    80006798:	e914                	sd	a3,16(a0)
    8000679a:	6d0c                	ld	a1,24(a0)
    8000679c:	7110                	ld	a2,32(a0)
    8000679e:	6194                	ld	a3,0(a1)
    800067a0:	96b2                	add	a3,a3,a2
    800067a2:	e194                	sd	a3,0(a1)
    800067a4:	4589                	li	a1,2
    800067a6:	14459073          	csrw	sip,a1
    800067aa:	6914                	ld	a3,16(a0)
    800067ac:	6510                	ld	a2,8(a0)
    800067ae:	610c                	ld	a1,0(a0)
    800067b0:	34051573          	csrrw	a0,mscratch,a0
    800067b4:	30200073          	mret
	...

00000000800067ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800067ba:	1141                	addi	sp,sp,-16
    800067bc:	e422                	sd	s0,8(sp)
    800067be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800067c0:	0c0007b7          	lui	a5,0xc000
    800067c4:	4705                	li	a4,1
    800067c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800067c8:	c3d8                	sw	a4,4(a5)
}
    800067ca:	6422                	ld	s0,8(sp)
    800067cc:	0141                	addi	sp,sp,16
    800067ce:	8082                	ret

00000000800067d0 <plicinithart>:

void
plicinithart(void)
{
    800067d0:	1141                	addi	sp,sp,-16
    800067d2:	e406                	sd	ra,8(sp)
    800067d4:	e022                	sd	s0,0(sp)
    800067d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067d8:	ffffb097          	auipc	ra,0xffffb
    800067dc:	746080e7          	jalr	1862(ra) # 80001f1e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800067e0:	0085171b          	slliw	a4,a0,0x8
    800067e4:	0c0027b7          	lui	a5,0xc002
    800067e8:	97ba                	add	a5,a5,a4
    800067ea:	40200713          	li	a4,1026
    800067ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800067f2:	00d5151b          	slliw	a0,a0,0xd
    800067f6:	0c2017b7          	lui	a5,0xc201
    800067fa:	953e                	add	a0,a0,a5
    800067fc:	00052023          	sw	zero,0(a0)
}
    80006800:	60a2                	ld	ra,8(sp)
    80006802:	6402                	ld	s0,0(sp)
    80006804:	0141                	addi	sp,sp,16
    80006806:	8082                	ret

0000000080006808 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006808:	1141                	addi	sp,sp,-16
    8000680a:	e406                	sd	ra,8(sp)
    8000680c:	e022                	sd	s0,0(sp)
    8000680e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006810:	ffffb097          	auipc	ra,0xffffb
    80006814:	70e080e7          	jalr	1806(ra) # 80001f1e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006818:	00d5179b          	slliw	a5,a0,0xd
    8000681c:	0c201537          	lui	a0,0xc201
    80006820:	953e                	add	a0,a0,a5
  return irq;
}
    80006822:	4148                	lw	a0,4(a0)
    80006824:	60a2                	ld	ra,8(sp)
    80006826:	6402                	ld	s0,0(sp)
    80006828:	0141                	addi	sp,sp,16
    8000682a:	8082                	ret

000000008000682c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000682c:	1101                	addi	sp,sp,-32
    8000682e:	ec06                	sd	ra,24(sp)
    80006830:	e822                	sd	s0,16(sp)
    80006832:	e426                	sd	s1,8(sp)
    80006834:	1000                	addi	s0,sp,32
    80006836:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006838:	ffffb097          	auipc	ra,0xffffb
    8000683c:	6e6080e7          	jalr	1766(ra) # 80001f1e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006840:	00d5151b          	slliw	a0,a0,0xd
    80006844:	0c2017b7          	lui	a5,0xc201
    80006848:	97aa                	add	a5,a5,a0
    8000684a:	c3c4                	sw	s1,4(a5)
}
    8000684c:	60e2                	ld	ra,24(sp)
    8000684e:	6442                	ld	s0,16(sp)
    80006850:	64a2                	ld	s1,8(sp)
    80006852:	6105                	addi	sp,sp,32
    80006854:	8082                	ret

0000000080006856 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006856:	1141                	addi	sp,sp,-16
    80006858:	e406                	sd	ra,8(sp)
    8000685a:	e022                	sd	s0,0(sp)
    8000685c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000685e:	479d                	li	a5,7
    80006860:	06a7c963          	blt	a5,a0,800068d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006864:	0002c797          	auipc	a5,0x2c
    80006868:	79c78793          	addi	a5,a5,1948 # 80033000 <disk>
    8000686c:	00a78733          	add	a4,a5,a0
    80006870:	6789                	lui	a5,0x2
    80006872:	97ba                	add	a5,a5,a4
    80006874:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006878:	e7ad                	bnez	a5,800068e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000687a:	00451793          	slli	a5,a0,0x4
    8000687e:	0002e717          	auipc	a4,0x2e
    80006882:	78270713          	addi	a4,a4,1922 # 80035000 <disk+0x2000>
    80006886:	6314                	ld	a3,0(a4)
    80006888:	96be                	add	a3,a3,a5
    8000688a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000688e:	6314                	ld	a3,0(a4)
    80006890:	96be                	add	a3,a3,a5
    80006892:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006896:	6314                	ld	a3,0(a4)
    80006898:	96be                	add	a3,a3,a5
    8000689a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000689e:	6318                	ld	a4,0(a4)
    800068a0:	97ba                	add	a5,a5,a4
    800068a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800068a6:	0002c797          	auipc	a5,0x2c
    800068aa:	75a78793          	addi	a5,a5,1882 # 80033000 <disk>
    800068ae:	97aa                	add	a5,a5,a0
    800068b0:	6509                	lui	a0,0x2
    800068b2:	953e                	add	a0,a0,a5
    800068b4:	4785                	li	a5,1
    800068b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800068ba:	0002e517          	auipc	a0,0x2e
    800068be:	75e50513          	addi	a0,a0,1886 # 80035018 <disk+0x2018>
    800068c2:	ffffc097          	auipc	ra,0xffffc
    800068c6:	fe0080e7          	jalr	-32(ra) # 800028a2 <wakeup>
}
    800068ca:	60a2                	ld	ra,8(sp)
    800068cc:	6402                	ld	s0,0(sp)
    800068ce:	0141                	addi	sp,sp,16
    800068d0:	8082                	ret
    panic("free_desc 1");
    800068d2:	00002517          	auipc	a0,0x2
    800068d6:	eee50513          	addi	a0,a0,-274 # 800087c0 <syscalls+0x358>
    800068da:	ffffa097          	auipc	ra,0xffffa
    800068de:	c50080e7          	jalr	-944(ra) # 8000052a <panic>
    panic("free_desc 2");
    800068e2:	00002517          	auipc	a0,0x2
    800068e6:	eee50513          	addi	a0,a0,-274 # 800087d0 <syscalls+0x368>
    800068ea:	ffffa097          	auipc	ra,0xffffa
    800068ee:	c40080e7          	jalr	-960(ra) # 8000052a <panic>

00000000800068f2 <virtio_disk_init>:
{
    800068f2:	1101                	addi	sp,sp,-32
    800068f4:	ec06                	sd	ra,24(sp)
    800068f6:	e822                	sd	s0,16(sp)
    800068f8:	e426                	sd	s1,8(sp)
    800068fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800068fc:	00002597          	auipc	a1,0x2
    80006900:	ee458593          	addi	a1,a1,-284 # 800087e0 <syscalls+0x378>
    80006904:	0002f517          	auipc	a0,0x2f
    80006908:	82450513          	addi	a0,a0,-2012 # 80035128 <disk+0x2128>
    8000690c:	ffffa097          	auipc	ra,0xffffa
    80006910:	226080e7          	jalr	550(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006914:	100017b7          	lui	a5,0x10001
    80006918:	4398                	lw	a4,0(a5)
    8000691a:	2701                	sext.w	a4,a4
    8000691c:	747277b7          	lui	a5,0x74727
    80006920:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006924:	0ef71163          	bne	a4,a5,80006a06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006928:	100017b7          	lui	a5,0x10001
    8000692c:	43dc                	lw	a5,4(a5)
    8000692e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006930:	4705                	li	a4,1
    80006932:	0ce79a63          	bne	a5,a4,80006a06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006936:	100017b7          	lui	a5,0x10001
    8000693a:	479c                	lw	a5,8(a5)
    8000693c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000693e:	4709                	li	a4,2
    80006940:	0ce79363          	bne	a5,a4,80006a06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006944:	100017b7          	lui	a5,0x10001
    80006948:	47d8                	lw	a4,12(a5)
    8000694a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000694c:	554d47b7          	lui	a5,0x554d4
    80006950:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006954:	0af71963          	bne	a4,a5,80006a06 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006958:	100017b7          	lui	a5,0x10001
    8000695c:	4705                	li	a4,1
    8000695e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006960:	470d                	li	a4,3
    80006962:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006964:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006966:	c7ffe737          	lui	a4,0xc7ffe
    8000696a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc875f>
    8000696e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006970:	2701                	sext.w	a4,a4
    80006972:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006974:	472d                	li	a4,11
    80006976:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006978:	473d                	li	a4,15
    8000697a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000697c:	6705                	lui	a4,0x1
    8000697e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006980:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006984:	5bdc                	lw	a5,52(a5)
    80006986:	2781                	sext.w	a5,a5
  if(max == 0)
    80006988:	c7d9                	beqz	a5,80006a16 <virtio_disk_init+0x124>
  if(max < NUM)
    8000698a:	471d                	li	a4,7
    8000698c:	08f77d63          	bgeu	a4,a5,80006a26 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006990:	100014b7          	lui	s1,0x10001
    80006994:	47a1                	li	a5,8
    80006996:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006998:	6609                	lui	a2,0x2
    8000699a:	4581                	li	a1,0
    8000699c:	0002c517          	auipc	a0,0x2c
    800069a0:	66450513          	addi	a0,a0,1636 # 80033000 <disk>
    800069a4:	ffffa097          	auipc	ra,0xffffa
    800069a8:	31a080e7          	jalr	794(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800069ac:	0002c717          	auipc	a4,0x2c
    800069b0:	65470713          	addi	a4,a4,1620 # 80033000 <disk>
    800069b4:	00c75793          	srli	a5,a4,0xc
    800069b8:	2781                	sext.w	a5,a5
    800069ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800069bc:	0002e797          	auipc	a5,0x2e
    800069c0:	64478793          	addi	a5,a5,1604 # 80035000 <disk+0x2000>
    800069c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800069c6:	0002c717          	auipc	a4,0x2c
    800069ca:	6ba70713          	addi	a4,a4,1722 # 80033080 <disk+0x80>
    800069ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800069d0:	0002d717          	auipc	a4,0x2d
    800069d4:	63070713          	addi	a4,a4,1584 # 80034000 <disk+0x1000>
    800069d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800069da:	4705                	li	a4,1
    800069dc:	00e78c23          	sb	a4,24(a5)
    800069e0:	00e78ca3          	sb	a4,25(a5)
    800069e4:	00e78d23          	sb	a4,26(a5)
    800069e8:	00e78da3          	sb	a4,27(a5)
    800069ec:	00e78e23          	sb	a4,28(a5)
    800069f0:	00e78ea3          	sb	a4,29(a5)
    800069f4:	00e78f23          	sb	a4,30(a5)
    800069f8:	00e78fa3          	sb	a4,31(a5)
}
    800069fc:	60e2                	ld	ra,24(sp)
    800069fe:	6442                	ld	s0,16(sp)
    80006a00:	64a2                	ld	s1,8(sp)
    80006a02:	6105                	addi	sp,sp,32
    80006a04:	8082                	ret
    panic("could not find virtio disk");
    80006a06:	00002517          	auipc	a0,0x2
    80006a0a:	dea50513          	addi	a0,a0,-534 # 800087f0 <syscalls+0x388>
    80006a0e:	ffffa097          	auipc	ra,0xffffa
    80006a12:	b1c080e7          	jalr	-1252(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006a16:	00002517          	auipc	a0,0x2
    80006a1a:	dfa50513          	addi	a0,a0,-518 # 80008810 <syscalls+0x3a8>
    80006a1e:	ffffa097          	auipc	ra,0xffffa
    80006a22:	b0c080e7          	jalr	-1268(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006a26:	00002517          	auipc	a0,0x2
    80006a2a:	e0a50513          	addi	a0,a0,-502 # 80008830 <syscalls+0x3c8>
    80006a2e:	ffffa097          	auipc	ra,0xffffa
    80006a32:	afc080e7          	jalr	-1284(ra) # 8000052a <panic>

0000000080006a36 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a36:	7119                	addi	sp,sp,-128
    80006a38:	fc86                	sd	ra,120(sp)
    80006a3a:	f8a2                	sd	s0,112(sp)
    80006a3c:	f4a6                	sd	s1,104(sp)
    80006a3e:	f0ca                	sd	s2,96(sp)
    80006a40:	ecce                	sd	s3,88(sp)
    80006a42:	e8d2                	sd	s4,80(sp)
    80006a44:	e4d6                	sd	s5,72(sp)
    80006a46:	e0da                	sd	s6,64(sp)
    80006a48:	fc5e                	sd	s7,56(sp)
    80006a4a:	f862                	sd	s8,48(sp)
    80006a4c:	f466                	sd	s9,40(sp)
    80006a4e:	f06a                	sd	s10,32(sp)
    80006a50:	ec6e                	sd	s11,24(sp)
    80006a52:	0100                	addi	s0,sp,128
    80006a54:	8aaa                	mv	s5,a0
    80006a56:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006a58:	00c52c83          	lw	s9,12(a0)
    80006a5c:	001c9c9b          	slliw	s9,s9,0x1
    80006a60:	1c82                	slli	s9,s9,0x20
    80006a62:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006a66:	0002e517          	auipc	a0,0x2e
    80006a6a:	6c250513          	addi	a0,a0,1730 # 80035128 <disk+0x2128>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	154080e7          	jalr	340(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006a76:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006a78:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006a7a:	0002cc17          	auipc	s8,0x2c
    80006a7e:	586c0c13          	addi	s8,s8,1414 # 80033000 <disk>
    80006a82:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006a84:	4b0d                	li	s6,3
    80006a86:	a0ad                	j	80006af0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006a88:	00fc0733          	add	a4,s8,a5
    80006a8c:	975e                	add	a4,a4,s7
    80006a8e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a92:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006a94:	0207c563          	bltz	a5,80006abe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006a98:	2905                	addiw	s2,s2,1
    80006a9a:	0611                	addi	a2,a2,4
    80006a9c:	19690d63          	beq	s2,s6,80006c36 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006aa0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006aa2:	0002e717          	auipc	a4,0x2e
    80006aa6:	57670713          	addi	a4,a4,1398 # 80035018 <disk+0x2018>
    80006aaa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006aac:	00074683          	lbu	a3,0(a4)
    80006ab0:	fee1                	bnez	a3,80006a88 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ab2:	2785                	addiw	a5,a5,1
    80006ab4:	0705                	addi	a4,a4,1
    80006ab6:	fe979be3          	bne	a5,s1,80006aac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006aba:	57fd                	li	a5,-1
    80006abc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006abe:	01205d63          	blez	s2,80006ad8 <virtio_disk_rw+0xa2>
    80006ac2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006ac4:	000a2503          	lw	a0,0(s4)
    80006ac8:	00000097          	auipc	ra,0x0
    80006acc:	d8e080e7          	jalr	-626(ra) # 80006856 <free_desc>
      for(int j = 0; j < i; j++)
    80006ad0:	2d85                	addiw	s11,s11,1
    80006ad2:	0a11                	addi	s4,s4,4
    80006ad4:	ffb918e3          	bne	s2,s11,80006ac4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ad8:	0002e597          	auipc	a1,0x2e
    80006adc:	65058593          	addi	a1,a1,1616 # 80035128 <disk+0x2128>
    80006ae0:	0002e517          	auipc	a0,0x2e
    80006ae4:	53850513          	addi	a0,a0,1336 # 80035018 <disk+0x2018>
    80006ae8:	ffffc097          	auipc	ra,0xffffc
    80006aec:	c2e080e7          	jalr	-978(ra) # 80002716 <sleep>
  for(int i = 0; i < 3; i++){
    80006af0:	f8040a13          	addi	s4,s0,-128
{
    80006af4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006af6:	894e                	mv	s2,s3
    80006af8:	b765                	j	80006aa0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006afa:	0002e697          	auipc	a3,0x2e
    80006afe:	5066b683          	ld	a3,1286(a3) # 80035000 <disk+0x2000>
    80006b02:	96ba                	add	a3,a3,a4
    80006b04:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006b08:	0002c817          	auipc	a6,0x2c
    80006b0c:	4f880813          	addi	a6,a6,1272 # 80033000 <disk>
    80006b10:	0002e697          	auipc	a3,0x2e
    80006b14:	4f068693          	addi	a3,a3,1264 # 80035000 <disk+0x2000>
    80006b18:	6290                	ld	a2,0(a3)
    80006b1a:	963a                	add	a2,a2,a4
    80006b1c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006b20:	0015e593          	ori	a1,a1,1
    80006b24:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006b28:	f8842603          	lw	a2,-120(s0)
    80006b2c:	628c                	ld	a1,0(a3)
    80006b2e:	972e                	add	a4,a4,a1
    80006b30:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b34:	20050593          	addi	a1,a0,512
    80006b38:	0592                	slli	a1,a1,0x4
    80006b3a:	95c2                	add	a1,a1,a6
    80006b3c:	577d                	li	a4,-1
    80006b3e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b42:	00461713          	slli	a4,a2,0x4
    80006b46:	6290                	ld	a2,0(a3)
    80006b48:	963a                	add	a2,a2,a4
    80006b4a:	03078793          	addi	a5,a5,48
    80006b4e:	97c2                	add	a5,a5,a6
    80006b50:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006b52:	629c                	ld	a5,0(a3)
    80006b54:	97ba                	add	a5,a5,a4
    80006b56:	4605                	li	a2,1
    80006b58:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b5a:	629c                	ld	a5,0(a3)
    80006b5c:	97ba                	add	a5,a5,a4
    80006b5e:	4809                	li	a6,2
    80006b60:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006b64:	629c                	ld	a5,0(a3)
    80006b66:	973e                	add	a4,a4,a5
    80006b68:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b6c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006b70:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b74:	6698                	ld	a4,8(a3)
    80006b76:	00275783          	lhu	a5,2(a4)
    80006b7a:	8b9d                	andi	a5,a5,7
    80006b7c:	0786                	slli	a5,a5,0x1
    80006b7e:	97ba                	add	a5,a5,a4
    80006b80:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006b84:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b88:	6698                	ld	a4,8(a3)
    80006b8a:	00275783          	lhu	a5,2(a4)
    80006b8e:	2785                	addiw	a5,a5,1
    80006b90:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b94:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b98:	100017b7          	lui	a5,0x10001
    80006b9c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ba0:	004aa783          	lw	a5,4(s5)
    80006ba4:	02c79163          	bne	a5,a2,80006bc6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006ba8:	0002e917          	auipc	s2,0x2e
    80006bac:	58090913          	addi	s2,s2,1408 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    80006bb0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006bb2:	85ca                	mv	a1,s2
    80006bb4:	8556                	mv	a0,s5
    80006bb6:	ffffc097          	auipc	ra,0xffffc
    80006bba:	b60080e7          	jalr	-1184(ra) # 80002716 <sleep>
  while(b->disk == 1) {
    80006bbe:	004aa783          	lw	a5,4(s5)
    80006bc2:	fe9788e3          	beq	a5,s1,80006bb2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006bc6:	f8042903          	lw	s2,-128(s0)
    80006bca:	20090793          	addi	a5,s2,512
    80006bce:	00479713          	slli	a4,a5,0x4
    80006bd2:	0002c797          	auipc	a5,0x2c
    80006bd6:	42e78793          	addi	a5,a5,1070 # 80033000 <disk>
    80006bda:	97ba                	add	a5,a5,a4
    80006bdc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006be0:	0002e997          	auipc	s3,0x2e
    80006be4:	42098993          	addi	s3,s3,1056 # 80035000 <disk+0x2000>
    80006be8:	00491713          	slli	a4,s2,0x4
    80006bec:	0009b783          	ld	a5,0(s3)
    80006bf0:	97ba                	add	a5,a5,a4
    80006bf2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006bf6:	854a                	mv	a0,s2
    80006bf8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006bfc:	00000097          	auipc	ra,0x0
    80006c00:	c5a080e7          	jalr	-934(ra) # 80006856 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c04:	8885                	andi	s1,s1,1
    80006c06:	f0ed                	bnez	s1,80006be8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c08:	0002e517          	auipc	a0,0x2e
    80006c0c:	52050513          	addi	a0,a0,1312 # 80035128 <disk+0x2128>
    80006c10:	ffffa097          	auipc	ra,0xffffa
    80006c14:	066080e7          	jalr	102(ra) # 80000c76 <release>
}
    80006c18:	70e6                	ld	ra,120(sp)
    80006c1a:	7446                	ld	s0,112(sp)
    80006c1c:	74a6                	ld	s1,104(sp)
    80006c1e:	7906                	ld	s2,96(sp)
    80006c20:	69e6                	ld	s3,88(sp)
    80006c22:	6a46                	ld	s4,80(sp)
    80006c24:	6aa6                	ld	s5,72(sp)
    80006c26:	6b06                	ld	s6,64(sp)
    80006c28:	7be2                	ld	s7,56(sp)
    80006c2a:	7c42                	ld	s8,48(sp)
    80006c2c:	7ca2                	ld	s9,40(sp)
    80006c2e:	7d02                	ld	s10,32(sp)
    80006c30:	6de2                	ld	s11,24(sp)
    80006c32:	6109                	addi	sp,sp,128
    80006c34:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c36:	f8042503          	lw	a0,-128(s0)
    80006c3a:	20050793          	addi	a5,a0,512
    80006c3e:	0792                	slli	a5,a5,0x4
  if(write)
    80006c40:	0002c817          	auipc	a6,0x2c
    80006c44:	3c080813          	addi	a6,a6,960 # 80033000 <disk>
    80006c48:	00f80733          	add	a4,a6,a5
    80006c4c:	01a036b3          	snez	a3,s10
    80006c50:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006c54:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006c58:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c5c:	7679                	lui	a2,0xffffe
    80006c5e:	963e                	add	a2,a2,a5
    80006c60:	0002e697          	auipc	a3,0x2e
    80006c64:	3a068693          	addi	a3,a3,928 # 80035000 <disk+0x2000>
    80006c68:	6298                	ld	a4,0(a3)
    80006c6a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c6c:	0a878593          	addi	a1,a5,168
    80006c70:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c72:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c74:	6298                	ld	a4,0(a3)
    80006c76:	9732                	add	a4,a4,a2
    80006c78:	45c1                	li	a1,16
    80006c7a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c7c:	6298                	ld	a4,0(a3)
    80006c7e:	9732                	add	a4,a4,a2
    80006c80:	4585                	li	a1,1
    80006c82:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c86:	f8442703          	lw	a4,-124(s0)
    80006c8a:	628c                	ld	a1,0(a3)
    80006c8c:	962e                	add	a2,a2,a1
    80006c8e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c92:	0712                	slli	a4,a4,0x4
    80006c94:	6290                	ld	a2,0(a3)
    80006c96:	963a                	add	a2,a2,a4
    80006c98:	058a8593          	addi	a1,s5,88
    80006c9c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c9e:	6294                	ld	a3,0(a3)
    80006ca0:	96ba                	add	a3,a3,a4
    80006ca2:	40000613          	li	a2,1024
    80006ca6:	c690                	sw	a2,8(a3)
  if(write)
    80006ca8:	e40d19e3          	bnez	s10,80006afa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006cac:	0002e697          	auipc	a3,0x2e
    80006cb0:	3546b683          	ld	a3,852(a3) # 80035000 <disk+0x2000>
    80006cb4:	96ba                	add	a3,a3,a4
    80006cb6:	4609                	li	a2,2
    80006cb8:	00c69623          	sh	a2,12(a3)
    80006cbc:	b5b1                	j	80006b08 <virtio_disk_rw+0xd2>

0000000080006cbe <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006cbe:	1101                	addi	sp,sp,-32
    80006cc0:	ec06                	sd	ra,24(sp)
    80006cc2:	e822                	sd	s0,16(sp)
    80006cc4:	e426                	sd	s1,8(sp)
    80006cc6:	e04a                	sd	s2,0(sp)
    80006cc8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006cca:	0002e517          	auipc	a0,0x2e
    80006cce:	45e50513          	addi	a0,a0,1118 # 80035128 <disk+0x2128>
    80006cd2:	ffffa097          	auipc	ra,0xffffa
    80006cd6:	ef0080e7          	jalr	-272(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006cda:	10001737          	lui	a4,0x10001
    80006cde:	533c                	lw	a5,96(a4)
    80006ce0:	8b8d                	andi	a5,a5,3
    80006ce2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ce4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ce8:	0002e797          	auipc	a5,0x2e
    80006cec:	31878793          	addi	a5,a5,792 # 80035000 <disk+0x2000>
    80006cf0:	6b94                	ld	a3,16(a5)
    80006cf2:	0207d703          	lhu	a4,32(a5)
    80006cf6:	0026d783          	lhu	a5,2(a3)
    80006cfa:	06f70163          	beq	a4,a5,80006d5c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006cfe:	0002c917          	auipc	s2,0x2c
    80006d02:	30290913          	addi	s2,s2,770 # 80033000 <disk>
    80006d06:	0002e497          	auipc	s1,0x2e
    80006d0a:	2fa48493          	addi	s1,s1,762 # 80035000 <disk+0x2000>
    __sync_synchronize();
    80006d0e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d12:	6898                	ld	a4,16(s1)
    80006d14:	0204d783          	lhu	a5,32(s1)
    80006d18:	8b9d                	andi	a5,a5,7
    80006d1a:	078e                	slli	a5,a5,0x3
    80006d1c:	97ba                	add	a5,a5,a4
    80006d1e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d20:	20078713          	addi	a4,a5,512
    80006d24:	0712                	slli	a4,a4,0x4
    80006d26:	974a                	add	a4,a4,s2
    80006d28:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006d2c:	e731                	bnez	a4,80006d78 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d2e:	20078793          	addi	a5,a5,512
    80006d32:	0792                	slli	a5,a5,0x4
    80006d34:	97ca                	add	a5,a5,s2
    80006d36:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006d38:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d3c:	ffffc097          	auipc	ra,0xffffc
    80006d40:	b66080e7          	jalr	-1178(ra) # 800028a2 <wakeup>

    disk.used_idx += 1;
    80006d44:	0204d783          	lhu	a5,32(s1)
    80006d48:	2785                	addiw	a5,a5,1
    80006d4a:	17c2                	slli	a5,a5,0x30
    80006d4c:	93c1                	srli	a5,a5,0x30
    80006d4e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d52:	6898                	ld	a4,16(s1)
    80006d54:	00275703          	lhu	a4,2(a4)
    80006d58:	faf71be3          	bne	a4,a5,80006d0e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006d5c:	0002e517          	auipc	a0,0x2e
    80006d60:	3cc50513          	addi	a0,a0,972 # 80035128 <disk+0x2128>
    80006d64:	ffffa097          	auipc	ra,0xffffa
    80006d68:	f12080e7          	jalr	-238(ra) # 80000c76 <release>
}
    80006d6c:	60e2                	ld	ra,24(sp)
    80006d6e:	6442                	ld	s0,16(sp)
    80006d70:	64a2                	ld	s1,8(sp)
    80006d72:	6902                	ld	s2,0(sp)
    80006d74:	6105                	addi	sp,sp,32
    80006d76:	8082                	ret
      panic("virtio_disk_intr status");
    80006d78:	00002517          	auipc	a0,0x2
    80006d7c:	ad850513          	addi	a0,a0,-1320 # 80008850 <syscalls+0x3e8>
    80006d80:	ffff9097          	auipc	ra,0xffff9
    80006d84:	7aa080e7          	jalr	1962(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
