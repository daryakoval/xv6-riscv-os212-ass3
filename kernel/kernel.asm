
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
    80000068:	6bc78793          	addi	a5,a5,1724 # 80006720 <timervec>
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
    80000122:	9a0080e7          	jalr	-1632(ra) # 80002abe <either_copyin>
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
    800001b6:	d48080e7          	jalr	-696(ra) # 80001efa <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	4ec080e7          	jalr	1260(ra) # 800026ae <sleep>
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
    80000202:	86a080e7          	jalr	-1942(ra) # 80002a68 <either_copyout>
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
    800002e2:	836080e7          	jalr	-1994(ra) # 80002b14 <procdump>
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
    80000436:	408080e7          	jalr	1032(ra) # 8000283a <wakeup>
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
    80000468:	2b478793          	addi	a5,a5,692 # 80031718 <devsw>
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
    80000882:	fbc080e7          	jalr	-68(ra) # 8000283a <wakeup>
    
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
    8000090e:	da4080e7          	jalr	-604(ra) # 800026ae <sleep>
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
    80000b60:	382080e7          	jalr	898(ra) # 80001ede <mycpu>
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
    80000b92:	350080e7          	jalr	848(ra) # 80001ede <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	344080e7          	jalr	836(ra) # 80001ede <mycpu>
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
    80000bb6:	32c080e7          	jalr	812(ra) # 80001ede <mycpu>
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
    80000bf6:	2ec080e7          	jalr	748(ra) # 80001ede <mycpu>
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
    80000c22:	2c0080e7          	jalr	704(ra) # 80001ede <mycpu>
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
    80000e78:	05a080e7          	jalr	90(ra) # 80001ece <cpuid>
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
    80000e94:	03e080e7          	jalr	62(ra) # 80001ece <cpuid>
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
    80000eb6:	da4080e7          	jalr	-604(ra) # 80002c56 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	8a6080e7          	jalr	-1882(ra) # 80006760 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	63a080e7          	jalr	1594(ra) # 800024fc <scheduler>
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
    80000f26:	efc080e7          	jalr	-260(ra) # 80001e1e <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	d04080e7          	jalr	-764(ra) # 80002c2e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	d24080e7          	jalr	-732(ra) # 80002c56 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	810080e7          	jalr	-2032(ra) # 8000674a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	81e080e7          	jalr	-2018(ra) # 80006760 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	462080e7          	jalr	1122(ra) # 800033ac <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	af4080e7          	jalr	-1292(ra) # 80003a46 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	db4080e7          	jalr	-588(ra) # 80004d0e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	920080e7          	jalr	-1760(ra) # 80006882 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	2ae080e7          	jalr	686(ra) # 80002218 <userinit>
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
    80001210:	b7c080e7          	jalr	-1156(ra) # 80001d88 <proc_mapstacks>
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
    800012d2:	c2c080e7          	jalr	-980(ra) # 80001efa <myproc>
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
    80001842:	6bc080e7          	jalr	1724(ra) # 80001efa <myproc>
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
    800018e8:	616080e7          	jalr	1558(ra) # 80001efa <myproc>
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
    80001936:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001938:	00000097          	auipc	ra,0x0
    8000193c:	5c2080e7          	jalr	1474(ra) # 80001efa <myproc>
    80001940:	8aaa                	mv	s5,a0
  struct page_metadata *pg;
  uint64 min_creation_time = ~0;
  int min_creation_index = 1;
    80001942:	4485                	li	s1,1
  uint64 min_creation_time = ~0;
    80001944:	59fd                	li	s3,-1
    80001946:	37050913          	addi	s2,a0,880

  findIndex:
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    if(pg->state && pg->creationOrder<= min_creation_time){
      min_creation_index=(int)(pg - p->pages_in_memory);
    8000194a:	17050a13          	addi	s4,a0,368
    8000194e:	a0a1                	j	80001996 <get_page_scfifo+0x70>
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    80001950:	02078793          	addi	a5,a5,32
    80001954:	00f90e63          	beq	s2,a5,80001970 <get_page_scfifo+0x4a>
    if(pg->state && pg->creationOrder<= min_creation_time){
    80001958:	4798                	lw	a4,8(a5)
    8000195a:	db7d                	beqz	a4,80001950 <get_page_scfifo+0x2a>
    8000195c:	6f98                	ld	a4,24(a5)
    8000195e:	fee9e9e3          	bltu	s3,a4,80001950 <get_page_scfifo+0x2a>
      min_creation_index=(int)(pg - p->pages_in_memory);
    80001962:	414786b3          	sub	a3,a5,s4
    80001966:	8695                	srai	a3,a3,0x5
    80001968:	0006849b          	sext.w	s1,a3
      min_creation_time=pg->creationOrder;
    8000196c:	89ba                	mv	s3,a4
    8000196e:	b7cd                	j	80001950 <get_page_scfifo+0x2a>
    }
  }
  pte_t* pte=walk(p->pagetable,p->pages_in_memory[min_creation_index].va,0); // return addr
    80001970:	00549793          	slli	a5,s1,0x5
    80001974:	97d6                	add	a5,a5,s5
    80001976:	4601                	li	a2,0
    80001978:	1707b583          	ld	a1,368(a5)
    8000197c:	050ab503          	ld	a0,80(s5) # fffffffffffff050 <end+0xffffffff7ffc9050>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	626080e7          	jalr	1574(ra) # 80000fa6 <walk>
  if((*pte & PTE_A)!=0){ // give second chance 
    80001988:	611c                	ld	a5,0(a0)
    8000198a:	0407f713          	andi	a4,a5,64
    8000198e:	c719                	beqz	a4,8000199c <get_page_scfifo+0x76>
  *pte &=~ PTE_A; // trun off the access flag
    80001990:	fbf7f793          	andi	a5,a5,-65
    80001994:	e11c                	sd	a5,0(a0)
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    80001996:	190a8793          	addi	a5,s5,400
    8000199a:	bf7d                	j	80001958 <get_page_scfifo+0x32>
  goto findIndex;
  }
  // if got here then we found pg with min time that PTE_A is turned off
  return min_creation_index;
}
    8000199c:	8526                	mv	a0,s1
    8000199e:	70e2                	ld	ra,56(sp)
    800019a0:	7442                	ld	s0,48(sp)
    800019a2:	74a2                	ld	s1,40(sp)
    800019a4:	7902                	ld	s2,32(sp)
    800019a6:	69e2                	ld	s3,24(sp)
    800019a8:	6a42                	ld	s4,16(sp)
    800019aa:	6aa2                	ld	s5,8(sp)
    800019ac:	6121                	addi	sp,sp,64
    800019ae:	8082                	ret

00000000800019b0 <get_page_lapa>:

int get_page_lapa(){
    800019b0:	1141                	addi	sp,sp,-16
    800019b2:	e406                	sd	ra,8(sp)
    800019b4:	e022                	sd	s0,0(sp)
    800019b6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800019b8:	00000097          	auipc	ra,0x0
    800019bc:	542080e7          	jalr	1346(ra) # 80001efa <myproc>
    800019c0:	87aa                	mv	a5,a0
  struct page_metadata *pg;
  int min_number_of_1=64;
  int index_with_min_1=-1;
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800019c2:	19050613          	addi	a2,a0,400
    800019c6:	37050e13          	addi	t3,a0,880
  int index_with_min_1=-1;
    800019ca:	557d                	li	a0,-1
  int min_number_of_1=64;
    800019cc:	04000813          	li	a6,64
    int counter=0;
    if(pg->state){
        for(int i=0;i<64;i++){ // do a mask for the 64 bits 
    800019d0:	4e81                	li	t4,0
          uint64 mask = 1 << i;
    800019d2:	4885                	li	a7,1
        for(int i=0;i<64;i++){ // do a mask for the 64 bits 
    800019d4:	04000313          	li	t1,64
          if(counter>=min_number_of_1) // in case count is bigger than current min 
            break;
        }
        if(counter<min_number_of_1){
          min_number_of_1=counter;
          index_with_min_1=(int)(pg - p->pages_in_memory);
    800019d8:	17078f13          	addi	t5,a5,368
    800019dc:	a02d                	j	80001a06 <get_page_lapa+0x56>
          if(counter>=min_number_of_1) // in case count is bigger than current min 
    800019de:	0306d063          	bge	a3,a6,800019fe <get_page_lapa+0x4e>
        for(int i=0;i<64;i++){ // do a mask for the 64 bits 
    800019e2:	2705                	addiw	a4,a4,1
    800019e4:	00670863          	beq	a4,t1,800019f4 <get_page_lapa+0x44>
          uint64 mask = 1 << i;
    800019e8:	00e897bb          	sllw	a5,a7,a4
          if((pg->age & mask)!=0)// if 1 is found 
    800019ec:	8fed                	and	a5,a5,a1
    800019ee:	dbe5                	beqz	a5,800019de <get_page_lapa+0x2e>
              counter++;
    800019f0:	2685                	addiw	a3,a3,1
    800019f2:	b7f5                	j	800019de <get_page_lapa+0x2e>
          index_with_min_1=(int)(pg - p->pages_in_memory);
    800019f4:	41e60533          	sub	a0,a2,t5
    800019f8:	8515                	srai	a0,a0,0x5
    800019fa:	2501                	sext.w	a0,a0
    800019fc:	8836                	mv	a6,a3
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800019fe:	02060613          	addi	a2,a2,32 # 1020 <_entry-0x7fffefe0>
    80001a02:	01c60863          	beq	a2,t3,80001a12 <get_page_lapa+0x62>
    if(pg->state){
    80001a06:	461c                	lw	a5,8(a2)
    80001a08:	dbfd                	beqz	a5,800019fe <get_page_lapa+0x4e>
          if((pg->age & mask)!=0)// if 1 is found 
    80001a0a:	6a0c                	ld	a1,16(a2)
        for(int i=0;i<64;i++){ // do a mask for the 64 bits 
    80001a0c:	8776                	mv	a4,t4
    int counter=0;
    80001a0e:	86f6                	mv	a3,t4
    80001a10:	bfe1                	j	800019e8 <get_page_lapa+0x38>
        }
      }
    }
    return index_with_min_1;
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret

0000000080001a1a <get_page_by_alg>:
// get page that will be swaped out (Task 2)
// Returns page index in pages_in_memory array, this page will be swapped out
int get_page_by_alg(){
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e406                	sd	ra,8(sp)
    80001a1e:	e022                	sd	s0,0(sp)
    80001a20:	0800                	addi	s0,sp,16
  #ifdef SCFIFO
  return get_page_scfifo();
    80001a22:	00000097          	auipc	ra,0x0
    80001a26:	f04080e7          	jalr	-252(ra) # 80001926 <get_page_scfifo>
  return get_page_lapa();
  #endif
  #ifdef NONE
  return 1; //will never got here
  #endif
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret

0000000080001a32 <swap_into_file>:


//Chose page to remove from main memory (using one of task2 algorithms) 
//and swap this page into file
void swap_into_file(pagetable_t pagetable){
    80001a32:	7139                	addi	sp,sp,-64
    80001a34:	fc06                	sd	ra,56(sp)
    80001a36:	f822                	sd	s0,48(sp)
    80001a38:	f426                	sd	s1,40(sp)
    80001a3a:	f04a                	sd	s2,32(sp)
    80001a3c:	ec4e                	sd	s3,24(sp)
    80001a3e:	e852                	sd	s4,16(sp)
    80001a40:	e456                	sd	s5,8(sp)
    80001a42:	e05a                	sd	s6,0(sp)
    80001a44:	0080                	addi	s0,sp,64
    80001a46:	8a2a                	mv	s4,a0
  #ifdef YES
  printf("too much psyc pages: lets swap into file page\n");
  #endif

  struct proc *p = myproc();
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	4b2080e7          	jalr	1202(ra) # 80001efa <myproc>
  if(p->num_pages_in_psyc + p->num_pages_in_swapfile == MAX_TOTAL_PAGES){
    80001a50:	57052783          	lw	a5,1392(a0)
    80001a54:	57452703          	lw	a4,1396(a0)
    80001a58:	9fb9                	addw	a5,a5,a4
    80001a5a:	02000713          	li	a4,32
    80001a5e:	02e78c63          	beq	a5,a4,80001a96 <swap_into_file+0x64>
    80001a62:	892a                	mv	s2,a0
  return get_page_scfifo();
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	ec2080e7          	jalr	-318(ra) # 80001926 <get_page_scfifo>

  //find free space in swaped pages array,
  //add selected to swap out page to this array 
  //and write this page to swapfile.
  struct page_metadata *pg;
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001a6c:	37090a93          	addi	s5,s2,880 # 1370 <_entry-0x7fffec90>
    80001a70:	57090713          	addi	a4,s2,1392
    80001a74:	84d6                	mv	s1,s5
    if(!pg->state){
    80001a76:	449c                	lw	a5,8(s1)
    80001a78:	c79d                	beqz	a5,80001aa6 <swap_into_file+0x74>
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001a7a:	02048493          	addi	s1,s1,32
    80001a7e:	fee49ce3          	bne	s1,a4,80001a76 <swap_into_file+0x44>
      sfence_vma(); 
      break;
    }
  }

}
    80001a82:	70e2                	ld	ra,56(sp)
    80001a84:	7442                	ld	s0,48(sp)
    80001a86:	74a2                	ld	s1,40(sp)
    80001a88:	7902                	ld	s2,32(sp)
    80001a8a:	69e2                	ld	s3,24(sp)
    80001a8c:	6a42                	ld	s4,16(sp)
    80001a8e:	6aa2                	ld	s5,8(sp)
    80001a90:	6b02                	ld	s6,0(sp)
    80001a92:	6121                	addi	sp,sp,64
    80001a94:	8082                	ret
    panic("more than 32 pages per proccess");
    80001a96:	00006517          	auipc	a0,0x6
    80001a9a:	72a50513          	addi	a0,a0,1834 # 800081c0 <digits+0x180>
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	a8c080e7          	jalr	-1396(ra) # 8000052a <panic>
      pg->state = 1;
    80001aa6:	4785                	li	a5,1
    80001aa8:	c49c                	sw	a5,8(s1)
      pg->va = pg_to_swap->va;
    80001aaa:	00551993          	slli	s3,a0,0x5
    80001aae:	99ca                	add	s3,s3,s2
    80001ab0:	1709b583          	ld	a1,368(s3)
    80001ab4:	e08c                	sd	a1,0(s1)
      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
    80001ab6:	4601                	li	a2,0
    80001ab8:	8552                	mv	a0,s4
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	4ec080e7          	jalr	1260(ra) # 80000fa6 <walk>
    80001ac2:	8b2a                	mv	s6,a0
      uint64 pa = PTE2PA(*pte);
    80001ac4:	00053a03          	ld	s4,0(a0)
    80001ac8:	00aa5a13          	srli	s4,s4,0xa
    80001acc:	0a32                	slli	s4,s4,0xc
      int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001ace:	41548633          	sub	a2,s1,s5
      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 
    80001ad2:	6685                	lui	a3,0x1
    80001ad4:	0076161b          	slliw	a2,a2,0x7
    80001ad8:	85d2                	mv	a1,s4
    80001ada:	854a                	mv	a0,s2
    80001adc:	00003097          	auipc	ra,0x3
    80001ae0:	c1c080e7          	jalr	-996(ra) # 800046f8 <writeToSwapFile>
      p->num_pages_in_swapfile++;
    80001ae4:	57492783          	lw	a5,1396(s2)
    80001ae8:	2785                	addiw	a5,a5,1
    80001aea:	56f92a23          	sw	a5,1396(s2)
      kfree((void*)pa); 
    80001aee:	8552                	mv	a0,s4
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	ee6080e7          	jalr	-282(ra) # 800009d6 <kfree>
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
    80001af8:	000b3783          	ld	a5,0(s6) # 1000 <_entry-0x7ffff000>
    80001afc:	9bf9                	andi	a5,a5,-2
    80001afe:	2007e793          	ori	a5,a5,512
    80001b02:	00fb3023          	sd	a5,0(s6)
      pg_to_swap->state = 0;
    80001b06:	1609ac23          	sw	zero,376(s3)
      pg_to_swap->va = 0;
    80001b0a:	1609b823          	sd	zero,368(s3)
      p->num_pages_in_psyc--;
    80001b0e:	57092783          	lw	a5,1392(s2)
    80001b12:	37fd                	addiw	a5,a5,-1
    80001b14:	56f92823          	sw	a5,1392(s2)
    80001b18:	12000073          	sfence.vma
}
    80001b1c:	b79d                	j	80001a82 <swap_into_file+0x50>

0000000080001b1e <add_to_memory>:

//Adding new page created by uvmalloc() to proccess pages
void add_to_memory(uint64 a, pagetable_t pagetable){
    80001b1e:	7179                	addi	sp,sp,-48
    80001b20:	f406                	sd	ra,40(sp)
    80001b22:	f022                	sd	s0,32(sp)
    80001b24:	ec26                	sd	s1,24(sp)
    80001b26:	e84a                	sd	s2,16(sp)
    80001b28:	e44e                	sd	s3,8(sp)
    80001b2a:	1800                	addi	s0,sp,48
    80001b2c:	892a                	mv	s2,a0
    80001b2e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	3ca080e7          	jalr	970(ra) # 80001efa <myproc>
    80001b38:	84aa                	mv	s1,a0
  //No free space in the psyc memory,
  //Chose page to remove from main memory (using one of task2 algorithms) 
  //and swap this page into file
  if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001b3a:	57052703          	lw	a4,1392(a0)
    80001b3e:	47c1                	li	a5,16
    80001b40:	04f70763          	beq	a4,a5,80001b8e <add_to_memory+0x70>
    swap_into_file(pagetable);
  }

  //Now we have free space in psyc memory (maybe we had free space before too):
  //just add all page information to pages_in_memory array:
  int free_index_memory_array = find_free_index_in_memory_array();
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	cf2080e7          	jalr	-782(ra) # 80001836 <find_free_index_in_memory_array>
  
  #ifdef YES
  printf("add to file: adding va= %p\n", a);
  #endif

  pg->state = 1;
    80001b4c:	00551793          	slli	a5,a0,0x5
    80001b50:	97a6                	add	a5,a5,s1
    80001b52:	4705                	li	a4,1
    80001b54:	16e7ac23          	sw	a4,376(a5)
  pg->va = a;
    80001b58:	1727b823          	sd	s2,368(a5)
  #endif
  #ifdef LAPA
  pg->age = (uint64)~0;
  #endif

  p->num_pages_in_psyc++;
    80001b5c:	5704a783          	lw	a5,1392(s1)
    80001b60:	2785                	addiw	a5,a5,1
    80001b62:	56f4a823          	sw	a5,1392(s1)

  pte_t* pte = walk(pagetable, pg->va, 0);
    80001b66:	4601                	li	a2,0
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	854e                	mv	a0,s3
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	43a080e7          	jalr	1082(ra) # 80000fa6 <walk>
  //set pte flags:
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001b74:	611c                	ld	a5,0(a0)
    80001b76:	dff7f793          	andi	a5,a5,-513
  *pte |= PTE_V;
    80001b7a:	0017e793          	ori	a5,a5,1
    80001b7e:	e11c                	sd	a5,0(a0)
  #ifdef YES
  printf("finish add to memory: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
  #endif
}
    80001b80:	70a2                	ld	ra,40(sp)
    80001b82:	7402                	ld	s0,32(sp)
    80001b84:	64e2                	ld	s1,24(sp)
    80001b86:	6942                	ld	s2,16(sp)
    80001b88:	69a2                	ld	s3,8(sp)
    80001b8a:	6145                	addi	sp,sp,48
    80001b8c:	8082                	ret
    swap_into_file(pagetable);
    80001b8e:	854e                	mv	a0,s3
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	ea2080e7          	jalr	-350(ra) # 80001a32 <swap_into_file>
    80001b98:	b775                	j	80001b44 <add_to_memory+0x26>

0000000080001b9a <uvmalloc>:
  if(newsz < oldsz)
    80001b9a:	0cb66363          	bltu	a2,a1,80001c60 <uvmalloc+0xc6>
{
    80001b9e:	7139                	addi	sp,sp,-64
    80001ba0:	fc06                	sd	ra,56(sp)
    80001ba2:	f822                	sd	s0,48(sp)
    80001ba4:	f426                	sd	s1,40(sp)
    80001ba6:	f04a                	sd	s2,32(sp)
    80001ba8:	ec4e                	sd	s3,24(sp)
    80001baa:	e852                	sd	s4,16(sp)
    80001bac:	e456                	sd	s5,8(sp)
    80001bae:	e05a                	sd	s6,0(sp)
    80001bb0:	0080                	addi	s0,sp,64
    80001bb2:	89aa                	mv	s3,a0
    80001bb4:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    80001bb6:	6a05                	lui	s4,0x1
    80001bb8:	1a7d                	addi	s4,s4,-1
    80001bba:	95d2                	add	a1,a1,s4
    80001bbc:	7a7d                	lui	s4,0xfffff
    80001bbe:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001bc2:	0aca7163          	bgeu	s4,a2,80001c64 <uvmalloc+0xca>
    80001bc6:	8952                	mv	s2,s4
    if(myproc()->pid > 2){
    80001bc8:	4b09                	li	s6,2
    80001bca:	a0a9                	j	80001c14 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001bcc:	8652                	mv	a2,s4
    80001bce:	85ca                	mv	a1,s2
    80001bd0:	854e                	mv	a0,s3
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	874080e7          	jalr	-1932(ra) # 80001446 <uvmdealloc>
      return 0;
    80001bda:	4501                	li	a0,0
}
    80001bdc:	70e2                	ld	ra,56(sp)
    80001bde:	7442                	ld	s0,48(sp)
    80001be0:	74a2                	ld	s1,40(sp)
    80001be2:	7902                	ld	s2,32(sp)
    80001be4:	69e2                	ld	s3,24(sp)
    80001be6:	6a42                	ld	s4,16(sp)
    80001be8:	6aa2                	ld	s5,8(sp)
    80001bea:	6b02                	ld	s6,0(sp)
    80001bec:	6121                	addi	sp,sp,64
    80001bee:	8082                	ret
      kfree(mem);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	de4080e7          	jalr	-540(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001bfa:	8652                	mv	a2,s4
    80001bfc:	85ca                	mv	a1,s2
    80001bfe:	854e                	mv	a0,s3
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	846080e7          	jalr	-1978(ra) # 80001446 <uvmdealloc>
      return 0;
    80001c08:	4501                	li	a0,0
    80001c0a:	bfc9                	j	80001bdc <uvmalloc+0x42>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001c0c:	6785                	lui	a5,0x1
    80001c0e:	993e                	add	s2,s2,a5
    80001c10:	05597663          	bgeu	s2,s5,80001c5c <uvmalloc+0xc2>
    mem = kalloc();
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	ebe080e7          	jalr	-322(ra) # 80000ad2 <kalloc>
    80001c1c:	84aa                	mv	s1,a0
    if(mem == 0){
    80001c1e:	d55d                	beqz	a0,80001bcc <uvmalloc+0x32>
    memset(mem, 0, PGSIZE);
    80001c20:	6605                	lui	a2,0x1
    80001c22:	4581                	li	a1,0
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	09a080e7          	jalr	154(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001c2c:	4779                	li	a4,30
    80001c2e:	86a6                	mv	a3,s1
    80001c30:	6605                	lui	a2,0x1
    80001c32:	85ca                	mv	a1,s2
    80001c34:	854e                	mv	a0,s3
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	458080e7          	jalr	1112(ra) # 8000108e <mappages>
    80001c3e:	f94d                	bnez	a0,80001bf0 <uvmalloc+0x56>
    if(myproc()->pid > 2){
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	2ba080e7          	jalr	698(ra) # 80001efa <myproc>
    80001c48:	591c                	lw	a5,48(a0)
    80001c4a:	fcfb51e3          	bge	s6,a5,80001c0c <uvmalloc+0x72>
      add_to_memory(a, pagetable);
    80001c4e:	85ce                	mv	a1,s3
    80001c50:	854a                	mv	a0,s2
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	ecc080e7          	jalr	-308(ra) # 80001b1e <add_to_memory>
    80001c5a:	bf4d                	j	80001c0c <uvmalloc+0x72>
  return newsz;
    80001c5c:	8556                	mv	a0,s5
    80001c5e:	bfbd                	j	80001bdc <uvmalloc+0x42>
    return oldsz;
    80001c60:	852e                	mv	a0,a1
}
    80001c62:	8082                	ret
  return newsz;
    80001c64:	8532                	mv	a0,a2
    80001c66:	bf9d                	j	80001bdc <uvmalloc+0x42>

0000000080001c68 <handle_pagefault>:

//Handle page fault - called from trap.c
int handle_pagefault(){
    80001c68:	7139                	addi	sp,sp,-64
    80001c6a:	fc06                	sd	ra,56(sp)
    80001c6c:	f822                	sd	s0,48(sp)
    80001c6e:	f426                	sd	s1,40(sp)
    80001c70:	f04a                	sd	s2,32(sp)
    80001c72:	ec4e                	sd	s3,24(sp)
    80001c74:	e852                	sd	s4,16(sp)
    80001c76:	e456                	sd	s5,8(sp)
    80001c78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	280080e7          	jalr	640(ra) # 80001efa <myproc>
    80001c82:	89aa                	mv	s3,a0
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001c84:	14302973          	csrr	s2,stval
  uint64 va = r_stval();
  
  pte_t* pte = walk(p->pagetable, va, 0);
    80001c88:	4601                	li	a2,0
    80001c8a:	85ca                	mv	a1,s2
    80001c8c:	6928                	ld	a0,80(a0)
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	318080e7          	jalr	792(ra) # 80000fa6 <walk>
  //If the page was swaped out, we should bring it back to memory
  if(*pte & PTE_PG){
    80001c96:	610c                	ld	a1,0(a0)
    80001c98:	2005f793          	andi	a5,a1,512
    80001c9c:	cfe1                	beqz	a5,80001d74 <handle_pagefault+0x10c>
    //If no place in memory - swap out page
    if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001c9e:	5709a703          	lw	a4,1392(s3)
    80001ca2:	47c1                	li	a5,16
    80001ca4:	04f70263          	beq	a4,a5,80001ce8 <handle_pagefault+0x80>
      swap_into_file(p->pagetable);
    }

    //Now we have free space in psyc memory (maybe we had free space before too):
    //bring page from swapFile and put it into physic memory
    uint64 va1 = PGROUNDDOWN(va);
    80001ca8:	77fd                	lui	a5,0xfffff
    80001caa:	00f97933          	and	s2,s2,a5
    char *mem = kalloc();
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	e24080e7          	jalr	-476(ra) # 80000ad2 <kalloc>
    80001cb6:	8a2a                	mv	s4,a0
    
    struct page_metadata *pg;
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001cb8:	37098a93          	addi	s5,s3,880
    80001cbc:	57098713          	addi	a4,s3,1392
    80001cc0:	84d6                	mv	s1,s5
      if(pg->va == va1){
    80001cc2:	609c                	ld	a5,0(s1)
    80001cc4:	03278963          	beq	a5,s2,80001cf6 <handle_pagefault+0x8e>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001cc8:	02048493          	addi	s1,s1,32
    80001ccc:	fee49be3          	bne	s1,a4,80001cc2 <handle_pagefault+0x5a>
  asm volatile("sfence.vma zero, zero");
    80001cd0:	12000073          	sfence.vma
    }
    sfence_vma();
    #ifdef YES
    printf("finish handle_page\n");
    #endif
    return 3;
    80001cd4:	450d                	li	a0,3
  }else{
    printf("segfault: pte: %p\n", *pte);
    return 0; //this is segfault
  }
    80001cd6:	70e2                	ld	ra,56(sp)
    80001cd8:	7442                	ld	s0,48(sp)
    80001cda:	74a2                	ld	s1,40(sp)
    80001cdc:	7902                	ld	s2,32(sp)
    80001cde:	69e2                	ld	s3,24(sp)
    80001ce0:	6a42                	ld	s4,16(sp)
    80001ce2:	6aa2                	ld	s5,8(sp)
    80001ce4:	6121                	addi	sp,sp,64
    80001ce6:	8082                	ret
      swap_into_file(p->pagetable);
    80001ce8:	0509b503          	ld	a0,80(s3)
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	d46080e7          	jalr	-698(ra) # 80001a32 <swap_into_file>
    80001cf4:	bf55                	j	80001ca8 <handle_pagefault+0x40>
        pte_t* pte = walk(p->pagetable, va1, 0);
    80001cf6:	4601                	li	a2,0
    80001cf8:	85ca                	mv	a1,s2
    80001cfa:	0509b503          	ld	a0,80(s3)
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	2a8080e7          	jalr	680(ra) # 80000fa6 <walk>
    80001d06:	892a                	mv	s2,a0
        int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001d08:	41548633          	sub	a2,s1,s5
        readFromSwapFile(p, mem, offset, PGSIZE);
    80001d0c:	6685                	lui	a3,0x1
    80001d0e:	0076161b          	slliw	a2,a2,0x7
    80001d12:	85d2                	mv	a1,s4
    80001d14:	854e                	mv	a0,s3
    80001d16:	00003097          	auipc	ra,0x3
    80001d1a:	a06080e7          	jalr	-1530(ra) # 8000471c <readFromSwapFile>
        int free_index_memory_array = find_free_index_in_memory_array();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	b18080e7          	jalr	-1256(ra) # 80001836 <find_free_index_in_memory_array>
        free_memory_page->state = 1;
    80001d26:	00551793          	slli	a5,a0,0x5
    80001d2a:	97ce                	add	a5,a5,s3
    80001d2c:	4705                	li	a4,1
    80001d2e:	16e7ac23          	sw	a4,376(a5) # fffffffffffff178 <end+0xffffffff7ffc9178>
        free_memory_page->va = pg->va;
    80001d32:	6098                	ld	a4,0(s1)
    80001d34:	16e7b823          	sd	a4,368(a5)
        p->num_pages_in_swapfile--;
    80001d38:	5749a783          	lw	a5,1396(s3)
    80001d3c:	37fd                	addiw	a5,a5,-1
    80001d3e:	56f9aa23          	sw	a5,1396(s3)
        pg->state = 0;
    80001d42:	0004a423          	sw	zero,8(s1)
        pg->va = 0;
    80001d46:	0004b023          	sd	zero,0(s1)
        pg->age = 0;
    80001d4a:	0004b823          	sd	zero,16(s1)
        p->num_pages_in_psyc++;
    80001d4e:	5709a783          	lw	a5,1392(s3)
    80001d52:	2785                	addiw	a5,a5,1
    80001d54:	56f9a823          	sw	a5,1392(s3)
        *pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress 
    80001d58:	00ca5a13          	srli	s4,s4,0xc
    80001d5c:	0a2a                	slli	s4,s4,0xa
    80001d5e:	00093783          	ld	a5,0(s2)
    80001d62:	1ff7f793          	andi	a5,a5,511
        *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001d66:	0147ea33          	or	s4,a5,s4
        *pte |= PTE_V;
    80001d6a:	001a6a13          	ori	s4,s4,1
    80001d6e:	01493023          	sd	s4,0(s2)
        break;
    80001d72:	bfb9                	j	80001cd0 <handle_pagefault+0x68>
    printf("segfault: pte: %p\n", *pte);
    80001d74:	00006517          	auipc	a0,0x6
    80001d78:	46c50513          	addi	a0,a0,1132 # 800081e0 <digits+0x1a0>
    80001d7c:	ffffe097          	auipc	ra,0xffffe
    80001d80:	7f8080e7          	jalr	2040(ra) # 80000574 <printf>
    return 0; //this is segfault
    80001d84:	4501                	li	a0,0
    80001d86:	bf81                	j	80001cd6 <handle_pagefault+0x6e>

0000000080001d88 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d88:	7139                	addi	sp,sp,-64
    80001d8a:	fc06                	sd	ra,56(sp)
    80001d8c:	f822                	sd	s0,48(sp)
    80001d8e:	f426                	sd	s1,40(sp)
    80001d90:	f04a                	sd	s2,32(sp)
    80001d92:	ec4e                	sd	s3,24(sp)
    80001d94:	e852                	sd	s4,16(sp)
    80001d96:	e456                	sd	s5,8(sp)
    80001d98:	e05a                	sd	s6,0(sp)
    80001d9a:	0080                	addi	s0,sp,64
    80001d9c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d9e:	00010497          	auipc	s1,0x10
    80001da2:	93248493          	addi	s1,s1,-1742 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001da6:	8b26                	mv	s6,s1
    80001da8:	00006a97          	auipc	s5,0x6
    80001dac:	258a8a93          	addi	s5,s5,600 # 80008000 <etext>
    80001db0:	04000937          	lui	s2,0x4000
    80001db4:	197d                	addi	s2,s2,-1
    80001db6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db8:	00025a17          	auipc	s4,0x25
    80001dbc:	718a0a13          	addi	s4,s4,1816 # 800274d0 <tickslock>
    char *pa = kalloc();
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	d12080e7          	jalr	-750(ra) # 80000ad2 <kalloc>
    80001dc8:	862a                	mv	a2,a0
    if(pa == 0)
    80001dca:	c131                	beqz	a0,80001e0e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001dcc:	416485b3          	sub	a1,s1,s6
    80001dd0:	858d                	srai	a1,a1,0x3
    80001dd2:	000ab783          	ld	a5,0(s5)
    80001dd6:	02f585b3          	mul	a1,a1,a5
    80001dda:	2585                	addiw	a1,a1,1
    80001ddc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001de0:	4719                	li	a4,6
    80001de2:	6685                	lui	a3,0x1
    80001de4:	40b905b3          	sub	a1,s2,a1
    80001de8:	854e                	mv	a0,s3
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	332080e7          	jalr	818(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001df2:	57848493          	addi	s1,s1,1400
    80001df6:	fd4495e3          	bne	s1,s4,80001dc0 <proc_mapstacks+0x38>
  }
}
    80001dfa:	70e2                	ld	ra,56(sp)
    80001dfc:	7442                	ld	s0,48(sp)
    80001dfe:	74a2                	ld	s1,40(sp)
    80001e00:	7902                	ld	s2,32(sp)
    80001e02:	69e2                	ld	s3,24(sp)
    80001e04:	6a42                	ld	s4,16(sp)
    80001e06:	6aa2                	ld	s5,8(sp)
    80001e08:	6b02                	ld	s6,0(sp)
    80001e0a:	6121                	addi	sp,sp,64
    80001e0c:	8082                	ret
      panic("kalloc");
    80001e0e:	00006517          	auipc	a0,0x6
    80001e12:	3ea50513          	addi	a0,a0,1002 # 800081f8 <digits+0x1b8>
    80001e16:	ffffe097          	auipc	ra,0xffffe
    80001e1a:	714080e7          	jalr	1812(ra) # 8000052a <panic>

0000000080001e1e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e1e:	7139                	addi	sp,sp,-64
    80001e20:	fc06                	sd	ra,56(sp)
    80001e22:	f822                	sd	s0,48(sp)
    80001e24:	f426                	sd	s1,40(sp)
    80001e26:	f04a                	sd	s2,32(sp)
    80001e28:	ec4e                	sd	s3,24(sp)
    80001e2a:	e852                	sd	s4,16(sp)
    80001e2c:	e456                	sd	s5,8(sp)
    80001e2e:	e05a                	sd	s6,0(sp)
    80001e30:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001e32:	00006597          	auipc	a1,0x6
    80001e36:	3ce58593          	addi	a1,a1,974 # 80008200 <digits+0x1c0>
    80001e3a:	0000f517          	auipc	a0,0xf
    80001e3e:	46650513          	addi	a0,a0,1126 # 800112a0 <pid_lock>
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	cf0080e7          	jalr	-784(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e4a:	00006597          	auipc	a1,0x6
    80001e4e:	3be58593          	addi	a1,a1,958 # 80008208 <digits+0x1c8>
    80001e52:	0000f517          	auipc	a0,0xf
    80001e56:	46650513          	addi	a0,a0,1126 # 800112b8 <wait_lock>
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	cd8080e7          	jalr	-808(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e62:	00010497          	auipc	s1,0x10
    80001e66:	86e48493          	addi	s1,s1,-1938 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001e6a:	00006b17          	auipc	s6,0x6
    80001e6e:	3aeb0b13          	addi	s6,s6,942 # 80008218 <digits+0x1d8>
      p->kstack = KSTACK((int) (p - proc));
    80001e72:	8aa6                	mv	s5,s1
    80001e74:	00006a17          	auipc	s4,0x6
    80001e78:	18ca0a13          	addi	s4,s4,396 # 80008000 <etext>
    80001e7c:	04000937          	lui	s2,0x4000
    80001e80:	197d                	addi	s2,s2,-1
    80001e82:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e84:	00025997          	auipc	s3,0x25
    80001e88:	64c98993          	addi	s3,s3,1612 # 800274d0 <tickslock>
      initlock(&p->lock, "proc");
    80001e8c:	85da                	mv	a1,s6
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	ca2080e7          	jalr	-862(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001e98:	415487b3          	sub	a5,s1,s5
    80001e9c:	878d                	srai	a5,a5,0x3
    80001e9e:	000a3703          	ld	a4,0(s4)
    80001ea2:	02e787b3          	mul	a5,a5,a4
    80001ea6:	2785                	addiw	a5,a5,1
    80001ea8:	00d7979b          	slliw	a5,a5,0xd
    80001eac:	40f907b3          	sub	a5,s2,a5
    80001eb0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb2:	57848493          	addi	s1,s1,1400
    80001eb6:	fd349be3          	bne	s1,s3,80001e8c <procinit+0x6e>
  }
}
    80001eba:	70e2                	ld	ra,56(sp)
    80001ebc:	7442                	ld	s0,48(sp)
    80001ebe:	74a2                	ld	s1,40(sp)
    80001ec0:	7902                	ld	s2,32(sp)
    80001ec2:	69e2                	ld	s3,24(sp)
    80001ec4:	6a42                	ld	s4,16(sp)
    80001ec6:	6aa2                	ld	s5,8(sp)
    80001ec8:	6b02                	ld	s6,0(sp)
    80001eca:	6121                	addi	sp,sp,64
    80001ecc:	8082                	ret

0000000080001ece <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ece:	1141                	addi	sp,sp,-16
    80001ed0:	e422                	sd	s0,8(sp)
    80001ed2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ed4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ed6:	2501                	sext.w	a0,a0
    80001ed8:	6422                	ld	s0,8(sp)
    80001eda:	0141                	addi	sp,sp,16
    80001edc:	8082                	ret

0000000080001ede <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ede:	1141                	addi	sp,sp,-16
    80001ee0:	e422                	sd	s0,8(sp)
    80001ee2:	0800                	addi	s0,sp,16
    80001ee4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ee6:	2781                	sext.w	a5,a5
    80001ee8:	079e                	slli	a5,a5,0x7
  return c;
}
    80001eea:	0000f517          	auipc	a0,0xf
    80001eee:	3e650513          	addi	a0,a0,998 # 800112d0 <cpus>
    80001ef2:	953e                	add	a0,a0,a5
    80001ef4:	6422                	ld	s0,8(sp)
    80001ef6:	0141                	addi	sp,sp,16
    80001ef8:	8082                	ret

0000000080001efa <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001efa:	1101                	addi	sp,sp,-32
    80001efc:	ec06                	sd	ra,24(sp)
    80001efe:	e822                	sd	s0,16(sp)
    80001f00:	e426                	sd	s1,8(sp)
    80001f02:	1000                	addi	s0,sp,32
  push_off();
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	c72080e7          	jalr	-910(ra) # 80000b76 <push_off>
    80001f0c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f0e:	2781                	sext.w	a5,a5
    80001f10:	079e                	slli	a5,a5,0x7
    80001f12:	0000f717          	auipc	a4,0xf
    80001f16:	38e70713          	addi	a4,a4,910 # 800112a0 <pid_lock>
    80001f1a:	97ba                	add	a5,a5,a4
    80001f1c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cf8080e7          	jalr	-776(ra) # 80000c16 <pop_off>
  return p;
}
    80001f26:	8526                	mv	a0,s1
    80001f28:	60e2                	ld	ra,24(sp)
    80001f2a:	6442                	ld	s0,16(sp)
    80001f2c:	64a2                	ld	s1,8(sp)
    80001f2e:	6105                	addi	sp,sp,32
    80001f30:	8082                	ret

0000000080001f32 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f32:	1141                	addi	sp,sp,-16
    80001f34:	e406                	sd	ra,8(sp)
    80001f36:	e022                	sd	s0,0(sp)
    80001f38:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	fc0080e7          	jalr	-64(ra) # 80001efa <myproc>
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d34080e7          	jalr	-716(ra) # 80000c76 <release>

  if (first) {
    80001f4a:	00007797          	auipc	a5,0x7
    80001f4e:	9267a783          	lw	a5,-1754(a5) # 80008870 <first.1>
    80001f52:	eb89                	bnez	a5,80001f64 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f54:	00001097          	auipc	ra,0x1
    80001f58:	d1a080e7          	jalr	-742(ra) # 80002c6e <usertrapret>
}
    80001f5c:	60a2                	ld	ra,8(sp)
    80001f5e:	6402                	ld	s0,0(sp)
    80001f60:	0141                	addi	sp,sp,16
    80001f62:	8082                	ret
    first = 0;
    80001f64:	00007797          	auipc	a5,0x7
    80001f68:	9007a623          	sw	zero,-1780(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001f6c:	4505                	li	a0,1
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	a58080e7          	jalr	-1448(ra) # 800039c6 <fsinit>
    80001f76:	bff9                	j	80001f54 <forkret+0x22>

0000000080001f78 <allocpid>:
allocpid() {
    80001f78:	1101                	addi	sp,sp,-32
    80001f7a:	ec06                	sd	ra,24(sp)
    80001f7c:	e822                	sd	s0,16(sp)
    80001f7e:	e426                	sd	s1,8(sp)
    80001f80:	e04a                	sd	s2,0(sp)
    80001f82:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001f84:	0000f917          	auipc	s2,0xf
    80001f88:	31c90913          	addi	s2,s2,796 # 800112a0 <pid_lock>
    80001f8c:	854a                	mv	a0,s2
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	c34080e7          	jalr	-972(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001f96:	00007797          	auipc	a5,0x7
    80001f9a:	8de78793          	addi	a5,a5,-1826 # 80008874 <nextpid>
    80001f9e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001fa0:	0014871b          	addiw	a4,s1,1
    80001fa4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001fa6:	854a                	mv	a0,s2
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	cce080e7          	jalr	-818(ra) # 80000c76 <release>
}
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	60e2                	ld	ra,24(sp)
    80001fb4:	6442                	ld	s0,16(sp)
    80001fb6:	64a2                	ld	s1,8(sp)
    80001fb8:	6902                	ld	s2,0(sp)
    80001fba:	6105                	addi	sp,sp,32
    80001fbc:	8082                	ret

0000000080001fbe <proc_pagetable>:
{
    80001fbe:	1101                	addi	sp,sp,-32
    80001fc0:	ec06                	sd	ra,24(sp)
    80001fc2:	e822                	sd	s0,16(sp)
    80001fc4:	e426                	sd	s1,8(sp)
    80001fc6:	e04a                	sd	s2,0(sp)
    80001fc8:	1000                	addi	s0,sp,32
    80001fca:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	3da080e7          	jalr	986(ra) # 800013a6 <uvmcreate>
    80001fd4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001fd6:	c121                	beqz	a0,80002016 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001fd8:	4729                	li	a4,10
    80001fda:	00005697          	auipc	a3,0x5
    80001fde:	02668693          	addi	a3,a3,38 # 80007000 <_trampoline>
    80001fe2:	6605                	lui	a2,0x1
    80001fe4:	040005b7          	lui	a1,0x4000
    80001fe8:	15fd                	addi	a1,a1,-1
    80001fea:	05b2                	slli	a1,a1,0xc
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	0a2080e7          	jalr	162(ra) # 8000108e <mappages>
    80001ff4:	02054863          	bltz	a0,80002024 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ff8:	4719                	li	a4,6
    80001ffa:	05893683          	ld	a3,88(s2)
    80001ffe:	6605                	lui	a2,0x1
    80002000:	020005b7          	lui	a1,0x2000
    80002004:	15fd                	addi	a1,a1,-1
    80002006:	05b6                	slli	a1,a1,0xd
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	084080e7          	jalr	132(ra) # 8000108e <mappages>
    80002012:	02054163          	bltz	a0,80002034 <proc_pagetable+0x76>
}
    80002016:	8526                	mv	a0,s1
    80002018:	60e2                	ld	ra,24(sp)
    8000201a:	6442                	ld	s0,16(sp)
    8000201c:	64a2                	ld	s1,8(sp)
    8000201e:	6902                	ld	s2,0(sp)
    80002020:	6105                	addi	sp,sp,32
    80002022:	8082                	ret
    uvmfree(pagetable, 0);
    80002024:	4581                	li	a1,0
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	4d0080e7          	jalr	1232(ra) # 800014f8 <uvmfree>
    return 0;
    80002030:	4481                	li	s1,0
    80002032:	b7d5                	j	80002016 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002034:	4681                	li	a3,0
    80002036:	4605                	li	a2,1
    80002038:	040005b7          	lui	a1,0x4000
    8000203c:	15fd                	addi	a1,a1,-1
    8000203e:	05b2                	slli	a1,a1,0xc
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	200080e7          	jalr	512(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    8000204a:	4581                	li	a1,0
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	4aa080e7          	jalr	1194(ra) # 800014f8 <uvmfree>
    return 0;
    80002056:	4481                	li	s1,0
    80002058:	bf7d                	j	80002016 <proc_pagetable+0x58>

000000008000205a <proc_freepagetable>:
{
    8000205a:	1101                	addi	sp,sp,-32
    8000205c:	ec06                	sd	ra,24(sp)
    8000205e:	e822                	sd	s0,16(sp)
    80002060:	e426                	sd	s1,8(sp)
    80002062:	e04a                	sd	s2,0(sp)
    80002064:	1000                	addi	s0,sp,32
    80002066:	84aa                	mv	s1,a0
    80002068:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000206a:	4681                	li	a3,0
    8000206c:	4605                	li	a2,1
    8000206e:	040005b7          	lui	a1,0x4000
    80002072:	15fd                	addi	a1,a1,-1
    80002074:	05b2                	slli	a1,a1,0xc
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	1cc080e7          	jalr	460(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000207e:	4681                	li	a3,0
    80002080:	4605                	li	a2,1
    80002082:	020005b7          	lui	a1,0x2000
    80002086:	15fd                	addi	a1,a1,-1
    80002088:	05b6                	slli	a1,a1,0xd
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	1b6080e7          	jalr	438(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80002094:	85ca                	mv	a1,s2
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	460080e7          	jalr	1120(ra) # 800014f8 <uvmfree>
}
    800020a0:	60e2                	ld	ra,24(sp)
    800020a2:	6442                	ld	s0,16(sp)
    800020a4:	64a2                	ld	s1,8(sp)
    800020a6:	6902                	ld	s2,0(sp)
    800020a8:	6105                	addi	sp,sp,32
    800020aa:	8082                	ret

00000000800020ac <freeproc>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
    800020b6:	84aa                	mv	s1,a0
  if(p->trapframe)
    800020b8:	6d28                	ld	a0,88(a0)
    800020ba:	c509                	beqz	a0,800020c4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	91a080e7          	jalr	-1766(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    800020c4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800020c8:	68a8                	ld	a0,80(s1)
    800020ca:	c511                	beqz	a0,800020d6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800020cc:	64ac                	ld	a1,72(s1)
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	f8c080e7          	jalr	-116(ra) # 8000205a <proc_freepagetable>
  if(p->pid > 2){
    800020d6:	5898                	lw	a4,48(s1)
    800020d8:	4789                	li	a5,2
    800020da:	02e7dd63          	bge	a5,a4,80002114 <freeproc+0x68>
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800020de:	17048713          	addi	a4,s1,368
    800020e2:	37048793          	addi	a5,s1,880
    800020e6:	86be                	mv	a3,a5
      pg->state = 0;
    800020e8:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    800020ec:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    800020f0:	00073823          	sd	zero,16(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800020f4:	02070713          	addi	a4,a4,32
    800020f8:	fed718e3          	bne	a4,a3,800020e8 <freeproc+0x3c>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    800020fc:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    80002100:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    80002104:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    80002108:	0007b823          	sd	zero,16(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000210c:	02078793          	addi	a5,a5,32
    80002110:	fee798e3          	bne	a5,a4,80002100 <freeproc+0x54>
  p->pagetable = 0;
    80002114:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002118:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000211c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002120:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002124:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002128:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000212c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002130:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002134:	0004ac23          	sw	zero,24(s1)
  p->num_pages_in_swapfile = 0;
    80002138:	5604aa23          	sw	zero,1396(s1)
  p->num_pages_in_psyc = 0;
    8000213c:	5604a823          	sw	zero,1392(s1)
}
    80002140:	60e2                	ld	ra,24(sp)
    80002142:	6442                	ld	s0,16(sp)
    80002144:	64a2                	ld	s1,8(sp)
    80002146:	6105                	addi	sp,sp,32
    80002148:	8082                	ret

000000008000214a <allocproc>:
{
    8000214a:	1101                	addi	sp,sp,-32
    8000214c:	ec06                	sd	ra,24(sp)
    8000214e:	e822                	sd	s0,16(sp)
    80002150:	e426                	sd	s1,8(sp)
    80002152:	e04a                	sd	s2,0(sp)
    80002154:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	57a48493          	addi	s1,s1,1402 # 800116d0 <proc>
    8000215e:	00025917          	auipc	s2,0x25
    80002162:	37290913          	addi	s2,s2,882 # 800274d0 <tickslock>
    acquire(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a5a080e7          	jalr	-1446(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80002170:	4c9c                	lw	a5,24(s1)
    80002172:	cf81                	beqz	a5,8000218a <allocproc+0x40>
      release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b00080e7          	jalr	-1280(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	57848493          	addi	s1,s1,1400
    80002182:	ff2492e3          	bne	s1,s2,80002166 <allocproc+0x1c>
  return 0;
    80002186:	4481                	li	s1,0
    80002188:	a889                	j	800021da <allocproc+0x90>
  p->pid = allocpid();
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	dee080e7          	jalr	-530(ra) # 80001f78 <allocpid>
    80002192:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002194:	4785                	li	a5,1
    80002196:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	93a080e7          	jalr	-1734(ra) # 80000ad2 <kalloc>
    800021a0:	892a                	mv	s2,a0
    800021a2:	eca8                	sd	a0,88(s1)
    800021a4:	c131                	beqz	a0,800021e8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    800021a6:	8526                	mv	a0,s1
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	e16080e7          	jalr	-490(ra) # 80001fbe <proc_pagetable>
    800021b0:	892a                	mv	s2,a0
    800021b2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800021b4:	c531                	beqz	a0,80002200 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    800021b6:	07000613          	li	a2,112
    800021ba:	4581                	li	a1,0
    800021bc:	06048513          	addi	a0,s1,96
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	afe080e7          	jalr	-1282(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    800021c8:	00000797          	auipc	a5,0x0
    800021cc:	d6a78793          	addi	a5,a5,-662 # 80001f32 <forkret>
    800021d0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800021d2:	60bc                	ld	a5,64(s1)
    800021d4:	6705                	lui	a4,0x1
    800021d6:	97ba                	add	a5,a5,a4
    800021d8:	f4bc                	sd	a5,104(s1)
}
    800021da:	8526                	mv	a0,s1
    800021dc:	60e2                	ld	ra,24(sp)
    800021de:	6442                	ld	s0,16(sp)
    800021e0:	64a2                	ld	s1,8(sp)
    800021e2:	6902                	ld	s2,0(sp)
    800021e4:	6105                	addi	sp,sp,32
    800021e6:	8082                	ret
    freeproc(p);
    800021e8:	8526                	mv	a0,s1
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	ec2080e7          	jalr	-318(ra) # 800020ac <freeproc>
    release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	a82080e7          	jalr	-1406(ra) # 80000c76 <release>
    return 0;
    800021fc:	84ca                	mv	s1,s2
    800021fe:	bff1                	j	800021da <allocproc+0x90>
    freeproc(p);
    80002200:	8526                	mv	a0,s1
    80002202:	00000097          	auipc	ra,0x0
    80002206:	eaa080e7          	jalr	-342(ra) # 800020ac <freeproc>
    release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a6a080e7          	jalr	-1430(ra) # 80000c76 <release>
    return 0;
    80002214:	84ca                	mv	s1,s2
    80002216:	b7d1                	j	800021da <allocproc+0x90>

0000000080002218 <userinit>:
{
    80002218:	1101                	addi	sp,sp,-32
    8000221a:	ec06                	sd	ra,24(sp)
    8000221c:	e822                	sd	s0,16(sp)
    8000221e:	e426                	sd	s1,8(sp)
    80002220:	1000                	addi	s0,sp,32
  p = allocproc();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	f28080e7          	jalr	-216(ra) # 8000214a <allocproc>
    8000222a:	84aa                	mv	s1,a0
  initproc = p;
    8000222c:	00007797          	auipc	a5,0x7
    80002230:	dea7be23          	sd	a0,-516(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002234:	03400613          	li	a2,52
    80002238:	00006597          	auipc	a1,0x6
    8000223c:	64858593          	addi	a1,a1,1608 # 80008880 <initcode>
    80002240:	6928                	ld	a0,80(a0)
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	192080e7          	jalr	402(ra) # 800013d4 <uvminit>
  p->sz = PGSIZE;
    8000224a:	6785                	lui	a5,0x1
    8000224c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000224e:	6cb8                	ld	a4,88(s1)
    80002250:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002254:	6cb8                	ld	a4,88(s1)
    80002256:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002258:	4641                	li	a2,16
    8000225a:	00006597          	auipc	a1,0x6
    8000225e:	fc658593          	addi	a1,a1,-58 # 80008220 <digits+0x1e0>
    80002262:	15848513          	addi	a0,s1,344
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	baa080e7          	jalr	-1110(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	fc250513          	addi	a0,a0,-62 # 80008230 <digits+0x1f0>
    80002276:	00002097          	auipc	ra,0x2
    8000227a:	17e080e7          	jalr	382(ra) # 800043f4 <namei>
    8000227e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002282:	478d                	li	a5,3
    80002284:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	9ee080e7          	jalr	-1554(ra) # 80000c76 <release>
}
    80002290:	60e2                	ld	ra,24(sp)
    80002292:	6442                	ld	s0,16(sp)
    80002294:	64a2                	ld	s1,8(sp)
    80002296:	6105                	addi	sp,sp,32
    80002298:	8082                	ret

000000008000229a <growproc>:
{
    8000229a:	1101                	addi	sp,sp,-32
    8000229c:	ec06                	sd	ra,24(sp)
    8000229e:	e822                	sd	s0,16(sp)
    800022a0:	e426                	sd	s1,8(sp)
    800022a2:	e04a                	sd	s2,0(sp)
    800022a4:	1000                	addi	s0,sp,32
    800022a6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	c52080e7          	jalr	-942(ra) # 80001efa <myproc>
    800022b0:	892a                	mv	s2,a0
  sz = p->sz;
    800022b2:	652c                	ld	a1,72(a0)
    800022b4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800022b8:	00904f63          	bgtz	s1,800022d6 <growproc+0x3c>
  } else if(n < 0){
    800022bc:	0204cc63          	bltz	s1,800022f4 <growproc+0x5a>
  p->sz = sz;
    800022c0:	1602                	slli	a2,a2,0x20
    800022c2:	9201                	srli	a2,a2,0x20
    800022c4:	04c93423          	sd	a2,72(s2)
  return 0;
    800022c8:	4501                	li	a0,0
}
    800022ca:	60e2                	ld	ra,24(sp)
    800022cc:	6442                	ld	s0,16(sp)
    800022ce:	64a2                	ld	s1,8(sp)
    800022d0:	6902                	ld	s2,0(sp)
    800022d2:	6105                	addi	sp,sp,32
    800022d4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800022d6:	9e25                	addw	a2,a2,s1
    800022d8:	1602                	slli	a2,a2,0x20
    800022da:	9201                	srli	a2,a2,0x20
    800022dc:	1582                	slli	a1,a1,0x20
    800022de:	9181                	srli	a1,a1,0x20
    800022e0:	6928                	ld	a0,80(a0)
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	8b8080e7          	jalr	-1864(ra) # 80001b9a <uvmalloc>
    800022ea:	0005061b          	sext.w	a2,a0
    800022ee:	fa69                	bnez	a2,800022c0 <growproc+0x26>
      return -1;
    800022f0:	557d                	li	a0,-1
    800022f2:	bfe1                	j	800022ca <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022f4:	9e25                	addw	a2,a2,s1
    800022f6:	1602                	slli	a2,a2,0x20
    800022f8:	9201                	srli	a2,a2,0x20
    800022fa:	1582                	slli	a1,a1,0x20
    800022fc:	9181                	srli	a1,a1,0x20
    800022fe:	6928                	ld	a0,80(a0)
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	146080e7          	jalr	326(ra) # 80001446 <uvmdealloc>
    80002308:	0005061b          	sext.w	a2,a0
    8000230c:	bf55                	j	800022c0 <growproc+0x26>

000000008000230e <fork>:
{
    8000230e:	715d                	addi	sp,sp,-80
    80002310:	e486                	sd	ra,72(sp)
    80002312:	e0a2                	sd	s0,64(sp)
    80002314:	fc26                	sd	s1,56(sp)
    80002316:	f84a                	sd	s2,48(sp)
    80002318:	f44e                	sd	s3,40(sp)
    8000231a:	f052                	sd	s4,32(sp)
    8000231c:	ec56                	sd	s5,24(sp)
    8000231e:	e85a                	sd	s6,16(sp)
    80002320:	e45e                	sd	s7,8(sp)
    80002322:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	bd6080e7          	jalr	-1066(ra) # 80001efa <myproc>
    8000232c:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	e1c080e7          	jalr	-484(ra) # 8000214a <allocproc>
    80002336:	1c050163          	beqz	a0,800024f8 <fork+0x1ea>
    8000233a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000233c:	048a3603          	ld	a2,72(s4)
    80002340:	692c                	ld	a1,80(a0)
    80002342:	050a3503          	ld	a0,80(s4)
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	1ea080e7          	jalr	490(ra) # 80001530 <uvmcopy>
    8000234e:	04054863          	bltz	a0,8000239e <fork+0x90>
  np->sz = p->sz;
    80002352:	048a3783          	ld	a5,72(s4)
    80002356:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    8000235a:	058a3683          	ld	a3,88(s4)
    8000235e:	87b6                	mv	a5,a3
    80002360:	0589b703          	ld	a4,88(s3)
    80002364:	12068693          	addi	a3,a3,288
    80002368:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000236c:	6788                	ld	a0,8(a5)
    8000236e:	6b8c                	ld	a1,16(a5)
    80002370:	6f90                	ld	a2,24(a5)
    80002372:	01073023          	sd	a6,0(a4)
    80002376:	e708                	sd	a0,8(a4)
    80002378:	eb0c                	sd	a1,16(a4)
    8000237a:	ef10                	sd	a2,24(a4)
    8000237c:	02078793          	addi	a5,a5,32
    80002380:	02070713          	addi	a4,a4,32
    80002384:	fed792e3          	bne	a5,a3,80002368 <fork+0x5a>
  np->trapframe->a0 = 0;
    80002388:	0589b783          	ld	a5,88(s3)
    8000238c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002390:	0d0a0493          	addi	s1,s4,208
    80002394:	0d098913          	addi	s2,s3,208
    80002398:	150a0a93          	addi	s5,s4,336
    8000239c:	a00d                	j	800023be <fork+0xb0>
    freeproc(np);
    8000239e:	854e                	mv	a0,s3
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	d0c080e7          	jalr	-756(ra) # 800020ac <freeproc>
    release(&np->lock);
    800023a8:	854e                	mv	a0,s3
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8cc080e7          	jalr	-1844(ra) # 80000c76 <release>
    return -1;
    800023b2:	5afd                	li	s5,-1
    800023b4:	a205                	j	800024d4 <fork+0x1c6>
  for(i = 0; i < NOFILE; i++)
    800023b6:	04a1                	addi	s1,s1,8
    800023b8:	0921                	addi	s2,s2,8
    800023ba:	01548b63          	beq	s1,s5,800023d0 <fork+0xc2>
    if(p->ofile[i])
    800023be:	6088                	ld	a0,0(s1)
    800023c0:	d97d                	beqz	a0,800023b6 <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    800023c2:	00003097          	auipc	ra,0x3
    800023c6:	9de080e7          	jalr	-1570(ra) # 80004da0 <filedup>
    800023ca:	00a93023          	sd	a0,0(s2)
    800023ce:	b7e5                	j	800023b6 <fork+0xa8>
  np->cwd = idup(p->cwd);
    800023d0:	150a3503          	ld	a0,336(s4)
    800023d4:	00002097          	auipc	ra,0x2
    800023d8:	82c080e7          	jalr	-2004(ra) # 80003c00 <idup>
    800023dc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023e0:	4641                	li	a2,16
    800023e2:	158a0593          	addi	a1,s4,344
    800023e6:	15898513          	addi	a0,s3,344
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	a26080e7          	jalr	-1498(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    800023f2:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    800023f6:	854e                	mv	a0,s3
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	87e080e7          	jalr	-1922(ra) # 80000c76 <release>
if(np->pid > 2){
    80002400:	0309a703          	lw	a4,48(s3)
    80002404:	4789                	li	a5,2
    80002406:	0ee7c363          	blt	a5,a4,800024ec <fork+0x1de>
if(p->pid > 2){
    8000240a:	030a2703          	lw	a4,48(s4)
    8000240e:	4789                	li	a5,2
    80002410:	08e7d563          	bge	a5,a4,8000249a <fork+0x18c>
    80002414:	170a0793          	addi	a5,s4,368
    80002418:	17098713          	addi	a4,s3,368
    8000241c:	370a0613          	addi	a2,s4,880
    np->pages_in_memory[i].state = p->pages_in_memory[i].state;
    80002420:	4794                	lw	a3,8(a5)
    80002422:	c714                	sw	a3,8(a4)
    np->pages_in_memory[i].va = p->pages_in_memory[i].va;
    80002424:	6394                	ld	a3,0(a5)
    80002426:	e314                	sd	a3,0(a4)
    np->pages_in_memory[i].age = p->pages_in_memory[i].age;
    80002428:	6b94                	ld	a3,16(a5)
    8000242a:	eb14                	sd	a3,16(a4)
    np->pages_in_swapfile[i].state = p->pages_in_swapfile[i].state;
    8000242c:	2087a683          	lw	a3,520(a5)
    80002430:	20d72423          	sw	a3,520(a4)
    np->pages_in_swapfile[i].va = p->pages_in_swapfile[i].va;
    80002434:	2007b683          	ld	a3,512(a5)
    80002438:	20d73023          	sd	a3,512(a4)
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    8000243c:	02078793          	addi	a5,a5,32
    80002440:	02070713          	addi	a4,a4,32
    80002444:	fcc79ee3          	bne	a5,a2,80002420 <fork+0x112>
  np->num_pages_in_psyc = p->num_pages_in_psyc;
    80002448:	570a2783          	lw	a5,1392(s4)
    8000244c:	56f9a823          	sw	a5,1392(s3)
  np->num_pages_in_swapfile = p->num_pages_in_swapfile;
    80002450:	574a2783          	lw	a5,1396(s4)
    80002454:	56f9aa23          	sw	a5,1396(s3)
  char* buffer = kalloc();
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	67a080e7          	jalr	1658(ra) # 80000ad2 <kalloc>
    80002460:	892a                	mv	s2,a0
    80002462:	4481                	li	s1,0
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    80002464:	6b85                	lui	s7,0x1
    80002466:	6b41                	lui	s6,0x10
    readFromSwapFile(p, buffer, i*PGSIZE, PGSIZE);
    80002468:	6685                	lui	a3,0x1
    8000246a:	8626                	mv	a2,s1
    8000246c:	85ca                	mv	a1,s2
    8000246e:	8552                	mv	a0,s4
    80002470:	00002097          	auipc	ra,0x2
    80002474:	2ac080e7          	jalr	684(ra) # 8000471c <readFromSwapFile>
    writeToSwapFile(np, buffer, i*PGSIZE, PGSIZE);
    80002478:	6685                	lui	a3,0x1
    8000247a:	8626                	mv	a2,s1
    8000247c:	85ca                	mv	a1,s2
    8000247e:	854e                	mv	a0,s3
    80002480:	00002097          	auipc	ra,0x2
    80002484:	278080e7          	jalr	632(ra) # 800046f8 <writeToSwapFile>
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    80002488:	009b84bb          	addw	s1,s7,s1
    8000248c:	fd649ee3          	bne	s1,s6,80002468 <fork+0x15a>
  kfree(buffer);
    80002490:	854a                	mv	a0,s2
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	544080e7          	jalr	1348(ra) # 800009d6 <kfree>
  acquire(&wait_lock);
    8000249a:	0000f497          	auipc	s1,0xf
    8000249e:	e1e48493          	addi	s1,s1,-482 # 800112b8 <wait_lock>
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	71e080e7          	jalr	1822(ra) # 80000bc2 <acquire>
  np->parent = p;
    800024ac:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7c4080e7          	jalr	1988(ra) # 80000c76 <release>
  acquire(&np->lock);
    800024ba:	854e                	mv	a0,s3
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	706080e7          	jalr	1798(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    800024c4:	478d                	li	a5,3
    800024c6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800024ca:	854e                	mv	a0,s3
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7aa080e7          	jalr	1962(ra) # 80000c76 <release>
}
    800024d4:	8556                	mv	a0,s5
    800024d6:	60a6                	ld	ra,72(sp)
    800024d8:	6406                	ld	s0,64(sp)
    800024da:	74e2                	ld	s1,56(sp)
    800024dc:	7942                	ld	s2,48(sp)
    800024de:	79a2                	ld	s3,40(sp)
    800024e0:	7a02                	ld	s4,32(sp)
    800024e2:	6ae2                	ld	s5,24(sp)
    800024e4:	6b42                	ld	s6,16(sp)
    800024e6:	6ba2                	ld	s7,8(sp)
    800024e8:	6161                	addi	sp,sp,80
    800024ea:	8082                	ret
  createSwapFile(np);
    800024ec:	854e                	mv	a0,s3
    800024ee:	00002097          	auipc	ra,0x2
    800024f2:	15a080e7          	jalr	346(ra) # 80004648 <createSwapFile>
    800024f6:	bf11                	j	8000240a <fork+0xfc>
    return -1;
    800024f8:	5afd                	li	s5,-1
    800024fa:	bfe9                	j	800024d4 <fork+0x1c6>

00000000800024fc <scheduler>:
{
    800024fc:	7139                	addi	sp,sp,-64
    800024fe:	fc06                	sd	ra,56(sp)
    80002500:	f822                	sd	s0,48(sp)
    80002502:	f426                	sd	s1,40(sp)
    80002504:	f04a                	sd	s2,32(sp)
    80002506:	ec4e                	sd	s3,24(sp)
    80002508:	e852                	sd	s4,16(sp)
    8000250a:	e456                	sd	s5,8(sp)
    8000250c:	e05a                	sd	s6,0(sp)
    8000250e:	0080                	addi	s0,sp,64
    80002510:	8792                	mv	a5,tp
  int id = r_tp();
    80002512:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002514:	00779a93          	slli	s5,a5,0x7
    80002518:	0000f717          	auipc	a4,0xf
    8000251c:	d8870713          	addi	a4,a4,-632 # 800112a0 <pid_lock>
    80002520:	9756                	add	a4,a4,s5
    80002522:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002526:	0000f717          	auipc	a4,0xf
    8000252a:	db270713          	addi	a4,a4,-590 # 800112d8 <cpus+0x8>
    8000252e:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002530:	498d                	li	s3,3
        p->state = RUNNING;
    80002532:	4b11                	li	s6,4
        c->proc = p;
    80002534:	079e                	slli	a5,a5,0x7
    80002536:	0000fa17          	auipc	s4,0xf
    8000253a:	d6aa0a13          	addi	s4,s4,-662 # 800112a0 <pid_lock>
    8000253e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002540:	00025917          	auipc	s2,0x25
    80002544:	f9090913          	addi	s2,s2,-112 # 800274d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002548:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000254c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002550:	10079073          	csrw	sstatus,a5
    80002554:	0000f497          	auipc	s1,0xf
    80002558:	17c48493          	addi	s1,s1,380 # 800116d0 <proc>
    8000255c:	a811                	j	80002570 <scheduler+0x74>
      release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	716080e7          	jalr	1814(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002568:	57848493          	addi	s1,s1,1400
    8000256c:	fd248ee3          	beq	s1,s2,80002548 <scheduler+0x4c>
      acquire(&p->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	650080e7          	jalr	1616(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    8000257a:	4c9c                	lw	a5,24(s1)
    8000257c:	ff3791e3          	bne	a5,s3,8000255e <scheduler+0x62>
        p->state = RUNNING;
    80002580:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002584:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002588:	06048593          	addi	a1,s1,96
    8000258c:	8556                	mv	a0,s5
    8000258e:	00000097          	auipc	ra,0x0
    80002592:	636080e7          	jalr	1590(ra) # 80002bc4 <swtch>
        c->proc = 0;
    80002596:	020a3823          	sd	zero,48(s4)
    8000259a:	b7d1                	j	8000255e <scheduler+0x62>

000000008000259c <sched>:
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	950080e7          	jalr	-1712(ra) # 80001efa <myproc>
    800025b2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	594080e7          	jalr	1428(ra) # 80000b48 <holding>
    800025bc:	c93d                	beqz	a0,80002632 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025be:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800025c0:	2781                	sext.w	a5,a5
    800025c2:	079e                	slli	a5,a5,0x7
    800025c4:	0000f717          	auipc	a4,0xf
    800025c8:	cdc70713          	addi	a4,a4,-804 # 800112a0 <pid_lock>
    800025cc:	97ba                	add	a5,a5,a4
    800025ce:	0a87a703          	lw	a4,168(a5)
    800025d2:	4785                	li	a5,1
    800025d4:	06f71763          	bne	a4,a5,80002642 <sched+0xa6>
  if(p->state == RUNNING)
    800025d8:	4c98                	lw	a4,24(s1)
    800025da:	4791                	li	a5,4
    800025dc:	06f70b63          	beq	a4,a5,80002652 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025e4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025e6:	efb5                	bnez	a5,80002662 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025e8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025ea:	0000f917          	auipc	s2,0xf
    800025ee:	cb690913          	addi	s2,s2,-842 # 800112a0 <pid_lock>
    800025f2:	2781                	sext.w	a5,a5
    800025f4:	079e                	slli	a5,a5,0x7
    800025f6:	97ca                	add	a5,a5,s2
    800025f8:	0ac7a983          	lw	s3,172(a5)
    800025fc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025fe:	2781                	sext.w	a5,a5
    80002600:	079e                	slli	a5,a5,0x7
    80002602:	0000f597          	auipc	a1,0xf
    80002606:	cd658593          	addi	a1,a1,-810 # 800112d8 <cpus+0x8>
    8000260a:	95be                	add	a1,a1,a5
    8000260c:	06048513          	addi	a0,s1,96
    80002610:	00000097          	auipc	ra,0x0
    80002614:	5b4080e7          	jalr	1460(ra) # 80002bc4 <swtch>
    80002618:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000261a:	2781                	sext.w	a5,a5
    8000261c:	079e                	slli	a5,a5,0x7
    8000261e:	97ca                	add	a5,a5,s2
    80002620:	0b37a623          	sw	s3,172(a5)
}
    80002624:	70a2                	ld	ra,40(sp)
    80002626:	7402                	ld	s0,32(sp)
    80002628:	64e2                	ld	s1,24(sp)
    8000262a:	6942                	ld	s2,16(sp)
    8000262c:	69a2                	ld	s3,8(sp)
    8000262e:	6145                	addi	sp,sp,48
    80002630:	8082                	ret
    panic("sched p->lock");
    80002632:	00006517          	auipc	a0,0x6
    80002636:	c0650513          	addi	a0,a0,-1018 # 80008238 <digits+0x1f8>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	ef0080e7          	jalr	-272(ra) # 8000052a <panic>
    panic("sched locks");
    80002642:	00006517          	auipc	a0,0x6
    80002646:	c0650513          	addi	a0,a0,-1018 # 80008248 <digits+0x208>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	ee0080e7          	jalr	-288(ra) # 8000052a <panic>
    panic("sched running");
    80002652:	00006517          	auipc	a0,0x6
    80002656:	c0650513          	addi	a0,a0,-1018 # 80008258 <digits+0x218>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	ed0080e7          	jalr	-304(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002662:	00006517          	auipc	a0,0x6
    80002666:	c0650513          	addi	a0,a0,-1018 # 80008268 <digits+0x228>
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	ec0080e7          	jalr	-320(ra) # 8000052a <panic>

0000000080002672 <yield>:
{
    80002672:	1101                	addi	sp,sp,-32
    80002674:	ec06                	sd	ra,24(sp)
    80002676:	e822                	sd	s0,16(sp)
    80002678:	e426                	sd	s1,8(sp)
    8000267a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	87e080e7          	jalr	-1922(ra) # 80001efa <myproc>
    80002684:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	53c080e7          	jalr	1340(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000268e:	478d                	li	a5,3
    80002690:	cc9c                	sw	a5,24(s1)
  sched();
    80002692:	00000097          	auipc	ra,0x0
    80002696:	f0a080e7          	jalr	-246(ra) # 8000259c <sched>
  release(&p->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	5da080e7          	jalr	1498(ra) # 80000c76 <release>
}
    800026a4:	60e2                	ld	ra,24(sp)
    800026a6:	6442                	ld	s0,16(sp)
    800026a8:	64a2                	ld	s1,8(sp)
    800026aa:	6105                	addi	sp,sp,32
    800026ac:	8082                	ret

00000000800026ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026ae:	7179                	addi	sp,sp,-48
    800026b0:	f406                	sd	ra,40(sp)
    800026b2:	f022                	sd	s0,32(sp)
    800026b4:	ec26                	sd	s1,24(sp)
    800026b6:	e84a                	sd	s2,16(sp)
    800026b8:	e44e                	sd	s3,8(sp)
    800026ba:	1800                	addi	s0,sp,48
    800026bc:	89aa                	mv	s3,a0
    800026be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	83a080e7          	jalr	-1990(ra) # 80001efa <myproc>
    800026c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	4f8080e7          	jalr	1272(ra) # 80000bc2 <acquire>
  release(lk);
    800026d2:	854a                	mv	a0,s2
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	5a2080e7          	jalr	1442(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800026dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800026e0:	4789                	li	a5,2
    800026e2:	cc9c                	sw	a5,24(s1)

  sched();
    800026e4:	00000097          	auipc	ra,0x0
    800026e8:	eb8080e7          	jalr	-328(ra) # 8000259c <sched>

  // Tidy up.
  p->chan = 0;
    800026ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	584080e7          	jalr	1412(ra) # 80000c76 <release>
  acquire(lk);
    800026fa:	854a                	mv	a0,s2
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	4c6080e7          	jalr	1222(ra) # 80000bc2 <acquire>
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6145                	addi	sp,sp,48
    80002710:	8082                	ret

0000000080002712 <wait>:
{
    80002712:	715d                	addi	sp,sp,-80
    80002714:	e486                	sd	ra,72(sp)
    80002716:	e0a2                	sd	s0,64(sp)
    80002718:	fc26                	sd	s1,56(sp)
    8000271a:	f84a                	sd	s2,48(sp)
    8000271c:	f44e                	sd	s3,40(sp)
    8000271e:	f052                	sd	s4,32(sp)
    80002720:	ec56                	sd	s5,24(sp)
    80002722:	e85a                	sd	s6,16(sp)
    80002724:	e45e                	sd	s7,8(sp)
    80002726:	e062                	sd	s8,0(sp)
    80002728:	0880                	addi	s0,sp,80
    8000272a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000272c:	fffff097          	auipc	ra,0xfffff
    80002730:	7ce080e7          	jalr	1998(ra) # 80001efa <myproc>
    80002734:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002736:	0000f517          	auipc	a0,0xf
    8000273a:	b8250513          	addi	a0,a0,-1150 # 800112b8 <wait_lock>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	484080e7          	jalr	1156(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002746:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002748:	4a15                	li	s4,5
        havekids = 1;
    8000274a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000274c:	00025997          	auipc	s3,0x25
    80002750:	d8498993          	addi	s3,s3,-636 # 800274d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002754:	0000fc17          	auipc	s8,0xf
    80002758:	b64c0c13          	addi	s8,s8,-1180 # 800112b8 <wait_lock>
    havekids = 0;
    8000275c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000275e:	0000f497          	auipc	s1,0xf
    80002762:	f7248493          	addi	s1,s1,-142 # 800116d0 <proc>
    80002766:	a0bd                	j	800027d4 <wait+0xc2>
          pid = np->pid;
    80002768:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000276c:	000b0e63          	beqz	s6,80002788 <wait+0x76>
    80002770:	4691                	li	a3,4
    80002772:	02c48613          	addi	a2,s1,44
    80002776:	85da                	mv	a1,s6
    80002778:	05093503          	ld	a0,80(s2)
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	eec080e7          	jalr	-276(ra) # 80001668 <copyout>
    80002784:	02054563          	bltz	a0,800027ae <wait+0x9c>
          freeproc(np);
    80002788:	8526                	mv	a0,s1
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	922080e7          	jalr	-1758(ra) # 800020ac <freeproc>
          release(&np->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	4e2080e7          	jalr	1250(ra) # 80000c76 <release>
          release(&wait_lock);
    8000279c:	0000f517          	auipc	a0,0xf
    800027a0:	b1c50513          	addi	a0,a0,-1252 # 800112b8 <wait_lock>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4d2080e7          	jalr	1234(ra) # 80000c76 <release>
          return pid;
    800027ac:	a09d                	j	80002812 <wait+0x100>
            release(&np->lock);
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	4c6080e7          	jalr	1222(ra) # 80000c76 <release>
            release(&wait_lock);
    800027b8:	0000f517          	auipc	a0,0xf
    800027bc:	b0050513          	addi	a0,a0,-1280 # 800112b8 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
            return -1;
    800027c8:	59fd                	li	s3,-1
    800027ca:	a0a1                	j	80002812 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	57848493          	addi	s1,s1,1400
    800027d0:	03348463          	beq	s1,s3,800027f8 <wait+0xe6>
      if(np->parent == p){
    800027d4:	7c9c                	ld	a5,56(s1)
    800027d6:	ff279be3          	bne	a5,s2,800027cc <wait+0xba>
        acquire(&np->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	3e6080e7          	jalr	998(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800027e4:	4c9c                	lw	a5,24(s1)
    800027e6:	f94781e3          	beq	a5,s4,80002768 <wait+0x56>
        release(&np->lock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	48a080e7          	jalr	1162(ra) # 80000c76 <release>
        havekids = 1;
    800027f4:	8756                	mv	a4,s5
    800027f6:	bfd9                	j	800027cc <wait+0xba>
    if(!havekids || p->killed){
    800027f8:	c701                	beqz	a4,80002800 <wait+0xee>
    800027fa:	02892783          	lw	a5,40(s2)
    800027fe:	c79d                	beqz	a5,8000282c <wait+0x11a>
      release(&wait_lock);
    80002800:	0000f517          	auipc	a0,0xf
    80002804:	ab850513          	addi	a0,a0,-1352 # 800112b8 <wait_lock>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	46e080e7          	jalr	1134(ra) # 80000c76 <release>
      return -1;
    80002810:	59fd                	li	s3,-1
}
    80002812:	854e                	mv	a0,s3
    80002814:	60a6                	ld	ra,72(sp)
    80002816:	6406                	ld	s0,64(sp)
    80002818:	74e2                	ld	s1,56(sp)
    8000281a:	7942                	ld	s2,48(sp)
    8000281c:	79a2                	ld	s3,40(sp)
    8000281e:	7a02                	ld	s4,32(sp)
    80002820:	6ae2                	ld	s5,24(sp)
    80002822:	6b42                	ld	s6,16(sp)
    80002824:	6ba2                	ld	s7,8(sp)
    80002826:	6c02                	ld	s8,0(sp)
    80002828:	6161                	addi	sp,sp,80
    8000282a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000282c:	85e2                	mv	a1,s8
    8000282e:	854a                	mv	a0,s2
    80002830:	00000097          	auipc	ra,0x0
    80002834:	e7e080e7          	jalr	-386(ra) # 800026ae <sleep>
    havekids = 0;
    80002838:	b715                	j	8000275c <wait+0x4a>

000000008000283a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000283a:	7139                	addi	sp,sp,-64
    8000283c:	fc06                	sd	ra,56(sp)
    8000283e:	f822                	sd	s0,48(sp)
    80002840:	f426                	sd	s1,40(sp)
    80002842:	f04a                	sd	s2,32(sp)
    80002844:	ec4e                	sd	s3,24(sp)
    80002846:	e852                	sd	s4,16(sp)
    80002848:	e456                	sd	s5,8(sp)
    8000284a:	0080                	addi	s0,sp,64
    8000284c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000284e:	0000f497          	auipc	s1,0xf
    80002852:	e8248493          	addi	s1,s1,-382 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002856:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002858:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000285a:	00025917          	auipc	s2,0x25
    8000285e:	c7690913          	addi	s2,s2,-906 # 800274d0 <tickslock>
    80002862:	a811                	j	80002876 <wakeup+0x3c>
      }
      release(&p->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	410080e7          	jalr	1040(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000286e:	57848493          	addi	s1,s1,1400
    80002872:	03248663          	beq	s1,s2,8000289e <wakeup+0x64>
    if(p != myproc()){
    80002876:	fffff097          	auipc	ra,0xfffff
    8000287a:	684080e7          	jalr	1668(ra) # 80001efa <myproc>
    8000287e:	fea488e3          	beq	s1,a0,8000286e <wakeup+0x34>
      acquire(&p->lock);
    80002882:	8526                	mv	a0,s1
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	33e080e7          	jalr	830(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000288c:	4c9c                	lw	a5,24(s1)
    8000288e:	fd379be3          	bne	a5,s3,80002864 <wakeup+0x2a>
    80002892:	709c                	ld	a5,32(s1)
    80002894:	fd4798e3          	bne	a5,s4,80002864 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002898:	0154ac23          	sw	s5,24(s1)
    8000289c:	b7e1                	j	80002864 <wakeup+0x2a>
    }
  }
}
    8000289e:	70e2                	ld	ra,56(sp)
    800028a0:	7442                	ld	s0,48(sp)
    800028a2:	74a2                	ld	s1,40(sp)
    800028a4:	7902                	ld	s2,32(sp)
    800028a6:	69e2                	ld	s3,24(sp)
    800028a8:	6a42                	ld	s4,16(sp)
    800028aa:	6aa2                	ld	s5,8(sp)
    800028ac:	6121                	addi	sp,sp,64
    800028ae:	8082                	ret

00000000800028b0 <reparent>:
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	e052                	sd	s4,0(sp)
    800028be:	1800                	addi	s0,sp,48
    800028c0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c2:	0000f497          	auipc	s1,0xf
    800028c6:	e0e48493          	addi	s1,s1,-498 # 800116d0 <proc>
      pp->parent = initproc;
    800028ca:	00006a17          	auipc	s4,0x6
    800028ce:	75ea0a13          	addi	s4,s4,1886 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028d2:	00025997          	auipc	s3,0x25
    800028d6:	bfe98993          	addi	s3,s3,-1026 # 800274d0 <tickslock>
    800028da:	a029                	j	800028e4 <reparent+0x34>
    800028dc:	57848493          	addi	s1,s1,1400
    800028e0:	01348d63          	beq	s1,s3,800028fa <reparent+0x4a>
    if(pp->parent == p){
    800028e4:	7c9c                	ld	a5,56(s1)
    800028e6:	ff279be3          	bne	a5,s2,800028dc <reparent+0x2c>
      pp->parent = initproc;
    800028ea:	000a3503          	ld	a0,0(s4)
    800028ee:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	f4a080e7          	jalr	-182(ra) # 8000283a <wakeup>
    800028f8:	b7d5                	j	800028dc <reparent+0x2c>
}
    800028fa:	70a2                	ld	ra,40(sp)
    800028fc:	7402                	ld	s0,32(sp)
    800028fe:	64e2                	ld	s1,24(sp)
    80002900:	6942                	ld	s2,16(sp)
    80002902:	69a2                	ld	s3,8(sp)
    80002904:	6a02                	ld	s4,0(sp)
    80002906:	6145                	addi	sp,sp,48
    80002908:	8082                	ret

000000008000290a <exit>:
{
    8000290a:	7179                	addi	sp,sp,-48
    8000290c:	f406                	sd	ra,40(sp)
    8000290e:	f022                	sd	s0,32(sp)
    80002910:	ec26                	sd	s1,24(sp)
    80002912:	e84a                	sd	s2,16(sp)
    80002914:	e44e                	sd	s3,8(sp)
    80002916:	e052                	sd	s4,0(sp)
    80002918:	1800                	addi	s0,sp,48
    8000291a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	5de080e7          	jalr	1502(ra) # 80001efa <myproc>
    80002924:	89aa                	mv	s3,a0
  if(p == initproc)
    80002926:	00006797          	auipc	a5,0x6
    8000292a:	7027b783          	ld	a5,1794(a5) # 80009028 <initproc>
    8000292e:	0d050493          	addi	s1,a0,208
    80002932:	15050913          	addi	s2,a0,336
    80002936:	02a79363          	bne	a5,a0,8000295c <exit+0x52>
    panic("init exiting");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	94650513          	addi	a0,a0,-1722 # 80008280 <digits+0x240>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	be8080e7          	jalr	-1048(ra) # 8000052a <panic>
      fileclose(f);
    8000294a:	00002097          	auipc	ra,0x2
    8000294e:	4a8080e7          	jalr	1192(ra) # 80004df2 <fileclose>
      p->ofile[fd] = 0;
    80002952:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002956:	04a1                	addi	s1,s1,8
    80002958:	01248563          	beq	s1,s2,80002962 <exit+0x58>
    if(p->ofile[fd]){
    8000295c:	6088                	ld	a0,0(s1)
    8000295e:	f575                	bnez	a0,8000294a <exit+0x40>
    80002960:	bfdd                	j	80002956 <exit+0x4c>
  if(p->pid > 2) removeSwapFile(p);
    80002962:	0309a703          	lw	a4,48(s3)
    80002966:	4789                	li	a5,2
    80002968:	08e7c163          	blt	a5,a4,800029ea <exit+0xe0>
  begin_op();
    8000296c:	00002097          	auipc	ra,0x2
    80002970:	fba080e7          	jalr	-70(ra) # 80004926 <begin_op>
  iput(p->cwd);
    80002974:	1509b503          	ld	a0,336(s3)
    80002978:	00001097          	auipc	ra,0x1
    8000297c:	480080e7          	jalr	1152(ra) # 80003df8 <iput>
  end_op();
    80002980:	00002097          	auipc	ra,0x2
    80002984:	026080e7          	jalr	38(ra) # 800049a6 <end_op>
  p->cwd = 0;
    80002988:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000298c:	0000f497          	auipc	s1,0xf
    80002990:	92c48493          	addi	s1,s1,-1748 # 800112b8 <wait_lock>
    80002994:	8526                	mv	a0,s1
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	22c080e7          	jalr	556(ra) # 80000bc2 <acquire>
  reparent(p);
    8000299e:	854e                	mv	a0,s3
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	f10080e7          	jalr	-240(ra) # 800028b0 <reparent>
  wakeup(p->parent);
    800029a8:	0389b503          	ld	a0,56(s3)
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	e8e080e7          	jalr	-370(ra) # 8000283a <wakeup>
  acquire(&p->lock);
    800029b4:	854e                	mv	a0,s3
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	20c080e7          	jalr	524(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800029be:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029c2:	4795                	li	a5,5
    800029c4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800029c8:	8526                	mv	a0,s1
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	2ac080e7          	jalr	684(ra) # 80000c76 <release>
  sched();
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	bca080e7          	jalr	-1078(ra) # 8000259c <sched>
  panic("zombie exit");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	8b650513          	addi	a0,a0,-1866 # 80008290 <digits+0x250>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>
  if(p->pid > 2) removeSwapFile(p);
    800029ea:	854e                	mv	a0,s3
    800029ec:	00002097          	auipc	ra,0x2
    800029f0:	ab4080e7          	jalr	-1356(ra) # 800044a0 <removeSwapFile>
    800029f4:	bfa5                	j	8000296c <exit+0x62>

00000000800029f6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800029f6:	7179                	addi	sp,sp,-48
    800029f8:	f406                	sd	ra,40(sp)
    800029fa:	f022                	sd	s0,32(sp)
    800029fc:	ec26                	sd	s1,24(sp)
    800029fe:	e84a                	sd	s2,16(sp)
    80002a00:	e44e                	sd	s3,8(sp)
    80002a02:	1800                	addi	s0,sp,48
    80002a04:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a06:	0000f497          	auipc	s1,0xf
    80002a0a:	cca48493          	addi	s1,s1,-822 # 800116d0 <proc>
    80002a0e:	00025997          	auipc	s3,0x25
    80002a12:	ac298993          	addi	s3,s3,-1342 # 800274d0 <tickslock>
    acquire(&p->lock);
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	1aa080e7          	jalr	426(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002a20:	589c                	lw	a5,48(s1)
    80002a22:	01278d63          	beq	a5,s2,80002a3c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a26:	8526                	mv	a0,s1
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a30:	57848493          	addi	s1,s1,1400
    80002a34:	ff3491e3          	bne	s1,s3,80002a16 <kill+0x20>
  }
  return -1;
    80002a38:	557d                	li	a0,-1
    80002a3a:	a829                	j	80002a54 <kill+0x5e>
      p->killed = 1;
    80002a3c:	4785                	li	a5,1
    80002a3e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002a40:	4c98                	lw	a4,24(s1)
    80002a42:	4789                	li	a5,2
    80002a44:	00f70f63          	beq	a4,a5,80002a62 <kill+0x6c>
      release(&p->lock);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	22c080e7          	jalr	556(ra) # 80000c76 <release>
      return 0;
    80002a52:	4501                	li	a0,0
}
    80002a54:	70a2                	ld	ra,40(sp)
    80002a56:	7402                	ld	s0,32(sp)
    80002a58:	64e2                	ld	s1,24(sp)
    80002a5a:	6942                	ld	s2,16(sp)
    80002a5c:	69a2                	ld	s3,8(sp)
    80002a5e:	6145                	addi	sp,sp,48
    80002a60:	8082                	ret
        p->state = RUNNABLE;
    80002a62:	478d                	li	a5,3
    80002a64:	cc9c                	sw	a5,24(s1)
    80002a66:	b7cd                	j	80002a48 <kill+0x52>

0000000080002a68 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a68:	7179                	addi	sp,sp,-48
    80002a6a:	f406                	sd	ra,40(sp)
    80002a6c:	f022                	sd	s0,32(sp)
    80002a6e:	ec26                	sd	s1,24(sp)
    80002a70:	e84a                	sd	s2,16(sp)
    80002a72:	e44e                	sd	s3,8(sp)
    80002a74:	e052                	sd	s4,0(sp)
    80002a76:	1800                	addi	s0,sp,48
    80002a78:	84aa                	mv	s1,a0
    80002a7a:	892e                	mv	s2,a1
    80002a7c:	89b2                	mv	s3,a2
    80002a7e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	47a080e7          	jalr	1146(ra) # 80001efa <myproc>
  if(user_dst){
    80002a88:	c08d                	beqz	s1,80002aaa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a8a:	86d2                	mv	a3,s4
    80002a8c:	864e                	mv	a2,s3
    80002a8e:	85ca                	mv	a1,s2
    80002a90:	6928                	ld	a0,80(a0)
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	bd6080e7          	jalr	-1066(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a9a:	70a2                	ld	ra,40(sp)
    80002a9c:	7402                	ld	s0,32(sp)
    80002a9e:	64e2                	ld	s1,24(sp)
    80002aa0:	6942                	ld	s2,16(sp)
    80002aa2:	69a2                	ld	s3,8(sp)
    80002aa4:	6a02                	ld	s4,0(sp)
    80002aa6:	6145                	addi	sp,sp,48
    80002aa8:	8082                	ret
    memmove((char *)dst, src, len);
    80002aaa:	000a061b          	sext.w	a2,s4
    80002aae:	85ce                	mv	a1,s3
    80002ab0:	854a                	mv	a0,s2
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	268080e7          	jalr	616(ra) # 80000d1a <memmove>
    return 0;
    80002aba:	8526                	mv	a0,s1
    80002abc:	bff9                	j	80002a9a <either_copyout+0x32>

0000000080002abe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002abe:	7179                	addi	sp,sp,-48
    80002ac0:	f406                	sd	ra,40(sp)
    80002ac2:	f022                	sd	s0,32(sp)
    80002ac4:	ec26                	sd	s1,24(sp)
    80002ac6:	e84a                	sd	s2,16(sp)
    80002ac8:	e44e                	sd	s3,8(sp)
    80002aca:	e052                	sd	s4,0(sp)
    80002acc:	1800                	addi	s0,sp,48
    80002ace:	892a                	mv	s2,a0
    80002ad0:	84ae                	mv	s1,a1
    80002ad2:	89b2                	mv	s3,a2
    80002ad4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	424080e7          	jalr	1060(ra) # 80001efa <myproc>
  if(user_src){
    80002ade:	c08d                	beqz	s1,80002b00 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002ae0:	86d2                	mv	a3,s4
    80002ae2:	864e                	mv	a2,s3
    80002ae4:	85ca                	mv	a1,s2
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c0c080e7          	jalr	-1012(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002af0:	70a2                	ld	ra,40(sp)
    80002af2:	7402                	ld	s0,32(sp)
    80002af4:	64e2                	ld	s1,24(sp)
    80002af6:	6942                	ld	s2,16(sp)
    80002af8:	69a2                	ld	s3,8(sp)
    80002afa:	6a02                	ld	s4,0(sp)
    80002afc:	6145                	addi	sp,sp,48
    80002afe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b00:	000a061b          	sext.w	a2,s4
    80002b04:	85ce                	mv	a1,s3
    80002b06:	854a                	mv	a0,s2
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	212080e7          	jalr	530(ra) # 80000d1a <memmove>
    return 0;
    80002b10:	8526                	mv	a0,s1
    80002b12:	bff9                	j	80002af0 <either_copyin+0x32>

0000000080002b14 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b14:	715d                	addi	sp,sp,-80
    80002b16:	e486                	sd	ra,72(sp)
    80002b18:	e0a2                	sd	s0,64(sp)
    80002b1a:	fc26                	sd	s1,56(sp)
    80002b1c:	f84a                	sd	s2,48(sp)
    80002b1e:	f44e                	sd	s3,40(sp)
    80002b20:	f052                	sd	s4,32(sp)
    80002b22:	ec56                	sd	s5,24(sp)
    80002b24:	e85a                	sd	s6,16(sp)
    80002b26:	e45e                	sd	s7,8(sp)
    80002b28:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b2a:	00005517          	auipc	a0,0x5
    80002b2e:	59e50513          	addi	a0,a0,1438 # 800080c8 <digits+0x88>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a42080e7          	jalr	-1470(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b3a:	0000f497          	auipc	s1,0xf
    80002b3e:	cee48493          	addi	s1,s1,-786 # 80011828 <proc+0x158>
    80002b42:	00025917          	auipc	s2,0x25
    80002b46:	ae690913          	addi	s2,s2,-1306 # 80027628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b4a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002b4c:	00005997          	auipc	s3,0x5
    80002b50:	75498993          	addi	s3,s3,1876 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002b54:	00005a97          	auipc	s5,0x5
    80002b58:	754a8a93          	addi	s5,s5,1876 # 800082a8 <digits+0x268>
    printf("\n");
    80002b5c:	00005a17          	auipc	s4,0x5
    80002b60:	56ca0a13          	addi	s4,s4,1388 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b64:	00005b97          	auipc	s7,0x5
    80002b68:	77cb8b93          	addi	s7,s7,1916 # 800082e0 <states.0>
    80002b6c:	a00d                	j	80002b8e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b6e:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002b72:	8556                	mv	a0,s5
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	a00080e7          	jalr	-1536(ra) # 80000574 <printf>
    printf("\n");
    80002b7c:	8552                	mv	a0,s4
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	9f6080e7          	jalr	-1546(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b86:	57848493          	addi	s1,s1,1400
    80002b8a:	03248263          	beq	s1,s2,80002bae <procdump+0x9a>
    if(p->state == UNUSED)
    80002b8e:	86a6                	mv	a3,s1
    80002b90:	ec04a783          	lw	a5,-320(s1)
    80002b94:	dbed                	beqz	a5,80002b86 <procdump+0x72>
      state = "???";
    80002b96:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b98:	fcfb6be3          	bltu	s6,a5,80002b6e <procdump+0x5a>
    80002b9c:	02079713          	slli	a4,a5,0x20
    80002ba0:	01d75793          	srli	a5,a4,0x1d
    80002ba4:	97de                	add	a5,a5,s7
    80002ba6:	6390                	ld	a2,0(a5)
    80002ba8:	f279                	bnez	a2,80002b6e <procdump+0x5a>
      state = "???";
    80002baa:	864e                	mv	a2,s3
    80002bac:	b7c9                	j	80002b6e <procdump+0x5a>
  }
}
    80002bae:	60a6                	ld	ra,72(sp)
    80002bb0:	6406                	ld	s0,64(sp)
    80002bb2:	74e2                	ld	s1,56(sp)
    80002bb4:	7942                	ld	s2,48(sp)
    80002bb6:	79a2                	ld	s3,40(sp)
    80002bb8:	7a02                	ld	s4,32(sp)
    80002bba:	6ae2                	ld	s5,24(sp)
    80002bbc:	6b42                	ld	s6,16(sp)
    80002bbe:	6ba2                	ld	s7,8(sp)
    80002bc0:	6161                	addi	sp,sp,80
    80002bc2:	8082                	ret

0000000080002bc4 <swtch>:
    80002bc4:	00153023          	sd	ra,0(a0)
    80002bc8:	00253423          	sd	sp,8(a0)
    80002bcc:	e900                	sd	s0,16(a0)
    80002bce:	ed04                	sd	s1,24(a0)
    80002bd0:	03253023          	sd	s2,32(a0)
    80002bd4:	03353423          	sd	s3,40(a0)
    80002bd8:	03453823          	sd	s4,48(a0)
    80002bdc:	03553c23          	sd	s5,56(a0)
    80002be0:	05653023          	sd	s6,64(a0)
    80002be4:	05753423          	sd	s7,72(a0)
    80002be8:	05853823          	sd	s8,80(a0)
    80002bec:	05953c23          	sd	s9,88(a0)
    80002bf0:	07a53023          	sd	s10,96(a0)
    80002bf4:	07b53423          	sd	s11,104(a0)
    80002bf8:	0005b083          	ld	ra,0(a1)
    80002bfc:	0085b103          	ld	sp,8(a1)
    80002c00:	6980                	ld	s0,16(a1)
    80002c02:	6d84                	ld	s1,24(a1)
    80002c04:	0205b903          	ld	s2,32(a1)
    80002c08:	0285b983          	ld	s3,40(a1)
    80002c0c:	0305ba03          	ld	s4,48(a1)
    80002c10:	0385ba83          	ld	s5,56(a1)
    80002c14:	0405bb03          	ld	s6,64(a1)
    80002c18:	0485bb83          	ld	s7,72(a1)
    80002c1c:	0505bc03          	ld	s8,80(a1)
    80002c20:	0585bc83          	ld	s9,88(a1)
    80002c24:	0605bd03          	ld	s10,96(a1)
    80002c28:	0685bd83          	ld	s11,104(a1)
    80002c2c:	8082                	ret

0000000080002c2e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c2e:	1141                	addi	sp,sp,-16
    80002c30:	e406                	sd	ra,8(sp)
    80002c32:	e022                	sd	s0,0(sp)
    80002c34:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c36:	00005597          	auipc	a1,0x5
    80002c3a:	6da58593          	addi	a1,a1,1754 # 80008310 <states.0+0x30>
    80002c3e:	00025517          	auipc	a0,0x25
    80002c42:	89250513          	addi	a0,a0,-1902 # 800274d0 <tickslock>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	eec080e7          	jalr	-276(ra) # 80000b32 <initlock>
}
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c56:	1141                	addi	sp,sp,-16
    80002c58:	e422                	sd	s0,8(sp)
    80002c5a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5c:	00004797          	auipc	a5,0x4
    80002c60:	a3478793          	addi	a5,a5,-1484 # 80006690 <kernelvec>
    80002c64:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c68:	6422                	ld	s0,8(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e406                	sd	ra,8(sp)
    80002c72:	e022                	sd	s0,0(sp)
    80002c74:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	284080e7          	jalr	644(ra) # 80001efa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c82:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c84:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c88:	00004617          	auipc	a2,0x4
    80002c8c:	37860613          	addi	a2,a2,888 # 80007000 <_trampoline>
    80002c90:	00004697          	auipc	a3,0x4
    80002c94:	37068693          	addi	a3,a3,880 # 80007000 <_trampoline>
    80002c98:	8e91                	sub	a3,a3,a2
    80002c9a:	040007b7          	lui	a5,0x4000
    80002c9e:	17fd                	addi	a5,a5,-1
    80002ca0:	07b2                	slli	a5,a5,0xc
    80002ca2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ca8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002caa:	180026f3          	csrr	a3,satp
    80002cae:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cb0:	6d38                	ld	a4,88(a0)
    80002cb2:	6134                	ld	a3,64(a0)
    80002cb4:	6585                	lui	a1,0x1
    80002cb6:	96ae                	add	a3,a3,a1
    80002cb8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cba:	6d38                	ld	a4,88(a0)
    80002cbc:	00000697          	auipc	a3,0x0
    80002cc0:	14e68693          	addi	a3,a3,334 # 80002e0a <usertrap>
    80002cc4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cc6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cc8:	8692                	mv	a3,tp
    80002cca:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ccc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cd0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cd4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cdc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cde:	6f18                	ld	a4,24(a4)
    80002ce0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ce4:	692c                	ld	a1,80(a0)
    80002ce6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ce8:	00004717          	auipc	a4,0x4
    80002cec:	3a870713          	addi	a4,a4,936 # 80007090 <userret>
    80002cf0:	8f11                	sub	a4,a4,a2
    80002cf2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cf4:	577d                	li	a4,-1
    80002cf6:	177e                	slli	a4,a4,0x3f
    80002cf8:	8dd9                	or	a1,a1,a4
    80002cfa:	02000537          	lui	a0,0x2000
    80002cfe:	157d                	addi	a0,a0,-1
    80002d00:	0536                	slli	a0,a0,0xd
    80002d02:	9782                	jalr	a5
}
    80002d04:	60a2                	ld	ra,8(sp)
    80002d06:	6402                	ld	s0,0(sp)
    80002d08:	0141                	addi	sp,sp,16
    80002d0a:	8082                	ret

0000000080002d0c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d16:	00024497          	auipc	s1,0x24
    80002d1a:	7ba48493          	addi	s1,s1,1978 # 800274d0 <tickslock>
    80002d1e:	8526                	mv	a0,s1
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	ea2080e7          	jalr	-350(ra) # 80000bc2 <acquire>
  ticks++;
    80002d28:	00006517          	auipc	a0,0x6
    80002d2c:	30850513          	addi	a0,a0,776 # 80009030 <ticks>
    80002d30:	411c                	lw	a5,0(a0)
    80002d32:	2785                	addiw	a5,a5,1
    80002d34:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	b04080e7          	jalr	-1276(ra) # 8000283a <wakeup>
  release(&tickslock);
    80002d3e:	8526                	mv	a0,s1
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	f36080e7          	jalr	-202(ra) # 80000c76 <release>
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5c:	142027f3          	csrr	a5,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d60:	0007cc63          	bltz	a5,80002d78 <devintr+0x26>
    w_sip(r_sip() & ~2);

    return 2;
  }
  #ifndef NONE
  else if (scause == 13 || scause == 15){
    80002d64:	9bf5                	andi	a5,a5,-3
    80002d66:	4735                	li	a4,13
    #endif
    return handle_pagefault();
  }
  #endif
  else {
    return 0;
    80002d68:	4501                	li	a0,0
  else if (scause == 13 || scause == 15){
    80002d6a:	08e78b63          	beq	a5,a4,80002e00 <devintr+0xae>
  }
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret
     (scause & 0xff) == 9){
    80002d78:	0ff7f713          	andi	a4,a5,255
  if((scause & 0x8000000000000000L) &&
    80002d7c:	46a5                	li	a3,9
    80002d7e:	00d70963          	beq	a4,a3,80002d90 <devintr+0x3e>
  } else if(scause == 0x8000000000000001L){
    80002d82:	577d                	li	a4,-1
    80002d84:	177e                	slli	a4,a4,0x3f
    80002d86:	0705                	addi	a4,a4,1
    80002d88:	04e78b63          	beq	a5,a4,80002dde <devintr+0x8c>
    return 0;
    80002d8c:	4501                	li	a0,0
    80002d8e:	b7c5                	j	80002d6e <devintr+0x1c>
    int irq = plic_claim();
    80002d90:	00004097          	auipc	ra,0x4
    80002d94:	a08080e7          	jalr	-1528(ra) # 80006798 <plic_claim>
    80002d98:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d9a:	47a9                	li	a5,10
    80002d9c:	02f50763          	beq	a0,a5,80002dca <devintr+0x78>
    } else if(irq == VIRTIO0_IRQ){
    80002da0:	4785                	li	a5,1
    80002da2:	02f50963          	beq	a0,a5,80002dd4 <devintr+0x82>
    return 1;
    80002da6:	4505                	li	a0,1
    } else if(irq){
    80002da8:	d0f9                	beqz	s1,80002d6e <devintr+0x1c>
      printf("unexpected interrupt irq=%d\n", irq);
    80002daa:	85a6                	mv	a1,s1
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	56c50513          	addi	a0,a0,1388 # 80008318 <states.0+0x38>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	7c0080e7          	jalr	1984(ra) # 80000574 <printf>
      plic_complete(irq);
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	00004097          	auipc	ra,0x4
    80002dc2:	9fe080e7          	jalr	-1538(ra) # 800067bc <plic_complete>
    return 1;
    80002dc6:	4505                	li	a0,1
    80002dc8:	b75d                	j	80002d6e <devintr+0x1c>
      uartintr();
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	bbc080e7          	jalr	-1092(ra) # 80000986 <uartintr>
    80002dd2:	b7ed                	j	80002dbc <devintr+0x6a>
      virtio_disk_intr();
    80002dd4:	00004097          	auipc	ra,0x4
    80002dd8:	e7a080e7          	jalr	-390(ra) # 80006c4e <virtio_disk_intr>
    80002ddc:	b7c5                	j	80002dbc <devintr+0x6a>
    if(cpuid() == 0){
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	0f0080e7          	jalr	240(ra) # 80001ece <cpuid>
    80002de6:	c901                	beqz	a0,80002df6 <devintr+0xa4>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002de8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dee:	14479073          	csrw	sip,a5
    return 2;
    80002df2:	4509                	li	a0,2
    80002df4:	bfad                	j	80002d6e <devintr+0x1c>
      clockintr();
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	f16080e7          	jalr	-234(ra) # 80002d0c <clockintr>
    80002dfe:	b7ed                	j	80002de8 <devintr+0x96>
    return handle_pagefault();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	e68080e7          	jalr	-408(ra) # 80001c68 <handle_pagefault>
    80002e08:	b79d                	j	80002d6e <devintr+0x1c>

0000000080002e0a <usertrap>:
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	e04a                	sd	s2,0(sp)
    80002e14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e1a:	1007f793          	andi	a5,a5,256
    80002e1e:	e3ad                	bnez	a5,80002e80 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e20:	00004797          	auipc	a5,0x4
    80002e24:	87078793          	addi	a5,a5,-1936 # 80006690 <kernelvec>
    80002e28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	0ce080e7          	jalr	206(ra) # 80001efa <myproc>
    80002e34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e36:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e38:	14102773          	csrr	a4,sepc
    80002e3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e42:	47a1                	li	a5,8
    80002e44:	04f71c63          	bne	a4,a5,80002e9c <usertrap+0x92>
    if(p->killed)
    80002e48:	551c                	lw	a5,40(a0)
    80002e4a:	e3b9                	bnez	a5,80002e90 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e4c:	6cb8                	ld	a4,88(s1)
    80002e4e:	6f1c                	ld	a5,24(a4)
    80002e50:	0791                	addi	a5,a5,4
    80002e52:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e5c:	10079073          	csrw	sstatus,a5
    syscall();
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	2e0080e7          	jalr	736(ra) # 80003140 <syscall>
  if(p->killed)
    80002e68:	549c                	lw	a5,40(s1)
    80002e6a:	ebc1                	bnez	a5,80002efa <usertrap+0xf0>
  usertrapret();
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	e02080e7          	jalr	-510(ra) # 80002c6e <usertrapret>
}
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	64a2                	ld	s1,8(sp)
    80002e7a:	6902                	ld	s2,0(sp)
    80002e7c:	6105                	addi	sp,sp,32
    80002e7e:	8082                	ret
    panic("usertrap: not from user mode");
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	4b850513          	addi	a0,a0,1208 # 80008338 <states.0+0x58>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	6a2080e7          	jalr	1698(ra) # 8000052a <panic>
      exit(-1);
    80002e90:	557d                	li	a0,-1
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	a78080e7          	jalr	-1416(ra) # 8000290a <exit>
    80002e9a:	bf4d                	j	80002e4c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	eb6080e7          	jalr	-330(ra) # 80002d52 <devintr>
    80002ea4:	892a                	mv	s2,a0
    80002ea6:	c501                	beqz	a0,80002eae <usertrap+0xa4>
  if(p->killed)
    80002ea8:	549c                	lw	a5,40(s1)
    80002eaa:	c3a1                	beqz	a5,80002eea <usertrap+0xe0>
    80002eac:	a815                	j	80002ee0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eae:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002eb2:	5890                	lw	a2,48(s1)
    80002eb4:	00005517          	auipc	a0,0x5
    80002eb8:	4a450513          	addi	a0,a0,1188 # 80008358 <states.0+0x78>
    80002ebc:	ffffd097          	auipc	ra,0xffffd
    80002ec0:	6b8080e7          	jalr	1720(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ec8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	4bc50513          	addi	a0,a0,1212 # 80008388 <states.0+0xa8>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	6a0080e7          	jalr	1696(ra) # 80000574 <printf>
    p->killed = 1;
    80002edc:	4785                	li	a5,1
    80002ede:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ee0:	557d                	li	a0,-1
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	a28080e7          	jalr	-1496(ra) # 8000290a <exit>
  if(which_dev == 2)
    80002eea:	4789                	li	a5,2
    80002eec:	f8f910e3          	bne	s2,a5,80002e6c <usertrap+0x62>
    yield();
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	782080e7          	jalr	1922(ra) # 80002672 <yield>
    80002ef8:	bf95                	j	80002e6c <usertrap+0x62>
  int which_dev = 0;
    80002efa:	4901                	li	s2,0
    80002efc:	b7d5                	j	80002ee0 <usertrap+0xd6>

0000000080002efe <kerneltrap>:
{
    80002efe:	7179                	addi	sp,sp,-48
    80002f00:	f406                	sd	ra,40(sp)
    80002f02:	f022                	sd	s0,32(sp)
    80002f04:	ec26                	sd	s1,24(sp)
    80002f06:	e84a                	sd	s2,16(sp)
    80002f08:	e44e                	sd	s3,8(sp)
    80002f0a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f0c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f10:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f14:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f18:	1004f793          	andi	a5,s1,256
    80002f1c:	cb85                	beqz	a5,80002f4c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f22:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f24:	ef85                	bnez	a5,80002f5c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	e2c080e7          	jalr	-468(ra) # 80002d52 <devintr>
    80002f2e:	cd1d                	beqz	a0,80002f6c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f30:	4789                	li	a5,2
    80002f32:	06f50a63          	beq	a0,a5,80002fa6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f36:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f3a:	10049073          	csrw	sstatus,s1
}
    80002f3e:	70a2                	ld	ra,40(sp)
    80002f40:	7402                	ld	s0,32(sp)
    80002f42:	64e2                	ld	s1,24(sp)
    80002f44:	6942                	ld	s2,16(sp)
    80002f46:	69a2                	ld	s3,8(sp)
    80002f48:	6145                	addi	sp,sp,48
    80002f4a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	45c50513          	addi	a0,a0,1116 # 800083a8 <states.0+0xc8>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5d6080e7          	jalr	1494(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002f5c:	00005517          	auipc	a0,0x5
    80002f60:	47450513          	addi	a0,a0,1140 # 800083d0 <states.0+0xf0>
    80002f64:	ffffd097          	auipc	ra,0xffffd
    80002f68:	5c6080e7          	jalr	1478(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002f6c:	85ce                	mv	a1,s3
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	48250513          	addi	a0,a0,1154 # 800083f0 <states.0+0x110>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	5fe080e7          	jalr	1534(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f82:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f86:	00005517          	auipc	a0,0x5
    80002f8a:	47a50513          	addi	a0,a0,1146 # 80008400 <states.0+0x120>
    80002f8e:	ffffd097          	auipc	ra,0xffffd
    80002f92:	5e6080e7          	jalr	1510(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002f96:	00005517          	auipc	a0,0x5
    80002f9a:	48250513          	addi	a0,a0,1154 # 80008418 <states.0+0x138>
    80002f9e:	ffffd097          	auipc	ra,0xffffd
    80002fa2:	58c080e7          	jalr	1420(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	f54080e7          	jalr	-172(ra) # 80001efa <myproc>
    80002fae:	d541                	beqz	a0,80002f36 <kerneltrap+0x38>
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	f4a080e7          	jalr	-182(ra) # 80001efa <myproc>
    80002fb8:	4d18                	lw	a4,24(a0)
    80002fba:	4791                	li	a5,4
    80002fbc:	f6f71de3          	bne	a4,a5,80002f36 <kerneltrap+0x38>
    yield();
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	6b2080e7          	jalr	1714(ra) # 80002672 <yield>
    80002fc8:	b7bd                	j	80002f36 <kerneltrap+0x38>

0000000080002fca <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	1000                	addi	s0,sp,32
    80002fd4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	f24080e7          	jalr	-220(ra) # 80001efa <myproc>
  switch (n) {
    80002fde:	4795                	li	a5,5
    80002fe0:	0497e163          	bltu	a5,s1,80003022 <argraw+0x58>
    80002fe4:	048a                	slli	s1,s1,0x2
    80002fe6:	00005717          	auipc	a4,0x5
    80002fea:	46a70713          	addi	a4,a4,1130 # 80008450 <states.0+0x170>
    80002fee:	94ba                	add	s1,s1,a4
    80002ff0:	409c                	lw	a5,0(s1)
    80002ff2:	97ba                	add	a5,a5,a4
    80002ff4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ff6:	6d3c                	ld	a5,88(a0)
    80002ff8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret
    return p->trapframe->a1;
    80003004:	6d3c                	ld	a5,88(a0)
    80003006:	7fa8                	ld	a0,120(a5)
    80003008:	bfcd                	j	80002ffa <argraw+0x30>
    return p->trapframe->a2;
    8000300a:	6d3c                	ld	a5,88(a0)
    8000300c:	63c8                	ld	a0,128(a5)
    8000300e:	b7f5                	j	80002ffa <argraw+0x30>
    return p->trapframe->a3;
    80003010:	6d3c                	ld	a5,88(a0)
    80003012:	67c8                	ld	a0,136(a5)
    80003014:	b7dd                	j	80002ffa <argraw+0x30>
    return p->trapframe->a4;
    80003016:	6d3c                	ld	a5,88(a0)
    80003018:	6bc8                	ld	a0,144(a5)
    8000301a:	b7c5                	j	80002ffa <argraw+0x30>
    return p->trapframe->a5;
    8000301c:	6d3c                	ld	a5,88(a0)
    8000301e:	6fc8                	ld	a0,152(a5)
    80003020:	bfe9                	j	80002ffa <argraw+0x30>
  panic("argraw");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	40650513          	addi	a0,a0,1030 # 80008428 <states.0+0x148>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	500080e7          	jalr	1280(ra) # 8000052a <panic>

0000000080003032 <fetchaddr>:
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	e04a                	sd	s2,0(sp)
    8000303c:	1000                	addi	s0,sp,32
    8000303e:	84aa                	mv	s1,a0
    80003040:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	eb8080e7          	jalr	-328(ra) # 80001efa <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000304a:	653c                	ld	a5,72(a0)
    8000304c:	02f4f863          	bgeu	s1,a5,8000307c <fetchaddr+0x4a>
    80003050:	00848713          	addi	a4,s1,8
    80003054:	02e7e663          	bltu	a5,a4,80003080 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003058:	46a1                	li	a3,8
    8000305a:	8626                	mv	a2,s1
    8000305c:	85ca                	mv	a1,s2
    8000305e:	6928                	ld	a0,80(a0)
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	694080e7          	jalr	1684(ra) # 800016f4 <copyin>
    80003068:	00a03533          	snez	a0,a0
    8000306c:	40a00533          	neg	a0,a0
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6902                	ld	s2,0(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret
    return -1;
    8000307c:	557d                	li	a0,-1
    8000307e:	bfcd                	j	80003070 <fetchaddr+0x3e>
    80003080:	557d                	li	a0,-1
    80003082:	b7fd                	j	80003070 <fetchaddr+0x3e>

0000000080003084 <fetchstr>:
{
    80003084:	7179                	addi	sp,sp,-48
    80003086:	f406                	sd	ra,40(sp)
    80003088:	f022                	sd	s0,32(sp)
    8000308a:	ec26                	sd	s1,24(sp)
    8000308c:	e84a                	sd	s2,16(sp)
    8000308e:	e44e                	sd	s3,8(sp)
    80003090:	1800                	addi	s0,sp,48
    80003092:	892a                	mv	s2,a0
    80003094:	84ae                	mv	s1,a1
    80003096:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	e62080e7          	jalr	-414(ra) # 80001efa <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030a0:	86ce                	mv	a3,s3
    800030a2:	864a                	mv	a2,s2
    800030a4:	85a6                	mv	a1,s1
    800030a6:	6928                	ld	a0,80(a0)
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	6da080e7          	jalr	1754(ra) # 80001782 <copyinstr>
  if(err < 0)
    800030b0:	00054763          	bltz	a0,800030be <fetchstr+0x3a>
  return strlen(buf);
    800030b4:	8526                	mv	a0,s1
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	d8c080e7          	jalr	-628(ra) # 80000e42 <strlen>
}
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret

00000000800030cc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030cc:	1101                	addi	sp,sp,-32
    800030ce:	ec06                	sd	ra,24(sp)
    800030d0:	e822                	sd	s0,16(sp)
    800030d2:	e426                	sd	s1,8(sp)
    800030d4:	1000                	addi	s0,sp,32
    800030d6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	ef2080e7          	jalr	-270(ra) # 80002fca <argraw>
    800030e0:	c088                	sw	a0,0(s1)
  return 0;
}
    800030e2:	4501                	li	a0,0
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	e426                	sd	s1,8(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	ed0080e7          	jalr	-304(ra) # 80002fca <argraw>
    80003102:	e088                	sd	a0,0(s1)
  return 0;
}
    80003104:	4501                	li	a0,0
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	64a2                	ld	s1,8(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret

0000000080003110 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	e04a                	sd	s2,0(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84ae                	mv	s1,a1
    8000311e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003120:	00000097          	auipc	ra,0x0
    80003124:	eaa080e7          	jalr	-342(ra) # 80002fca <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003128:	864a                	mv	a2,s2
    8000312a:	85a6                	mv	a1,s1
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	f58080e7          	jalr	-168(ra) # 80003084 <fetchstr>
}
    80003134:	60e2                	ld	ra,24(sp)
    80003136:	6442                	ld	s0,16(sp)
    80003138:	64a2                	ld	s1,8(sp)
    8000313a:	6902                	ld	s2,0(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	e04a                	sd	s2,0(sp)
    8000314a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000314c:	fffff097          	auipc	ra,0xfffff
    80003150:	dae080e7          	jalr	-594(ra) # 80001efa <myproc>
    80003154:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003156:	05853903          	ld	s2,88(a0)
    8000315a:	0a893783          	ld	a5,168(s2)
    8000315e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003162:	37fd                	addiw	a5,a5,-1
    80003164:	4751                	li	a4,20
    80003166:	00f76f63          	bltu	a4,a5,80003184 <syscall+0x44>
    8000316a:	00369713          	slli	a4,a3,0x3
    8000316e:	00005797          	auipc	a5,0x5
    80003172:	2fa78793          	addi	a5,a5,762 # 80008468 <syscalls>
    80003176:	97ba                	add	a5,a5,a4
    80003178:	639c                	ld	a5,0(a5)
    8000317a:	c789                	beqz	a5,80003184 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000317c:	9782                	jalr	a5
    8000317e:	06a93823          	sd	a0,112(s2)
    80003182:	a839                	j	800031a0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003184:	15848613          	addi	a2,s1,344
    80003188:	588c                	lw	a1,48(s1)
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	2a650513          	addi	a0,a0,678 # 80008430 <states.0+0x150>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3e2080e7          	jalr	994(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000319a:	6cbc                	ld	a5,88(s1)
    8000319c:	577d                	li	a4,-1
    8000319e:	fbb8                	sd	a4,112(a5)
  }
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6902                	ld	s2,0(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031b4:	fec40593          	addi	a1,s0,-20
    800031b8:	4501                	li	a0,0
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	f12080e7          	jalr	-238(ra) # 800030cc <argint>
    return -1;
    800031c2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031c4:	00054963          	bltz	a0,800031d6 <sys_exit+0x2a>
  exit(n);
    800031c8:	fec42503          	lw	a0,-20(s0)
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	73e080e7          	jalr	1854(ra) # 8000290a <exit>
  return 0;  // not reached
    800031d4:	4781                	li	a5,0
}
    800031d6:	853e                	mv	a0,a5
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret

00000000800031e0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031e0:	1141                	addi	sp,sp,-16
    800031e2:	e406                	sd	ra,8(sp)
    800031e4:	e022                	sd	s0,0(sp)
    800031e6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031e8:	fffff097          	auipc	ra,0xfffff
    800031ec:	d12080e7          	jalr	-750(ra) # 80001efa <myproc>
}
    800031f0:	5908                	lw	a0,48(a0)
    800031f2:	60a2                	ld	ra,8(sp)
    800031f4:	6402                	ld	s0,0(sp)
    800031f6:	0141                	addi	sp,sp,16
    800031f8:	8082                	ret

00000000800031fa <sys_fork>:

uint64
sys_fork(void)
{
    800031fa:	1141                	addi	sp,sp,-16
    800031fc:	e406                	sd	ra,8(sp)
    800031fe:	e022                	sd	s0,0(sp)
    80003200:	0800                	addi	s0,sp,16
  return fork();
    80003202:	fffff097          	auipc	ra,0xfffff
    80003206:	10c080e7          	jalr	268(ra) # 8000230e <fork>
}
    8000320a:	60a2                	ld	ra,8(sp)
    8000320c:	6402                	ld	s0,0(sp)
    8000320e:	0141                	addi	sp,sp,16
    80003210:	8082                	ret

0000000080003212 <sys_wait>:

uint64
sys_wait(void)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000321a:	fe840593          	addi	a1,s0,-24
    8000321e:	4501                	li	a0,0
    80003220:	00000097          	auipc	ra,0x0
    80003224:	ece080e7          	jalr	-306(ra) # 800030ee <argaddr>
    80003228:	87aa                	mv	a5,a0
    return -1;
    8000322a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000322c:	0007c863          	bltz	a5,8000323c <sys_wait+0x2a>
  return wait(p);
    80003230:	fe843503          	ld	a0,-24(s0)
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	4de080e7          	jalr	1246(ra) # 80002712 <wait>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret

0000000080003244 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003244:	7179                	addi	sp,sp,-48
    80003246:	f406                	sd	ra,40(sp)
    80003248:	f022                	sd	s0,32(sp)
    8000324a:	ec26                	sd	s1,24(sp)
    8000324c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000324e:	fdc40593          	addi	a1,s0,-36
    80003252:	4501                	li	a0,0
    80003254:	00000097          	auipc	ra,0x0
    80003258:	e78080e7          	jalr	-392(ra) # 800030cc <argint>
    return -1;
    8000325c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000325e:	00054f63          	bltz	a0,8000327c <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	c98080e7          	jalr	-872(ra) # 80001efa <myproc>
    8000326a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000326c:	fdc42503          	lw	a0,-36(s0)
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	02a080e7          	jalr	42(ra) # 8000229a <growproc>
    80003278:	00054863          	bltz	a0,80003288 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000327c:	8526                	mv	a0,s1
    8000327e:	70a2                	ld	ra,40(sp)
    80003280:	7402                	ld	s0,32(sp)
    80003282:	64e2                	ld	s1,24(sp)
    80003284:	6145                	addi	sp,sp,48
    80003286:	8082                	ret
    return -1;
    80003288:	54fd                	li	s1,-1
    8000328a:	bfcd                	j	8000327c <sys_sbrk+0x38>

000000008000328c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000328c:	7139                	addi	sp,sp,-64
    8000328e:	fc06                	sd	ra,56(sp)
    80003290:	f822                	sd	s0,48(sp)
    80003292:	f426                	sd	s1,40(sp)
    80003294:	f04a                	sd	s2,32(sp)
    80003296:	ec4e                	sd	s3,24(sp)
    80003298:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000329a:	fcc40593          	addi	a1,s0,-52
    8000329e:	4501                	li	a0,0
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	e2c080e7          	jalr	-468(ra) # 800030cc <argint>
    return -1;
    800032a8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032aa:	06054563          	bltz	a0,80003314 <sys_sleep+0x88>
  acquire(&tickslock);
    800032ae:	00024517          	auipc	a0,0x24
    800032b2:	22250513          	addi	a0,a0,546 # 800274d0 <tickslock>
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	90c080e7          	jalr	-1780(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800032be:	00006917          	auipc	s2,0x6
    800032c2:	d7292903          	lw	s2,-654(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800032c6:	fcc42783          	lw	a5,-52(s0)
    800032ca:	cf85                	beqz	a5,80003302 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032cc:	00024997          	auipc	s3,0x24
    800032d0:	20498993          	addi	s3,s3,516 # 800274d0 <tickslock>
    800032d4:	00006497          	auipc	s1,0x6
    800032d8:	d5c48493          	addi	s1,s1,-676 # 80009030 <ticks>
    if(myproc()->killed){
    800032dc:	fffff097          	auipc	ra,0xfffff
    800032e0:	c1e080e7          	jalr	-994(ra) # 80001efa <myproc>
    800032e4:	551c                	lw	a5,40(a0)
    800032e6:	ef9d                	bnez	a5,80003324 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032e8:	85ce                	mv	a1,s3
    800032ea:	8526                	mv	a0,s1
    800032ec:	fffff097          	auipc	ra,0xfffff
    800032f0:	3c2080e7          	jalr	962(ra) # 800026ae <sleep>
  while(ticks - ticks0 < n){
    800032f4:	409c                	lw	a5,0(s1)
    800032f6:	412787bb          	subw	a5,a5,s2
    800032fa:	fcc42703          	lw	a4,-52(s0)
    800032fe:	fce7efe3          	bltu	a5,a4,800032dc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003302:	00024517          	auipc	a0,0x24
    80003306:	1ce50513          	addi	a0,a0,462 # 800274d0 <tickslock>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	96c080e7          	jalr	-1684(ra) # 80000c76 <release>
  return 0;
    80003312:	4781                	li	a5,0
}
    80003314:	853e                	mv	a0,a5
    80003316:	70e2                	ld	ra,56(sp)
    80003318:	7442                	ld	s0,48(sp)
    8000331a:	74a2                	ld	s1,40(sp)
    8000331c:	7902                	ld	s2,32(sp)
    8000331e:	69e2                	ld	s3,24(sp)
    80003320:	6121                	addi	sp,sp,64
    80003322:	8082                	ret
      release(&tickslock);
    80003324:	00024517          	auipc	a0,0x24
    80003328:	1ac50513          	addi	a0,a0,428 # 800274d0 <tickslock>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	94a080e7          	jalr	-1718(ra) # 80000c76 <release>
      return -1;
    80003334:	57fd                	li	a5,-1
    80003336:	bff9                	j	80003314 <sys_sleep+0x88>

0000000080003338 <sys_kill>:

uint64
sys_kill(void)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003340:	fec40593          	addi	a1,s0,-20
    80003344:	4501                	li	a0,0
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	d86080e7          	jalr	-634(ra) # 800030cc <argint>
    8000334e:	87aa                	mv	a5,a0
    return -1;
    80003350:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003352:	0007c863          	bltz	a5,80003362 <sys_kill+0x2a>
  return kill(pid);
    80003356:	fec42503          	lw	a0,-20(s0)
    8000335a:	fffff097          	auipc	ra,0xfffff
    8000335e:	69c080e7          	jalr	1692(ra) # 800029f6 <kill>
}
    80003362:	60e2                	ld	ra,24(sp)
    80003364:	6442                	ld	s0,16(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003374:	00024517          	auipc	a0,0x24
    80003378:	15c50513          	addi	a0,a0,348 # 800274d0 <tickslock>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	846080e7          	jalr	-1978(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003384:	00006497          	auipc	s1,0x6
    80003388:	cac4a483          	lw	s1,-852(s1) # 80009030 <ticks>
  release(&tickslock);
    8000338c:	00024517          	auipc	a0,0x24
    80003390:	14450513          	addi	a0,a0,324 # 800274d0 <tickslock>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	8e2080e7          	jalr	-1822(ra) # 80000c76 <release>
  return xticks;
}
    8000339c:	02049513          	slli	a0,s1,0x20
    800033a0:	9101                	srli	a0,a0,0x20
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	64a2                	ld	s1,8(sp)
    800033a8:	6105                	addi	sp,sp,32
    800033aa:	8082                	ret

00000000800033ac <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033ac:	7179                	addi	sp,sp,-48
    800033ae:	f406                	sd	ra,40(sp)
    800033b0:	f022                	sd	s0,32(sp)
    800033b2:	ec26                	sd	s1,24(sp)
    800033b4:	e84a                	sd	s2,16(sp)
    800033b6:	e44e                	sd	s3,8(sp)
    800033b8:	e052                	sd	s4,0(sp)
    800033ba:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033bc:	00005597          	auipc	a1,0x5
    800033c0:	15c58593          	addi	a1,a1,348 # 80008518 <syscalls+0xb0>
    800033c4:	00024517          	auipc	a0,0x24
    800033c8:	12450513          	addi	a0,a0,292 # 800274e8 <bcache>
    800033cc:	ffffd097          	auipc	ra,0xffffd
    800033d0:	766080e7          	jalr	1894(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033d4:	0002c797          	auipc	a5,0x2c
    800033d8:	11478793          	addi	a5,a5,276 # 8002f4e8 <bcache+0x8000>
    800033dc:	0002c717          	auipc	a4,0x2c
    800033e0:	37470713          	addi	a4,a4,884 # 8002f750 <bcache+0x8268>
    800033e4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033e8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ec:	00024497          	auipc	s1,0x24
    800033f0:	11448493          	addi	s1,s1,276 # 80027500 <bcache+0x18>
    b->next = bcache.head.next;
    800033f4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033f6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033f8:	00005a17          	auipc	s4,0x5
    800033fc:	128a0a13          	addi	s4,s4,296 # 80008520 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003400:	2b893783          	ld	a5,696(s2)
    80003404:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003406:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000340a:	85d2                	mv	a1,s4
    8000340c:	01048513          	addi	a0,s1,16
    80003410:	00001097          	auipc	ra,0x1
    80003414:	7d4080e7          	jalr	2004(ra) # 80004be4 <initsleeplock>
    bcache.head.next->prev = b;
    80003418:	2b893783          	ld	a5,696(s2)
    8000341c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000341e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003422:	45848493          	addi	s1,s1,1112
    80003426:	fd349de3          	bne	s1,s3,80003400 <binit+0x54>
  }
}
    8000342a:	70a2                	ld	ra,40(sp)
    8000342c:	7402                	ld	s0,32(sp)
    8000342e:	64e2                	ld	s1,24(sp)
    80003430:	6942                	ld	s2,16(sp)
    80003432:	69a2                	ld	s3,8(sp)
    80003434:	6a02                	ld	s4,0(sp)
    80003436:	6145                	addi	sp,sp,48
    80003438:	8082                	ret

000000008000343a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	1800                	addi	s0,sp,48
    80003448:	892a                	mv	s2,a0
    8000344a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000344c:	00024517          	auipc	a0,0x24
    80003450:	09c50513          	addi	a0,a0,156 # 800274e8 <bcache>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	76e080e7          	jalr	1902(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000345c:	0002c497          	auipc	s1,0x2c
    80003460:	3444b483          	ld	s1,836(s1) # 8002f7a0 <bcache+0x82b8>
    80003464:	0002c797          	auipc	a5,0x2c
    80003468:	2ec78793          	addi	a5,a5,748 # 8002f750 <bcache+0x8268>
    8000346c:	02f48f63          	beq	s1,a5,800034aa <bread+0x70>
    80003470:	873e                	mv	a4,a5
    80003472:	a021                	j	8000347a <bread+0x40>
    80003474:	68a4                	ld	s1,80(s1)
    80003476:	02e48a63          	beq	s1,a4,800034aa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000347a:	449c                	lw	a5,8(s1)
    8000347c:	ff279ce3          	bne	a5,s2,80003474 <bread+0x3a>
    80003480:	44dc                	lw	a5,12(s1)
    80003482:	ff3799e3          	bne	a5,s3,80003474 <bread+0x3a>
      b->refcnt++;
    80003486:	40bc                	lw	a5,64(s1)
    80003488:	2785                	addiw	a5,a5,1
    8000348a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000348c:	00024517          	auipc	a0,0x24
    80003490:	05c50513          	addi	a0,a0,92 # 800274e8 <bcache>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	7e2080e7          	jalr	2018(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000349c:	01048513          	addi	a0,s1,16
    800034a0:	00001097          	auipc	ra,0x1
    800034a4:	77e080e7          	jalr	1918(ra) # 80004c1e <acquiresleep>
      return b;
    800034a8:	a8b9                	j	80003506 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034aa:	0002c497          	auipc	s1,0x2c
    800034ae:	2ee4b483          	ld	s1,750(s1) # 8002f798 <bcache+0x82b0>
    800034b2:	0002c797          	auipc	a5,0x2c
    800034b6:	29e78793          	addi	a5,a5,670 # 8002f750 <bcache+0x8268>
    800034ba:	00f48863          	beq	s1,a5,800034ca <bread+0x90>
    800034be:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034c0:	40bc                	lw	a5,64(s1)
    800034c2:	cf81                	beqz	a5,800034da <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c4:	64a4                	ld	s1,72(s1)
    800034c6:	fee49de3          	bne	s1,a4,800034c0 <bread+0x86>
  panic("bget: no buffers");
    800034ca:	00005517          	auipc	a0,0x5
    800034ce:	05e50513          	addi	a0,a0,94 # 80008528 <syscalls+0xc0>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	058080e7          	jalr	88(ra) # 8000052a <panic>
      b->dev = dev;
    800034da:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034de:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034e2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034e6:	4785                	li	a5,1
    800034e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034ea:	00024517          	auipc	a0,0x24
    800034ee:	ffe50513          	addi	a0,a0,-2 # 800274e8 <bcache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	784080e7          	jalr	1924(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800034fa:	01048513          	addi	a0,s1,16
    800034fe:	00001097          	auipc	ra,0x1
    80003502:	720080e7          	jalr	1824(ra) # 80004c1e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003506:	409c                	lw	a5,0(s1)
    80003508:	cb89                	beqz	a5,8000351a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000350a:	8526                	mv	a0,s1
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6145                	addi	sp,sp,48
    80003518:	8082                	ret
    virtio_disk_rw(b, 0);
    8000351a:	4581                	li	a1,0
    8000351c:	8526                	mv	a0,s1
    8000351e:	00003097          	auipc	ra,0x3
    80003522:	4a8080e7          	jalr	1192(ra) # 800069c6 <virtio_disk_rw>
    b->valid = 1;
    80003526:	4785                	li	a5,1
    80003528:	c09c                	sw	a5,0(s1)
  return b;
    8000352a:	b7c5                	j	8000350a <bread+0xd0>

000000008000352c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000352c:	1101                	addi	sp,sp,-32
    8000352e:	ec06                	sd	ra,24(sp)
    80003530:	e822                	sd	s0,16(sp)
    80003532:	e426                	sd	s1,8(sp)
    80003534:	1000                	addi	s0,sp,32
    80003536:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003538:	0541                	addi	a0,a0,16
    8000353a:	00001097          	auipc	ra,0x1
    8000353e:	77e080e7          	jalr	1918(ra) # 80004cb8 <holdingsleep>
    80003542:	cd01                	beqz	a0,8000355a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003544:	4585                	li	a1,1
    80003546:	8526                	mv	a0,s1
    80003548:	00003097          	auipc	ra,0x3
    8000354c:	47e080e7          	jalr	1150(ra) # 800069c6 <virtio_disk_rw>
}
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	64a2                	ld	s1,8(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret
    panic("bwrite");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	fe650513          	addi	a0,a0,-26 # 80008540 <syscalls+0xd8>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fc8080e7          	jalr	-56(ra) # 8000052a <panic>

000000008000356a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000356a:	1101                	addi	sp,sp,-32
    8000356c:	ec06                	sd	ra,24(sp)
    8000356e:	e822                	sd	s0,16(sp)
    80003570:	e426                	sd	s1,8(sp)
    80003572:	e04a                	sd	s2,0(sp)
    80003574:	1000                	addi	s0,sp,32
    80003576:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003578:	01050913          	addi	s2,a0,16
    8000357c:	854a                	mv	a0,s2
    8000357e:	00001097          	auipc	ra,0x1
    80003582:	73a080e7          	jalr	1850(ra) # 80004cb8 <holdingsleep>
    80003586:	c92d                	beqz	a0,800035f8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003588:	854a                	mv	a0,s2
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	6ea080e7          	jalr	1770(ra) # 80004c74 <releasesleep>

  acquire(&bcache.lock);
    80003592:	00024517          	auipc	a0,0x24
    80003596:	f5650513          	addi	a0,a0,-170 # 800274e8 <bcache>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	628080e7          	jalr	1576(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800035a2:	40bc                	lw	a5,64(s1)
    800035a4:	37fd                	addiw	a5,a5,-1
    800035a6:	0007871b          	sext.w	a4,a5
    800035aa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035ac:	eb05                	bnez	a4,800035dc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035ae:	68bc                	ld	a5,80(s1)
    800035b0:	64b8                	ld	a4,72(s1)
    800035b2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035b4:	64bc                	ld	a5,72(s1)
    800035b6:	68b8                	ld	a4,80(s1)
    800035b8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035ba:	0002c797          	auipc	a5,0x2c
    800035be:	f2e78793          	addi	a5,a5,-210 # 8002f4e8 <bcache+0x8000>
    800035c2:	2b87b703          	ld	a4,696(a5)
    800035c6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035c8:	0002c717          	auipc	a4,0x2c
    800035cc:	18870713          	addi	a4,a4,392 # 8002f750 <bcache+0x8268>
    800035d0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035d2:	2b87b703          	ld	a4,696(a5)
    800035d6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035d8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035dc:	00024517          	auipc	a0,0x24
    800035e0:	f0c50513          	addi	a0,a0,-244 # 800274e8 <bcache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	692080e7          	jalr	1682(ra) # 80000c76 <release>
}
    800035ec:	60e2                	ld	ra,24(sp)
    800035ee:	6442                	ld	s0,16(sp)
    800035f0:	64a2                	ld	s1,8(sp)
    800035f2:	6902                	ld	s2,0(sp)
    800035f4:	6105                	addi	sp,sp,32
    800035f6:	8082                	ret
    panic("brelse");
    800035f8:	00005517          	auipc	a0,0x5
    800035fc:	f5050513          	addi	a0,a0,-176 # 80008548 <syscalls+0xe0>
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	f2a080e7          	jalr	-214(ra) # 8000052a <panic>

0000000080003608 <bpin>:

void
bpin(struct buf *b) {
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	e426                	sd	s1,8(sp)
    80003610:	1000                	addi	s0,sp,32
    80003612:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003614:	00024517          	auipc	a0,0x24
    80003618:	ed450513          	addi	a0,a0,-300 # 800274e8 <bcache>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	5a6080e7          	jalr	1446(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003624:	40bc                	lw	a5,64(s1)
    80003626:	2785                	addiw	a5,a5,1
    80003628:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000362a:	00024517          	auipc	a0,0x24
    8000362e:	ebe50513          	addi	a0,a0,-322 # 800274e8 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	644080e7          	jalr	1604(ra) # 80000c76 <release>
}
    8000363a:	60e2                	ld	ra,24(sp)
    8000363c:	6442                	ld	s0,16(sp)
    8000363e:	64a2                	ld	s1,8(sp)
    80003640:	6105                	addi	sp,sp,32
    80003642:	8082                	ret

0000000080003644 <bunpin>:

void
bunpin(struct buf *b) {
    80003644:	1101                	addi	sp,sp,-32
    80003646:	ec06                	sd	ra,24(sp)
    80003648:	e822                	sd	s0,16(sp)
    8000364a:	e426                	sd	s1,8(sp)
    8000364c:	1000                	addi	s0,sp,32
    8000364e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003650:	00024517          	auipc	a0,0x24
    80003654:	e9850513          	addi	a0,a0,-360 # 800274e8 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	56a080e7          	jalr	1386(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003660:	40bc                	lw	a5,64(s1)
    80003662:	37fd                	addiw	a5,a5,-1
    80003664:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003666:	00024517          	auipc	a0,0x24
    8000366a:	e8250513          	addi	a0,a0,-382 # 800274e8 <bcache>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	608080e7          	jalr	1544(ra) # 80000c76 <release>
}
    80003676:	60e2                	ld	ra,24(sp)
    80003678:	6442                	ld	s0,16(sp)
    8000367a:	64a2                	ld	s1,8(sp)
    8000367c:	6105                	addi	sp,sp,32
    8000367e:	8082                	ret

0000000080003680 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003680:	1101                	addi	sp,sp,-32
    80003682:	ec06                	sd	ra,24(sp)
    80003684:	e822                	sd	s0,16(sp)
    80003686:	e426                	sd	s1,8(sp)
    80003688:	e04a                	sd	s2,0(sp)
    8000368a:	1000                	addi	s0,sp,32
    8000368c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000368e:	00d5d59b          	srliw	a1,a1,0xd
    80003692:	0002c797          	auipc	a5,0x2c
    80003696:	5327a783          	lw	a5,1330(a5) # 8002fbc4 <sb+0x1c>
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	d9e080e7          	jalr	-610(ra) # 8000343a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036a4:	0074f713          	andi	a4,s1,7
    800036a8:	4785                	li	a5,1
    800036aa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036ae:	14ce                	slli	s1,s1,0x33
    800036b0:	90d9                	srli	s1,s1,0x36
    800036b2:	00950733          	add	a4,a0,s1
    800036b6:	05874703          	lbu	a4,88(a4)
    800036ba:	00e7f6b3          	and	a3,a5,a4
    800036be:	c69d                	beqz	a3,800036ec <bfree+0x6c>
    800036c0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036c2:	94aa                	add	s1,s1,a0
    800036c4:	fff7c793          	not	a5,a5
    800036c8:	8ff9                	and	a5,a5,a4
    800036ca:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	430080e7          	jalr	1072(ra) # 80004afe <log_write>
  brelse(bp);
    800036d6:	854a                	mv	a0,s2
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	e92080e7          	jalr	-366(ra) # 8000356a <brelse>
}
    800036e0:	60e2                	ld	ra,24(sp)
    800036e2:	6442                	ld	s0,16(sp)
    800036e4:	64a2                	ld	s1,8(sp)
    800036e6:	6902                	ld	s2,0(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret
    panic("freeing free block");
    800036ec:	00005517          	auipc	a0,0x5
    800036f0:	e6450513          	addi	a0,a0,-412 # 80008550 <syscalls+0xe8>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	e36080e7          	jalr	-458(ra) # 8000052a <panic>

00000000800036fc <balloc>:
{
    800036fc:	711d                	addi	sp,sp,-96
    800036fe:	ec86                	sd	ra,88(sp)
    80003700:	e8a2                	sd	s0,80(sp)
    80003702:	e4a6                	sd	s1,72(sp)
    80003704:	e0ca                	sd	s2,64(sp)
    80003706:	fc4e                	sd	s3,56(sp)
    80003708:	f852                	sd	s4,48(sp)
    8000370a:	f456                	sd	s5,40(sp)
    8000370c:	f05a                	sd	s6,32(sp)
    8000370e:	ec5e                	sd	s7,24(sp)
    80003710:	e862                	sd	s8,16(sp)
    80003712:	e466                	sd	s9,8(sp)
    80003714:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003716:	0002c797          	auipc	a5,0x2c
    8000371a:	4967a783          	lw	a5,1174(a5) # 8002fbac <sb+0x4>
    8000371e:	cbd1                	beqz	a5,800037b2 <balloc+0xb6>
    80003720:	8baa                	mv	s7,a0
    80003722:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003724:	0002cb17          	auipc	s6,0x2c
    80003728:	484b0b13          	addi	s6,s6,1156 # 8002fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000372e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003730:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003732:	6c89                	lui	s9,0x2
    80003734:	a831                	j	80003750 <balloc+0x54>
    brelse(bp);
    80003736:	854a                	mv	a0,s2
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	e32080e7          	jalr	-462(ra) # 8000356a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003740:	015c87bb          	addw	a5,s9,s5
    80003744:	00078a9b          	sext.w	s5,a5
    80003748:	004b2703          	lw	a4,4(s6)
    8000374c:	06eaf363          	bgeu	s5,a4,800037b2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003750:	41fad79b          	sraiw	a5,s5,0x1f
    80003754:	0137d79b          	srliw	a5,a5,0x13
    80003758:	015787bb          	addw	a5,a5,s5
    8000375c:	40d7d79b          	sraiw	a5,a5,0xd
    80003760:	01cb2583          	lw	a1,28(s6)
    80003764:	9dbd                	addw	a1,a1,a5
    80003766:	855e                	mv	a0,s7
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	cd2080e7          	jalr	-814(ra) # 8000343a <bread>
    80003770:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003772:	004b2503          	lw	a0,4(s6)
    80003776:	000a849b          	sext.w	s1,s5
    8000377a:	8662                	mv	a2,s8
    8000377c:	faa4fde3          	bgeu	s1,a0,80003736 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003780:	41f6579b          	sraiw	a5,a2,0x1f
    80003784:	01d7d69b          	srliw	a3,a5,0x1d
    80003788:	00c6873b          	addw	a4,a3,a2
    8000378c:	00777793          	andi	a5,a4,7
    80003790:	9f95                	subw	a5,a5,a3
    80003792:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003796:	4037571b          	sraiw	a4,a4,0x3
    8000379a:	00e906b3          	add	a3,s2,a4
    8000379e:	0586c683          	lbu	a3,88(a3)
    800037a2:	00d7f5b3          	and	a1,a5,a3
    800037a6:	cd91                	beqz	a1,800037c2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a8:	2605                	addiw	a2,a2,1
    800037aa:	2485                	addiw	s1,s1,1
    800037ac:	fd4618e3          	bne	a2,s4,8000377c <balloc+0x80>
    800037b0:	b759                	j	80003736 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037b2:	00005517          	auipc	a0,0x5
    800037b6:	db650513          	addi	a0,a0,-586 # 80008568 <syscalls+0x100>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	d70080e7          	jalr	-656(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037c2:	974a                	add	a4,a4,s2
    800037c4:	8fd5                	or	a5,a5,a3
    800037c6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	332080e7          	jalr	818(ra) # 80004afe <log_write>
        brelse(bp);
    800037d4:	854a                	mv	a0,s2
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	d94080e7          	jalr	-620(ra) # 8000356a <brelse>
  bp = bread(dev, bno);
    800037de:	85a6                	mv	a1,s1
    800037e0:	855e                	mv	a0,s7
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	c58080e7          	jalr	-936(ra) # 8000343a <bread>
    800037ea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037ec:	40000613          	li	a2,1024
    800037f0:	4581                	li	a1,0
    800037f2:	05850513          	addi	a0,a0,88
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	4c8080e7          	jalr	1224(ra) # 80000cbe <memset>
  log_write(bp);
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	2fe080e7          	jalr	766(ra) # 80004afe <log_write>
  brelse(bp);
    80003808:	854a                	mv	a0,s2
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	d60080e7          	jalr	-672(ra) # 8000356a <brelse>
}
    80003812:	8526                	mv	a0,s1
    80003814:	60e6                	ld	ra,88(sp)
    80003816:	6446                	ld	s0,80(sp)
    80003818:	64a6                	ld	s1,72(sp)
    8000381a:	6906                	ld	s2,64(sp)
    8000381c:	79e2                	ld	s3,56(sp)
    8000381e:	7a42                	ld	s4,48(sp)
    80003820:	7aa2                	ld	s5,40(sp)
    80003822:	7b02                	ld	s6,32(sp)
    80003824:	6be2                	ld	s7,24(sp)
    80003826:	6c42                	ld	s8,16(sp)
    80003828:	6ca2                	ld	s9,8(sp)
    8000382a:	6125                	addi	sp,sp,96
    8000382c:	8082                	ret

000000008000382e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000382e:	7179                	addi	sp,sp,-48
    80003830:	f406                	sd	ra,40(sp)
    80003832:	f022                	sd	s0,32(sp)
    80003834:	ec26                	sd	s1,24(sp)
    80003836:	e84a                	sd	s2,16(sp)
    80003838:	e44e                	sd	s3,8(sp)
    8000383a:	e052                	sd	s4,0(sp)
    8000383c:	1800                	addi	s0,sp,48
    8000383e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003840:	47ad                	li	a5,11
    80003842:	04b7fe63          	bgeu	a5,a1,8000389e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003846:	ff45849b          	addiw	s1,a1,-12
    8000384a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000384e:	0ff00793          	li	a5,255
    80003852:	0ae7e463          	bltu	a5,a4,800038fa <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003856:	08052583          	lw	a1,128(a0)
    8000385a:	c5b5                	beqz	a1,800038c6 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000385c:	00092503          	lw	a0,0(s2)
    80003860:	00000097          	auipc	ra,0x0
    80003864:	bda080e7          	jalr	-1062(ra) # 8000343a <bread>
    80003868:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000386a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000386e:	02049713          	slli	a4,s1,0x20
    80003872:	01e75593          	srli	a1,a4,0x1e
    80003876:	00b784b3          	add	s1,a5,a1
    8000387a:	0004a983          	lw	s3,0(s1)
    8000387e:	04098e63          	beqz	s3,800038da <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003882:	8552                	mv	a0,s4
    80003884:	00000097          	auipc	ra,0x0
    80003888:	ce6080e7          	jalr	-794(ra) # 8000356a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000388c:	854e                	mv	a0,s3
    8000388e:	70a2                	ld	ra,40(sp)
    80003890:	7402                	ld	s0,32(sp)
    80003892:	64e2                	ld	s1,24(sp)
    80003894:	6942                	ld	s2,16(sp)
    80003896:	69a2                	ld	s3,8(sp)
    80003898:	6a02                	ld	s4,0(sp)
    8000389a:	6145                	addi	sp,sp,48
    8000389c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000389e:	02059793          	slli	a5,a1,0x20
    800038a2:	01e7d593          	srli	a1,a5,0x1e
    800038a6:	00b504b3          	add	s1,a0,a1
    800038aa:	0504a983          	lw	s3,80(s1)
    800038ae:	fc099fe3          	bnez	s3,8000388c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038b2:	4108                	lw	a0,0(a0)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e48080e7          	jalr	-440(ra) # 800036fc <balloc>
    800038bc:	0005099b          	sext.w	s3,a0
    800038c0:	0534a823          	sw	s3,80(s1)
    800038c4:	b7e1                	j	8000388c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038c6:	4108                	lw	a0,0(a0)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e34080e7          	jalr	-460(ra) # 800036fc <balloc>
    800038d0:	0005059b          	sext.w	a1,a0
    800038d4:	08b92023          	sw	a1,128(s2)
    800038d8:	b751                	j	8000385c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038da:	00092503          	lw	a0,0(s2)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	e1e080e7          	jalr	-482(ra) # 800036fc <balloc>
    800038e6:	0005099b          	sext.w	s3,a0
    800038ea:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038ee:	8552                	mv	a0,s4
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	20e080e7          	jalr	526(ra) # 80004afe <log_write>
    800038f8:	b769                	j	80003882 <bmap+0x54>
  panic("bmap: out of range");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	c8650513          	addi	a0,a0,-890 # 80008580 <syscalls+0x118>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c28080e7          	jalr	-984(ra) # 8000052a <panic>

000000008000390a <iget>:
{
    8000390a:	7179                	addi	sp,sp,-48
    8000390c:	f406                	sd	ra,40(sp)
    8000390e:	f022                	sd	s0,32(sp)
    80003910:	ec26                	sd	s1,24(sp)
    80003912:	e84a                	sd	s2,16(sp)
    80003914:	e44e                	sd	s3,8(sp)
    80003916:	e052                	sd	s4,0(sp)
    80003918:	1800                	addi	s0,sp,48
    8000391a:	89aa                	mv	s3,a0
    8000391c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000391e:	0002c517          	auipc	a0,0x2c
    80003922:	2aa50513          	addi	a0,a0,682 # 8002fbc8 <itable>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	29c080e7          	jalr	668(ra) # 80000bc2 <acquire>
  empty = 0;
    8000392e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003930:	0002c497          	auipc	s1,0x2c
    80003934:	2b048493          	addi	s1,s1,688 # 8002fbe0 <itable+0x18>
    80003938:	0002e697          	auipc	a3,0x2e
    8000393c:	d3868693          	addi	a3,a3,-712 # 80031670 <log>
    80003940:	a039                	j	8000394e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003942:	02090b63          	beqz	s2,80003978 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003946:	08848493          	addi	s1,s1,136
    8000394a:	02d48a63          	beq	s1,a3,8000397e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000394e:	449c                	lw	a5,8(s1)
    80003950:	fef059e3          	blez	a5,80003942 <iget+0x38>
    80003954:	4098                	lw	a4,0(s1)
    80003956:	ff3716e3          	bne	a4,s3,80003942 <iget+0x38>
    8000395a:	40d8                	lw	a4,4(s1)
    8000395c:	ff4713e3          	bne	a4,s4,80003942 <iget+0x38>
      ip->ref++;
    80003960:	2785                	addiw	a5,a5,1
    80003962:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003964:	0002c517          	auipc	a0,0x2c
    80003968:	26450513          	addi	a0,a0,612 # 8002fbc8 <itable>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	30a080e7          	jalr	778(ra) # 80000c76 <release>
      return ip;
    80003974:	8926                	mv	s2,s1
    80003976:	a03d                	j	800039a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003978:	f7f9                	bnez	a5,80003946 <iget+0x3c>
    8000397a:	8926                	mv	s2,s1
    8000397c:	b7e9                	j	80003946 <iget+0x3c>
  if(empty == 0)
    8000397e:	02090c63          	beqz	s2,800039b6 <iget+0xac>
  ip->dev = dev;
    80003982:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003986:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000398a:	4785                	li	a5,1
    8000398c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003990:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003994:	0002c517          	auipc	a0,0x2c
    80003998:	23450513          	addi	a0,a0,564 # 8002fbc8 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	2da080e7          	jalr	730(ra) # 80000c76 <release>
}
    800039a4:	854a                	mv	a0,s2
    800039a6:	70a2                	ld	ra,40(sp)
    800039a8:	7402                	ld	s0,32(sp)
    800039aa:	64e2                	ld	s1,24(sp)
    800039ac:	6942                	ld	s2,16(sp)
    800039ae:	69a2                	ld	s3,8(sp)
    800039b0:	6a02                	ld	s4,0(sp)
    800039b2:	6145                	addi	sp,sp,48
    800039b4:	8082                	ret
    panic("iget: no inodes");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	be250513          	addi	a0,a0,-1054 # 80008598 <syscalls+0x130>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b6c080e7          	jalr	-1172(ra) # 8000052a <panic>

00000000800039c6 <fsinit>:
fsinit(int dev) {
    800039c6:	7179                	addi	sp,sp,-48
    800039c8:	f406                	sd	ra,40(sp)
    800039ca:	f022                	sd	s0,32(sp)
    800039cc:	ec26                	sd	s1,24(sp)
    800039ce:	e84a                	sd	s2,16(sp)
    800039d0:	e44e                	sd	s3,8(sp)
    800039d2:	1800                	addi	s0,sp,48
    800039d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039d6:	4585                	li	a1,1
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	a62080e7          	jalr	-1438(ra) # 8000343a <bread>
    800039e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039e2:	0002c997          	auipc	s3,0x2c
    800039e6:	1c698993          	addi	s3,s3,454 # 8002fba8 <sb>
    800039ea:	02000613          	li	a2,32
    800039ee:	05850593          	addi	a1,a0,88
    800039f2:	854e                	mv	a0,s3
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	326080e7          	jalr	806(ra) # 80000d1a <memmove>
  brelse(bp);
    800039fc:	8526                	mv	a0,s1
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	b6c080e7          	jalr	-1172(ra) # 8000356a <brelse>
  if(sb.magic != FSMAGIC)
    80003a06:	0009a703          	lw	a4,0(s3)
    80003a0a:	102037b7          	lui	a5,0x10203
    80003a0e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a12:	02f71263          	bne	a4,a5,80003a36 <fsinit+0x70>
  initlog(dev, &sb);
    80003a16:	0002c597          	auipc	a1,0x2c
    80003a1a:	19258593          	addi	a1,a1,402 # 8002fba8 <sb>
    80003a1e:	854a                	mv	a0,s2
    80003a20:	00001097          	auipc	ra,0x1
    80003a24:	e60080e7          	jalr	-416(ra) # 80004880 <initlog>
}
    80003a28:	70a2                	ld	ra,40(sp)
    80003a2a:	7402                	ld	s0,32(sp)
    80003a2c:	64e2                	ld	s1,24(sp)
    80003a2e:	6942                	ld	s2,16(sp)
    80003a30:	69a2                	ld	s3,8(sp)
    80003a32:	6145                	addi	sp,sp,48
    80003a34:	8082                	ret
    panic("invalid file system");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	b7250513          	addi	a0,a0,-1166 # 800085a8 <syscalls+0x140>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	aec080e7          	jalr	-1300(ra) # 8000052a <panic>

0000000080003a46 <iinit>:
{
    80003a46:	7179                	addi	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a54:	00005597          	auipc	a1,0x5
    80003a58:	b6c58593          	addi	a1,a1,-1172 # 800085c0 <syscalls+0x158>
    80003a5c:	0002c517          	auipc	a0,0x2c
    80003a60:	16c50513          	addi	a0,a0,364 # 8002fbc8 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	0ce080e7          	jalr	206(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a6c:	0002c497          	auipc	s1,0x2c
    80003a70:	18448493          	addi	s1,s1,388 # 8002fbf0 <itable+0x28>
    80003a74:	0002e997          	auipc	s3,0x2e
    80003a78:	c0c98993          	addi	s3,s3,-1012 # 80031680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a7c:	00005917          	auipc	s2,0x5
    80003a80:	b4c90913          	addi	s2,s2,-1204 # 800085c8 <syscalls+0x160>
    80003a84:	85ca                	mv	a1,s2
    80003a86:	8526                	mv	a0,s1
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	15c080e7          	jalr	348(ra) # 80004be4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a90:	08848493          	addi	s1,s1,136
    80003a94:	ff3498e3          	bne	s1,s3,80003a84 <iinit+0x3e>
}
    80003a98:	70a2                	ld	ra,40(sp)
    80003a9a:	7402                	ld	s0,32(sp)
    80003a9c:	64e2                	ld	s1,24(sp)
    80003a9e:	6942                	ld	s2,16(sp)
    80003aa0:	69a2                	ld	s3,8(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret

0000000080003aa6 <ialloc>:
{
    80003aa6:	715d                	addi	sp,sp,-80
    80003aa8:	e486                	sd	ra,72(sp)
    80003aaa:	e0a2                	sd	s0,64(sp)
    80003aac:	fc26                	sd	s1,56(sp)
    80003aae:	f84a                	sd	s2,48(sp)
    80003ab0:	f44e                	sd	s3,40(sp)
    80003ab2:	f052                	sd	s4,32(sp)
    80003ab4:	ec56                	sd	s5,24(sp)
    80003ab6:	e85a                	sd	s6,16(sp)
    80003ab8:	e45e                	sd	s7,8(sp)
    80003aba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003abc:	0002c717          	auipc	a4,0x2c
    80003ac0:	0f872703          	lw	a4,248(a4) # 8002fbb4 <sb+0xc>
    80003ac4:	4785                	li	a5,1
    80003ac6:	04e7fa63          	bgeu	a5,a4,80003b1a <ialloc+0x74>
    80003aca:	8aaa                	mv	s5,a0
    80003acc:	8bae                	mv	s7,a1
    80003ace:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ad0:	0002ca17          	auipc	s4,0x2c
    80003ad4:	0d8a0a13          	addi	s4,s4,216 # 8002fba8 <sb>
    80003ad8:	00048b1b          	sext.w	s6,s1
    80003adc:	0044d793          	srli	a5,s1,0x4
    80003ae0:	018a2583          	lw	a1,24(s4)
    80003ae4:	9dbd                	addw	a1,a1,a5
    80003ae6:	8556                	mv	a0,s5
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	952080e7          	jalr	-1710(ra) # 8000343a <bread>
    80003af0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003af2:	05850993          	addi	s3,a0,88
    80003af6:	00f4f793          	andi	a5,s1,15
    80003afa:	079a                	slli	a5,a5,0x6
    80003afc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003afe:	00099783          	lh	a5,0(s3)
    80003b02:	c785                	beqz	a5,80003b2a <ialloc+0x84>
    brelse(bp);
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	a66080e7          	jalr	-1434(ra) # 8000356a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b0c:	0485                	addi	s1,s1,1
    80003b0e:	00ca2703          	lw	a4,12(s4)
    80003b12:	0004879b          	sext.w	a5,s1
    80003b16:	fce7e1e3          	bltu	a5,a4,80003ad8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b1a:	00005517          	auipc	a0,0x5
    80003b1e:	ab650513          	addi	a0,a0,-1354 # 800085d0 <syscalls+0x168>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	a08080e7          	jalr	-1528(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003b2a:	04000613          	li	a2,64
    80003b2e:	4581                	li	a1,0
    80003b30:	854e                	mv	a0,s3
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	18c080e7          	jalr	396(ra) # 80000cbe <memset>
      dip->type = type;
    80003b3a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	fbe080e7          	jalr	-66(ra) # 80004afe <log_write>
      brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	a20080e7          	jalr	-1504(ra) # 8000356a <brelse>
      return iget(dev, inum);
    80003b52:	85da                	mv	a1,s6
    80003b54:	8556                	mv	a0,s5
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	db4080e7          	jalr	-588(ra) # 8000390a <iget>
}
    80003b5e:	60a6                	ld	ra,72(sp)
    80003b60:	6406                	ld	s0,64(sp)
    80003b62:	74e2                	ld	s1,56(sp)
    80003b64:	7942                	ld	s2,48(sp)
    80003b66:	79a2                	ld	s3,40(sp)
    80003b68:	7a02                	ld	s4,32(sp)
    80003b6a:	6ae2                	ld	s5,24(sp)
    80003b6c:	6b42                	ld	s6,16(sp)
    80003b6e:	6ba2                	ld	s7,8(sp)
    80003b70:	6161                	addi	sp,sp,80
    80003b72:	8082                	ret

0000000080003b74 <iupdate>:
{
    80003b74:	1101                	addi	sp,sp,-32
    80003b76:	ec06                	sd	ra,24(sp)
    80003b78:	e822                	sd	s0,16(sp)
    80003b7a:	e426                	sd	s1,8(sp)
    80003b7c:	e04a                	sd	s2,0(sp)
    80003b7e:	1000                	addi	s0,sp,32
    80003b80:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b82:	415c                	lw	a5,4(a0)
    80003b84:	0047d79b          	srliw	a5,a5,0x4
    80003b88:	0002c597          	auipc	a1,0x2c
    80003b8c:	0385a583          	lw	a1,56(a1) # 8002fbc0 <sb+0x18>
    80003b90:	9dbd                	addw	a1,a1,a5
    80003b92:	4108                	lw	a0,0(a0)
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	8a6080e7          	jalr	-1882(ra) # 8000343a <bread>
    80003b9c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b9e:	05850793          	addi	a5,a0,88
    80003ba2:	40c8                	lw	a0,4(s1)
    80003ba4:	893d                	andi	a0,a0,15
    80003ba6:	051a                	slli	a0,a0,0x6
    80003ba8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003baa:	04449703          	lh	a4,68(s1)
    80003bae:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bb2:	04649703          	lh	a4,70(s1)
    80003bb6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bba:	04849703          	lh	a4,72(s1)
    80003bbe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bc2:	04a49703          	lh	a4,74(s1)
    80003bc6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bca:	44f8                	lw	a4,76(s1)
    80003bcc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bce:	03400613          	li	a2,52
    80003bd2:	05048593          	addi	a1,s1,80
    80003bd6:	0531                	addi	a0,a0,12
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	142080e7          	jalr	322(ra) # 80000d1a <memmove>
  log_write(bp);
    80003be0:	854a                	mv	a0,s2
    80003be2:	00001097          	auipc	ra,0x1
    80003be6:	f1c080e7          	jalr	-228(ra) # 80004afe <log_write>
  brelse(bp);
    80003bea:	854a                	mv	a0,s2
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	97e080e7          	jalr	-1666(ra) # 8000356a <brelse>
}
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6902                	ld	s2,0(sp)
    80003bfc:	6105                	addi	sp,sp,32
    80003bfe:	8082                	ret

0000000080003c00 <idup>:
{
    80003c00:	1101                	addi	sp,sp,-32
    80003c02:	ec06                	sd	ra,24(sp)
    80003c04:	e822                	sd	s0,16(sp)
    80003c06:	e426                	sd	s1,8(sp)
    80003c08:	1000                	addi	s0,sp,32
    80003c0a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c0c:	0002c517          	auipc	a0,0x2c
    80003c10:	fbc50513          	addi	a0,a0,-68 # 8002fbc8 <itable>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	fae080e7          	jalr	-82(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003c1c:	449c                	lw	a5,8(s1)
    80003c1e:	2785                	addiw	a5,a5,1
    80003c20:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c22:	0002c517          	auipc	a0,0x2c
    80003c26:	fa650513          	addi	a0,a0,-90 # 8002fbc8 <itable>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	04c080e7          	jalr	76(ra) # 80000c76 <release>
}
    80003c32:	8526                	mv	a0,s1
    80003c34:	60e2                	ld	ra,24(sp)
    80003c36:	6442                	ld	s0,16(sp)
    80003c38:	64a2                	ld	s1,8(sp)
    80003c3a:	6105                	addi	sp,sp,32
    80003c3c:	8082                	ret

0000000080003c3e <ilock>:
{
    80003c3e:	1101                	addi	sp,sp,-32
    80003c40:	ec06                	sd	ra,24(sp)
    80003c42:	e822                	sd	s0,16(sp)
    80003c44:	e426                	sd	s1,8(sp)
    80003c46:	e04a                	sd	s2,0(sp)
    80003c48:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c4a:	c115                	beqz	a0,80003c6e <ilock+0x30>
    80003c4c:	84aa                	mv	s1,a0
    80003c4e:	451c                	lw	a5,8(a0)
    80003c50:	00f05f63          	blez	a5,80003c6e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c54:	0541                	addi	a0,a0,16
    80003c56:	00001097          	auipc	ra,0x1
    80003c5a:	fc8080e7          	jalr	-56(ra) # 80004c1e <acquiresleep>
  if(ip->valid == 0){
    80003c5e:	40bc                	lw	a5,64(s1)
    80003c60:	cf99                	beqz	a5,80003c7e <ilock+0x40>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6902                	ld	s2,0(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret
    panic("ilock");
    80003c6e:	00005517          	auipc	a0,0x5
    80003c72:	97a50513          	addi	a0,a0,-1670 # 800085e8 <syscalls+0x180>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8b4080e7          	jalr	-1868(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c7e:	40dc                	lw	a5,4(s1)
    80003c80:	0047d79b          	srliw	a5,a5,0x4
    80003c84:	0002c597          	auipc	a1,0x2c
    80003c88:	f3c5a583          	lw	a1,-196(a1) # 8002fbc0 <sb+0x18>
    80003c8c:	9dbd                	addw	a1,a1,a5
    80003c8e:	4088                	lw	a0,0(s1)
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	7aa080e7          	jalr	1962(ra) # 8000343a <bread>
    80003c98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c9a:	05850593          	addi	a1,a0,88
    80003c9e:	40dc                	lw	a5,4(s1)
    80003ca0:	8bbd                	andi	a5,a5,15
    80003ca2:	079a                	slli	a5,a5,0x6
    80003ca4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ca6:	00059783          	lh	a5,0(a1)
    80003caa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cae:	00259783          	lh	a5,2(a1)
    80003cb2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cb6:	00459783          	lh	a5,4(a1)
    80003cba:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cbe:	00659783          	lh	a5,6(a1)
    80003cc2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cc6:	459c                	lw	a5,8(a1)
    80003cc8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cca:	03400613          	li	a2,52
    80003cce:	05b1                	addi	a1,a1,12
    80003cd0:	05048513          	addi	a0,s1,80
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	046080e7          	jalr	70(ra) # 80000d1a <memmove>
    brelse(bp);
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	88c080e7          	jalr	-1908(ra) # 8000356a <brelse>
    ip->valid = 1;
    80003ce6:	4785                	li	a5,1
    80003ce8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cea:	04449783          	lh	a5,68(s1)
    80003cee:	fbb5                	bnez	a5,80003c62 <ilock+0x24>
      panic("ilock: no type");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	90050513          	addi	a0,a0,-1792 # 800085f0 <syscalls+0x188>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	832080e7          	jalr	-1998(ra) # 8000052a <panic>

0000000080003d00 <iunlock>:
{
    80003d00:	1101                	addi	sp,sp,-32
    80003d02:	ec06                	sd	ra,24(sp)
    80003d04:	e822                	sd	s0,16(sp)
    80003d06:	e426                	sd	s1,8(sp)
    80003d08:	e04a                	sd	s2,0(sp)
    80003d0a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d0c:	c905                	beqz	a0,80003d3c <iunlock+0x3c>
    80003d0e:	84aa                	mv	s1,a0
    80003d10:	01050913          	addi	s2,a0,16
    80003d14:	854a                	mv	a0,s2
    80003d16:	00001097          	auipc	ra,0x1
    80003d1a:	fa2080e7          	jalr	-94(ra) # 80004cb8 <holdingsleep>
    80003d1e:	cd19                	beqz	a0,80003d3c <iunlock+0x3c>
    80003d20:	449c                	lw	a5,8(s1)
    80003d22:	00f05d63          	blez	a5,80003d3c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d26:	854a                	mv	a0,s2
    80003d28:	00001097          	auipc	ra,0x1
    80003d2c:	f4c080e7          	jalr	-180(ra) # 80004c74 <releasesleep>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret
    panic("iunlock");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	8c450513          	addi	a0,a0,-1852 # 80008600 <syscalls+0x198>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7e6080e7          	jalr	2022(ra) # 8000052a <panic>

0000000080003d4c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d4c:	7179                	addi	sp,sp,-48
    80003d4e:	f406                	sd	ra,40(sp)
    80003d50:	f022                	sd	s0,32(sp)
    80003d52:	ec26                	sd	s1,24(sp)
    80003d54:	e84a                	sd	s2,16(sp)
    80003d56:	e44e                	sd	s3,8(sp)
    80003d58:	e052                	sd	s4,0(sp)
    80003d5a:	1800                	addi	s0,sp,48
    80003d5c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d5e:	05050493          	addi	s1,a0,80
    80003d62:	08050913          	addi	s2,a0,128
    80003d66:	a021                	j	80003d6e <itrunc+0x22>
    80003d68:	0491                	addi	s1,s1,4
    80003d6a:	01248d63          	beq	s1,s2,80003d84 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d6e:	408c                	lw	a1,0(s1)
    80003d70:	dde5                	beqz	a1,80003d68 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d72:	0009a503          	lw	a0,0(s3)
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	90a080e7          	jalr	-1782(ra) # 80003680 <bfree>
      ip->addrs[i] = 0;
    80003d7e:	0004a023          	sw	zero,0(s1)
    80003d82:	b7dd                	j	80003d68 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d84:	0809a583          	lw	a1,128(s3)
    80003d88:	e185                	bnez	a1,80003da8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d8a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d8e:	854e                	mv	a0,s3
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	de4080e7          	jalr	-540(ra) # 80003b74 <iupdate>
}
    80003d98:	70a2                	ld	ra,40(sp)
    80003d9a:	7402                	ld	s0,32(sp)
    80003d9c:	64e2                	ld	s1,24(sp)
    80003d9e:	6942                	ld	s2,16(sp)
    80003da0:	69a2                	ld	s3,8(sp)
    80003da2:	6a02                	ld	s4,0(sp)
    80003da4:	6145                	addi	sp,sp,48
    80003da6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003da8:	0009a503          	lw	a0,0(s3)
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	68e080e7          	jalr	1678(ra) # 8000343a <bread>
    80003db4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003db6:	05850493          	addi	s1,a0,88
    80003dba:	45850913          	addi	s2,a0,1112
    80003dbe:	a021                	j	80003dc6 <itrunc+0x7a>
    80003dc0:	0491                	addi	s1,s1,4
    80003dc2:	01248b63          	beq	s1,s2,80003dd8 <itrunc+0x8c>
      if(a[j])
    80003dc6:	408c                	lw	a1,0(s1)
    80003dc8:	dde5                	beqz	a1,80003dc0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dca:	0009a503          	lw	a0,0(s3)
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	8b2080e7          	jalr	-1870(ra) # 80003680 <bfree>
    80003dd6:	b7ed                	j	80003dc0 <itrunc+0x74>
    brelse(bp);
    80003dd8:	8552                	mv	a0,s4
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	790080e7          	jalr	1936(ra) # 8000356a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003de2:	0809a583          	lw	a1,128(s3)
    80003de6:	0009a503          	lw	a0,0(s3)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	896080e7          	jalr	-1898(ra) # 80003680 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003df2:	0809a023          	sw	zero,128(s3)
    80003df6:	bf51                	j	80003d8a <itrunc+0x3e>

0000000080003df8 <iput>:
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	e426                	sd	s1,8(sp)
    80003e00:	e04a                	sd	s2,0(sp)
    80003e02:	1000                	addi	s0,sp,32
    80003e04:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e06:	0002c517          	auipc	a0,0x2c
    80003e0a:	dc250513          	addi	a0,a0,-574 # 8002fbc8 <itable>
    80003e0e:	ffffd097          	auipc	ra,0xffffd
    80003e12:	db4080e7          	jalr	-588(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e16:	4498                	lw	a4,8(s1)
    80003e18:	4785                	li	a5,1
    80003e1a:	02f70363          	beq	a4,a5,80003e40 <iput+0x48>
  ip->ref--;
    80003e1e:	449c                	lw	a5,8(s1)
    80003e20:	37fd                	addiw	a5,a5,-1
    80003e22:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e24:	0002c517          	auipc	a0,0x2c
    80003e28:	da450513          	addi	a0,a0,-604 # 8002fbc8 <itable>
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	e4a080e7          	jalr	-438(ra) # 80000c76 <release>
}
    80003e34:	60e2                	ld	ra,24(sp)
    80003e36:	6442                	ld	s0,16(sp)
    80003e38:	64a2                	ld	s1,8(sp)
    80003e3a:	6902                	ld	s2,0(sp)
    80003e3c:	6105                	addi	sp,sp,32
    80003e3e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e40:	40bc                	lw	a5,64(s1)
    80003e42:	dff1                	beqz	a5,80003e1e <iput+0x26>
    80003e44:	04a49783          	lh	a5,74(s1)
    80003e48:	fbf9                	bnez	a5,80003e1e <iput+0x26>
    acquiresleep(&ip->lock);
    80003e4a:	01048913          	addi	s2,s1,16
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00001097          	auipc	ra,0x1
    80003e54:	dce080e7          	jalr	-562(ra) # 80004c1e <acquiresleep>
    release(&itable.lock);
    80003e58:	0002c517          	auipc	a0,0x2c
    80003e5c:	d7050513          	addi	a0,a0,-656 # 8002fbc8 <itable>
    80003e60:	ffffd097          	auipc	ra,0xffffd
    80003e64:	e16080e7          	jalr	-490(ra) # 80000c76 <release>
    itrunc(ip);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	ee2080e7          	jalr	-286(ra) # 80003d4c <itrunc>
    ip->type = 0;
    80003e72:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e76:	8526                	mv	a0,s1
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	cfc080e7          	jalr	-772(ra) # 80003b74 <iupdate>
    ip->valid = 0;
    80003e80:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e84:	854a                	mv	a0,s2
    80003e86:	00001097          	auipc	ra,0x1
    80003e8a:	dee080e7          	jalr	-530(ra) # 80004c74 <releasesleep>
    acquire(&itable.lock);
    80003e8e:	0002c517          	auipc	a0,0x2c
    80003e92:	d3a50513          	addi	a0,a0,-710 # 8002fbc8 <itable>
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	d2c080e7          	jalr	-724(ra) # 80000bc2 <acquire>
    80003e9e:	b741                	j	80003e1e <iput+0x26>

0000000080003ea0 <iunlockput>:
{
    80003ea0:	1101                	addi	sp,sp,-32
    80003ea2:	ec06                	sd	ra,24(sp)
    80003ea4:	e822                	sd	s0,16(sp)
    80003ea6:	e426                	sd	s1,8(sp)
    80003ea8:	1000                	addi	s0,sp,32
    80003eaa:	84aa                	mv	s1,a0
  iunlock(ip);
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	e54080e7          	jalr	-428(ra) # 80003d00 <iunlock>
  iput(ip);
    80003eb4:	8526                	mv	a0,s1
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	f42080e7          	jalr	-190(ra) # 80003df8 <iput>
}
    80003ebe:	60e2                	ld	ra,24(sp)
    80003ec0:	6442                	ld	s0,16(sp)
    80003ec2:	64a2                	ld	s1,8(sp)
    80003ec4:	6105                	addi	sp,sp,32
    80003ec6:	8082                	ret

0000000080003ec8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ec8:	1141                	addi	sp,sp,-16
    80003eca:	e422                	sd	s0,8(sp)
    80003ecc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ece:	411c                	lw	a5,0(a0)
    80003ed0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ed2:	415c                	lw	a5,4(a0)
    80003ed4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ed6:	04451783          	lh	a5,68(a0)
    80003eda:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ede:	04a51783          	lh	a5,74(a0)
    80003ee2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ee6:	04c56783          	lwu	a5,76(a0)
    80003eea:	e99c                	sd	a5,16(a1)
}
    80003eec:	6422                	ld	s0,8(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ef2:	457c                	lw	a5,76(a0)
    80003ef4:	0ed7e963          	bltu	a5,a3,80003fe6 <readi+0xf4>
{
    80003ef8:	7159                	addi	sp,sp,-112
    80003efa:	f486                	sd	ra,104(sp)
    80003efc:	f0a2                	sd	s0,96(sp)
    80003efe:	eca6                	sd	s1,88(sp)
    80003f00:	e8ca                	sd	s2,80(sp)
    80003f02:	e4ce                	sd	s3,72(sp)
    80003f04:	e0d2                	sd	s4,64(sp)
    80003f06:	fc56                	sd	s5,56(sp)
    80003f08:	f85a                	sd	s6,48(sp)
    80003f0a:	f45e                	sd	s7,40(sp)
    80003f0c:	f062                	sd	s8,32(sp)
    80003f0e:	ec66                	sd	s9,24(sp)
    80003f10:	e86a                	sd	s10,16(sp)
    80003f12:	e46e                	sd	s11,8(sp)
    80003f14:	1880                	addi	s0,sp,112
    80003f16:	8baa                	mv	s7,a0
    80003f18:	8c2e                	mv	s8,a1
    80003f1a:	8ab2                	mv	s5,a2
    80003f1c:	84b6                	mv	s1,a3
    80003f1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f20:	9f35                	addw	a4,a4,a3
    return 0;
    80003f22:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f24:	0ad76063          	bltu	a4,a3,80003fc4 <readi+0xd2>
  if(off + n > ip->size)
    80003f28:	00e7f463          	bgeu	a5,a4,80003f30 <readi+0x3e>
    n = ip->size - off;
    80003f2c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f30:	0a0b0963          	beqz	s6,80003fe2 <readi+0xf0>
    80003f34:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f36:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f3a:	5cfd                	li	s9,-1
    80003f3c:	a82d                	j	80003f76 <readi+0x84>
    80003f3e:	020a1d93          	slli	s11,s4,0x20
    80003f42:	020ddd93          	srli	s11,s11,0x20
    80003f46:	05890793          	addi	a5,s2,88
    80003f4a:	86ee                	mv	a3,s11
    80003f4c:	963e                	add	a2,a2,a5
    80003f4e:	85d6                	mv	a1,s5
    80003f50:	8562                	mv	a0,s8
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	b16080e7          	jalr	-1258(ra) # 80002a68 <either_copyout>
    80003f5a:	05950d63          	beq	a0,s9,80003fb4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	60a080e7          	jalr	1546(ra) # 8000356a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f68:	013a09bb          	addw	s3,s4,s3
    80003f6c:	009a04bb          	addw	s1,s4,s1
    80003f70:	9aee                	add	s5,s5,s11
    80003f72:	0569f763          	bgeu	s3,s6,80003fc0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f76:	000ba903          	lw	s2,0(s7)
    80003f7a:	00a4d59b          	srliw	a1,s1,0xa
    80003f7e:	855e                	mv	a0,s7
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	8ae080e7          	jalr	-1874(ra) # 8000382e <bmap>
    80003f88:	0005059b          	sext.w	a1,a0
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	4ac080e7          	jalr	1196(ra) # 8000343a <bread>
    80003f96:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f98:	3ff4f613          	andi	a2,s1,1023
    80003f9c:	40cd07bb          	subw	a5,s10,a2
    80003fa0:	413b073b          	subw	a4,s6,s3
    80003fa4:	8a3e                	mv	s4,a5
    80003fa6:	2781                	sext.w	a5,a5
    80003fa8:	0007069b          	sext.w	a3,a4
    80003fac:	f8f6f9e3          	bgeu	a3,a5,80003f3e <readi+0x4c>
    80003fb0:	8a3a                	mv	s4,a4
    80003fb2:	b771                	j	80003f3e <readi+0x4c>
      brelse(bp);
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	5b4080e7          	jalr	1460(ra) # 8000356a <brelse>
      tot = -1;
    80003fbe:	59fd                	li	s3,-1
  }
  return tot;
    80003fc0:	0009851b          	sext.w	a0,s3
}
    80003fc4:	70a6                	ld	ra,104(sp)
    80003fc6:	7406                	ld	s0,96(sp)
    80003fc8:	64e6                	ld	s1,88(sp)
    80003fca:	6946                	ld	s2,80(sp)
    80003fcc:	69a6                	ld	s3,72(sp)
    80003fce:	6a06                	ld	s4,64(sp)
    80003fd0:	7ae2                	ld	s5,56(sp)
    80003fd2:	7b42                	ld	s6,48(sp)
    80003fd4:	7ba2                	ld	s7,40(sp)
    80003fd6:	7c02                	ld	s8,32(sp)
    80003fd8:	6ce2                	ld	s9,24(sp)
    80003fda:	6d42                	ld	s10,16(sp)
    80003fdc:	6da2                	ld	s11,8(sp)
    80003fde:	6165                	addi	sp,sp,112
    80003fe0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fe2:	89da                	mv	s3,s6
    80003fe4:	bff1                	j	80003fc0 <readi+0xce>
    return 0;
    80003fe6:	4501                	li	a0,0
}
    80003fe8:	8082                	ret

0000000080003fea <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fea:	457c                	lw	a5,76(a0)
    80003fec:	10d7e863          	bltu	a5,a3,800040fc <writei+0x112>
{
    80003ff0:	7159                	addi	sp,sp,-112
    80003ff2:	f486                	sd	ra,104(sp)
    80003ff4:	f0a2                	sd	s0,96(sp)
    80003ff6:	eca6                	sd	s1,88(sp)
    80003ff8:	e8ca                	sd	s2,80(sp)
    80003ffa:	e4ce                	sd	s3,72(sp)
    80003ffc:	e0d2                	sd	s4,64(sp)
    80003ffe:	fc56                	sd	s5,56(sp)
    80004000:	f85a                	sd	s6,48(sp)
    80004002:	f45e                	sd	s7,40(sp)
    80004004:	f062                	sd	s8,32(sp)
    80004006:	ec66                	sd	s9,24(sp)
    80004008:	e86a                	sd	s10,16(sp)
    8000400a:	e46e                	sd	s11,8(sp)
    8000400c:	1880                	addi	s0,sp,112
    8000400e:	8b2a                	mv	s6,a0
    80004010:	8c2e                	mv	s8,a1
    80004012:	8ab2                	mv	s5,a2
    80004014:	8936                	mv	s2,a3
    80004016:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004018:	00e687bb          	addw	a5,a3,a4
    8000401c:	0ed7e263          	bltu	a5,a3,80004100 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004020:	00043737          	lui	a4,0x43
    80004024:	0ef76063          	bltu	a4,a5,80004104 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004028:	0c0b8863          	beqz	s7,800040f8 <writei+0x10e>
    8000402c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004032:	5cfd                	li	s9,-1
    80004034:	a091                	j	80004078 <writei+0x8e>
    80004036:	02099d93          	slli	s11,s3,0x20
    8000403a:	020ddd93          	srli	s11,s11,0x20
    8000403e:	05848793          	addi	a5,s1,88
    80004042:	86ee                	mv	a3,s11
    80004044:	8656                	mv	a2,s5
    80004046:	85e2                	mv	a1,s8
    80004048:	953e                	add	a0,a0,a5
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	a74080e7          	jalr	-1420(ra) # 80002abe <either_copyin>
    80004052:	07950263          	beq	a0,s9,800040b6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004056:	8526                	mv	a0,s1
    80004058:	00001097          	auipc	ra,0x1
    8000405c:	aa6080e7          	jalr	-1370(ra) # 80004afe <log_write>
    brelse(bp);
    80004060:	8526                	mv	a0,s1
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	508080e7          	jalr	1288(ra) # 8000356a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000406a:	01498a3b          	addw	s4,s3,s4
    8000406e:	0129893b          	addw	s2,s3,s2
    80004072:	9aee                	add	s5,s5,s11
    80004074:	057a7663          	bgeu	s4,s7,800040c0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004078:	000b2483          	lw	s1,0(s6)
    8000407c:	00a9559b          	srliw	a1,s2,0xa
    80004080:	855a                	mv	a0,s6
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	7ac080e7          	jalr	1964(ra) # 8000382e <bmap>
    8000408a:	0005059b          	sext.w	a1,a0
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	3aa080e7          	jalr	938(ra) # 8000343a <bread>
    80004098:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000409a:	3ff97513          	andi	a0,s2,1023
    8000409e:	40ad07bb          	subw	a5,s10,a0
    800040a2:	414b873b          	subw	a4,s7,s4
    800040a6:	89be                	mv	s3,a5
    800040a8:	2781                	sext.w	a5,a5
    800040aa:	0007069b          	sext.w	a3,a4
    800040ae:	f8f6f4e3          	bgeu	a3,a5,80004036 <writei+0x4c>
    800040b2:	89ba                	mv	s3,a4
    800040b4:	b749                	j	80004036 <writei+0x4c>
      brelse(bp);
    800040b6:	8526                	mv	a0,s1
    800040b8:	fffff097          	auipc	ra,0xfffff
    800040bc:	4b2080e7          	jalr	1202(ra) # 8000356a <brelse>
  }

  if(off > ip->size)
    800040c0:	04cb2783          	lw	a5,76(s6)
    800040c4:	0127f463          	bgeu	a5,s2,800040cc <writei+0xe2>
    ip->size = off;
    800040c8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040cc:	855a                	mv	a0,s6
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	aa6080e7          	jalr	-1370(ra) # 80003b74 <iupdate>

  return tot;
    800040d6:	000a051b          	sext.w	a0,s4
}
    800040da:	70a6                	ld	ra,104(sp)
    800040dc:	7406                	ld	s0,96(sp)
    800040de:	64e6                	ld	s1,88(sp)
    800040e0:	6946                	ld	s2,80(sp)
    800040e2:	69a6                	ld	s3,72(sp)
    800040e4:	6a06                	ld	s4,64(sp)
    800040e6:	7ae2                	ld	s5,56(sp)
    800040e8:	7b42                	ld	s6,48(sp)
    800040ea:	7ba2                	ld	s7,40(sp)
    800040ec:	7c02                	ld	s8,32(sp)
    800040ee:	6ce2                	ld	s9,24(sp)
    800040f0:	6d42                	ld	s10,16(sp)
    800040f2:	6da2                	ld	s11,8(sp)
    800040f4:	6165                	addi	sp,sp,112
    800040f6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f8:	8a5e                	mv	s4,s7
    800040fa:	bfc9                	j	800040cc <writei+0xe2>
    return -1;
    800040fc:	557d                	li	a0,-1
}
    800040fe:	8082                	ret
    return -1;
    80004100:	557d                	li	a0,-1
    80004102:	bfe1                	j	800040da <writei+0xf0>
    return -1;
    80004104:	557d                	li	a0,-1
    80004106:	bfd1                	j	800040da <writei+0xf0>

0000000080004108 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004108:	1141                	addi	sp,sp,-16
    8000410a:	e406                	sd	ra,8(sp)
    8000410c:	e022                	sd	s0,0(sp)
    8000410e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004110:	4639                	li	a2,14
    80004112:	ffffd097          	auipc	ra,0xffffd
    80004116:	c84080e7          	jalr	-892(ra) # 80000d96 <strncmp>
}
    8000411a:	60a2                	ld	ra,8(sp)
    8000411c:	6402                	ld	s0,0(sp)
    8000411e:	0141                	addi	sp,sp,16
    80004120:	8082                	ret

0000000080004122 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004122:	7139                	addi	sp,sp,-64
    80004124:	fc06                	sd	ra,56(sp)
    80004126:	f822                	sd	s0,48(sp)
    80004128:	f426                	sd	s1,40(sp)
    8000412a:	f04a                	sd	s2,32(sp)
    8000412c:	ec4e                	sd	s3,24(sp)
    8000412e:	e852                	sd	s4,16(sp)
    80004130:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004132:	04451703          	lh	a4,68(a0)
    80004136:	4785                	li	a5,1
    80004138:	00f71a63          	bne	a4,a5,8000414c <dirlookup+0x2a>
    8000413c:	892a                	mv	s2,a0
    8000413e:	89ae                	mv	s3,a1
    80004140:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004142:	457c                	lw	a5,76(a0)
    80004144:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004146:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004148:	e79d                	bnez	a5,80004176 <dirlookup+0x54>
    8000414a:	a8a5                	j	800041c2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	4bc50513          	addi	a0,a0,1212 # 80008608 <syscalls+0x1a0>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	3d6080e7          	jalr	982(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000415c:	00004517          	auipc	a0,0x4
    80004160:	4c450513          	addi	a0,a0,1220 # 80008620 <syscalls+0x1b8>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	3c6080e7          	jalr	966(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416c:	24c1                	addiw	s1,s1,16
    8000416e:	04c92783          	lw	a5,76(s2)
    80004172:	04f4f763          	bgeu	s1,a5,800041c0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004176:	4741                	li	a4,16
    80004178:	86a6                	mv	a3,s1
    8000417a:	fc040613          	addi	a2,s0,-64
    8000417e:	4581                	li	a1,0
    80004180:	854a                	mv	a0,s2
    80004182:	00000097          	auipc	ra,0x0
    80004186:	d70080e7          	jalr	-656(ra) # 80003ef2 <readi>
    8000418a:	47c1                	li	a5,16
    8000418c:	fcf518e3          	bne	a0,a5,8000415c <dirlookup+0x3a>
    if(de.inum == 0)
    80004190:	fc045783          	lhu	a5,-64(s0)
    80004194:	dfe1                	beqz	a5,8000416c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004196:	fc240593          	addi	a1,s0,-62
    8000419a:	854e                	mv	a0,s3
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	f6c080e7          	jalr	-148(ra) # 80004108 <namecmp>
    800041a4:	f561                	bnez	a0,8000416c <dirlookup+0x4a>
      if(poff)
    800041a6:	000a0463          	beqz	s4,800041ae <dirlookup+0x8c>
        *poff = off;
    800041aa:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ae:	fc045583          	lhu	a1,-64(s0)
    800041b2:	00092503          	lw	a0,0(s2)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	754080e7          	jalr	1876(ra) # 8000390a <iget>
    800041be:	a011                	j	800041c2 <dirlookup+0xa0>
  return 0;
    800041c0:	4501                	li	a0,0
}
    800041c2:	70e2                	ld	ra,56(sp)
    800041c4:	7442                	ld	s0,48(sp)
    800041c6:	74a2                	ld	s1,40(sp)
    800041c8:	7902                	ld	s2,32(sp)
    800041ca:	69e2                	ld	s3,24(sp)
    800041cc:	6a42                	ld	s4,16(sp)
    800041ce:	6121                	addi	sp,sp,64
    800041d0:	8082                	ret

00000000800041d2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041d2:	711d                	addi	sp,sp,-96
    800041d4:	ec86                	sd	ra,88(sp)
    800041d6:	e8a2                	sd	s0,80(sp)
    800041d8:	e4a6                	sd	s1,72(sp)
    800041da:	e0ca                	sd	s2,64(sp)
    800041dc:	fc4e                	sd	s3,56(sp)
    800041de:	f852                	sd	s4,48(sp)
    800041e0:	f456                	sd	s5,40(sp)
    800041e2:	f05a                	sd	s6,32(sp)
    800041e4:	ec5e                	sd	s7,24(sp)
    800041e6:	e862                	sd	s8,16(sp)
    800041e8:	e466                	sd	s9,8(sp)
    800041ea:	1080                	addi	s0,sp,96
    800041ec:	84aa                	mv	s1,a0
    800041ee:	8aae                	mv	s5,a1
    800041f0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041f2:	00054703          	lbu	a4,0(a0)
    800041f6:	02f00793          	li	a5,47
    800041fa:	02f70363          	beq	a4,a5,80004220 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041fe:	ffffe097          	auipc	ra,0xffffe
    80004202:	cfc080e7          	jalr	-772(ra) # 80001efa <myproc>
    80004206:	15053503          	ld	a0,336(a0)
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	9f6080e7          	jalr	-1546(ra) # 80003c00 <idup>
    80004212:	89aa                	mv	s3,a0
  while(*path == '/')
    80004214:	02f00913          	li	s2,47
  len = path - s;
    80004218:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000421a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000421c:	4b85                	li	s7,1
    8000421e:	a865                	j	800042d6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004220:	4585                	li	a1,1
    80004222:	4505                	li	a0,1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	6e6080e7          	jalr	1766(ra) # 8000390a <iget>
    8000422c:	89aa                	mv	s3,a0
    8000422e:	b7dd                	j	80004214 <namex+0x42>
      iunlockput(ip);
    80004230:	854e                	mv	a0,s3
    80004232:	00000097          	auipc	ra,0x0
    80004236:	c6e080e7          	jalr	-914(ra) # 80003ea0 <iunlockput>
      return 0;
    8000423a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000423c:	854e                	mv	a0,s3
    8000423e:	60e6                	ld	ra,88(sp)
    80004240:	6446                	ld	s0,80(sp)
    80004242:	64a6                	ld	s1,72(sp)
    80004244:	6906                	ld	s2,64(sp)
    80004246:	79e2                	ld	s3,56(sp)
    80004248:	7a42                	ld	s4,48(sp)
    8000424a:	7aa2                	ld	s5,40(sp)
    8000424c:	7b02                	ld	s6,32(sp)
    8000424e:	6be2                	ld	s7,24(sp)
    80004250:	6c42                	ld	s8,16(sp)
    80004252:	6ca2                	ld	s9,8(sp)
    80004254:	6125                	addi	sp,sp,96
    80004256:	8082                	ret
      iunlock(ip);
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	aa6080e7          	jalr	-1370(ra) # 80003d00 <iunlock>
      return ip;
    80004262:	bfe9                	j	8000423c <namex+0x6a>
      iunlockput(ip);
    80004264:	854e                	mv	a0,s3
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	c3a080e7          	jalr	-966(ra) # 80003ea0 <iunlockput>
      return 0;
    8000426e:	89e6                	mv	s3,s9
    80004270:	b7f1                	j	8000423c <namex+0x6a>
  len = path - s;
    80004272:	40b48633          	sub	a2,s1,a1
    80004276:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000427a:	099c5463          	bge	s8,s9,80004302 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000427e:	4639                	li	a2,14
    80004280:	8552                	mv	a0,s4
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	a98080e7          	jalr	-1384(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	01279763          	bne	a5,s2,8000429c <namex+0xca>
    path++;
    80004292:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004294:	0004c783          	lbu	a5,0(s1)
    80004298:	ff278de3          	beq	a5,s2,80004292 <namex+0xc0>
    ilock(ip);
    8000429c:	854e                	mv	a0,s3
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	9a0080e7          	jalr	-1632(ra) # 80003c3e <ilock>
    if(ip->type != T_DIR){
    800042a6:	04499783          	lh	a5,68(s3)
    800042aa:	f97793e3          	bne	a5,s7,80004230 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ae:	000a8563          	beqz	s5,800042b8 <namex+0xe6>
    800042b2:	0004c783          	lbu	a5,0(s1)
    800042b6:	d3cd                	beqz	a5,80004258 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b8:	865a                	mv	a2,s6
    800042ba:	85d2                	mv	a1,s4
    800042bc:	854e                	mv	a0,s3
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	e64080e7          	jalr	-412(ra) # 80004122 <dirlookup>
    800042c6:	8caa                	mv	s9,a0
    800042c8:	dd51                	beqz	a0,80004264 <namex+0x92>
    iunlockput(ip);
    800042ca:	854e                	mv	a0,s3
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	bd4080e7          	jalr	-1068(ra) # 80003ea0 <iunlockput>
    ip = next;
    800042d4:	89e6                	mv	s3,s9
  while(*path == '/')
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	05279763          	bne	a5,s2,80004328 <namex+0x156>
    path++;
    800042de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042e0:	0004c783          	lbu	a5,0(s1)
    800042e4:	ff278de3          	beq	a5,s2,800042de <namex+0x10c>
  if(*path == 0)
    800042e8:	c79d                	beqz	a5,80004316 <namex+0x144>
    path++;
    800042ea:	85a6                	mv	a1,s1
  len = path - s;
    800042ec:	8cda                	mv	s9,s6
    800042ee:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800042f0:	01278963          	beq	a5,s2,80004302 <namex+0x130>
    800042f4:	dfbd                	beqz	a5,80004272 <namex+0xa0>
    path++;
    800042f6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042f8:	0004c783          	lbu	a5,0(s1)
    800042fc:	ff279ce3          	bne	a5,s2,800042f4 <namex+0x122>
    80004300:	bf8d                	j	80004272 <namex+0xa0>
    memmove(name, s, len);
    80004302:	2601                	sext.w	a2,a2
    80004304:	8552                	mv	a0,s4
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	a14080e7          	jalr	-1516(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000430e:	9cd2                	add	s9,s9,s4
    80004310:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004314:	bf9d                	j	8000428a <namex+0xb8>
  if(nameiparent){
    80004316:	f20a83e3          	beqz	s5,8000423c <namex+0x6a>
    iput(ip);
    8000431a:	854e                	mv	a0,s3
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	adc080e7          	jalr	-1316(ra) # 80003df8 <iput>
    return 0;
    80004324:	4981                	li	s3,0
    80004326:	bf19                	j	8000423c <namex+0x6a>
  if(*path == 0)
    80004328:	d7fd                	beqz	a5,80004316 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000432a:	0004c783          	lbu	a5,0(s1)
    8000432e:	85a6                	mv	a1,s1
    80004330:	b7d1                	j	800042f4 <namex+0x122>

0000000080004332 <dirlink>:
{
    80004332:	7139                	addi	sp,sp,-64
    80004334:	fc06                	sd	ra,56(sp)
    80004336:	f822                	sd	s0,48(sp)
    80004338:	f426                	sd	s1,40(sp)
    8000433a:	f04a                	sd	s2,32(sp)
    8000433c:	ec4e                	sd	s3,24(sp)
    8000433e:	e852                	sd	s4,16(sp)
    80004340:	0080                	addi	s0,sp,64
    80004342:	892a                	mv	s2,a0
    80004344:	8a2e                	mv	s4,a1
    80004346:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004348:	4601                	li	a2,0
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	dd8080e7          	jalr	-552(ra) # 80004122 <dirlookup>
    80004352:	e93d                	bnez	a0,800043c8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	04c92483          	lw	s1,76(s2)
    80004358:	c49d                	beqz	s1,80004386 <dirlink+0x54>
    8000435a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000435c:	4741                	li	a4,16
    8000435e:	86a6                	mv	a3,s1
    80004360:	fc040613          	addi	a2,s0,-64
    80004364:	4581                	li	a1,0
    80004366:	854a                	mv	a0,s2
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	b8a080e7          	jalr	-1142(ra) # 80003ef2 <readi>
    80004370:	47c1                	li	a5,16
    80004372:	06f51163          	bne	a0,a5,800043d4 <dirlink+0xa2>
    if(de.inum == 0)
    80004376:	fc045783          	lhu	a5,-64(s0)
    8000437a:	c791                	beqz	a5,80004386 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437c:	24c1                	addiw	s1,s1,16
    8000437e:	04c92783          	lw	a5,76(s2)
    80004382:	fcf4ede3          	bltu	s1,a5,8000435c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004386:	4639                	li	a2,14
    80004388:	85d2                	mv	a1,s4
    8000438a:	fc240513          	addi	a0,s0,-62
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	a44080e7          	jalr	-1468(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004396:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000439a:	4741                	li	a4,16
    8000439c:	86a6                	mv	a3,s1
    8000439e:	fc040613          	addi	a2,s0,-64
    800043a2:	4581                	li	a1,0
    800043a4:	854a                	mv	a0,s2
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	c44080e7          	jalr	-956(ra) # 80003fea <writei>
    800043ae:	872a                	mv	a4,a0
    800043b0:	47c1                	li	a5,16
  return 0;
    800043b2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b4:	02f71863          	bne	a4,a5,800043e4 <dirlink+0xb2>
}
    800043b8:	70e2                	ld	ra,56(sp)
    800043ba:	7442                	ld	s0,48(sp)
    800043bc:	74a2                	ld	s1,40(sp)
    800043be:	7902                	ld	s2,32(sp)
    800043c0:	69e2                	ld	s3,24(sp)
    800043c2:	6a42                	ld	s4,16(sp)
    800043c4:	6121                	addi	sp,sp,64
    800043c6:	8082                	ret
    iput(ip);
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	a30080e7          	jalr	-1488(ra) # 80003df8 <iput>
    return -1;
    800043d0:	557d                	li	a0,-1
    800043d2:	b7dd                	j	800043b8 <dirlink+0x86>
      panic("dirlink read");
    800043d4:	00004517          	auipc	a0,0x4
    800043d8:	25c50513          	addi	a0,a0,604 # 80008630 <syscalls+0x1c8>
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	14e080e7          	jalr	334(ra) # 8000052a <panic>
    panic("dirlink");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	3d450513          	addi	a0,a0,980 # 800087b8 <syscalls+0x350>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	13e080e7          	jalr	318(ra) # 8000052a <panic>

00000000800043f4 <namei>:

struct inode*
namei(char *path)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043fc:	fe040613          	addi	a2,s0,-32
    80004400:	4581                	li	a1,0
    80004402:	00000097          	auipc	ra,0x0
    80004406:	dd0080e7          	jalr	-560(ra) # 800041d2 <namex>
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004412:	1141                	addi	sp,sp,-16
    80004414:	e406                	sd	ra,8(sp)
    80004416:	e022                	sd	s0,0(sp)
    80004418:	0800                	addi	s0,sp,16
    8000441a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000441c:	4585                	li	a1,1
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	db4080e7          	jalr	-588(ra) # 800041d2 <namex>
}
    80004426:	60a2                	ld	ra,8(sp)
    80004428:	6402                	ld	s0,0(sp)
    8000442a:	0141                	addi	sp,sp,16
    8000442c:	8082                	ret

000000008000442e <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec22                	sd	s0,24(sp)
    80004432:	1000                	addi	s0,sp,32
    80004434:	872a                	mv	a4,a0
    80004436:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    80004438:	00004797          	auipc	a5,0x4
    8000443c:	20878793          	addi	a5,a5,520 # 80008640 <syscalls+0x1d8>
    80004440:	6394                	ld	a3,0(a5)
    80004442:	fed43023          	sd	a3,-32(s0)
    80004446:	0087d683          	lhu	a3,8(a5)
    8000444a:	fed41423          	sh	a3,-24(s0)
    8000444e:	00a7c783          	lbu	a5,10(a5)
    80004452:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004456:	87ae                	mv	a5,a1
    if(i<0){
    80004458:	02074b63          	bltz	a4,8000448e <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    8000445c:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    8000445e:	4629                	li	a2,10
        ++p;
    80004460:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004462:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004466:	feed                	bnez	a3,80004460 <itoa+0x32>
    *p = '\0';
    80004468:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    8000446c:	4629                	li	a2,10
    8000446e:	17fd                	addi	a5,a5,-1
    80004470:	02c766bb          	remw	a3,a4,a2
    80004474:	ff040593          	addi	a1,s0,-16
    80004478:	96ae                	add	a3,a3,a1
    8000447a:	ff06c683          	lbu	a3,-16(a3)
    8000447e:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004482:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004486:	f765                	bnez	a4,8000446e <itoa+0x40>
    return b;
}
    80004488:	6462                	ld	s0,24(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret
        *p++ = '-';
    8000448e:	00158793          	addi	a5,a1,1
    80004492:	02d00693          	li	a3,45
    80004496:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000449a:	40e0073b          	negw	a4,a4
    8000449e:	bf7d                	j	8000445c <itoa+0x2e>

00000000800044a0 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    800044a0:	711d                	addi	sp,sp,-96
    800044a2:	ec86                	sd	ra,88(sp)
    800044a4:	e8a2                	sd	s0,80(sp)
    800044a6:	e4a6                	sd	s1,72(sp)
    800044a8:	e0ca                	sd	s2,64(sp)
    800044aa:	1080                	addi	s0,sp,96
    800044ac:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800044ae:	4619                	li	a2,6
    800044b0:	00004597          	auipc	a1,0x4
    800044b4:	1a058593          	addi	a1,a1,416 # 80008650 <syscalls+0x1e8>
    800044b8:	fd040513          	addi	a0,s0,-48
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	85e080e7          	jalr	-1954(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800044c4:	fd640593          	addi	a1,s0,-42
    800044c8:	5888                	lw	a0,48(s1)
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	f64080e7          	jalr	-156(ra) # 8000442e <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    800044d2:	1684b503          	ld	a0,360(s1)
    800044d6:	16050763          	beqz	a0,80004644 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    800044da:	00001097          	auipc	ra,0x1
    800044de:	918080e7          	jalr	-1768(ra) # 80004df2 <fileclose>

  begin_op();
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	444080e7          	jalr	1092(ra) # 80004926 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800044ea:	fb040593          	addi	a1,s0,-80
    800044ee:	fd040513          	addi	a0,s0,-48
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	f20080e7          	jalr	-224(ra) # 80004412 <nameiparent>
    800044fa:	892a                	mv	s2,a0
    800044fc:	cd69                	beqz	a0,800045d6 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	740080e7          	jalr	1856(ra) # 80003c3e <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004506:	00004597          	auipc	a1,0x4
    8000450a:	15258593          	addi	a1,a1,338 # 80008658 <syscalls+0x1f0>
    8000450e:	fb040513          	addi	a0,s0,-80
    80004512:	00000097          	auipc	ra,0x0
    80004516:	bf6080e7          	jalr	-1034(ra) # 80004108 <namecmp>
    8000451a:	c57d                	beqz	a0,80004608 <removeSwapFile+0x168>
    8000451c:	00004597          	auipc	a1,0x4
    80004520:	14458593          	addi	a1,a1,324 # 80008660 <syscalls+0x1f8>
    80004524:	fb040513          	addi	a0,s0,-80
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	be0080e7          	jalr	-1056(ra) # 80004108 <namecmp>
    80004530:	cd61                	beqz	a0,80004608 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004532:	fac40613          	addi	a2,s0,-84
    80004536:	fb040593          	addi	a1,s0,-80
    8000453a:	854a                	mv	a0,s2
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	be6080e7          	jalr	-1050(ra) # 80004122 <dirlookup>
    80004544:	84aa                	mv	s1,a0
    80004546:	c169                	beqz	a0,80004608 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	6f6080e7          	jalr	1782(ra) # 80003c3e <ilock>

  if(ip->nlink < 1)
    80004550:	04a49783          	lh	a5,74(s1)
    80004554:	08f05763          	blez	a5,800045e2 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004558:	04449703          	lh	a4,68(s1)
    8000455c:	4785                	li	a5,1
    8000455e:	08f70a63          	beq	a4,a5,800045f2 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004562:	4641                	li	a2,16
    80004564:	4581                	li	a1,0
    80004566:	fc040513          	addi	a0,s0,-64
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	754080e7          	jalr	1876(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004572:	4741                	li	a4,16
    80004574:	fac42683          	lw	a3,-84(s0)
    80004578:	fc040613          	addi	a2,s0,-64
    8000457c:	4581                	li	a1,0
    8000457e:	854a                	mv	a0,s2
    80004580:	00000097          	auipc	ra,0x0
    80004584:	a6a080e7          	jalr	-1430(ra) # 80003fea <writei>
    80004588:	47c1                	li	a5,16
    8000458a:	08f51a63          	bne	a0,a5,8000461e <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000458e:	04449703          	lh	a4,68(s1)
    80004592:	4785                	li	a5,1
    80004594:	08f70d63          	beq	a4,a5,8000462e <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004598:	854a                	mv	a0,s2
    8000459a:	00000097          	auipc	ra,0x0
    8000459e:	906080e7          	jalr	-1786(ra) # 80003ea0 <iunlockput>

  ip->nlink--;
    800045a2:	04a4d783          	lhu	a5,74(s1)
    800045a6:	37fd                	addiw	a5,a5,-1
    800045a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800045ac:	8526                	mv	a0,s1
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	5c6080e7          	jalr	1478(ra) # 80003b74 <iupdate>
  iunlockput(ip);
    800045b6:	8526                	mv	a0,s1
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	8e8080e7          	jalr	-1816(ra) # 80003ea0 <iunlockput>

  end_op();
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	3e6080e7          	jalr	998(ra) # 800049a6 <end_op>

  return 0;
    800045c8:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    800045ca:	60e6                	ld	ra,88(sp)
    800045cc:	6446                	ld	s0,80(sp)
    800045ce:	64a6                	ld	s1,72(sp)
    800045d0:	6906                	ld	s2,64(sp)
    800045d2:	6125                	addi	sp,sp,96
    800045d4:	8082                	ret
    end_op();
    800045d6:	00000097          	auipc	ra,0x0
    800045da:	3d0080e7          	jalr	976(ra) # 800049a6 <end_op>
    return -1;
    800045de:	557d                	li	a0,-1
    800045e0:	b7ed                	j	800045ca <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800045e2:	00004517          	auipc	a0,0x4
    800045e6:	08650513          	addi	a0,a0,134 # 80008668 <syscalls+0x200>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	f40080e7          	jalr	-192(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800045f2:	8526                	mv	a0,s1
    800045f4:	00001097          	auipc	ra,0x1
    800045f8:	7f2080e7          	jalr	2034(ra) # 80005de6 <isdirempty>
    800045fc:	f13d                	bnez	a0,80004562 <removeSwapFile+0xc2>
    iunlockput(ip);
    800045fe:	8526                	mv	a0,s1
    80004600:	00000097          	auipc	ra,0x0
    80004604:	8a0080e7          	jalr	-1888(ra) # 80003ea0 <iunlockput>
    iunlockput(dp);
    80004608:	854a                	mv	a0,s2
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	896080e7          	jalr	-1898(ra) # 80003ea0 <iunlockput>
    end_op();
    80004612:	00000097          	auipc	ra,0x0
    80004616:	394080e7          	jalr	916(ra) # 800049a6 <end_op>
    return -1;
    8000461a:	557d                	li	a0,-1
    8000461c:	b77d                	j	800045ca <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000461e:	00004517          	auipc	a0,0x4
    80004622:	06250513          	addi	a0,a0,98 # 80008680 <syscalls+0x218>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	f04080e7          	jalr	-252(ra) # 8000052a <panic>
    dp->nlink--;
    8000462e:	04a95783          	lhu	a5,74(s2)
    80004632:	37fd                	addiw	a5,a5,-1
    80004634:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004638:	854a                	mv	a0,s2
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	53a080e7          	jalr	1338(ra) # 80003b74 <iupdate>
    80004642:	bf99                	j	80004598 <removeSwapFile+0xf8>
    return -1;
    80004644:	557d                	li	a0,-1
    80004646:	b751                	j	800045ca <removeSwapFile+0x12a>

0000000080004648 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004648:	7179                	addi	sp,sp,-48
    8000464a:	f406                	sd	ra,40(sp)
    8000464c:	f022                	sd	s0,32(sp)
    8000464e:	ec26                	sd	s1,24(sp)
    80004650:	e84a                	sd	s2,16(sp)
    80004652:	1800                	addi	s0,sp,48
    80004654:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004656:	4619                	li	a2,6
    80004658:	00004597          	auipc	a1,0x4
    8000465c:	ff858593          	addi	a1,a1,-8 # 80008650 <syscalls+0x1e8>
    80004660:	fd040513          	addi	a0,s0,-48
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	6b6080e7          	jalr	1718(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000466c:	fd640593          	addi	a1,s0,-42
    80004670:	5888                	lw	a0,48(s1)
    80004672:	00000097          	auipc	ra,0x0
    80004676:	dbc080e7          	jalr	-580(ra) # 8000442e <itoa>

  begin_op();
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	2ac080e7          	jalr	684(ra) # 80004926 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004682:	4681                	li	a3,0
    80004684:	4601                	li	a2,0
    80004686:	4589                	li	a1,2
    80004688:	fd040513          	addi	a0,s0,-48
    8000468c:	00002097          	auipc	ra,0x2
    80004690:	94e080e7          	jalr	-1714(ra) # 80005fda <create>
    80004694:	892a                	mv	s2,a0
  iunlock(in);
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	66a080e7          	jalr	1642(ra) # 80003d00 <iunlock>
  p->swapFile = filealloc();
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	698080e7          	jalr	1688(ra) # 80004d36 <filealloc>
    800046a6:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    800046aa:	cd1d                	beqz	a0,800046e8 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    800046ac:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    800046b0:	1684b703          	ld	a4,360(s1)
    800046b4:	4789                	li	a5,2
    800046b6:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    800046b8:	1684b703          	ld	a4,360(s1)
    800046bc:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    800046c0:	1684b703          	ld	a4,360(s1)
    800046c4:	4685                	li	a3,1
    800046c6:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800046ca:	1684b703          	ld	a4,360(s1)
    800046ce:	00f704a3          	sb	a5,9(a4)
    end_op();
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	2d4080e7          	jalr	724(ra) # 800049a6 <end_op>

    return 0;
}
    800046da:	4501                	li	a0,0
    800046dc:	70a2                	ld	ra,40(sp)
    800046de:	7402                	ld	s0,32(sp)
    800046e0:	64e2                	ld	s1,24(sp)
    800046e2:	6942                	ld	s2,16(sp)
    800046e4:	6145                	addi	sp,sp,48
    800046e6:	8082                	ret
    panic("no slot for files on /store");
    800046e8:	00004517          	auipc	a0,0x4
    800046ec:	fa850513          	addi	a0,a0,-88 # 80008690 <syscalls+0x228>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	e3a080e7          	jalr	-454(ra) # 8000052a <panic>

00000000800046f8 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800046f8:	1141                	addi	sp,sp,-16
    800046fa:	e406                	sd	ra,8(sp)
    800046fc:	e022                	sd	s0,0(sp)
    800046fe:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004700:	16853783          	ld	a5,360(a0)
    80004704:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004706:	8636                	mv	a2,a3
    80004708:	16853503          	ld	a0,360(a0)
    8000470c:	00001097          	auipc	ra,0x1
    80004710:	ad8080e7          	jalr	-1320(ra) # 800051e4 <kfilewrite>
}
    80004714:	60a2                	ld	ra,8(sp)
    80004716:	6402                	ld	s0,0(sp)
    80004718:	0141                	addi	sp,sp,16
    8000471a:	8082                	ret

000000008000471c <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000471c:	1141                	addi	sp,sp,-16
    8000471e:	e406                	sd	ra,8(sp)
    80004720:	e022                	sd	s0,0(sp)
    80004722:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004724:	16853783          	ld	a5,360(a0)
    80004728:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    8000472a:	8636                	mv	a2,a3
    8000472c:	16853503          	ld	a0,360(a0)
    80004730:	00001097          	auipc	ra,0x1
    80004734:	9f2080e7          	jalr	-1550(ra) # 80005122 <kfileread>
    80004738:	60a2                	ld	ra,8(sp)
    8000473a:	6402                	ld	s0,0(sp)
    8000473c:	0141                	addi	sp,sp,16
    8000473e:	8082                	ret

0000000080004740 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004740:	1101                	addi	sp,sp,-32
    80004742:	ec06                	sd	ra,24(sp)
    80004744:	e822                	sd	s0,16(sp)
    80004746:	e426                	sd	s1,8(sp)
    80004748:	e04a                	sd	s2,0(sp)
    8000474a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000474c:	0002d917          	auipc	s2,0x2d
    80004750:	f2490913          	addi	s2,s2,-220 # 80031670 <log>
    80004754:	01892583          	lw	a1,24(s2)
    80004758:	02892503          	lw	a0,40(s2)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	cde080e7          	jalr	-802(ra) # 8000343a <bread>
    80004764:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004766:	02c92683          	lw	a3,44(s2)
    8000476a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000476c:	02d05863          	blez	a3,8000479c <write_head+0x5c>
    80004770:	0002d797          	auipc	a5,0x2d
    80004774:	f3078793          	addi	a5,a5,-208 # 800316a0 <log+0x30>
    80004778:	05c50713          	addi	a4,a0,92
    8000477c:	36fd                	addiw	a3,a3,-1
    8000477e:	02069613          	slli	a2,a3,0x20
    80004782:	01e65693          	srli	a3,a2,0x1e
    80004786:	0002d617          	auipc	a2,0x2d
    8000478a:	f1e60613          	addi	a2,a2,-226 # 800316a4 <log+0x34>
    8000478e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004790:	4390                	lw	a2,0(a5)
    80004792:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004794:	0791                	addi	a5,a5,4
    80004796:	0711                	addi	a4,a4,4
    80004798:	fed79ce3          	bne	a5,a3,80004790 <write_head+0x50>
  }
  bwrite(buf);
    8000479c:	8526                	mv	a0,s1
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	d8e080e7          	jalr	-626(ra) # 8000352c <bwrite>
  brelse(buf);
    800047a6:	8526                	mv	a0,s1
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	dc2080e7          	jalr	-574(ra) # 8000356a <brelse>
}
    800047b0:	60e2                	ld	ra,24(sp)
    800047b2:	6442                	ld	s0,16(sp)
    800047b4:	64a2                	ld	s1,8(sp)
    800047b6:	6902                	ld	s2,0(sp)
    800047b8:	6105                	addi	sp,sp,32
    800047ba:	8082                	ret

00000000800047bc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047bc:	0002d797          	auipc	a5,0x2d
    800047c0:	ee07a783          	lw	a5,-288(a5) # 8003169c <log+0x2c>
    800047c4:	0af05d63          	blez	a5,8000487e <install_trans+0xc2>
{
    800047c8:	7139                	addi	sp,sp,-64
    800047ca:	fc06                	sd	ra,56(sp)
    800047cc:	f822                	sd	s0,48(sp)
    800047ce:	f426                	sd	s1,40(sp)
    800047d0:	f04a                	sd	s2,32(sp)
    800047d2:	ec4e                	sd	s3,24(sp)
    800047d4:	e852                	sd	s4,16(sp)
    800047d6:	e456                	sd	s5,8(sp)
    800047d8:	e05a                	sd	s6,0(sp)
    800047da:	0080                	addi	s0,sp,64
    800047dc:	8b2a                	mv	s6,a0
    800047de:	0002da97          	auipc	s5,0x2d
    800047e2:	ec2a8a93          	addi	s5,s5,-318 # 800316a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047e8:	0002d997          	auipc	s3,0x2d
    800047ec:	e8898993          	addi	s3,s3,-376 # 80031670 <log>
    800047f0:	a00d                	j	80004812 <install_trans+0x56>
    brelse(lbuf);
    800047f2:	854a                	mv	a0,s2
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	d76080e7          	jalr	-650(ra) # 8000356a <brelse>
    brelse(dbuf);
    800047fc:	8526                	mv	a0,s1
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	d6c080e7          	jalr	-660(ra) # 8000356a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004806:	2a05                	addiw	s4,s4,1
    80004808:	0a91                	addi	s5,s5,4
    8000480a:	02c9a783          	lw	a5,44(s3)
    8000480e:	04fa5e63          	bge	s4,a5,8000486a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004812:	0189a583          	lw	a1,24(s3)
    80004816:	014585bb          	addw	a1,a1,s4
    8000481a:	2585                	addiw	a1,a1,1
    8000481c:	0289a503          	lw	a0,40(s3)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	c1a080e7          	jalr	-998(ra) # 8000343a <bread>
    80004828:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000482a:	000aa583          	lw	a1,0(s5)
    8000482e:	0289a503          	lw	a0,40(s3)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	c08080e7          	jalr	-1016(ra) # 8000343a <bread>
    8000483a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000483c:	40000613          	li	a2,1024
    80004840:	05890593          	addi	a1,s2,88
    80004844:	05850513          	addi	a0,a0,88
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	4d2080e7          	jalr	1234(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004850:	8526                	mv	a0,s1
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	cda080e7          	jalr	-806(ra) # 8000352c <bwrite>
    if(recovering == 0)
    8000485a:	f80b1ce3          	bnez	s6,800047f2 <install_trans+0x36>
      bunpin(dbuf);
    8000485e:	8526                	mv	a0,s1
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	de4080e7          	jalr	-540(ra) # 80003644 <bunpin>
    80004868:	b769                	j	800047f2 <install_trans+0x36>
}
    8000486a:	70e2                	ld	ra,56(sp)
    8000486c:	7442                	ld	s0,48(sp)
    8000486e:	74a2                	ld	s1,40(sp)
    80004870:	7902                	ld	s2,32(sp)
    80004872:	69e2                	ld	s3,24(sp)
    80004874:	6a42                	ld	s4,16(sp)
    80004876:	6aa2                	ld	s5,8(sp)
    80004878:	6b02                	ld	s6,0(sp)
    8000487a:	6121                	addi	sp,sp,64
    8000487c:	8082                	ret
    8000487e:	8082                	ret

0000000080004880 <initlog>:
{
    80004880:	7179                	addi	sp,sp,-48
    80004882:	f406                	sd	ra,40(sp)
    80004884:	f022                	sd	s0,32(sp)
    80004886:	ec26                	sd	s1,24(sp)
    80004888:	e84a                	sd	s2,16(sp)
    8000488a:	e44e                	sd	s3,8(sp)
    8000488c:	1800                	addi	s0,sp,48
    8000488e:	892a                	mv	s2,a0
    80004890:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004892:	0002d497          	auipc	s1,0x2d
    80004896:	dde48493          	addi	s1,s1,-546 # 80031670 <log>
    8000489a:	00004597          	auipc	a1,0x4
    8000489e:	e1658593          	addi	a1,a1,-490 # 800086b0 <syscalls+0x248>
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	28e080e7          	jalr	654(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800048ac:	0149a583          	lw	a1,20(s3)
    800048b0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048b2:	0109a783          	lw	a5,16(s3)
    800048b6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048b8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048bc:	854a                	mv	a0,s2
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	b7c080e7          	jalr	-1156(ra) # 8000343a <bread>
  log.lh.n = lh->n;
    800048c6:	4d34                	lw	a3,88(a0)
    800048c8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048ca:	02d05663          	blez	a3,800048f6 <initlog+0x76>
    800048ce:	05c50793          	addi	a5,a0,92
    800048d2:	0002d717          	auipc	a4,0x2d
    800048d6:	dce70713          	addi	a4,a4,-562 # 800316a0 <log+0x30>
    800048da:	36fd                	addiw	a3,a3,-1
    800048dc:	02069613          	slli	a2,a3,0x20
    800048e0:	01e65693          	srli	a3,a2,0x1e
    800048e4:	06050613          	addi	a2,a0,96
    800048e8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800048ea:	4390                	lw	a2,0(a5)
    800048ec:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800048ee:	0791                	addi	a5,a5,4
    800048f0:	0711                	addi	a4,a4,4
    800048f2:	fed79ce3          	bne	a5,a3,800048ea <initlog+0x6a>
  brelse(buf);
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	c74080e7          	jalr	-908(ra) # 8000356a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048fe:	4505                	li	a0,1
    80004900:	00000097          	auipc	ra,0x0
    80004904:	ebc080e7          	jalr	-324(ra) # 800047bc <install_trans>
  log.lh.n = 0;
    80004908:	0002d797          	auipc	a5,0x2d
    8000490c:	d807aa23          	sw	zero,-620(a5) # 8003169c <log+0x2c>
  write_head(); // clear the log
    80004910:	00000097          	auipc	ra,0x0
    80004914:	e30080e7          	jalr	-464(ra) # 80004740 <write_head>
}
    80004918:	70a2                	ld	ra,40(sp)
    8000491a:	7402                	ld	s0,32(sp)
    8000491c:	64e2                	ld	s1,24(sp)
    8000491e:	6942                	ld	s2,16(sp)
    80004920:	69a2                	ld	s3,8(sp)
    80004922:	6145                	addi	sp,sp,48
    80004924:	8082                	ret

0000000080004926 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004926:	1101                	addi	sp,sp,-32
    80004928:	ec06                	sd	ra,24(sp)
    8000492a:	e822                	sd	s0,16(sp)
    8000492c:	e426                	sd	s1,8(sp)
    8000492e:	e04a                	sd	s2,0(sp)
    80004930:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004932:	0002d517          	auipc	a0,0x2d
    80004936:	d3e50513          	addi	a0,a0,-706 # 80031670 <log>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	288080e7          	jalr	648(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004942:	0002d497          	auipc	s1,0x2d
    80004946:	d2e48493          	addi	s1,s1,-722 # 80031670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000494a:	4979                	li	s2,30
    8000494c:	a039                	j	8000495a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000494e:	85a6                	mv	a1,s1
    80004950:	8526                	mv	a0,s1
    80004952:	ffffe097          	auipc	ra,0xffffe
    80004956:	d5c080e7          	jalr	-676(ra) # 800026ae <sleep>
    if(log.committing){
    8000495a:	50dc                	lw	a5,36(s1)
    8000495c:	fbed                	bnez	a5,8000494e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000495e:	509c                	lw	a5,32(s1)
    80004960:	0017871b          	addiw	a4,a5,1
    80004964:	0007069b          	sext.w	a3,a4
    80004968:	0027179b          	slliw	a5,a4,0x2
    8000496c:	9fb9                	addw	a5,a5,a4
    8000496e:	0017979b          	slliw	a5,a5,0x1
    80004972:	54d8                	lw	a4,44(s1)
    80004974:	9fb9                	addw	a5,a5,a4
    80004976:	00f95963          	bge	s2,a5,80004988 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000497a:	85a6                	mv	a1,s1
    8000497c:	8526                	mv	a0,s1
    8000497e:	ffffe097          	auipc	ra,0xffffe
    80004982:	d30080e7          	jalr	-720(ra) # 800026ae <sleep>
    80004986:	bfd1                	j	8000495a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004988:	0002d517          	auipc	a0,0x2d
    8000498c:	ce850513          	addi	a0,a0,-792 # 80031670 <log>
    80004990:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	2e4080e7          	jalr	740(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000499a:	60e2                	ld	ra,24(sp)
    8000499c:	6442                	ld	s0,16(sp)
    8000499e:	64a2                	ld	s1,8(sp)
    800049a0:	6902                	ld	s2,0(sp)
    800049a2:	6105                	addi	sp,sp,32
    800049a4:	8082                	ret

00000000800049a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800049a6:	7139                	addi	sp,sp,-64
    800049a8:	fc06                	sd	ra,56(sp)
    800049aa:	f822                	sd	s0,48(sp)
    800049ac:	f426                	sd	s1,40(sp)
    800049ae:	f04a                	sd	s2,32(sp)
    800049b0:	ec4e                	sd	s3,24(sp)
    800049b2:	e852                	sd	s4,16(sp)
    800049b4:	e456                	sd	s5,8(sp)
    800049b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049b8:	0002d497          	auipc	s1,0x2d
    800049bc:	cb848493          	addi	s1,s1,-840 # 80031670 <log>
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	200080e7          	jalr	512(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800049ca:	509c                	lw	a5,32(s1)
    800049cc:	37fd                	addiw	a5,a5,-1
    800049ce:	0007891b          	sext.w	s2,a5
    800049d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049d4:	50dc                	lw	a5,36(s1)
    800049d6:	e7b9                	bnez	a5,80004a24 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049d8:	04091e63          	bnez	s2,80004a34 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800049dc:	0002d497          	auipc	s1,0x2d
    800049e0:	c9448493          	addi	s1,s1,-876 # 80031670 <log>
    800049e4:	4785                	li	a5,1
    800049e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	28c080e7          	jalr	652(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049f2:	54dc                	lw	a5,44(s1)
    800049f4:	06f04763          	bgtz	a5,80004a62 <end_op+0xbc>
    acquire(&log.lock);
    800049f8:	0002d497          	auipc	s1,0x2d
    800049fc:	c7848493          	addi	s1,s1,-904 # 80031670 <log>
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	1c0080e7          	jalr	448(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004a0a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffe097          	auipc	ra,0xffffe
    80004a14:	e2a080e7          	jalr	-470(ra) # 8000283a <wakeup>
    release(&log.lock);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	25c080e7          	jalr	604(ra) # 80000c76 <release>
}
    80004a22:	a03d                	j	80004a50 <end_op+0xaa>
    panic("log.committing");
    80004a24:	00004517          	auipc	a0,0x4
    80004a28:	c9450513          	addi	a0,a0,-876 # 800086b8 <syscalls+0x250>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	afe080e7          	jalr	-1282(ra) # 8000052a <panic>
    wakeup(&log);
    80004a34:	0002d497          	auipc	s1,0x2d
    80004a38:	c3c48493          	addi	s1,s1,-964 # 80031670 <log>
    80004a3c:	8526                	mv	a0,s1
    80004a3e:	ffffe097          	auipc	ra,0xffffe
    80004a42:	dfc080e7          	jalr	-516(ra) # 8000283a <wakeup>
  release(&log.lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	22e080e7          	jalr	558(ra) # 80000c76 <release>
}
    80004a50:	70e2                	ld	ra,56(sp)
    80004a52:	7442                	ld	s0,48(sp)
    80004a54:	74a2                	ld	s1,40(sp)
    80004a56:	7902                	ld	s2,32(sp)
    80004a58:	69e2                	ld	s3,24(sp)
    80004a5a:	6a42                	ld	s4,16(sp)
    80004a5c:	6aa2                	ld	s5,8(sp)
    80004a5e:	6121                	addi	sp,sp,64
    80004a60:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a62:	0002da97          	auipc	s5,0x2d
    80004a66:	c3ea8a93          	addi	s5,s5,-962 # 800316a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a6a:	0002da17          	auipc	s4,0x2d
    80004a6e:	c06a0a13          	addi	s4,s4,-1018 # 80031670 <log>
    80004a72:	018a2583          	lw	a1,24(s4)
    80004a76:	012585bb          	addw	a1,a1,s2
    80004a7a:	2585                	addiw	a1,a1,1
    80004a7c:	028a2503          	lw	a0,40(s4)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	9ba080e7          	jalr	-1606(ra) # 8000343a <bread>
    80004a88:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a8a:	000aa583          	lw	a1,0(s5)
    80004a8e:	028a2503          	lw	a0,40(s4)
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	9a8080e7          	jalr	-1624(ra) # 8000343a <bread>
    80004a9a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a9c:	40000613          	li	a2,1024
    80004aa0:	05850593          	addi	a1,a0,88
    80004aa4:	05848513          	addi	a0,s1,88
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	272080e7          	jalr	626(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	a7a080e7          	jalr	-1414(ra) # 8000352c <bwrite>
    brelse(from);
    80004aba:	854e                	mv	a0,s3
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	aae080e7          	jalr	-1362(ra) # 8000356a <brelse>
    brelse(to);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	aa4080e7          	jalr	-1372(ra) # 8000356a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ace:	2905                	addiw	s2,s2,1
    80004ad0:	0a91                	addi	s5,s5,4
    80004ad2:	02ca2783          	lw	a5,44(s4)
    80004ad6:	f8f94ee3          	blt	s2,a5,80004a72 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	c66080e7          	jalr	-922(ra) # 80004740 <write_head>
    install_trans(0); // Now install writes to home locations
    80004ae2:	4501                	li	a0,0
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	cd8080e7          	jalr	-808(ra) # 800047bc <install_trans>
    log.lh.n = 0;
    80004aec:	0002d797          	auipc	a5,0x2d
    80004af0:	ba07a823          	sw	zero,-1104(a5) # 8003169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	c4c080e7          	jalr	-948(ra) # 80004740 <write_head>
    80004afc:	bdf5                	j	800049f8 <end_op+0x52>

0000000080004afe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004afe:	1101                	addi	sp,sp,-32
    80004b00:	ec06                	sd	ra,24(sp)
    80004b02:	e822                	sd	s0,16(sp)
    80004b04:	e426                	sd	s1,8(sp)
    80004b06:	e04a                	sd	s2,0(sp)
    80004b08:	1000                	addi	s0,sp,32
    80004b0a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b0c:	0002d917          	auipc	s2,0x2d
    80004b10:	b6490913          	addi	s2,s2,-1180 # 80031670 <log>
    80004b14:	854a                	mv	a0,s2
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	0ac080e7          	jalr	172(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b1e:	02c92603          	lw	a2,44(s2)
    80004b22:	47f5                	li	a5,29
    80004b24:	06c7c563          	blt	a5,a2,80004b8e <log_write+0x90>
    80004b28:	0002d797          	auipc	a5,0x2d
    80004b2c:	b647a783          	lw	a5,-1180(a5) # 8003168c <log+0x1c>
    80004b30:	37fd                	addiw	a5,a5,-1
    80004b32:	04f65e63          	bge	a2,a5,80004b8e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b36:	0002d797          	auipc	a5,0x2d
    80004b3a:	b5a7a783          	lw	a5,-1190(a5) # 80031690 <log+0x20>
    80004b3e:	06f05063          	blez	a5,80004b9e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b42:	4781                	li	a5,0
    80004b44:	06c05563          	blez	a2,80004bae <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004b48:	44cc                	lw	a1,12(s1)
    80004b4a:	0002d717          	auipc	a4,0x2d
    80004b4e:	b5670713          	addi	a4,a4,-1194 # 800316a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b52:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004b54:	4314                	lw	a3,0(a4)
    80004b56:	04b68c63          	beq	a3,a1,80004bae <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b5a:	2785                	addiw	a5,a5,1
    80004b5c:	0711                	addi	a4,a4,4
    80004b5e:	fef61be3          	bne	a2,a5,80004b54 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b62:	0621                	addi	a2,a2,8
    80004b64:	060a                	slli	a2,a2,0x2
    80004b66:	0002d797          	auipc	a5,0x2d
    80004b6a:	b0a78793          	addi	a5,a5,-1270 # 80031670 <log>
    80004b6e:	963e                	add	a2,a2,a5
    80004b70:	44dc                	lw	a5,12(s1)
    80004b72:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b74:	8526                	mv	a0,s1
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	a92080e7          	jalr	-1390(ra) # 80003608 <bpin>
    log.lh.n++;
    80004b7e:	0002d717          	auipc	a4,0x2d
    80004b82:	af270713          	addi	a4,a4,-1294 # 80031670 <log>
    80004b86:	575c                	lw	a5,44(a4)
    80004b88:	2785                	addiw	a5,a5,1
    80004b8a:	d75c                	sw	a5,44(a4)
    80004b8c:	a835                	j	80004bc8 <log_write+0xca>
    panic("too big a transaction");
    80004b8e:	00004517          	auipc	a0,0x4
    80004b92:	b3a50513          	addi	a0,a0,-1222 # 800086c8 <syscalls+0x260>
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	994080e7          	jalr	-1644(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004b9e:	00004517          	auipc	a0,0x4
    80004ba2:	b4250513          	addi	a0,a0,-1214 # 800086e0 <syscalls+0x278>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	984080e7          	jalr	-1660(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004bae:	00878713          	addi	a4,a5,8
    80004bb2:	00271693          	slli	a3,a4,0x2
    80004bb6:	0002d717          	auipc	a4,0x2d
    80004bba:	aba70713          	addi	a4,a4,-1350 # 80031670 <log>
    80004bbe:	9736                	add	a4,a4,a3
    80004bc0:	44d4                	lw	a3,12(s1)
    80004bc2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bc4:	faf608e3          	beq	a2,a5,80004b74 <log_write+0x76>
  }
  release(&log.lock);
    80004bc8:	0002d517          	auipc	a0,0x2d
    80004bcc:	aa850513          	addi	a0,a0,-1368 # 80031670 <log>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0a6080e7          	jalr	166(ra) # 80000c76 <release>
}
    80004bd8:	60e2                	ld	ra,24(sp)
    80004bda:	6442                	ld	s0,16(sp)
    80004bdc:	64a2                	ld	s1,8(sp)
    80004bde:	6902                	ld	s2,0(sp)
    80004be0:	6105                	addi	sp,sp,32
    80004be2:	8082                	ret

0000000080004be4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004be4:	1101                	addi	sp,sp,-32
    80004be6:	ec06                	sd	ra,24(sp)
    80004be8:	e822                	sd	s0,16(sp)
    80004bea:	e426                	sd	s1,8(sp)
    80004bec:	e04a                	sd	s2,0(sp)
    80004bee:	1000                	addi	s0,sp,32
    80004bf0:	84aa                	mv	s1,a0
    80004bf2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bf4:	00004597          	auipc	a1,0x4
    80004bf8:	b0c58593          	addi	a1,a1,-1268 # 80008700 <syscalls+0x298>
    80004bfc:	0521                	addi	a0,a0,8
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	f34080e7          	jalr	-204(ra) # 80000b32 <initlock>
  lk->name = name;
    80004c06:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c0a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c0e:	0204a423          	sw	zero,40(s1)
}
    80004c12:	60e2                	ld	ra,24(sp)
    80004c14:	6442                	ld	s0,16(sp)
    80004c16:	64a2                	ld	s1,8(sp)
    80004c18:	6902                	ld	s2,0(sp)
    80004c1a:	6105                	addi	sp,sp,32
    80004c1c:	8082                	ret

0000000080004c1e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c1e:	1101                	addi	sp,sp,-32
    80004c20:	ec06                	sd	ra,24(sp)
    80004c22:	e822                	sd	s0,16(sp)
    80004c24:	e426                	sd	s1,8(sp)
    80004c26:	e04a                	sd	s2,0(sp)
    80004c28:	1000                	addi	s0,sp,32
    80004c2a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c2c:	00850913          	addi	s2,a0,8
    80004c30:	854a                	mv	a0,s2
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	f90080e7          	jalr	-112(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004c3a:	409c                	lw	a5,0(s1)
    80004c3c:	cb89                	beqz	a5,80004c4e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c3e:	85ca                	mv	a1,s2
    80004c40:	8526                	mv	a0,s1
    80004c42:	ffffe097          	auipc	ra,0xffffe
    80004c46:	a6c080e7          	jalr	-1428(ra) # 800026ae <sleep>
  while (lk->locked) {
    80004c4a:	409c                	lw	a5,0(s1)
    80004c4c:	fbed                	bnez	a5,80004c3e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c4e:	4785                	li	a5,1
    80004c50:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	2a8080e7          	jalr	680(ra) # 80001efa <myproc>
    80004c5a:	591c                	lw	a5,48(a0)
    80004c5c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c5e:	854a                	mv	a0,s2
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	016080e7          	jalr	22(ra) # 80000c76 <release>
}
    80004c68:	60e2                	ld	ra,24(sp)
    80004c6a:	6442                	ld	s0,16(sp)
    80004c6c:	64a2                	ld	s1,8(sp)
    80004c6e:	6902                	ld	s2,0(sp)
    80004c70:	6105                	addi	sp,sp,32
    80004c72:	8082                	ret

0000000080004c74 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c74:	1101                	addi	sp,sp,-32
    80004c76:	ec06                	sd	ra,24(sp)
    80004c78:	e822                	sd	s0,16(sp)
    80004c7a:	e426                	sd	s1,8(sp)
    80004c7c:	e04a                	sd	s2,0(sp)
    80004c7e:	1000                	addi	s0,sp,32
    80004c80:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c82:	00850913          	addi	s2,a0,8
    80004c86:	854a                	mv	a0,s2
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	f3a080e7          	jalr	-198(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004c90:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c94:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffe097          	auipc	ra,0xffffe
    80004c9e:	ba0080e7          	jalr	-1120(ra) # 8000283a <wakeup>
  release(&lk->lk);
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	fd2080e7          	jalr	-46(ra) # 80000c76 <release>
}
    80004cac:	60e2                	ld	ra,24(sp)
    80004cae:	6442                	ld	s0,16(sp)
    80004cb0:	64a2                	ld	s1,8(sp)
    80004cb2:	6902                	ld	s2,0(sp)
    80004cb4:	6105                	addi	sp,sp,32
    80004cb6:	8082                	ret

0000000080004cb8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004cb8:	7179                	addi	sp,sp,-48
    80004cba:	f406                	sd	ra,40(sp)
    80004cbc:	f022                	sd	s0,32(sp)
    80004cbe:	ec26                	sd	s1,24(sp)
    80004cc0:	e84a                	sd	s2,16(sp)
    80004cc2:	e44e                	sd	s3,8(sp)
    80004cc4:	1800                	addi	s0,sp,48
    80004cc6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cc8:	00850913          	addi	s2,a0,8
    80004ccc:	854a                	mv	a0,s2
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	ef4080e7          	jalr	-268(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cd6:	409c                	lw	a5,0(s1)
    80004cd8:	ef99                	bnez	a5,80004cf6 <holdingsleep+0x3e>
    80004cda:	4481                	li	s1,0
  release(&lk->lk);
    80004cdc:	854a                	mv	a0,s2
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	f98080e7          	jalr	-104(ra) # 80000c76 <release>
  return r;
}
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	70a2                	ld	ra,40(sp)
    80004cea:	7402                	ld	s0,32(sp)
    80004cec:	64e2                	ld	s1,24(sp)
    80004cee:	6942                	ld	s2,16(sp)
    80004cf0:	69a2                	ld	s3,8(sp)
    80004cf2:	6145                	addi	sp,sp,48
    80004cf4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cf6:	0284a983          	lw	s3,40(s1)
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	200080e7          	jalr	512(ra) # 80001efa <myproc>
    80004d02:	5904                	lw	s1,48(a0)
    80004d04:	413484b3          	sub	s1,s1,s3
    80004d08:	0014b493          	seqz	s1,s1
    80004d0c:	bfc1                	j	80004cdc <holdingsleep+0x24>

0000000080004d0e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d0e:	1141                	addi	sp,sp,-16
    80004d10:	e406                	sd	ra,8(sp)
    80004d12:	e022                	sd	s0,0(sp)
    80004d14:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d16:	00004597          	auipc	a1,0x4
    80004d1a:	9fa58593          	addi	a1,a1,-1542 # 80008710 <syscalls+0x2a8>
    80004d1e:	0002d517          	auipc	a0,0x2d
    80004d22:	a9a50513          	addi	a0,a0,-1382 # 800317b8 <ftable>
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	e0c080e7          	jalr	-500(ra) # 80000b32 <initlock>
}
    80004d2e:	60a2                	ld	ra,8(sp)
    80004d30:	6402                	ld	s0,0(sp)
    80004d32:	0141                	addi	sp,sp,16
    80004d34:	8082                	ret

0000000080004d36 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d36:	1101                	addi	sp,sp,-32
    80004d38:	ec06                	sd	ra,24(sp)
    80004d3a:	e822                	sd	s0,16(sp)
    80004d3c:	e426                	sd	s1,8(sp)
    80004d3e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d40:	0002d517          	auipc	a0,0x2d
    80004d44:	a7850513          	addi	a0,a0,-1416 # 800317b8 <ftable>
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	e7a080e7          	jalr	-390(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d50:	0002d497          	auipc	s1,0x2d
    80004d54:	a8048493          	addi	s1,s1,-1408 # 800317d0 <ftable+0x18>
    80004d58:	0002e717          	auipc	a4,0x2e
    80004d5c:	a1870713          	addi	a4,a4,-1512 # 80032770 <ftable+0xfb8>
    if(f->ref == 0){
    80004d60:	40dc                	lw	a5,4(s1)
    80004d62:	cf99                	beqz	a5,80004d80 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d64:	02848493          	addi	s1,s1,40
    80004d68:	fee49ce3          	bne	s1,a4,80004d60 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d6c:	0002d517          	auipc	a0,0x2d
    80004d70:	a4c50513          	addi	a0,a0,-1460 # 800317b8 <ftable>
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f02080e7          	jalr	-254(ra) # 80000c76 <release>
  return 0;
    80004d7c:	4481                	li	s1,0
    80004d7e:	a819                	j	80004d94 <filealloc+0x5e>
      f->ref = 1;
    80004d80:	4785                	li	a5,1
    80004d82:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d84:	0002d517          	auipc	a0,0x2d
    80004d88:	a3450513          	addi	a0,a0,-1484 # 800317b8 <ftable>
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	eea080e7          	jalr	-278(ra) # 80000c76 <release>
}
    80004d94:	8526                	mv	a0,s1
    80004d96:	60e2                	ld	ra,24(sp)
    80004d98:	6442                	ld	s0,16(sp)
    80004d9a:	64a2                	ld	s1,8(sp)
    80004d9c:	6105                	addi	sp,sp,32
    80004d9e:	8082                	ret

0000000080004da0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004da0:	1101                	addi	sp,sp,-32
    80004da2:	ec06                	sd	ra,24(sp)
    80004da4:	e822                	sd	s0,16(sp)
    80004da6:	e426                	sd	s1,8(sp)
    80004da8:	1000                	addi	s0,sp,32
    80004daa:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004dac:	0002d517          	auipc	a0,0x2d
    80004db0:	a0c50513          	addi	a0,a0,-1524 # 800317b8 <ftable>
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	e0e080e7          	jalr	-498(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004dbc:	40dc                	lw	a5,4(s1)
    80004dbe:	02f05263          	blez	a5,80004de2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004dc2:	2785                	addiw	a5,a5,1
    80004dc4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004dc6:	0002d517          	auipc	a0,0x2d
    80004dca:	9f250513          	addi	a0,a0,-1550 # 800317b8 <ftable>
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	ea8080e7          	jalr	-344(ra) # 80000c76 <release>
  return f;
}
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	60e2                	ld	ra,24(sp)
    80004dda:	6442                	ld	s0,16(sp)
    80004ddc:	64a2                	ld	s1,8(sp)
    80004dde:	6105                	addi	sp,sp,32
    80004de0:	8082                	ret
    panic("filedup");
    80004de2:	00004517          	auipc	a0,0x4
    80004de6:	93650513          	addi	a0,a0,-1738 # 80008718 <syscalls+0x2b0>
    80004dea:	ffffb097          	auipc	ra,0xffffb
    80004dee:	740080e7          	jalr	1856(ra) # 8000052a <panic>

0000000080004df2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004df2:	7139                	addi	sp,sp,-64
    80004df4:	fc06                	sd	ra,56(sp)
    80004df6:	f822                	sd	s0,48(sp)
    80004df8:	f426                	sd	s1,40(sp)
    80004dfa:	f04a                	sd	s2,32(sp)
    80004dfc:	ec4e                	sd	s3,24(sp)
    80004dfe:	e852                	sd	s4,16(sp)
    80004e00:	e456                	sd	s5,8(sp)
    80004e02:	0080                	addi	s0,sp,64
    80004e04:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e06:	0002d517          	auipc	a0,0x2d
    80004e0a:	9b250513          	addi	a0,a0,-1614 # 800317b8 <ftable>
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	db4080e7          	jalr	-588(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004e16:	40dc                	lw	a5,4(s1)
    80004e18:	06f05163          	blez	a5,80004e7a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e1c:	37fd                	addiw	a5,a5,-1
    80004e1e:	0007871b          	sext.w	a4,a5
    80004e22:	c0dc                	sw	a5,4(s1)
    80004e24:	06e04363          	bgtz	a4,80004e8a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e28:	0004a903          	lw	s2,0(s1)
    80004e2c:	0094ca83          	lbu	s5,9(s1)
    80004e30:	0104ba03          	ld	s4,16(s1)
    80004e34:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e38:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e3c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e40:	0002d517          	auipc	a0,0x2d
    80004e44:	97850513          	addi	a0,a0,-1672 # 800317b8 <ftable>
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e2e080e7          	jalr	-466(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004e50:	4785                	li	a5,1
    80004e52:	04f90d63          	beq	s2,a5,80004eac <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e56:	3979                	addiw	s2,s2,-2
    80004e58:	4785                	li	a5,1
    80004e5a:	0527e063          	bltu	a5,s2,80004e9a <fileclose+0xa8>
    begin_op();
    80004e5e:	00000097          	auipc	ra,0x0
    80004e62:	ac8080e7          	jalr	-1336(ra) # 80004926 <begin_op>
    iput(ff.ip);
    80004e66:	854e                	mv	a0,s3
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	f90080e7          	jalr	-112(ra) # 80003df8 <iput>
    end_op();
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	b36080e7          	jalr	-1226(ra) # 800049a6 <end_op>
    80004e78:	a00d                	j	80004e9a <fileclose+0xa8>
    panic("fileclose");
    80004e7a:	00004517          	auipc	a0,0x4
    80004e7e:	8a650513          	addi	a0,a0,-1882 # 80008720 <syscalls+0x2b8>
    80004e82:	ffffb097          	auipc	ra,0xffffb
    80004e86:	6a8080e7          	jalr	1704(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004e8a:	0002d517          	auipc	a0,0x2d
    80004e8e:	92e50513          	addi	a0,a0,-1746 # 800317b8 <ftable>
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	de4080e7          	jalr	-540(ra) # 80000c76 <release>
  }
}
    80004e9a:	70e2                	ld	ra,56(sp)
    80004e9c:	7442                	ld	s0,48(sp)
    80004e9e:	74a2                	ld	s1,40(sp)
    80004ea0:	7902                	ld	s2,32(sp)
    80004ea2:	69e2                	ld	s3,24(sp)
    80004ea4:	6a42                	ld	s4,16(sp)
    80004ea6:	6aa2                	ld	s5,8(sp)
    80004ea8:	6121                	addi	sp,sp,64
    80004eaa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004eac:	85d6                	mv	a1,s5
    80004eae:	8552                	mv	a0,s4
    80004eb0:	00000097          	auipc	ra,0x0
    80004eb4:	542080e7          	jalr	1346(ra) # 800053f2 <pipeclose>
    80004eb8:	b7cd                	j	80004e9a <fileclose+0xa8>

0000000080004eba <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004eba:	715d                	addi	sp,sp,-80
    80004ebc:	e486                	sd	ra,72(sp)
    80004ebe:	e0a2                	sd	s0,64(sp)
    80004ec0:	fc26                	sd	s1,56(sp)
    80004ec2:	f84a                	sd	s2,48(sp)
    80004ec4:	f44e                	sd	s3,40(sp)
    80004ec6:	0880                	addi	s0,sp,80
    80004ec8:	84aa                	mv	s1,a0
    80004eca:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	02e080e7          	jalr	46(ra) # 80001efa <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ed4:	409c                	lw	a5,0(s1)
    80004ed6:	37f9                	addiw	a5,a5,-2
    80004ed8:	4705                	li	a4,1
    80004eda:	04f76763          	bltu	a4,a5,80004f28 <filestat+0x6e>
    80004ede:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ee0:	6c88                	ld	a0,24(s1)
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	d5c080e7          	jalr	-676(ra) # 80003c3e <ilock>
    stati(f->ip, &st);
    80004eea:	fb840593          	addi	a1,s0,-72
    80004eee:	6c88                	ld	a0,24(s1)
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	fd8080e7          	jalr	-40(ra) # 80003ec8 <stati>
    iunlock(f->ip);
    80004ef8:	6c88                	ld	a0,24(s1)
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	e06080e7          	jalr	-506(ra) # 80003d00 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f02:	46e1                	li	a3,24
    80004f04:	fb840613          	addi	a2,s0,-72
    80004f08:	85ce                	mv	a1,s3
    80004f0a:	05093503          	ld	a0,80(s2)
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	75a080e7          	jalr	1882(ra) # 80001668 <copyout>
    80004f16:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f1a:	60a6                	ld	ra,72(sp)
    80004f1c:	6406                	ld	s0,64(sp)
    80004f1e:	74e2                	ld	s1,56(sp)
    80004f20:	7942                	ld	s2,48(sp)
    80004f22:	79a2                	ld	s3,40(sp)
    80004f24:	6161                	addi	sp,sp,80
    80004f26:	8082                	ret
  return -1;
    80004f28:	557d                	li	a0,-1
    80004f2a:	bfc5                	j	80004f1a <filestat+0x60>

0000000080004f2c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f2c:	7179                	addi	sp,sp,-48
    80004f2e:	f406                	sd	ra,40(sp)
    80004f30:	f022                	sd	s0,32(sp)
    80004f32:	ec26                	sd	s1,24(sp)
    80004f34:	e84a                	sd	s2,16(sp)
    80004f36:	e44e                	sd	s3,8(sp)
    80004f38:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f3a:	00854783          	lbu	a5,8(a0)
    80004f3e:	c3d5                	beqz	a5,80004fe2 <fileread+0xb6>
    80004f40:	84aa                	mv	s1,a0
    80004f42:	89ae                	mv	s3,a1
    80004f44:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f46:	411c                	lw	a5,0(a0)
    80004f48:	4705                	li	a4,1
    80004f4a:	04e78963          	beq	a5,a4,80004f9c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f4e:	470d                	li	a4,3
    80004f50:	04e78d63          	beq	a5,a4,80004faa <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f54:	4709                	li	a4,2
    80004f56:	06e79e63          	bne	a5,a4,80004fd2 <fileread+0xa6>
    ilock(f->ip);
    80004f5a:	6d08                	ld	a0,24(a0)
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	ce2080e7          	jalr	-798(ra) # 80003c3e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f64:	874a                	mv	a4,s2
    80004f66:	5094                	lw	a3,32(s1)
    80004f68:	864e                	mv	a2,s3
    80004f6a:	4585                	li	a1,1
    80004f6c:	6c88                	ld	a0,24(s1)
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	f84080e7          	jalr	-124(ra) # 80003ef2 <readi>
    80004f76:	892a                	mv	s2,a0
    80004f78:	00a05563          	blez	a0,80004f82 <fileread+0x56>
      f->off += r;
    80004f7c:	509c                	lw	a5,32(s1)
    80004f7e:	9fa9                	addw	a5,a5,a0
    80004f80:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f82:	6c88                	ld	a0,24(s1)
    80004f84:	fffff097          	auipc	ra,0xfffff
    80004f88:	d7c080e7          	jalr	-644(ra) # 80003d00 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f8c:	854a                	mv	a0,s2
    80004f8e:	70a2                	ld	ra,40(sp)
    80004f90:	7402                	ld	s0,32(sp)
    80004f92:	64e2                	ld	s1,24(sp)
    80004f94:	6942                	ld	s2,16(sp)
    80004f96:	69a2                	ld	s3,8(sp)
    80004f98:	6145                	addi	sp,sp,48
    80004f9a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f9c:	6908                	ld	a0,16(a0)
    80004f9e:	00000097          	auipc	ra,0x0
    80004fa2:	5b6080e7          	jalr	1462(ra) # 80005554 <piperead>
    80004fa6:	892a                	mv	s2,a0
    80004fa8:	b7d5                	j	80004f8c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004faa:	02451783          	lh	a5,36(a0)
    80004fae:	03079693          	slli	a3,a5,0x30
    80004fb2:	92c1                	srli	a3,a3,0x30
    80004fb4:	4725                	li	a4,9
    80004fb6:	02d76863          	bltu	a4,a3,80004fe6 <fileread+0xba>
    80004fba:	0792                	slli	a5,a5,0x4
    80004fbc:	0002c717          	auipc	a4,0x2c
    80004fc0:	75c70713          	addi	a4,a4,1884 # 80031718 <devsw>
    80004fc4:	97ba                	add	a5,a5,a4
    80004fc6:	639c                	ld	a5,0(a5)
    80004fc8:	c38d                	beqz	a5,80004fea <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fca:	4505                	li	a0,1
    80004fcc:	9782                	jalr	a5
    80004fce:	892a                	mv	s2,a0
    80004fd0:	bf75                	j	80004f8c <fileread+0x60>
    panic("fileread");
    80004fd2:	00003517          	auipc	a0,0x3
    80004fd6:	75e50513          	addi	a0,a0,1886 # 80008730 <syscalls+0x2c8>
    80004fda:	ffffb097          	auipc	ra,0xffffb
    80004fde:	550080e7          	jalr	1360(ra) # 8000052a <panic>
    return -1;
    80004fe2:	597d                	li	s2,-1
    80004fe4:	b765                	j	80004f8c <fileread+0x60>
      return -1;
    80004fe6:	597d                	li	s2,-1
    80004fe8:	b755                	j	80004f8c <fileread+0x60>
    80004fea:	597d                	li	s2,-1
    80004fec:	b745                	j	80004f8c <fileread+0x60>

0000000080004fee <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004fee:	715d                	addi	sp,sp,-80
    80004ff0:	e486                	sd	ra,72(sp)
    80004ff2:	e0a2                	sd	s0,64(sp)
    80004ff4:	fc26                	sd	s1,56(sp)
    80004ff6:	f84a                	sd	s2,48(sp)
    80004ff8:	f44e                	sd	s3,40(sp)
    80004ffa:	f052                	sd	s4,32(sp)
    80004ffc:	ec56                	sd	s5,24(sp)
    80004ffe:	e85a                	sd	s6,16(sp)
    80005000:	e45e                	sd	s7,8(sp)
    80005002:	e062                	sd	s8,0(sp)
    80005004:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005006:	00954783          	lbu	a5,9(a0)
    8000500a:	10078663          	beqz	a5,80005116 <filewrite+0x128>
    8000500e:	892a                	mv	s2,a0
    80005010:	8aae                	mv	s5,a1
    80005012:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005014:	411c                	lw	a5,0(a0)
    80005016:	4705                	li	a4,1
    80005018:	02e78263          	beq	a5,a4,8000503c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000501c:	470d                	li	a4,3
    8000501e:	02e78663          	beq	a5,a4,8000504a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005022:	4709                	li	a4,2
    80005024:	0ee79163          	bne	a5,a4,80005106 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005028:	0ac05d63          	blez	a2,800050e2 <filewrite+0xf4>
    int i = 0;
    8000502c:	4981                	li	s3,0
    8000502e:	6b05                	lui	s6,0x1
    80005030:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005034:	6b85                	lui	s7,0x1
    80005036:	c00b8b9b          	addiw	s7,s7,-1024
    8000503a:	a861                	j	800050d2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000503c:	6908                	ld	a0,16(a0)
    8000503e:	00000097          	auipc	ra,0x0
    80005042:	424080e7          	jalr	1060(ra) # 80005462 <pipewrite>
    80005046:	8a2a                	mv	s4,a0
    80005048:	a045                	j	800050e8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000504a:	02451783          	lh	a5,36(a0)
    8000504e:	03079693          	slli	a3,a5,0x30
    80005052:	92c1                	srli	a3,a3,0x30
    80005054:	4725                	li	a4,9
    80005056:	0cd76263          	bltu	a4,a3,8000511a <filewrite+0x12c>
    8000505a:	0792                	slli	a5,a5,0x4
    8000505c:	0002c717          	auipc	a4,0x2c
    80005060:	6bc70713          	addi	a4,a4,1724 # 80031718 <devsw>
    80005064:	97ba                	add	a5,a5,a4
    80005066:	679c                	ld	a5,8(a5)
    80005068:	cbdd                	beqz	a5,8000511e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000506a:	4505                	li	a0,1
    8000506c:	9782                	jalr	a5
    8000506e:	8a2a                	mv	s4,a0
    80005070:	a8a5                	j	800050e8 <filewrite+0xfa>
    80005072:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005076:	00000097          	auipc	ra,0x0
    8000507a:	8b0080e7          	jalr	-1872(ra) # 80004926 <begin_op>
      ilock(f->ip);
    8000507e:	01893503          	ld	a0,24(s2)
    80005082:	fffff097          	auipc	ra,0xfffff
    80005086:	bbc080e7          	jalr	-1092(ra) # 80003c3e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000508a:	8762                	mv	a4,s8
    8000508c:	02092683          	lw	a3,32(s2)
    80005090:	01598633          	add	a2,s3,s5
    80005094:	4585                	li	a1,1
    80005096:	01893503          	ld	a0,24(s2)
    8000509a:	fffff097          	auipc	ra,0xfffff
    8000509e:	f50080e7          	jalr	-176(ra) # 80003fea <writei>
    800050a2:	84aa                	mv	s1,a0
    800050a4:	00a05763          	blez	a0,800050b2 <filewrite+0xc4>
        f->off += r;
    800050a8:	02092783          	lw	a5,32(s2)
    800050ac:	9fa9                	addw	a5,a5,a0
    800050ae:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050b2:	01893503          	ld	a0,24(s2)
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	c4a080e7          	jalr	-950(ra) # 80003d00 <iunlock>
      end_op();
    800050be:	00000097          	auipc	ra,0x0
    800050c2:	8e8080e7          	jalr	-1816(ra) # 800049a6 <end_op>

      if(r != n1){
    800050c6:	009c1f63          	bne	s8,s1,800050e4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050ca:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050ce:	0149db63          	bge	s3,s4,800050e4 <filewrite+0xf6>
      int n1 = n - i;
    800050d2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050d6:	84be                	mv	s1,a5
    800050d8:	2781                	sext.w	a5,a5
    800050da:	f8fb5ce3          	bge	s6,a5,80005072 <filewrite+0x84>
    800050de:	84de                	mv	s1,s7
    800050e0:	bf49                	j	80005072 <filewrite+0x84>
    int i = 0;
    800050e2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050e4:	013a1f63          	bne	s4,s3,80005102 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050e8:	8552                	mv	a0,s4
    800050ea:	60a6                	ld	ra,72(sp)
    800050ec:	6406                	ld	s0,64(sp)
    800050ee:	74e2                	ld	s1,56(sp)
    800050f0:	7942                	ld	s2,48(sp)
    800050f2:	79a2                	ld	s3,40(sp)
    800050f4:	7a02                	ld	s4,32(sp)
    800050f6:	6ae2                	ld	s5,24(sp)
    800050f8:	6b42                	ld	s6,16(sp)
    800050fa:	6ba2                	ld	s7,8(sp)
    800050fc:	6c02                	ld	s8,0(sp)
    800050fe:	6161                	addi	sp,sp,80
    80005100:	8082                	ret
    ret = (i == n ? n : -1);
    80005102:	5a7d                	li	s4,-1
    80005104:	b7d5                	j	800050e8 <filewrite+0xfa>
    panic("filewrite");
    80005106:	00003517          	auipc	a0,0x3
    8000510a:	63a50513          	addi	a0,a0,1594 # 80008740 <syscalls+0x2d8>
    8000510e:	ffffb097          	auipc	ra,0xffffb
    80005112:	41c080e7          	jalr	1052(ra) # 8000052a <panic>
    return -1;
    80005116:	5a7d                	li	s4,-1
    80005118:	bfc1                	j	800050e8 <filewrite+0xfa>
      return -1;
    8000511a:	5a7d                	li	s4,-1
    8000511c:	b7f1                	j	800050e8 <filewrite+0xfa>
    8000511e:	5a7d                	li	s4,-1
    80005120:	b7e1                	j	800050e8 <filewrite+0xfa>

0000000080005122 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005122:	7179                	addi	sp,sp,-48
    80005124:	f406                	sd	ra,40(sp)
    80005126:	f022                	sd	s0,32(sp)
    80005128:	ec26                	sd	s1,24(sp)
    8000512a:	e84a                	sd	s2,16(sp)
    8000512c:	e44e                	sd	s3,8(sp)
    8000512e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005130:	00854783          	lbu	a5,8(a0)
    80005134:	c3d5                	beqz	a5,800051d8 <kfileread+0xb6>
    80005136:	84aa                	mv	s1,a0
    80005138:	89ae                	mv	s3,a1
    8000513a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000513c:	411c                	lw	a5,0(a0)
    8000513e:	4705                	li	a4,1
    80005140:	04e78963          	beq	a5,a4,80005192 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005144:	470d                	li	a4,3
    80005146:	04e78d63          	beq	a5,a4,800051a0 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000514a:	4709                	li	a4,2
    8000514c:	06e79e63          	bne	a5,a4,800051c8 <kfileread+0xa6>
    ilock(f->ip);
    80005150:	6d08                	ld	a0,24(a0)
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	aec080e7          	jalr	-1300(ra) # 80003c3e <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    8000515a:	874a                	mv	a4,s2
    8000515c:	5094                	lw	a3,32(s1)
    8000515e:	864e                	mv	a2,s3
    80005160:	4581                	li	a1,0
    80005162:	6c88                	ld	a0,24(s1)
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	d8e080e7          	jalr	-626(ra) # 80003ef2 <readi>
    8000516c:	892a                	mv	s2,a0
    8000516e:	00a05563          	blez	a0,80005178 <kfileread+0x56>
      f->off += r;
    80005172:	509c                	lw	a5,32(s1)
    80005174:	9fa9                	addw	a5,a5,a0
    80005176:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005178:	6c88                	ld	a0,24(s1)
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	b86080e7          	jalr	-1146(ra) # 80003d00 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005182:	854a                	mv	a0,s2
    80005184:	70a2                	ld	ra,40(sp)
    80005186:	7402                	ld	s0,32(sp)
    80005188:	64e2                	ld	s1,24(sp)
    8000518a:	6942                	ld	s2,16(sp)
    8000518c:	69a2                	ld	s3,8(sp)
    8000518e:	6145                	addi	sp,sp,48
    80005190:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005192:	6908                	ld	a0,16(a0)
    80005194:	00000097          	auipc	ra,0x0
    80005198:	3c0080e7          	jalr	960(ra) # 80005554 <piperead>
    8000519c:	892a                	mv	s2,a0
    8000519e:	b7d5                	j	80005182 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800051a0:	02451783          	lh	a5,36(a0)
    800051a4:	03079693          	slli	a3,a5,0x30
    800051a8:	92c1                	srli	a3,a3,0x30
    800051aa:	4725                	li	a4,9
    800051ac:	02d76863          	bltu	a4,a3,800051dc <kfileread+0xba>
    800051b0:	0792                	slli	a5,a5,0x4
    800051b2:	0002c717          	auipc	a4,0x2c
    800051b6:	56670713          	addi	a4,a4,1382 # 80031718 <devsw>
    800051ba:	97ba                	add	a5,a5,a4
    800051bc:	639c                	ld	a5,0(a5)
    800051be:	c38d                	beqz	a5,800051e0 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051c0:	4505                	li	a0,1
    800051c2:	9782                	jalr	a5
    800051c4:	892a                	mv	s2,a0
    800051c6:	bf75                	j	80005182 <kfileread+0x60>
    panic("fileread");
    800051c8:	00003517          	auipc	a0,0x3
    800051cc:	56850513          	addi	a0,a0,1384 # 80008730 <syscalls+0x2c8>
    800051d0:	ffffb097          	auipc	ra,0xffffb
    800051d4:	35a080e7          	jalr	858(ra) # 8000052a <panic>
    return -1;
    800051d8:	597d                	li	s2,-1
    800051da:	b765                	j	80005182 <kfileread+0x60>
      return -1;
    800051dc:	597d                	li	s2,-1
    800051de:	b755                	j	80005182 <kfileread+0x60>
    800051e0:	597d                	li	s2,-1
    800051e2:	b745                	j	80005182 <kfileread+0x60>

00000000800051e4 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800051e4:	715d                	addi	sp,sp,-80
    800051e6:	e486                	sd	ra,72(sp)
    800051e8:	e0a2                	sd	s0,64(sp)
    800051ea:	fc26                	sd	s1,56(sp)
    800051ec:	f84a                	sd	s2,48(sp)
    800051ee:	f44e                	sd	s3,40(sp)
    800051f0:	f052                	sd	s4,32(sp)
    800051f2:	ec56                	sd	s5,24(sp)
    800051f4:	e85a                	sd	s6,16(sp)
    800051f6:	e45e                	sd	s7,8(sp)
    800051f8:	e062                	sd	s8,0(sp)
    800051fa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800051fc:	00954783          	lbu	a5,9(a0)
    80005200:	10078663          	beqz	a5,8000530c <kfilewrite+0x128>
    80005204:	892a                	mv	s2,a0
    80005206:	8aae                	mv	s5,a1
    80005208:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000520a:	411c                	lw	a5,0(a0)
    8000520c:	4705                	li	a4,1
    8000520e:	02e78263          	beq	a5,a4,80005232 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005212:	470d                	li	a4,3
    80005214:	02e78663          	beq	a5,a4,80005240 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005218:	4709                	li	a4,2
    8000521a:	0ee79163          	bne	a5,a4,800052fc <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000521e:	0ac05d63          	blez	a2,800052d8 <kfilewrite+0xf4>
    int i = 0;
    80005222:	4981                	li	s3,0
    80005224:	6b05                	lui	s6,0x1
    80005226:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000522a:	6b85                	lui	s7,0x1
    8000522c:	c00b8b9b          	addiw	s7,s7,-1024
    80005230:	a861                	j	800052c8 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005232:	6908                	ld	a0,16(a0)
    80005234:	00000097          	auipc	ra,0x0
    80005238:	22e080e7          	jalr	558(ra) # 80005462 <pipewrite>
    8000523c:	8a2a                	mv	s4,a0
    8000523e:	a045                	j	800052de <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005240:	02451783          	lh	a5,36(a0)
    80005244:	03079693          	slli	a3,a5,0x30
    80005248:	92c1                	srli	a3,a3,0x30
    8000524a:	4725                	li	a4,9
    8000524c:	0cd76263          	bltu	a4,a3,80005310 <kfilewrite+0x12c>
    80005250:	0792                	slli	a5,a5,0x4
    80005252:	0002c717          	auipc	a4,0x2c
    80005256:	4c670713          	addi	a4,a4,1222 # 80031718 <devsw>
    8000525a:	97ba                	add	a5,a5,a4
    8000525c:	679c                	ld	a5,8(a5)
    8000525e:	cbdd                	beqz	a5,80005314 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005260:	4505                	li	a0,1
    80005262:	9782                	jalr	a5
    80005264:	8a2a                	mv	s4,a0
    80005266:	a8a5                	j	800052de <kfilewrite+0xfa>
    80005268:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	6ba080e7          	jalr	1722(ra) # 80004926 <begin_op>
      ilock(f->ip);
    80005274:	01893503          	ld	a0,24(s2)
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	9c6080e7          	jalr	-1594(ra) # 80003c3e <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005280:	8762                	mv	a4,s8
    80005282:	02092683          	lw	a3,32(s2)
    80005286:	01598633          	add	a2,s3,s5
    8000528a:	4581                	li	a1,0
    8000528c:	01893503          	ld	a0,24(s2)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	d5a080e7          	jalr	-678(ra) # 80003fea <writei>
    80005298:	84aa                	mv	s1,a0
    8000529a:	00a05763          	blez	a0,800052a8 <kfilewrite+0xc4>
        f->off += r;
    8000529e:	02092783          	lw	a5,32(s2)
    800052a2:	9fa9                	addw	a5,a5,a0
    800052a4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800052a8:	01893503          	ld	a0,24(s2)
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	a54080e7          	jalr	-1452(ra) # 80003d00 <iunlock>
      end_op();
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	6f2080e7          	jalr	1778(ra) # 800049a6 <end_op>

      if(r != n1){
    800052bc:	009c1f63          	bne	s8,s1,800052da <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800052c0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052c4:	0149db63          	bge	s3,s4,800052da <kfilewrite+0xf6>
      int n1 = n - i;
    800052c8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800052cc:	84be                	mv	s1,a5
    800052ce:	2781                	sext.w	a5,a5
    800052d0:	f8fb5ce3          	bge	s6,a5,80005268 <kfilewrite+0x84>
    800052d4:	84de                	mv	s1,s7
    800052d6:	bf49                	j	80005268 <kfilewrite+0x84>
    int i = 0;
    800052d8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800052da:	013a1f63          	bne	s4,s3,800052f8 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    800052de:	8552                	mv	a0,s4
    800052e0:	60a6                	ld	ra,72(sp)
    800052e2:	6406                	ld	s0,64(sp)
    800052e4:	74e2                	ld	s1,56(sp)
    800052e6:	7942                	ld	s2,48(sp)
    800052e8:	79a2                	ld	s3,40(sp)
    800052ea:	7a02                	ld	s4,32(sp)
    800052ec:	6ae2                	ld	s5,24(sp)
    800052ee:	6b42                	ld	s6,16(sp)
    800052f0:	6ba2                	ld	s7,8(sp)
    800052f2:	6c02                	ld	s8,0(sp)
    800052f4:	6161                	addi	sp,sp,80
    800052f6:	8082                	ret
    ret = (i == n ? n : -1);
    800052f8:	5a7d                	li	s4,-1
    800052fa:	b7d5                	j	800052de <kfilewrite+0xfa>
    panic("filewrite");
    800052fc:	00003517          	auipc	a0,0x3
    80005300:	44450513          	addi	a0,a0,1092 # 80008740 <syscalls+0x2d8>
    80005304:	ffffb097          	auipc	ra,0xffffb
    80005308:	226080e7          	jalr	550(ra) # 8000052a <panic>
    return -1;
    8000530c:	5a7d                	li	s4,-1
    8000530e:	bfc1                	j	800052de <kfilewrite+0xfa>
      return -1;
    80005310:	5a7d                	li	s4,-1
    80005312:	b7f1                	j	800052de <kfilewrite+0xfa>
    80005314:	5a7d                	li	s4,-1
    80005316:	b7e1                	j	800052de <kfilewrite+0xfa>

0000000080005318 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005318:	7179                	addi	sp,sp,-48
    8000531a:	f406                	sd	ra,40(sp)
    8000531c:	f022                	sd	s0,32(sp)
    8000531e:	ec26                	sd	s1,24(sp)
    80005320:	e84a                	sd	s2,16(sp)
    80005322:	e44e                	sd	s3,8(sp)
    80005324:	e052                	sd	s4,0(sp)
    80005326:	1800                	addi	s0,sp,48
    80005328:	84aa                	mv	s1,a0
    8000532a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000532c:	0005b023          	sd	zero,0(a1)
    80005330:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005334:	00000097          	auipc	ra,0x0
    80005338:	a02080e7          	jalr	-1534(ra) # 80004d36 <filealloc>
    8000533c:	e088                	sd	a0,0(s1)
    8000533e:	c551                	beqz	a0,800053ca <pipealloc+0xb2>
    80005340:	00000097          	auipc	ra,0x0
    80005344:	9f6080e7          	jalr	-1546(ra) # 80004d36 <filealloc>
    80005348:	00aa3023          	sd	a0,0(s4)
    8000534c:	c92d                	beqz	a0,800053be <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	784080e7          	jalr	1924(ra) # 80000ad2 <kalloc>
    80005356:	892a                	mv	s2,a0
    80005358:	c125                	beqz	a0,800053b8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000535a:	4985                	li	s3,1
    8000535c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005360:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005364:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005368:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000536c:	00003597          	auipc	a1,0x3
    80005370:	3e458593          	addi	a1,a1,996 # 80008750 <syscalls+0x2e8>
    80005374:	ffffb097          	auipc	ra,0xffffb
    80005378:	7be080e7          	jalr	1982(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    8000537c:	609c                	ld	a5,0(s1)
    8000537e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005382:	609c                	ld	a5,0(s1)
    80005384:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005388:	609c                	ld	a5,0(s1)
    8000538a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000538e:	609c                	ld	a5,0(s1)
    80005390:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005394:	000a3783          	ld	a5,0(s4)
    80005398:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000539c:	000a3783          	ld	a5,0(s4)
    800053a0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800053a4:	000a3783          	ld	a5,0(s4)
    800053a8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053ac:	000a3783          	ld	a5,0(s4)
    800053b0:	0127b823          	sd	s2,16(a5)
  return 0;
    800053b4:	4501                	li	a0,0
    800053b6:	a025                	j	800053de <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053b8:	6088                	ld	a0,0(s1)
    800053ba:	e501                	bnez	a0,800053c2 <pipealloc+0xaa>
    800053bc:	a039                	j	800053ca <pipealloc+0xb2>
    800053be:	6088                	ld	a0,0(s1)
    800053c0:	c51d                	beqz	a0,800053ee <pipealloc+0xd6>
    fileclose(*f0);
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	a30080e7          	jalr	-1488(ra) # 80004df2 <fileclose>
  if(*f1)
    800053ca:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053ce:	557d                	li	a0,-1
  if(*f1)
    800053d0:	c799                	beqz	a5,800053de <pipealloc+0xc6>
    fileclose(*f1);
    800053d2:	853e                	mv	a0,a5
    800053d4:	00000097          	auipc	ra,0x0
    800053d8:	a1e080e7          	jalr	-1506(ra) # 80004df2 <fileclose>
  return -1;
    800053dc:	557d                	li	a0,-1
}
    800053de:	70a2                	ld	ra,40(sp)
    800053e0:	7402                	ld	s0,32(sp)
    800053e2:	64e2                	ld	s1,24(sp)
    800053e4:	6942                	ld	s2,16(sp)
    800053e6:	69a2                	ld	s3,8(sp)
    800053e8:	6a02                	ld	s4,0(sp)
    800053ea:	6145                	addi	sp,sp,48
    800053ec:	8082                	ret
  return -1;
    800053ee:	557d                	li	a0,-1
    800053f0:	b7fd                	j	800053de <pipealloc+0xc6>

00000000800053f2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053f2:	1101                	addi	sp,sp,-32
    800053f4:	ec06                	sd	ra,24(sp)
    800053f6:	e822                	sd	s0,16(sp)
    800053f8:	e426                	sd	s1,8(sp)
    800053fa:	e04a                	sd	s2,0(sp)
    800053fc:	1000                	addi	s0,sp,32
    800053fe:	84aa                	mv	s1,a0
    80005400:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005402:	ffffb097          	auipc	ra,0xffffb
    80005406:	7c0080e7          	jalr	1984(ra) # 80000bc2 <acquire>
  if(writable){
    8000540a:	02090d63          	beqz	s2,80005444 <pipeclose+0x52>
    pi->writeopen = 0;
    8000540e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005412:	21848513          	addi	a0,s1,536
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	424080e7          	jalr	1060(ra) # 8000283a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000541e:	2204b783          	ld	a5,544(s1)
    80005422:	eb95                	bnez	a5,80005456 <pipeclose+0x64>
    release(&pi->lock);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffc097          	auipc	ra,0xffffc
    8000542a:	850080e7          	jalr	-1968(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffb097          	auipc	ra,0xffffb
    80005434:	5a6080e7          	jalr	1446(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005438:	60e2                	ld	ra,24(sp)
    8000543a:	6442                	ld	s0,16(sp)
    8000543c:	64a2                	ld	s1,8(sp)
    8000543e:	6902                	ld	s2,0(sp)
    80005440:	6105                	addi	sp,sp,32
    80005442:	8082                	ret
    pi->readopen = 0;
    80005444:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005448:	21c48513          	addi	a0,s1,540
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	3ee080e7          	jalr	1006(ra) # 8000283a <wakeup>
    80005454:	b7e9                	j	8000541e <pipeclose+0x2c>
    release(&pi->lock);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	81e080e7          	jalr	-2018(ra) # 80000c76 <release>
}
    80005460:	bfe1                	j	80005438 <pipeclose+0x46>

0000000080005462 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005462:	711d                	addi	sp,sp,-96
    80005464:	ec86                	sd	ra,88(sp)
    80005466:	e8a2                	sd	s0,80(sp)
    80005468:	e4a6                	sd	s1,72(sp)
    8000546a:	e0ca                	sd	s2,64(sp)
    8000546c:	fc4e                	sd	s3,56(sp)
    8000546e:	f852                	sd	s4,48(sp)
    80005470:	f456                	sd	s5,40(sp)
    80005472:	f05a                	sd	s6,32(sp)
    80005474:	ec5e                	sd	s7,24(sp)
    80005476:	e862                	sd	s8,16(sp)
    80005478:	1080                	addi	s0,sp,96
    8000547a:	84aa                	mv	s1,a0
    8000547c:	8aae                	mv	s5,a1
    8000547e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005480:	ffffd097          	auipc	ra,0xffffd
    80005484:	a7a080e7          	jalr	-1414(ra) # 80001efa <myproc>
    80005488:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffb097          	auipc	ra,0xffffb
    80005490:	736080e7          	jalr	1846(ra) # 80000bc2 <acquire>
  while(i < n){
    80005494:	0b405363          	blez	s4,8000553a <pipewrite+0xd8>
  int i = 0;
    80005498:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000549a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000549c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800054a0:	21c48b93          	addi	s7,s1,540
    800054a4:	a089                	j	800054e6 <pipewrite+0x84>
      release(&pi->lock);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffb097          	auipc	ra,0xffffb
    800054ac:	7ce080e7          	jalr	1998(ra) # 80000c76 <release>
      return -1;
    800054b0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054b2:	854a                	mv	a0,s2
    800054b4:	60e6                	ld	ra,88(sp)
    800054b6:	6446                	ld	s0,80(sp)
    800054b8:	64a6                	ld	s1,72(sp)
    800054ba:	6906                	ld	s2,64(sp)
    800054bc:	79e2                	ld	s3,56(sp)
    800054be:	7a42                	ld	s4,48(sp)
    800054c0:	7aa2                	ld	s5,40(sp)
    800054c2:	7b02                	ld	s6,32(sp)
    800054c4:	6be2                	ld	s7,24(sp)
    800054c6:	6c42                	ld	s8,16(sp)
    800054c8:	6125                	addi	sp,sp,96
    800054ca:	8082                	ret
      wakeup(&pi->nread);
    800054cc:	8562                	mv	a0,s8
    800054ce:	ffffd097          	auipc	ra,0xffffd
    800054d2:	36c080e7          	jalr	876(ra) # 8000283a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054d6:	85a6                	mv	a1,s1
    800054d8:	855e                	mv	a0,s7
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	1d4080e7          	jalr	468(ra) # 800026ae <sleep>
  while(i < n){
    800054e2:	05495d63          	bge	s2,s4,8000553c <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800054e6:	2204a783          	lw	a5,544(s1)
    800054ea:	dfd5                	beqz	a5,800054a6 <pipewrite+0x44>
    800054ec:	0289a783          	lw	a5,40(s3)
    800054f0:	fbdd                	bnez	a5,800054a6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800054f2:	2184a783          	lw	a5,536(s1)
    800054f6:	21c4a703          	lw	a4,540(s1)
    800054fa:	2007879b          	addiw	a5,a5,512
    800054fe:	fcf707e3          	beq	a4,a5,800054cc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005502:	4685                	li	a3,1
    80005504:	01590633          	add	a2,s2,s5
    80005508:	faf40593          	addi	a1,s0,-81
    8000550c:	0509b503          	ld	a0,80(s3)
    80005510:	ffffc097          	auipc	ra,0xffffc
    80005514:	1e4080e7          	jalr	484(ra) # 800016f4 <copyin>
    80005518:	03650263          	beq	a0,s6,8000553c <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000551c:	21c4a783          	lw	a5,540(s1)
    80005520:	0017871b          	addiw	a4,a5,1
    80005524:	20e4ae23          	sw	a4,540(s1)
    80005528:	1ff7f793          	andi	a5,a5,511
    8000552c:	97a6                	add	a5,a5,s1
    8000552e:	faf44703          	lbu	a4,-81(s0)
    80005532:	00e78c23          	sb	a4,24(a5)
      i++;
    80005536:	2905                	addiw	s2,s2,1
    80005538:	b76d                	j	800054e2 <pipewrite+0x80>
  int i = 0;
    8000553a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000553c:	21848513          	addi	a0,s1,536
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	2fa080e7          	jalr	762(ra) # 8000283a <wakeup>
  release(&pi->lock);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	72c080e7          	jalr	1836(ra) # 80000c76 <release>
  return i;
    80005552:	b785                	j	800054b2 <pipewrite+0x50>

0000000080005554 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005554:	715d                	addi	sp,sp,-80
    80005556:	e486                	sd	ra,72(sp)
    80005558:	e0a2                	sd	s0,64(sp)
    8000555a:	fc26                	sd	s1,56(sp)
    8000555c:	f84a                	sd	s2,48(sp)
    8000555e:	f44e                	sd	s3,40(sp)
    80005560:	f052                	sd	s4,32(sp)
    80005562:	ec56                	sd	s5,24(sp)
    80005564:	e85a                	sd	s6,16(sp)
    80005566:	0880                	addi	s0,sp,80
    80005568:	84aa                	mv	s1,a0
    8000556a:	892e                	mv	s2,a1
    8000556c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	98c080e7          	jalr	-1652(ra) # 80001efa <myproc>
    80005576:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffb097          	auipc	ra,0xffffb
    8000557e:	648080e7          	jalr	1608(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005582:	2184a703          	lw	a4,536(s1)
    80005586:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000558a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000558e:	02f71463          	bne	a4,a5,800055b6 <piperead+0x62>
    80005592:	2244a783          	lw	a5,548(s1)
    80005596:	c385                	beqz	a5,800055b6 <piperead+0x62>
    if(pr->killed){
    80005598:	028a2783          	lw	a5,40(s4)
    8000559c:	ebc1                	bnez	a5,8000562c <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000559e:	85a6                	mv	a1,s1
    800055a0:	854e                	mv	a0,s3
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	10c080e7          	jalr	268(ra) # 800026ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055aa:	2184a703          	lw	a4,536(s1)
    800055ae:	21c4a783          	lw	a5,540(s1)
    800055b2:	fef700e3          	beq	a4,a5,80005592 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055b6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055b8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ba:	05505363          	blez	s5,80005600 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800055be:	2184a783          	lw	a5,536(s1)
    800055c2:	21c4a703          	lw	a4,540(s1)
    800055c6:	02f70d63          	beq	a4,a5,80005600 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055ca:	0017871b          	addiw	a4,a5,1
    800055ce:	20e4ac23          	sw	a4,536(s1)
    800055d2:	1ff7f793          	andi	a5,a5,511
    800055d6:	97a6                	add	a5,a5,s1
    800055d8:	0187c783          	lbu	a5,24(a5)
    800055dc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055e0:	4685                	li	a3,1
    800055e2:	fbf40613          	addi	a2,s0,-65
    800055e6:	85ca                	mv	a1,s2
    800055e8:	050a3503          	ld	a0,80(s4)
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	07c080e7          	jalr	124(ra) # 80001668 <copyout>
    800055f4:	01650663          	beq	a0,s6,80005600 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055f8:	2985                	addiw	s3,s3,1
    800055fa:	0905                	addi	s2,s2,1
    800055fc:	fd3a91e3          	bne	s5,s3,800055be <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005600:	21c48513          	addi	a0,s1,540
    80005604:	ffffd097          	auipc	ra,0xffffd
    80005608:	236080e7          	jalr	566(ra) # 8000283a <wakeup>
  release(&pi->lock);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	668080e7          	jalr	1640(ra) # 80000c76 <release>
  return i;
}
    80005616:	854e                	mv	a0,s3
    80005618:	60a6                	ld	ra,72(sp)
    8000561a:	6406                	ld	s0,64(sp)
    8000561c:	74e2                	ld	s1,56(sp)
    8000561e:	7942                	ld	s2,48(sp)
    80005620:	79a2                	ld	s3,40(sp)
    80005622:	7a02                	ld	s4,32(sp)
    80005624:	6ae2                	ld	s5,24(sp)
    80005626:	6b42                	ld	s6,16(sp)
    80005628:	6161                	addi	sp,sp,80
    8000562a:	8082                	ret
      release(&pi->lock);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffb097          	auipc	ra,0xffffb
    80005632:	648080e7          	jalr	1608(ra) # 80000c76 <release>
      return -1;
    80005636:	59fd                	li	s3,-1
    80005638:	bff9                	j	80005616 <piperead+0xc2>

000000008000563a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000563a:	de010113          	addi	sp,sp,-544
    8000563e:	20113c23          	sd	ra,536(sp)
    80005642:	20813823          	sd	s0,528(sp)
    80005646:	20913423          	sd	s1,520(sp)
    8000564a:	21213023          	sd	s2,512(sp)
    8000564e:	ffce                	sd	s3,504(sp)
    80005650:	fbd2                	sd	s4,496(sp)
    80005652:	f7d6                	sd	s5,488(sp)
    80005654:	f3da                	sd	s6,480(sp)
    80005656:	efde                	sd	s7,472(sp)
    80005658:	ebe2                	sd	s8,464(sp)
    8000565a:	e7e6                	sd	s9,456(sp)
    8000565c:	e3ea                	sd	s10,448(sp)
    8000565e:	ff6e                	sd	s11,440(sp)
    80005660:	1400                	addi	s0,sp,544
    80005662:	dea43c23          	sd	a0,-520(s0)
    80005666:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000566a:	ffffd097          	auipc	ra,0xffffd
    8000566e:	890080e7          	jalr	-1904(ra) # 80001efa <myproc>
    80005672:	84aa                	mv	s1,a0

  #ifndef NONE
  if(p->pid > 2){
    80005674:	5918                	lw	a4,48(a0)
    80005676:	4789                	li	a5,2
    80005678:	04e7db63          	bge	a5,a4,800056ce <exec+0x94>
    struct page_metadata *pg;
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    8000567c:	17050713          	addi	a4,a0,368
    80005680:	37050793          	addi	a5,a0,880
    80005684:	86be                	mv	a3,a5
      pg->state = 0;
    80005686:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    8000568a:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    8000568e:	00073823          	sd	zero,16(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80005692:	02070713          	addi	a4,a4,32
    80005696:	fed718e3          	bne	a4,a3,80005686 <exec+0x4c>
    }
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000569a:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    8000569e:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    800056a2:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    800056a6:	0007b823          	sd	zero,16(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    800056aa:	02078793          	addi	a5,a5,32
    800056ae:	fee798e3          	bne	a5,a4,8000569e <exec+0x64>
    }
    p->num_pages_in_swapfile = 0;
    800056b2:	5604aa23          	sw	zero,1396(s1)
    p->num_pages_in_psyc = 0;
    800056b6:	5604a823          	sw	zero,1392(s1)
    removeSwapFile(p);
    800056ba:	8526                	mv	a0,s1
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	de4080e7          	jalr	-540(ra) # 800044a0 <removeSwapFile>
    createSwapFile(p);
    800056c4:	8526                	mv	a0,s1
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	f82080e7          	jalr	-126(ra) # 80004648 <createSwapFile>
  }
  #endif

  begin_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	258080e7          	jalr	600(ra) # 80004926 <begin_op>

  if((ip = namei(path)) == 0){
    800056d6:	df843503          	ld	a0,-520(s0)
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	d1a080e7          	jalr	-742(ra) # 800043f4 <namei>
    800056e2:	8aaa                	mv	s5,a0
    800056e4:	c935                	beqz	a0,80005758 <exec+0x11e>
    end_op();
    return -1;
  }
  ilock(ip);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	558080e7          	jalr	1368(ra) # 80003c3e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056ee:	04000713          	li	a4,64
    800056f2:	4681                	li	a3,0
    800056f4:	e4840613          	addi	a2,s0,-440
    800056f8:	4581                	li	a1,0
    800056fa:	8556                	mv	a0,s5
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	7f6080e7          	jalr	2038(ra) # 80003ef2 <readi>
    80005704:	04000793          	li	a5,64
    80005708:	00f51a63          	bne	a0,a5,8000571c <exec+0xe2>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000570c:	e4842703          	lw	a4,-440(s0)
    80005710:	464c47b7          	lui	a5,0x464c4
    80005714:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005718:	04f70663          	beq	a4,a5,80005764 <exec+0x12a>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000571c:	8556                	mv	a0,s5
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	782080e7          	jalr	1922(ra) # 80003ea0 <iunlockput>
    end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	280080e7          	jalr	640(ra) # 800049a6 <end_op>
  }
  return -1;
    8000572e:	557d                	li	a0,-1
}
    80005730:	21813083          	ld	ra,536(sp)
    80005734:	21013403          	ld	s0,528(sp)
    80005738:	20813483          	ld	s1,520(sp)
    8000573c:	20013903          	ld	s2,512(sp)
    80005740:	79fe                	ld	s3,504(sp)
    80005742:	7a5e                	ld	s4,496(sp)
    80005744:	7abe                	ld	s5,488(sp)
    80005746:	7b1e                	ld	s6,480(sp)
    80005748:	6bfe                	ld	s7,472(sp)
    8000574a:	6c5e                	ld	s8,464(sp)
    8000574c:	6cbe                	ld	s9,456(sp)
    8000574e:	6d1e                	ld	s10,448(sp)
    80005750:	7dfa                	ld	s11,440(sp)
    80005752:	22010113          	addi	sp,sp,544
    80005756:	8082                	ret
    end_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	24e080e7          	jalr	590(ra) # 800049a6 <end_op>
    return -1;
    80005760:	557d                	li	a0,-1
    80005762:	b7f9                	j	80005730 <exec+0xf6>
  if((pagetable = proc_pagetable(p)) == 0)
    80005764:	8526                	mv	a0,s1
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	858080e7          	jalr	-1960(ra) # 80001fbe <proc_pagetable>
    8000576e:	8b2a                	mv	s6,a0
    80005770:	d555                	beqz	a0,8000571c <exec+0xe2>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005772:	e6842783          	lw	a5,-408(s0)
    80005776:	e8045703          	lhu	a4,-384(s0)
    8000577a:	c735                	beqz	a4,800057e6 <exec+0x1ac>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000577c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000577e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005782:	6a05                	lui	s4,0x1
    80005784:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005788:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000578c:	6d85                	lui	s11,0x1
    8000578e:	7d7d                	lui	s10,0xfffff
    80005790:	ac1d                	j	800059c6 <exec+0x38c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005792:	00003517          	auipc	a0,0x3
    80005796:	fc650513          	addi	a0,a0,-58 # 80008758 <syscalls+0x2f0>
    8000579a:	ffffb097          	auipc	ra,0xffffb
    8000579e:	d90080e7          	jalr	-624(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800057a2:	874a                	mv	a4,s2
    800057a4:	009c86bb          	addw	a3,s9,s1
    800057a8:	4581                	li	a1,0
    800057aa:	8556                	mv	a0,s5
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	746080e7          	jalr	1862(ra) # 80003ef2 <readi>
    800057b4:	2501                	sext.w	a0,a0
    800057b6:	1aa91863          	bne	s2,a0,80005966 <exec+0x32c>
  for(i = 0; i < sz; i += PGSIZE){
    800057ba:	009d84bb          	addw	s1,s11,s1
    800057be:	013d09bb          	addw	s3,s10,s3
    800057c2:	1f74f263          	bgeu	s1,s7,800059a6 <exec+0x36c>
    pa = walkaddr(pagetable, va + i);
    800057c6:	02049593          	slli	a1,s1,0x20
    800057ca:	9181                	srli	a1,a1,0x20
    800057cc:	95e2                	add	a1,a1,s8
    800057ce:	855a                	mv	a0,s6
    800057d0:	ffffc097          	auipc	ra,0xffffc
    800057d4:	87c080e7          	jalr	-1924(ra) # 8000104c <walkaddr>
    800057d8:	862a                	mv	a2,a0
    if(pa == 0)
    800057da:	dd45                	beqz	a0,80005792 <exec+0x158>
      n = PGSIZE;
    800057dc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800057de:	fd49f2e3          	bgeu	s3,s4,800057a2 <exec+0x168>
      n = sz - i;
    800057e2:	894e                	mv	s2,s3
    800057e4:	bf7d                	j	800057a2 <exec+0x168>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800057e6:	4481                	li	s1,0
  iunlockput(ip);
    800057e8:	8556                	mv	a0,s5
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	6b6080e7          	jalr	1718(ra) # 80003ea0 <iunlockput>
  end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	1b4080e7          	jalr	436(ra) # 800049a6 <end_op>
  p = myproc();
    800057fa:	ffffc097          	auipc	ra,0xffffc
    800057fe:	700080e7          	jalr	1792(ra) # 80001efa <myproc>
    80005802:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005804:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005808:	6785                	lui	a5,0x1
    8000580a:	17fd                	addi	a5,a5,-1
    8000580c:	94be                	add	s1,s1,a5
    8000580e:	77fd                	lui	a5,0xfffff
    80005810:	8fe5                	and	a5,a5,s1
    80005812:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005816:	6609                	lui	a2,0x2
    80005818:	963e                	add	a2,a2,a5
    8000581a:	85be                	mv	a1,a5
    8000581c:	855a                	mv	a0,s6
    8000581e:	ffffc097          	auipc	ra,0xffffc
    80005822:	37c080e7          	jalr	892(ra) # 80001b9a <uvmalloc>
    80005826:	8c2a                	mv	s8,a0
  ip = 0;
    80005828:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000582a:	12050e63          	beqz	a0,80005966 <exec+0x32c>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000582e:	75f9                	lui	a1,0xffffe
    80005830:	95aa                	add	a1,a1,a0
    80005832:	855a                	mv	a0,s6
    80005834:	ffffc097          	auipc	ra,0xffffc
    80005838:	e02080e7          	jalr	-510(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    8000583c:	7afd                	lui	s5,0xfffff
    8000583e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005840:	de843783          	ld	a5,-536(s0)
    80005844:	6388                	ld	a0,0(a5)
    80005846:	c925                	beqz	a0,800058b6 <exec+0x27c>
    80005848:	e8840993          	addi	s3,s0,-376
    8000584c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005850:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005852:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005854:	ffffb097          	auipc	ra,0xffffb
    80005858:	5ee080e7          	jalr	1518(ra) # 80000e42 <strlen>
    8000585c:	0015079b          	addiw	a5,a0,1
    80005860:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005864:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005868:	13596363          	bltu	s2,s5,8000598e <exec+0x354>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000586c:	de843d83          	ld	s11,-536(s0)
    80005870:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005874:	8552                	mv	a0,s4
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	5cc080e7          	jalr	1484(ra) # 80000e42 <strlen>
    8000587e:	0015069b          	addiw	a3,a0,1
    80005882:	8652                	mv	a2,s4
    80005884:	85ca                	mv	a1,s2
    80005886:	855a                	mv	a0,s6
    80005888:	ffffc097          	auipc	ra,0xffffc
    8000588c:	de0080e7          	jalr	-544(ra) # 80001668 <copyout>
    80005890:	10054363          	bltz	a0,80005996 <exec+0x35c>
    ustack[argc] = sp;
    80005894:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005898:	0485                	addi	s1,s1,1
    8000589a:	008d8793          	addi	a5,s11,8
    8000589e:	def43423          	sd	a5,-536(s0)
    800058a2:	008db503          	ld	a0,8(s11)
    800058a6:	c911                	beqz	a0,800058ba <exec+0x280>
    if(argc >= MAXARG)
    800058a8:	09a1                	addi	s3,s3,8
    800058aa:	fb9995e3          	bne	s3,s9,80005854 <exec+0x21a>
  sz = sz1;
    800058ae:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800058b2:	4a81                	li	s5,0
    800058b4:	a84d                	j	80005966 <exec+0x32c>
  sp = sz;
    800058b6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058b8:	4481                	li	s1,0
  ustack[argc] = 0;
    800058ba:	00349793          	slli	a5,s1,0x3
    800058be:	f9040713          	addi	a4,s0,-112
    800058c2:	97ba                	add	a5,a5,a4
    800058c4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffc8ef8>
  sp -= (argc+1) * sizeof(uint64);
    800058c8:	00148693          	addi	a3,s1,1
    800058cc:	068e                	slli	a3,a3,0x3
    800058ce:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800058d2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800058d6:	01597663          	bgeu	s2,s5,800058e2 <exec+0x2a8>
  sz = sz1;
    800058da:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800058de:	4a81                	li	s5,0
    800058e0:	a059                	j	80005966 <exec+0x32c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800058e2:	e8840613          	addi	a2,s0,-376
    800058e6:	85ca                	mv	a1,s2
    800058e8:	855a                	mv	a0,s6
    800058ea:	ffffc097          	auipc	ra,0xffffc
    800058ee:	d7e080e7          	jalr	-642(ra) # 80001668 <copyout>
    800058f2:	0a054663          	bltz	a0,8000599e <exec+0x364>
  p->trapframe->a1 = sp;
    800058f6:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800058fa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800058fe:	df843783          	ld	a5,-520(s0)
    80005902:	0007c703          	lbu	a4,0(a5)
    80005906:	cf11                	beqz	a4,80005922 <exec+0x2e8>
    80005908:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000590a:	02f00693          	li	a3,47
    8000590e:	a039                	j	8000591c <exec+0x2e2>
      last = s+1;
    80005910:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005914:	0785                	addi	a5,a5,1
    80005916:	fff7c703          	lbu	a4,-1(a5)
    8000591a:	c701                	beqz	a4,80005922 <exec+0x2e8>
    if(*s == '/')
    8000591c:	fed71ce3          	bne	a4,a3,80005914 <exec+0x2da>
    80005920:	bfc5                	j	80005910 <exec+0x2d6>
  safestrcpy(p->name, last, sizeof(p->name));
    80005922:	4641                	li	a2,16
    80005924:	df843583          	ld	a1,-520(s0)
    80005928:	158b8513          	addi	a0,s7,344
    8000592c:	ffffb097          	auipc	ra,0xffffb
    80005930:	4e4080e7          	jalr	1252(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005934:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005938:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000593c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005940:	058bb783          	ld	a5,88(s7)
    80005944:	e6043703          	ld	a4,-416(s0)
    80005948:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000594a:	058bb783          	ld	a5,88(s7)
    8000594e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005952:	85ea                	mv	a1,s10
    80005954:	ffffc097          	auipc	ra,0xffffc
    80005958:	706080e7          	jalr	1798(ra) # 8000205a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000595c:	0004851b          	sext.w	a0,s1
    80005960:	bbc1                	j	80005730 <exec+0xf6>
    80005962:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    80005966:	df043583          	ld	a1,-528(s0)
    8000596a:	855a                	mv	a0,s6
    8000596c:	ffffc097          	auipc	ra,0xffffc
    80005970:	6ee080e7          	jalr	1774(ra) # 8000205a <proc_freepagetable>
  if(ip){
    80005974:	da0a94e3          	bnez	s5,8000571c <exec+0xe2>
  return -1;
    80005978:	557d                	li	a0,-1
    8000597a:	bb5d                	j	80005730 <exec+0xf6>
    8000597c:	de943823          	sd	s1,-528(s0)
    80005980:	b7dd                	j	80005966 <exec+0x32c>
    80005982:	de943823          	sd	s1,-528(s0)
    80005986:	b7c5                	j	80005966 <exec+0x32c>
    80005988:	de943823          	sd	s1,-528(s0)
    8000598c:	bfe9                	j	80005966 <exec+0x32c>
  sz = sz1;
    8000598e:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005992:	4a81                	li	s5,0
    80005994:	bfc9                	j	80005966 <exec+0x32c>
  sz = sz1;
    80005996:	df843823          	sd	s8,-528(s0)
  ip = 0;
    8000599a:	4a81                	li	s5,0
    8000599c:	b7e9                	j	80005966 <exec+0x32c>
  sz = sz1;
    8000599e:	df843823          	sd	s8,-528(s0)
  ip = 0;
    800059a2:	4a81                	li	s5,0
    800059a4:	b7c9                	j	80005966 <exec+0x32c>
    sz = sz1;
    800059a6:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059aa:	e0843783          	ld	a5,-504(s0)
    800059ae:	0017869b          	addiw	a3,a5,1
    800059b2:	e0d43423          	sd	a3,-504(s0)
    800059b6:	e0043783          	ld	a5,-512(s0)
    800059ba:	0387879b          	addiw	a5,a5,56
    800059be:	e8045703          	lhu	a4,-384(s0)
    800059c2:	e2e6d3e3          	bge	a3,a4,800057e8 <exec+0x1ae>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800059c6:	2781                	sext.w	a5,a5
    800059c8:	e0f43023          	sd	a5,-512(s0)
    800059cc:	03800713          	li	a4,56
    800059d0:	86be                	mv	a3,a5
    800059d2:	e1040613          	addi	a2,s0,-496
    800059d6:	4581                	li	a1,0
    800059d8:	8556                	mv	a0,s5
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	518080e7          	jalr	1304(ra) # 80003ef2 <readi>
    800059e2:	03800793          	li	a5,56
    800059e6:	f6f51ee3          	bne	a0,a5,80005962 <exec+0x328>
    if(ph.type != ELF_PROG_LOAD)
    800059ea:	e1042783          	lw	a5,-496(s0)
    800059ee:	4705                	li	a4,1
    800059f0:	fae79de3          	bne	a5,a4,800059aa <exec+0x370>
    if(ph.memsz < ph.filesz)
    800059f4:	e3843603          	ld	a2,-456(s0)
    800059f8:	e3043783          	ld	a5,-464(s0)
    800059fc:	f8f660e3          	bltu	a2,a5,8000597c <exec+0x342>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a00:	e2043783          	ld	a5,-480(s0)
    80005a04:	963e                	add	a2,a2,a5
    80005a06:	f6f66ee3          	bltu	a2,a5,80005982 <exec+0x348>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a0a:	85a6                	mv	a1,s1
    80005a0c:	855a                	mv	a0,s6
    80005a0e:	ffffc097          	auipc	ra,0xffffc
    80005a12:	18c080e7          	jalr	396(ra) # 80001b9a <uvmalloc>
    80005a16:	dea43823          	sd	a0,-528(s0)
    80005a1a:	d53d                	beqz	a0,80005988 <exec+0x34e>
    if(ph.vaddr % PGSIZE != 0)
    80005a1c:	e2043c03          	ld	s8,-480(s0)
    80005a20:	de043783          	ld	a5,-544(s0)
    80005a24:	00fc77b3          	and	a5,s8,a5
    80005a28:	ff9d                	bnez	a5,80005966 <exec+0x32c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a2a:	e1842c83          	lw	s9,-488(s0)
    80005a2e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005a32:	f60b8ae3          	beqz	s7,800059a6 <exec+0x36c>
    80005a36:	89de                	mv	s3,s7
    80005a38:	4481                	li	s1,0
    80005a3a:	b371                	j	800057c6 <exec+0x18c>

0000000080005a3c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a3c:	7179                	addi	sp,sp,-48
    80005a3e:	f406                	sd	ra,40(sp)
    80005a40:	f022                	sd	s0,32(sp)
    80005a42:	ec26                	sd	s1,24(sp)
    80005a44:	e84a                	sd	s2,16(sp)
    80005a46:	1800                	addi	s0,sp,48
    80005a48:	892e                	mv	s2,a1
    80005a4a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005a4c:	fdc40593          	addi	a1,s0,-36
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	67c080e7          	jalr	1660(ra) # 800030cc <argint>
    80005a58:	04054063          	bltz	a0,80005a98 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a5c:	fdc42703          	lw	a4,-36(s0)
    80005a60:	47bd                	li	a5,15
    80005a62:	02e7ed63          	bltu	a5,a4,80005a9c <argfd+0x60>
    80005a66:	ffffc097          	auipc	ra,0xffffc
    80005a6a:	494080e7          	jalr	1172(ra) # 80001efa <myproc>
    80005a6e:	fdc42703          	lw	a4,-36(s0)
    80005a72:	01a70793          	addi	a5,a4,26
    80005a76:	078e                	slli	a5,a5,0x3
    80005a78:	953e                	add	a0,a0,a5
    80005a7a:	611c                	ld	a5,0(a0)
    80005a7c:	c395                	beqz	a5,80005aa0 <argfd+0x64>
    return -1;
  if(pfd)
    80005a7e:	00090463          	beqz	s2,80005a86 <argfd+0x4a>
    *pfd = fd;
    80005a82:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a86:	4501                	li	a0,0
  if(pf)
    80005a88:	c091                	beqz	s1,80005a8c <argfd+0x50>
    *pf = f;
    80005a8a:	e09c                	sd	a5,0(s1)
}
    80005a8c:	70a2                	ld	ra,40(sp)
    80005a8e:	7402                	ld	s0,32(sp)
    80005a90:	64e2                	ld	s1,24(sp)
    80005a92:	6942                	ld	s2,16(sp)
    80005a94:	6145                	addi	sp,sp,48
    80005a96:	8082                	ret
    return -1;
    80005a98:	557d                	li	a0,-1
    80005a9a:	bfcd                	j	80005a8c <argfd+0x50>
    return -1;
    80005a9c:	557d                	li	a0,-1
    80005a9e:	b7fd                	j	80005a8c <argfd+0x50>
    80005aa0:	557d                	li	a0,-1
    80005aa2:	b7ed                	j	80005a8c <argfd+0x50>

0000000080005aa4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005aa4:	1101                	addi	sp,sp,-32
    80005aa6:	ec06                	sd	ra,24(sp)
    80005aa8:	e822                	sd	s0,16(sp)
    80005aaa:	e426                	sd	s1,8(sp)
    80005aac:	1000                	addi	s0,sp,32
    80005aae:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ab0:	ffffc097          	auipc	ra,0xffffc
    80005ab4:	44a080e7          	jalr	1098(ra) # 80001efa <myproc>
    80005ab8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005aba:	0d050793          	addi	a5,a0,208
    80005abe:	4501                	li	a0,0
    80005ac0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ac2:	6398                	ld	a4,0(a5)
    80005ac4:	cb19                	beqz	a4,80005ada <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ac6:	2505                	addiw	a0,a0,1
    80005ac8:	07a1                	addi	a5,a5,8
    80005aca:	fed51ce3          	bne	a0,a3,80005ac2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ace:	557d                	li	a0,-1
}
    80005ad0:	60e2                	ld	ra,24(sp)
    80005ad2:	6442                	ld	s0,16(sp)
    80005ad4:	64a2                	ld	s1,8(sp)
    80005ad6:	6105                	addi	sp,sp,32
    80005ad8:	8082                	ret
      p->ofile[fd] = f;
    80005ada:	01a50793          	addi	a5,a0,26
    80005ade:	078e                	slli	a5,a5,0x3
    80005ae0:	963e                	add	a2,a2,a5
    80005ae2:	e204                	sd	s1,0(a2)
      return fd;
    80005ae4:	b7f5                	j	80005ad0 <fdalloc+0x2c>

0000000080005ae6 <sys_dup>:

uint64
sys_dup(void)
{
    80005ae6:	7179                	addi	sp,sp,-48
    80005ae8:	f406                	sd	ra,40(sp)
    80005aea:	f022                	sd	s0,32(sp)
    80005aec:	ec26                	sd	s1,24(sp)
    80005aee:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005af0:	fd840613          	addi	a2,s0,-40
    80005af4:	4581                	li	a1,0
    80005af6:	4501                	li	a0,0
    80005af8:	00000097          	auipc	ra,0x0
    80005afc:	f44080e7          	jalr	-188(ra) # 80005a3c <argfd>
    return -1;
    80005b00:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b02:	02054363          	bltz	a0,80005b28 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b06:	fd843503          	ld	a0,-40(s0)
    80005b0a:	00000097          	auipc	ra,0x0
    80005b0e:	f9a080e7          	jalr	-102(ra) # 80005aa4 <fdalloc>
    80005b12:	84aa                	mv	s1,a0
    return -1;
    80005b14:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b16:	00054963          	bltz	a0,80005b28 <sys_dup+0x42>
  filedup(f);
    80005b1a:	fd843503          	ld	a0,-40(s0)
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	282080e7          	jalr	642(ra) # 80004da0 <filedup>
  return fd;
    80005b26:	87a6                	mv	a5,s1
}
    80005b28:	853e                	mv	a0,a5
    80005b2a:	70a2                	ld	ra,40(sp)
    80005b2c:	7402                	ld	s0,32(sp)
    80005b2e:	64e2                	ld	s1,24(sp)
    80005b30:	6145                	addi	sp,sp,48
    80005b32:	8082                	ret

0000000080005b34 <sys_read>:

uint64
sys_read(void)
{
    80005b34:	7179                	addi	sp,sp,-48
    80005b36:	f406                	sd	ra,40(sp)
    80005b38:	f022                	sd	s0,32(sp)
    80005b3a:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b3c:	fe840613          	addi	a2,s0,-24
    80005b40:	4581                	li	a1,0
    80005b42:	4501                	li	a0,0
    80005b44:	00000097          	auipc	ra,0x0
    80005b48:	ef8080e7          	jalr	-264(ra) # 80005a3c <argfd>
    return -1;
    80005b4c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b4e:	04054163          	bltz	a0,80005b90 <sys_read+0x5c>
    80005b52:	fe440593          	addi	a1,s0,-28
    80005b56:	4509                	li	a0,2
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	574080e7          	jalr	1396(ra) # 800030cc <argint>
    return -1;
    80005b60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b62:	02054763          	bltz	a0,80005b90 <sys_read+0x5c>
    80005b66:	fd840593          	addi	a1,s0,-40
    80005b6a:	4505                	li	a0,1
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	582080e7          	jalr	1410(ra) # 800030ee <argaddr>
    return -1;
    80005b74:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b76:	00054d63          	bltz	a0,80005b90 <sys_read+0x5c>
  return fileread(f, p, n);
    80005b7a:	fe442603          	lw	a2,-28(s0)
    80005b7e:	fd843583          	ld	a1,-40(s0)
    80005b82:	fe843503          	ld	a0,-24(s0)
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	3a6080e7          	jalr	934(ra) # 80004f2c <fileread>
    80005b8e:	87aa                	mv	a5,a0
}
    80005b90:	853e                	mv	a0,a5
    80005b92:	70a2                	ld	ra,40(sp)
    80005b94:	7402                	ld	s0,32(sp)
    80005b96:	6145                	addi	sp,sp,48
    80005b98:	8082                	ret

0000000080005b9a <sys_write>:

uint64
sys_write(void)
{
    80005b9a:	7179                	addi	sp,sp,-48
    80005b9c:	f406                	sd	ra,40(sp)
    80005b9e:	f022                	sd	s0,32(sp)
    80005ba0:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ba2:	fe840613          	addi	a2,s0,-24
    80005ba6:	4581                	li	a1,0
    80005ba8:	4501                	li	a0,0
    80005baa:	00000097          	auipc	ra,0x0
    80005bae:	e92080e7          	jalr	-366(ra) # 80005a3c <argfd>
    return -1;
    80005bb2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bb4:	04054163          	bltz	a0,80005bf6 <sys_write+0x5c>
    80005bb8:	fe440593          	addi	a1,s0,-28
    80005bbc:	4509                	li	a0,2
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	50e080e7          	jalr	1294(ra) # 800030cc <argint>
    return -1;
    80005bc6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc8:	02054763          	bltz	a0,80005bf6 <sys_write+0x5c>
    80005bcc:	fd840593          	addi	a1,s0,-40
    80005bd0:	4505                	li	a0,1
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	51c080e7          	jalr	1308(ra) # 800030ee <argaddr>
    return -1;
    80005bda:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bdc:	00054d63          	bltz	a0,80005bf6 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005be0:	fe442603          	lw	a2,-28(s0)
    80005be4:	fd843583          	ld	a1,-40(s0)
    80005be8:	fe843503          	ld	a0,-24(s0)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	402080e7          	jalr	1026(ra) # 80004fee <filewrite>
    80005bf4:	87aa                	mv	a5,a0
}
    80005bf6:	853e                	mv	a0,a5
    80005bf8:	70a2                	ld	ra,40(sp)
    80005bfa:	7402                	ld	s0,32(sp)
    80005bfc:	6145                	addi	sp,sp,48
    80005bfe:	8082                	ret

0000000080005c00 <sys_close>:

uint64
sys_close(void)
{
    80005c00:	1101                	addi	sp,sp,-32
    80005c02:	ec06                	sd	ra,24(sp)
    80005c04:	e822                	sd	s0,16(sp)
    80005c06:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005c08:	fe040613          	addi	a2,s0,-32
    80005c0c:	fec40593          	addi	a1,s0,-20
    80005c10:	4501                	li	a0,0
    80005c12:	00000097          	auipc	ra,0x0
    80005c16:	e2a080e7          	jalr	-470(ra) # 80005a3c <argfd>
    return -1;
    80005c1a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c1c:	02054463          	bltz	a0,80005c44 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	2da080e7          	jalr	730(ra) # 80001efa <myproc>
    80005c28:	fec42783          	lw	a5,-20(s0)
    80005c2c:	07e9                	addi	a5,a5,26
    80005c2e:	078e                	slli	a5,a5,0x3
    80005c30:	97aa                	add	a5,a5,a0
    80005c32:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c36:	fe043503          	ld	a0,-32(s0)
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	1b8080e7          	jalr	440(ra) # 80004df2 <fileclose>
  return 0;
    80005c42:	4781                	li	a5,0
}
    80005c44:	853e                	mv	a0,a5
    80005c46:	60e2                	ld	ra,24(sp)
    80005c48:	6442                	ld	s0,16(sp)
    80005c4a:	6105                	addi	sp,sp,32
    80005c4c:	8082                	ret

0000000080005c4e <sys_fstat>:

uint64
sys_fstat(void)
{
    80005c4e:	1101                	addi	sp,sp,-32
    80005c50:	ec06                	sd	ra,24(sp)
    80005c52:	e822                	sd	s0,16(sp)
    80005c54:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c56:	fe840613          	addi	a2,s0,-24
    80005c5a:	4581                	li	a1,0
    80005c5c:	4501                	li	a0,0
    80005c5e:	00000097          	auipc	ra,0x0
    80005c62:	dde080e7          	jalr	-546(ra) # 80005a3c <argfd>
    return -1;
    80005c66:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c68:	02054563          	bltz	a0,80005c92 <sys_fstat+0x44>
    80005c6c:	fe040593          	addi	a1,s0,-32
    80005c70:	4505                	li	a0,1
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	47c080e7          	jalr	1148(ra) # 800030ee <argaddr>
    return -1;
    80005c7a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c7c:	00054b63          	bltz	a0,80005c92 <sys_fstat+0x44>
  return filestat(f, st);
    80005c80:	fe043583          	ld	a1,-32(s0)
    80005c84:	fe843503          	ld	a0,-24(s0)
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	232080e7          	jalr	562(ra) # 80004eba <filestat>
    80005c90:	87aa                	mv	a5,a0
}
    80005c92:	853e                	mv	a0,a5
    80005c94:	60e2                	ld	ra,24(sp)
    80005c96:	6442                	ld	s0,16(sp)
    80005c98:	6105                	addi	sp,sp,32
    80005c9a:	8082                	ret

0000000080005c9c <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005c9c:	7169                	addi	sp,sp,-304
    80005c9e:	f606                	sd	ra,296(sp)
    80005ca0:	f222                	sd	s0,288(sp)
    80005ca2:	ee26                	sd	s1,280(sp)
    80005ca4:	ea4a                	sd	s2,272(sp)
    80005ca6:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ca8:	08000613          	li	a2,128
    80005cac:	ed040593          	addi	a1,s0,-304
    80005cb0:	4501                	li	a0,0
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	45e080e7          	jalr	1118(ra) # 80003110 <argstr>
    return -1;
    80005cba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cbc:	10054e63          	bltz	a0,80005dd8 <sys_link+0x13c>
    80005cc0:	08000613          	li	a2,128
    80005cc4:	f5040593          	addi	a1,s0,-176
    80005cc8:	4505                	li	a0,1
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	446080e7          	jalr	1094(ra) # 80003110 <argstr>
    return -1;
    80005cd2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cd4:	10054263          	bltz	a0,80005dd8 <sys_link+0x13c>

  begin_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	c4e080e7          	jalr	-946(ra) # 80004926 <begin_op>
  if((ip = namei(old)) == 0){
    80005ce0:	ed040513          	addi	a0,s0,-304
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	710080e7          	jalr	1808(ra) # 800043f4 <namei>
    80005cec:	84aa                	mv	s1,a0
    80005cee:	c551                	beqz	a0,80005d7a <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	f4e080e7          	jalr	-178(ra) # 80003c3e <ilock>
  if(ip->type == T_DIR){
    80005cf8:	04449703          	lh	a4,68(s1)
    80005cfc:	4785                	li	a5,1
    80005cfe:	08f70463          	beq	a4,a5,80005d86 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005d02:	04a4d783          	lhu	a5,74(s1)
    80005d06:	2785                	addiw	a5,a5,1
    80005d08:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d0c:	8526                	mv	a0,s1
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	e66080e7          	jalr	-410(ra) # 80003b74 <iupdate>
  iunlock(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	fe8080e7          	jalr	-24(ra) # 80003d00 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005d20:	fd040593          	addi	a1,s0,-48
    80005d24:	f5040513          	addi	a0,s0,-176
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	6ea080e7          	jalr	1770(ra) # 80004412 <nameiparent>
    80005d30:	892a                	mv	s2,a0
    80005d32:	c935                	beqz	a0,80005da6 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	f0a080e7          	jalr	-246(ra) # 80003c3e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d3c:	00092703          	lw	a4,0(s2)
    80005d40:	409c                	lw	a5,0(s1)
    80005d42:	04f71d63          	bne	a4,a5,80005d9c <sys_link+0x100>
    80005d46:	40d0                	lw	a2,4(s1)
    80005d48:	fd040593          	addi	a1,s0,-48
    80005d4c:	854a                	mv	a0,s2
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	5e4080e7          	jalr	1508(ra) # 80004332 <dirlink>
    80005d56:	04054363          	bltz	a0,80005d9c <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005d5a:	854a                	mv	a0,s2
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	144080e7          	jalr	324(ra) # 80003ea0 <iunlockput>
  iput(ip);
    80005d64:	8526                	mv	a0,s1
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	092080e7          	jalr	146(ra) # 80003df8 <iput>

  end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	c38080e7          	jalr	-968(ra) # 800049a6 <end_op>

  return 0;
    80005d76:	4781                	li	a5,0
    80005d78:	a085                	j	80005dd8 <sys_link+0x13c>
    end_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	c2c080e7          	jalr	-980(ra) # 800049a6 <end_op>
    return -1;
    80005d82:	57fd                	li	a5,-1
    80005d84:	a891                	j	80005dd8 <sys_link+0x13c>
    iunlockput(ip);
    80005d86:	8526                	mv	a0,s1
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	118080e7          	jalr	280(ra) # 80003ea0 <iunlockput>
    end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	c16080e7          	jalr	-1002(ra) # 800049a6 <end_op>
    return -1;
    80005d98:	57fd                	li	a5,-1
    80005d9a:	a83d                	j	80005dd8 <sys_link+0x13c>
    iunlockput(dp);
    80005d9c:	854a                	mv	a0,s2
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	102080e7          	jalr	258(ra) # 80003ea0 <iunlockput>

bad:
  ilock(ip);
    80005da6:	8526                	mv	a0,s1
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	e96080e7          	jalr	-362(ra) # 80003c3e <ilock>
  ip->nlink--;
    80005db0:	04a4d783          	lhu	a5,74(s1)
    80005db4:	37fd                	addiw	a5,a5,-1
    80005db6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dba:	8526                	mv	a0,s1
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	db8080e7          	jalr	-584(ra) # 80003b74 <iupdate>
  iunlockput(ip);
    80005dc4:	8526                	mv	a0,s1
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	0da080e7          	jalr	218(ra) # 80003ea0 <iunlockput>
  end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	bd8080e7          	jalr	-1064(ra) # 800049a6 <end_op>
  return -1;
    80005dd6:	57fd                	li	a5,-1
}
    80005dd8:	853e                	mv	a0,a5
    80005dda:	70b2                	ld	ra,296(sp)
    80005ddc:	7412                	ld	s0,288(sp)
    80005dde:	64f2                	ld	s1,280(sp)
    80005de0:	6952                	ld	s2,272(sp)
    80005de2:	6155                	addi	sp,sp,304
    80005de4:	8082                	ret

0000000080005de6 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005de6:	4578                	lw	a4,76(a0)
    80005de8:	02000793          	li	a5,32
    80005dec:	04e7fa63          	bgeu	a5,a4,80005e40 <isdirempty+0x5a>
{
    80005df0:	7179                	addi	sp,sp,-48
    80005df2:	f406                	sd	ra,40(sp)
    80005df4:	f022                	sd	s0,32(sp)
    80005df6:	ec26                	sd	s1,24(sp)
    80005df8:	e84a                	sd	s2,16(sp)
    80005dfa:	1800                	addi	s0,sp,48
    80005dfc:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dfe:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e02:	4741                	li	a4,16
    80005e04:	86a6                	mv	a3,s1
    80005e06:	fd040613          	addi	a2,s0,-48
    80005e0a:	4581                	li	a1,0
    80005e0c:	854a                	mv	a0,s2
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	0e4080e7          	jalr	228(ra) # 80003ef2 <readi>
    80005e16:	47c1                	li	a5,16
    80005e18:	00f51c63          	bne	a0,a5,80005e30 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005e1c:	fd045783          	lhu	a5,-48(s0)
    80005e20:	e395                	bnez	a5,80005e44 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e22:	24c1                	addiw	s1,s1,16
    80005e24:	04c92783          	lw	a5,76(s2)
    80005e28:	fcf4ede3          	bltu	s1,a5,80005e02 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005e2c:	4505                	li	a0,1
    80005e2e:	a821                	j	80005e46 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005e30:	00003517          	auipc	a0,0x3
    80005e34:	94850513          	addi	a0,a0,-1720 # 80008778 <syscalls+0x310>
    80005e38:	ffffa097          	auipc	ra,0xffffa
    80005e3c:	6f2080e7          	jalr	1778(ra) # 8000052a <panic>
  return 1;
    80005e40:	4505                	li	a0,1
}
    80005e42:	8082                	ret
      return 0;
    80005e44:	4501                	li	a0,0
}
    80005e46:	70a2                	ld	ra,40(sp)
    80005e48:	7402                	ld	s0,32(sp)
    80005e4a:	64e2                	ld	s1,24(sp)
    80005e4c:	6942                	ld	s2,16(sp)
    80005e4e:	6145                	addi	sp,sp,48
    80005e50:	8082                	ret

0000000080005e52 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005e52:	7155                	addi	sp,sp,-208
    80005e54:	e586                	sd	ra,200(sp)
    80005e56:	e1a2                	sd	s0,192(sp)
    80005e58:	fd26                	sd	s1,184(sp)
    80005e5a:	f94a                	sd	s2,176(sp)
    80005e5c:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005e5e:	08000613          	li	a2,128
    80005e62:	f4040593          	addi	a1,s0,-192
    80005e66:	4501                	li	a0,0
    80005e68:	ffffd097          	auipc	ra,0xffffd
    80005e6c:	2a8080e7          	jalr	680(ra) # 80003110 <argstr>
    80005e70:	16054363          	bltz	a0,80005fd6 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	ab2080e7          	jalr	-1358(ra) # 80004926 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e7c:	fc040593          	addi	a1,s0,-64
    80005e80:	f4040513          	addi	a0,s0,-192
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	58e080e7          	jalr	1422(ra) # 80004412 <nameiparent>
    80005e8c:	84aa                	mv	s1,a0
    80005e8e:	c961                	beqz	a0,80005f5e <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	dae080e7          	jalr	-594(ra) # 80003c3e <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e98:	00002597          	auipc	a1,0x2
    80005e9c:	7c058593          	addi	a1,a1,1984 # 80008658 <syscalls+0x1f0>
    80005ea0:	fc040513          	addi	a0,s0,-64
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	264080e7          	jalr	612(ra) # 80004108 <namecmp>
    80005eac:	c175                	beqz	a0,80005f90 <sys_unlink+0x13e>
    80005eae:	00002597          	auipc	a1,0x2
    80005eb2:	7b258593          	addi	a1,a1,1970 # 80008660 <syscalls+0x1f8>
    80005eb6:	fc040513          	addi	a0,s0,-64
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	24e080e7          	jalr	590(ra) # 80004108 <namecmp>
    80005ec2:	c579                	beqz	a0,80005f90 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ec4:	f3c40613          	addi	a2,s0,-196
    80005ec8:	fc040593          	addi	a1,s0,-64
    80005ecc:	8526                	mv	a0,s1
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	254080e7          	jalr	596(ra) # 80004122 <dirlookup>
    80005ed6:	892a                	mv	s2,a0
    80005ed8:	cd45                	beqz	a0,80005f90 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	d64080e7          	jalr	-668(ra) # 80003c3e <ilock>

  if(ip->nlink < 1)
    80005ee2:	04a91783          	lh	a5,74(s2)
    80005ee6:	08f05263          	blez	a5,80005f6a <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005eea:	04491703          	lh	a4,68(s2)
    80005eee:	4785                	li	a5,1
    80005ef0:	08f70563          	beq	a4,a5,80005f7a <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005ef4:	4641                	li	a2,16
    80005ef6:	4581                	li	a1,0
    80005ef8:	fd040513          	addi	a0,s0,-48
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	dc2080e7          	jalr	-574(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f04:	4741                	li	a4,16
    80005f06:	f3c42683          	lw	a3,-196(s0)
    80005f0a:	fd040613          	addi	a2,s0,-48
    80005f0e:	4581                	li	a1,0
    80005f10:	8526                	mv	a0,s1
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	0d8080e7          	jalr	216(ra) # 80003fea <writei>
    80005f1a:	47c1                	li	a5,16
    80005f1c:	08f51a63          	bne	a0,a5,80005fb0 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005f20:	04491703          	lh	a4,68(s2)
    80005f24:	4785                	li	a5,1
    80005f26:	08f70d63          	beq	a4,a5,80005fc0 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005f2a:	8526                	mv	a0,s1
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	f74080e7          	jalr	-140(ra) # 80003ea0 <iunlockput>

  ip->nlink--;
    80005f34:	04a95783          	lhu	a5,74(s2)
    80005f38:	37fd                	addiw	a5,a5,-1
    80005f3a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f3e:	854a                	mv	a0,s2
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	c34080e7          	jalr	-972(ra) # 80003b74 <iupdate>
  iunlockput(ip);
    80005f48:	854a                	mv	a0,s2
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	f56080e7          	jalr	-170(ra) # 80003ea0 <iunlockput>

  end_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	a54080e7          	jalr	-1452(ra) # 800049a6 <end_op>

  return 0;
    80005f5a:	4501                	li	a0,0
    80005f5c:	a0a1                	j	80005fa4 <sys_unlink+0x152>
    end_op();
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	a48080e7          	jalr	-1464(ra) # 800049a6 <end_op>
    return -1;
    80005f66:	557d                	li	a0,-1
    80005f68:	a835                	j	80005fa4 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005f6a:	00002517          	auipc	a0,0x2
    80005f6e:	6fe50513          	addi	a0,a0,1790 # 80008668 <syscalls+0x200>
    80005f72:	ffffa097          	auipc	ra,0xffffa
    80005f76:	5b8080e7          	jalr	1464(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f7a:	854a                	mv	a0,s2
    80005f7c:	00000097          	auipc	ra,0x0
    80005f80:	e6a080e7          	jalr	-406(ra) # 80005de6 <isdirempty>
    80005f84:	f925                	bnez	a0,80005ef4 <sys_unlink+0xa2>
    iunlockput(ip);
    80005f86:	854a                	mv	a0,s2
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	f18080e7          	jalr	-232(ra) # 80003ea0 <iunlockput>

bad:
  iunlockput(dp);
    80005f90:	8526                	mv	a0,s1
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	f0e080e7          	jalr	-242(ra) # 80003ea0 <iunlockput>
  end_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	a0c080e7          	jalr	-1524(ra) # 800049a6 <end_op>
  return -1;
    80005fa2:	557d                	li	a0,-1
}
    80005fa4:	60ae                	ld	ra,200(sp)
    80005fa6:	640e                	ld	s0,192(sp)
    80005fa8:	74ea                	ld	s1,184(sp)
    80005faa:	794a                	ld	s2,176(sp)
    80005fac:	6169                	addi	sp,sp,208
    80005fae:	8082                	ret
    panic("unlink: writei");
    80005fb0:	00002517          	auipc	a0,0x2
    80005fb4:	6d050513          	addi	a0,a0,1744 # 80008680 <syscalls+0x218>
    80005fb8:	ffffa097          	auipc	ra,0xffffa
    80005fbc:	572080e7          	jalr	1394(ra) # 8000052a <panic>
    dp->nlink--;
    80005fc0:	04a4d783          	lhu	a5,74(s1)
    80005fc4:	37fd                	addiw	a5,a5,-1
    80005fc6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005fca:	8526                	mv	a0,s1
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	ba8080e7          	jalr	-1112(ra) # 80003b74 <iupdate>
    80005fd4:	bf99                	j	80005f2a <sys_unlink+0xd8>
    return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	b7f1                	j	80005fa4 <sys_unlink+0x152>

0000000080005fda <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005fda:	715d                	addi	sp,sp,-80
    80005fdc:	e486                	sd	ra,72(sp)
    80005fde:	e0a2                	sd	s0,64(sp)
    80005fe0:	fc26                	sd	s1,56(sp)
    80005fe2:	f84a                	sd	s2,48(sp)
    80005fe4:	f44e                	sd	s3,40(sp)
    80005fe6:	f052                	sd	s4,32(sp)
    80005fe8:	ec56                	sd	s5,24(sp)
    80005fea:	0880                	addi	s0,sp,80
    80005fec:	89ae                	mv	s3,a1
    80005fee:	8ab2                	mv	s5,a2
    80005ff0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005ff2:	fb040593          	addi	a1,s0,-80
    80005ff6:	ffffe097          	auipc	ra,0xffffe
    80005ffa:	41c080e7          	jalr	1052(ra) # 80004412 <nameiparent>
    80005ffe:	892a                	mv	s2,a0
    80006000:	12050e63          	beqz	a0,8000613c <create+0x162>
    return 0;

  ilock(dp);
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	c3a080e7          	jalr	-966(ra) # 80003c3e <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000600c:	4601                	li	a2,0
    8000600e:	fb040593          	addi	a1,s0,-80
    80006012:	854a                	mv	a0,s2
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	10e080e7          	jalr	270(ra) # 80004122 <dirlookup>
    8000601c:	84aa                	mv	s1,a0
    8000601e:	c921                	beqz	a0,8000606e <create+0x94>
    iunlockput(dp);
    80006020:	854a                	mv	a0,s2
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	e7e080e7          	jalr	-386(ra) # 80003ea0 <iunlockput>
    ilock(ip);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	c12080e7          	jalr	-1006(ra) # 80003c3e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006034:	2981                	sext.w	s3,s3
    80006036:	4789                	li	a5,2
    80006038:	02f99463          	bne	s3,a5,80006060 <create+0x86>
    8000603c:	0444d783          	lhu	a5,68(s1)
    80006040:	37f9                	addiw	a5,a5,-2
    80006042:	17c2                	slli	a5,a5,0x30
    80006044:	93c1                	srli	a5,a5,0x30
    80006046:	4705                	li	a4,1
    80006048:	00f76c63          	bltu	a4,a5,80006060 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000604c:	8526                	mv	a0,s1
    8000604e:	60a6                	ld	ra,72(sp)
    80006050:	6406                	ld	s0,64(sp)
    80006052:	74e2                	ld	s1,56(sp)
    80006054:	7942                	ld	s2,48(sp)
    80006056:	79a2                	ld	s3,40(sp)
    80006058:	7a02                	ld	s4,32(sp)
    8000605a:	6ae2                	ld	s5,24(sp)
    8000605c:	6161                	addi	sp,sp,80
    8000605e:	8082                	ret
    iunlockput(ip);
    80006060:	8526                	mv	a0,s1
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	e3e080e7          	jalr	-450(ra) # 80003ea0 <iunlockput>
    return 0;
    8000606a:	4481                	li	s1,0
    8000606c:	b7c5                	j	8000604c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000606e:	85ce                	mv	a1,s3
    80006070:	00092503          	lw	a0,0(s2)
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	a32080e7          	jalr	-1486(ra) # 80003aa6 <ialloc>
    8000607c:	84aa                	mv	s1,a0
    8000607e:	c521                	beqz	a0,800060c6 <create+0xec>
  ilock(ip);
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	bbe080e7          	jalr	-1090(ra) # 80003c3e <ilock>
  ip->major = major;
    80006088:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000608c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006090:	4a05                	li	s4,1
    80006092:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	adc080e7          	jalr	-1316(ra) # 80003b74 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800060a0:	2981                	sext.w	s3,s3
    800060a2:	03498a63          	beq	s3,s4,800060d6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800060a6:	40d0                	lw	a2,4(s1)
    800060a8:	fb040593          	addi	a1,s0,-80
    800060ac:	854a                	mv	a0,s2
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	284080e7          	jalr	644(ra) # 80004332 <dirlink>
    800060b6:	06054b63          	bltz	a0,8000612c <create+0x152>
  iunlockput(dp);
    800060ba:	854a                	mv	a0,s2
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	de4080e7          	jalr	-540(ra) # 80003ea0 <iunlockput>
  return ip;
    800060c4:	b761                	j	8000604c <create+0x72>
    panic("create: ialloc");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	6ca50513          	addi	a0,a0,1738 # 80008790 <syscalls+0x328>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	45c080e7          	jalr	1116(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800060d6:	04a95783          	lhu	a5,74(s2)
    800060da:	2785                	addiw	a5,a5,1
    800060dc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800060e0:	854a                	mv	a0,s2
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	a92080e7          	jalr	-1390(ra) # 80003b74 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800060ea:	40d0                	lw	a2,4(s1)
    800060ec:	00002597          	auipc	a1,0x2
    800060f0:	56c58593          	addi	a1,a1,1388 # 80008658 <syscalls+0x1f0>
    800060f4:	8526                	mv	a0,s1
    800060f6:	ffffe097          	auipc	ra,0xffffe
    800060fa:	23c080e7          	jalr	572(ra) # 80004332 <dirlink>
    800060fe:	00054f63          	bltz	a0,8000611c <create+0x142>
    80006102:	00492603          	lw	a2,4(s2)
    80006106:	00002597          	auipc	a1,0x2
    8000610a:	55a58593          	addi	a1,a1,1370 # 80008660 <syscalls+0x1f8>
    8000610e:	8526                	mv	a0,s1
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	222080e7          	jalr	546(ra) # 80004332 <dirlink>
    80006118:	f80557e3          	bgez	a0,800060a6 <create+0xcc>
      panic("create dots");
    8000611c:	00002517          	auipc	a0,0x2
    80006120:	68450513          	addi	a0,a0,1668 # 800087a0 <syscalls+0x338>
    80006124:	ffffa097          	auipc	ra,0xffffa
    80006128:	406080e7          	jalr	1030(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000612c:	00002517          	auipc	a0,0x2
    80006130:	68450513          	addi	a0,a0,1668 # 800087b0 <syscalls+0x348>
    80006134:	ffffa097          	auipc	ra,0xffffa
    80006138:	3f6080e7          	jalr	1014(ra) # 8000052a <panic>
    return 0;
    8000613c:	84aa                	mv	s1,a0
    8000613e:	b739                	j	8000604c <create+0x72>

0000000080006140 <sys_open>:

uint64
sys_open(void)
{
    80006140:	7131                	addi	sp,sp,-192
    80006142:	fd06                	sd	ra,184(sp)
    80006144:	f922                	sd	s0,176(sp)
    80006146:	f526                	sd	s1,168(sp)
    80006148:	f14a                	sd	s2,160(sp)
    8000614a:	ed4e                	sd	s3,152(sp)
    8000614c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000614e:	08000613          	li	a2,128
    80006152:	f5040593          	addi	a1,s0,-176
    80006156:	4501                	li	a0,0
    80006158:	ffffd097          	auipc	ra,0xffffd
    8000615c:	fb8080e7          	jalr	-72(ra) # 80003110 <argstr>
    return -1;
    80006160:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006162:	0c054163          	bltz	a0,80006224 <sys_open+0xe4>
    80006166:	f4c40593          	addi	a1,s0,-180
    8000616a:	4505                	li	a0,1
    8000616c:	ffffd097          	auipc	ra,0xffffd
    80006170:	f60080e7          	jalr	-160(ra) # 800030cc <argint>
    80006174:	0a054863          	bltz	a0,80006224 <sys_open+0xe4>

  begin_op();
    80006178:	ffffe097          	auipc	ra,0xffffe
    8000617c:	7ae080e7          	jalr	1966(ra) # 80004926 <begin_op>

  if(omode & O_CREATE){
    80006180:	f4c42783          	lw	a5,-180(s0)
    80006184:	2007f793          	andi	a5,a5,512
    80006188:	cbdd                	beqz	a5,8000623e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000618a:	4681                	li	a3,0
    8000618c:	4601                	li	a2,0
    8000618e:	4589                	li	a1,2
    80006190:	f5040513          	addi	a0,s0,-176
    80006194:	00000097          	auipc	ra,0x0
    80006198:	e46080e7          	jalr	-442(ra) # 80005fda <create>
    8000619c:	892a                	mv	s2,a0
    if(ip == 0){
    8000619e:	c959                	beqz	a0,80006234 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800061a0:	04491703          	lh	a4,68(s2)
    800061a4:	478d                	li	a5,3
    800061a6:	00f71763          	bne	a4,a5,800061b4 <sys_open+0x74>
    800061aa:	04695703          	lhu	a4,70(s2)
    800061ae:	47a5                	li	a5,9
    800061b0:	0ce7ec63          	bltu	a5,a4,80006288 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	b82080e7          	jalr	-1150(ra) # 80004d36 <filealloc>
    800061bc:	89aa                	mv	s3,a0
    800061be:	10050263          	beqz	a0,800062c2 <sys_open+0x182>
    800061c2:	00000097          	auipc	ra,0x0
    800061c6:	8e2080e7          	jalr	-1822(ra) # 80005aa4 <fdalloc>
    800061ca:	84aa                	mv	s1,a0
    800061cc:	0e054663          	bltz	a0,800062b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800061d0:	04491703          	lh	a4,68(s2)
    800061d4:	478d                	li	a5,3
    800061d6:	0cf70463          	beq	a4,a5,8000629e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800061da:	4789                	li	a5,2
    800061dc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800061e0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800061e4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800061e8:	f4c42783          	lw	a5,-180(s0)
    800061ec:	0017c713          	xori	a4,a5,1
    800061f0:	8b05                	andi	a4,a4,1
    800061f2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800061f6:	0037f713          	andi	a4,a5,3
    800061fa:	00e03733          	snez	a4,a4
    800061fe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006202:	4007f793          	andi	a5,a5,1024
    80006206:	c791                	beqz	a5,80006212 <sys_open+0xd2>
    80006208:	04491703          	lh	a4,68(s2)
    8000620c:	4789                	li	a5,2
    8000620e:	08f70f63          	beq	a4,a5,800062ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006212:	854a                	mv	a0,s2
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	aec080e7          	jalr	-1300(ra) # 80003d00 <iunlock>
  end_op();
    8000621c:	ffffe097          	auipc	ra,0xffffe
    80006220:	78a080e7          	jalr	1930(ra) # 800049a6 <end_op>

  return fd;
}
    80006224:	8526                	mv	a0,s1
    80006226:	70ea                	ld	ra,184(sp)
    80006228:	744a                	ld	s0,176(sp)
    8000622a:	74aa                	ld	s1,168(sp)
    8000622c:	790a                	ld	s2,160(sp)
    8000622e:	69ea                	ld	s3,152(sp)
    80006230:	6129                	addi	sp,sp,192
    80006232:	8082                	ret
      end_op();
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	772080e7          	jalr	1906(ra) # 800049a6 <end_op>
      return -1;
    8000623c:	b7e5                	j	80006224 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000623e:	f5040513          	addi	a0,s0,-176
    80006242:	ffffe097          	auipc	ra,0xffffe
    80006246:	1b2080e7          	jalr	434(ra) # 800043f4 <namei>
    8000624a:	892a                	mv	s2,a0
    8000624c:	c905                	beqz	a0,8000627c <sys_open+0x13c>
    ilock(ip);
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	9f0080e7          	jalr	-1552(ra) # 80003c3e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006256:	04491703          	lh	a4,68(s2)
    8000625a:	4785                	li	a5,1
    8000625c:	f4f712e3          	bne	a4,a5,800061a0 <sys_open+0x60>
    80006260:	f4c42783          	lw	a5,-180(s0)
    80006264:	dba1                	beqz	a5,800061b4 <sys_open+0x74>
      iunlockput(ip);
    80006266:	854a                	mv	a0,s2
    80006268:	ffffe097          	auipc	ra,0xffffe
    8000626c:	c38080e7          	jalr	-968(ra) # 80003ea0 <iunlockput>
      end_op();
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	736080e7          	jalr	1846(ra) # 800049a6 <end_op>
      return -1;
    80006278:	54fd                	li	s1,-1
    8000627a:	b76d                	j	80006224 <sys_open+0xe4>
      end_op();
    8000627c:	ffffe097          	auipc	ra,0xffffe
    80006280:	72a080e7          	jalr	1834(ra) # 800049a6 <end_op>
      return -1;
    80006284:	54fd                	li	s1,-1
    80006286:	bf79                	j	80006224 <sys_open+0xe4>
    iunlockput(ip);
    80006288:	854a                	mv	a0,s2
    8000628a:	ffffe097          	auipc	ra,0xffffe
    8000628e:	c16080e7          	jalr	-1002(ra) # 80003ea0 <iunlockput>
    end_op();
    80006292:	ffffe097          	auipc	ra,0xffffe
    80006296:	714080e7          	jalr	1812(ra) # 800049a6 <end_op>
    return -1;
    8000629a:	54fd                	li	s1,-1
    8000629c:	b761                	j	80006224 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000629e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800062a2:	04691783          	lh	a5,70(s2)
    800062a6:	02f99223          	sh	a5,36(s3)
    800062aa:	bf2d                	j	800061e4 <sys_open+0xa4>
    itrunc(ip);
    800062ac:	854a                	mv	a0,s2
    800062ae:	ffffe097          	auipc	ra,0xffffe
    800062b2:	a9e080e7          	jalr	-1378(ra) # 80003d4c <itrunc>
    800062b6:	bfb1                	j	80006212 <sys_open+0xd2>
      fileclose(f);
    800062b8:	854e                	mv	a0,s3
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	b38080e7          	jalr	-1224(ra) # 80004df2 <fileclose>
    iunlockput(ip);
    800062c2:	854a                	mv	a0,s2
    800062c4:	ffffe097          	auipc	ra,0xffffe
    800062c8:	bdc080e7          	jalr	-1060(ra) # 80003ea0 <iunlockput>
    end_op();
    800062cc:	ffffe097          	auipc	ra,0xffffe
    800062d0:	6da080e7          	jalr	1754(ra) # 800049a6 <end_op>
    return -1;
    800062d4:	54fd                	li	s1,-1
    800062d6:	b7b9                	j	80006224 <sys_open+0xe4>

00000000800062d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800062d8:	7175                	addi	sp,sp,-144
    800062da:	e506                	sd	ra,136(sp)
    800062dc:	e122                	sd	s0,128(sp)
    800062de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800062e0:	ffffe097          	auipc	ra,0xffffe
    800062e4:	646080e7          	jalr	1606(ra) # 80004926 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800062e8:	08000613          	li	a2,128
    800062ec:	f7040593          	addi	a1,s0,-144
    800062f0:	4501                	li	a0,0
    800062f2:	ffffd097          	auipc	ra,0xffffd
    800062f6:	e1e080e7          	jalr	-482(ra) # 80003110 <argstr>
    800062fa:	02054963          	bltz	a0,8000632c <sys_mkdir+0x54>
    800062fe:	4681                	li	a3,0
    80006300:	4601                	li	a2,0
    80006302:	4585                	li	a1,1
    80006304:	f7040513          	addi	a0,s0,-144
    80006308:	00000097          	auipc	ra,0x0
    8000630c:	cd2080e7          	jalr	-814(ra) # 80005fda <create>
    80006310:	cd11                	beqz	a0,8000632c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006312:	ffffe097          	auipc	ra,0xffffe
    80006316:	b8e080e7          	jalr	-1138(ra) # 80003ea0 <iunlockput>
  end_op();
    8000631a:	ffffe097          	auipc	ra,0xffffe
    8000631e:	68c080e7          	jalr	1676(ra) # 800049a6 <end_op>
  return 0;
    80006322:	4501                	li	a0,0
}
    80006324:	60aa                	ld	ra,136(sp)
    80006326:	640a                	ld	s0,128(sp)
    80006328:	6149                	addi	sp,sp,144
    8000632a:	8082                	ret
    end_op();
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	67a080e7          	jalr	1658(ra) # 800049a6 <end_op>
    return -1;
    80006334:	557d                	li	a0,-1
    80006336:	b7fd                	j	80006324 <sys_mkdir+0x4c>

0000000080006338 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006338:	7135                	addi	sp,sp,-160
    8000633a:	ed06                	sd	ra,152(sp)
    8000633c:	e922                	sd	s0,144(sp)
    8000633e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006340:	ffffe097          	auipc	ra,0xffffe
    80006344:	5e6080e7          	jalr	1510(ra) # 80004926 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006348:	08000613          	li	a2,128
    8000634c:	f7040593          	addi	a1,s0,-144
    80006350:	4501                	li	a0,0
    80006352:	ffffd097          	auipc	ra,0xffffd
    80006356:	dbe080e7          	jalr	-578(ra) # 80003110 <argstr>
    8000635a:	04054a63          	bltz	a0,800063ae <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000635e:	f6c40593          	addi	a1,s0,-148
    80006362:	4505                	li	a0,1
    80006364:	ffffd097          	auipc	ra,0xffffd
    80006368:	d68080e7          	jalr	-664(ra) # 800030cc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000636c:	04054163          	bltz	a0,800063ae <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006370:	f6840593          	addi	a1,s0,-152
    80006374:	4509                	li	a0,2
    80006376:	ffffd097          	auipc	ra,0xffffd
    8000637a:	d56080e7          	jalr	-682(ra) # 800030cc <argint>
     argint(1, &major) < 0 ||
    8000637e:	02054863          	bltz	a0,800063ae <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006382:	f6841683          	lh	a3,-152(s0)
    80006386:	f6c41603          	lh	a2,-148(s0)
    8000638a:	458d                	li	a1,3
    8000638c:	f7040513          	addi	a0,s0,-144
    80006390:	00000097          	auipc	ra,0x0
    80006394:	c4a080e7          	jalr	-950(ra) # 80005fda <create>
     argint(2, &minor) < 0 ||
    80006398:	c919                	beqz	a0,800063ae <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000639a:	ffffe097          	auipc	ra,0xffffe
    8000639e:	b06080e7          	jalr	-1274(ra) # 80003ea0 <iunlockput>
  end_op();
    800063a2:	ffffe097          	auipc	ra,0xffffe
    800063a6:	604080e7          	jalr	1540(ra) # 800049a6 <end_op>
  return 0;
    800063aa:	4501                	li	a0,0
    800063ac:	a031                	j	800063b8 <sys_mknod+0x80>
    end_op();
    800063ae:	ffffe097          	auipc	ra,0xffffe
    800063b2:	5f8080e7          	jalr	1528(ra) # 800049a6 <end_op>
    return -1;
    800063b6:	557d                	li	a0,-1
}
    800063b8:	60ea                	ld	ra,152(sp)
    800063ba:	644a                	ld	s0,144(sp)
    800063bc:	610d                	addi	sp,sp,160
    800063be:	8082                	ret

00000000800063c0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800063c0:	7135                	addi	sp,sp,-160
    800063c2:	ed06                	sd	ra,152(sp)
    800063c4:	e922                	sd	s0,144(sp)
    800063c6:	e526                	sd	s1,136(sp)
    800063c8:	e14a                	sd	s2,128(sp)
    800063ca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800063cc:	ffffc097          	auipc	ra,0xffffc
    800063d0:	b2e080e7          	jalr	-1234(ra) # 80001efa <myproc>
    800063d4:	892a                	mv	s2,a0
  
  begin_op();
    800063d6:	ffffe097          	auipc	ra,0xffffe
    800063da:	550080e7          	jalr	1360(ra) # 80004926 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800063de:	08000613          	li	a2,128
    800063e2:	f6040593          	addi	a1,s0,-160
    800063e6:	4501                	li	a0,0
    800063e8:	ffffd097          	auipc	ra,0xffffd
    800063ec:	d28080e7          	jalr	-728(ra) # 80003110 <argstr>
    800063f0:	04054b63          	bltz	a0,80006446 <sys_chdir+0x86>
    800063f4:	f6040513          	addi	a0,s0,-160
    800063f8:	ffffe097          	auipc	ra,0xffffe
    800063fc:	ffc080e7          	jalr	-4(ra) # 800043f4 <namei>
    80006400:	84aa                	mv	s1,a0
    80006402:	c131                	beqz	a0,80006446 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006404:	ffffe097          	auipc	ra,0xffffe
    80006408:	83a080e7          	jalr	-1990(ra) # 80003c3e <ilock>
  if(ip->type != T_DIR){
    8000640c:	04449703          	lh	a4,68(s1)
    80006410:	4785                	li	a5,1
    80006412:	04f71063          	bne	a4,a5,80006452 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006416:	8526                	mv	a0,s1
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	8e8080e7          	jalr	-1816(ra) # 80003d00 <iunlock>
  iput(p->cwd);
    80006420:	15093503          	ld	a0,336(s2)
    80006424:	ffffe097          	auipc	ra,0xffffe
    80006428:	9d4080e7          	jalr	-1580(ra) # 80003df8 <iput>
  end_op();
    8000642c:	ffffe097          	auipc	ra,0xffffe
    80006430:	57a080e7          	jalr	1402(ra) # 800049a6 <end_op>
  p->cwd = ip;
    80006434:	14993823          	sd	s1,336(s2)
  return 0;
    80006438:	4501                	li	a0,0
}
    8000643a:	60ea                	ld	ra,152(sp)
    8000643c:	644a                	ld	s0,144(sp)
    8000643e:	64aa                	ld	s1,136(sp)
    80006440:	690a                	ld	s2,128(sp)
    80006442:	610d                	addi	sp,sp,160
    80006444:	8082                	ret
    end_op();
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	560080e7          	jalr	1376(ra) # 800049a6 <end_op>
    return -1;
    8000644e:	557d                	li	a0,-1
    80006450:	b7ed                	j	8000643a <sys_chdir+0x7a>
    iunlockput(ip);
    80006452:	8526                	mv	a0,s1
    80006454:	ffffe097          	auipc	ra,0xffffe
    80006458:	a4c080e7          	jalr	-1460(ra) # 80003ea0 <iunlockput>
    end_op();
    8000645c:	ffffe097          	auipc	ra,0xffffe
    80006460:	54a080e7          	jalr	1354(ra) # 800049a6 <end_op>
    return -1;
    80006464:	557d                	li	a0,-1
    80006466:	bfd1                	j	8000643a <sys_chdir+0x7a>

0000000080006468 <sys_exec>:

uint64
sys_exec(void)
{
    80006468:	7145                	addi	sp,sp,-464
    8000646a:	e786                	sd	ra,456(sp)
    8000646c:	e3a2                	sd	s0,448(sp)
    8000646e:	ff26                	sd	s1,440(sp)
    80006470:	fb4a                	sd	s2,432(sp)
    80006472:	f74e                	sd	s3,424(sp)
    80006474:	f352                	sd	s4,416(sp)
    80006476:	ef56                	sd	s5,408(sp)
    80006478:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000647a:	08000613          	li	a2,128
    8000647e:	f4040593          	addi	a1,s0,-192
    80006482:	4501                	li	a0,0
    80006484:	ffffd097          	auipc	ra,0xffffd
    80006488:	c8c080e7          	jalr	-884(ra) # 80003110 <argstr>
    return -1;
    8000648c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000648e:	0c054a63          	bltz	a0,80006562 <sys_exec+0xfa>
    80006492:	e3840593          	addi	a1,s0,-456
    80006496:	4505                	li	a0,1
    80006498:	ffffd097          	auipc	ra,0xffffd
    8000649c:	c56080e7          	jalr	-938(ra) # 800030ee <argaddr>
    800064a0:	0c054163          	bltz	a0,80006562 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800064a4:	10000613          	li	a2,256
    800064a8:	4581                	li	a1,0
    800064aa:	e4040513          	addi	a0,s0,-448
    800064ae:	ffffb097          	auipc	ra,0xffffb
    800064b2:	810080e7          	jalr	-2032(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800064b6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800064ba:	89a6                	mv	s3,s1
    800064bc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800064be:	02000a13          	li	s4,32
    800064c2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800064c6:	00391793          	slli	a5,s2,0x3
    800064ca:	e3040593          	addi	a1,s0,-464
    800064ce:	e3843503          	ld	a0,-456(s0)
    800064d2:	953e                	add	a0,a0,a5
    800064d4:	ffffd097          	auipc	ra,0xffffd
    800064d8:	b5e080e7          	jalr	-1186(ra) # 80003032 <fetchaddr>
    800064dc:	02054a63          	bltz	a0,80006510 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800064e0:	e3043783          	ld	a5,-464(s0)
    800064e4:	c3b9                	beqz	a5,8000652a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800064e6:	ffffa097          	auipc	ra,0xffffa
    800064ea:	5ec080e7          	jalr	1516(ra) # 80000ad2 <kalloc>
    800064ee:	85aa                	mv	a1,a0
    800064f0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800064f4:	cd11                	beqz	a0,80006510 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800064f6:	6605                	lui	a2,0x1
    800064f8:	e3043503          	ld	a0,-464(s0)
    800064fc:	ffffd097          	auipc	ra,0xffffd
    80006500:	b88080e7          	jalr	-1144(ra) # 80003084 <fetchstr>
    80006504:	00054663          	bltz	a0,80006510 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006508:	0905                	addi	s2,s2,1
    8000650a:	09a1                	addi	s3,s3,8
    8000650c:	fb491be3          	bne	s2,s4,800064c2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006510:	10048913          	addi	s2,s1,256
    80006514:	6088                	ld	a0,0(s1)
    80006516:	c529                	beqz	a0,80006560 <sys_exec+0xf8>
    kfree(argv[i]);
    80006518:	ffffa097          	auipc	ra,0xffffa
    8000651c:	4be080e7          	jalr	1214(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006520:	04a1                	addi	s1,s1,8
    80006522:	ff2499e3          	bne	s1,s2,80006514 <sys_exec+0xac>
  return -1;
    80006526:	597d                	li	s2,-1
    80006528:	a82d                	j	80006562 <sys_exec+0xfa>
      argv[i] = 0;
    8000652a:	0a8e                	slli	s5,s5,0x3
    8000652c:	fc040793          	addi	a5,s0,-64
    80006530:	9abe                	add	s5,s5,a5
    80006532:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffc8e80>
  int ret = exec(path, argv);
    80006536:	e4040593          	addi	a1,s0,-448
    8000653a:	f4040513          	addi	a0,s0,-192
    8000653e:	fffff097          	auipc	ra,0xfffff
    80006542:	0fc080e7          	jalr	252(ra) # 8000563a <exec>
    80006546:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006548:	10048993          	addi	s3,s1,256
    8000654c:	6088                	ld	a0,0(s1)
    8000654e:	c911                	beqz	a0,80006562 <sys_exec+0xfa>
    kfree(argv[i]);
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	486080e7          	jalr	1158(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006558:	04a1                	addi	s1,s1,8
    8000655a:	ff3499e3          	bne	s1,s3,8000654c <sys_exec+0xe4>
    8000655e:	a011                	j	80006562 <sys_exec+0xfa>
  return -1;
    80006560:	597d                	li	s2,-1
}
    80006562:	854a                	mv	a0,s2
    80006564:	60be                	ld	ra,456(sp)
    80006566:	641e                	ld	s0,448(sp)
    80006568:	74fa                	ld	s1,440(sp)
    8000656a:	795a                	ld	s2,432(sp)
    8000656c:	79ba                	ld	s3,424(sp)
    8000656e:	7a1a                	ld	s4,416(sp)
    80006570:	6afa                	ld	s5,408(sp)
    80006572:	6179                	addi	sp,sp,464
    80006574:	8082                	ret

0000000080006576 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006576:	7139                	addi	sp,sp,-64
    80006578:	fc06                	sd	ra,56(sp)
    8000657a:	f822                	sd	s0,48(sp)
    8000657c:	f426                	sd	s1,40(sp)
    8000657e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006580:	ffffc097          	auipc	ra,0xffffc
    80006584:	97a080e7          	jalr	-1670(ra) # 80001efa <myproc>
    80006588:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000658a:	fd840593          	addi	a1,s0,-40
    8000658e:	4501                	li	a0,0
    80006590:	ffffd097          	auipc	ra,0xffffd
    80006594:	b5e080e7          	jalr	-1186(ra) # 800030ee <argaddr>
    return -1;
    80006598:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000659a:	0e054063          	bltz	a0,8000667a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000659e:	fc840593          	addi	a1,s0,-56
    800065a2:	fd040513          	addi	a0,s0,-48
    800065a6:	fffff097          	auipc	ra,0xfffff
    800065aa:	d72080e7          	jalr	-654(ra) # 80005318 <pipealloc>
    return -1;
    800065ae:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800065b0:	0c054563          	bltz	a0,8000667a <sys_pipe+0x104>
  fd0 = -1;
    800065b4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800065b8:	fd043503          	ld	a0,-48(s0)
    800065bc:	fffff097          	auipc	ra,0xfffff
    800065c0:	4e8080e7          	jalr	1256(ra) # 80005aa4 <fdalloc>
    800065c4:	fca42223          	sw	a0,-60(s0)
    800065c8:	08054c63          	bltz	a0,80006660 <sys_pipe+0xea>
    800065cc:	fc843503          	ld	a0,-56(s0)
    800065d0:	fffff097          	auipc	ra,0xfffff
    800065d4:	4d4080e7          	jalr	1236(ra) # 80005aa4 <fdalloc>
    800065d8:	fca42023          	sw	a0,-64(s0)
    800065dc:	06054863          	bltz	a0,8000664c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065e0:	4691                	li	a3,4
    800065e2:	fc440613          	addi	a2,s0,-60
    800065e6:	fd843583          	ld	a1,-40(s0)
    800065ea:	68a8                	ld	a0,80(s1)
    800065ec:	ffffb097          	auipc	ra,0xffffb
    800065f0:	07c080e7          	jalr	124(ra) # 80001668 <copyout>
    800065f4:	02054063          	bltz	a0,80006614 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800065f8:	4691                	li	a3,4
    800065fa:	fc040613          	addi	a2,s0,-64
    800065fe:	fd843583          	ld	a1,-40(s0)
    80006602:	0591                	addi	a1,a1,4
    80006604:	68a8                	ld	a0,80(s1)
    80006606:	ffffb097          	auipc	ra,0xffffb
    8000660a:	062080e7          	jalr	98(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000660e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006610:	06055563          	bgez	a0,8000667a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006614:	fc442783          	lw	a5,-60(s0)
    80006618:	07e9                	addi	a5,a5,26
    8000661a:	078e                	slli	a5,a5,0x3
    8000661c:	97a6                	add	a5,a5,s1
    8000661e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006622:	fc042503          	lw	a0,-64(s0)
    80006626:	0569                	addi	a0,a0,26
    80006628:	050e                	slli	a0,a0,0x3
    8000662a:	9526                	add	a0,a0,s1
    8000662c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006630:	fd043503          	ld	a0,-48(s0)
    80006634:	ffffe097          	auipc	ra,0xffffe
    80006638:	7be080e7          	jalr	1982(ra) # 80004df2 <fileclose>
    fileclose(wf);
    8000663c:	fc843503          	ld	a0,-56(s0)
    80006640:	ffffe097          	auipc	ra,0xffffe
    80006644:	7b2080e7          	jalr	1970(ra) # 80004df2 <fileclose>
    return -1;
    80006648:	57fd                	li	a5,-1
    8000664a:	a805                	j	8000667a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000664c:	fc442783          	lw	a5,-60(s0)
    80006650:	0007c863          	bltz	a5,80006660 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006654:	01a78513          	addi	a0,a5,26
    80006658:	050e                	slli	a0,a0,0x3
    8000665a:	9526                	add	a0,a0,s1
    8000665c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006660:	fd043503          	ld	a0,-48(s0)
    80006664:	ffffe097          	auipc	ra,0xffffe
    80006668:	78e080e7          	jalr	1934(ra) # 80004df2 <fileclose>
    fileclose(wf);
    8000666c:	fc843503          	ld	a0,-56(s0)
    80006670:	ffffe097          	auipc	ra,0xffffe
    80006674:	782080e7          	jalr	1922(ra) # 80004df2 <fileclose>
    return -1;
    80006678:	57fd                	li	a5,-1
}
    8000667a:	853e                	mv	a0,a5
    8000667c:	70e2                	ld	ra,56(sp)
    8000667e:	7442                	ld	s0,48(sp)
    80006680:	74a2                	ld	s1,40(sp)
    80006682:	6121                	addi	sp,sp,64
    80006684:	8082                	ret
	...

0000000080006690 <kernelvec>:
    80006690:	7111                	addi	sp,sp,-256
    80006692:	e006                	sd	ra,0(sp)
    80006694:	e40a                	sd	sp,8(sp)
    80006696:	e80e                	sd	gp,16(sp)
    80006698:	ec12                	sd	tp,24(sp)
    8000669a:	f016                	sd	t0,32(sp)
    8000669c:	f41a                	sd	t1,40(sp)
    8000669e:	f81e                	sd	t2,48(sp)
    800066a0:	fc22                	sd	s0,56(sp)
    800066a2:	e0a6                	sd	s1,64(sp)
    800066a4:	e4aa                	sd	a0,72(sp)
    800066a6:	e8ae                	sd	a1,80(sp)
    800066a8:	ecb2                	sd	a2,88(sp)
    800066aa:	f0b6                	sd	a3,96(sp)
    800066ac:	f4ba                	sd	a4,104(sp)
    800066ae:	f8be                	sd	a5,112(sp)
    800066b0:	fcc2                	sd	a6,120(sp)
    800066b2:	e146                	sd	a7,128(sp)
    800066b4:	e54a                	sd	s2,136(sp)
    800066b6:	e94e                	sd	s3,144(sp)
    800066b8:	ed52                	sd	s4,152(sp)
    800066ba:	f156                	sd	s5,160(sp)
    800066bc:	f55a                	sd	s6,168(sp)
    800066be:	f95e                	sd	s7,176(sp)
    800066c0:	fd62                	sd	s8,184(sp)
    800066c2:	e1e6                	sd	s9,192(sp)
    800066c4:	e5ea                	sd	s10,200(sp)
    800066c6:	e9ee                	sd	s11,208(sp)
    800066c8:	edf2                	sd	t3,216(sp)
    800066ca:	f1f6                	sd	t4,224(sp)
    800066cc:	f5fa                	sd	t5,232(sp)
    800066ce:	f9fe                	sd	t6,240(sp)
    800066d0:	82ffc0ef          	jal	ra,80002efe <kerneltrap>
    800066d4:	6082                	ld	ra,0(sp)
    800066d6:	6122                	ld	sp,8(sp)
    800066d8:	61c2                	ld	gp,16(sp)
    800066da:	7282                	ld	t0,32(sp)
    800066dc:	7322                	ld	t1,40(sp)
    800066de:	73c2                	ld	t2,48(sp)
    800066e0:	7462                	ld	s0,56(sp)
    800066e2:	6486                	ld	s1,64(sp)
    800066e4:	6526                	ld	a0,72(sp)
    800066e6:	65c6                	ld	a1,80(sp)
    800066e8:	6666                	ld	a2,88(sp)
    800066ea:	7686                	ld	a3,96(sp)
    800066ec:	7726                	ld	a4,104(sp)
    800066ee:	77c6                	ld	a5,112(sp)
    800066f0:	7866                	ld	a6,120(sp)
    800066f2:	688a                	ld	a7,128(sp)
    800066f4:	692a                	ld	s2,136(sp)
    800066f6:	69ca                	ld	s3,144(sp)
    800066f8:	6a6a                	ld	s4,152(sp)
    800066fa:	7a8a                	ld	s5,160(sp)
    800066fc:	7b2a                	ld	s6,168(sp)
    800066fe:	7bca                	ld	s7,176(sp)
    80006700:	7c6a                	ld	s8,184(sp)
    80006702:	6c8e                	ld	s9,192(sp)
    80006704:	6d2e                	ld	s10,200(sp)
    80006706:	6dce                	ld	s11,208(sp)
    80006708:	6e6e                	ld	t3,216(sp)
    8000670a:	7e8e                	ld	t4,224(sp)
    8000670c:	7f2e                	ld	t5,232(sp)
    8000670e:	7fce                	ld	t6,240(sp)
    80006710:	6111                	addi	sp,sp,256
    80006712:	10200073          	sret
    80006716:	00000013          	nop
    8000671a:	00000013          	nop
    8000671e:	0001                	nop

0000000080006720 <timervec>:
    80006720:	34051573          	csrrw	a0,mscratch,a0
    80006724:	e10c                	sd	a1,0(a0)
    80006726:	e510                	sd	a2,8(a0)
    80006728:	e914                	sd	a3,16(a0)
    8000672a:	6d0c                	ld	a1,24(a0)
    8000672c:	7110                	ld	a2,32(a0)
    8000672e:	6194                	ld	a3,0(a1)
    80006730:	96b2                	add	a3,a3,a2
    80006732:	e194                	sd	a3,0(a1)
    80006734:	4589                	li	a1,2
    80006736:	14459073          	csrw	sip,a1
    8000673a:	6914                	ld	a3,16(a0)
    8000673c:	6510                	ld	a2,8(a0)
    8000673e:	610c                	ld	a1,0(a0)
    80006740:	34051573          	csrrw	a0,mscratch,a0
    80006744:	30200073          	mret
	...

000000008000674a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000674a:	1141                	addi	sp,sp,-16
    8000674c:	e422                	sd	s0,8(sp)
    8000674e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006750:	0c0007b7          	lui	a5,0xc000
    80006754:	4705                	li	a4,1
    80006756:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006758:	c3d8                	sw	a4,4(a5)
}
    8000675a:	6422                	ld	s0,8(sp)
    8000675c:	0141                	addi	sp,sp,16
    8000675e:	8082                	ret

0000000080006760 <plicinithart>:

void
plicinithart(void)
{
    80006760:	1141                	addi	sp,sp,-16
    80006762:	e406                	sd	ra,8(sp)
    80006764:	e022                	sd	s0,0(sp)
    80006766:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006768:	ffffb097          	auipc	ra,0xffffb
    8000676c:	766080e7          	jalr	1894(ra) # 80001ece <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006770:	0085171b          	slliw	a4,a0,0x8
    80006774:	0c0027b7          	lui	a5,0xc002
    80006778:	97ba                	add	a5,a5,a4
    8000677a:	40200713          	li	a4,1026
    8000677e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006782:	00d5151b          	slliw	a0,a0,0xd
    80006786:	0c2017b7          	lui	a5,0xc201
    8000678a:	953e                	add	a0,a0,a5
    8000678c:	00052023          	sw	zero,0(a0)
}
    80006790:	60a2                	ld	ra,8(sp)
    80006792:	6402                	ld	s0,0(sp)
    80006794:	0141                	addi	sp,sp,16
    80006796:	8082                	ret

0000000080006798 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006798:	1141                	addi	sp,sp,-16
    8000679a:	e406                	sd	ra,8(sp)
    8000679c:	e022                	sd	s0,0(sp)
    8000679e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067a0:	ffffb097          	auipc	ra,0xffffb
    800067a4:	72e080e7          	jalr	1838(ra) # 80001ece <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800067a8:	00d5179b          	slliw	a5,a0,0xd
    800067ac:	0c201537          	lui	a0,0xc201
    800067b0:	953e                	add	a0,a0,a5
  return irq;
}
    800067b2:	4148                	lw	a0,4(a0)
    800067b4:	60a2                	ld	ra,8(sp)
    800067b6:	6402                	ld	s0,0(sp)
    800067b8:	0141                	addi	sp,sp,16
    800067ba:	8082                	ret

00000000800067bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800067bc:	1101                	addi	sp,sp,-32
    800067be:	ec06                	sd	ra,24(sp)
    800067c0:	e822                	sd	s0,16(sp)
    800067c2:	e426                	sd	s1,8(sp)
    800067c4:	1000                	addi	s0,sp,32
    800067c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800067c8:	ffffb097          	auipc	ra,0xffffb
    800067cc:	706080e7          	jalr	1798(ra) # 80001ece <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800067d0:	00d5151b          	slliw	a0,a0,0xd
    800067d4:	0c2017b7          	lui	a5,0xc201
    800067d8:	97aa                	add	a5,a5,a0
    800067da:	c3c4                	sw	s1,4(a5)
}
    800067dc:	60e2                	ld	ra,24(sp)
    800067de:	6442                	ld	s0,16(sp)
    800067e0:	64a2                	ld	s1,8(sp)
    800067e2:	6105                	addi	sp,sp,32
    800067e4:	8082                	ret

00000000800067e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800067e6:	1141                	addi	sp,sp,-16
    800067e8:	e406                	sd	ra,8(sp)
    800067ea:	e022                	sd	s0,0(sp)
    800067ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800067ee:	479d                	li	a5,7
    800067f0:	06a7c963          	blt	a5,a0,80006862 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800067f4:	0002d797          	auipc	a5,0x2d
    800067f8:	80c78793          	addi	a5,a5,-2036 # 80033000 <disk>
    800067fc:	00a78733          	add	a4,a5,a0
    80006800:	6789                	lui	a5,0x2
    80006802:	97ba                	add	a5,a5,a4
    80006804:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006808:	e7ad                	bnez	a5,80006872 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000680a:	00451793          	slli	a5,a0,0x4
    8000680e:	0002e717          	auipc	a4,0x2e
    80006812:	7f270713          	addi	a4,a4,2034 # 80035000 <disk+0x2000>
    80006816:	6314                	ld	a3,0(a4)
    80006818:	96be                	add	a3,a3,a5
    8000681a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000681e:	6314                	ld	a3,0(a4)
    80006820:	96be                	add	a3,a3,a5
    80006822:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006826:	6314                	ld	a3,0(a4)
    80006828:	96be                	add	a3,a3,a5
    8000682a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000682e:	6318                	ld	a4,0(a4)
    80006830:	97ba                	add	a5,a5,a4
    80006832:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006836:	0002c797          	auipc	a5,0x2c
    8000683a:	7ca78793          	addi	a5,a5,1994 # 80033000 <disk>
    8000683e:	97aa                	add	a5,a5,a0
    80006840:	6509                	lui	a0,0x2
    80006842:	953e                	add	a0,a0,a5
    80006844:	4785                	li	a5,1
    80006846:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000684a:	0002e517          	auipc	a0,0x2e
    8000684e:	7ce50513          	addi	a0,a0,1998 # 80035018 <disk+0x2018>
    80006852:	ffffc097          	auipc	ra,0xffffc
    80006856:	fe8080e7          	jalr	-24(ra) # 8000283a <wakeup>
}
    8000685a:	60a2                	ld	ra,8(sp)
    8000685c:	6402                	ld	s0,0(sp)
    8000685e:	0141                	addi	sp,sp,16
    80006860:	8082                	ret
    panic("free_desc 1");
    80006862:	00002517          	auipc	a0,0x2
    80006866:	f5e50513          	addi	a0,a0,-162 # 800087c0 <syscalls+0x358>
    8000686a:	ffffa097          	auipc	ra,0xffffa
    8000686e:	cc0080e7          	jalr	-832(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006872:	00002517          	auipc	a0,0x2
    80006876:	f5e50513          	addi	a0,a0,-162 # 800087d0 <syscalls+0x368>
    8000687a:	ffffa097          	auipc	ra,0xffffa
    8000687e:	cb0080e7          	jalr	-848(ra) # 8000052a <panic>

0000000080006882 <virtio_disk_init>:
{
    80006882:	1101                	addi	sp,sp,-32
    80006884:	ec06                	sd	ra,24(sp)
    80006886:	e822                	sd	s0,16(sp)
    80006888:	e426                	sd	s1,8(sp)
    8000688a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000688c:	00002597          	auipc	a1,0x2
    80006890:	f5458593          	addi	a1,a1,-172 # 800087e0 <syscalls+0x378>
    80006894:	0002f517          	auipc	a0,0x2f
    80006898:	89450513          	addi	a0,a0,-1900 # 80035128 <disk+0x2128>
    8000689c:	ffffa097          	auipc	ra,0xffffa
    800068a0:	296080e7          	jalr	662(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068a4:	100017b7          	lui	a5,0x10001
    800068a8:	4398                	lw	a4,0(a5)
    800068aa:	2701                	sext.w	a4,a4
    800068ac:	747277b7          	lui	a5,0x74727
    800068b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800068b4:	0ef71163          	bne	a4,a5,80006996 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800068b8:	100017b7          	lui	a5,0x10001
    800068bc:	43dc                	lw	a5,4(a5)
    800068be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068c0:	4705                	li	a4,1
    800068c2:	0ce79a63          	bne	a5,a4,80006996 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068c6:	100017b7          	lui	a5,0x10001
    800068ca:	479c                	lw	a5,8(a5)
    800068cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800068ce:	4709                	li	a4,2
    800068d0:	0ce79363          	bne	a5,a4,80006996 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800068d4:	100017b7          	lui	a5,0x10001
    800068d8:	47d8                	lw	a4,12(a5)
    800068da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068dc:	554d47b7          	lui	a5,0x554d4
    800068e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800068e4:	0af71963          	bne	a4,a5,80006996 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800068e8:	100017b7          	lui	a5,0x10001
    800068ec:	4705                	li	a4,1
    800068ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068f0:	470d                	li	a4,3
    800068f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800068f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800068f6:	c7ffe737          	lui	a4,0xc7ffe
    800068fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc875f>
    800068fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006900:	2701                	sext.w	a4,a4
    80006902:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006904:	472d                	li	a4,11
    80006906:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006908:	473d                	li	a4,15
    8000690a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000690c:	6705                	lui	a4,0x1
    8000690e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006910:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006914:	5bdc                	lw	a5,52(a5)
    80006916:	2781                	sext.w	a5,a5
  if(max == 0)
    80006918:	c7d9                	beqz	a5,800069a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000691a:	471d                	li	a4,7
    8000691c:	08f77d63          	bgeu	a4,a5,800069b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006920:	100014b7          	lui	s1,0x10001
    80006924:	47a1                	li	a5,8
    80006926:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006928:	6609                	lui	a2,0x2
    8000692a:	4581                	li	a1,0
    8000692c:	0002c517          	auipc	a0,0x2c
    80006930:	6d450513          	addi	a0,a0,1748 # 80033000 <disk>
    80006934:	ffffa097          	auipc	ra,0xffffa
    80006938:	38a080e7          	jalr	906(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000693c:	0002c717          	auipc	a4,0x2c
    80006940:	6c470713          	addi	a4,a4,1732 # 80033000 <disk>
    80006944:	00c75793          	srli	a5,a4,0xc
    80006948:	2781                	sext.w	a5,a5
    8000694a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000694c:	0002e797          	auipc	a5,0x2e
    80006950:	6b478793          	addi	a5,a5,1716 # 80035000 <disk+0x2000>
    80006954:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006956:	0002c717          	auipc	a4,0x2c
    8000695a:	72a70713          	addi	a4,a4,1834 # 80033080 <disk+0x80>
    8000695e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006960:	0002d717          	auipc	a4,0x2d
    80006964:	6a070713          	addi	a4,a4,1696 # 80034000 <disk+0x1000>
    80006968:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000696a:	4705                	li	a4,1
    8000696c:	00e78c23          	sb	a4,24(a5)
    80006970:	00e78ca3          	sb	a4,25(a5)
    80006974:	00e78d23          	sb	a4,26(a5)
    80006978:	00e78da3          	sb	a4,27(a5)
    8000697c:	00e78e23          	sb	a4,28(a5)
    80006980:	00e78ea3          	sb	a4,29(a5)
    80006984:	00e78f23          	sb	a4,30(a5)
    80006988:	00e78fa3          	sb	a4,31(a5)
}
    8000698c:	60e2                	ld	ra,24(sp)
    8000698e:	6442                	ld	s0,16(sp)
    80006990:	64a2                	ld	s1,8(sp)
    80006992:	6105                	addi	sp,sp,32
    80006994:	8082                	ret
    panic("could not find virtio disk");
    80006996:	00002517          	auipc	a0,0x2
    8000699a:	e5a50513          	addi	a0,a0,-422 # 800087f0 <syscalls+0x388>
    8000699e:	ffffa097          	auipc	ra,0xffffa
    800069a2:	b8c080e7          	jalr	-1140(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800069a6:	00002517          	auipc	a0,0x2
    800069aa:	e6a50513          	addi	a0,a0,-406 # 80008810 <syscalls+0x3a8>
    800069ae:	ffffa097          	auipc	ra,0xffffa
    800069b2:	b7c080e7          	jalr	-1156(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800069b6:	00002517          	auipc	a0,0x2
    800069ba:	e7a50513          	addi	a0,a0,-390 # 80008830 <syscalls+0x3c8>
    800069be:	ffffa097          	auipc	ra,0xffffa
    800069c2:	b6c080e7          	jalr	-1172(ra) # 8000052a <panic>

00000000800069c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800069c6:	7119                	addi	sp,sp,-128
    800069c8:	fc86                	sd	ra,120(sp)
    800069ca:	f8a2                	sd	s0,112(sp)
    800069cc:	f4a6                	sd	s1,104(sp)
    800069ce:	f0ca                	sd	s2,96(sp)
    800069d0:	ecce                	sd	s3,88(sp)
    800069d2:	e8d2                	sd	s4,80(sp)
    800069d4:	e4d6                	sd	s5,72(sp)
    800069d6:	e0da                	sd	s6,64(sp)
    800069d8:	fc5e                	sd	s7,56(sp)
    800069da:	f862                	sd	s8,48(sp)
    800069dc:	f466                	sd	s9,40(sp)
    800069de:	f06a                	sd	s10,32(sp)
    800069e0:	ec6e                	sd	s11,24(sp)
    800069e2:	0100                	addi	s0,sp,128
    800069e4:	8aaa                	mv	s5,a0
    800069e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800069e8:	00c52c83          	lw	s9,12(a0)
    800069ec:	001c9c9b          	slliw	s9,s9,0x1
    800069f0:	1c82                	slli	s9,s9,0x20
    800069f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800069f6:	0002e517          	auipc	a0,0x2e
    800069fa:	73250513          	addi	a0,a0,1842 # 80035128 <disk+0x2128>
    800069fe:	ffffa097          	auipc	ra,0xffffa
    80006a02:	1c4080e7          	jalr	452(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006a06:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006a08:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006a0a:	0002cc17          	auipc	s8,0x2c
    80006a0e:	5f6c0c13          	addi	s8,s8,1526 # 80033000 <disk>
    80006a12:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006a14:	4b0d                	li	s6,3
    80006a16:	a0ad                	j	80006a80 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006a18:	00fc0733          	add	a4,s8,a5
    80006a1c:	975e                	add	a4,a4,s7
    80006a1e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a22:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006a24:	0207c563          	bltz	a5,80006a4e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006a28:	2905                	addiw	s2,s2,1
    80006a2a:	0611                	addi	a2,a2,4
    80006a2c:	19690d63          	beq	s2,s6,80006bc6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006a30:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006a32:	0002e717          	auipc	a4,0x2e
    80006a36:	5e670713          	addi	a4,a4,1510 # 80035018 <disk+0x2018>
    80006a3a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006a3c:	00074683          	lbu	a3,0(a4)
    80006a40:	fee1                	bnez	a3,80006a18 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006a42:	2785                	addiw	a5,a5,1
    80006a44:	0705                	addi	a4,a4,1
    80006a46:	fe979be3          	bne	a5,s1,80006a3c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006a4a:	57fd                	li	a5,-1
    80006a4c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006a4e:	01205d63          	blez	s2,80006a68 <virtio_disk_rw+0xa2>
    80006a52:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006a54:	000a2503          	lw	a0,0(s4)
    80006a58:	00000097          	auipc	ra,0x0
    80006a5c:	d8e080e7          	jalr	-626(ra) # 800067e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006a60:	2d85                	addiw	s11,s11,1
    80006a62:	0a11                	addi	s4,s4,4
    80006a64:	ffb918e3          	bne	s2,s11,80006a54 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a68:	0002e597          	auipc	a1,0x2e
    80006a6c:	6c058593          	addi	a1,a1,1728 # 80035128 <disk+0x2128>
    80006a70:	0002e517          	auipc	a0,0x2e
    80006a74:	5a850513          	addi	a0,a0,1448 # 80035018 <disk+0x2018>
    80006a78:	ffffc097          	auipc	ra,0xffffc
    80006a7c:	c36080e7          	jalr	-970(ra) # 800026ae <sleep>
  for(int i = 0; i < 3; i++){
    80006a80:	f8040a13          	addi	s4,s0,-128
{
    80006a84:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006a86:	894e                	mv	s2,s3
    80006a88:	b765                	j	80006a30 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006a8a:	0002e697          	auipc	a3,0x2e
    80006a8e:	5766b683          	ld	a3,1398(a3) # 80035000 <disk+0x2000>
    80006a92:	96ba                	add	a3,a3,a4
    80006a94:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006a98:	0002c817          	auipc	a6,0x2c
    80006a9c:	56880813          	addi	a6,a6,1384 # 80033000 <disk>
    80006aa0:	0002e697          	auipc	a3,0x2e
    80006aa4:	56068693          	addi	a3,a3,1376 # 80035000 <disk+0x2000>
    80006aa8:	6290                	ld	a2,0(a3)
    80006aaa:	963a                	add	a2,a2,a4
    80006aac:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006ab0:	0015e593          	ori	a1,a1,1
    80006ab4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006ab8:	f8842603          	lw	a2,-120(s0)
    80006abc:	628c                	ld	a1,0(a3)
    80006abe:	972e                	add	a4,a4,a1
    80006ac0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ac4:	20050593          	addi	a1,a0,512
    80006ac8:	0592                	slli	a1,a1,0x4
    80006aca:	95c2                	add	a1,a1,a6
    80006acc:	577d                	li	a4,-1
    80006ace:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006ad2:	00461713          	slli	a4,a2,0x4
    80006ad6:	6290                	ld	a2,0(a3)
    80006ad8:	963a                	add	a2,a2,a4
    80006ada:	03078793          	addi	a5,a5,48
    80006ade:	97c2                	add	a5,a5,a6
    80006ae0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006ae2:	629c                	ld	a5,0(a3)
    80006ae4:	97ba                	add	a5,a5,a4
    80006ae6:	4605                	li	a2,1
    80006ae8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006aea:	629c                	ld	a5,0(a3)
    80006aec:	97ba                	add	a5,a5,a4
    80006aee:	4809                	li	a6,2
    80006af0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006af4:	629c                	ld	a5,0(a3)
    80006af6:	973e                	add	a4,a4,a5
    80006af8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006afc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006b00:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b04:	6698                	ld	a4,8(a3)
    80006b06:	00275783          	lhu	a5,2(a4)
    80006b0a:	8b9d                	andi	a5,a5,7
    80006b0c:	0786                	slli	a5,a5,0x1
    80006b0e:	97ba                	add	a5,a5,a4
    80006b10:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006b14:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b18:	6698                	ld	a4,8(a3)
    80006b1a:	00275783          	lhu	a5,2(a4)
    80006b1e:	2785                	addiw	a5,a5,1
    80006b20:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b24:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b28:	100017b7          	lui	a5,0x10001
    80006b2c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b30:	004aa783          	lw	a5,4(s5)
    80006b34:	02c79163          	bne	a5,a2,80006b56 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006b38:	0002e917          	auipc	s2,0x2e
    80006b3c:	5f090913          	addi	s2,s2,1520 # 80035128 <disk+0x2128>
  while(b->disk == 1) {
    80006b40:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006b42:	85ca                	mv	a1,s2
    80006b44:	8556                	mv	a0,s5
    80006b46:	ffffc097          	auipc	ra,0xffffc
    80006b4a:	b68080e7          	jalr	-1176(ra) # 800026ae <sleep>
  while(b->disk == 1) {
    80006b4e:	004aa783          	lw	a5,4(s5)
    80006b52:	fe9788e3          	beq	a5,s1,80006b42 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006b56:	f8042903          	lw	s2,-128(s0)
    80006b5a:	20090793          	addi	a5,s2,512
    80006b5e:	00479713          	slli	a4,a5,0x4
    80006b62:	0002c797          	auipc	a5,0x2c
    80006b66:	49e78793          	addi	a5,a5,1182 # 80033000 <disk>
    80006b6a:	97ba                	add	a5,a5,a4
    80006b6c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006b70:	0002e997          	auipc	s3,0x2e
    80006b74:	49098993          	addi	s3,s3,1168 # 80035000 <disk+0x2000>
    80006b78:	00491713          	slli	a4,s2,0x4
    80006b7c:	0009b783          	ld	a5,0(s3)
    80006b80:	97ba                	add	a5,a5,a4
    80006b82:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b86:	854a                	mv	a0,s2
    80006b88:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b8c:	00000097          	auipc	ra,0x0
    80006b90:	c5a080e7          	jalr	-934(ra) # 800067e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006b94:	8885                	andi	s1,s1,1
    80006b96:	f0ed                	bnez	s1,80006b78 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006b98:	0002e517          	auipc	a0,0x2e
    80006b9c:	59050513          	addi	a0,a0,1424 # 80035128 <disk+0x2128>
    80006ba0:	ffffa097          	auipc	ra,0xffffa
    80006ba4:	0d6080e7          	jalr	214(ra) # 80000c76 <release>
}
    80006ba8:	70e6                	ld	ra,120(sp)
    80006baa:	7446                	ld	s0,112(sp)
    80006bac:	74a6                	ld	s1,104(sp)
    80006bae:	7906                	ld	s2,96(sp)
    80006bb0:	69e6                	ld	s3,88(sp)
    80006bb2:	6a46                	ld	s4,80(sp)
    80006bb4:	6aa6                	ld	s5,72(sp)
    80006bb6:	6b06                	ld	s6,64(sp)
    80006bb8:	7be2                	ld	s7,56(sp)
    80006bba:	7c42                	ld	s8,48(sp)
    80006bbc:	7ca2                	ld	s9,40(sp)
    80006bbe:	7d02                	ld	s10,32(sp)
    80006bc0:	6de2                	ld	s11,24(sp)
    80006bc2:	6109                	addi	sp,sp,128
    80006bc4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bc6:	f8042503          	lw	a0,-128(s0)
    80006bca:	20050793          	addi	a5,a0,512
    80006bce:	0792                	slli	a5,a5,0x4
  if(write)
    80006bd0:	0002c817          	auipc	a6,0x2c
    80006bd4:	43080813          	addi	a6,a6,1072 # 80033000 <disk>
    80006bd8:	00f80733          	add	a4,a6,a5
    80006bdc:	01a036b3          	snez	a3,s10
    80006be0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006be4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006be8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bec:	7679                	lui	a2,0xffffe
    80006bee:	963e                	add	a2,a2,a5
    80006bf0:	0002e697          	auipc	a3,0x2e
    80006bf4:	41068693          	addi	a3,a3,1040 # 80035000 <disk+0x2000>
    80006bf8:	6298                	ld	a4,0(a3)
    80006bfa:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bfc:	0a878593          	addi	a1,a5,168
    80006c00:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c02:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c04:	6298                	ld	a4,0(a3)
    80006c06:	9732                	add	a4,a4,a2
    80006c08:	45c1                	li	a1,16
    80006c0a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c0c:	6298                	ld	a4,0(a3)
    80006c0e:	9732                	add	a4,a4,a2
    80006c10:	4585                	li	a1,1
    80006c12:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c16:	f8442703          	lw	a4,-124(s0)
    80006c1a:	628c                	ld	a1,0(a3)
    80006c1c:	962e                	add	a2,a2,a1
    80006c1e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffc800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c22:	0712                	slli	a4,a4,0x4
    80006c24:	6290                	ld	a2,0(a3)
    80006c26:	963a                	add	a2,a2,a4
    80006c28:	058a8593          	addi	a1,s5,88
    80006c2c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c2e:	6294                	ld	a3,0(a3)
    80006c30:	96ba                	add	a3,a3,a4
    80006c32:	40000613          	li	a2,1024
    80006c36:	c690                	sw	a2,8(a3)
  if(write)
    80006c38:	e40d19e3          	bnez	s10,80006a8a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006c3c:	0002e697          	auipc	a3,0x2e
    80006c40:	3c46b683          	ld	a3,964(a3) # 80035000 <disk+0x2000>
    80006c44:	96ba                	add	a3,a3,a4
    80006c46:	4609                	li	a2,2
    80006c48:	00c69623          	sh	a2,12(a3)
    80006c4c:	b5b1                	j	80006a98 <virtio_disk_rw+0xd2>

0000000080006c4e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006c4e:	1101                	addi	sp,sp,-32
    80006c50:	ec06                	sd	ra,24(sp)
    80006c52:	e822                	sd	s0,16(sp)
    80006c54:	e426                	sd	s1,8(sp)
    80006c56:	e04a                	sd	s2,0(sp)
    80006c58:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006c5a:	0002e517          	auipc	a0,0x2e
    80006c5e:	4ce50513          	addi	a0,a0,1230 # 80035128 <disk+0x2128>
    80006c62:	ffffa097          	auipc	ra,0xffffa
    80006c66:	f60080e7          	jalr	-160(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006c6a:	10001737          	lui	a4,0x10001
    80006c6e:	533c                	lw	a5,96(a4)
    80006c70:	8b8d                	andi	a5,a5,3
    80006c72:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c74:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c78:	0002e797          	auipc	a5,0x2e
    80006c7c:	38878793          	addi	a5,a5,904 # 80035000 <disk+0x2000>
    80006c80:	6b94                	ld	a3,16(a5)
    80006c82:	0207d703          	lhu	a4,32(a5)
    80006c86:	0026d783          	lhu	a5,2(a3)
    80006c8a:	06f70163          	beq	a4,a5,80006cec <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c8e:	0002c917          	auipc	s2,0x2c
    80006c92:	37290913          	addi	s2,s2,882 # 80033000 <disk>
    80006c96:	0002e497          	auipc	s1,0x2e
    80006c9a:	36a48493          	addi	s1,s1,874 # 80035000 <disk+0x2000>
    __sync_synchronize();
    80006c9e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ca2:	6898                	ld	a4,16(s1)
    80006ca4:	0204d783          	lhu	a5,32(s1)
    80006ca8:	8b9d                	andi	a5,a5,7
    80006caa:	078e                	slli	a5,a5,0x3
    80006cac:	97ba                	add	a5,a5,a4
    80006cae:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006cb0:	20078713          	addi	a4,a5,512
    80006cb4:	0712                	slli	a4,a4,0x4
    80006cb6:	974a                	add	a4,a4,s2
    80006cb8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006cbc:	e731                	bnez	a4,80006d08 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006cbe:	20078793          	addi	a5,a5,512
    80006cc2:	0792                	slli	a5,a5,0x4
    80006cc4:	97ca                	add	a5,a5,s2
    80006cc6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006cc8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ccc:	ffffc097          	auipc	ra,0xffffc
    80006cd0:	b6e080e7          	jalr	-1170(ra) # 8000283a <wakeup>

    disk.used_idx += 1;
    80006cd4:	0204d783          	lhu	a5,32(s1)
    80006cd8:	2785                	addiw	a5,a5,1
    80006cda:	17c2                	slli	a5,a5,0x30
    80006cdc:	93c1                	srli	a5,a5,0x30
    80006cde:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ce2:	6898                	ld	a4,16(s1)
    80006ce4:	00275703          	lhu	a4,2(a4)
    80006ce8:	faf71be3          	bne	a4,a5,80006c9e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006cec:	0002e517          	auipc	a0,0x2e
    80006cf0:	43c50513          	addi	a0,a0,1084 # 80035128 <disk+0x2128>
    80006cf4:	ffffa097          	auipc	ra,0xffffa
    80006cf8:	f82080e7          	jalr	-126(ra) # 80000c76 <release>
}
    80006cfc:	60e2                	ld	ra,24(sp)
    80006cfe:	6442                	ld	s0,16(sp)
    80006d00:	64a2                	ld	s1,8(sp)
    80006d02:	6902                	ld	s2,0(sp)
    80006d04:	6105                	addi	sp,sp,32
    80006d06:	8082                	ret
      panic("virtio_disk_intr status");
    80006d08:	00002517          	auipc	a0,0x2
    80006d0c:	b4850513          	addi	a0,a0,-1208 # 80008850 <syscalls+0x3e8>
    80006d10:	ffffa097          	auipc	ra,0xffffa
    80006d14:	81a080e7          	jalr	-2022(ra) # 8000052a <panic>
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
