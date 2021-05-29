
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
    80000122:	a0e080e7          	jalr	-1522(ra) # 80002b2c <either_copyin>
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
    800001b6:	d9e080e7          	jalr	-610(ra) # 80001f50 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	55a080e7          	jalr	1370(ra) # 8000271c <sleep>
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
    80000202:	8d8080e7          	jalr	-1832(ra) # 80002ad6 <either_copyout>
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
    800002e2:	8a4080e7          	jalr	-1884(ra) # 80002b82 <procdump>
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
    80000436:	476080e7          	jalr	1142(ra) # 800028a8 <wakeup>
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
    80000882:	02a080e7          	jalr	42(ra) # 800028a8 <wakeup>
    
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
    8000090e:	e12080e7          	jalr	-494(ra) # 8000271c <sleep>
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
    80000b60:	3d8080e7          	jalr	984(ra) # 80001f34 <mycpu>
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
    80000b92:	3a6080e7          	jalr	934(ra) # 80001f34 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	39a080e7          	jalr	922(ra) # 80001f34 <mycpu>
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
    80000bb6:	382080e7          	jalr	898(ra) # 80001f34 <mycpu>
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
    80000bf6:	342080e7          	jalr	834(ra) # 80001f34 <mycpu>
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
    80000c22:	316080e7          	jalr	790(ra) # 80001f34 <mycpu>
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
    80000e78:	0b0080e7          	jalr	176(ra) # 80001f24 <cpuid>
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
    80000e94:	094080e7          	jalr	148(ra) # 80001f24 <cpuid>
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
    80000eb6:	e12080e7          	jalr	-494(ra) # 80002cc4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	916080e7          	jalr	-1770(ra) # 800067d0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	6a8080e7          	jalr	1704(ra) # 8000256a <scheduler>
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
    80000f26:	f52080e7          	jalr	-174(ra) # 80001e74 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	d72080e7          	jalr	-654(ra) # 80002c9c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	d92080e7          	jalr	-622(ra) # 80002cc4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	880080e7          	jalr	-1920(ra) # 800067ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	88e080e7          	jalr	-1906(ra) # 800067d0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	4d0080e7          	jalr	1232(ra) # 8000341a <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	b62080e7          	jalr	-1182(ra) # 80003ab4 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	e22080e7          	jalr	-478(ra) # 80004d7c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	990080e7          	jalr	-1648(ra) # 800068f2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	314080e7          	jalr	788(ra) # 8000227e <userinit>
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
    80001210:	bd2080e7          	jalr	-1070(ra) # 80001dde <proc_mapstacks>
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
    800012d2:	c82080e7          	jalr	-894(ra) # 80001f50 <myproc>
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
    80001842:	712080e7          	jalr	1810(ra) # 80001f50 <myproc>
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
    800018e8:	66c080e7          	jalr	1644(ra) # 80001f50 <myproc>
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
    8000193e:	616080e7          	jalr	1558(ra) # 80001f50 <myproc>
    80001942:	89aa                	mv	s3,a0
  findIndex:
  min_creation_time = (uint64)~0;
  min_creation_index = 1;


  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    80001944:	17050a13          	addi	s4,a0,368
    80001948:	37050913          	addi	s2,a0,880
  min_creation_index = 1;
    8000194c:	4b05                	li	s6,1
  min_creation_time = (uint64)~0;
    8000194e:	5afd                	li	s5,-1
    80001950:	a8b1                	j	800019ac <get_page_scfifo+0x86>
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    80001952:	02078793          	addi	a5,a5,32
    80001956:	01278e63          	beq	a5,s2,80001972 <get_page_scfifo+0x4c>
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
    80001990:	c315                	beqz	a4,800019b4 <get_page_scfifo+0x8e>
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
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){ // loop over and fine min creation time for fifo 
    800019ac:	87d2                	mv	a5,s4
  min_creation_index = 1;
    800019ae:	84da                	mv	s1,s6
  min_creation_time = (uint64)~0;
    800019b0:	86d6                	mv	a3,s5
    800019b2:	b765                	j	8000195a <get_page_scfifo+0x34>
    goto findIndex; // find again 
  }
  // if got here then we found pg with min time that PTE_A is turned off
  return min_creation_index;
}
    800019b4:	8526                	mv	a0,s1
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret

00000000800019ca <get_page_lapa>:

int get_page_lapa(){
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e406                	sd	ra,8(sp)
    800019ce:	e022                	sd	s0,0(sp)
    800019d0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	57e080e7          	jalr	1406(ra) # 80001f50 <myproc>
    800019da:	87aa                	mv	a5,a0
  struct page_metadata *pg;
  int min_number_of_1=64;
  int index_with_min_1=-1;
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800019dc:	19050613          	addi	a2,a0,400
    800019e0:	37050e13          	addi	t3,a0,880
  int index_with_min_1=-1;
    800019e4:	557d                	li	a0,-1
  int min_number_of_1=64;
    800019e6:	04000593          	li	a1,64
    int counter=0,stoploop=0;
    if(pg->state){
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    800019ea:	4f01                	li	t5,0
          uint64 mask = 1 << i;
    800019ec:	4885                	li	a7,1
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    800019ee:	04000313          	li	t1,64
          if(counter>min_number_of_1) // in case count is bigger than current min 
            stoploop=1;           // stop counting and break from loop
        }
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
          min_number_of_1=counter;
          index_with_min_1=(int)(pg - p->pages_in_memory);
    800019f2:	17078e93          	addi	t4,a5,368
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    800019f6:	5ffd                	li	t6,-1
    800019f8:	a805                	j	80001a28 <get_page_lapa+0x5e>
          if(counter>min_number_of_1) // in case count is bigger than current min 
    800019fa:	02d5ce63          	blt	a1,a3,80001a36 <get_page_lapa+0x6c>
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    800019fe:	2705                	addiw	a4,a4,1
    80001a00:	00670963          	beq	a4,t1,80001a12 <get_page_lapa+0x48>
          uint64 mask = 1 << i;
    80001a04:	00e897bb          	sllw	a5,a7,a4
          if((pg->age & mask)!=0)// if 1 is found 
    80001a08:	0107f7b3          	and	a5,a5,a6
    80001a0c:	d7fd                	beqz	a5,800019fa <get_page_lapa+0x30>
              counter++;
    80001a0e:	2685                	addiw	a3,a3,1
    80001a10:	b7ed                	j	800019fa <get_page_lapa+0x30>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001a12:	02b6d263          	bge	a3,a1,80001a36 <get_page_lapa+0x6c>
          index_with_min_1=(int)(pg - p->pages_in_memory);
    80001a16:	41d60533          	sub	a0,a2,t4
    80001a1a:	8515                	srai	a0,a0,0x5
    80001a1c:	2501                	sext.w	a0,a0
    80001a1e:	85b6                	mv	a1,a3
  for(pg = p->pages_in_memory+1; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80001a20:	02060613          	addi	a2,a2,32 # 1020 <_entry-0x7fffefe0>
    80001a24:	01c60e63          	beq	a2,t3,80001a40 <get_page_lapa+0x76>
    if(pg->state){
    80001a28:	461c                	lw	a5,8(a2)
    80001a2a:	dbfd                	beqz	a5,80001a20 <get_page_lapa+0x56>
          if((pg->age & mask)!=0)// if 1 is found 
    80001a2c:	01063803          	ld	a6,16(a2)
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001a30:	877a                	mv	a4,t5
    int counter=0,stoploop=0;
    80001a32:	86fa                	mv	a3,t5
    80001a34:	bfc1                	j	80001a04 <get_page_lapa+0x3a>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001a36:	fff515e3          	bne	a0,t6,80001a20 <get_page_lapa+0x56>
    80001a3a:	feb693e3          	bne	a3,a1,80001a20 <get_page_lapa+0x56>
    80001a3e:	bfe1                	j	80001a16 <get_page_lapa+0x4c>
        }
      }
    }
    return index_with_min_1;
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret

0000000080001a48 <get_page_by_alg>:
// get page that will be swaped out (Task 2)
// Returns page index in pages_in_memory array, this page will be swapped out
int get_page_by_alg(){
    80001a48:	1141                	addi	sp,sp,-16
    80001a4a:	e406                	sd	ra,8(sp)
    80001a4c:	e022                	sd	s0,0(sp)
    80001a4e:	0800                	addi	s0,sp,16
  #ifdef SCFIFO
  return get_page_scfifo();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	ed6080e7          	jalr	-298(ra) # 80001926 <get_page_scfifo>
  return get_page_lapa();
  #endif
  #ifdef NONE
  return 1; //will never got here
  #endif
}
    80001a58:	60a2                	ld	ra,8(sp)
    80001a5a:	6402                	ld	s0,0(sp)
    80001a5c:	0141                	addi	sp,sp,16
    80001a5e:	8082                	ret

0000000080001a60 <swap_into_file>:


//Chose page to remove from main memory (using one of task2 algorithms) 
//and swap this page into file
void swap_into_file(pagetable_t pagetable){
    80001a60:	7139                	addi	sp,sp,-64
    80001a62:	fc06                	sd	ra,56(sp)
    80001a64:	f822                	sd	s0,48(sp)
    80001a66:	f426                	sd	s1,40(sp)
    80001a68:	f04a                	sd	s2,32(sp)
    80001a6a:	ec4e                	sd	s3,24(sp)
    80001a6c:	e852                	sd	s4,16(sp)
    80001a6e:	e456                	sd	s5,8(sp)
    80001a70:	e05a                	sd	s6,0(sp)
    80001a72:	0080                	addi	s0,sp,64
    80001a74:	8a2a                	mv	s4,a0
  #ifdef YES
  printf("too much psyc pages: lets swap into file page\n");
  #endif

  struct proc *p = myproc();
    80001a76:	00000097          	auipc	ra,0x0
    80001a7a:	4da080e7          	jalr	1242(ra) # 80001f50 <myproc>
  if(p->num_pages_in_psyc + p->num_pages_in_swapfile == MAX_TOTAL_PAGES){
    80001a7e:	57052783          	lw	a5,1392(a0)
    80001a82:	57452703          	lw	a4,1396(a0)
    80001a86:	9fb9                	addw	a5,a5,a4
    80001a88:	02000713          	li	a4,32
    80001a8c:	02e78c63          	beq	a5,a4,80001ac4 <swap_into_file+0x64>
    80001a90:	892a                	mv	s2,a0
  return get_page_scfifo();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	e94080e7          	jalr	-364(ra) # 80001926 <get_page_scfifo>

  //find free space in swaped pages array,
  //add selected to swap out page to this array 
  //and write this page to swapfile.
  struct page_metadata *pg;
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001a9a:	37090a93          	addi	s5,s2,880 # 1370 <_entry-0x7fffec90>
    80001a9e:	57090713          	addi	a4,s2,1392
    80001aa2:	84d6                	mv	s1,s5
    if(!pg->state){
    80001aa4:	449c                	lw	a5,8(s1)
    80001aa6:	c79d                	beqz	a5,80001ad4 <swap_into_file+0x74>
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001aa8:	02048493          	addi	s1,s1,32
    80001aac:	fee49ce3          	bne	s1,a4,80001aa4 <swap_into_file+0x44>
      sfence_vma(); 
      break;
    }
  }

}
    80001ab0:	70e2                	ld	ra,56(sp)
    80001ab2:	7442                	ld	s0,48(sp)
    80001ab4:	74a2                	ld	s1,40(sp)
    80001ab6:	7902                	ld	s2,32(sp)
    80001ab8:	69e2                	ld	s3,24(sp)
    80001aba:	6a42                	ld	s4,16(sp)
    80001abc:	6aa2                	ld	s5,8(sp)
    80001abe:	6b02                	ld	s6,0(sp)
    80001ac0:	6121                	addi	sp,sp,64
    80001ac2:	8082                	ret
    panic("more than 32 pages per proccess");
    80001ac4:	00006517          	auipc	a0,0x6
    80001ac8:	6fc50513          	addi	a0,a0,1788 # 800081c0 <digits+0x180>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	a5e080e7          	jalr	-1442(ra) # 8000052a <panic>
      pg->state = 1;
    80001ad4:	4785                	li	a5,1
    80001ad6:	c49c                	sw	a5,8(s1)
      pg->va = pg_to_swap->va;
    80001ad8:	00551993          	slli	s3,a0,0x5
    80001adc:	99ca                	add	s3,s3,s2
    80001ade:	1709b583          	ld	a1,368(s3)
    80001ae2:	e08c                	sd	a1,0(s1)
      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
    80001ae4:	4601                	li	a2,0
    80001ae6:	8552                	mv	a0,s4
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	4be080e7          	jalr	1214(ra) # 80000fa6 <walk>
    80001af0:	8b2a                	mv	s6,a0
      uint64 pa = PTE2PA(*pte);
    80001af2:	00053a03          	ld	s4,0(a0)
    80001af6:	00aa5a13          	srli	s4,s4,0xa
    80001afa:	0a32                	slli	s4,s4,0xc
      int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001afc:	41548633          	sub	a2,s1,s5
      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 
    80001b00:	6685                	lui	a3,0x1
    80001b02:	0076161b          	slliw	a2,a2,0x7
    80001b06:	85d2                	mv	a1,s4
    80001b08:	854a                	mv	a0,s2
    80001b0a:	00003097          	auipc	ra,0x3
    80001b0e:	c5c080e7          	jalr	-932(ra) # 80004766 <writeToSwapFile>
      p->num_pages_in_swapfile++;
    80001b12:	57492783          	lw	a5,1396(s2)
    80001b16:	2785                	addiw	a5,a5,1
    80001b18:	56f92a23          	sw	a5,1396(s2)
      kfree((void*)pa); 
    80001b1c:	8552                	mv	a0,s4
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	eb8080e7          	jalr	-328(ra) # 800009d6 <kfree>
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
    80001b26:	000b3783          	ld	a5,0(s6) # 1000 <_entry-0x7ffff000>
    80001b2a:	9bf9                	andi	a5,a5,-2
    80001b2c:	2007e793          	ori	a5,a5,512
    80001b30:	00fb3023          	sd	a5,0(s6)
      pg_to_swap->state = 0;
    80001b34:	1609ac23          	sw	zero,376(s3)
      pg_to_swap->va = 0;
    80001b38:	1609b823          	sd	zero,368(s3)
      p->num_pages_in_psyc--;
    80001b3c:	57092783          	lw	a5,1392(s2)
    80001b40:	37fd                	addiw	a5,a5,-1
    80001b42:	56f92823          	sw	a5,1392(s2)
    80001b46:	12000073          	sfence.vma
}
    80001b4a:	b79d                	j	80001ab0 <swap_into_file+0x50>

0000000080001b4c <add_to_memory>:

//Adding new page created by uvmalloc() to proccess pages
void add_to_memory(uint64 a, pagetable_t pagetable){
    80001b4c:	7179                	addi	sp,sp,-48
    80001b4e:	f406                	sd	ra,40(sp)
    80001b50:	f022                	sd	s0,32(sp)
    80001b52:	ec26                	sd	s1,24(sp)
    80001b54:	e84a                	sd	s2,16(sp)
    80001b56:	e44e                	sd	s3,8(sp)
    80001b58:	1800                	addi	s0,sp,48
    80001b5a:	892a                	mv	s2,a0
    80001b5c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	3f2080e7          	jalr	1010(ra) # 80001f50 <myproc>
    80001b66:	84aa                	mv	s1,a0
  //No free space in the psyc memory,
  //Chose page to remove from main memory (using one of task2 algorithms) 
  //and swap this page into file
  if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001b68:	57052703          	lw	a4,1392(a0)
    80001b6c:	47c1                	li	a5,16
    80001b6e:	06f70163          	beq	a4,a5,80001bd0 <add_to_memory+0x84>
    swap_into_file(pagetable);
  }

  //Now we have free space in psyc memory (maybe we had free space before too):
  //just add all page information to pages_in_memory array:
  int free_index_memory_array = find_free_index_in_memory_array();
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	cc4080e7          	jalr	-828(ra) # 80001836 <find_free_index_in_memory_array>
  
  #ifdef YES
  printf("add to file: adding va= %p\n", a);
  #endif

  pg->state = 1;
    80001b7a:	00551713          	slli	a4,a0,0x5
    80001b7e:	9726                	add	a4,a4,s1
    80001b80:	4685                	li	a3,1
    80001b82:	16d72c23          	sw	a3,376(a4)
  pg->va = a;
    80001b86:	17273823          	sd	s2,368(a4)
  #endif
  #ifdef LAPA
  pg->age = (uint64)~0;
  #endif
  #ifdef SCFIFO
  pg->creationOrder=++p->creationTimeGenerator;
    80001b8a:	5784b703          	ld	a4,1400(s1)
    80001b8e:	0705                	addi	a4,a4,1
    80001b90:	56e4bc23          	sd	a4,1400(s1)
    80001b94:	00c50793          	addi	a5,a0,12
    80001b98:	0796                	slli	a5,a5,0x5
    80001b9a:	97a6                	add	a5,a5,s1
    80001b9c:	e798                	sd	a4,8(a5)
  #endif

  p->num_pages_in_psyc++;
    80001b9e:	5704a783          	lw	a5,1392(s1)
    80001ba2:	2785                	addiw	a5,a5,1
    80001ba4:	56f4a823          	sw	a5,1392(s1)

  pte_t* pte = walk(pagetable, pg->va, 0);
    80001ba8:	4601                	li	a2,0
    80001baa:	85ca                	mv	a1,s2
    80001bac:	854e                	mv	a0,s3
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	3f8080e7          	jalr	1016(ra) # 80000fa6 <walk>
  //set pte flags:
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001bb6:	611c                	ld	a5,0(a0)
    80001bb8:	dff7f793          	andi	a5,a5,-513
  *pte |= PTE_V;
    80001bbc:	0017e793          	ori	a5,a5,1
    80001bc0:	e11c                	sd	a5,0(a0)
  #ifdef YES
  printf("finish add to memory: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
  #endif
}
    80001bc2:	70a2                	ld	ra,40(sp)
    80001bc4:	7402                	ld	s0,32(sp)
    80001bc6:	64e2                	ld	s1,24(sp)
    80001bc8:	6942                	ld	s2,16(sp)
    80001bca:	69a2                	ld	s3,8(sp)
    80001bcc:	6145                	addi	sp,sp,48
    80001bce:	8082                	ret
    swap_into_file(pagetable);
    80001bd0:	854e                	mv	a0,s3
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	e8e080e7          	jalr	-370(ra) # 80001a60 <swap_into_file>
    80001bda:	bf61                	j	80001b72 <add_to_memory+0x26>

0000000080001bdc <uvmalloc>:
  if(newsz < oldsz)
    80001bdc:	0cb66363          	bltu	a2,a1,80001ca2 <uvmalloc+0xc6>
{
    80001be0:	7139                	addi	sp,sp,-64
    80001be2:	fc06                	sd	ra,56(sp)
    80001be4:	f822                	sd	s0,48(sp)
    80001be6:	f426                	sd	s1,40(sp)
    80001be8:	f04a                	sd	s2,32(sp)
    80001bea:	ec4e                	sd	s3,24(sp)
    80001bec:	e852                	sd	s4,16(sp)
    80001bee:	e456                	sd	s5,8(sp)
    80001bf0:	e05a                	sd	s6,0(sp)
    80001bf2:	0080                	addi	s0,sp,64
    80001bf4:	89aa                	mv	s3,a0
    80001bf6:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    80001bf8:	6a05                	lui	s4,0x1
    80001bfa:	1a7d                	addi	s4,s4,-1
    80001bfc:	95d2                	add	a1,a1,s4
    80001bfe:	7a7d                	lui	s4,0xfffff
    80001c00:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001c04:	0aca7163          	bgeu	s4,a2,80001ca6 <uvmalloc+0xca>
    80001c08:	8952                	mv	s2,s4
    if(myproc()->pid > 2){
    80001c0a:	4b09                	li	s6,2
    80001c0c:	a0a9                	j	80001c56 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001c0e:	8652                	mv	a2,s4
    80001c10:	85ca                	mv	a1,s2
    80001c12:	854e                	mv	a0,s3
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	832080e7          	jalr	-1998(ra) # 80001446 <uvmdealloc>
      return 0;
    80001c1c:	4501                	li	a0,0
}
    80001c1e:	70e2                	ld	ra,56(sp)
    80001c20:	7442                	ld	s0,48(sp)
    80001c22:	74a2                	ld	s1,40(sp)
    80001c24:	7902                	ld	s2,32(sp)
    80001c26:	69e2                	ld	s3,24(sp)
    80001c28:	6a42                	ld	s4,16(sp)
    80001c2a:	6aa2                	ld	s5,8(sp)
    80001c2c:	6b02                	ld	s6,0(sp)
    80001c2e:	6121                	addi	sp,sp,64
    80001c30:	8082                	ret
      kfree(mem);
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	da2080e7          	jalr	-606(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001c3c:	8652                	mv	a2,s4
    80001c3e:	85ca                	mv	a1,s2
    80001c40:	854e                	mv	a0,s3
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	804080e7          	jalr	-2044(ra) # 80001446 <uvmdealloc>
      return 0;
    80001c4a:	4501                	li	a0,0
    80001c4c:	bfc9                	j	80001c1e <uvmalloc+0x42>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001c4e:	6785                	lui	a5,0x1
    80001c50:	993e                	add	s2,s2,a5
    80001c52:	05597663          	bgeu	s2,s5,80001c9e <uvmalloc+0xc2>
    mem = kalloc();
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	e7c080e7          	jalr	-388(ra) # 80000ad2 <kalloc>
    80001c5e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001c60:	d55d                	beqz	a0,80001c0e <uvmalloc+0x32>
    memset(mem, 0, PGSIZE);
    80001c62:	6605                	lui	a2,0x1
    80001c64:	4581                	li	a1,0
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	058080e7          	jalr	88(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001c6e:	4779                	li	a4,30
    80001c70:	86a6                	mv	a3,s1
    80001c72:	6605                	lui	a2,0x1
    80001c74:	85ca                	mv	a1,s2
    80001c76:	854e                	mv	a0,s3
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	416080e7          	jalr	1046(ra) # 8000108e <mappages>
    80001c80:	f94d                	bnez	a0,80001c32 <uvmalloc+0x56>
    if(myproc()->pid > 2){
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	2ce080e7          	jalr	718(ra) # 80001f50 <myproc>
    80001c8a:	591c                	lw	a5,48(a0)
    80001c8c:	fcfb51e3          	bge	s6,a5,80001c4e <uvmalloc+0x72>
      add_to_memory(a, pagetable);
    80001c90:	85ce                	mv	a1,s3
    80001c92:	854a                	mv	a0,s2
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	eb8080e7          	jalr	-328(ra) # 80001b4c <add_to_memory>
    80001c9c:	bf4d                	j	80001c4e <uvmalloc+0x72>
  return newsz;
    80001c9e:	8556                	mv	a0,s5
    80001ca0:	bfbd                	j	80001c1e <uvmalloc+0x42>
    return oldsz;
    80001ca2:	852e                	mv	a0,a1
}
    80001ca4:	8082                	ret
  return newsz;
    80001ca6:	8532                	mv	a0,a2
    80001ca8:	bf9d                	j	80001c1e <uvmalloc+0x42>

0000000080001caa <handle_pagefault>:

//Handle page fault - called from trap.c
int handle_pagefault(){
    80001caa:	7139                	addi	sp,sp,-64
    80001cac:	fc06                	sd	ra,56(sp)
    80001cae:	f822                	sd	s0,48(sp)
    80001cb0:	f426                	sd	s1,40(sp)
    80001cb2:	f04a                	sd	s2,32(sp)
    80001cb4:	ec4e                	sd	s3,24(sp)
    80001cb6:	e852                	sd	s4,16(sp)
    80001cb8:	e456                	sd	s5,8(sp)
    80001cba:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	294080e7          	jalr	660(ra) # 80001f50 <myproc>
    80001cc4:	892a                	mv	s2,a0
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001cc6:	143029f3          	csrr	s3,stval
  uint64 va = r_stval();
  
  pte_t* pte = walk(p->pagetable, va, 0);
    80001cca:	4601                	li	a2,0
    80001ccc:	85ce                	mv	a1,s3
    80001cce:	6928                	ld	a0,80(a0)
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	2d6080e7          	jalr	726(ra) # 80000fa6 <walk>
  //If the page was swaped out, we should bring it back to memory
  if(*pte & PTE_PG){
    80001cd8:	610c                	ld	a1,0(a0)
    80001cda:	2005f793          	andi	a5,a1,512
    80001cde:	c7f5                	beqz	a5,80001dca <handle_pagefault+0x120>
    //If no place in memory - swap out page
    if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    80001ce0:	57092703          	lw	a4,1392(s2)
    80001ce4:	47c1                	li	a5,16
    80001ce6:	04f70263          	beq	a4,a5,80001d2a <handle_pagefault+0x80>
      swap_into_file(p->pagetable);
    }

    //Now we have free space in psyc memory (maybe we had free space before too):
    //bring page from swapFile and put it into physic memory
    uint64 va1 = PGROUNDDOWN(va);
    80001cea:	77fd                	lui	a5,0xfffff
    80001cec:	00f9f9b3          	and	s3,s3,a5
    char *mem = kalloc();
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	de2080e7          	jalr	-542(ra) # 80000ad2 <kalloc>
    80001cf8:	8a2a                	mv	s4,a0
    
    struct page_metadata *pg;
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001cfa:	37090a93          	addi	s5,s2,880
    80001cfe:	57090713          	addi	a4,s2,1392
    80001d02:	84d6                	mv	s1,s5
      if(pg->va == va1){
    80001d04:	609c                	ld	a5,0(s1)
    80001d06:	03378963          	beq	a5,s3,80001d38 <handle_pagefault+0x8e>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80001d0a:	02048493          	addi	s1,s1,32
    80001d0e:	fee49be3          	bne	s1,a4,80001d04 <handle_pagefault+0x5a>
  asm volatile("sfence.vma zero, zero");
    80001d12:	12000073          	sfence.vma
    }
    sfence_vma();
    #ifdef YES
    printf("finish handle_page\n");
    #endif
    return 3;
    80001d16:	450d                	li	a0,3
  }else{
    printf("segfault: pte: %p\n", *pte);
    return 0; //this is segfault
  }
    80001d18:	70e2                	ld	ra,56(sp)
    80001d1a:	7442                	ld	s0,48(sp)
    80001d1c:	74a2                	ld	s1,40(sp)
    80001d1e:	7902                	ld	s2,32(sp)
    80001d20:	69e2                	ld	s3,24(sp)
    80001d22:	6a42                	ld	s4,16(sp)
    80001d24:	6aa2                	ld	s5,8(sp)
    80001d26:	6121                	addi	sp,sp,64
    80001d28:	8082                	ret
      swap_into_file(p->pagetable);
    80001d2a:	05093503          	ld	a0,80(s2)
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	d32080e7          	jalr	-718(ra) # 80001a60 <swap_into_file>
    80001d36:	bf55                	j	80001cea <handle_pagefault+0x40>
        pte_t* pte = walk(p->pagetable, va1, 0);
    80001d38:	4601                	li	a2,0
    80001d3a:	85ce                	mv	a1,s3
    80001d3c:	05093503          	ld	a0,80(s2)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	266080e7          	jalr	614(ra) # 80000fa6 <walk>
    80001d48:	89aa                	mv	s3,a0
        int offset = (pg - p->pages_in_swapfile)*PGSIZE;
    80001d4a:	41548633          	sub	a2,s1,s5
        readFromSwapFile(p, mem, offset, PGSIZE);
    80001d4e:	6685                	lui	a3,0x1
    80001d50:	0076161b          	slliw	a2,a2,0x7
    80001d54:	85d2                	mv	a1,s4
    80001d56:	854a                	mv	a0,s2
    80001d58:	00003097          	auipc	ra,0x3
    80001d5c:	a32080e7          	jalr	-1486(ra) # 8000478a <readFromSwapFile>
        int free_index_memory_array = find_free_index_in_memory_array();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	ad6080e7          	jalr	-1322(ra) # 80001836 <find_free_index_in_memory_array>
        free_memory_page->state = 1;
    80001d68:	00551793          	slli	a5,a0,0x5
    80001d6c:	97ca                	add	a5,a5,s2
    80001d6e:	4705                	li	a4,1
    80001d70:	16e7ac23          	sw	a4,376(a5) # fffffffffffff178 <end+0xffffffff7ffc9178>
        free_memory_page->va = pg->va;
    80001d74:	6098                	ld	a4,0(s1)
    80001d76:	16e7b823          	sd	a4,368(a5)
        free_memory_page->creationOrder=++p->creationTimeGenerator;
    80001d7a:	57893703          	ld	a4,1400(s2)
    80001d7e:	0705                	addi	a4,a4,1
    80001d80:	56e93c23          	sd	a4,1400(s2)
    80001d84:	00c50793          	addi	a5,a0,12
    80001d88:	0796                	slli	a5,a5,0x5
    80001d8a:	97ca                	add	a5,a5,s2
    80001d8c:	e798                	sd	a4,8(a5)
        p->num_pages_in_swapfile--;
    80001d8e:	57492783          	lw	a5,1396(s2)
    80001d92:	37fd                	addiw	a5,a5,-1
    80001d94:	56f92a23          	sw	a5,1396(s2)
        pg->state = 0;
    80001d98:	0004a423          	sw	zero,8(s1)
        pg->va = 0;
    80001d9c:	0004b023          	sd	zero,0(s1)
        pg->age = 0;
    80001da0:	0004b823          	sd	zero,16(s1)
        p->num_pages_in_psyc++;
    80001da4:	57092783          	lw	a5,1392(s2)
    80001da8:	2785                	addiw	a5,a5,1
    80001daa:	56f92823          	sw	a5,1392(s2)
        *pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress 
    80001dae:	00ca5a13          	srli	s4,s4,0xc
    80001db2:	0a2a                	slli	s4,s4,0xa
    80001db4:	0009b783          	ld	a5,0(s3)
    80001db8:	1ff7f793          	andi	a5,a5,511
        *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001dbc:	0147ea33          	or	s4,a5,s4
        *pte |= PTE_V;
    80001dc0:	001a6a13          	ori	s4,s4,1
    80001dc4:	0149b023          	sd	s4,0(s3)
        break;
    80001dc8:	b7a9                	j	80001d12 <handle_pagefault+0x68>
    printf("segfault: pte: %p\n", *pte);
    80001dca:	00006517          	auipc	a0,0x6
    80001dce:	41650513          	addi	a0,a0,1046 # 800081e0 <digits+0x1a0>
    80001dd2:	ffffe097          	auipc	ra,0xffffe
    80001dd6:	7a2080e7          	jalr	1954(ra) # 80000574 <printf>
    return 0; //this is segfault
    80001dda:	4501                	li	a0,0
    80001ddc:	bf35                	j	80001d18 <handle_pagefault+0x6e>

0000000080001dde <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001dde:	7139                	addi	sp,sp,-64
    80001de0:	fc06                	sd	ra,56(sp)
    80001de2:	f822                	sd	s0,48(sp)
    80001de4:	f426                	sd	s1,40(sp)
    80001de6:	f04a                	sd	s2,32(sp)
    80001de8:	ec4e                	sd	s3,24(sp)
    80001dea:	e852                	sd	s4,16(sp)
    80001dec:	e456                	sd	s5,8(sp)
    80001dee:	e05a                	sd	s6,0(sp)
    80001df0:	0080                	addi	s0,sp,64
    80001df2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001df4:	00010497          	auipc	s1,0x10
    80001df8:	8dc48493          	addi	s1,s1,-1828 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001dfc:	8b26                	mv	s6,s1
    80001dfe:	00006a97          	auipc	s5,0x6
    80001e02:	202a8a93          	addi	s5,s5,514 # 80008000 <etext>
    80001e06:	04000937          	lui	s2,0x4000
    80001e0a:	197d                	addi	s2,s2,-1
    80001e0c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e0e:	00026a17          	auipc	s4,0x26
    80001e12:	8c2a0a13          	addi	s4,s4,-1854 # 800276d0 <tickslock>
    char *pa = kalloc();
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	cbc080e7          	jalr	-836(ra) # 80000ad2 <kalloc>
    80001e1e:	862a                	mv	a2,a0
    if(pa == 0)
    80001e20:	c131                	beqz	a0,80001e64 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001e22:	416485b3          	sub	a1,s1,s6
    80001e26:	859d                	srai	a1,a1,0x7
    80001e28:	000ab783          	ld	a5,0(s5)
    80001e2c:	02f585b3          	mul	a1,a1,a5
    80001e30:	2585                	addiw	a1,a1,1
    80001e32:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e36:	4719                	li	a4,6
    80001e38:	6685                	lui	a3,0x1
    80001e3a:	40b905b3          	sub	a1,s2,a1
    80001e3e:	854e                	mv	a0,s3
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	2dc080e7          	jalr	732(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e48:	58048493          	addi	s1,s1,1408
    80001e4c:	fd4495e3          	bne	s1,s4,80001e16 <proc_mapstacks+0x38>
  }
}
    80001e50:	70e2                	ld	ra,56(sp)
    80001e52:	7442                	ld	s0,48(sp)
    80001e54:	74a2                	ld	s1,40(sp)
    80001e56:	7902                	ld	s2,32(sp)
    80001e58:	69e2                	ld	s3,24(sp)
    80001e5a:	6a42                	ld	s4,16(sp)
    80001e5c:	6aa2                	ld	s5,8(sp)
    80001e5e:	6b02                	ld	s6,0(sp)
    80001e60:	6121                	addi	sp,sp,64
    80001e62:	8082                	ret
      panic("kalloc");
    80001e64:	00006517          	auipc	a0,0x6
    80001e68:	39450513          	addi	a0,a0,916 # 800081f8 <digits+0x1b8>
    80001e6c:	ffffe097          	auipc	ra,0xffffe
    80001e70:	6be080e7          	jalr	1726(ra) # 8000052a <panic>

0000000080001e74 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e74:	7139                	addi	sp,sp,-64
    80001e76:	fc06                	sd	ra,56(sp)
    80001e78:	f822                	sd	s0,48(sp)
    80001e7a:	f426                	sd	s1,40(sp)
    80001e7c:	f04a                	sd	s2,32(sp)
    80001e7e:	ec4e                	sd	s3,24(sp)
    80001e80:	e852                	sd	s4,16(sp)
    80001e82:	e456                	sd	s5,8(sp)
    80001e84:	e05a                	sd	s6,0(sp)
    80001e86:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001e88:	00006597          	auipc	a1,0x6
    80001e8c:	37858593          	addi	a1,a1,888 # 80008200 <digits+0x1c0>
    80001e90:	0000f517          	auipc	a0,0xf
    80001e94:	41050513          	addi	a0,a0,1040 # 800112a0 <pid_lock>
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	c9a080e7          	jalr	-870(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ea0:	00006597          	auipc	a1,0x6
    80001ea4:	36858593          	addi	a1,a1,872 # 80008208 <digits+0x1c8>
    80001ea8:	0000f517          	auipc	a0,0xf
    80001eac:	41050513          	addi	a0,a0,1040 # 800112b8 <wait_lock>
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	c82080e7          	jalr	-894(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb8:	00010497          	auipc	s1,0x10
    80001ebc:	81848493          	addi	s1,s1,-2024 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001ec0:	00006b17          	auipc	s6,0x6
    80001ec4:	358b0b13          	addi	s6,s6,856 # 80008218 <digits+0x1d8>
      p->kstack = KSTACK((int) (p - proc));
    80001ec8:	8aa6                	mv	s5,s1
    80001eca:	00006a17          	auipc	s4,0x6
    80001ece:	136a0a13          	addi	s4,s4,310 # 80008000 <etext>
    80001ed2:	04000937          	lui	s2,0x4000
    80001ed6:	197d                	addi	s2,s2,-1
    80001ed8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eda:	00025997          	auipc	s3,0x25
    80001ede:	7f698993          	addi	s3,s3,2038 # 800276d0 <tickslock>
      initlock(&p->lock, "proc");
    80001ee2:	85da                	mv	a1,s6
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	c4c080e7          	jalr	-948(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001eee:	415487b3          	sub	a5,s1,s5
    80001ef2:	879d                	srai	a5,a5,0x7
    80001ef4:	000a3703          	ld	a4,0(s4)
    80001ef8:	02e787b3          	mul	a5,a5,a4
    80001efc:	2785                	addiw	a5,a5,1
    80001efe:	00d7979b          	slliw	a5,a5,0xd
    80001f02:	40f907b3          	sub	a5,s2,a5
    80001f06:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	58048493          	addi	s1,s1,1408
    80001f0c:	fd349be3          	bne	s1,s3,80001ee2 <procinit+0x6e>
  }
}
    80001f10:	70e2                	ld	ra,56(sp)
    80001f12:	7442                	ld	s0,48(sp)
    80001f14:	74a2                	ld	s1,40(sp)
    80001f16:	7902                	ld	s2,32(sp)
    80001f18:	69e2                	ld	s3,24(sp)
    80001f1a:	6a42                	ld	s4,16(sp)
    80001f1c:	6aa2                	ld	s5,8(sp)
    80001f1e:	6b02                	ld	s6,0(sp)
    80001f20:	6121                	addi	sp,sp,64
    80001f22:	8082                	ret

0000000080001f24 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f24:	1141                	addi	sp,sp,-16
    80001f26:	e422                	sd	s0,8(sp)
    80001f28:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f2a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f2c:	2501                	sext.w	a0,a0
    80001f2e:	6422                	ld	s0,8(sp)
    80001f30:	0141                	addi	sp,sp,16
    80001f32:	8082                	ret

0000000080001f34 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001f34:	1141                	addi	sp,sp,-16
    80001f36:	e422                	sd	s0,8(sp)
    80001f38:	0800                	addi	s0,sp,16
    80001f3a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f3c:	2781                	sext.w	a5,a5
    80001f3e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001f40:	0000f517          	auipc	a0,0xf
    80001f44:	39050513          	addi	a0,a0,912 # 800112d0 <cpus>
    80001f48:	953e                	add	a0,a0,a5
    80001f4a:	6422                	ld	s0,8(sp)
    80001f4c:	0141                	addi	sp,sp,16
    80001f4e:	8082                	ret

0000000080001f50 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001f50:	1101                	addi	sp,sp,-32
    80001f52:	ec06                	sd	ra,24(sp)
    80001f54:	e822                	sd	s0,16(sp)
    80001f56:	e426                	sd	s1,8(sp)
    80001f58:	1000                	addi	s0,sp,32
  push_off();
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c1c080e7          	jalr	-996(ra) # 80000b76 <push_off>
    80001f62:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f64:	2781                	sext.w	a5,a5
    80001f66:	079e                	slli	a5,a5,0x7
    80001f68:	0000f717          	auipc	a4,0xf
    80001f6c:	33870713          	addi	a4,a4,824 # 800112a0 <pid_lock>
    80001f70:	97ba                	add	a5,a5,a4
    80001f72:	7b84                	ld	s1,48(a5)
  pop_off();
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	ca2080e7          	jalr	-862(ra) # 80000c16 <pop_off>
  return p;
}
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	60e2                	ld	ra,24(sp)
    80001f80:	6442                	ld	s0,16(sp)
    80001f82:	64a2                	ld	s1,8(sp)
    80001f84:	6105                	addi	sp,sp,32
    80001f86:	8082                	ret

0000000080001f88 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f88:	1141                	addi	sp,sp,-16
    80001f8a:	e406                	sd	ra,8(sp)
    80001f8c:	e022                	sd	s0,0(sp)
    80001f8e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	fc0080e7          	jalr	-64(ra) # 80001f50 <myproc>
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	cde080e7          	jalr	-802(ra) # 80000c76 <release>

  if (first) {
    80001fa0:	00007797          	auipc	a5,0x7
    80001fa4:	8d07a783          	lw	a5,-1840(a5) # 80008870 <first.1>
    80001fa8:	eb89                	bnez	a5,80001fba <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001faa:	00001097          	auipc	ra,0x1
    80001fae:	d32080e7          	jalr	-718(ra) # 80002cdc <usertrapret>
}
    80001fb2:	60a2                	ld	ra,8(sp)
    80001fb4:	6402                	ld	s0,0(sp)
    80001fb6:	0141                	addi	sp,sp,16
    80001fb8:	8082                	ret
    first = 0;
    80001fba:	00007797          	auipc	a5,0x7
    80001fbe:	8a07ab23          	sw	zero,-1866(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001fc2:	4505                	li	a0,1
    80001fc4:	00002097          	auipc	ra,0x2
    80001fc8:	a70080e7          	jalr	-1424(ra) # 80003a34 <fsinit>
    80001fcc:	bff9                	j	80001faa <forkret+0x22>

0000000080001fce <allocpid>:
allocpid() {
    80001fce:	1101                	addi	sp,sp,-32
    80001fd0:	ec06                	sd	ra,24(sp)
    80001fd2:	e822                	sd	s0,16(sp)
    80001fd4:	e426                	sd	s1,8(sp)
    80001fd6:	e04a                	sd	s2,0(sp)
    80001fd8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001fda:	0000f917          	auipc	s2,0xf
    80001fde:	2c690913          	addi	s2,s2,710 # 800112a0 <pid_lock>
    80001fe2:	854a                	mv	a0,s2
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	bde080e7          	jalr	-1058(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001fec:	00007797          	auipc	a5,0x7
    80001ff0:	88878793          	addi	a5,a5,-1912 # 80008874 <nextpid>
    80001ff4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ff6:	0014871b          	addiw	a4,s1,1
    80001ffa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ffc:	854a                	mv	a0,s2
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	c78080e7          	jalr	-904(ra) # 80000c76 <release>
}
    80002006:	8526                	mv	a0,s1
    80002008:	60e2                	ld	ra,24(sp)
    8000200a:	6442                	ld	s0,16(sp)
    8000200c:	64a2                	ld	s1,8(sp)
    8000200e:	6902                	ld	s2,0(sp)
    80002010:	6105                	addi	sp,sp,32
    80002012:	8082                	ret

0000000080002014 <proc_pagetable>:
{
    80002014:	1101                	addi	sp,sp,-32
    80002016:	ec06                	sd	ra,24(sp)
    80002018:	e822                	sd	s0,16(sp)
    8000201a:	e426                	sd	s1,8(sp)
    8000201c:	e04a                	sd	s2,0(sp)
    8000201e:	1000                	addi	s0,sp,32
    80002020:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	384080e7          	jalr	900(ra) # 800013a6 <uvmcreate>
    8000202a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000202c:	c121                	beqz	a0,8000206c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000202e:	4729                	li	a4,10
    80002030:	00005697          	auipc	a3,0x5
    80002034:	fd068693          	addi	a3,a3,-48 # 80007000 <_trampoline>
    80002038:	6605                	lui	a2,0x1
    8000203a:	040005b7          	lui	a1,0x4000
    8000203e:	15fd                	addi	a1,a1,-1
    80002040:	05b2                	slli	a1,a1,0xc
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	04c080e7          	jalr	76(ra) # 8000108e <mappages>
    8000204a:	02054863          	bltz	a0,8000207a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000204e:	4719                	li	a4,6
    80002050:	05893683          	ld	a3,88(s2)
    80002054:	6605                	lui	a2,0x1
    80002056:	020005b7          	lui	a1,0x2000
    8000205a:	15fd                	addi	a1,a1,-1
    8000205c:	05b6                	slli	a1,a1,0xd
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	02e080e7          	jalr	46(ra) # 8000108e <mappages>
    80002068:	02054163          	bltz	a0,8000208a <proc_pagetable+0x76>
}
    8000206c:	8526                	mv	a0,s1
    8000206e:	60e2                	ld	ra,24(sp)
    80002070:	6442                	ld	s0,16(sp)
    80002072:	64a2                	ld	s1,8(sp)
    80002074:	6902                	ld	s2,0(sp)
    80002076:	6105                	addi	sp,sp,32
    80002078:	8082                	ret
    uvmfree(pagetable, 0);
    8000207a:	4581                	li	a1,0
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	47a080e7          	jalr	1146(ra) # 800014f8 <uvmfree>
    return 0;
    80002086:	4481                	li	s1,0
    80002088:	b7d5                	j	8000206c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000208a:	4681                	li	a3,0
    8000208c:	4605                	li	a2,1
    8000208e:	040005b7          	lui	a1,0x4000
    80002092:	15fd                	addi	a1,a1,-1
    80002094:	05b2                	slli	a1,a1,0xc
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	1aa080e7          	jalr	426(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    800020a0:	4581                	li	a1,0
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	454080e7          	jalr	1108(ra) # 800014f8 <uvmfree>
    return 0;
    800020ac:	4481                	li	s1,0
    800020ae:	bf7d                	j	8000206c <proc_pagetable+0x58>

00000000800020b0 <proc_freepagetable>:
{
    800020b0:	1101                	addi	sp,sp,-32
    800020b2:	ec06                	sd	ra,24(sp)
    800020b4:	e822                	sd	s0,16(sp)
    800020b6:	e426                	sd	s1,8(sp)
    800020b8:	e04a                	sd	s2,0(sp)
    800020ba:	1000                	addi	s0,sp,32
    800020bc:	84aa                	mv	s1,a0
    800020be:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020c0:	4681                	li	a3,0
    800020c2:	4605                	li	a2,1
    800020c4:	040005b7          	lui	a1,0x4000
    800020c8:	15fd                	addi	a1,a1,-1
    800020ca:	05b2                	slli	a1,a1,0xc
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	176080e7          	jalr	374(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020d4:	4681                	li	a3,0
    800020d6:	4605                	li	a2,1
    800020d8:	020005b7          	lui	a1,0x2000
    800020dc:	15fd                	addi	a1,a1,-1
    800020de:	05b6                	slli	a1,a1,0xd
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	160080e7          	jalr	352(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    800020ea:	85ca                	mv	a1,s2
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	40a080e7          	jalr	1034(ra) # 800014f8 <uvmfree>
}
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	64a2                	ld	s1,8(sp)
    800020fc:	6902                	ld	s2,0(sp)
    800020fe:	6105                	addi	sp,sp,32
    80002100:	8082                	ret

0000000080002102 <freeproc>:
{
    80002102:	1101                	addi	sp,sp,-32
    80002104:	ec06                	sd	ra,24(sp)
    80002106:	e822                	sd	s0,16(sp)
    80002108:	e426                	sd	s1,8(sp)
    8000210a:	1000                	addi	s0,sp,32
    8000210c:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000210e:	6d28                	ld	a0,88(a0)
    80002110:	c509                	beqz	a0,8000211a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	8c4080e7          	jalr	-1852(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    8000211a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    8000211e:	68a8                	ld	a0,80(s1)
    80002120:	c511                	beqz	a0,8000212c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002122:	64ac                	ld	a1,72(s1)
    80002124:	00000097          	auipc	ra,0x0
    80002128:	f8c080e7          	jalr	-116(ra) # 800020b0 <proc_freepagetable>
  if(p->pid > 2){
    8000212c:	5898                	lw	a4,48(s1)
    8000212e:	4789                	li	a5,2
    80002130:	04e7d163          	bge	a5,a4,80002172 <freeproc+0x70>
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80002134:	17048713          	addi	a4,s1,368
    80002138:	37048793          	addi	a5,s1,880
    8000213c:	86be                	mv	a3,a5
      pg->state = 0;
    8000213e:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    80002142:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    80002146:	00073823          	sd	zero,16(a4)
      pg->creationOrder=0;
    8000214a:	00073c23          	sd	zero,24(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    8000214e:	02070713          	addi	a4,a4,32
    80002152:	fed716e3          	bne	a4,a3,8000213e <freeproc+0x3c>
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80002156:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    8000215a:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    8000215e:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    80002162:	0007b823          	sd	zero,16(a5)
      pg->creationOrder=0;
    80002166:	0007bc23          	sd	zero,24(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000216a:	02078793          	addi	a5,a5,32
    8000216e:	fee796e3          	bne	a5,a4,8000215a <freeproc+0x58>
  p->pagetable = 0;
    80002172:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002176:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000217a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000217e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002182:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002186:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000218a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000218e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002192:	0004ac23          	sw	zero,24(s1)
  p->num_pages_in_swapfile = 0;
    80002196:	5604aa23          	sw	zero,1396(s1)
  p->num_pages_in_psyc = 0;
    8000219a:	5604a823          	sw	zero,1392(s1)
  p->creationTimeGenerator=0;
    8000219e:	5604bc23          	sd	zero,1400(s1)
}
    800021a2:	60e2                	ld	ra,24(sp)
    800021a4:	6442                	ld	s0,16(sp)
    800021a6:	64a2                	ld	s1,8(sp)
    800021a8:	6105                	addi	sp,sp,32
    800021aa:	8082                	ret

00000000800021ac <allocproc>:
{
    800021ac:	1101                	addi	sp,sp,-32
    800021ae:	ec06                	sd	ra,24(sp)
    800021b0:	e822                	sd	s0,16(sp)
    800021b2:	e426                	sd	s1,8(sp)
    800021b4:	e04a                	sd	s2,0(sp)
    800021b6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800021b8:	0000f497          	auipc	s1,0xf
    800021bc:	51848493          	addi	s1,s1,1304 # 800116d0 <proc>
    800021c0:	00025917          	auipc	s2,0x25
    800021c4:	51090913          	addi	s2,s2,1296 # 800276d0 <tickslock>
    acquire(&p->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	9f8080e7          	jalr	-1544(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    800021d2:	4c9c                	lw	a5,24(s1)
    800021d4:	cf81                	beqz	a5,800021ec <allocproc+0x40>
      release(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	a9e080e7          	jalr	-1378(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021e0:	58048493          	addi	s1,s1,1408
    800021e4:	ff2492e3          	bne	s1,s2,800021c8 <allocproc+0x1c>
  return 0;
    800021e8:	4481                	li	s1,0
    800021ea:	a899                	j	80002240 <allocproc+0x94>
  p->pid = allocpid();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	de2080e7          	jalr	-542(ra) # 80001fce <allocpid>
    800021f4:	d888                	sw	a0,48(s1)
  p->state = USED;
    800021f6:	4785                	li	a5,1
    800021f8:	cc9c                	sw	a5,24(s1)
  p->creationTimeGenerator=0;
    800021fa:	5604bc23          	sd	zero,1400(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	8d4080e7          	jalr	-1836(ra) # 80000ad2 <kalloc>
    80002206:	892a                	mv	s2,a0
    80002208:	eca8                	sd	a0,88(s1)
    8000220a:	c131                	beqz	a0,8000224e <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    8000220c:	8526                	mv	a0,s1
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	e06080e7          	jalr	-506(ra) # 80002014 <proc_pagetable>
    80002216:	892a                	mv	s2,a0
    80002218:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    8000221a:	c531                	beqz	a0,80002266 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    8000221c:	07000613          	li	a2,112
    80002220:	4581                	li	a1,0
    80002222:	06048513          	addi	a0,s1,96
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a98080e7          	jalr	-1384(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    8000222e:	00000797          	auipc	a5,0x0
    80002232:	d5a78793          	addi	a5,a5,-678 # 80001f88 <forkret>
    80002236:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002238:	60bc                	ld	a5,64(s1)
    8000223a:	6705                	lui	a4,0x1
    8000223c:	97ba                	add	a5,a5,a4
    8000223e:	f4bc                	sd	a5,104(s1)
}
    80002240:	8526                	mv	a0,s1
    80002242:	60e2                	ld	ra,24(sp)
    80002244:	6442                	ld	s0,16(sp)
    80002246:	64a2                	ld	s1,8(sp)
    80002248:	6902                	ld	s2,0(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret
    freeproc(p);
    8000224e:	8526                	mv	a0,s1
    80002250:	00000097          	auipc	ra,0x0
    80002254:	eb2080e7          	jalr	-334(ra) # 80002102 <freeproc>
    release(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a1c080e7          	jalr	-1508(ra) # 80000c76 <release>
    return 0;
    80002262:	84ca                	mv	s1,s2
    80002264:	bff1                	j	80002240 <allocproc+0x94>
    freeproc(p);
    80002266:	8526                	mv	a0,s1
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	e9a080e7          	jalr	-358(ra) # 80002102 <freeproc>
    release(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a04080e7          	jalr	-1532(ra) # 80000c76 <release>
    return 0;
    8000227a:	84ca                	mv	s1,s2
    8000227c:	b7d1                	j	80002240 <allocproc+0x94>

000000008000227e <userinit>:
{
    8000227e:	1101                	addi	sp,sp,-32
    80002280:	ec06                	sd	ra,24(sp)
    80002282:	e822                	sd	s0,16(sp)
    80002284:	e426                	sd	s1,8(sp)
    80002286:	1000                	addi	s0,sp,32
  p = allocproc();
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	f24080e7          	jalr	-220(ra) # 800021ac <allocproc>
    80002290:	84aa                	mv	s1,a0
  initproc = p;
    80002292:	00007797          	auipc	a5,0x7
    80002296:	d8a7bb23          	sd	a0,-618(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000229a:	03400613          	li	a2,52
    8000229e:	00006597          	auipc	a1,0x6
    800022a2:	5e258593          	addi	a1,a1,1506 # 80008880 <initcode>
    800022a6:	6928                	ld	a0,80(a0)
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	12c080e7          	jalr	300(ra) # 800013d4 <uvminit>
  p->sz = PGSIZE;
    800022b0:	6785                	lui	a5,0x1
    800022b2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800022b4:	6cb8                	ld	a4,88(s1)
    800022b6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800022ba:	6cb8                	ld	a4,88(s1)
    800022bc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800022be:	4641                	li	a2,16
    800022c0:	00006597          	auipc	a1,0x6
    800022c4:	f6058593          	addi	a1,a1,-160 # 80008220 <digits+0x1e0>
    800022c8:	15848513          	addi	a0,s1,344
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	b44080e7          	jalr	-1212(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    800022d4:	00006517          	auipc	a0,0x6
    800022d8:	f5c50513          	addi	a0,a0,-164 # 80008230 <digits+0x1f0>
    800022dc:	00002097          	auipc	ra,0x2
    800022e0:	186080e7          	jalr	390(ra) # 80004462 <namei>
    800022e4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800022e8:	478d                	li	a5,3
    800022ea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800022f6:	60e2                	ld	ra,24(sp)
    800022f8:	6442                	ld	s0,16(sp)
    800022fa:	64a2                	ld	s1,8(sp)
    800022fc:	6105                	addi	sp,sp,32
    800022fe:	8082                	ret

0000000080002300 <growproc>:
{
    80002300:	1101                	addi	sp,sp,-32
    80002302:	ec06                	sd	ra,24(sp)
    80002304:	e822                	sd	s0,16(sp)
    80002306:	e426                	sd	s1,8(sp)
    80002308:	e04a                	sd	s2,0(sp)
    8000230a:	1000                	addi	s0,sp,32
    8000230c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	c42080e7          	jalr	-958(ra) # 80001f50 <myproc>
    80002316:	892a                	mv	s2,a0
  sz = p->sz;
    80002318:	652c                	ld	a1,72(a0)
    8000231a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000231e:	00904f63          	bgtz	s1,8000233c <growproc+0x3c>
  } else if(n < 0){
    80002322:	0204cc63          	bltz	s1,8000235a <growproc+0x5a>
  p->sz = sz;
    80002326:	1602                	slli	a2,a2,0x20
    80002328:	9201                	srli	a2,a2,0x20
    8000232a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000232e:	4501                	li	a0,0
}
    80002330:	60e2                	ld	ra,24(sp)
    80002332:	6442                	ld	s0,16(sp)
    80002334:	64a2                	ld	s1,8(sp)
    80002336:	6902                	ld	s2,0(sp)
    80002338:	6105                	addi	sp,sp,32
    8000233a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000233c:	9e25                	addw	a2,a2,s1
    8000233e:	1602                	slli	a2,a2,0x20
    80002340:	9201                	srli	a2,a2,0x20
    80002342:	1582                	slli	a1,a1,0x20
    80002344:	9181                	srli	a1,a1,0x20
    80002346:	6928                	ld	a0,80(a0)
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	894080e7          	jalr	-1900(ra) # 80001bdc <uvmalloc>
    80002350:	0005061b          	sext.w	a2,a0
    80002354:	fa69                	bnez	a2,80002326 <growproc+0x26>
      return -1;
    80002356:	557d                	li	a0,-1
    80002358:	bfe1                	j	80002330 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000235a:	9e25                	addw	a2,a2,s1
    8000235c:	1602                	slli	a2,a2,0x20
    8000235e:	9201                	srli	a2,a2,0x20
    80002360:	1582                	slli	a1,a1,0x20
    80002362:	9181                	srli	a1,a1,0x20
    80002364:	6928                	ld	a0,80(a0)
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	0e0080e7          	jalr	224(ra) # 80001446 <uvmdealloc>
    8000236e:	0005061b          	sext.w	a2,a0
    80002372:	bf55                	j	80002326 <growproc+0x26>

0000000080002374 <fork>:
{
    80002374:	715d                	addi	sp,sp,-80
    80002376:	e486                	sd	ra,72(sp)
    80002378:	e0a2                	sd	s0,64(sp)
    8000237a:	fc26                	sd	s1,56(sp)
    8000237c:	f84a                	sd	s2,48(sp)
    8000237e:	f44e                	sd	s3,40(sp)
    80002380:	f052                	sd	s4,32(sp)
    80002382:	ec56                	sd	s5,24(sp)
    80002384:	e85a                	sd	s6,16(sp)
    80002386:	e45e                	sd	s7,8(sp)
    80002388:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	bc6080e7          	jalr	-1082(ra) # 80001f50 <myproc>
    80002392:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    80002394:	00000097          	auipc	ra,0x0
    80002398:	e18080e7          	jalr	-488(ra) # 800021ac <allocproc>
    8000239c:	1c050563          	beqz	a0,80002566 <fork+0x1f2>
    800023a0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800023a2:	048a3603          	ld	a2,72(s4)
    800023a6:	692c                	ld	a1,80(a0)
    800023a8:	050a3503          	ld	a0,80(s4)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	184080e7          	jalr	388(ra) # 80001530 <uvmcopy>
    800023b4:	04054863          	bltz	a0,80002404 <fork+0x90>
  np->sz = p->sz;
    800023b8:	048a3783          	ld	a5,72(s4)
    800023bc:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800023c0:	058a3683          	ld	a3,88(s4)
    800023c4:	87b6                	mv	a5,a3
    800023c6:	0589b703          	ld	a4,88(s3)
    800023ca:	12068693          	addi	a3,a3,288
    800023ce:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800023d2:	6788                	ld	a0,8(a5)
    800023d4:	6b8c                	ld	a1,16(a5)
    800023d6:	6f90                	ld	a2,24(a5)
    800023d8:	01073023          	sd	a6,0(a4)
    800023dc:	e708                	sd	a0,8(a4)
    800023de:	eb0c                	sd	a1,16(a4)
    800023e0:	ef10                	sd	a2,24(a4)
    800023e2:	02078793          	addi	a5,a5,32
    800023e6:	02070713          	addi	a4,a4,32
    800023ea:	fed792e3          	bne	a5,a3,800023ce <fork+0x5a>
  np->trapframe->a0 = 0;
    800023ee:	0589b783          	ld	a5,88(s3)
    800023f2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800023f6:	0d0a0493          	addi	s1,s4,208
    800023fa:	0d098913          	addi	s2,s3,208
    800023fe:	150a0a93          	addi	s5,s4,336
    80002402:	a00d                	j	80002424 <fork+0xb0>
    freeproc(np);
    80002404:	854e                	mv	a0,s3
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	cfc080e7          	jalr	-772(ra) # 80002102 <freeproc>
    release(&np->lock);
    8000240e:	854e                	mv	a0,s3
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	866080e7          	jalr	-1946(ra) # 80000c76 <release>
    return -1;
    80002418:	5afd                	li	s5,-1
    8000241a:	a225                	j	80002542 <fork+0x1ce>
  for(i = 0; i < NOFILE; i++)
    8000241c:	04a1                	addi	s1,s1,8
    8000241e:	0921                	addi	s2,s2,8
    80002420:	01548b63          	beq	s1,s5,80002436 <fork+0xc2>
    if(p->ofile[i])
    80002424:	6088                	ld	a0,0(s1)
    80002426:	d97d                	beqz	a0,8000241c <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80002428:	00003097          	auipc	ra,0x3
    8000242c:	9e6080e7          	jalr	-1562(ra) # 80004e0e <filedup>
    80002430:	00a93023          	sd	a0,0(s2)
    80002434:	b7e5                	j	8000241c <fork+0xa8>
  np->cwd = idup(p->cwd);
    80002436:	150a3503          	ld	a0,336(s4)
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	834080e7          	jalr	-1996(ra) # 80003c6e <idup>
    80002442:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002446:	4641                	li	a2,16
    80002448:	158a0593          	addi	a1,s4,344
    8000244c:	15898513          	addi	a0,s3,344
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	9c0080e7          	jalr	-1600(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002458:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    8000245c:	854e                	mv	a0,s3
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	818080e7          	jalr	-2024(ra) # 80000c76 <release>
if(np->pid > 2){
    80002466:	0309a703          	lw	a4,48(s3)
    8000246a:	4789                	li	a5,2
    8000246c:	0ee7c763          	blt	a5,a4,8000255a <fork+0x1e6>
if(p->pid > 2){
    80002470:	030a2703          	lw	a4,48(s4)
    80002474:	4789                	li	a5,2
    80002476:	08e7d963          	bge	a5,a4,80002508 <fork+0x194>
    8000247a:	170a0793          	addi	a5,s4,368
    8000247e:	17098713          	addi	a4,s3,368
    80002482:	370a0613          	addi	a2,s4,880
    np->pages_in_memory[i].state = p->pages_in_memory[i].state;
    80002486:	4794                	lw	a3,8(a5)
    80002488:	c714                	sw	a3,8(a4)
    np->pages_in_memory[i].va = p->pages_in_memory[i].va;
    8000248a:	6394                	ld	a3,0(a5)
    8000248c:	e314                	sd	a3,0(a4)
    np->pages_in_memory[i].age = p->pages_in_memory[i].age;
    8000248e:	6b94                	ld	a3,16(a5)
    80002490:	eb14                	sd	a3,16(a4)
    np->pages_in_swapfile[i].state = p->pages_in_swapfile[i].state;
    80002492:	2087a683          	lw	a3,520(a5)
    80002496:	20d72423          	sw	a3,520(a4)
    np->pages_in_swapfile[i].va = p->pages_in_swapfile[i].va;
    8000249a:	2007b683          	ld	a3,512(a5)
    8000249e:	20d73023          	sd	a3,512(a4)
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    800024a2:	02078793          	addi	a5,a5,32
    800024a6:	02070713          	addi	a4,a4,32
    800024aa:	fcc79ee3          	bne	a5,a2,80002486 <fork+0x112>
  np->num_pages_in_psyc = p->num_pages_in_psyc;
    800024ae:	570a2783          	lw	a5,1392(s4)
    800024b2:	56f9a823          	sw	a5,1392(s3)
  np->num_pages_in_swapfile = p->num_pages_in_swapfile;
    800024b6:	574a2783          	lw	a5,1396(s4)
    800024ba:	56f9aa23          	sw	a5,1396(s3)
  np->creationTimeGenerator=p->creationTimeGenerator;
    800024be:	578a3783          	ld	a5,1400(s4)
    800024c2:	56f9bc23          	sd	a5,1400(s3)
  char* buffer = kalloc();
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	60c080e7          	jalr	1548(ra) # 80000ad2 <kalloc>
    800024ce:	892a                	mv	s2,a0
    800024d0:	4481                	li	s1,0
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    800024d2:	6b85                	lui	s7,0x1
    800024d4:	6b41                	lui	s6,0x10
    readFromSwapFile(p, buffer, i*PGSIZE, PGSIZE);
    800024d6:	6685                	lui	a3,0x1
    800024d8:	8626                	mv	a2,s1
    800024da:	85ca                	mv	a1,s2
    800024dc:	8552                	mv	a0,s4
    800024de:	00002097          	auipc	ra,0x2
    800024e2:	2ac080e7          	jalr	684(ra) # 8000478a <readFromSwapFile>
    writeToSwapFile(np, buffer, i*PGSIZE, PGSIZE);
    800024e6:	6685                	lui	a3,0x1
    800024e8:	8626                	mv	a2,s1
    800024ea:	85ca                	mv	a1,s2
    800024ec:	854e                	mv	a0,s3
    800024ee:	00002097          	auipc	ra,0x2
    800024f2:	278080e7          	jalr	632(ra) # 80004766 <writeToSwapFile>
  for(i = 0; i < MAX_PSYC_PAGES; i++){
    800024f6:	009b84bb          	addw	s1,s7,s1
    800024fa:	fd649ee3          	bne	s1,s6,800024d6 <fork+0x162>
  kfree(buffer);
    800024fe:	854a                	mv	a0,s2
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	4d6080e7          	jalr	1238(ra) # 800009d6 <kfree>
  acquire(&wait_lock);
    80002508:	0000f497          	auipc	s1,0xf
    8000250c:	db048493          	addi	s1,s1,-592 # 800112b8 <wait_lock>
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	6b0080e7          	jalr	1712(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000251a:	0349bc23          	sd	s4,56(s3)
  release(&wait_lock);
    8000251e:	8526                	mv	a0,s1
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	756080e7          	jalr	1878(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002528:	854e                	mv	a0,s3
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	698080e7          	jalr	1688(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002532:	478d                	li	a5,3
    80002534:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002538:	854e                	mv	a0,s3
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	73c080e7          	jalr	1852(ra) # 80000c76 <release>
}
    80002542:	8556                	mv	a0,s5
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6161                	addi	sp,sp,80
    80002558:	8082                	ret
  createSwapFile(np);
    8000255a:	854e                	mv	a0,s3
    8000255c:	00002097          	auipc	ra,0x2
    80002560:	15a080e7          	jalr	346(ra) # 800046b6 <createSwapFile>
    80002564:	b731                	j	80002470 <fork+0xfc>
    return -1;
    80002566:	5afd                	li	s5,-1
    80002568:	bfe9                	j	80002542 <fork+0x1ce>

000000008000256a <scheduler>:
{
    8000256a:	7139                	addi	sp,sp,-64
    8000256c:	fc06                	sd	ra,56(sp)
    8000256e:	f822                	sd	s0,48(sp)
    80002570:	f426                	sd	s1,40(sp)
    80002572:	f04a                	sd	s2,32(sp)
    80002574:	ec4e                	sd	s3,24(sp)
    80002576:	e852                	sd	s4,16(sp)
    80002578:	e456                	sd	s5,8(sp)
    8000257a:	e05a                	sd	s6,0(sp)
    8000257c:	0080                	addi	s0,sp,64
    8000257e:	8792                	mv	a5,tp
  int id = r_tp();
    80002580:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002582:	00779a93          	slli	s5,a5,0x7
    80002586:	0000f717          	auipc	a4,0xf
    8000258a:	d1a70713          	addi	a4,a4,-742 # 800112a0 <pid_lock>
    8000258e:	9756                	add	a4,a4,s5
    80002590:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002594:	0000f717          	auipc	a4,0xf
    80002598:	d4470713          	addi	a4,a4,-700 # 800112d8 <cpus+0x8>
    8000259c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000259e:	498d                	li	s3,3
        p->state = RUNNING;
    800025a0:	4b11                	li	s6,4
        c->proc = p;
    800025a2:	079e                	slli	a5,a5,0x7
    800025a4:	0000fa17          	auipc	s4,0xf
    800025a8:	cfca0a13          	addi	s4,s4,-772 # 800112a0 <pid_lock>
    800025ac:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800025ae:	00025917          	auipc	s2,0x25
    800025b2:	12290913          	addi	s2,s2,290 # 800276d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025ba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025be:	10079073          	csrw	sstatus,a5
    800025c2:	0000f497          	auipc	s1,0xf
    800025c6:	10e48493          	addi	s1,s1,270 # 800116d0 <proc>
    800025ca:	a811                	j	800025de <scheduler+0x74>
      release(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6a8080e7          	jalr	1704(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800025d6:	58048493          	addi	s1,s1,1408
    800025da:	fd248ee3          	beq	s1,s2,800025b6 <scheduler+0x4c>
      acquire(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	5e2080e7          	jalr	1506(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800025e8:	4c9c                	lw	a5,24(s1)
    800025ea:	ff3791e3          	bne	a5,s3,800025cc <scheduler+0x62>
        p->state = RUNNING;
    800025ee:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800025f2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800025f6:	06048593          	addi	a1,s1,96
    800025fa:	8556                	mv	a0,s5
    800025fc:	00000097          	auipc	ra,0x0
    80002600:	636080e7          	jalr	1590(ra) # 80002c32 <swtch>
        c->proc = 0;
    80002604:	020a3823          	sd	zero,48(s4)
    80002608:	b7d1                	j	800025cc <scheduler+0x62>

000000008000260a <sched>:
{
    8000260a:	7179                	addi	sp,sp,-48
    8000260c:	f406                	sd	ra,40(sp)
    8000260e:	f022                	sd	s0,32(sp)
    80002610:	ec26                	sd	s1,24(sp)
    80002612:	e84a                	sd	s2,16(sp)
    80002614:	e44e                	sd	s3,8(sp)
    80002616:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002618:	00000097          	auipc	ra,0x0
    8000261c:	938080e7          	jalr	-1736(ra) # 80001f50 <myproc>
    80002620:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	526080e7          	jalr	1318(ra) # 80000b48 <holding>
    8000262a:	c93d                	beqz	a0,800026a0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000262c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000262e:	2781                	sext.w	a5,a5
    80002630:	079e                	slli	a5,a5,0x7
    80002632:	0000f717          	auipc	a4,0xf
    80002636:	c6e70713          	addi	a4,a4,-914 # 800112a0 <pid_lock>
    8000263a:	97ba                	add	a5,a5,a4
    8000263c:	0a87a703          	lw	a4,168(a5)
    80002640:	4785                	li	a5,1
    80002642:	06f71763          	bne	a4,a5,800026b0 <sched+0xa6>
  if(p->state == RUNNING)
    80002646:	4c98                	lw	a4,24(s1)
    80002648:	4791                	li	a5,4
    8000264a:	06f70b63          	beq	a4,a5,800026c0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002652:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002654:	efb5                	bnez	a5,800026d0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002656:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002658:	0000f917          	auipc	s2,0xf
    8000265c:	c4890913          	addi	s2,s2,-952 # 800112a0 <pid_lock>
    80002660:	2781                	sext.w	a5,a5
    80002662:	079e                	slli	a5,a5,0x7
    80002664:	97ca                	add	a5,a5,s2
    80002666:	0ac7a983          	lw	s3,172(a5)
    8000266a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000266c:	2781                	sext.w	a5,a5
    8000266e:	079e                	slli	a5,a5,0x7
    80002670:	0000f597          	auipc	a1,0xf
    80002674:	c6858593          	addi	a1,a1,-920 # 800112d8 <cpus+0x8>
    80002678:	95be                	add	a1,a1,a5
    8000267a:	06048513          	addi	a0,s1,96
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	5b4080e7          	jalr	1460(ra) # 80002c32 <swtch>
    80002686:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002688:	2781                	sext.w	a5,a5
    8000268a:	079e                	slli	a5,a5,0x7
    8000268c:	97ca                	add	a5,a5,s2
    8000268e:	0b37a623          	sw	s3,172(a5)
}
    80002692:	70a2                	ld	ra,40(sp)
    80002694:	7402                	ld	s0,32(sp)
    80002696:	64e2                	ld	s1,24(sp)
    80002698:	6942                	ld	s2,16(sp)
    8000269a:	69a2                	ld	s3,8(sp)
    8000269c:	6145                	addi	sp,sp,48
    8000269e:	8082                	ret
    panic("sched p->lock");
    800026a0:	00006517          	auipc	a0,0x6
    800026a4:	b9850513          	addi	a0,a0,-1128 # 80008238 <digits+0x1f8>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	e82080e7          	jalr	-382(ra) # 8000052a <panic>
    panic("sched locks");
    800026b0:	00006517          	auipc	a0,0x6
    800026b4:	b9850513          	addi	a0,a0,-1128 # 80008248 <digits+0x208>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	e72080e7          	jalr	-398(ra) # 8000052a <panic>
    panic("sched running");
    800026c0:	00006517          	auipc	a0,0x6
    800026c4:	b9850513          	addi	a0,a0,-1128 # 80008258 <digits+0x218>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	e62080e7          	jalr	-414(ra) # 8000052a <panic>
    panic("sched interruptible");
    800026d0:	00006517          	auipc	a0,0x6
    800026d4:	b9850513          	addi	a0,a0,-1128 # 80008268 <digits+0x228>
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	e52080e7          	jalr	-430(ra) # 8000052a <panic>

00000000800026e0 <yield>:
{
    800026e0:	1101                	addi	sp,sp,-32
    800026e2:	ec06                	sd	ra,24(sp)
    800026e4:	e822                	sd	s0,16(sp)
    800026e6:	e426                	sd	s1,8(sp)
    800026e8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	866080e7          	jalr	-1946(ra) # 80001f50 <myproc>
    800026f2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4ce080e7          	jalr	1230(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800026fc:	478d                	li	a5,3
    800026fe:	cc9c                	sw	a5,24(s1)
  sched();
    80002700:	00000097          	auipc	ra,0x0
    80002704:	f0a080e7          	jalr	-246(ra) # 8000260a <sched>
  release(&p->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	56c080e7          	jalr	1388(ra) # 80000c76 <release>
}
    80002712:	60e2                	ld	ra,24(sp)
    80002714:	6442                	ld	s0,16(sp)
    80002716:	64a2                	ld	s1,8(sp)
    80002718:	6105                	addi	sp,sp,32
    8000271a:	8082                	ret

000000008000271c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000271c:	7179                	addi	sp,sp,-48
    8000271e:	f406                	sd	ra,40(sp)
    80002720:	f022                	sd	s0,32(sp)
    80002722:	ec26                	sd	s1,24(sp)
    80002724:	e84a                	sd	s2,16(sp)
    80002726:	e44e                	sd	s3,8(sp)
    80002728:	1800                	addi	s0,sp,48
    8000272a:	89aa                	mv	s3,a0
    8000272c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000272e:	00000097          	auipc	ra,0x0
    80002732:	822080e7          	jalr	-2014(ra) # 80001f50 <myproc>
    80002736:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	48a080e7          	jalr	1162(ra) # 80000bc2 <acquire>
  release(lk);
    80002740:	854a                	mv	a0,s2
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	534080e7          	jalr	1332(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    8000274a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000274e:	4789                	li	a5,2
    80002750:	cc9c                	sw	a5,24(s1)

  sched();
    80002752:	00000097          	auipc	ra,0x0
    80002756:	eb8080e7          	jalr	-328(ra) # 8000260a <sched>

  // Tidy up.
  p->chan = 0;
    8000275a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	516080e7          	jalr	1302(ra) # 80000c76 <release>
  acquire(lk);
    80002768:	854a                	mv	a0,s2
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	458080e7          	jalr	1112(ra) # 80000bc2 <acquire>
}
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6145                	addi	sp,sp,48
    8000277e:	8082                	ret

0000000080002780 <wait>:
{
    80002780:	715d                	addi	sp,sp,-80
    80002782:	e486                	sd	ra,72(sp)
    80002784:	e0a2                	sd	s0,64(sp)
    80002786:	fc26                	sd	s1,56(sp)
    80002788:	f84a                	sd	s2,48(sp)
    8000278a:	f44e                	sd	s3,40(sp)
    8000278c:	f052                	sd	s4,32(sp)
    8000278e:	ec56                	sd	s5,24(sp)
    80002790:	e85a                	sd	s6,16(sp)
    80002792:	e45e                	sd	s7,8(sp)
    80002794:	e062                	sd	s8,0(sp)
    80002796:	0880                	addi	s0,sp,80
    80002798:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	7b6080e7          	jalr	1974(ra) # 80001f50 <myproc>
    800027a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027a4:	0000f517          	auipc	a0,0xf
    800027a8:	b1450513          	addi	a0,a0,-1260 # 800112b8 <wait_lock>
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	416080e7          	jalr	1046(ra) # 80000bc2 <acquire>
    havekids = 0;
    800027b4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027b6:	4a15                	li	s4,5
        havekids = 1;
    800027b8:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800027ba:	00025997          	auipc	s3,0x25
    800027be:	f1698993          	addi	s3,s3,-234 # 800276d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027c2:	0000fc17          	auipc	s8,0xf
    800027c6:	af6c0c13          	addi	s8,s8,-1290 # 800112b8 <wait_lock>
    havekids = 0;
    800027ca:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	0000f497          	auipc	s1,0xf
    800027d0:	f0448493          	addi	s1,s1,-252 # 800116d0 <proc>
    800027d4:	a0bd                	j	80002842 <wait+0xc2>
          pid = np->pid;
    800027d6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027da:	000b0e63          	beqz	s6,800027f6 <wait+0x76>
    800027de:	4691                	li	a3,4
    800027e0:	02c48613          	addi	a2,s1,44
    800027e4:	85da                	mv	a1,s6
    800027e6:	05093503          	ld	a0,80(s2)
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	e7e080e7          	jalr	-386(ra) # 80001668 <copyout>
    800027f2:	02054563          	bltz	a0,8000281c <wait+0x9c>
          freeproc(np);
    800027f6:	8526                	mv	a0,s1
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	90a080e7          	jalr	-1782(ra) # 80002102 <freeproc>
          release(&np->lock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	474080e7          	jalr	1140(ra) # 80000c76 <release>
          release(&wait_lock);
    8000280a:	0000f517          	auipc	a0,0xf
    8000280e:	aae50513          	addi	a0,a0,-1362 # 800112b8 <wait_lock>
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	464080e7          	jalr	1124(ra) # 80000c76 <release>
          return pid;
    8000281a:	a09d                	j	80002880 <wait+0x100>
            release(&np->lock);
    8000281c:	8526                	mv	a0,s1
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	458080e7          	jalr	1112(ra) # 80000c76 <release>
            release(&wait_lock);
    80002826:	0000f517          	auipc	a0,0xf
    8000282a:	a9250513          	addi	a0,a0,-1390 # 800112b8 <wait_lock>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	448080e7          	jalr	1096(ra) # 80000c76 <release>
            return -1;
    80002836:	59fd                	li	s3,-1
    80002838:	a0a1                	j	80002880 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000283a:	58048493          	addi	s1,s1,1408
    8000283e:	03348463          	beq	s1,s3,80002866 <wait+0xe6>
      if(np->parent == p){
    80002842:	7c9c                	ld	a5,56(s1)
    80002844:	ff279be3          	bne	a5,s2,8000283a <wait+0xba>
        acquire(&np->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	378080e7          	jalr	888(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002852:	4c9c                	lw	a5,24(s1)
    80002854:	f94781e3          	beq	a5,s4,800027d6 <wait+0x56>
        release(&np->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	41c080e7          	jalr	1052(ra) # 80000c76 <release>
        havekids = 1;
    80002862:	8756                	mv	a4,s5
    80002864:	bfd9                	j	8000283a <wait+0xba>
    if(!havekids || p->killed){
    80002866:	c701                	beqz	a4,8000286e <wait+0xee>
    80002868:	02892783          	lw	a5,40(s2)
    8000286c:	c79d                	beqz	a5,8000289a <wait+0x11a>
      release(&wait_lock);
    8000286e:	0000f517          	auipc	a0,0xf
    80002872:	a4a50513          	addi	a0,a0,-1462 # 800112b8 <wait_lock>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	400080e7          	jalr	1024(ra) # 80000c76 <release>
      return -1;
    8000287e:	59fd                	li	s3,-1
}
    80002880:	854e                	mv	a0,s3
    80002882:	60a6                	ld	ra,72(sp)
    80002884:	6406                	ld	s0,64(sp)
    80002886:	74e2                	ld	s1,56(sp)
    80002888:	7942                	ld	s2,48(sp)
    8000288a:	79a2                	ld	s3,40(sp)
    8000288c:	7a02                	ld	s4,32(sp)
    8000288e:	6ae2                	ld	s5,24(sp)
    80002890:	6b42                	ld	s6,16(sp)
    80002892:	6ba2                	ld	s7,8(sp)
    80002894:	6c02                	ld	s8,0(sp)
    80002896:	6161                	addi	sp,sp,80
    80002898:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000289a:	85e2                	mv	a1,s8
    8000289c:	854a                	mv	a0,s2
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	e7e080e7          	jalr	-386(ra) # 8000271c <sleep>
    havekids = 0;
    800028a6:	b715                	j	800027ca <wait+0x4a>

00000000800028a8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028a8:	7139                	addi	sp,sp,-64
    800028aa:	fc06                	sd	ra,56(sp)
    800028ac:	f822                	sd	s0,48(sp)
    800028ae:	f426                	sd	s1,40(sp)
    800028b0:	f04a                	sd	s2,32(sp)
    800028b2:	ec4e                	sd	s3,24(sp)
    800028b4:	e852                	sd	s4,16(sp)
    800028b6:	e456                	sd	s5,8(sp)
    800028b8:	0080                	addi	s0,sp,64
    800028ba:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800028bc:	0000f497          	auipc	s1,0xf
    800028c0:	e1448493          	addi	s1,s1,-492 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800028c4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800028c6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800028c8:	00025917          	auipc	s2,0x25
    800028cc:	e0890913          	addi	s2,s2,-504 # 800276d0 <tickslock>
    800028d0:	a811                	j	800028e4 <wakeup+0x3c>
      }
      release(&p->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	3a2080e7          	jalr	930(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028dc:	58048493          	addi	s1,s1,1408
    800028e0:	03248663          	beq	s1,s2,8000290c <wakeup+0x64>
    if(p != myproc()){
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	66c080e7          	jalr	1644(ra) # 80001f50 <myproc>
    800028ec:	fea488e3          	beq	s1,a0,800028dc <wakeup+0x34>
      acquire(&p->lock);
    800028f0:	8526                	mv	a0,s1
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	2d0080e7          	jalr	720(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800028fa:	4c9c                	lw	a5,24(s1)
    800028fc:	fd379be3          	bne	a5,s3,800028d2 <wakeup+0x2a>
    80002900:	709c                	ld	a5,32(s1)
    80002902:	fd4798e3          	bne	a5,s4,800028d2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002906:	0154ac23          	sw	s5,24(s1)
    8000290a:	b7e1                	j	800028d2 <wakeup+0x2a>
    }
  }
}
    8000290c:	70e2                	ld	ra,56(sp)
    8000290e:	7442                	ld	s0,48(sp)
    80002910:	74a2                	ld	s1,40(sp)
    80002912:	7902                	ld	s2,32(sp)
    80002914:	69e2                	ld	s3,24(sp)
    80002916:	6a42                	ld	s4,16(sp)
    80002918:	6aa2                	ld	s5,8(sp)
    8000291a:	6121                	addi	sp,sp,64
    8000291c:	8082                	ret

000000008000291e <reparent>:
{
    8000291e:	7179                	addi	sp,sp,-48
    80002920:	f406                	sd	ra,40(sp)
    80002922:	f022                	sd	s0,32(sp)
    80002924:	ec26                	sd	s1,24(sp)
    80002926:	e84a                	sd	s2,16(sp)
    80002928:	e44e                	sd	s3,8(sp)
    8000292a:	e052                	sd	s4,0(sp)
    8000292c:	1800                	addi	s0,sp,48
    8000292e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002930:	0000f497          	auipc	s1,0xf
    80002934:	da048493          	addi	s1,s1,-608 # 800116d0 <proc>
      pp->parent = initproc;
    80002938:	00006a17          	auipc	s4,0x6
    8000293c:	6f0a0a13          	addi	s4,s4,1776 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002940:	00025997          	auipc	s3,0x25
    80002944:	d9098993          	addi	s3,s3,-624 # 800276d0 <tickslock>
    80002948:	a029                	j	80002952 <reparent+0x34>
    8000294a:	58048493          	addi	s1,s1,1408
    8000294e:	01348d63          	beq	s1,s3,80002968 <reparent+0x4a>
    if(pp->parent == p){
    80002952:	7c9c                	ld	a5,56(s1)
    80002954:	ff279be3          	bne	a5,s2,8000294a <reparent+0x2c>
      pp->parent = initproc;
    80002958:	000a3503          	ld	a0,0(s4)
    8000295c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	f4a080e7          	jalr	-182(ra) # 800028a8 <wakeup>
    80002966:	b7d5                	j	8000294a <reparent+0x2c>
}
    80002968:	70a2                	ld	ra,40(sp)
    8000296a:	7402                	ld	s0,32(sp)
    8000296c:	64e2                	ld	s1,24(sp)
    8000296e:	6942                	ld	s2,16(sp)
    80002970:	69a2                	ld	s3,8(sp)
    80002972:	6a02                	ld	s4,0(sp)
    80002974:	6145                	addi	sp,sp,48
    80002976:	8082                	ret

0000000080002978 <exit>:
{
    80002978:	7179                	addi	sp,sp,-48
    8000297a:	f406                	sd	ra,40(sp)
    8000297c:	f022                	sd	s0,32(sp)
    8000297e:	ec26                	sd	s1,24(sp)
    80002980:	e84a                	sd	s2,16(sp)
    80002982:	e44e                	sd	s3,8(sp)
    80002984:	e052                	sd	s4,0(sp)
    80002986:	1800                	addi	s0,sp,48
    80002988:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	5c6080e7          	jalr	1478(ra) # 80001f50 <myproc>
    80002992:	89aa                	mv	s3,a0
  if(p == initproc)
    80002994:	00006797          	auipc	a5,0x6
    80002998:	6947b783          	ld	a5,1684(a5) # 80009028 <initproc>
    8000299c:	0d050493          	addi	s1,a0,208
    800029a0:	15050913          	addi	s2,a0,336
    800029a4:	02a79363          	bne	a5,a0,800029ca <exit+0x52>
    panic("init exiting");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	8d850513          	addi	a0,a0,-1832 # 80008280 <digits+0x240>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b7a080e7          	jalr	-1158(ra) # 8000052a <panic>
      fileclose(f);
    800029b8:	00002097          	auipc	ra,0x2
    800029bc:	4a8080e7          	jalr	1192(ra) # 80004e60 <fileclose>
      p->ofile[fd] = 0;
    800029c0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029c4:	04a1                	addi	s1,s1,8
    800029c6:	01248563          	beq	s1,s2,800029d0 <exit+0x58>
    if(p->ofile[fd]){
    800029ca:	6088                	ld	a0,0(s1)
    800029cc:	f575                	bnez	a0,800029b8 <exit+0x40>
    800029ce:	bfdd                	j	800029c4 <exit+0x4c>
  if(p->pid > 2) removeSwapFile(p);
    800029d0:	0309a703          	lw	a4,48(s3)
    800029d4:	4789                	li	a5,2
    800029d6:	08e7c163          	blt	a5,a4,80002a58 <exit+0xe0>
  begin_op();
    800029da:	00002097          	auipc	ra,0x2
    800029de:	fba080e7          	jalr	-70(ra) # 80004994 <begin_op>
  iput(p->cwd);
    800029e2:	1509b503          	ld	a0,336(s3)
    800029e6:	00001097          	auipc	ra,0x1
    800029ea:	480080e7          	jalr	1152(ra) # 80003e66 <iput>
  end_op();
    800029ee:	00002097          	auipc	ra,0x2
    800029f2:	026080e7          	jalr	38(ra) # 80004a14 <end_op>
  p->cwd = 0;
    800029f6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800029fa:	0000f497          	auipc	s1,0xf
    800029fe:	8be48493          	addi	s1,s1,-1858 # 800112b8 <wait_lock>
    80002a02:	8526                	mv	a0,s1
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	1be080e7          	jalr	446(ra) # 80000bc2 <acquire>
  reparent(p);
    80002a0c:	854e                	mv	a0,s3
    80002a0e:	00000097          	auipc	ra,0x0
    80002a12:	f10080e7          	jalr	-240(ra) # 8000291e <reparent>
  wakeup(p->parent);
    80002a16:	0389b503          	ld	a0,56(s3)
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	e8e080e7          	jalr	-370(ra) # 800028a8 <wakeup>
  acquire(&p->lock);
    80002a22:	854e                	mv	a0,s3
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	19e080e7          	jalr	414(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002a2c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a30:	4795                	li	a5,5
    80002a32:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	23e080e7          	jalr	574(ra) # 80000c76 <release>
  sched();
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	bca080e7          	jalr	-1078(ra) # 8000260a <sched>
  panic("zombie exit");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	84850513          	addi	a0,a0,-1976 # 80008290 <digits+0x250>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	ada080e7          	jalr	-1318(ra) # 8000052a <panic>
  if(p->pid > 2) removeSwapFile(p);
    80002a58:	854e                	mv	a0,s3
    80002a5a:	00002097          	auipc	ra,0x2
    80002a5e:	ab4080e7          	jalr	-1356(ra) # 8000450e <removeSwapFile>
    80002a62:	bfa5                	j	800029da <exit+0x62>

0000000080002a64 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a64:	7179                	addi	sp,sp,-48
    80002a66:	f406                	sd	ra,40(sp)
    80002a68:	f022                	sd	s0,32(sp)
    80002a6a:	ec26                	sd	s1,24(sp)
    80002a6c:	e84a                	sd	s2,16(sp)
    80002a6e:	e44e                	sd	s3,8(sp)
    80002a70:	1800                	addi	s0,sp,48
    80002a72:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a74:	0000f497          	auipc	s1,0xf
    80002a78:	c5c48493          	addi	s1,s1,-932 # 800116d0 <proc>
    80002a7c:	00025997          	auipc	s3,0x25
    80002a80:	c5498993          	addi	s3,s3,-940 # 800276d0 <tickslock>
    acquire(&p->lock);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	13c080e7          	jalr	316(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002a8e:	589c                	lw	a5,48(s1)
    80002a90:	01278d63          	beq	a5,s2,80002aaa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a94:	8526                	mv	a0,s1
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	1e0080e7          	jalr	480(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a9e:	58048493          	addi	s1,s1,1408
    80002aa2:	ff3491e3          	bne	s1,s3,80002a84 <kill+0x20>
  }
  return -1;
    80002aa6:	557d                	li	a0,-1
    80002aa8:	a829                	j	80002ac2 <kill+0x5e>
      p->killed = 1;
    80002aaa:	4785                	li	a5,1
    80002aac:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002aae:	4c98                	lw	a4,24(s1)
    80002ab0:	4789                	li	a5,2
    80002ab2:	00f70f63          	beq	a4,a5,80002ad0 <kill+0x6c>
      release(&p->lock);
    80002ab6:	8526                	mv	a0,s1
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	1be080e7          	jalr	446(ra) # 80000c76 <release>
      return 0;
    80002ac0:	4501                	li	a0,0
}
    80002ac2:	70a2                	ld	ra,40(sp)
    80002ac4:	7402                	ld	s0,32(sp)
    80002ac6:	64e2                	ld	s1,24(sp)
    80002ac8:	6942                	ld	s2,16(sp)
    80002aca:	69a2                	ld	s3,8(sp)
    80002acc:	6145                	addi	sp,sp,48
    80002ace:	8082                	ret
        p->state = RUNNABLE;
    80002ad0:	478d                	li	a5,3
    80002ad2:	cc9c                	sw	a5,24(s1)
    80002ad4:	b7cd                	j	80002ab6 <kill+0x52>

0000000080002ad6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002ad6:	7179                	addi	sp,sp,-48
    80002ad8:	f406                	sd	ra,40(sp)
    80002ada:	f022                	sd	s0,32(sp)
    80002adc:	ec26                	sd	s1,24(sp)
    80002ade:	e84a                	sd	s2,16(sp)
    80002ae0:	e44e                	sd	s3,8(sp)
    80002ae2:	e052                	sd	s4,0(sp)
    80002ae4:	1800                	addi	s0,sp,48
    80002ae6:	84aa                	mv	s1,a0
    80002ae8:	892e                	mv	s2,a1
    80002aea:	89b2                	mv	s3,a2
    80002aec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	462080e7          	jalr	1122(ra) # 80001f50 <myproc>
  if(user_dst){
    80002af6:	c08d                	beqz	s1,80002b18 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002af8:	86d2                	mv	a3,s4
    80002afa:	864e                	mv	a2,s3
    80002afc:	85ca                	mv	a1,s2
    80002afe:	6928                	ld	a0,80(a0)
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	b68080e7          	jalr	-1176(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b08:	70a2                	ld	ra,40(sp)
    80002b0a:	7402                	ld	s0,32(sp)
    80002b0c:	64e2                	ld	s1,24(sp)
    80002b0e:	6942                	ld	s2,16(sp)
    80002b10:	69a2                	ld	s3,8(sp)
    80002b12:	6a02                	ld	s4,0(sp)
    80002b14:	6145                	addi	sp,sp,48
    80002b16:	8082                	ret
    memmove((char *)dst, src, len);
    80002b18:	000a061b          	sext.w	a2,s4
    80002b1c:	85ce                	mv	a1,s3
    80002b1e:	854a                	mv	a0,s2
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	1fa080e7          	jalr	506(ra) # 80000d1a <memmove>
    return 0;
    80002b28:	8526                	mv	a0,s1
    80002b2a:	bff9                	j	80002b08 <either_copyout+0x32>

0000000080002b2c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b2c:	7179                	addi	sp,sp,-48
    80002b2e:	f406                	sd	ra,40(sp)
    80002b30:	f022                	sd	s0,32(sp)
    80002b32:	ec26                	sd	s1,24(sp)
    80002b34:	e84a                	sd	s2,16(sp)
    80002b36:	e44e                	sd	s3,8(sp)
    80002b38:	e052                	sd	s4,0(sp)
    80002b3a:	1800                	addi	s0,sp,48
    80002b3c:	892a                	mv	s2,a0
    80002b3e:	84ae                	mv	s1,a1
    80002b40:	89b2                	mv	s3,a2
    80002b42:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	40c080e7          	jalr	1036(ra) # 80001f50 <myproc>
  if(user_src){
    80002b4c:	c08d                	beqz	s1,80002b6e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b4e:	86d2                	mv	a3,s4
    80002b50:	864e                	mv	a2,s3
    80002b52:	85ca                	mv	a1,s2
    80002b54:	6928                	ld	a0,80(a0)
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	b9e080e7          	jalr	-1122(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	69a2                	ld	s3,8(sp)
    80002b68:	6a02                	ld	s4,0(sp)
    80002b6a:	6145                	addi	sp,sp,48
    80002b6c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b6e:	000a061b          	sext.w	a2,s4
    80002b72:	85ce                	mv	a1,s3
    80002b74:	854a                	mv	a0,s2
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	1a4080e7          	jalr	420(ra) # 80000d1a <memmove>
    return 0;
    80002b7e:	8526                	mv	a0,s1
    80002b80:	bff9                	j	80002b5e <either_copyin+0x32>

0000000080002b82 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b82:	715d                	addi	sp,sp,-80
    80002b84:	e486                	sd	ra,72(sp)
    80002b86:	e0a2                	sd	s0,64(sp)
    80002b88:	fc26                	sd	s1,56(sp)
    80002b8a:	f84a                	sd	s2,48(sp)
    80002b8c:	f44e                	sd	s3,40(sp)
    80002b8e:	f052                	sd	s4,32(sp)
    80002b90:	ec56                	sd	s5,24(sp)
    80002b92:	e85a                	sd	s6,16(sp)
    80002b94:	e45e                	sd	s7,8(sp)
    80002b96:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b98:	00005517          	auipc	a0,0x5
    80002b9c:	53050513          	addi	a0,a0,1328 # 800080c8 <digits+0x88>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9d4080e7          	jalr	-1580(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ba8:	0000f497          	auipc	s1,0xf
    80002bac:	c8048493          	addi	s1,s1,-896 # 80011828 <proc+0x158>
    80002bb0:	00025917          	auipc	s2,0x25
    80002bb4:	c7890913          	addi	s2,s2,-904 # 80027828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bb8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002bba:	00005997          	auipc	s3,0x5
    80002bbe:	6e698993          	addi	s3,s3,1766 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002bc2:	00005a97          	auipc	s5,0x5
    80002bc6:	6e6a8a93          	addi	s5,s5,1766 # 800082a8 <digits+0x268>
    printf("\n");
    80002bca:	00005a17          	auipc	s4,0x5
    80002bce:	4fea0a13          	addi	s4,s4,1278 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bd2:	00005b97          	auipc	s7,0x5
    80002bd6:	70eb8b93          	addi	s7,s7,1806 # 800082e0 <states.0>
    80002bda:	a00d                	j	80002bfc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bdc:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002be0:	8556                	mv	a0,s5
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	992080e7          	jalr	-1646(ra) # 80000574 <printf>
    printf("\n");
    80002bea:	8552                	mv	a0,s4
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	988080e7          	jalr	-1656(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bf4:	58048493          	addi	s1,s1,1408
    80002bf8:	03248263          	beq	s1,s2,80002c1c <procdump+0x9a>
    if(p->state == UNUSED)
    80002bfc:	86a6                	mv	a3,s1
    80002bfe:	ec04a783          	lw	a5,-320(s1)
    80002c02:	dbed                	beqz	a5,80002bf4 <procdump+0x72>
      state = "???";
    80002c04:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c06:	fcfb6be3          	bltu	s6,a5,80002bdc <procdump+0x5a>
    80002c0a:	02079713          	slli	a4,a5,0x20
    80002c0e:	01d75793          	srli	a5,a4,0x1d
    80002c12:	97de                	add	a5,a5,s7
    80002c14:	6390                	ld	a2,0(a5)
    80002c16:	f279                	bnez	a2,80002bdc <procdump+0x5a>
      state = "???";
    80002c18:	864e                	mv	a2,s3
    80002c1a:	b7c9                	j	80002bdc <procdump+0x5a>
  }
}
    80002c1c:	60a6                	ld	ra,72(sp)
    80002c1e:	6406                	ld	s0,64(sp)
    80002c20:	74e2                	ld	s1,56(sp)
    80002c22:	7942                	ld	s2,48(sp)
    80002c24:	79a2                	ld	s3,40(sp)
    80002c26:	7a02                	ld	s4,32(sp)
    80002c28:	6ae2                	ld	s5,24(sp)
    80002c2a:	6b42                	ld	s6,16(sp)
    80002c2c:	6ba2                	ld	s7,8(sp)
    80002c2e:	6161                	addi	sp,sp,80
    80002c30:	8082                	ret

0000000080002c32 <swtch>:
    80002c32:	00153023          	sd	ra,0(a0)
    80002c36:	00253423          	sd	sp,8(a0)
    80002c3a:	e900                	sd	s0,16(a0)
    80002c3c:	ed04                	sd	s1,24(a0)
    80002c3e:	03253023          	sd	s2,32(a0)
    80002c42:	03353423          	sd	s3,40(a0)
    80002c46:	03453823          	sd	s4,48(a0)
    80002c4a:	03553c23          	sd	s5,56(a0)
    80002c4e:	05653023          	sd	s6,64(a0)
    80002c52:	05753423          	sd	s7,72(a0)
    80002c56:	05853823          	sd	s8,80(a0)
    80002c5a:	05953c23          	sd	s9,88(a0)
    80002c5e:	07a53023          	sd	s10,96(a0)
    80002c62:	07b53423          	sd	s11,104(a0)
    80002c66:	0005b083          	ld	ra,0(a1)
    80002c6a:	0085b103          	ld	sp,8(a1)
    80002c6e:	6980                	ld	s0,16(a1)
    80002c70:	6d84                	ld	s1,24(a1)
    80002c72:	0205b903          	ld	s2,32(a1)
    80002c76:	0285b983          	ld	s3,40(a1)
    80002c7a:	0305ba03          	ld	s4,48(a1)
    80002c7e:	0385ba83          	ld	s5,56(a1)
    80002c82:	0405bb03          	ld	s6,64(a1)
    80002c86:	0485bb83          	ld	s7,72(a1)
    80002c8a:	0505bc03          	ld	s8,80(a1)
    80002c8e:	0585bc83          	ld	s9,88(a1)
    80002c92:	0605bd03          	ld	s10,96(a1)
    80002c96:	0685bd83          	ld	s11,104(a1)
    80002c9a:	8082                	ret

0000000080002c9c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c9c:	1141                	addi	sp,sp,-16
    80002c9e:	e406                	sd	ra,8(sp)
    80002ca0:	e022                	sd	s0,0(sp)
    80002ca2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ca4:	00005597          	auipc	a1,0x5
    80002ca8:	66c58593          	addi	a1,a1,1644 # 80008310 <states.0+0x30>
    80002cac:	00025517          	auipc	a0,0x25
    80002cb0:	a2450513          	addi	a0,a0,-1500 # 800276d0 <tickslock>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	e7e080e7          	jalr	-386(ra) # 80000b32 <initlock>
}
    80002cbc:	60a2                	ld	ra,8(sp)
    80002cbe:	6402                	ld	s0,0(sp)
    80002cc0:	0141                	addi	sp,sp,16
    80002cc2:	8082                	ret

0000000080002cc4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e422                	sd	s0,8(sp)
    80002cc8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cca:	00004797          	auipc	a5,0x4
    80002cce:	a3678793          	addi	a5,a5,-1482 # 80006700 <kernelvec>
    80002cd2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cd6:	6422                	ld	s0,8(sp)
    80002cd8:	0141                	addi	sp,sp,16
    80002cda:	8082                	ret

0000000080002cdc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e406                	sd	ra,8(sp)
    80002ce0:	e022                	sd	s0,0(sp)
    80002ce2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	26c080e7          	jalr	620(ra) # 80001f50 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cf6:	00004617          	auipc	a2,0x4
    80002cfa:	30a60613          	addi	a2,a2,778 # 80007000 <_trampoline>
    80002cfe:	00004697          	auipc	a3,0x4
    80002d02:	30268693          	addi	a3,a3,770 # 80007000 <_trampoline>
    80002d06:	8e91                	sub	a3,a3,a2
    80002d08:	040007b7          	lui	a5,0x4000
    80002d0c:	17fd                	addi	a5,a5,-1
    80002d0e:	07b2                	slli	a5,a5,0xc
    80002d10:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d12:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d16:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d18:	180026f3          	csrr	a3,satp
    80002d1c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d1e:	6d38                	ld	a4,88(a0)
    80002d20:	6134                	ld	a3,64(a0)
    80002d22:	6585                	lui	a1,0x1
    80002d24:	96ae                	add	a3,a3,a1
    80002d26:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d28:	6d38                	ld	a4,88(a0)
    80002d2a:	00000697          	auipc	a3,0x0
    80002d2e:	14e68693          	addi	a3,a3,334 # 80002e78 <usertrap>
    80002d32:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d34:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d36:	8692                	mv	a3,tp
    80002d38:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d3e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d42:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d46:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d4a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d4c:	6f18                	ld	a4,24(a4)
    80002d4e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d52:	692c                	ld	a1,80(a0)
    80002d54:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d56:	00004717          	auipc	a4,0x4
    80002d5a:	33a70713          	addi	a4,a4,826 # 80007090 <userret>
    80002d5e:	8f11                	sub	a4,a4,a2
    80002d60:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d62:	577d                	li	a4,-1
    80002d64:	177e                	slli	a4,a4,0x3f
    80002d66:	8dd9                	or	a1,a1,a4
    80002d68:	02000537          	lui	a0,0x2000
    80002d6c:	157d                	addi	a0,a0,-1
    80002d6e:	0536                	slli	a0,a0,0xd
    80002d70:	9782                	jalr	a5
}
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	e426                	sd	s1,8(sp)
    80002d82:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d84:	00025497          	auipc	s1,0x25
    80002d88:	94c48493          	addi	s1,s1,-1716 # 800276d0 <tickslock>
    80002d8c:	8526                	mv	a0,s1
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	e34080e7          	jalr	-460(ra) # 80000bc2 <acquire>
  ticks++;
    80002d96:	00006517          	auipc	a0,0x6
    80002d9a:	29a50513          	addi	a0,a0,666 # 80009030 <ticks>
    80002d9e:	411c                	lw	a5,0(a0)
    80002da0:	2785                	addiw	a5,a5,1
    80002da2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	b04080e7          	jalr	-1276(ra) # 800028a8 <wakeup>
  release(&tickslock);
    80002dac:	8526                	mv	a0,s1
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	ec8080e7          	jalr	-312(ra) # 80000c76 <release>
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dca:	142027f3          	csrr	a5,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dce:	0007cc63          	bltz	a5,80002de6 <devintr+0x26>
    w_sip(r_sip() & ~2);

    return 2;
  }
  #ifndef NONE
  else if (scause == 13 || scause == 15){
    80002dd2:	9bf5                	andi	a5,a5,-3
    80002dd4:	4735                	li	a4,13
    #endif
    return handle_pagefault();
  }
  #endif
  else {
    return 0;
    80002dd6:	4501                	li	a0,0
  else if (scause == 13 || scause == 15){
    80002dd8:	08e78b63          	beq	a5,a4,80002e6e <devintr+0xae>
  }
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret
     (scause & 0xff) == 9){
    80002de6:	0ff7f713          	andi	a4,a5,255
  if((scause & 0x8000000000000000L) &&
    80002dea:	46a5                	li	a3,9
    80002dec:	00d70963          	beq	a4,a3,80002dfe <devintr+0x3e>
  } else if(scause == 0x8000000000000001L){
    80002df0:	577d                	li	a4,-1
    80002df2:	177e                	slli	a4,a4,0x3f
    80002df4:	0705                	addi	a4,a4,1
    80002df6:	04e78b63          	beq	a5,a4,80002e4c <devintr+0x8c>
    return 0;
    80002dfa:	4501                	li	a0,0
    80002dfc:	b7c5                	j	80002ddc <devintr+0x1c>
    int irq = plic_claim();
    80002dfe:	00004097          	auipc	ra,0x4
    80002e02:	a0a080e7          	jalr	-1526(ra) # 80006808 <plic_claim>
    80002e06:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e08:	47a9                	li	a5,10
    80002e0a:	02f50763          	beq	a0,a5,80002e38 <devintr+0x78>
    } else if(irq == VIRTIO0_IRQ){
    80002e0e:	4785                	li	a5,1
    80002e10:	02f50963          	beq	a0,a5,80002e42 <devintr+0x82>
    return 1;
    80002e14:	4505                	li	a0,1
    } else if(irq){
    80002e16:	d0f9                	beqz	s1,80002ddc <devintr+0x1c>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e18:	85a6                	mv	a1,s1
    80002e1a:	00005517          	auipc	a0,0x5
    80002e1e:	4fe50513          	addi	a0,a0,1278 # 80008318 <states.0+0x38>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	752080e7          	jalr	1874(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e2a:	8526                	mv	a0,s1
    80002e2c:	00004097          	auipc	ra,0x4
    80002e30:	a00080e7          	jalr	-1536(ra) # 8000682c <plic_complete>
    return 1;
    80002e34:	4505                	li	a0,1
    80002e36:	b75d                	j	80002ddc <devintr+0x1c>
      uartintr();
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	b4e080e7          	jalr	-1202(ra) # 80000986 <uartintr>
    80002e40:	b7ed                	j	80002e2a <devintr+0x6a>
      virtio_disk_intr();
    80002e42:	00004097          	auipc	ra,0x4
    80002e46:	e7c080e7          	jalr	-388(ra) # 80006cbe <virtio_disk_intr>
    80002e4a:	b7c5                	j	80002e2a <devintr+0x6a>
    if(cpuid() == 0){
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	0d8080e7          	jalr	216(ra) # 80001f24 <cpuid>
    80002e54:	c901                	beqz	a0,80002e64 <devintr+0xa4>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e56:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e5a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e5c:	14479073          	csrw	sip,a5
    return 2;
    80002e60:	4509                	li	a0,2
    80002e62:	bfad                	j	80002ddc <devintr+0x1c>
      clockintr();
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	f16080e7          	jalr	-234(ra) # 80002d7a <clockintr>
    80002e6c:	b7ed                	j	80002e56 <devintr+0x96>
    return handle_pagefault();
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	e3c080e7          	jalr	-452(ra) # 80001caa <handle_pagefault>
    80002e76:	b79d                	j	80002ddc <devintr+0x1c>

0000000080002e78 <usertrap>:
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e84:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e88:	1007f793          	andi	a5,a5,256
    80002e8c:	e3ad                	bnez	a5,80002eee <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e8e:	00004797          	auipc	a5,0x4
    80002e92:	87278793          	addi	a5,a5,-1934 # 80006700 <kernelvec>
    80002e96:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	0b6080e7          	jalr	182(ra) # 80001f50 <myproc>
    80002ea2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ea4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea6:	14102773          	csrr	a4,sepc
    80002eaa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eac:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002eb0:	47a1                	li	a5,8
    80002eb2:	04f71c63          	bne	a4,a5,80002f0a <usertrap+0x92>
    if(p->killed)
    80002eb6:	551c                	lw	a5,40(a0)
    80002eb8:	e3b9                	bnez	a5,80002efe <usertrap+0x86>
    p->trapframe->epc += 4;
    80002eba:	6cb8                	ld	a4,88(s1)
    80002ebc:	6f1c                	ld	a5,24(a4)
    80002ebe:	0791                	addi	a5,a5,4
    80002ec0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ec6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eca:	10079073          	csrw	sstatus,a5
    syscall();
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	2e0080e7          	jalr	736(ra) # 800031ae <syscall>
  if(p->killed)
    80002ed6:	549c                	lw	a5,40(s1)
    80002ed8:	ebc1                	bnez	a5,80002f68 <usertrap+0xf0>
  usertrapret();
    80002eda:	00000097          	auipc	ra,0x0
    80002ede:	e02080e7          	jalr	-510(ra) # 80002cdc <usertrapret>
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6902                	ld	s2,0(sp)
    80002eea:	6105                	addi	sp,sp,32
    80002eec:	8082                	ret
    panic("usertrap: not from user mode");
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	44a50513          	addi	a0,a0,1098 # 80008338 <states.0+0x58>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	634080e7          	jalr	1588(ra) # 8000052a <panic>
      exit(-1);
    80002efe:	557d                	li	a0,-1
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	a78080e7          	jalr	-1416(ra) # 80002978 <exit>
    80002f08:	bf4d                	j	80002eba <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f0a:	00000097          	auipc	ra,0x0
    80002f0e:	eb6080e7          	jalr	-330(ra) # 80002dc0 <devintr>
    80002f12:	892a                	mv	s2,a0
    80002f14:	c501                	beqz	a0,80002f1c <usertrap+0xa4>
  if(p->killed)
    80002f16:	549c                	lw	a5,40(s1)
    80002f18:	c3a1                	beqz	a5,80002f58 <usertrap+0xe0>
    80002f1a:	a815                	j	80002f4e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f1c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f20:	5890                	lw	a2,48(s1)
    80002f22:	00005517          	auipc	a0,0x5
    80002f26:	43650513          	addi	a0,a0,1078 # 80008358 <states.0+0x78>
    80002f2a:	ffffd097          	auipc	ra,0xffffd
    80002f2e:	64a080e7          	jalr	1610(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f36:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f3a:	00005517          	auipc	a0,0x5
    80002f3e:	44e50513          	addi	a0,a0,1102 # 80008388 <states.0+0xa8>
    80002f42:	ffffd097          	auipc	ra,0xffffd
    80002f46:	632080e7          	jalr	1586(ra) # 80000574 <printf>
    p->killed = 1;
    80002f4a:	4785                	li	a5,1
    80002f4c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f4e:	557d                	li	a0,-1
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	a28080e7          	jalr	-1496(ra) # 80002978 <exit>
  if(which_dev == 2)
    80002f58:	4789                	li	a5,2
    80002f5a:	f8f910e3          	bne	s2,a5,80002eda <usertrap+0x62>
    yield();
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	782080e7          	jalr	1922(ra) # 800026e0 <yield>
    80002f66:	bf95                	j	80002eda <usertrap+0x62>
  int which_dev = 0;
    80002f68:	4901                	li	s2,0
    80002f6a:	b7d5                	j	80002f4e <usertrap+0xd6>

0000000080002f6c <kerneltrap>:
{
    80002f6c:	7179                	addi	sp,sp,-48
    80002f6e:	f406                	sd	ra,40(sp)
    80002f70:	f022                	sd	s0,32(sp)
    80002f72:	ec26                	sd	s1,24(sp)
    80002f74:	e84a                	sd	s2,16(sp)
    80002f76:	e44e                	sd	s3,8(sp)
    80002f78:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f7a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f7e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f82:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f86:	1004f793          	andi	a5,s1,256
    80002f8a:	cb85                	beqz	a5,80002fba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f90:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f92:	ef85                	bnez	a5,80002fca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	e2c080e7          	jalr	-468(ra) # 80002dc0 <devintr>
    80002f9c:	cd1d                	beqz	a0,80002fda <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f9e:	4789                	li	a5,2
    80002fa0:	06f50a63          	beq	a0,a5,80003014 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fa4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa8:	10049073          	csrw	sstatus,s1
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6942                	ld	s2,16(sp)
    80002fb4:	69a2                	ld	s3,8(sp)
    80002fb6:	6145                	addi	sp,sp,48
    80002fb8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	3ee50513          	addi	a0,a0,1006 # 800083a8 <states.0+0xc8>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	568080e7          	jalr	1384(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	40650513          	addi	a0,a0,1030 # 800083d0 <states.0+0xf0>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	558080e7          	jalr	1368(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002fda:	85ce                	mv	a1,s3
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	41450513          	addi	a0,a0,1044 # 800083f0 <states.0+0x110>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	590080e7          	jalr	1424(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ff0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	40c50513          	addi	a0,a0,1036 # 80008400 <states.0+0x120>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	578080e7          	jalr	1400(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003004:	00005517          	auipc	a0,0x5
    80003008:	41450513          	addi	a0,a0,1044 # 80008418 <states.0+0x138>
    8000300c:	ffffd097          	auipc	ra,0xffffd
    80003010:	51e080e7          	jalr	1310(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	f3c080e7          	jalr	-196(ra) # 80001f50 <myproc>
    8000301c:	d541                	beqz	a0,80002fa4 <kerneltrap+0x38>
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	f32080e7          	jalr	-206(ra) # 80001f50 <myproc>
    80003026:	4d18                	lw	a4,24(a0)
    80003028:	4791                	li	a5,4
    8000302a:	f6f71de3          	bne	a4,a5,80002fa4 <kerneltrap+0x38>
    yield();
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	6b2080e7          	jalr	1714(ra) # 800026e0 <yield>
    80003036:	b7bd                	j	80002fa4 <kerneltrap+0x38>

0000000080003038 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	1000                	addi	s0,sp,32
    80003042:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	f0c080e7          	jalr	-244(ra) # 80001f50 <myproc>
  switch (n) {
    8000304c:	4795                	li	a5,5
    8000304e:	0497e163          	bltu	a5,s1,80003090 <argraw+0x58>
    80003052:	048a                	slli	s1,s1,0x2
    80003054:	00005717          	auipc	a4,0x5
    80003058:	3fc70713          	addi	a4,a4,1020 # 80008450 <states.0+0x170>
    8000305c:	94ba                	add	s1,s1,a4
    8000305e:	409c                	lw	a5,0(s1)
    80003060:	97ba                	add	a5,a5,a4
    80003062:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003064:	6d3c                	ld	a5,88(a0)
    80003066:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret
    return p->trapframe->a1;
    80003072:	6d3c                	ld	a5,88(a0)
    80003074:	7fa8                	ld	a0,120(a5)
    80003076:	bfcd                	j	80003068 <argraw+0x30>
    return p->trapframe->a2;
    80003078:	6d3c                	ld	a5,88(a0)
    8000307a:	63c8                	ld	a0,128(a5)
    8000307c:	b7f5                	j	80003068 <argraw+0x30>
    return p->trapframe->a3;
    8000307e:	6d3c                	ld	a5,88(a0)
    80003080:	67c8                	ld	a0,136(a5)
    80003082:	b7dd                	j	80003068 <argraw+0x30>
    return p->trapframe->a4;
    80003084:	6d3c                	ld	a5,88(a0)
    80003086:	6bc8                	ld	a0,144(a5)
    80003088:	b7c5                	j	80003068 <argraw+0x30>
    return p->trapframe->a5;
    8000308a:	6d3c                	ld	a5,88(a0)
    8000308c:	6fc8                	ld	a0,152(a5)
    8000308e:	bfe9                	j	80003068 <argraw+0x30>
  panic("argraw");
    80003090:	00005517          	auipc	a0,0x5
    80003094:	39850513          	addi	a0,a0,920 # 80008428 <states.0+0x148>
    80003098:	ffffd097          	auipc	ra,0xffffd
    8000309c:	492080e7          	jalr	1170(ra) # 8000052a <panic>

00000000800030a0 <fetchaddr>:
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	e04a                	sd	s2,0(sp)
    800030aa:	1000                	addi	s0,sp,32
    800030ac:	84aa                	mv	s1,a0
    800030ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	ea0080e7          	jalr	-352(ra) # 80001f50 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030b8:	653c                	ld	a5,72(a0)
    800030ba:	02f4f863          	bgeu	s1,a5,800030ea <fetchaddr+0x4a>
    800030be:	00848713          	addi	a4,s1,8
    800030c2:	02e7e663          	bltu	a5,a4,800030ee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030c6:	46a1                	li	a3,8
    800030c8:	8626                	mv	a2,s1
    800030ca:	85ca                	mv	a1,s2
    800030cc:	6928                	ld	a0,80(a0)
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	626080e7          	jalr	1574(ra) # 800016f4 <copyin>
    800030d6:	00a03533          	snez	a0,a0
    800030da:	40a00533          	neg	a0,a0
}
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	64a2                	ld	s1,8(sp)
    800030e4:	6902                	ld	s2,0(sp)
    800030e6:	6105                	addi	sp,sp,32
    800030e8:	8082                	ret
    return -1;
    800030ea:	557d                	li	a0,-1
    800030ec:	bfcd                	j	800030de <fetchaddr+0x3e>
    800030ee:	557d                	li	a0,-1
    800030f0:	b7fd                	j	800030de <fetchaddr+0x3e>

00000000800030f2 <fetchstr>:
{
    800030f2:	7179                	addi	sp,sp,-48
    800030f4:	f406                	sd	ra,40(sp)
    800030f6:	f022                	sd	s0,32(sp)
    800030f8:	ec26                	sd	s1,24(sp)
    800030fa:	e84a                	sd	s2,16(sp)
    800030fc:	e44e                	sd	s3,8(sp)
    800030fe:	1800                	addi	s0,sp,48
    80003100:	892a                	mv	s2,a0
    80003102:	84ae                	mv	s1,a1
    80003104:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	e4a080e7          	jalr	-438(ra) # 80001f50 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000310e:	86ce                	mv	a3,s3
    80003110:	864a                	mv	a2,s2
    80003112:	85a6                	mv	a1,s1
    80003114:	6928                	ld	a0,80(a0)
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	66c080e7          	jalr	1644(ra) # 80001782 <copyinstr>
  if(err < 0)
    8000311e:	00054763          	bltz	a0,8000312c <fetchstr+0x3a>
  return strlen(buf);
    80003122:	8526                	mv	a0,s1
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	d1e080e7          	jalr	-738(ra) # 80000e42 <strlen>
}
    8000312c:	70a2                	ld	ra,40(sp)
    8000312e:	7402                	ld	s0,32(sp)
    80003130:	64e2                	ld	s1,24(sp)
    80003132:	6942                	ld	s2,16(sp)
    80003134:	69a2                	ld	s3,8(sp)
    80003136:	6145                	addi	sp,sp,48
    80003138:	8082                	ret

000000008000313a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	ef2080e7          	jalr	-270(ra) # 80003038 <argraw>
    8000314e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003150:	4501                	li	a0,0
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	ed0080e7          	jalr	-304(ra) # 80003038 <argraw>
    80003170:	e088                	sd	a0,0(s1)
  return 0;
}
    80003172:	4501                	li	a0,0
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	e04a                	sd	s2,0(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84ae                	mv	s1,a1
    8000318c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	eaa080e7          	jalr	-342(ra) # 80003038 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003196:	864a                	mv	a2,s2
    80003198:	85a6                	mv	a1,s1
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	f58080e7          	jalr	-168(ra) # 800030f2 <fetchstr>
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6902                	ld	s2,0(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	e04a                	sd	s2,0(sp)
    800031b8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	d96080e7          	jalr	-618(ra) # 80001f50 <myproc>
    800031c2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031c4:	05853903          	ld	s2,88(a0)
    800031c8:	0a893783          	ld	a5,168(s2)
    800031cc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031d0:	37fd                	addiw	a5,a5,-1
    800031d2:	4751                	li	a4,20
    800031d4:	00f76f63          	bltu	a4,a5,800031f2 <syscall+0x44>
    800031d8:	00369713          	slli	a4,a3,0x3
    800031dc:	00005797          	auipc	a5,0x5
    800031e0:	28c78793          	addi	a5,a5,652 # 80008468 <syscalls>
    800031e4:	97ba                	add	a5,a5,a4
    800031e6:	639c                	ld	a5,0(a5)
    800031e8:	c789                	beqz	a5,800031f2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031ea:	9782                	jalr	a5
    800031ec:	06a93823          	sd	a0,112(s2)
    800031f0:	a839                	j	8000320e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031f2:	15848613          	addi	a2,s1,344
    800031f6:	588c                	lw	a1,48(s1)
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	23850513          	addi	a0,a0,568 # 80008430 <states.0+0x150>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	374080e7          	jalr	884(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003208:	6cbc                	ld	a5,88(s1)
    8000320a:	577d                	li	a4,-1
    8000320c:	fbb8                	sd	a4,112(a5)
  }
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6902                	ld	s2,0(sp)
    80003216:	6105                	addi	sp,sp,32
    80003218:	8082                	ret

000000008000321a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003222:	fec40593          	addi	a1,s0,-20
    80003226:	4501                	li	a0,0
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	f12080e7          	jalr	-238(ra) # 8000313a <argint>
    return -1;
    80003230:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003232:	00054963          	bltz	a0,80003244 <sys_exit+0x2a>
  exit(n);
    80003236:	fec42503          	lw	a0,-20(s0)
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	73e080e7          	jalr	1854(ra) # 80002978 <exit>
  return 0;  // not reached
    80003242:	4781                	li	a5,0
}
    80003244:	853e                	mv	a0,a5
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret

000000008000324e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000324e:	1141                	addi	sp,sp,-16
    80003250:	e406                	sd	ra,8(sp)
    80003252:	e022                	sd	s0,0(sp)
    80003254:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	cfa080e7          	jalr	-774(ra) # 80001f50 <myproc>
}
    8000325e:	5908                	lw	a0,48(a0)
    80003260:	60a2                	ld	ra,8(sp)
    80003262:	6402                	ld	s0,0(sp)
    80003264:	0141                	addi	sp,sp,16
    80003266:	8082                	ret

0000000080003268 <sys_fork>:

uint64
sys_fork(void)
{
    80003268:	1141                	addi	sp,sp,-16
    8000326a:	e406                	sd	ra,8(sp)
    8000326c:	e022                	sd	s0,0(sp)
    8000326e:	0800                	addi	s0,sp,16
  return fork();
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	104080e7          	jalr	260(ra) # 80002374 <fork>
}
    80003278:	60a2                	ld	ra,8(sp)
    8000327a:	6402                	ld	s0,0(sp)
    8000327c:	0141                	addi	sp,sp,16
    8000327e:	8082                	ret

0000000080003280 <sys_wait>:

uint64
sys_wait(void)
{
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003288:	fe840593          	addi	a1,s0,-24
    8000328c:	4501                	li	a0,0
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	ece080e7          	jalr	-306(ra) # 8000315c <argaddr>
    80003296:	87aa                	mv	a5,a0
    return -1;
    80003298:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000329a:	0007c863          	bltz	a5,800032aa <sys_wait+0x2a>
  return wait(p);
    8000329e:	fe843503          	ld	a0,-24(s0)
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	4de080e7          	jalr	1246(ra) # 80002780 <wait>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032b2:	7179                	addi	sp,sp,-48
    800032b4:	f406                	sd	ra,40(sp)
    800032b6:	f022                	sd	s0,32(sp)
    800032b8:	ec26                	sd	s1,24(sp)
    800032ba:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032bc:	fdc40593          	addi	a1,s0,-36
    800032c0:	4501                	li	a0,0
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	e78080e7          	jalr	-392(ra) # 8000313a <argint>
    return -1;
    800032ca:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800032cc:	00054f63          	bltz	a0,800032ea <sys_sbrk+0x38>
  addr = myproc()->sz;
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	c80080e7          	jalr	-896(ra) # 80001f50 <myproc>
    800032d8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032da:	fdc42503          	lw	a0,-36(s0)
    800032de:	fffff097          	auipc	ra,0xfffff
    800032e2:	022080e7          	jalr	34(ra) # 80002300 <growproc>
    800032e6:	00054863          	bltz	a0,800032f6 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800032ea:	8526                	mv	a0,s1
    800032ec:	70a2                	ld	ra,40(sp)
    800032ee:	7402                	ld	s0,32(sp)
    800032f0:	64e2                	ld	s1,24(sp)
    800032f2:	6145                	addi	sp,sp,48
    800032f4:	8082                	ret
    return -1;
    800032f6:	54fd                	li	s1,-1
    800032f8:	bfcd                	j	800032ea <sys_sbrk+0x38>

00000000800032fa <sys_sleep>:

uint64
sys_sleep(void)
{
    800032fa:	7139                	addi	sp,sp,-64
    800032fc:	fc06                	sd	ra,56(sp)
    800032fe:	f822                	sd	s0,48(sp)
    80003300:	f426                	sd	s1,40(sp)
    80003302:	f04a                	sd	s2,32(sp)
    80003304:	ec4e                	sd	s3,24(sp)
    80003306:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003308:	fcc40593          	addi	a1,s0,-52
    8000330c:	4501                	li	a0,0
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	e2c080e7          	jalr	-468(ra) # 8000313a <argint>
    return -1;
    80003316:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003318:	06054563          	bltz	a0,80003382 <sys_sleep+0x88>
  acquire(&tickslock);
    8000331c:	00024517          	auipc	a0,0x24
    80003320:	3b450513          	addi	a0,a0,948 # 800276d0 <tickslock>
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	89e080e7          	jalr	-1890(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000332c:	00006917          	auipc	s2,0x6
    80003330:	d0492903          	lw	s2,-764(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003334:	fcc42783          	lw	a5,-52(s0)
    80003338:	cf85                	beqz	a5,80003370 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000333a:	00024997          	auipc	s3,0x24
    8000333e:	39698993          	addi	s3,s3,918 # 800276d0 <tickslock>
    80003342:	00006497          	auipc	s1,0x6
    80003346:	cee48493          	addi	s1,s1,-786 # 80009030 <ticks>
    if(myproc()->killed){
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	c06080e7          	jalr	-1018(ra) # 80001f50 <myproc>
    80003352:	551c                	lw	a5,40(a0)
    80003354:	ef9d                	bnez	a5,80003392 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003356:	85ce                	mv	a1,s3
    80003358:	8526                	mv	a0,s1
    8000335a:	fffff097          	auipc	ra,0xfffff
    8000335e:	3c2080e7          	jalr	962(ra) # 8000271c <sleep>
  while(ticks - ticks0 < n){
    80003362:	409c                	lw	a5,0(s1)
    80003364:	412787bb          	subw	a5,a5,s2
    80003368:	fcc42703          	lw	a4,-52(s0)
    8000336c:	fce7efe3          	bltu	a5,a4,8000334a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003370:	00024517          	auipc	a0,0x24
    80003374:	36050513          	addi	a0,a0,864 # 800276d0 <tickslock>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	8fe080e7          	jalr	-1794(ra) # 80000c76 <release>
  return 0;
    80003380:	4781                	li	a5,0
}
    80003382:	853e                	mv	a0,a5
    80003384:	70e2                	ld	ra,56(sp)
    80003386:	7442                	ld	s0,48(sp)
    80003388:	74a2                	ld	s1,40(sp)
    8000338a:	7902                	ld	s2,32(sp)
    8000338c:	69e2                	ld	s3,24(sp)
    8000338e:	6121                	addi	sp,sp,64
    80003390:	8082                	ret
      release(&tickslock);
    80003392:	00024517          	auipc	a0,0x24
    80003396:	33e50513          	addi	a0,a0,830 # 800276d0 <tickslock>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	8dc080e7          	jalr	-1828(ra) # 80000c76 <release>
      return -1;
    800033a2:	57fd                	li	a5,-1
    800033a4:	bff9                	j	80003382 <sys_sleep+0x88>

00000000800033a6 <sys_kill>:

uint64
sys_kill(void)
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033ae:	fec40593          	addi	a1,s0,-20
    800033b2:	4501                	li	a0,0
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	d86080e7          	jalr	-634(ra) # 8000313a <argint>
    800033bc:	87aa                	mv	a5,a0
    return -1;
    800033be:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033c0:	0007c863          	bltz	a5,800033d0 <sys_kill+0x2a>
  return kill(pid);
    800033c4:	fec42503          	lw	a0,-20(s0)
    800033c8:	fffff097          	auipc	ra,0xfffff
    800033cc:	69c080e7          	jalr	1692(ra) # 80002a64 <kill>
}
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	6105                	addi	sp,sp,32
    800033d6:	8082                	ret

00000000800033d8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033e2:	00024517          	auipc	a0,0x24
    800033e6:	2ee50513          	addi	a0,a0,750 # 800276d0 <tickslock>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7d8080e7          	jalr	2008(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800033f2:	00006497          	auipc	s1,0x6
    800033f6:	c3e4a483          	lw	s1,-962(s1) # 80009030 <ticks>
  release(&tickslock);
    800033fa:	00024517          	auipc	a0,0x24
    800033fe:	2d650513          	addi	a0,a0,726 # 800276d0 <tickslock>
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	874080e7          	jalr	-1932(ra) # 80000c76 <release>
  return xticks;
}
    8000340a:	02049513          	slli	a0,s1,0x20
    8000340e:	9101                	srli	a0,a0,0x20
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	64a2                	ld	s1,8(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret

000000008000341a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000341a:	7179                	addi	sp,sp,-48
    8000341c:	f406                	sd	ra,40(sp)
    8000341e:	f022                	sd	s0,32(sp)
    80003420:	ec26                	sd	s1,24(sp)
    80003422:	e84a                	sd	s2,16(sp)
    80003424:	e44e                	sd	s3,8(sp)
    80003426:	e052                	sd	s4,0(sp)
    80003428:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000342a:	00005597          	auipc	a1,0x5
    8000342e:	0ee58593          	addi	a1,a1,238 # 80008518 <syscalls+0xb0>
    80003432:	00024517          	auipc	a0,0x24
    80003436:	2b650513          	addi	a0,a0,694 # 800276e8 <bcache>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	6f8080e7          	jalr	1784(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003442:	0002c797          	auipc	a5,0x2c
    80003446:	2a678793          	addi	a5,a5,678 # 8002f6e8 <bcache+0x8000>
    8000344a:	0002c717          	auipc	a4,0x2c
    8000344e:	50670713          	addi	a4,a4,1286 # 8002f950 <bcache+0x8268>
    80003452:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003456:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000345a:	00024497          	auipc	s1,0x24
    8000345e:	2a648493          	addi	s1,s1,678 # 80027700 <bcache+0x18>
    b->next = bcache.head.next;
    80003462:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003464:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003466:	00005a17          	auipc	s4,0x5
    8000346a:	0baa0a13          	addi	s4,s4,186 # 80008520 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000346e:	2b893783          	ld	a5,696(s2)
    80003472:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003474:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003478:	85d2                	mv	a1,s4
    8000347a:	01048513          	addi	a0,s1,16
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	7d4080e7          	jalr	2004(ra) # 80004c52 <initsleeplock>
    bcache.head.next->prev = b;
    80003486:	2b893783          	ld	a5,696(s2)
    8000348a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000348c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003490:	45848493          	addi	s1,s1,1112
    80003494:	fd349de3          	bne	s1,s3,8000346e <binit+0x54>
  }
}
    80003498:	70a2                	ld	ra,40(sp)
    8000349a:	7402                	ld	s0,32(sp)
    8000349c:	64e2                	ld	s1,24(sp)
    8000349e:	6942                	ld	s2,16(sp)
    800034a0:	69a2                	ld	s3,8(sp)
    800034a2:	6a02                	ld	s4,0(sp)
    800034a4:	6145                	addi	sp,sp,48
    800034a6:	8082                	ret

00000000800034a8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034a8:	7179                	addi	sp,sp,-48
    800034aa:	f406                	sd	ra,40(sp)
    800034ac:	f022                	sd	s0,32(sp)
    800034ae:	ec26                	sd	s1,24(sp)
    800034b0:	e84a                	sd	s2,16(sp)
    800034b2:	e44e                	sd	s3,8(sp)
    800034b4:	1800                	addi	s0,sp,48
    800034b6:	892a                	mv	s2,a0
    800034b8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034ba:	00024517          	auipc	a0,0x24
    800034be:	22e50513          	addi	a0,a0,558 # 800276e8 <bcache>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	700080e7          	jalr	1792(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034ca:	0002c497          	auipc	s1,0x2c
    800034ce:	4d64b483          	ld	s1,1238(s1) # 8002f9a0 <bcache+0x82b8>
    800034d2:	0002c797          	auipc	a5,0x2c
    800034d6:	47e78793          	addi	a5,a5,1150 # 8002f950 <bcache+0x8268>
    800034da:	02f48f63          	beq	s1,a5,80003518 <bread+0x70>
    800034de:	873e                	mv	a4,a5
    800034e0:	a021                	j	800034e8 <bread+0x40>
    800034e2:	68a4                	ld	s1,80(s1)
    800034e4:	02e48a63          	beq	s1,a4,80003518 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034e8:	449c                	lw	a5,8(s1)
    800034ea:	ff279ce3          	bne	a5,s2,800034e2 <bread+0x3a>
    800034ee:	44dc                	lw	a5,12(s1)
    800034f0:	ff3799e3          	bne	a5,s3,800034e2 <bread+0x3a>
      b->refcnt++;
    800034f4:	40bc                	lw	a5,64(s1)
    800034f6:	2785                	addiw	a5,a5,1
    800034f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034fa:	00024517          	auipc	a0,0x24
    800034fe:	1ee50513          	addi	a0,a0,494 # 800276e8 <bcache>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	774080e7          	jalr	1908(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000350a:	01048513          	addi	a0,s1,16
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	77e080e7          	jalr	1918(ra) # 80004c8c <acquiresleep>
      return b;
    80003516:	a8b9                	j	80003574 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003518:	0002c497          	auipc	s1,0x2c
    8000351c:	4804b483          	ld	s1,1152(s1) # 8002f998 <bcache+0x82b0>
    80003520:	0002c797          	auipc	a5,0x2c
    80003524:	43078793          	addi	a5,a5,1072 # 8002f950 <bcache+0x8268>
    80003528:	00f48863          	beq	s1,a5,80003538 <bread+0x90>
    8000352c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000352e:	40bc                	lw	a5,64(s1)
    80003530:	cf81                	beqz	a5,80003548 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003532:	64a4                	ld	s1,72(s1)
    80003534:	fee49de3          	bne	s1,a4,8000352e <bread+0x86>
  panic("bget: no buffers");
    80003538:	00005517          	auipc	a0,0x5
    8000353c:	ff050513          	addi	a0,a0,-16 # 80008528 <syscalls+0xc0>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
      b->dev = dev;
    80003548:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000354c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003550:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003554:	4785                	li	a5,1
    80003556:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003558:	00024517          	auipc	a0,0x24
    8000355c:	19050513          	addi	a0,a0,400 # 800276e8 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	716080e7          	jalr	1814(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003568:	01048513          	addi	a0,s1,16
    8000356c:	00001097          	auipc	ra,0x1
    80003570:	720080e7          	jalr	1824(ra) # 80004c8c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003574:	409c                	lw	a5,0(s1)
    80003576:	cb89                	beqz	a5,80003588 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003578:	8526                	mv	a0,s1
    8000357a:	70a2                	ld	ra,40(sp)
    8000357c:	7402                	ld	s0,32(sp)
    8000357e:	64e2                	ld	s1,24(sp)
    80003580:	6942                	ld	s2,16(sp)
    80003582:	69a2                	ld	s3,8(sp)
    80003584:	6145                	addi	sp,sp,48
    80003586:	8082                	ret
    virtio_disk_rw(b, 0);
    80003588:	4581                	li	a1,0
    8000358a:	8526                	mv	a0,s1
    8000358c:	00003097          	auipc	ra,0x3
    80003590:	4aa080e7          	jalr	1194(ra) # 80006a36 <virtio_disk_rw>
    b->valid = 1;
    80003594:	4785                	li	a5,1
    80003596:	c09c                	sw	a5,0(s1)
  return b;
    80003598:	b7c5                	j	80003578 <bread+0xd0>

000000008000359a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000359a:	1101                	addi	sp,sp,-32
    8000359c:	ec06                	sd	ra,24(sp)
    8000359e:	e822                	sd	s0,16(sp)
    800035a0:	e426                	sd	s1,8(sp)
    800035a2:	1000                	addi	s0,sp,32
    800035a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035a6:	0541                	addi	a0,a0,16
    800035a8:	00001097          	auipc	ra,0x1
    800035ac:	77e080e7          	jalr	1918(ra) # 80004d26 <holdingsleep>
    800035b0:	cd01                	beqz	a0,800035c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035b2:	4585                	li	a1,1
    800035b4:	8526                	mv	a0,s1
    800035b6:	00003097          	auipc	ra,0x3
    800035ba:	480080e7          	jalr	1152(ra) # 80006a36 <virtio_disk_rw>
}
    800035be:	60e2                	ld	ra,24(sp)
    800035c0:	6442                	ld	s0,16(sp)
    800035c2:	64a2                	ld	s1,8(sp)
    800035c4:	6105                	addi	sp,sp,32
    800035c6:	8082                	ret
    panic("bwrite");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	f7850513          	addi	a0,a0,-136 # 80008540 <syscalls+0xd8>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f5a080e7          	jalr	-166(ra) # 8000052a <panic>

00000000800035d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	e426                	sd	s1,8(sp)
    800035e0:	e04a                	sd	s2,0(sp)
    800035e2:	1000                	addi	s0,sp,32
    800035e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035e6:	01050913          	addi	s2,a0,16
    800035ea:	854a                	mv	a0,s2
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	73a080e7          	jalr	1850(ra) # 80004d26 <holdingsleep>
    800035f4:	c92d                	beqz	a0,80003666 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035f6:	854a                	mv	a0,s2
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	6ea080e7          	jalr	1770(ra) # 80004ce2 <releasesleep>

  acquire(&bcache.lock);
    80003600:	00024517          	auipc	a0,0x24
    80003604:	0e850513          	addi	a0,a0,232 # 800276e8 <bcache>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5ba080e7          	jalr	1466(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003610:	40bc                	lw	a5,64(s1)
    80003612:	37fd                	addiw	a5,a5,-1
    80003614:	0007871b          	sext.w	a4,a5
    80003618:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000361a:	eb05                	bnez	a4,8000364a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000361c:	68bc                	ld	a5,80(s1)
    8000361e:	64b8                	ld	a4,72(s1)
    80003620:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003622:	64bc                	ld	a5,72(s1)
    80003624:	68b8                	ld	a4,80(s1)
    80003626:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003628:	0002c797          	auipc	a5,0x2c
    8000362c:	0c078793          	addi	a5,a5,192 # 8002f6e8 <bcache+0x8000>
    80003630:	2b87b703          	ld	a4,696(a5)
    80003634:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003636:	0002c717          	auipc	a4,0x2c
    8000363a:	31a70713          	addi	a4,a4,794 # 8002f950 <bcache+0x8268>
    8000363e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003640:	2b87b703          	ld	a4,696(a5)
    80003644:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003646:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000364a:	00024517          	auipc	a0,0x24
    8000364e:	09e50513          	addi	a0,a0,158 # 800276e8 <bcache>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	624080e7          	jalr	1572(ra) # 80000c76 <release>
}
    8000365a:	60e2                	ld	ra,24(sp)
    8000365c:	6442                	ld	s0,16(sp)
    8000365e:	64a2                	ld	s1,8(sp)
    80003660:	6902                	ld	s2,0(sp)
    80003662:	6105                	addi	sp,sp,32
    80003664:	8082                	ret
    panic("brelse");
    80003666:	00005517          	auipc	a0,0x5
    8000366a:	ee250513          	addi	a0,a0,-286 # 80008548 <syscalls+0xe0>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	ebc080e7          	jalr	-324(ra) # 8000052a <panic>

0000000080003676 <bpin>:

void
bpin(struct buf *b) {
    80003676:	1101                	addi	sp,sp,-32
    80003678:	ec06                	sd	ra,24(sp)
    8000367a:	e822                	sd	s0,16(sp)
    8000367c:	e426                	sd	s1,8(sp)
    8000367e:	1000                	addi	s0,sp,32
    80003680:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003682:	00024517          	auipc	a0,0x24
    80003686:	06650513          	addi	a0,a0,102 # 800276e8 <bcache>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	538080e7          	jalr	1336(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003692:	40bc                	lw	a5,64(s1)
    80003694:	2785                	addiw	a5,a5,1
    80003696:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003698:	00024517          	auipc	a0,0x24
    8000369c:	05050513          	addi	a0,a0,80 # 800276e8 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5d6080e7          	jalr	1494(ra) # 80000c76 <release>
}
    800036a8:	60e2                	ld	ra,24(sp)
    800036aa:	6442                	ld	s0,16(sp)
    800036ac:	64a2                	ld	s1,8(sp)
    800036ae:	6105                	addi	sp,sp,32
    800036b0:	8082                	ret

00000000800036b2 <bunpin>:

void
bunpin(struct buf *b) {
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	e426                	sd	s1,8(sp)
    800036ba:	1000                	addi	s0,sp,32
    800036bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036be:	00024517          	auipc	a0,0x24
    800036c2:	02a50513          	addi	a0,a0,42 # 800276e8 <bcache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	4fc080e7          	jalr	1276(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800036ce:	40bc                	lw	a5,64(s1)
    800036d0:	37fd                	addiw	a5,a5,-1
    800036d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036d4:	00024517          	auipc	a0,0x24
    800036d8:	01450513          	addi	a0,a0,20 # 800276e8 <bcache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	59a080e7          	jalr	1434(ra) # 80000c76 <release>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret

00000000800036ee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	e04a                	sd	s2,0(sp)
    800036f8:	1000                	addi	s0,sp,32
    800036fa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036fc:	00d5d59b          	srliw	a1,a1,0xd
    80003700:	0002c797          	auipc	a5,0x2c
    80003704:	6c47a783          	lw	a5,1732(a5) # 8002fdc4 <sb+0x1c>
    80003708:	9dbd                	addw	a1,a1,a5
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	d9e080e7          	jalr	-610(ra) # 800034a8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003712:	0074f713          	andi	a4,s1,7
    80003716:	4785                	li	a5,1
    80003718:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000371c:	14ce                	slli	s1,s1,0x33
    8000371e:	90d9                	srli	s1,s1,0x36
    80003720:	00950733          	add	a4,a0,s1
    80003724:	05874703          	lbu	a4,88(a4)
    80003728:	00e7f6b3          	and	a3,a5,a4
    8000372c:	c69d                	beqz	a3,8000375a <bfree+0x6c>
    8000372e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003730:	94aa                	add	s1,s1,a0
    80003732:	fff7c793          	not	a5,a5
    80003736:	8ff9                	and	a5,a5,a4
    80003738:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	430080e7          	jalr	1072(ra) # 80004b6c <log_write>
  brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	e92080e7          	jalr	-366(ra) # 800035d8 <brelse>
}
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6902                	ld	s2,0(sp)
    80003756:	6105                	addi	sp,sp,32
    80003758:	8082                	ret
    panic("freeing free block");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	df650513          	addi	a0,a0,-522 # 80008550 <syscalls+0xe8>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	dc8080e7          	jalr	-568(ra) # 8000052a <panic>

000000008000376a <balloc>:
{
    8000376a:	711d                	addi	sp,sp,-96
    8000376c:	ec86                	sd	ra,88(sp)
    8000376e:	e8a2                	sd	s0,80(sp)
    80003770:	e4a6                	sd	s1,72(sp)
    80003772:	e0ca                	sd	s2,64(sp)
    80003774:	fc4e                	sd	s3,56(sp)
    80003776:	f852                	sd	s4,48(sp)
    80003778:	f456                	sd	s5,40(sp)
    8000377a:	f05a                	sd	s6,32(sp)
    8000377c:	ec5e                	sd	s7,24(sp)
    8000377e:	e862                	sd	s8,16(sp)
    80003780:	e466                	sd	s9,8(sp)
    80003782:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003784:	0002c797          	auipc	a5,0x2c
    80003788:	6287a783          	lw	a5,1576(a5) # 8002fdac <sb+0x4>
    8000378c:	cbd1                	beqz	a5,80003820 <balloc+0xb6>
    8000378e:	8baa                	mv	s7,a0
    80003790:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003792:	0002cb17          	auipc	s6,0x2c
    80003796:	616b0b13          	addi	s6,s6,1558 # 8002fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000379a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000379c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000379e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037a0:	6c89                	lui	s9,0x2
    800037a2:	a831                	j	800037be <balloc+0x54>
    brelse(bp);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	e32080e7          	jalr	-462(ra) # 800035d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037ae:	015c87bb          	addw	a5,s9,s5
    800037b2:	00078a9b          	sext.w	s5,a5
    800037b6:	004b2703          	lw	a4,4(s6)
    800037ba:	06eaf363          	bgeu	s5,a4,80003820 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037be:	41fad79b          	sraiw	a5,s5,0x1f
    800037c2:	0137d79b          	srliw	a5,a5,0x13
    800037c6:	015787bb          	addw	a5,a5,s5
    800037ca:	40d7d79b          	sraiw	a5,a5,0xd
    800037ce:	01cb2583          	lw	a1,28(s6)
    800037d2:	9dbd                	addw	a1,a1,a5
    800037d4:	855e                	mv	a0,s7
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	cd2080e7          	jalr	-814(ra) # 800034a8 <bread>
    800037de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037e0:	004b2503          	lw	a0,4(s6)
    800037e4:	000a849b          	sext.w	s1,s5
    800037e8:	8662                	mv	a2,s8
    800037ea:	faa4fde3          	bgeu	s1,a0,800037a4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800037ee:	41f6579b          	sraiw	a5,a2,0x1f
    800037f2:	01d7d69b          	srliw	a3,a5,0x1d
    800037f6:	00c6873b          	addw	a4,a3,a2
    800037fa:	00777793          	andi	a5,a4,7
    800037fe:	9f95                	subw	a5,a5,a3
    80003800:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003804:	4037571b          	sraiw	a4,a4,0x3
    80003808:	00e906b3          	add	a3,s2,a4
    8000380c:	0586c683          	lbu	a3,88(a3)
    80003810:	00d7f5b3          	and	a1,a5,a3
    80003814:	cd91                	beqz	a1,80003830 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003816:	2605                	addiw	a2,a2,1
    80003818:	2485                	addiw	s1,s1,1
    8000381a:	fd4618e3          	bne	a2,s4,800037ea <balloc+0x80>
    8000381e:	b759                	j	800037a4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003820:	00005517          	auipc	a0,0x5
    80003824:	d4850513          	addi	a0,a0,-696 # 80008568 <syscalls+0x100>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	d02080e7          	jalr	-766(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003830:	974a                	add	a4,a4,s2
    80003832:	8fd5                	or	a5,a5,a3
    80003834:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	332080e7          	jalr	818(ra) # 80004b6c <log_write>
        brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	d94080e7          	jalr	-620(ra) # 800035d8 <brelse>
  bp = bread(dev, bno);
    8000384c:	85a6                	mv	a1,s1
    8000384e:	855e                	mv	a0,s7
    80003850:	00000097          	auipc	ra,0x0
    80003854:	c58080e7          	jalr	-936(ra) # 800034a8 <bread>
    80003858:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000385a:	40000613          	li	a2,1024
    8000385e:	4581                	li	a1,0
    80003860:	05850513          	addi	a0,a0,88
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	45a080e7          	jalr	1114(ra) # 80000cbe <memset>
  log_write(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	2fe080e7          	jalr	766(ra) # 80004b6c <log_write>
  brelse(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	d60080e7          	jalr	-672(ra) # 800035d8 <brelse>
}
    80003880:	8526                	mv	a0,s1
    80003882:	60e6                	ld	ra,88(sp)
    80003884:	6446                	ld	s0,80(sp)
    80003886:	64a6                	ld	s1,72(sp)
    80003888:	6906                	ld	s2,64(sp)
    8000388a:	79e2                	ld	s3,56(sp)
    8000388c:	7a42                	ld	s4,48(sp)
    8000388e:	7aa2                	ld	s5,40(sp)
    80003890:	7b02                	ld	s6,32(sp)
    80003892:	6be2                	ld	s7,24(sp)
    80003894:	6c42                	ld	s8,16(sp)
    80003896:	6ca2                	ld	s9,8(sp)
    80003898:	6125                	addi	sp,sp,96
    8000389a:	8082                	ret

000000008000389c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000389c:	7179                	addi	sp,sp,-48
    8000389e:	f406                	sd	ra,40(sp)
    800038a0:	f022                	sd	s0,32(sp)
    800038a2:	ec26                	sd	s1,24(sp)
    800038a4:	e84a                	sd	s2,16(sp)
    800038a6:	e44e                	sd	s3,8(sp)
    800038a8:	e052                	sd	s4,0(sp)
    800038aa:	1800                	addi	s0,sp,48
    800038ac:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038ae:	47ad                	li	a5,11
    800038b0:	04b7fe63          	bgeu	a5,a1,8000390c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038b4:	ff45849b          	addiw	s1,a1,-12
    800038b8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038bc:	0ff00793          	li	a5,255
    800038c0:	0ae7e463          	bltu	a5,a4,80003968 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038c4:	08052583          	lw	a1,128(a0)
    800038c8:	c5b5                	beqz	a1,80003934 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038ca:	00092503          	lw	a0,0(s2)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	bda080e7          	jalr	-1062(ra) # 800034a8 <bread>
    800038d6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038d8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038dc:	02049713          	slli	a4,s1,0x20
    800038e0:	01e75593          	srli	a1,a4,0x1e
    800038e4:	00b784b3          	add	s1,a5,a1
    800038e8:	0004a983          	lw	s3,0(s1)
    800038ec:	04098e63          	beqz	s3,80003948 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038f0:	8552                	mv	a0,s4
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	ce6080e7          	jalr	-794(ra) # 800035d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038fa:	854e                	mv	a0,s3
    800038fc:	70a2                	ld	ra,40(sp)
    800038fe:	7402                	ld	s0,32(sp)
    80003900:	64e2                	ld	s1,24(sp)
    80003902:	6942                	ld	s2,16(sp)
    80003904:	69a2                	ld	s3,8(sp)
    80003906:	6a02                	ld	s4,0(sp)
    80003908:	6145                	addi	sp,sp,48
    8000390a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000390c:	02059793          	slli	a5,a1,0x20
    80003910:	01e7d593          	srli	a1,a5,0x1e
    80003914:	00b504b3          	add	s1,a0,a1
    80003918:	0504a983          	lw	s3,80(s1)
    8000391c:	fc099fe3          	bnez	s3,800038fa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003920:	4108                	lw	a0,0(a0)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e48080e7          	jalr	-440(ra) # 8000376a <balloc>
    8000392a:	0005099b          	sext.w	s3,a0
    8000392e:	0534a823          	sw	s3,80(s1)
    80003932:	b7e1                	j	800038fa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003934:	4108                	lw	a0,0(a0)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	e34080e7          	jalr	-460(ra) # 8000376a <balloc>
    8000393e:	0005059b          	sext.w	a1,a0
    80003942:	08b92023          	sw	a1,128(s2)
    80003946:	b751                	j	800038ca <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003948:	00092503          	lw	a0,0(s2)
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	e1e080e7          	jalr	-482(ra) # 8000376a <balloc>
    80003954:	0005099b          	sext.w	s3,a0
    80003958:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000395c:	8552                	mv	a0,s4
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	20e080e7          	jalr	526(ra) # 80004b6c <log_write>
    80003966:	b769                	j	800038f0 <bmap+0x54>
  panic("bmap: out of range");
    80003968:	00005517          	auipc	a0,0x5
    8000396c:	c1850513          	addi	a0,a0,-1000 # 80008580 <syscalls+0x118>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	bba080e7          	jalr	-1094(ra) # 8000052a <panic>

0000000080003978 <iget>:
{
    80003978:	7179                	addi	sp,sp,-48
    8000397a:	f406                	sd	ra,40(sp)
    8000397c:	f022                	sd	s0,32(sp)
    8000397e:	ec26                	sd	s1,24(sp)
    80003980:	e84a                	sd	s2,16(sp)
    80003982:	e44e                	sd	s3,8(sp)
    80003984:	e052                	sd	s4,0(sp)
    80003986:	1800                	addi	s0,sp,48
    80003988:	89aa                	mv	s3,a0
    8000398a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000398c:	0002c517          	auipc	a0,0x2c
    80003990:	43c50513          	addi	a0,a0,1084 # 8002fdc8 <itable>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	22e080e7          	jalr	558(ra) # 80000bc2 <acquire>
  empty = 0;
    8000399c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000399e:	0002c497          	auipc	s1,0x2c
    800039a2:	44248493          	addi	s1,s1,1090 # 8002fde0 <itable+0x18>
    800039a6:	0002e697          	auipc	a3,0x2e
    800039aa:	eca68693          	addi	a3,a3,-310 # 80031870 <log>
    800039ae:	a039                	j	800039bc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039b0:	02090b63          	beqz	s2,800039e6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039b4:	08848493          	addi	s1,s1,136
    800039b8:	02d48a63          	beq	s1,a3,800039ec <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039bc:	449c                	lw	a5,8(s1)
    800039be:	fef059e3          	blez	a5,800039b0 <iget+0x38>
    800039c2:	4098                	lw	a4,0(s1)
    800039c4:	ff3716e3          	bne	a4,s3,800039b0 <iget+0x38>
    800039c8:	40d8                	lw	a4,4(s1)
    800039ca:	ff4713e3          	bne	a4,s4,800039b0 <iget+0x38>
      ip->ref++;
    800039ce:	2785                	addiw	a5,a5,1
    800039d0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039d2:	0002c517          	auipc	a0,0x2c
    800039d6:	3f650513          	addi	a0,a0,1014 # 8002fdc8 <itable>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	29c080e7          	jalr	668(ra) # 80000c76 <release>
      return ip;
    800039e2:	8926                	mv	s2,s1
    800039e4:	a03d                	j	80003a12 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039e6:	f7f9                	bnez	a5,800039b4 <iget+0x3c>
    800039e8:	8926                	mv	s2,s1
    800039ea:	b7e9                	j	800039b4 <iget+0x3c>
  if(empty == 0)
    800039ec:	02090c63          	beqz	s2,80003a24 <iget+0xac>
  ip->dev = dev;
    800039f0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039f4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039f8:	4785                	li	a5,1
    800039fa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039fe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a02:	0002c517          	auipc	a0,0x2c
    80003a06:	3c650513          	addi	a0,a0,966 # 8002fdc8 <itable>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	26c080e7          	jalr	620(ra) # 80000c76 <release>
}
    80003a12:	854a                	mv	a0,s2
    80003a14:	70a2                	ld	ra,40(sp)
    80003a16:	7402                	ld	s0,32(sp)
    80003a18:	64e2                	ld	s1,24(sp)
    80003a1a:	6942                	ld	s2,16(sp)
    80003a1c:	69a2                	ld	s3,8(sp)
    80003a1e:	6a02                	ld	s4,0(sp)
    80003a20:	6145                	addi	sp,sp,48
    80003a22:	8082                	ret
    panic("iget: no inodes");
    80003a24:	00005517          	auipc	a0,0x5
    80003a28:	b7450513          	addi	a0,a0,-1164 # 80008598 <syscalls+0x130>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	afe080e7          	jalr	-1282(ra) # 8000052a <panic>

0000000080003a34 <fsinit>:
fsinit(int dev) {
    80003a34:	7179                	addi	sp,sp,-48
    80003a36:	f406                	sd	ra,40(sp)
    80003a38:	f022                	sd	s0,32(sp)
    80003a3a:	ec26                	sd	s1,24(sp)
    80003a3c:	e84a                	sd	s2,16(sp)
    80003a3e:	e44e                	sd	s3,8(sp)
    80003a40:	1800                	addi	s0,sp,48
    80003a42:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a44:	4585                	li	a1,1
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	a62080e7          	jalr	-1438(ra) # 800034a8 <bread>
    80003a4e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a50:	0002c997          	auipc	s3,0x2c
    80003a54:	35898993          	addi	s3,s3,856 # 8002fda8 <sb>
    80003a58:	02000613          	li	a2,32
    80003a5c:	05850593          	addi	a1,a0,88
    80003a60:	854e                	mv	a0,s3
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	2b8080e7          	jalr	696(ra) # 80000d1a <memmove>
  brelse(bp);
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	b6c080e7          	jalr	-1172(ra) # 800035d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003a74:	0009a703          	lw	a4,0(s3)
    80003a78:	102037b7          	lui	a5,0x10203
    80003a7c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a80:	02f71263          	bne	a4,a5,80003aa4 <fsinit+0x70>
  initlog(dev, &sb);
    80003a84:	0002c597          	auipc	a1,0x2c
    80003a88:	32458593          	addi	a1,a1,804 # 8002fda8 <sb>
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	e60080e7          	jalr	-416(ra) # 800048ee <initlog>
}
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6145                	addi	sp,sp,48
    80003aa2:	8082                	ret
    panic("invalid file system");
    80003aa4:	00005517          	auipc	a0,0x5
    80003aa8:	b0450513          	addi	a0,a0,-1276 # 800085a8 <syscalls+0x140>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	a7e080e7          	jalr	-1410(ra) # 8000052a <panic>

0000000080003ab4 <iinit>:
{
    80003ab4:	7179                	addi	sp,sp,-48
    80003ab6:	f406                	sd	ra,40(sp)
    80003ab8:	f022                	sd	s0,32(sp)
    80003aba:	ec26                	sd	s1,24(sp)
    80003abc:	e84a                	sd	s2,16(sp)
    80003abe:	e44e                	sd	s3,8(sp)
    80003ac0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ac2:	00005597          	auipc	a1,0x5
    80003ac6:	afe58593          	addi	a1,a1,-1282 # 800085c0 <syscalls+0x158>
    80003aca:	0002c517          	auipc	a0,0x2c
    80003ace:	2fe50513          	addi	a0,a0,766 # 8002fdc8 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	060080e7          	jalr	96(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ada:	0002c497          	auipc	s1,0x2c
    80003ade:	31648493          	addi	s1,s1,790 # 8002fdf0 <itable+0x28>
    80003ae2:	0002e997          	auipc	s3,0x2e
    80003ae6:	d9e98993          	addi	s3,s3,-610 # 80031880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003aea:	00005917          	auipc	s2,0x5
    80003aee:	ade90913          	addi	s2,s2,-1314 # 800085c8 <syscalls+0x160>
    80003af2:	85ca                	mv	a1,s2
    80003af4:	8526                	mv	a0,s1
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	15c080e7          	jalr	348(ra) # 80004c52 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003afe:	08848493          	addi	s1,s1,136
    80003b02:	ff3498e3          	bne	s1,s3,80003af2 <iinit+0x3e>
}
    80003b06:	70a2                	ld	ra,40(sp)
    80003b08:	7402                	ld	s0,32(sp)
    80003b0a:	64e2                	ld	s1,24(sp)
    80003b0c:	6942                	ld	s2,16(sp)
    80003b0e:	69a2                	ld	s3,8(sp)
    80003b10:	6145                	addi	sp,sp,48
    80003b12:	8082                	ret

0000000080003b14 <ialloc>:
{
    80003b14:	715d                	addi	sp,sp,-80
    80003b16:	e486                	sd	ra,72(sp)
    80003b18:	e0a2                	sd	s0,64(sp)
    80003b1a:	fc26                	sd	s1,56(sp)
    80003b1c:	f84a                	sd	s2,48(sp)
    80003b1e:	f44e                	sd	s3,40(sp)
    80003b20:	f052                	sd	s4,32(sp)
    80003b22:	ec56                	sd	s5,24(sp)
    80003b24:	e85a                	sd	s6,16(sp)
    80003b26:	e45e                	sd	s7,8(sp)
    80003b28:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b2a:	0002c717          	auipc	a4,0x2c
    80003b2e:	28a72703          	lw	a4,650(a4) # 8002fdb4 <sb+0xc>
    80003b32:	4785                	li	a5,1
    80003b34:	04e7fa63          	bgeu	a5,a4,80003b88 <ialloc+0x74>
    80003b38:	8aaa                	mv	s5,a0
    80003b3a:	8bae                	mv	s7,a1
    80003b3c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b3e:	0002ca17          	auipc	s4,0x2c
    80003b42:	26aa0a13          	addi	s4,s4,618 # 8002fda8 <sb>
    80003b46:	00048b1b          	sext.w	s6,s1
    80003b4a:	0044d793          	srli	a5,s1,0x4
    80003b4e:	018a2583          	lw	a1,24(s4)
    80003b52:	9dbd                	addw	a1,a1,a5
    80003b54:	8556                	mv	a0,s5
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	952080e7          	jalr	-1710(ra) # 800034a8 <bread>
    80003b5e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b60:	05850993          	addi	s3,a0,88
    80003b64:	00f4f793          	andi	a5,s1,15
    80003b68:	079a                	slli	a5,a5,0x6
    80003b6a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b6c:	00099783          	lh	a5,0(s3)
    80003b70:	c785                	beqz	a5,80003b98 <ialloc+0x84>
    brelse(bp);
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	a66080e7          	jalr	-1434(ra) # 800035d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b7a:	0485                	addi	s1,s1,1
    80003b7c:	00ca2703          	lw	a4,12(s4)
    80003b80:	0004879b          	sext.w	a5,s1
    80003b84:	fce7e1e3          	bltu	a5,a4,80003b46 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b88:	00005517          	auipc	a0,0x5
    80003b8c:	a4850513          	addi	a0,a0,-1464 # 800085d0 <syscalls+0x168>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	99a080e7          	jalr	-1638(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003b98:	04000613          	li	a2,64
    80003b9c:	4581                	li	a1,0
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	11e080e7          	jalr	286(ra) # 80000cbe <memset>
      dip->type = type;
    80003ba8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	fbe080e7          	jalr	-66(ra) # 80004b6c <log_write>
      brelse(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	a20080e7          	jalr	-1504(ra) # 800035d8 <brelse>
      return iget(dev, inum);
    80003bc0:	85da                	mv	a1,s6
    80003bc2:	8556                	mv	a0,s5
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	db4080e7          	jalr	-588(ra) # 80003978 <iget>
}
    80003bcc:	60a6                	ld	ra,72(sp)
    80003bce:	6406                	ld	s0,64(sp)
    80003bd0:	74e2                	ld	s1,56(sp)
    80003bd2:	7942                	ld	s2,48(sp)
    80003bd4:	79a2                	ld	s3,40(sp)
    80003bd6:	7a02                	ld	s4,32(sp)
    80003bd8:	6ae2                	ld	s5,24(sp)
    80003bda:	6b42                	ld	s6,16(sp)
    80003bdc:	6ba2                	ld	s7,8(sp)
    80003bde:	6161                	addi	sp,sp,80
    80003be0:	8082                	ret

0000000080003be2 <iupdate>:
{
    80003be2:	1101                	addi	sp,sp,-32
    80003be4:	ec06                	sd	ra,24(sp)
    80003be6:	e822                	sd	s0,16(sp)
    80003be8:	e426                	sd	s1,8(sp)
    80003bea:	e04a                	sd	s2,0(sp)
    80003bec:	1000                	addi	s0,sp,32
    80003bee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bf0:	415c                	lw	a5,4(a0)
    80003bf2:	0047d79b          	srliw	a5,a5,0x4
    80003bf6:	0002c597          	auipc	a1,0x2c
    80003bfa:	1ca5a583          	lw	a1,458(a1) # 8002fdc0 <sb+0x18>
    80003bfe:	9dbd                	addw	a1,a1,a5
    80003c00:	4108                	lw	a0,0(a0)
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	8a6080e7          	jalr	-1882(ra) # 800034a8 <bread>
    80003c0a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c0c:	05850793          	addi	a5,a0,88
    80003c10:	40c8                	lw	a0,4(s1)
    80003c12:	893d                	andi	a0,a0,15
    80003c14:	051a                	slli	a0,a0,0x6
    80003c16:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c18:	04449703          	lh	a4,68(s1)
    80003c1c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c20:	04649703          	lh	a4,70(s1)
    80003c24:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c28:	04849703          	lh	a4,72(s1)
    80003c2c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c30:	04a49703          	lh	a4,74(s1)
    80003c34:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c38:	44f8                	lw	a4,76(s1)
    80003c3a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c3c:	03400613          	li	a2,52
    80003c40:	05048593          	addi	a1,s1,80
    80003c44:	0531                	addi	a0,a0,12
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	0d4080e7          	jalr	212(ra) # 80000d1a <memmove>
  log_write(bp);
    80003c4e:	854a                	mv	a0,s2
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	f1c080e7          	jalr	-228(ra) # 80004b6c <log_write>
  brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	97e080e7          	jalr	-1666(ra) # 800035d8 <brelse>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6902                	ld	s2,0(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret

0000000080003c6e <idup>:
{
    80003c6e:	1101                	addi	sp,sp,-32
    80003c70:	ec06                	sd	ra,24(sp)
    80003c72:	e822                	sd	s0,16(sp)
    80003c74:	e426                	sd	s1,8(sp)
    80003c76:	1000                	addi	s0,sp,32
    80003c78:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c7a:	0002c517          	auipc	a0,0x2c
    80003c7e:	14e50513          	addi	a0,a0,334 # 8002fdc8 <itable>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	f40080e7          	jalr	-192(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003c8a:	449c                	lw	a5,8(s1)
    80003c8c:	2785                	addiw	a5,a5,1
    80003c8e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c90:	0002c517          	auipc	a0,0x2c
    80003c94:	13850513          	addi	a0,a0,312 # 8002fdc8 <itable>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	fde080e7          	jalr	-34(ra) # 80000c76 <release>
}
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	60e2                	ld	ra,24(sp)
    80003ca4:	6442                	ld	s0,16(sp)
    80003ca6:	64a2                	ld	s1,8(sp)
    80003ca8:	6105                	addi	sp,sp,32
    80003caa:	8082                	ret

0000000080003cac <ilock>:
{
    80003cac:	1101                	addi	sp,sp,-32
    80003cae:	ec06                	sd	ra,24(sp)
    80003cb0:	e822                	sd	s0,16(sp)
    80003cb2:	e426                	sd	s1,8(sp)
    80003cb4:	e04a                	sd	s2,0(sp)
    80003cb6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cb8:	c115                	beqz	a0,80003cdc <ilock+0x30>
    80003cba:	84aa                	mv	s1,a0
    80003cbc:	451c                	lw	a5,8(a0)
    80003cbe:	00f05f63          	blez	a5,80003cdc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cc2:	0541                	addi	a0,a0,16
    80003cc4:	00001097          	auipc	ra,0x1
    80003cc8:	fc8080e7          	jalr	-56(ra) # 80004c8c <acquiresleep>
  if(ip->valid == 0){
    80003ccc:	40bc                	lw	a5,64(s1)
    80003cce:	cf99                	beqz	a5,80003cec <ilock+0x40>
}
    80003cd0:	60e2                	ld	ra,24(sp)
    80003cd2:	6442                	ld	s0,16(sp)
    80003cd4:	64a2                	ld	s1,8(sp)
    80003cd6:	6902                	ld	s2,0(sp)
    80003cd8:	6105                	addi	sp,sp,32
    80003cda:	8082                	ret
    panic("ilock");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	90c50513          	addi	a0,a0,-1780 # 800085e8 <syscalls+0x180>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	846080e7          	jalr	-1978(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cec:	40dc                	lw	a5,4(s1)
    80003cee:	0047d79b          	srliw	a5,a5,0x4
    80003cf2:	0002c597          	auipc	a1,0x2c
    80003cf6:	0ce5a583          	lw	a1,206(a1) # 8002fdc0 <sb+0x18>
    80003cfa:	9dbd                	addw	a1,a1,a5
    80003cfc:	4088                	lw	a0,0(s1)
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	7aa080e7          	jalr	1962(ra) # 800034a8 <bread>
    80003d06:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d08:	05850593          	addi	a1,a0,88
    80003d0c:	40dc                	lw	a5,4(s1)
    80003d0e:	8bbd                	andi	a5,a5,15
    80003d10:	079a                	slli	a5,a5,0x6
    80003d12:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d14:	00059783          	lh	a5,0(a1)
    80003d18:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d1c:	00259783          	lh	a5,2(a1)
    80003d20:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d24:	00459783          	lh	a5,4(a1)
    80003d28:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d2c:	00659783          	lh	a5,6(a1)
    80003d30:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d34:	459c                	lw	a5,8(a1)
    80003d36:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d38:	03400613          	li	a2,52
    80003d3c:	05b1                	addi	a1,a1,12
    80003d3e:	05048513          	addi	a0,s1,80
    80003d42:	ffffd097          	auipc	ra,0xffffd
    80003d46:	fd8080e7          	jalr	-40(ra) # 80000d1a <memmove>
    brelse(bp);
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	88c080e7          	jalr	-1908(ra) # 800035d8 <brelse>
    ip->valid = 1;
    80003d54:	4785                	li	a5,1
    80003d56:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d58:	04449783          	lh	a5,68(s1)
    80003d5c:	fbb5                	bnez	a5,80003cd0 <ilock+0x24>
      panic("ilock: no type");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	89250513          	addi	a0,a0,-1902 # 800085f0 <syscalls+0x188>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7c4080e7          	jalr	1988(ra) # 8000052a <panic>

0000000080003d6e <iunlock>:
{
    80003d6e:	1101                	addi	sp,sp,-32
    80003d70:	ec06                	sd	ra,24(sp)
    80003d72:	e822                	sd	s0,16(sp)
    80003d74:	e426                	sd	s1,8(sp)
    80003d76:	e04a                	sd	s2,0(sp)
    80003d78:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d7a:	c905                	beqz	a0,80003daa <iunlock+0x3c>
    80003d7c:	84aa                	mv	s1,a0
    80003d7e:	01050913          	addi	s2,a0,16
    80003d82:	854a                	mv	a0,s2
    80003d84:	00001097          	auipc	ra,0x1
    80003d88:	fa2080e7          	jalr	-94(ra) # 80004d26 <holdingsleep>
    80003d8c:	cd19                	beqz	a0,80003daa <iunlock+0x3c>
    80003d8e:	449c                	lw	a5,8(s1)
    80003d90:	00f05d63          	blez	a5,80003daa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d94:	854a                	mv	a0,s2
    80003d96:	00001097          	auipc	ra,0x1
    80003d9a:	f4c080e7          	jalr	-180(ra) # 80004ce2 <releasesleep>
}
    80003d9e:	60e2                	ld	ra,24(sp)
    80003da0:	6442                	ld	s0,16(sp)
    80003da2:	64a2                	ld	s1,8(sp)
    80003da4:	6902                	ld	s2,0(sp)
    80003da6:	6105                	addi	sp,sp,32
    80003da8:	8082                	ret
    panic("iunlock");
    80003daa:	00005517          	auipc	a0,0x5
    80003dae:	85650513          	addi	a0,a0,-1962 # 80008600 <syscalls+0x198>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	778080e7          	jalr	1912(ra) # 8000052a <panic>

0000000080003dba <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dba:	7179                	addi	sp,sp,-48
    80003dbc:	f406                	sd	ra,40(sp)
    80003dbe:	f022                	sd	s0,32(sp)
    80003dc0:	ec26                	sd	s1,24(sp)
    80003dc2:	e84a                	sd	s2,16(sp)
    80003dc4:	e44e                	sd	s3,8(sp)
    80003dc6:	e052                	sd	s4,0(sp)
    80003dc8:	1800                	addi	s0,sp,48
    80003dca:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dcc:	05050493          	addi	s1,a0,80
    80003dd0:	08050913          	addi	s2,a0,128
    80003dd4:	a021                	j	80003ddc <itrunc+0x22>
    80003dd6:	0491                	addi	s1,s1,4
    80003dd8:	01248d63          	beq	s1,s2,80003df2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ddc:	408c                	lw	a1,0(s1)
    80003dde:	dde5                	beqz	a1,80003dd6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003de0:	0009a503          	lw	a0,0(s3)
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	90a080e7          	jalr	-1782(ra) # 800036ee <bfree>
      ip->addrs[i] = 0;
    80003dec:	0004a023          	sw	zero,0(s1)
    80003df0:	b7dd                	j	80003dd6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003df2:	0809a583          	lw	a1,128(s3)
    80003df6:	e185                	bnez	a1,80003e16 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003df8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	de4080e7          	jalr	-540(ra) # 80003be2 <iupdate>
}
    80003e06:	70a2                	ld	ra,40(sp)
    80003e08:	7402                	ld	s0,32(sp)
    80003e0a:	64e2                	ld	s1,24(sp)
    80003e0c:	6942                	ld	s2,16(sp)
    80003e0e:	69a2                	ld	s3,8(sp)
    80003e10:	6a02                	ld	s4,0(sp)
    80003e12:	6145                	addi	sp,sp,48
    80003e14:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e16:	0009a503          	lw	a0,0(s3)
    80003e1a:	fffff097          	auipc	ra,0xfffff
    80003e1e:	68e080e7          	jalr	1678(ra) # 800034a8 <bread>
    80003e22:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e24:	05850493          	addi	s1,a0,88
    80003e28:	45850913          	addi	s2,a0,1112
    80003e2c:	a021                	j	80003e34 <itrunc+0x7a>
    80003e2e:	0491                	addi	s1,s1,4
    80003e30:	01248b63          	beq	s1,s2,80003e46 <itrunc+0x8c>
      if(a[j])
    80003e34:	408c                	lw	a1,0(s1)
    80003e36:	dde5                	beqz	a1,80003e2e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e38:	0009a503          	lw	a0,0(s3)
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	8b2080e7          	jalr	-1870(ra) # 800036ee <bfree>
    80003e44:	b7ed                	j	80003e2e <itrunc+0x74>
    brelse(bp);
    80003e46:	8552                	mv	a0,s4
    80003e48:	fffff097          	auipc	ra,0xfffff
    80003e4c:	790080e7          	jalr	1936(ra) # 800035d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e50:	0809a583          	lw	a1,128(s3)
    80003e54:	0009a503          	lw	a0,0(s3)
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	896080e7          	jalr	-1898(ra) # 800036ee <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e60:	0809a023          	sw	zero,128(s3)
    80003e64:	bf51                	j	80003df8 <itrunc+0x3e>

0000000080003e66 <iput>:
{
    80003e66:	1101                	addi	sp,sp,-32
    80003e68:	ec06                	sd	ra,24(sp)
    80003e6a:	e822                	sd	s0,16(sp)
    80003e6c:	e426                	sd	s1,8(sp)
    80003e6e:	e04a                	sd	s2,0(sp)
    80003e70:	1000                	addi	s0,sp,32
    80003e72:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e74:	0002c517          	auipc	a0,0x2c
    80003e78:	f5450513          	addi	a0,a0,-172 # 8002fdc8 <itable>
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	d46080e7          	jalr	-698(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e84:	4498                	lw	a4,8(s1)
    80003e86:	4785                	li	a5,1
    80003e88:	02f70363          	beq	a4,a5,80003eae <iput+0x48>
  ip->ref--;
    80003e8c:	449c                	lw	a5,8(s1)
    80003e8e:	37fd                	addiw	a5,a5,-1
    80003e90:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e92:	0002c517          	auipc	a0,0x2c
    80003e96:	f3650513          	addi	a0,a0,-202 # 8002fdc8 <itable>
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	ddc080e7          	jalr	-548(ra) # 80000c76 <release>
}
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6902                	ld	s2,0(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eae:	40bc                	lw	a5,64(s1)
    80003eb0:	dff1                	beqz	a5,80003e8c <iput+0x26>
    80003eb2:	04a49783          	lh	a5,74(s1)
    80003eb6:	fbf9                	bnez	a5,80003e8c <iput+0x26>
    acquiresleep(&ip->lock);
    80003eb8:	01048913          	addi	s2,s1,16
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	dce080e7          	jalr	-562(ra) # 80004c8c <acquiresleep>
    release(&itable.lock);
    80003ec6:	0002c517          	auipc	a0,0x2c
    80003eca:	f0250513          	addi	a0,a0,-254 # 8002fdc8 <itable>
    80003ece:	ffffd097          	auipc	ra,0xffffd
    80003ed2:	da8080e7          	jalr	-600(ra) # 80000c76 <release>
    itrunc(ip);
    80003ed6:	8526                	mv	a0,s1
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	ee2080e7          	jalr	-286(ra) # 80003dba <itrunc>
    ip->type = 0;
    80003ee0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	cfc080e7          	jalr	-772(ra) # 80003be2 <iupdate>
    ip->valid = 0;
    80003eee:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	00001097          	auipc	ra,0x1
    80003ef8:	dee080e7          	jalr	-530(ra) # 80004ce2 <releasesleep>
    acquire(&itable.lock);
    80003efc:	0002c517          	auipc	a0,0x2c
    80003f00:	ecc50513          	addi	a0,a0,-308 # 8002fdc8 <itable>
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	cbe080e7          	jalr	-834(ra) # 80000bc2 <acquire>
    80003f0c:	b741                	j	80003e8c <iput+0x26>

0000000080003f0e <iunlockput>:
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	e426                	sd	s1,8(sp)
    80003f16:	1000                	addi	s0,sp,32
    80003f18:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	e54080e7          	jalr	-428(ra) # 80003d6e <iunlock>
  iput(ip);
    80003f22:	8526                	mv	a0,s1
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	f42080e7          	jalr	-190(ra) # 80003e66 <iput>
}
    80003f2c:	60e2                	ld	ra,24(sp)
    80003f2e:	6442                	ld	s0,16(sp)
    80003f30:	64a2                	ld	s1,8(sp)
    80003f32:	6105                	addi	sp,sp,32
    80003f34:	8082                	ret

0000000080003f36 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f36:	1141                	addi	sp,sp,-16
    80003f38:	e422                	sd	s0,8(sp)
    80003f3a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f3c:	411c                	lw	a5,0(a0)
    80003f3e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f40:	415c                	lw	a5,4(a0)
    80003f42:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f44:	04451783          	lh	a5,68(a0)
    80003f48:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f4c:	04a51783          	lh	a5,74(a0)
    80003f50:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f54:	04c56783          	lwu	a5,76(a0)
    80003f58:	e99c                	sd	a5,16(a1)
}
    80003f5a:	6422                	ld	s0,8(sp)
    80003f5c:	0141                	addi	sp,sp,16
    80003f5e:	8082                	ret

0000000080003f60 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f60:	457c                	lw	a5,76(a0)
    80003f62:	0ed7e963          	bltu	a5,a3,80004054 <readi+0xf4>
{
    80003f66:	7159                	addi	sp,sp,-112
    80003f68:	f486                	sd	ra,104(sp)
    80003f6a:	f0a2                	sd	s0,96(sp)
    80003f6c:	eca6                	sd	s1,88(sp)
    80003f6e:	e8ca                	sd	s2,80(sp)
    80003f70:	e4ce                	sd	s3,72(sp)
    80003f72:	e0d2                	sd	s4,64(sp)
    80003f74:	fc56                	sd	s5,56(sp)
    80003f76:	f85a                	sd	s6,48(sp)
    80003f78:	f45e                	sd	s7,40(sp)
    80003f7a:	f062                	sd	s8,32(sp)
    80003f7c:	ec66                	sd	s9,24(sp)
    80003f7e:	e86a                	sd	s10,16(sp)
    80003f80:	e46e                	sd	s11,8(sp)
    80003f82:	1880                	addi	s0,sp,112
    80003f84:	8baa                	mv	s7,a0
    80003f86:	8c2e                	mv	s8,a1
    80003f88:	8ab2                	mv	s5,a2
    80003f8a:	84b6                	mv	s1,a3
    80003f8c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f8e:	9f35                	addw	a4,a4,a3
    return 0;
    80003f90:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f92:	0ad76063          	bltu	a4,a3,80004032 <readi+0xd2>
  if(off + n > ip->size)
    80003f96:	00e7f463          	bgeu	a5,a4,80003f9e <readi+0x3e>
    n = ip->size - off;
    80003f9a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f9e:	0a0b0963          	beqz	s6,80004050 <readi+0xf0>
    80003fa2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fa8:	5cfd                	li	s9,-1
    80003faa:	a82d                	j	80003fe4 <readi+0x84>
    80003fac:	020a1d93          	slli	s11,s4,0x20
    80003fb0:	020ddd93          	srli	s11,s11,0x20
    80003fb4:	05890793          	addi	a5,s2,88
    80003fb8:	86ee                	mv	a3,s11
    80003fba:	963e                	add	a2,a2,a5
    80003fbc:	85d6                	mv	a1,s5
    80003fbe:	8562                	mv	a0,s8
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	b16080e7          	jalr	-1258(ra) # 80002ad6 <either_copyout>
    80003fc8:	05950d63          	beq	a0,s9,80004022 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fcc:	854a                	mv	a0,s2
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	60a080e7          	jalr	1546(ra) # 800035d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fd6:	013a09bb          	addw	s3,s4,s3
    80003fda:	009a04bb          	addw	s1,s4,s1
    80003fde:	9aee                	add	s5,s5,s11
    80003fe0:	0569f763          	bgeu	s3,s6,8000402e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fe4:	000ba903          	lw	s2,0(s7)
    80003fe8:	00a4d59b          	srliw	a1,s1,0xa
    80003fec:	855e                	mv	a0,s7
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	8ae080e7          	jalr	-1874(ra) # 8000389c <bmap>
    80003ff6:	0005059b          	sext.w	a1,a0
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	4ac080e7          	jalr	1196(ra) # 800034a8 <bread>
    80004004:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004006:	3ff4f613          	andi	a2,s1,1023
    8000400a:	40cd07bb          	subw	a5,s10,a2
    8000400e:	413b073b          	subw	a4,s6,s3
    80004012:	8a3e                	mv	s4,a5
    80004014:	2781                	sext.w	a5,a5
    80004016:	0007069b          	sext.w	a3,a4
    8000401a:	f8f6f9e3          	bgeu	a3,a5,80003fac <readi+0x4c>
    8000401e:	8a3a                	mv	s4,a4
    80004020:	b771                	j	80003fac <readi+0x4c>
      brelse(bp);
    80004022:	854a                	mv	a0,s2
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	5b4080e7          	jalr	1460(ra) # 800035d8 <brelse>
      tot = -1;
    8000402c:	59fd                	li	s3,-1
  }
  return tot;
    8000402e:	0009851b          	sext.w	a0,s3
}
    80004032:	70a6                	ld	ra,104(sp)
    80004034:	7406                	ld	s0,96(sp)
    80004036:	64e6                	ld	s1,88(sp)
    80004038:	6946                	ld	s2,80(sp)
    8000403a:	69a6                	ld	s3,72(sp)
    8000403c:	6a06                	ld	s4,64(sp)
    8000403e:	7ae2                	ld	s5,56(sp)
    80004040:	7b42                	ld	s6,48(sp)
    80004042:	7ba2                	ld	s7,40(sp)
    80004044:	7c02                	ld	s8,32(sp)
    80004046:	6ce2                	ld	s9,24(sp)
    80004048:	6d42                	ld	s10,16(sp)
    8000404a:	6da2                	ld	s11,8(sp)
    8000404c:	6165                	addi	sp,sp,112
    8000404e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004050:	89da                	mv	s3,s6
    80004052:	bff1                	j	8000402e <readi+0xce>
    return 0;
    80004054:	4501                	li	a0,0
}
    80004056:	8082                	ret

0000000080004058 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004058:	457c                	lw	a5,76(a0)
    8000405a:	10d7e863          	bltu	a5,a3,8000416a <writei+0x112>
{
    8000405e:	7159                	addi	sp,sp,-112
    80004060:	f486                	sd	ra,104(sp)
    80004062:	f0a2                	sd	s0,96(sp)
    80004064:	eca6                	sd	s1,88(sp)
    80004066:	e8ca                	sd	s2,80(sp)
    80004068:	e4ce                	sd	s3,72(sp)
    8000406a:	e0d2                	sd	s4,64(sp)
    8000406c:	fc56                	sd	s5,56(sp)
    8000406e:	f85a                	sd	s6,48(sp)
    80004070:	f45e                	sd	s7,40(sp)
    80004072:	f062                	sd	s8,32(sp)
    80004074:	ec66                	sd	s9,24(sp)
    80004076:	e86a                	sd	s10,16(sp)
    80004078:	e46e                	sd	s11,8(sp)
    8000407a:	1880                	addi	s0,sp,112
    8000407c:	8b2a                	mv	s6,a0
    8000407e:	8c2e                	mv	s8,a1
    80004080:	8ab2                	mv	s5,a2
    80004082:	8936                	mv	s2,a3
    80004084:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004086:	00e687bb          	addw	a5,a3,a4
    8000408a:	0ed7e263          	bltu	a5,a3,8000416e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000408e:	00043737          	lui	a4,0x43
    80004092:	0ef76063          	bltu	a4,a5,80004172 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004096:	0c0b8863          	beqz	s7,80004166 <writei+0x10e>
    8000409a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000409c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040a0:	5cfd                	li	s9,-1
    800040a2:	a091                	j	800040e6 <writei+0x8e>
    800040a4:	02099d93          	slli	s11,s3,0x20
    800040a8:	020ddd93          	srli	s11,s11,0x20
    800040ac:	05848793          	addi	a5,s1,88
    800040b0:	86ee                	mv	a3,s11
    800040b2:	8656                	mv	a2,s5
    800040b4:	85e2                	mv	a1,s8
    800040b6:	953e                	add	a0,a0,a5
    800040b8:	fffff097          	auipc	ra,0xfffff
    800040bc:	a74080e7          	jalr	-1420(ra) # 80002b2c <either_copyin>
    800040c0:	07950263          	beq	a0,s9,80004124 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040c4:	8526                	mv	a0,s1
    800040c6:	00001097          	auipc	ra,0x1
    800040ca:	aa6080e7          	jalr	-1370(ra) # 80004b6c <log_write>
    brelse(bp);
    800040ce:	8526                	mv	a0,s1
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	508080e7          	jalr	1288(ra) # 800035d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d8:	01498a3b          	addw	s4,s3,s4
    800040dc:	0129893b          	addw	s2,s3,s2
    800040e0:	9aee                	add	s5,s5,s11
    800040e2:	057a7663          	bgeu	s4,s7,8000412e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040e6:	000b2483          	lw	s1,0(s6)
    800040ea:	00a9559b          	srliw	a1,s2,0xa
    800040ee:	855a                	mv	a0,s6
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	7ac080e7          	jalr	1964(ra) # 8000389c <bmap>
    800040f8:	0005059b          	sext.w	a1,a0
    800040fc:	8526                	mv	a0,s1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	3aa080e7          	jalr	938(ra) # 800034a8 <bread>
    80004106:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004108:	3ff97513          	andi	a0,s2,1023
    8000410c:	40ad07bb          	subw	a5,s10,a0
    80004110:	414b873b          	subw	a4,s7,s4
    80004114:	89be                	mv	s3,a5
    80004116:	2781                	sext.w	a5,a5
    80004118:	0007069b          	sext.w	a3,a4
    8000411c:	f8f6f4e3          	bgeu	a3,a5,800040a4 <writei+0x4c>
    80004120:	89ba                	mv	s3,a4
    80004122:	b749                	j	800040a4 <writei+0x4c>
      brelse(bp);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	4b2080e7          	jalr	1202(ra) # 800035d8 <brelse>
  }

  if(off > ip->size)
    8000412e:	04cb2783          	lw	a5,76(s6)
    80004132:	0127f463          	bgeu	a5,s2,8000413a <writei+0xe2>
    ip->size = off;
    80004136:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000413a:	855a                	mv	a0,s6
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	aa6080e7          	jalr	-1370(ra) # 80003be2 <iupdate>

  return tot;
    80004144:	000a051b          	sext.w	a0,s4
}
    80004148:	70a6                	ld	ra,104(sp)
    8000414a:	7406                	ld	s0,96(sp)
    8000414c:	64e6                	ld	s1,88(sp)
    8000414e:	6946                	ld	s2,80(sp)
    80004150:	69a6                	ld	s3,72(sp)
    80004152:	6a06                	ld	s4,64(sp)
    80004154:	7ae2                	ld	s5,56(sp)
    80004156:	7b42                	ld	s6,48(sp)
    80004158:	7ba2                	ld	s7,40(sp)
    8000415a:	7c02                	ld	s8,32(sp)
    8000415c:	6ce2                	ld	s9,24(sp)
    8000415e:	6d42                	ld	s10,16(sp)
    80004160:	6da2                	ld	s11,8(sp)
    80004162:	6165                	addi	sp,sp,112
    80004164:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004166:	8a5e                	mv	s4,s7
    80004168:	bfc9                	j	8000413a <writei+0xe2>
    return -1;
    8000416a:	557d                	li	a0,-1
}
    8000416c:	8082                	ret
    return -1;
    8000416e:	557d                	li	a0,-1
    80004170:	bfe1                	j	80004148 <writei+0xf0>
    return -1;
    80004172:	557d                	li	a0,-1
    80004174:	bfd1                	j	80004148 <writei+0xf0>

0000000080004176 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004176:	1141                	addi	sp,sp,-16
    80004178:	e406                	sd	ra,8(sp)
    8000417a:	e022                	sd	s0,0(sp)
    8000417c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000417e:	4639                	li	a2,14
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	c16080e7          	jalr	-1002(ra) # 80000d96 <strncmp>
}
    80004188:	60a2                	ld	ra,8(sp)
    8000418a:	6402                	ld	s0,0(sp)
    8000418c:	0141                	addi	sp,sp,16
    8000418e:	8082                	ret

0000000080004190 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004190:	7139                	addi	sp,sp,-64
    80004192:	fc06                	sd	ra,56(sp)
    80004194:	f822                	sd	s0,48(sp)
    80004196:	f426                	sd	s1,40(sp)
    80004198:	f04a                	sd	s2,32(sp)
    8000419a:	ec4e                	sd	s3,24(sp)
    8000419c:	e852                	sd	s4,16(sp)
    8000419e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041a0:	04451703          	lh	a4,68(a0)
    800041a4:	4785                	li	a5,1
    800041a6:	00f71a63          	bne	a4,a5,800041ba <dirlookup+0x2a>
    800041aa:	892a                	mv	s2,a0
    800041ac:	89ae                	mv	s3,a1
    800041ae:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b0:	457c                	lw	a5,76(a0)
    800041b2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041b4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b6:	e79d                	bnez	a5,800041e4 <dirlookup+0x54>
    800041b8:	a8a5                	j	80004230 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041ba:	00004517          	auipc	a0,0x4
    800041be:	44e50513          	addi	a0,a0,1102 # 80008608 <syscalls+0x1a0>
    800041c2:	ffffc097          	auipc	ra,0xffffc
    800041c6:	368080e7          	jalr	872(ra) # 8000052a <panic>
      panic("dirlookup read");
    800041ca:	00004517          	auipc	a0,0x4
    800041ce:	45650513          	addi	a0,a0,1110 # 80008620 <syscalls+0x1b8>
    800041d2:	ffffc097          	auipc	ra,0xffffc
    800041d6:	358080e7          	jalr	856(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041da:	24c1                	addiw	s1,s1,16
    800041dc:	04c92783          	lw	a5,76(s2)
    800041e0:	04f4f763          	bgeu	s1,a5,8000422e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e4:	4741                	li	a4,16
    800041e6:	86a6                	mv	a3,s1
    800041e8:	fc040613          	addi	a2,s0,-64
    800041ec:	4581                	li	a1,0
    800041ee:	854a                	mv	a0,s2
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	d70080e7          	jalr	-656(ra) # 80003f60 <readi>
    800041f8:	47c1                	li	a5,16
    800041fa:	fcf518e3          	bne	a0,a5,800041ca <dirlookup+0x3a>
    if(de.inum == 0)
    800041fe:	fc045783          	lhu	a5,-64(s0)
    80004202:	dfe1                	beqz	a5,800041da <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004204:	fc240593          	addi	a1,s0,-62
    80004208:	854e                	mv	a0,s3
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	f6c080e7          	jalr	-148(ra) # 80004176 <namecmp>
    80004212:	f561                	bnez	a0,800041da <dirlookup+0x4a>
      if(poff)
    80004214:	000a0463          	beqz	s4,8000421c <dirlookup+0x8c>
        *poff = off;
    80004218:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000421c:	fc045583          	lhu	a1,-64(s0)
    80004220:	00092503          	lw	a0,0(s2)
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	754080e7          	jalr	1876(ra) # 80003978 <iget>
    8000422c:	a011                	j	80004230 <dirlookup+0xa0>
  return 0;
    8000422e:	4501                	li	a0,0
}
    80004230:	70e2                	ld	ra,56(sp)
    80004232:	7442                	ld	s0,48(sp)
    80004234:	74a2                	ld	s1,40(sp)
    80004236:	7902                	ld	s2,32(sp)
    80004238:	69e2                	ld	s3,24(sp)
    8000423a:	6a42                	ld	s4,16(sp)
    8000423c:	6121                	addi	sp,sp,64
    8000423e:	8082                	ret

0000000080004240 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004240:	711d                	addi	sp,sp,-96
    80004242:	ec86                	sd	ra,88(sp)
    80004244:	e8a2                	sd	s0,80(sp)
    80004246:	e4a6                	sd	s1,72(sp)
    80004248:	e0ca                	sd	s2,64(sp)
    8000424a:	fc4e                	sd	s3,56(sp)
    8000424c:	f852                	sd	s4,48(sp)
    8000424e:	f456                	sd	s5,40(sp)
    80004250:	f05a                	sd	s6,32(sp)
    80004252:	ec5e                	sd	s7,24(sp)
    80004254:	e862                	sd	s8,16(sp)
    80004256:	e466                	sd	s9,8(sp)
    80004258:	1080                	addi	s0,sp,96
    8000425a:	84aa                	mv	s1,a0
    8000425c:	8aae                	mv	s5,a1
    8000425e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004260:	00054703          	lbu	a4,0(a0)
    80004264:	02f00793          	li	a5,47
    80004268:	02f70363          	beq	a4,a5,8000428e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000426c:	ffffe097          	auipc	ra,0xffffe
    80004270:	ce4080e7          	jalr	-796(ra) # 80001f50 <myproc>
    80004274:	15053503          	ld	a0,336(a0)
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	9f6080e7          	jalr	-1546(ra) # 80003c6e <idup>
    80004280:	89aa                	mv	s3,a0
  while(*path == '/')
    80004282:	02f00913          	li	s2,47
  len = path - s;
    80004286:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004288:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000428a:	4b85                	li	s7,1
    8000428c:	a865                	j	80004344 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000428e:	4585                	li	a1,1
    80004290:	4505                	li	a0,1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	6e6080e7          	jalr	1766(ra) # 80003978 <iget>
    8000429a:	89aa                	mv	s3,a0
    8000429c:	b7dd                	j	80004282 <namex+0x42>
      iunlockput(ip);
    8000429e:	854e                	mv	a0,s3
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	c6e080e7          	jalr	-914(ra) # 80003f0e <iunlockput>
      return 0;
    800042a8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042aa:	854e                	mv	a0,s3
    800042ac:	60e6                	ld	ra,88(sp)
    800042ae:	6446                	ld	s0,80(sp)
    800042b0:	64a6                	ld	s1,72(sp)
    800042b2:	6906                	ld	s2,64(sp)
    800042b4:	79e2                	ld	s3,56(sp)
    800042b6:	7a42                	ld	s4,48(sp)
    800042b8:	7aa2                	ld	s5,40(sp)
    800042ba:	7b02                	ld	s6,32(sp)
    800042bc:	6be2                	ld	s7,24(sp)
    800042be:	6c42                	ld	s8,16(sp)
    800042c0:	6ca2                	ld	s9,8(sp)
    800042c2:	6125                	addi	sp,sp,96
    800042c4:	8082                	ret
      iunlock(ip);
    800042c6:	854e                	mv	a0,s3
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	aa6080e7          	jalr	-1370(ra) # 80003d6e <iunlock>
      return ip;
    800042d0:	bfe9                	j	800042aa <namex+0x6a>
      iunlockput(ip);
    800042d2:	854e                	mv	a0,s3
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	c3a080e7          	jalr	-966(ra) # 80003f0e <iunlockput>
      return 0;
    800042dc:	89e6                	mv	s3,s9
    800042de:	b7f1                	j	800042aa <namex+0x6a>
  len = path - s;
    800042e0:	40b48633          	sub	a2,s1,a1
    800042e4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800042e8:	099c5463          	bge	s8,s9,80004370 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042ec:	4639                	li	a2,14
    800042ee:	8552                	mv	a0,s4
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	a2a080e7          	jalr	-1494(ra) # 80000d1a <memmove>
  while(*path == '/')
    800042f8:	0004c783          	lbu	a5,0(s1)
    800042fc:	01279763          	bne	a5,s2,8000430a <namex+0xca>
    path++;
    80004300:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004302:	0004c783          	lbu	a5,0(s1)
    80004306:	ff278de3          	beq	a5,s2,80004300 <namex+0xc0>
    ilock(ip);
    8000430a:	854e                	mv	a0,s3
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	9a0080e7          	jalr	-1632(ra) # 80003cac <ilock>
    if(ip->type != T_DIR){
    80004314:	04499783          	lh	a5,68(s3)
    80004318:	f97793e3          	bne	a5,s7,8000429e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000431c:	000a8563          	beqz	s5,80004326 <namex+0xe6>
    80004320:	0004c783          	lbu	a5,0(s1)
    80004324:	d3cd                	beqz	a5,800042c6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004326:	865a                	mv	a2,s6
    80004328:	85d2                	mv	a1,s4
    8000432a:	854e                	mv	a0,s3
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	e64080e7          	jalr	-412(ra) # 80004190 <dirlookup>
    80004334:	8caa                	mv	s9,a0
    80004336:	dd51                	beqz	a0,800042d2 <namex+0x92>
    iunlockput(ip);
    80004338:	854e                	mv	a0,s3
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	bd4080e7          	jalr	-1068(ra) # 80003f0e <iunlockput>
    ip = next;
    80004342:	89e6                	mv	s3,s9
  while(*path == '/')
    80004344:	0004c783          	lbu	a5,0(s1)
    80004348:	05279763          	bne	a5,s2,80004396 <namex+0x156>
    path++;
    8000434c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000434e:	0004c783          	lbu	a5,0(s1)
    80004352:	ff278de3          	beq	a5,s2,8000434c <namex+0x10c>
  if(*path == 0)
    80004356:	c79d                	beqz	a5,80004384 <namex+0x144>
    path++;
    80004358:	85a6                	mv	a1,s1
  len = path - s;
    8000435a:	8cda                	mv	s9,s6
    8000435c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000435e:	01278963          	beq	a5,s2,80004370 <namex+0x130>
    80004362:	dfbd                	beqz	a5,800042e0 <namex+0xa0>
    path++;
    80004364:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	ff279ce3          	bne	a5,s2,80004362 <namex+0x122>
    8000436e:	bf8d                	j	800042e0 <namex+0xa0>
    memmove(name, s, len);
    80004370:	2601                	sext.w	a2,a2
    80004372:	8552                	mv	a0,s4
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	9a6080e7          	jalr	-1626(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000437c:	9cd2                	add	s9,s9,s4
    8000437e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004382:	bf9d                	j	800042f8 <namex+0xb8>
  if(nameiparent){
    80004384:	f20a83e3          	beqz	s5,800042aa <namex+0x6a>
    iput(ip);
    80004388:	854e                	mv	a0,s3
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	adc080e7          	jalr	-1316(ra) # 80003e66 <iput>
    return 0;
    80004392:	4981                	li	s3,0
    80004394:	bf19                	j	800042aa <namex+0x6a>
  if(*path == 0)
    80004396:	d7fd                	beqz	a5,80004384 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004398:	0004c783          	lbu	a5,0(s1)
    8000439c:	85a6                	mv	a1,s1
    8000439e:	b7d1                	j	80004362 <namex+0x122>

00000000800043a0 <dirlink>:
{
    800043a0:	7139                	addi	sp,sp,-64
    800043a2:	fc06                	sd	ra,56(sp)
    800043a4:	f822                	sd	s0,48(sp)
    800043a6:	f426                	sd	s1,40(sp)
    800043a8:	f04a                	sd	s2,32(sp)
    800043aa:	ec4e                	sd	s3,24(sp)
    800043ac:	e852                	sd	s4,16(sp)
    800043ae:	0080                	addi	s0,sp,64
    800043b0:	892a                	mv	s2,a0
    800043b2:	8a2e                	mv	s4,a1
    800043b4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043b6:	4601                	li	a2,0
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	dd8080e7          	jalr	-552(ra) # 80004190 <dirlookup>
    800043c0:	e93d                	bnez	a0,80004436 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c2:	04c92483          	lw	s1,76(s2)
    800043c6:	c49d                	beqz	s1,800043f4 <dirlink+0x54>
    800043c8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ca:	4741                	li	a4,16
    800043cc:	86a6                	mv	a3,s1
    800043ce:	fc040613          	addi	a2,s0,-64
    800043d2:	4581                	li	a1,0
    800043d4:	854a                	mv	a0,s2
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	b8a080e7          	jalr	-1142(ra) # 80003f60 <readi>
    800043de:	47c1                	li	a5,16
    800043e0:	06f51163          	bne	a0,a5,80004442 <dirlink+0xa2>
    if(de.inum == 0)
    800043e4:	fc045783          	lhu	a5,-64(s0)
    800043e8:	c791                	beqz	a5,800043f4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ea:	24c1                	addiw	s1,s1,16
    800043ec:	04c92783          	lw	a5,76(s2)
    800043f0:	fcf4ede3          	bltu	s1,a5,800043ca <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043f4:	4639                	li	a2,14
    800043f6:	85d2                	mv	a1,s4
    800043f8:	fc240513          	addi	a0,s0,-62
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	9d6080e7          	jalr	-1578(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004404:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004408:	4741                	li	a4,16
    8000440a:	86a6                	mv	a3,s1
    8000440c:	fc040613          	addi	a2,s0,-64
    80004410:	4581                	li	a1,0
    80004412:	854a                	mv	a0,s2
    80004414:	00000097          	auipc	ra,0x0
    80004418:	c44080e7          	jalr	-956(ra) # 80004058 <writei>
    8000441c:	872a                	mv	a4,a0
    8000441e:	47c1                	li	a5,16
  return 0;
    80004420:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004422:	02f71863          	bne	a4,a5,80004452 <dirlink+0xb2>
}
    80004426:	70e2                	ld	ra,56(sp)
    80004428:	7442                	ld	s0,48(sp)
    8000442a:	74a2                	ld	s1,40(sp)
    8000442c:	7902                	ld	s2,32(sp)
    8000442e:	69e2                	ld	s3,24(sp)
    80004430:	6a42                	ld	s4,16(sp)
    80004432:	6121                	addi	sp,sp,64
    80004434:	8082                	ret
    iput(ip);
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	a30080e7          	jalr	-1488(ra) # 80003e66 <iput>
    return -1;
    8000443e:	557d                	li	a0,-1
    80004440:	b7dd                	j	80004426 <dirlink+0x86>
      panic("dirlink read");
    80004442:	00004517          	auipc	a0,0x4
    80004446:	1ee50513          	addi	a0,a0,494 # 80008630 <syscalls+0x1c8>
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	0e0080e7          	jalr	224(ra) # 8000052a <panic>
    panic("dirlink");
    80004452:	00004517          	auipc	a0,0x4
    80004456:	36650513          	addi	a0,a0,870 # 800087b8 <syscalls+0x350>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	0d0080e7          	jalr	208(ra) # 8000052a <panic>

0000000080004462 <namei>:

struct inode*
namei(char *path)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000446a:	fe040613          	addi	a2,s0,-32
    8000446e:	4581                	li	a1,0
    80004470:	00000097          	auipc	ra,0x0
    80004474:	dd0080e7          	jalr	-560(ra) # 80004240 <namex>
}
    80004478:	60e2                	ld	ra,24(sp)
    8000447a:	6442                	ld	s0,16(sp)
    8000447c:	6105                	addi	sp,sp,32
    8000447e:	8082                	ret

0000000080004480 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004480:	1141                	addi	sp,sp,-16
    80004482:	e406                	sd	ra,8(sp)
    80004484:	e022                	sd	s0,0(sp)
    80004486:	0800                	addi	s0,sp,16
    80004488:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000448a:	4585                	li	a1,1
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	db4080e7          	jalr	-588(ra) # 80004240 <namex>
}
    80004494:	60a2                	ld	ra,8(sp)
    80004496:	6402                	ld	s0,0(sp)
    80004498:	0141                	addi	sp,sp,16
    8000449a:	8082                	ret

000000008000449c <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec22                	sd	s0,24(sp)
    800044a0:	1000                	addi	s0,sp,32
    800044a2:	872a                	mv	a4,a0
    800044a4:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800044a6:	00004797          	auipc	a5,0x4
    800044aa:	19a78793          	addi	a5,a5,410 # 80008640 <syscalls+0x1d8>
    800044ae:	6394                	ld	a3,0(a5)
    800044b0:	fed43023          	sd	a3,-32(s0)
    800044b4:	0087d683          	lhu	a3,8(a5)
    800044b8:	fed41423          	sh	a3,-24(s0)
    800044bc:	00a7c783          	lbu	a5,10(a5)
    800044c0:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800044c4:	87ae                	mv	a5,a1
    if(i<0){
    800044c6:	02074b63          	bltz	a4,800044fc <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800044ca:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800044cc:	4629                	li	a2,10
        ++p;
    800044ce:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800044d0:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800044d4:	feed                	bnez	a3,800044ce <itoa+0x32>
    *p = '\0';
    800044d6:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800044da:	4629                	li	a2,10
    800044dc:	17fd                	addi	a5,a5,-1
    800044de:	02c766bb          	remw	a3,a4,a2
    800044e2:	ff040593          	addi	a1,s0,-16
    800044e6:	96ae                	add	a3,a3,a1
    800044e8:	ff06c683          	lbu	a3,-16(a3)
    800044ec:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800044f0:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800044f4:	f765                	bnez	a4,800044dc <itoa+0x40>
    return b;
}
    800044f6:	6462                	ld	s0,24(sp)
    800044f8:	6105                	addi	sp,sp,32
    800044fa:	8082                	ret
        *p++ = '-';
    800044fc:	00158793          	addi	a5,a1,1
    80004500:	02d00693          	li	a3,45
    80004504:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004508:	40e0073b          	negw	a4,a4
    8000450c:	bf7d                	j	800044ca <itoa+0x2e>

000000008000450e <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000450e:	711d                	addi	sp,sp,-96
    80004510:	ec86                	sd	ra,88(sp)
    80004512:	e8a2                	sd	s0,80(sp)
    80004514:	e4a6                	sd	s1,72(sp)
    80004516:	e0ca                	sd	s2,64(sp)
    80004518:	1080                	addi	s0,sp,96
    8000451a:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000451c:	4619                	li	a2,6
    8000451e:	00004597          	auipc	a1,0x4
    80004522:	13258593          	addi	a1,a1,306 # 80008650 <syscalls+0x1e8>
    80004526:	fd040513          	addi	a0,s0,-48
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	7f0080e7          	jalr	2032(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004532:	fd640593          	addi	a1,s0,-42
    80004536:	5888                	lw	a0,48(s1)
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	f64080e7          	jalr	-156(ra) # 8000449c <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004540:	1684b503          	ld	a0,360(s1)
    80004544:	16050763          	beqz	a0,800046b2 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004548:	00001097          	auipc	ra,0x1
    8000454c:	918080e7          	jalr	-1768(ra) # 80004e60 <fileclose>

  begin_op();
    80004550:	00000097          	auipc	ra,0x0
    80004554:	444080e7          	jalr	1092(ra) # 80004994 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004558:	fb040593          	addi	a1,s0,-80
    8000455c:	fd040513          	addi	a0,s0,-48
    80004560:	00000097          	auipc	ra,0x0
    80004564:	f20080e7          	jalr	-224(ra) # 80004480 <nameiparent>
    80004568:	892a                	mv	s2,a0
    8000456a:	cd69                	beqz	a0,80004644 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	740080e7          	jalr	1856(ra) # 80003cac <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004574:	00004597          	auipc	a1,0x4
    80004578:	0e458593          	addi	a1,a1,228 # 80008658 <syscalls+0x1f0>
    8000457c:	fb040513          	addi	a0,s0,-80
    80004580:	00000097          	auipc	ra,0x0
    80004584:	bf6080e7          	jalr	-1034(ra) # 80004176 <namecmp>
    80004588:	c57d                	beqz	a0,80004676 <removeSwapFile+0x168>
    8000458a:	00004597          	auipc	a1,0x4
    8000458e:	0d658593          	addi	a1,a1,214 # 80008660 <syscalls+0x1f8>
    80004592:	fb040513          	addi	a0,s0,-80
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	be0080e7          	jalr	-1056(ra) # 80004176 <namecmp>
    8000459e:	cd61                	beqz	a0,80004676 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800045a0:	fac40613          	addi	a2,s0,-84
    800045a4:	fb040593          	addi	a1,s0,-80
    800045a8:	854a                	mv	a0,s2
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	be6080e7          	jalr	-1050(ra) # 80004190 <dirlookup>
    800045b2:	84aa                	mv	s1,a0
    800045b4:	c169                	beqz	a0,80004676 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	6f6080e7          	jalr	1782(ra) # 80003cac <ilock>

  if(ip->nlink < 1)
    800045be:	04a49783          	lh	a5,74(s1)
    800045c2:	08f05763          	blez	a5,80004650 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800045c6:	04449703          	lh	a4,68(s1)
    800045ca:	4785                	li	a5,1
    800045cc:	08f70a63          	beq	a4,a5,80004660 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800045d0:	4641                	li	a2,16
    800045d2:	4581                	li	a1,0
    800045d4:	fc040513          	addi	a0,s0,-64
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6e6080e7          	jalr	1766(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045e0:	4741                	li	a4,16
    800045e2:	fac42683          	lw	a3,-84(s0)
    800045e6:	fc040613          	addi	a2,s0,-64
    800045ea:	4581                	li	a1,0
    800045ec:	854a                	mv	a0,s2
    800045ee:	00000097          	auipc	ra,0x0
    800045f2:	a6a080e7          	jalr	-1430(ra) # 80004058 <writei>
    800045f6:	47c1                	li	a5,16
    800045f8:	08f51a63          	bne	a0,a5,8000468c <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800045fc:	04449703          	lh	a4,68(s1)
    80004600:	4785                	li	a5,1
    80004602:	08f70d63          	beq	a4,a5,8000469c <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004606:	854a                	mv	a0,s2
    80004608:	00000097          	auipc	ra,0x0
    8000460c:	906080e7          	jalr	-1786(ra) # 80003f0e <iunlockput>

  ip->nlink--;
    80004610:	04a4d783          	lhu	a5,74(s1)
    80004614:	37fd                	addiw	a5,a5,-1
    80004616:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000461a:	8526                	mv	a0,s1
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	5c6080e7          	jalr	1478(ra) # 80003be2 <iupdate>
  iunlockput(ip);
    80004624:	8526                	mv	a0,s1
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	8e8080e7          	jalr	-1816(ra) # 80003f0e <iunlockput>

  end_op();
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	3e6080e7          	jalr	998(ra) # 80004a14 <end_op>

  return 0;
    80004636:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004638:	60e6                	ld	ra,88(sp)
    8000463a:	6446                	ld	s0,80(sp)
    8000463c:	64a6                	ld	s1,72(sp)
    8000463e:	6906                	ld	s2,64(sp)
    80004640:	6125                	addi	sp,sp,96
    80004642:	8082                	ret
    end_op();
    80004644:	00000097          	auipc	ra,0x0
    80004648:	3d0080e7          	jalr	976(ra) # 80004a14 <end_op>
    return -1;
    8000464c:	557d                	li	a0,-1
    8000464e:	b7ed                	j	80004638 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004650:	00004517          	auipc	a0,0x4
    80004654:	01850513          	addi	a0,a0,24 # 80008668 <syscalls+0x200>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	ed2080e7          	jalr	-302(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004660:	8526                	mv	a0,s1
    80004662:	00001097          	auipc	ra,0x1
    80004666:	7fa080e7          	jalr	2042(ra) # 80005e5c <isdirempty>
    8000466a:	f13d                	bnez	a0,800045d0 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000466c:	8526                	mv	a0,s1
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	8a0080e7          	jalr	-1888(ra) # 80003f0e <iunlockput>
    iunlockput(dp);
    80004676:	854a                	mv	a0,s2
    80004678:	00000097          	auipc	ra,0x0
    8000467c:	896080e7          	jalr	-1898(ra) # 80003f0e <iunlockput>
    end_op();
    80004680:	00000097          	auipc	ra,0x0
    80004684:	394080e7          	jalr	916(ra) # 80004a14 <end_op>
    return -1;
    80004688:	557d                	li	a0,-1
    8000468a:	b77d                	j	80004638 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000468c:	00004517          	auipc	a0,0x4
    80004690:	ff450513          	addi	a0,a0,-12 # 80008680 <syscalls+0x218>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	e96080e7          	jalr	-362(ra) # 8000052a <panic>
    dp->nlink--;
    8000469c:	04a95783          	lhu	a5,74(s2)
    800046a0:	37fd                	addiw	a5,a5,-1
    800046a2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800046a6:	854a                	mv	a0,s2
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	53a080e7          	jalr	1338(ra) # 80003be2 <iupdate>
    800046b0:	bf99                	j	80004606 <removeSwapFile+0xf8>
    return -1;
    800046b2:	557d                	li	a0,-1
    800046b4:	b751                	j	80004638 <removeSwapFile+0x12a>

00000000800046b6 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800046b6:	7179                	addi	sp,sp,-48
    800046b8:	f406                	sd	ra,40(sp)
    800046ba:	f022                	sd	s0,32(sp)
    800046bc:	ec26                	sd	s1,24(sp)
    800046be:	e84a                	sd	s2,16(sp)
    800046c0:	1800                	addi	s0,sp,48
    800046c2:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800046c4:	4619                	li	a2,6
    800046c6:	00004597          	auipc	a1,0x4
    800046ca:	f8a58593          	addi	a1,a1,-118 # 80008650 <syscalls+0x1e8>
    800046ce:	fd040513          	addi	a0,s0,-48
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	648080e7          	jalr	1608(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800046da:	fd640593          	addi	a1,s0,-42
    800046de:	5888                	lw	a0,48(s1)
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	dbc080e7          	jalr	-580(ra) # 8000449c <itoa>

  begin_op();
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	2ac080e7          	jalr	684(ra) # 80004994 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800046f0:	4681                	li	a3,0
    800046f2:	4601                	li	a2,0
    800046f4:	4589                	li	a1,2
    800046f6:	fd040513          	addi	a0,s0,-48
    800046fa:	00002097          	auipc	ra,0x2
    800046fe:	956080e7          	jalr	-1706(ra) # 80006050 <create>
    80004702:	892a                	mv	s2,a0
  iunlock(in);
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	66a080e7          	jalr	1642(ra) # 80003d6e <iunlock>
  p->swapFile = filealloc();
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	698080e7          	jalr	1688(ra) # 80004da4 <filealloc>
    80004714:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004718:	cd1d                	beqz	a0,80004756 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000471a:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000471e:	1684b703          	ld	a4,360(s1)
    80004722:	4789                	li	a5,2
    80004724:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004726:	1684b703          	ld	a4,360(s1)
    8000472a:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    8000472e:	1684b703          	ld	a4,360(s1)
    80004732:	4685                	li	a3,1
    80004734:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004738:	1684b703          	ld	a4,360(s1)
    8000473c:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004740:	00000097          	auipc	ra,0x0
    80004744:	2d4080e7          	jalr	724(ra) # 80004a14 <end_op>

    return 0;
}
    80004748:	4501                	li	a0,0
    8000474a:	70a2                	ld	ra,40(sp)
    8000474c:	7402                	ld	s0,32(sp)
    8000474e:	64e2                	ld	s1,24(sp)
    80004750:	6942                	ld	s2,16(sp)
    80004752:	6145                	addi	sp,sp,48
    80004754:	8082                	ret
    panic("no slot for files on /store");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	f3a50513          	addi	a0,a0,-198 # 80008690 <syscalls+0x228>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	dcc080e7          	jalr	-564(ra) # 8000052a <panic>

0000000080004766 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004766:	1141                	addi	sp,sp,-16
    80004768:	e406                	sd	ra,8(sp)
    8000476a:	e022                	sd	s0,0(sp)
    8000476c:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000476e:	16853783          	ld	a5,360(a0)
    80004772:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004774:	8636                	mv	a2,a3
    80004776:	16853503          	ld	a0,360(a0)
    8000477a:	00001097          	auipc	ra,0x1
    8000477e:	ad8080e7          	jalr	-1320(ra) # 80005252 <kfilewrite>
}
    80004782:	60a2                	ld	ra,8(sp)
    80004784:	6402                	ld	s0,0(sp)
    80004786:	0141                	addi	sp,sp,16
    80004788:	8082                	ret

000000008000478a <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000478a:	1141                	addi	sp,sp,-16
    8000478c:	e406                	sd	ra,8(sp)
    8000478e:	e022                	sd	s0,0(sp)
    80004790:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004792:	16853783          	ld	a5,360(a0)
    80004796:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004798:	8636                	mv	a2,a3
    8000479a:	16853503          	ld	a0,360(a0)
    8000479e:	00001097          	auipc	ra,0x1
    800047a2:	9f2080e7          	jalr	-1550(ra) # 80005190 <kfileread>
    800047a6:	60a2                	ld	ra,8(sp)
    800047a8:	6402                	ld	s0,0(sp)
    800047aa:	0141                	addi	sp,sp,16
    800047ac:	8082                	ret

00000000800047ae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047ae:	1101                	addi	sp,sp,-32
    800047b0:	ec06                	sd	ra,24(sp)
    800047b2:	e822                	sd	s0,16(sp)
    800047b4:	e426                	sd	s1,8(sp)
    800047b6:	e04a                	sd	s2,0(sp)
    800047b8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047ba:	0002d917          	auipc	s2,0x2d
    800047be:	0b690913          	addi	s2,s2,182 # 80031870 <log>
    800047c2:	01892583          	lw	a1,24(s2)
    800047c6:	02892503          	lw	a0,40(s2)
    800047ca:	fffff097          	auipc	ra,0xfffff
    800047ce:	cde080e7          	jalr	-802(ra) # 800034a8 <bread>
    800047d2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047d4:	02c92683          	lw	a3,44(s2)
    800047d8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047da:	02d05863          	blez	a3,8000480a <write_head+0x5c>
    800047de:	0002d797          	auipc	a5,0x2d
    800047e2:	0c278793          	addi	a5,a5,194 # 800318a0 <log+0x30>
    800047e6:	05c50713          	addi	a4,a0,92
    800047ea:	36fd                	addiw	a3,a3,-1
    800047ec:	02069613          	slli	a2,a3,0x20
    800047f0:	01e65693          	srli	a3,a2,0x1e
    800047f4:	0002d617          	auipc	a2,0x2d
    800047f8:	0b060613          	addi	a2,a2,176 # 800318a4 <log+0x34>
    800047fc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047fe:	4390                	lw	a2,0(a5)
    80004800:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004802:	0791                	addi	a5,a5,4
    80004804:	0711                	addi	a4,a4,4
    80004806:	fed79ce3          	bne	a5,a3,800047fe <write_head+0x50>
  }
  bwrite(buf);
    8000480a:	8526                	mv	a0,s1
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	d8e080e7          	jalr	-626(ra) # 8000359a <bwrite>
  brelse(buf);
    80004814:	8526                	mv	a0,s1
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	dc2080e7          	jalr	-574(ra) # 800035d8 <brelse>
}
    8000481e:	60e2                	ld	ra,24(sp)
    80004820:	6442                	ld	s0,16(sp)
    80004822:	64a2                	ld	s1,8(sp)
    80004824:	6902                	ld	s2,0(sp)
    80004826:	6105                	addi	sp,sp,32
    80004828:	8082                	ret

000000008000482a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000482a:	0002d797          	auipc	a5,0x2d
    8000482e:	0727a783          	lw	a5,114(a5) # 8003189c <log+0x2c>
    80004832:	0af05d63          	blez	a5,800048ec <install_trans+0xc2>
{
    80004836:	7139                	addi	sp,sp,-64
    80004838:	fc06                	sd	ra,56(sp)
    8000483a:	f822                	sd	s0,48(sp)
    8000483c:	f426                	sd	s1,40(sp)
    8000483e:	f04a                	sd	s2,32(sp)
    80004840:	ec4e                	sd	s3,24(sp)
    80004842:	e852                	sd	s4,16(sp)
    80004844:	e456                	sd	s5,8(sp)
    80004846:	e05a                	sd	s6,0(sp)
    80004848:	0080                	addi	s0,sp,64
    8000484a:	8b2a                	mv	s6,a0
    8000484c:	0002da97          	auipc	s5,0x2d
    80004850:	054a8a93          	addi	s5,s5,84 # 800318a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004854:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004856:	0002d997          	auipc	s3,0x2d
    8000485a:	01a98993          	addi	s3,s3,26 # 80031870 <log>
    8000485e:	a00d                	j	80004880 <install_trans+0x56>
    brelse(lbuf);
    80004860:	854a                	mv	a0,s2
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	d76080e7          	jalr	-650(ra) # 800035d8 <brelse>
    brelse(dbuf);
    8000486a:	8526                	mv	a0,s1
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	d6c080e7          	jalr	-660(ra) # 800035d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004874:	2a05                	addiw	s4,s4,1
    80004876:	0a91                	addi	s5,s5,4
    80004878:	02c9a783          	lw	a5,44(s3)
    8000487c:	04fa5e63          	bge	s4,a5,800048d8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004880:	0189a583          	lw	a1,24(s3)
    80004884:	014585bb          	addw	a1,a1,s4
    80004888:	2585                	addiw	a1,a1,1
    8000488a:	0289a503          	lw	a0,40(s3)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	c1a080e7          	jalr	-998(ra) # 800034a8 <bread>
    80004896:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004898:	000aa583          	lw	a1,0(s5)
    8000489c:	0289a503          	lw	a0,40(s3)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	c08080e7          	jalr	-1016(ra) # 800034a8 <bread>
    800048a8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048aa:	40000613          	li	a2,1024
    800048ae:	05890593          	addi	a1,s2,88
    800048b2:	05850513          	addi	a0,a0,88
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	464080e7          	jalr	1124(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800048be:	8526                	mv	a0,s1
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	cda080e7          	jalr	-806(ra) # 8000359a <bwrite>
    if(recovering == 0)
    800048c8:	f80b1ce3          	bnez	s6,80004860 <install_trans+0x36>
      bunpin(dbuf);
    800048cc:	8526                	mv	a0,s1
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	de4080e7          	jalr	-540(ra) # 800036b2 <bunpin>
    800048d6:	b769                	j	80004860 <install_trans+0x36>
}
    800048d8:	70e2                	ld	ra,56(sp)
    800048da:	7442                	ld	s0,48(sp)
    800048dc:	74a2                	ld	s1,40(sp)
    800048de:	7902                	ld	s2,32(sp)
    800048e0:	69e2                	ld	s3,24(sp)
    800048e2:	6a42                	ld	s4,16(sp)
    800048e4:	6aa2                	ld	s5,8(sp)
    800048e6:	6b02                	ld	s6,0(sp)
    800048e8:	6121                	addi	sp,sp,64
    800048ea:	8082                	ret
    800048ec:	8082                	ret

00000000800048ee <initlog>:
{
    800048ee:	7179                	addi	sp,sp,-48
    800048f0:	f406                	sd	ra,40(sp)
    800048f2:	f022                	sd	s0,32(sp)
    800048f4:	ec26                	sd	s1,24(sp)
    800048f6:	e84a                	sd	s2,16(sp)
    800048f8:	e44e                	sd	s3,8(sp)
    800048fa:	1800                	addi	s0,sp,48
    800048fc:	892a                	mv	s2,a0
    800048fe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004900:	0002d497          	auipc	s1,0x2d
    80004904:	f7048493          	addi	s1,s1,-144 # 80031870 <log>
    80004908:	00004597          	auipc	a1,0x4
    8000490c:	da858593          	addi	a1,a1,-600 # 800086b0 <syscalls+0x248>
    80004910:	8526                	mv	a0,s1
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	220080e7          	jalr	544(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000491a:	0149a583          	lw	a1,20(s3)
    8000491e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004920:	0109a783          	lw	a5,16(s3)
    80004924:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004926:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000492a:	854a                	mv	a0,s2
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	b7c080e7          	jalr	-1156(ra) # 800034a8 <bread>
  log.lh.n = lh->n;
    80004934:	4d34                	lw	a3,88(a0)
    80004936:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004938:	02d05663          	blez	a3,80004964 <initlog+0x76>
    8000493c:	05c50793          	addi	a5,a0,92
    80004940:	0002d717          	auipc	a4,0x2d
    80004944:	f6070713          	addi	a4,a4,-160 # 800318a0 <log+0x30>
    80004948:	36fd                	addiw	a3,a3,-1
    8000494a:	02069613          	slli	a2,a3,0x20
    8000494e:	01e65693          	srli	a3,a2,0x1e
    80004952:	06050613          	addi	a2,a0,96
    80004956:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004958:	4390                	lw	a2,0(a5)
    8000495a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000495c:	0791                	addi	a5,a5,4
    8000495e:	0711                	addi	a4,a4,4
    80004960:	fed79ce3          	bne	a5,a3,80004958 <initlog+0x6a>
  brelse(buf);
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	c74080e7          	jalr	-908(ra) # 800035d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000496c:	4505                	li	a0,1
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	ebc080e7          	jalr	-324(ra) # 8000482a <install_trans>
  log.lh.n = 0;
    80004976:	0002d797          	auipc	a5,0x2d
    8000497a:	f207a323          	sw	zero,-218(a5) # 8003189c <log+0x2c>
  write_head(); // clear the log
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	e30080e7          	jalr	-464(ra) # 800047ae <write_head>
}
    80004986:	70a2                	ld	ra,40(sp)
    80004988:	7402                	ld	s0,32(sp)
    8000498a:	64e2                	ld	s1,24(sp)
    8000498c:	6942                	ld	s2,16(sp)
    8000498e:	69a2                	ld	s3,8(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret

0000000080004994 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004994:	1101                	addi	sp,sp,-32
    80004996:	ec06                	sd	ra,24(sp)
    80004998:	e822                	sd	s0,16(sp)
    8000499a:	e426                	sd	s1,8(sp)
    8000499c:	e04a                	sd	s2,0(sp)
    8000499e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800049a0:	0002d517          	auipc	a0,0x2d
    800049a4:	ed050513          	addi	a0,a0,-304 # 80031870 <log>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	21a080e7          	jalr	538(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800049b0:	0002d497          	auipc	s1,0x2d
    800049b4:	ec048493          	addi	s1,s1,-320 # 80031870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049b8:	4979                	li	s2,30
    800049ba:	a039                	j	800049c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800049bc:	85a6                	mv	a1,s1
    800049be:	8526                	mv	a0,s1
    800049c0:	ffffe097          	auipc	ra,0xffffe
    800049c4:	d5c080e7          	jalr	-676(ra) # 8000271c <sleep>
    if(log.committing){
    800049c8:	50dc                	lw	a5,36(s1)
    800049ca:	fbed                	bnez	a5,800049bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049cc:	509c                	lw	a5,32(s1)
    800049ce:	0017871b          	addiw	a4,a5,1
    800049d2:	0007069b          	sext.w	a3,a4
    800049d6:	0027179b          	slliw	a5,a4,0x2
    800049da:	9fb9                	addw	a5,a5,a4
    800049dc:	0017979b          	slliw	a5,a5,0x1
    800049e0:	54d8                	lw	a4,44(s1)
    800049e2:	9fb9                	addw	a5,a5,a4
    800049e4:	00f95963          	bge	s2,a5,800049f6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049e8:	85a6                	mv	a1,s1
    800049ea:	8526                	mv	a0,s1
    800049ec:	ffffe097          	auipc	ra,0xffffe
    800049f0:	d30080e7          	jalr	-720(ra) # 8000271c <sleep>
    800049f4:	bfd1                	j	800049c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049f6:	0002d517          	auipc	a0,0x2d
    800049fa:	e7a50513          	addi	a0,a0,-390 # 80031870 <log>
    800049fe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	276080e7          	jalr	630(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004a08:	60e2                	ld	ra,24(sp)
    80004a0a:	6442                	ld	s0,16(sp)
    80004a0c:	64a2                	ld	s1,8(sp)
    80004a0e:	6902                	ld	s2,0(sp)
    80004a10:	6105                	addi	sp,sp,32
    80004a12:	8082                	ret

0000000080004a14 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a14:	7139                	addi	sp,sp,-64
    80004a16:	fc06                	sd	ra,56(sp)
    80004a18:	f822                	sd	s0,48(sp)
    80004a1a:	f426                	sd	s1,40(sp)
    80004a1c:	f04a                	sd	s2,32(sp)
    80004a1e:	ec4e                	sd	s3,24(sp)
    80004a20:	e852                	sd	s4,16(sp)
    80004a22:	e456                	sd	s5,8(sp)
    80004a24:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a26:	0002d497          	auipc	s1,0x2d
    80004a2a:	e4a48493          	addi	s1,s1,-438 # 80031870 <log>
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	192080e7          	jalr	402(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004a38:	509c                	lw	a5,32(s1)
    80004a3a:	37fd                	addiw	a5,a5,-1
    80004a3c:	0007891b          	sext.w	s2,a5
    80004a40:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a42:	50dc                	lw	a5,36(s1)
    80004a44:	e7b9                	bnez	a5,80004a92 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a46:	04091e63          	bnez	s2,80004aa2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004a4a:	0002d497          	auipc	s1,0x2d
    80004a4e:	e2648493          	addi	s1,s1,-474 # 80031870 <log>
    80004a52:	4785                	li	a5,1
    80004a54:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a56:	8526                	mv	a0,s1
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	21e080e7          	jalr	542(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a60:	54dc                	lw	a5,44(s1)
    80004a62:	06f04763          	bgtz	a5,80004ad0 <end_op+0xbc>
    acquire(&log.lock);
    80004a66:	0002d497          	auipc	s1,0x2d
    80004a6a:	e0a48493          	addi	s1,s1,-502 # 80031870 <log>
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	152080e7          	jalr	338(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004a78:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffe097          	auipc	ra,0xffffe
    80004a82:	e2a080e7          	jalr	-470(ra) # 800028a8 <wakeup>
    release(&log.lock);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	1ee080e7          	jalr	494(ra) # 80000c76 <release>
}
    80004a90:	a03d                	j	80004abe <end_op+0xaa>
    panic("log.committing");
    80004a92:	00004517          	auipc	a0,0x4
    80004a96:	c2650513          	addi	a0,a0,-986 # 800086b8 <syscalls+0x250>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	a90080e7          	jalr	-1392(ra) # 8000052a <panic>
    wakeup(&log);
    80004aa2:	0002d497          	auipc	s1,0x2d
    80004aa6:	dce48493          	addi	s1,s1,-562 # 80031870 <log>
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffe097          	auipc	ra,0xffffe
    80004ab0:	dfc080e7          	jalr	-516(ra) # 800028a8 <wakeup>
  release(&log.lock);
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	1c0080e7          	jalr	448(ra) # 80000c76 <release>
}
    80004abe:	70e2                	ld	ra,56(sp)
    80004ac0:	7442                	ld	s0,48(sp)
    80004ac2:	74a2                	ld	s1,40(sp)
    80004ac4:	7902                	ld	s2,32(sp)
    80004ac6:	69e2                	ld	s3,24(sp)
    80004ac8:	6a42                	ld	s4,16(sp)
    80004aca:	6aa2                	ld	s5,8(sp)
    80004acc:	6121                	addi	sp,sp,64
    80004ace:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad0:	0002da97          	auipc	s5,0x2d
    80004ad4:	dd0a8a93          	addi	s5,s5,-560 # 800318a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ad8:	0002da17          	auipc	s4,0x2d
    80004adc:	d98a0a13          	addi	s4,s4,-616 # 80031870 <log>
    80004ae0:	018a2583          	lw	a1,24(s4)
    80004ae4:	012585bb          	addw	a1,a1,s2
    80004ae8:	2585                	addiw	a1,a1,1
    80004aea:	028a2503          	lw	a0,40(s4)
    80004aee:	fffff097          	auipc	ra,0xfffff
    80004af2:	9ba080e7          	jalr	-1606(ra) # 800034a8 <bread>
    80004af6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004af8:	000aa583          	lw	a1,0(s5)
    80004afc:	028a2503          	lw	a0,40(s4)
    80004b00:	fffff097          	auipc	ra,0xfffff
    80004b04:	9a8080e7          	jalr	-1624(ra) # 800034a8 <bread>
    80004b08:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b0a:	40000613          	li	a2,1024
    80004b0e:	05850593          	addi	a1,a0,88
    80004b12:	05848513          	addi	a0,s1,88
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	204080e7          	jalr	516(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004b1e:	8526                	mv	a0,s1
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	a7a080e7          	jalr	-1414(ra) # 8000359a <bwrite>
    brelse(from);
    80004b28:	854e                	mv	a0,s3
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	aae080e7          	jalr	-1362(ra) # 800035d8 <brelse>
    brelse(to);
    80004b32:	8526                	mv	a0,s1
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	aa4080e7          	jalr	-1372(ra) # 800035d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b3c:	2905                	addiw	s2,s2,1
    80004b3e:	0a91                	addi	s5,s5,4
    80004b40:	02ca2783          	lw	a5,44(s4)
    80004b44:	f8f94ee3          	blt	s2,a5,80004ae0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b48:	00000097          	auipc	ra,0x0
    80004b4c:	c66080e7          	jalr	-922(ra) # 800047ae <write_head>
    install_trans(0); // Now install writes to home locations
    80004b50:	4501                	li	a0,0
    80004b52:	00000097          	auipc	ra,0x0
    80004b56:	cd8080e7          	jalr	-808(ra) # 8000482a <install_trans>
    log.lh.n = 0;
    80004b5a:	0002d797          	auipc	a5,0x2d
    80004b5e:	d407a123          	sw	zero,-702(a5) # 8003189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	c4c080e7          	jalr	-948(ra) # 800047ae <write_head>
    80004b6a:	bdf5                	j	80004a66 <end_op+0x52>

0000000080004b6c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b6c:	1101                	addi	sp,sp,-32
    80004b6e:	ec06                	sd	ra,24(sp)
    80004b70:	e822                	sd	s0,16(sp)
    80004b72:	e426                	sd	s1,8(sp)
    80004b74:	e04a                	sd	s2,0(sp)
    80004b76:	1000                	addi	s0,sp,32
    80004b78:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b7a:	0002d917          	auipc	s2,0x2d
    80004b7e:	cf690913          	addi	s2,s2,-778 # 80031870 <log>
    80004b82:	854a                	mv	a0,s2
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	03e080e7          	jalr	62(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b8c:	02c92603          	lw	a2,44(s2)
    80004b90:	47f5                	li	a5,29
    80004b92:	06c7c563          	blt	a5,a2,80004bfc <log_write+0x90>
    80004b96:	0002d797          	auipc	a5,0x2d
    80004b9a:	cf67a783          	lw	a5,-778(a5) # 8003188c <log+0x1c>
    80004b9e:	37fd                	addiw	a5,a5,-1
    80004ba0:	04f65e63          	bge	a2,a5,80004bfc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ba4:	0002d797          	auipc	a5,0x2d
    80004ba8:	cec7a783          	lw	a5,-788(a5) # 80031890 <log+0x20>
    80004bac:	06f05063          	blez	a5,80004c0c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004bb0:	4781                	li	a5,0
    80004bb2:	06c05563          	blez	a2,80004c1c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bb6:	44cc                	lw	a1,12(s1)
    80004bb8:	0002d717          	auipc	a4,0x2d
    80004bbc:	ce870713          	addi	a4,a4,-792 # 800318a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bc0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bc2:	4314                	lw	a3,0(a4)
    80004bc4:	04b68c63          	beq	a3,a1,80004c1c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004bc8:	2785                	addiw	a5,a5,1
    80004bca:	0711                	addi	a4,a4,4
    80004bcc:	fef61be3          	bne	a2,a5,80004bc2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bd0:	0621                	addi	a2,a2,8
    80004bd2:	060a                	slli	a2,a2,0x2
    80004bd4:	0002d797          	auipc	a5,0x2d
    80004bd8:	c9c78793          	addi	a5,a5,-868 # 80031870 <log>
    80004bdc:	963e                	add	a2,a2,a5
    80004bde:	44dc                	lw	a5,12(s1)
    80004be0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004be2:	8526                	mv	a0,s1
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	a92080e7          	jalr	-1390(ra) # 80003676 <bpin>
    log.lh.n++;
    80004bec:	0002d717          	auipc	a4,0x2d
    80004bf0:	c8470713          	addi	a4,a4,-892 # 80031870 <log>
    80004bf4:	575c                	lw	a5,44(a4)
    80004bf6:	2785                	addiw	a5,a5,1
    80004bf8:	d75c                	sw	a5,44(a4)
    80004bfa:	a835                	j	80004c36 <log_write+0xca>
    panic("too big a transaction");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	acc50513          	addi	a0,a0,-1332 # 800086c8 <syscalls+0x260>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	926080e7          	jalr	-1754(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004c0c:	00004517          	auipc	a0,0x4
    80004c10:	ad450513          	addi	a0,a0,-1324 # 800086e0 <syscalls+0x278>
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	916080e7          	jalr	-1770(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004c1c:	00878713          	addi	a4,a5,8
    80004c20:	00271693          	slli	a3,a4,0x2
    80004c24:	0002d717          	auipc	a4,0x2d
    80004c28:	c4c70713          	addi	a4,a4,-948 # 80031870 <log>
    80004c2c:	9736                	add	a4,a4,a3
    80004c2e:	44d4                	lw	a3,12(s1)
    80004c30:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c32:	faf608e3          	beq	a2,a5,80004be2 <log_write+0x76>
  }
  release(&log.lock);
    80004c36:	0002d517          	auipc	a0,0x2d
    80004c3a:	c3a50513          	addi	a0,a0,-966 # 80031870 <log>
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	038080e7          	jalr	56(ra) # 80000c76 <release>
}
    80004c46:	60e2                	ld	ra,24(sp)
    80004c48:	6442                	ld	s0,16(sp)
    80004c4a:	64a2                	ld	s1,8(sp)
    80004c4c:	6902                	ld	s2,0(sp)
    80004c4e:	6105                	addi	sp,sp,32
    80004c50:	8082                	ret

0000000080004c52 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c52:	1101                	addi	sp,sp,-32
    80004c54:	ec06                	sd	ra,24(sp)
    80004c56:	e822                	sd	s0,16(sp)
    80004c58:	e426                	sd	s1,8(sp)
    80004c5a:	e04a                	sd	s2,0(sp)
    80004c5c:	1000                	addi	s0,sp,32
    80004c5e:	84aa                	mv	s1,a0
    80004c60:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c62:	00004597          	auipc	a1,0x4
    80004c66:	a9e58593          	addi	a1,a1,-1378 # 80008700 <syscalls+0x298>
    80004c6a:	0521                	addi	a0,a0,8
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	ec6080e7          	jalr	-314(ra) # 80000b32 <initlock>
  lk->name = name;
    80004c74:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c78:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c7c:	0204a423          	sw	zero,40(s1)
}
    80004c80:	60e2                	ld	ra,24(sp)
    80004c82:	6442                	ld	s0,16(sp)
    80004c84:	64a2                	ld	s1,8(sp)
    80004c86:	6902                	ld	s2,0(sp)
    80004c88:	6105                	addi	sp,sp,32
    80004c8a:	8082                	ret

0000000080004c8c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c8c:	1101                	addi	sp,sp,-32
    80004c8e:	ec06                	sd	ra,24(sp)
    80004c90:	e822                	sd	s0,16(sp)
    80004c92:	e426                	sd	s1,8(sp)
    80004c94:	e04a                	sd	s2,0(sp)
    80004c96:	1000                	addi	s0,sp,32
    80004c98:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c9a:	00850913          	addi	s2,a0,8
    80004c9e:	854a                	mv	a0,s2
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f22080e7          	jalr	-222(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004ca8:	409c                	lw	a5,0(s1)
    80004caa:	cb89                	beqz	a5,80004cbc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cac:	85ca                	mv	a1,s2
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffe097          	auipc	ra,0xffffe
    80004cb4:	a6c080e7          	jalr	-1428(ra) # 8000271c <sleep>
  while (lk->locked) {
    80004cb8:	409c                	lw	a5,0(s1)
    80004cba:	fbed                	bnez	a5,80004cac <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cbc:	4785                	li	a5,1
    80004cbe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	290080e7          	jalr	656(ra) # 80001f50 <myproc>
    80004cc8:	591c                	lw	a5,48(a0)
    80004cca:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ccc:	854a                	mv	a0,s2
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	fa8080e7          	jalr	-88(ra) # 80000c76 <release>
}
    80004cd6:	60e2                	ld	ra,24(sp)
    80004cd8:	6442                	ld	s0,16(sp)
    80004cda:	64a2                	ld	s1,8(sp)
    80004cdc:	6902                	ld	s2,0(sp)
    80004cde:	6105                	addi	sp,sp,32
    80004ce0:	8082                	ret

0000000080004ce2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ce2:	1101                	addi	sp,sp,-32
    80004ce4:	ec06                	sd	ra,24(sp)
    80004ce6:	e822                	sd	s0,16(sp)
    80004ce8:	e426                	sd	s1,8(sp)
    80004cea:	e04a                	sd	s2,0(sp)
    80004cec:	1000                	addi	s0,sp,32
    80004cee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cf0:	00850913          	addi	s2,a0,8
    80004cf4:	854a                	mv	a0,s2
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	ecc080e7          	jalr	-308(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004cfe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d02:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffe097          	auipc	ra,0xffffe
    80004d0c:	ba0080e7          	jalr	-1120(ra) # 800028a8 <wakeup>
  release(&lk->lk);
    80004d10:	854a                	mv	a0,s2
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	f64080e7          	jalr	-156(ra) # 80000c76 <release>
}
    80004d1a:	60e2                	ld	ra,24(sp)
    80004d1c:	6442                	ld	s0,16(sp)
    80004d1e:	64a2                	ld	s1,8(sp)
    80004d20:	6902                	ld	s2,0(sp)
    80004d22:	6105                	addi	sp,sp,32
    80004d24:	8082                	ret

0000000080004d26 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d26:	7179                	addi	sp,sp,-48
    80004d28:	f406                	sd	ra,40(sp)
    80004d2a:	f022                	sd	s0,32(sp)
    80004d2c:	ec26                	sd	s1,24(sp)
    80004d2e:	e84a                	sd	s2,16(sp)
    80004d30:	e44e                	sd	s3,8(sp)
    80004d32:	1800                	addi	s0,sp,48
    80004d34:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d36:	00850913          	addi	s2,a0,8
    80004d3a:	854a                	mv	a0,s2
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	e86080e7          	jalr	-378(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d44:	409c                	lw	a5,0(s1)
    80004d46:	ef99                	bnez	a5,80004d64 <holdingsleep+0x3e>
    80004d48:	4481                	li	s1,0
  release(&lk->lk);
    80004d4a:	854a                	mv	a0,s2
    80004d4c:	ffffc097          	auipc	ra,0xffffc
    80004d50:	f2a080e7          	jalr	-214(ra) # 80000c76 <release>
  return r;
}
    80004d54:	8526                	mv	a0,s1
    80004d56:	70a2                	ld	ra,40(sp)
    80004d58:	7402                	ld	s0,32(sp)
    80004d5a:	64e2                	ld	s1,24(sp)
    80004d5c:	6942                	ld	s2,16(sp)
    80004d5e:	69a2                	ld	s3,8(sp)
    80004d60:	6145                	addi	sp,sp,48
    80004d62:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d64:	0284a983          	lw	s3,40(s1)
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	1e8080e7          	jalr	488(ra) # 80001f50 <myproc>
    80004d70:	5904                	lw	s1,48(a0)
    80004d72:	413484b3          	sub	s1,s1,s3
    80004d76:	0014b493          	seqz	s1,s1
    80004d7a:	bfc1                	j	80004d4a <holdingsleep+0x24>

0000000080004d7c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d7c:	1141                	addi	sp,sp,-16
    80004d7e:	e406                	sd	ra,8(sp)
    80004d80:	e022                	sd	s0,0(sp)
    80004d82:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d84:	00004597          	auipc	a1,0x4
    80004d88:	98c58593          	addi	a1,a1,-1652 # 80008710 <syscalls+0x2a8>
    80004d8c:	0002d517          	auipc	a0,0x2d
    80004d90:	c2c50513          	addi	a0,a0,-980 # 800319b8 <ftable>
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	d9e080e7          	jalr	-610(ra) # 80000b32 <initlock>
}
    80004d9c:	60a2                	ld	ra,8(sp)
    80004d9e:	6402                	ld	s0,0(sp)
    80004da0:	0141                	addi	sp,sp,16
    80004da2:	8082                	ret

0000000080004da4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004da4:	1101                	addi	sp,sp,-32
    80004da6:	ec06                	sd	ra,24(sp)
    80004da8:	e822                	sd	s0,16(sp)
    80004daa:	e426                	sd	s1,8(sp)
    80004dac:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004dae:	0002d517          	auipc	a0,0x2d
    80004db2:	c0a50513          	addi	a0,a0,-1014 # 800319b8 <ftable>
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	e0c080e7          	jalr	-500(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dbe:	0002d497          	auipc	s1,0x2d
    80004dc2:	c1248493          	addi	s1,s1,-1006 # 800319d0 <ftable+0x18>
    80004dc6:	0002e717          	auipc	a4,0x2e
    80004dca:	baa70713          	addi	a4,a4,-1110 # 80032970 <ftable+0xfb8>
    if(f->ref == 0){
    80004dce:	40dc                	lw	a5,4(s1)
    80004dd0:	cf99                	beqz	a5,80004dee <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dd2:	02848493          	addi	s1,s1,40
    80004dd6:	fee49ce3          	bne	s1,a4,80004dce <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004dda:	0002d517          	auipc	a0,0x2d
    80004dde:	bde50513          	addi	a0,a0,-1058 # 800319b8 <ftable>
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	e94080e7          	jalr	-364(ra) # 80000c76 <release>
  return 0;
    80004dea:	4481                	li	s1,0
    80004dec:	a819                	j	80004e02 <filealloc+0x5e>
      f->ref = 1;
    80004dee:	4785                	li	a5,1
    80004df0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004df2:	0002d517          	auipc	a0,0x2d
    80004df6:	bc650513          	addi	a0,a0,-1082 # 800319b8 <ftable>
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	e7c080e7          	jalr	-388(ra) # 80000c76 <release>
}
    80004e02:	8526                	mv	a0,s1
    80004e04:	60e2                	ld	ra,24(sp)
    80004e06:	6442                	ld	s0,16(sp)
    80004e08:	64a2                	ld	s1,8(sp)
    80004e0a:	6105                	addi	sp,sp,32
    80004e0c:	8082                	ret

0000000080004e0e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e0e:	1101                	addi	sp,sp,-32
    80004e10:	ec06                	sd	ra,24(sp)
    80004e12:	e822                	sd	s0,16(sp)
    80004e14:	e426                	sd	s1,8(sp)
    80004e16:	1000                	addi	s0,sp,32
    80004e18:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e1a:	0002d517          	auipc	a0,0x2d
    80004e1e:	b9e50513          	addi	a0,a0,-1122 # 800319b8 <ftable>
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	da0080e7          	jalr	-608(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004e2a:	40dc                	lw	a5,4(s1)
    80004e2c:	02f05263          	blez	a5,80004e50 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e30:	2785                	addiw	a5,a5,1
    80004e32:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e34:	0002d517          	auipc	a0,0x2d
    80004e38:	b8450513          	addi	a0,a0,-1148 # 800319b8 <ftable>
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	e3a080e7          	jalr	-454(ra) # 80000c76 <release>
  return f;
}
    80004e44:	8526                	mv	a0,s1
    80004e46:	60e2                	ld	ra,24(sp)
    80004e48:	6442                	ld	s0,16(sp)
    80004e4a:	64a2                	ld	s1,8(sp)
    80004e4c:	6105                	addi	sp,sp,32
    80004e4e:	8082                	ret
    panic("filedup");
    80004e50:	00004517          	auipc	a0,0x4
    80004e54:	8c850513          	addi	a0,a0,-1848 # 80008718 <syscalls+0x2b0>
    80004e58:	ffffb097          	auipc	ra,0xffffb
    80004e5c:	6d2080e7          	jalr	1746(ra) # 8000052a <panic>

0000000080004e60 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e60:	7139                	addi	sp,sp,-64
    80004e62:	fc06                	sd	ra,56(sp)
    80004e64:	f822                	sd	s0,48(sp)
    80004e66:	f426                	sd	s1,40(sp)
    80004e68:	f04a                	sd	s2,32(sp)
    80004e6a:	ec4e                	sd	s3,24(sp)
    80004e6c:	e852                	sd	s4,16(sp)
    80004e6e:	e456                	sd	s5,8(sp)
    80004e70:	0080                	addi	s0,sp,64
    80004e72:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e74:	0002d517          	auipc	a0,0x2d
    80004e78:	b4450513          	addi	a0,a0,-1212 # 800319b8 <ftable>
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	d46080e7          	jalr	-698(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004e84:	40dc                	lw	a5,4(s1)
    80004e86:	06f05163          	blez	a5,80004ee8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e8a:	37fd                	addiw	a5,a5,-1
    80004e8c:	0007871b          	sext.w	a4,a5
    80004e90:	c0dc                	sw	a5,4(s1)
    80004e92:	06e04363          	bgtz	a4,80004ef8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e96:	0004a903          	lw	s2,0(s1)
    80004e9a:	0094ca83          	lbu	s5,9(s1)
    80004e9e:	0104ba03          	ld	s4,16(s1)
    80004ea2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ea6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004eaa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004eae:	0002d517          	auipc	a0,0x2d
    80004eb2:	b0a50513          	addi	a0,a0,-1270 # 800319b8 <ftable>
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	dc0080e7          	jalr	-576(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004ebe:	4785                	li	a5,1
    80004ec0:	04f90d63          	beq	s2,a5,80004f1a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ec4:	3979                	addiw	s2,s2,-2
    80004ec6:	4785                	li	a5,1
    80004ec8:	0527e063          	bltu	a5,s2,80004f08 <fileclose+0xa8>
    begin_op();
    80004ecc:	00000097          	auipc	ra,0x0
    80004ed0:	ac8080e7          	jalr	-1336(ra) # 80004994 <begin_op>
    iput(ff.ip);
    80004ed4:	854e                	mv	a0,s3
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	f90080e7          	jalr	-112(ra) # 80003e66 <iput>
    end_op();
    80004ede:	00000097          	auipc	ra,0x0
    80004ee2:	b36080e7          	jalr	-1226(ra) # 80004a14 <end_op>
    80004ee6:	a00d                	j	80004f08 <fileclose+0xa8>
    panic("fileclose");
    80004ee8:	00004517          	auipc	a0,0x4
    80004eec:	83850513          	addi	a0,a0,-1992 # 80008720 <syscalls+0x2b8>
    80004ef0:	ffffb097          	auipc	ra,0xffffb
    80004ef4:	63a080e7          	jalr	1594(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004ef8:	0002d517          	auipc	a0,0x2d
    80004efc:	ac050513          	addi	a0,a0,-1344 # 800319b8 <ftable>
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	d76080e7          	jalr	-650(ra) # 80000c76 <release>
  }
}
    80004f08:	70e2                	ld	ra,56(sp)
    80004f0a:	7442                	ld	s0,48(sp)
    80004f0c:	74a2                	ld	s1,40(sp)
    80004f0e:	7902                	ld	s2,32(sp)
    80004f10:	69e2                	ld	s3,24(sp)
    80004f12:	6a42                	ld	s4,16(sp)
    80004f14:	6aa2                	ld	s5,8(sp)
    80004f16:	6121                	addi	sp,sp,64
    80004f18:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f1a:	85d6                	mv	a1,s5
    80004f1c:	8552                	mv	a0,s4
    80004f1e:	00000097          	auipc	ra,0x0
    80004f22:	542080e7          	jalr	1346(ra) # 80005460 <pipeclose>
    80004f26:	b7cd                	j	80004f08 <fileclose+0xa8>

0000000080004f28 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f28:	715d                	addi	sp,sp,-80
    80004f2a:	e486                	sd	ra,72(sp)
    80004f2c:	e0a2                	sd	s0,64(sp)
    80004f2e:	fc26                	sd	s1,56(sp)
    80004f30:	f84a                	sd	s2,48(sp)
    80004f32:	f44e                	sd	s3,40(sp)
    80004f34:	0880                	addi	s0,sp,80
    80004f36:	84aa                	mv	s1,a0
    80004f38:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	016080e7          	jalr	22(ra) # 80001f50 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f42:	409c                	lw	a5,0(s1)
    80004f44:	37f9                	addiw	a5,a5,-2
    80004f46:	4705                	li	a4,1
    80004f48:	04f76763          	bltu	a4,a5,80004f96 <filestat+0x6e>
    80004f4c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f4e:	6c88                	ld	a0,24(s1)
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	d5c080e7          	jalr	-676(ra) # 80003cac <ilock>
    stati(f->ip, &st);
    80004f58:	fb840593          	addi	a1,s0,-72
    80004f5c:	6c88                	ld	a0,24(s1)
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	fd8080e7          	jalr	-40(ra) # 80003f36 <stati>
    iunlock(f->ip);
    80004f66:	6c88                	ld	a0,24(s1)
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	e06080e7          	jalr	-506(ra) # 80003d6e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f70:	46e1                	li	a3,24
    80004f72:	fb840613          	addi	a2,s0,-72
    80004f76:	85ce                	mv	a1,s3
    80004f78:	05093503          	ld	a0,80(s2)
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	6ec080e7          	jalr	1772(ra) # 80001668 <copyout>
    80004f84:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f88:	60a6                	ld	ra,72(sp)
    80004f8a:	6406                	ld	s0,64(sp)
    80004f8c:	74e2                	ld	s1,56(sp)
    80004f8e:	7942                	ld	s2,48(sp)
    80004f90:	79a2                	ld	s3,40(sp)
    80004f92:	6161                	addi	sp,sp,80
    80004f94:	8082                	ret
  return -1;
    80004f96:	557d                	li	a0,-1
    80004f98:	bfc5                	j	80004f88 <filestat+0x60>

0000000080004f9a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f9a:	7179                	addi	sp,sp,-48
    80004f9c:	f406                	sd	ra,40(sp)
    80004f9e:	f022                	sd	s0,32(sp)
    80004fa0:	ec26                	sd	s1,24(sp)
    80004fa2:	e84a                	sd	s2,16(sp)
    80004fa4:	e44e                	sd	s3,8(sp)
    80004fa6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fa8:	00854783          	lbu	a5,8(a0)
    80004fac:	c3d5                	beqz	a5,80005050 <fileread+0xb6>
    80004fae:	84aa                	mv	s1,a0
    80004fb0:	89ae                	mv	s3,a1
    80004fb2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fb4:	411c                	lw	a5,0(a0)
    80004fb6:	4705                	li	a4,1
    80004fb8:	04e78963          	beq	a5,a4,8000500a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fbc:	470d                	li	a4,3
    80004fbe:	04e78d63          	beq	a5,a4,80005018 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fc2:	4709                	li	a4,2
    80004fc4:	06e79e63          	bne	a5,a4,80005040 <fileread+0xa6>
    ilock(f->ip);
    80004fc8:	6d08                	ld	a0,24(a0)
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	ce2080e7          	jalr	-798(ra) # 80003cac <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fd2:	874a                	mv	a4,s2
    80004fd4:	5094                	lw	a3,32(s1)
    80004fd6:	864e                	mv	a2,s3
    80004fd8:	4585                	li	a1,1
    80004fda:	6c88                	ld	a0,24(s1)
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	f84080e7          	jalr	-124(ra) # 80003f60 <readi>
    80004fe4:	892a                	mv	s2,a0
    80004fe6:	00a05563          	blez	a0,80004ff0 <fileread+0x56>
      f->off += r;
    80004fea:	509c                	lw	a5,32(s1)
    80004fec:	9fa9                	addw	a5,a5,a0
    80004fee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ff0:	6c88                	ld	a0,24(s1)
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	d7c080e7          	jalr	-644(ra) # 80003d6e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	70a2                	ld	ra,40(sp)
    80004ffe:	7402                	ld	s0,32(sp)
    80005000:	64e2                	ld	s1,24(sp)
    80005002:	6942                	ld	s2,16(sp)
    80005004:	69a2                	ld	s3,8(sp)
    80005006:	6145                	addi	sp,sp,48
    80005008:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000500a:	6908                	ld	a0,16(a0)
    8000500c:	00000097          	auipc	ra,0x0
    80005010:	5b6080e7          	jalr	1462(ra) # 800055c2 <piperead>
    80005014:	892a                	mv	s2,a0
    80005016:	b7d5                	j	80004ffa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005018:	02451783          	lh	a5,36(a0)
    8000501c:	03079693          	slli	a3,a5,0x30
    80005020:	92c1                	srli	a3,a3,0x30
    80005022:	4725                	li	a4,9
    80005024:	02d76863          	bltu	a4,a3,80005054 <fileread+0xba>
    80005028:	0792                	slli	a5,a5,0x4
    8000502a:	0002d717          	auipc	a4,0x2d
    8000502e:	8ee70713          	addi	a4,a4,-1810 # 80031918 <devsw>
    80005032:	97ba                	add	a5,a5,a4
    80005034:	639c                	ld	a5,0(a5)
    80005036:	c38d                	beqz	a5,80005058 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005038:	4505                	li	a0,1
    8000503a:	9782                	jalr	a5
    8000503c:	892a                	mv	s2,a0
    8000503e:	bf75                	j	80004ffa <fileread+0x60>
    panic("fileread");
    80005040:	00003517          	auipc	a0,0x3
    80005044:	6f050513          	addi	a0,a0,1776 # 80008730 <syscalls+0x2c8>
    80005048:	ffffb097          	auipc	ra,0xffffb
    8000504c:	4e2080e7          	jalr	1250(ra) # 8000052a <panic>
    return -1;
    80005050:	597d                	li	s2,-1
    80005052:	b765                	j	80004ffa <fileread+0x60>
      return -1;
    80005054:	597d                	li	s2,-1
    80005056:	b755                	j	80004ffa <fileread+0x60>
    80005058:	597d                	li	s2,-1
    8000505a:	b745                	j	80004ffa <fileread+0x60>

000000008000505c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000505c:	715d                	addi	sp,sp,-80
    8000505e:	e486                	sd	ra,72(sp)
    80005060:	e0a2                	sd	s0,64(sp)
    80005062:	fc26                	sd	s1,56(sp)
    80005064:	f84a                	sd	s2,48(sp)
    80005066:	f44e                	sd	s3,40(sp)
    80005068:	f052                	sd	s4,32(sp)
    8000506a:	ec56                	sd	s5,24(sp)
    8000506c:	e85a                	sd	s6,16(sp)
    8000506e:	e45e                	sd	s7,8(sp)
    80005070:	e062                	sd	s8,0(sp)
    80005072:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005074:	00954783          	lbu	a5,9(a0)
    80005078:	10078663          	beqz	a5,80005184 <filewrite+0x128>
    8000507c:	892a                	mv	s2,a0
    8000507e:	8aae                	mv	s5,a1
    80005080:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005082:	411c                	lw	a5,0(a0)
    80005084:	4705                	li	a4,1
    80005086:	02e78263          	beq	a5,a4,800050aa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000508a:	470d                	li	a4,3
    8000508c:	02e78663          	beq	a5,a4,800050b8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005090:	4709                	li	a4,2
    80005092:	0ee79163          	bne	a5,a4,80005174 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005096:	0ac05d63          	blez	a2,80005150 <filewrite+0xf4>
    int i = 0;
    8000509a:	4981                	li	s3,0
    8000509c:	6b05                	lui	s6,0x1
    8000509e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050a2:	6b85                	lui	s7,0x1
    800050a4:	c00b8b9b          	addiw	s7,s7,-1024
    800050a8:	a861                	j	80005140 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050aa:	6908                	ld	a0,16(a0)
    800050ac:	00000097          	auipc	ra,0x0
    800050b0:	424080e7          	jalr	1060(ra) # 800054d0 <pipewrite>
    800050b4:	8a2a                	mv	s4,a0
    800050b6:	a045                	j	80005156 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050b8:	02451783          	lh	a5,36(a0)
    800050bc:	03079693          	slli	a3,a5,0x30
    800050c0:	92c1                	srli	a3,a3,0x30
    800050c2:	4725                	li	a4,9
    800050c4:	0cd76263          	bltu	a4,a3,80005188 <filewrite+0x12c>
    800050c8:	0792                	slli	a5,a5,0x4
    800050ca:	0002d717          	auipc	a4,0x2d
    800050ce:	84e70713          	addi	a4,a4,-1970 # 80031918 <devsw>
    800050d2:	97ba                	add	a5,a5,a4
    800050d4:	679c                	ld	a5,8(a5)
    800050d6:	cbdd                	beqz	a5,8000518c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050d8:	4505                	li	a0,1
    800050da:	9782                	jalr	a5
    800050dc:	8a2a                	mv	s4,a0
    800050de:	a8a5                	j	80005156 <filewrite+0xfa>
    800050e0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050e4:	00000097          	auipc	ra,0x0
    800050e8:	8b0080e7          	jalr	-1872(ra) # 80004994 <begin_op>
      ilock(f->ip);
    800050ec:	01893503          	ld	a0,24(s2)
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	bbc080e7          	jalr	-1092(ra) # 80003cac <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050f8:	8762                	mv	a4,s8
    800050fa:	02092683          	lw	a3,32(s2)
    800050fe:	01598633          	add	a2,s3,s5
    80005102:	4585                	li	a1,1
    80005104:	01893503          	ld	a0,24(s2)
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	f50080e7          	jalr	-176(ra) # 80004058 <writei>
    80005110:	84aa                	mv	s1,a0
    80005112:	00a05763          	blez	a0,80005120 <filewrite+0xc4>
        f->off += r;
    80005116:	02092783          	lw	a5,32(s2)
    8000511a:	9fa9                	addw	a5,a5,a0
    8000511c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005120:	01893503          	ld	a0,24(s2)
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	c4a080e7          	jalr	-950(ra) # 80003d6e <iunlock>
      end_op();
    8000512c:	00000097          	auipc	ra,0x0
    80005130:	8e8080e7          	jalr	-1816(ra) # 80004a14 <end_op>

      if(r != n1){
    80005134:	009c1f63          	bne	s8,s1,80005152 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005138:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000513c:	0149db63          	bge	s3,s4,80005152 <filewrite+0xf6>
      int n1 = n - i;
    80005140:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005144:	84be                	mv	s1,a5
    80005146:	2781                	sext.w	a5,a5
    80005148:	f8fb5ce3          	bge	s6,a5,800050e0 <filewrite+0x84>
    8000514c:	84de                	mv	s1,s7
    8000514e:	bf49                	j	800050e0 <filewrite+0x84>
    int i = 0;
    80005150:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005152:	013a1f63          	bne	s4,s3,80005170 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005156:	8552                	mv	a0,s4
    80005158:	60a6                	ld	ra,72(sp)
    8000515a:	6406                	ld	s0,64(sp)
    8000515c:	74e2                	ld	s1,56(sp)
    8000515e:	7942                	ld	s2,48(sp)
    80005160:	79a2                	ld	s3,40(sp)
    80005162:	7a02                	ld	s4,32(sp)
    80005164:	6ae2                	ld	s5,24(sp)
    80005166:	6b42                	ld	s6,16(sp)
    80005168:	6ba2                	ld	s7,8(sp)
    8000516a:	6c02                	ld	s8,0(sp)
    8000516c:	6161                	addi	sp,sp,80
    8000516e:	8082                	ret
    ret = (i == n ? n : -1);
    80005170:	5a7d                	li	s4,-1
    80005172:	b7d5                	j	80005156 <filewrite+0xfa>
    panic("filewrite");
    80005174:	00003517          	auipc	a0,0x3
    80005178:	5cc50513          	addi	a0,a0,1484 # 80008740 <syscalls+0x2d8>
    8000517c:	ffffb097          	auipc	ra,0xffffb
    80005180:	3ae080e7          	jalr	942(ra) # 8000052a <panic>
    return -1;
    80005184:	5a7d                	li	s4,-1
    80005186:	bfc1                	j	80005156 <filewrite+0xfa>
      return -1;
    80005188:	5a7d                	li	s4,-1
    8000518a:	b7f1                	j	80005156 <filewrite+0xfa>
    8000518c:	5a7d                	li	s4,-1
    8000518e:	b7e1                	j	80005156 <filewrite+0xfa>

0000000080005190 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005190:	7179                	addi	sp,sp,-48
    80005192:	f406                	sd	ra,40(sp)
    80005194:	f022                	sd	s0,32(sp)
    80005196:	ec26                	sd	s1,24(sp)
    80005198:	e84a                	sd	s2,16(sp)
    8000519a:	e44e                	sd	s3,8(sp)
    8000519c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000519e:	00854783          	lbu	a5,8(a0)
    800051a2:	c3d5                	beqz	a5,80005246 <kfileread+0xb6>
    800051a4:	84aa                	mv	s1,a0
    800051a6:	89ae                	mv	s3,a1
    800051a8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800051aa:	411c                	lw	a5,0(a0)
    800051ac:	4705                	li	a4,1
    800051ae:	04e78963          	beq	a5,a4,80005200 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051b2:	470d                	li	a4,3
    800051b4:	04e78d63          	beq	a5,a4,8000520e <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051b8:	4709                	li	a4,2
    800051ba:	06e79e63          	bne	a5,a4,80005236 <kfileread+0xa6>
    ilock(f->ip);
    800051be:	6d08                	ld	a0,24(a0)
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	aec080e7          	jalr	-1300(ra) # 80003cac <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800051c8:	874a                	mv	a4,s2
    800051ca:	5094                	lw	a3,32(s1)
    800051cc:	864e                	mv	a2,s3
    800051ce:	4581                	li	a1,0
    800051d0:	6c88                	ld	a0,24(s1)
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	d8e080e7          	jalr	-626(ra) # 80003f60 <readi>
    800051da:	892a                	mv	s2,a0
    800051dc:	00a05563          	blez	a0,800051e6 <kfileread+0x56>
      f->off += r;
    800051e0:	509c                	lw	a5,32(s1)
    800051e2:	9fa9                	addw	a5,a5,a0
    800051e4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051e6:	6c88                	ld	a0,24(s1)
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	b86080e7          	jalr	-1146(ra) # 80003d6e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051f0:	854a                	mv	a0,s2
    800051f2:	70a2                	ld	ra,40(sp)
    800051f4:	7402                	ld	s0,32(sp)
    800051f6:	64e2                	ld	s1,24(sp)
    800051f8:	6942                	ld	s2,16(sp)
    800051fa:	69a2                	ld	s3,8(sp)
    800051fc:	6145                	addi	sp,sp,48
    800051fe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005200:	6908                	ld	a0,16(a0)
    80005202:	00000097          	auipc	ra,0x0
    80005206:	3c0080e7          	jalr	960(ra) # 800055c2 <piperead>
    8000520a:	892a                	mv	s2,a0
    8000520c:	b7d5                	j	800051f0 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000520e:	02451783          	lh	a5,36(a0)
    80005212:	03079693          	slli	a3,a5,0x30
    80005216:	92c1                	srli	a3,a3,0x30
    80005218:	4725                	li	a4,9
    8000521a:	02d76863          	bltu	a4,a3,8000524a <kfileread+0xba>
    8000521e:	0792                	slli	a5,a5,0x4
    80005220:	0002c717          	auipc	a4,0x2c
    80005224:	6f870713          	addi	a4,a4,1784 # 80031918 <devsw>
    80005228:	97ba                	add	a5,a5,a4
    8000522a:	639c                	ld	a5,0(a5)
    8000522c:	c38d                	beqz	a5,8000524e <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000522e:	4505                	li	a0,1
    80005230:	9782                	jalr	a5
    80005232:	892a                	mv	s2,a0
    80005234:	bf75                	j	800051f0 <kfileread+0x60>
    panic("fileread");
    80005236:	00003517          	auipc	a0,0x3
    8000523a:	4fa50513          	addi	a0,a0,1274 # 80008730 <syscalls+0x2c8>
    8000523e:	ffffb097          	auipc	ra,0xffffb
    80005242:	2ec080e7          	jalr	748(ra) # 8000052a <panic>
    return -1;
    80005246:	597d                	li	s2,-1
    80005248:	b765                	j	800051f0 <kfileread+0x60>
      return -1;
    8000524a:	597d                	li	s2,-1
    8000524c:	b755                	j	800051f0 <kfileread+0x60>
    8000524e:	597d                	li	s2,-1
    80005250:	b745                	j	800051f0 <kfileread+0x60>

0000000080005252 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005252:	715d                	addi	sp,sp,-80
    80005254:	e486                	sd	ra,72(sp)
    80005256:	e0a2                	sd	s0,64(sp)
    80005258:	fc26                	sd	s1,56(sp)
    8000525a:	f84a                	sd	s2,48(sp)
    8000525c:	f44e                	sd	s3,40(sp)
    8000525e:	f052                	sd	s4,32(sp)
    80005260:	ec56                	sd	s5,24(sp)
    80005262:	e85a                	sd	s6,16(sp)
    80005264:	e45e                	sd	s7,8(sp)
    80005266:	e062                	sd	s8,0(sp)
    80005268:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000526a:	00954783          	lbu	a5,9(a0)
    8000526e:	10078663          	beqz	a5,8000537a <kfilewrite+0x128>
    80005272:	892a                	mv	s2,a0
    80005274:	8aae                	mv	s5,a1
    80005276:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005278:	411c                	lw	a5,0(a0)
    8000527a:	4705                	li	a4,1
    8000527c:	02e78263          	beq	a5,a4,800052a0 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005280:	470d                	li	a4,3
    80005282:	02e78663          	beq	a5,a4,800052ae <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005286:	4709                	li	a4,2
    80005288:	0ee79163          	bne	a5,a4,8000536a <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000528c:	0ac05d63          	blez	a2,80005346 <kfilewrite+0xf4>
    int i = 0;
    80005290:	4981                	li	s3,0
    80005292:	6b05                	lui	s6,0x1
    80005294:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005298:	6b85                	lui	s7,0x1
    8000529a:	c00b8b9b          	addiw	s7,s7,-1024
    8000529e:	a861                	j	80005336 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052a0:	6908                	ld	a0,16(a0)
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	22e080e7          	jalr	558(ra) # 800054d0 <pipewrite>
    800052aa:	8a2a                	mv	s4,a0
    800052ac:	a045                	j	8000534c <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052ae:	02451783          	lh	a5,36(a0)
    800052b2:	03079693          	slli	a3,a5,0x30
    800052b6:	92c1                	srli	a3,a3,0x30
    800052b8:	4725                	li	a4,9
    800052ba:	0cd76263          	bltu	a4,a3,8000537e <kfilewrite+0x12c>
    800052be:	0792                	slli	a5,a5,0x4
    800052c0:	0002c717          	auipc	a4,0x2c
    800052c4:	65870713          	addi	a4,a4,1624 # 80031918 <devsw>
    800052c8:	97ba                	add	a5,a5,a4
    800052ca:	679c                	ld	a5,8(a5)
    800052cc:	cbdd                	beqz	a5,80005382 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800052ce:	4505                	li	a0,1
    800052d0:	9782                	jalr	a5
    800052d2:	8a2a                	mv	s4,a0
    800052d4:	a8a5                	j	8000534c <kfilewrite+0xfa>
    800052d6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	6ba080e7          	jalr	1722(ra) # 80004994 <begin_op>
      ilock(f->ip);
    800052e2:	01893503          	ld	a0,24(s2)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	9c6080e7          	jalr	-1594(ra) # 80003cac <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800052ee:	8762                	mv	a4,s8
    800052f0:	02092683          	lw	a3,32(s2)
    800052f4:	01598633          	add	a2,s3,s5
    800052f8:	4581                	li	a1,0
    800052fa:	01893503          	ld	a0,24(s2)
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	d5a080e7          	jalr	-678(ra) # 80004058 <writei>
    80005306:	84aa                	mv	s1,a0
    80005308:	00a05763          	blez	a0,80005316 <kfilewrite+0xc4>
        f->off += r;
    8000530c:	02092783          	lw	a5,32(s2)
    80005310:	9fa9                	addw	a5,a5,a0
    80005312:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005316:	01893503          	ld	a0,24(s2)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	a54080e7          	jalr	-1452(ra) # 80003d6e <iunlock>
      end_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	6f2080e7          	jalr	1778(ra) # 80004a14 <end_op>

      if(r != n1){
    8000532a:	009c1f63          	bne	s8,s1,80005348 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000532e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005332:	0149db63          	bge	s3,s4,80005348 <kfilewrite+0xf6>
      int n1 = n - i;
    80005336:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000533a:	84be                	mv	s1,a5
    8000533c:	2781                	sext.w	a5,a5
    8000533e:	f8fb5ce3          	bge	s6,a5,800052d6 <kfilewrite+0x84>
    80005342:	84de                	mv	s1,s7
    80005344:	bf49                	j	800052d6 <kfilewrite+0x84>
    int i = 0;
    80005346:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005348:	013a1f63          	bne	s4,s3,80005366 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000534c:	8552                	mv	a0,s4
    8000534e:	60a6                	ld	ra,72(sp)
    80005350:	6406                	ld	s0,64(sp)
    80005352:	74e2                	ld	s1,56(sp)
    80005354:	7942                	ld	s2,48(sp)
    80005356:	79a2                	ld	s3,40(sp)
    80005358:	7a02                	ld	s4,32(sp)
    8000535a:	6ae2                	ld	s5,24(sp)
    8000535c:	6b42                	ld	s6,16(sp)
    8000535e:	6ba2                	ld	s7,8(sp)
    80005360:	6c02                	ld	s8,0(sp)
    80005362:	6161                	addi	sp,sp,80
    80005364:	8082                	ret
    ret = (i == n ? n : -1);
    80005366:	5a7d                	li	s4,-1
    80005368:	b7d5                	j	8000534c <kfilewrite+0xfa>
    panic("filewrite");
    8000536a:	00003517          	auipc	a0,0x3
    8000536e:	3d650513          	addi	a0,a0,982 # 80008740 <syscalls+0x2d8>
    80005372:	ffffb097          	auipc	ra,0xffffb
    80005376:	1b8080e7          	jalr	440(ra) # 8000052a <panic>
    return -1;
    8000537a:	5a7d                	li	s4,-1
    8000537c:	bfc1                	j	8000534c <kfilewrite+0xfa>
      return -1;
    8000537e:	5a7d                	li	s4,-1
    80005380:	b7f1                	j	8000534c <kfilewrite+0xfa>
    80005382:	5a7d                	li	s4,-1
    80005384:	b7e1                	j	8000534c <kfilewrite+0xfa>

0000000080005386 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005386:	7179                	addi	sp,sp,-48
    80005388:	f406                	sd	ra,40(sp)
    8000538a:	f022                	sd	s0,32(sp)
    8000538c:	ec26                	sd	s1,24(sp)
    8000538e:	e84a                	sd	s2,16(sp)
    80005390:	e44e                	sd	s3,8(sp)
    80005392:	e052                	sd	s4,0(sp)
    80005394:	1800                	addi	s0,sp,48
    80005396:	84aa                	mv	s1,a0
    80005398:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000539a:	0005b023          	sd	zero,0(a1)
    8000539e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	a02080e7          	jalr	-1534(ra) # 80004da4 <filealloc>
    800053aa:	e088                	sd	a0,0(s1)
    800053ac:	c551                	beqz	a0,80005438 <pipealloc+0xb2>
    800053ae:	00000097          	auipc	ra,0x0
    800053b2:	9f6080e7          	jalr	-1546(ra) # 80004da4 <filealloc>
    800053b6:	00aa3023          	sd	a0,0(s4)
    800053ba:	c92d                	beqz	a0,8000542c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800053bc:	ffffb097          	auipc	ra,0xffffb
    800053c0:	716080e7          	jalr	1814(ra) # 80000ad2 <kalloc>
    800053c4:	892a                	mv	s2,a0
    800053c6:	c125                	beqz	a0,80005426 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800053c8:	4985                	li	s3,1
    800053ca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800053ce:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800053d2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800053d6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053da:	00003597          	auipc	a1,0x3
    800053de:	37658593          	addi	a1,a1,886 # 80008750 <syscalls+0x2e8>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	750080e7          	jalr	1872(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800053ea:	609c                	ld	a5,0(s1)
    800053ec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800053f0:	609c                	ld	a5,0(s1)
    800053f2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800053f6:	609c                	ld	a5,0(s1)
    800053f8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800053fc:	609c                	ld	a5,0(s1)
    800053fe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005402:	000a3783          	ld	a5,0(s4)
    80005406:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000540a:	000a3783          	ld	a5,0(s4)
    8000540e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005412:	000a3783          	ld	a5,0(s4)
    80005416:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000541a:	000a3783          	ld	a5,0(s4)
    8000541e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005422:	4501                	li	a0,0
    80005424:	a025                	j	8000544c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005426:	6088                	ld	a0,0(s1)
    80005428:	e501                	bnez	a0,80005430 <pipealloc+0xaa>
    8000542a:	a039                	j	80005438 <pipealloc+0xb2>
    8000542c:	6088                	ld	a0,0(s1)
    8000542e:	c51d                	beqz	a0,8000545c <pipealloc+0xd6>
    fileclose(*f0);
    80005430:	00000097          	auipc	ra,0x0
    80005434:	a30080e7          	jalr	-1488(ra) # 80004e60 <fileclose>
  if(*f1)
    80005438:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000543c:	557d                	li	a0,-1
  if(*f1)
    8000543e:	c799                	beqz	a5,8000544c <pipealloc+0xc6>
    fileclose(*f1);
    80005440:	853e                	mv	a0,a5
    80005442:	00000097          	auipc	ra,0x0
    80005446:	a1e080e7          	jalr	-1506(ra) # 80004e60 <fileclose>
  return -1;
    8000544a:	557d                	li	a0,-1
}
    8000544c:	70a2                	ld	ra,40(sp)
    8000544e:	7402                	ld	s0,32(sp)
    80005450:	64e2                	ld	s1,24(sp)
    80005452:	6942                	ld	s2,16(sp)
    80005454:	69a2                	ld	s3,8(sp)
    80005456:	6a02                	ld	s4,0(sp)
    80005458:	6145                	addi	sp,sp,48
    8000545a:	8082                	ret
  return -1;
    8000545c:	557d                	li	a0,-1
    8000545e:	b7fd                	j	8000544c <pipealloc+0xc6>

0000000080005460 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005460:	1101                	addi	sp,sp,-32
    80005462:	ec06                	sd	ra,24(sp)
    80005464:	e822                	sd	s0,16(sp)
    80005466:	e426                	sd	s1,8(sp)
    80005468:	e04a                	sd	s2,0(sp)
    8000546a:	1000                	addi	s0,sp,32
    8000546c:	84aa                	mv	s1,a0
    8000546e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005470:	ffffb097          	auipc	ra,0xffffb
    80005474:	752080e7          	jalr	1874(ra) # 80000bc2 <acquire>
  if(writable){
    80005478:	02090d63          	beqz	s2,800054b2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000547c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005480:	21848513          	addi	a0,s1,536
    80005484:	ffffd097          	auipc	ra,0xffffd
    80005488:	424080e7          	jalr	1060(ra) # 800028a8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000548c:	2204b783          	ld	a5,544(s1)
    80005490:	eb95                	bnez	a5,800054c4 <pipeclose+0x64>
    release(&pi->lock);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffb097          	auipc	ra,0xffffb
    80005498:	7e2080e7          	jalr	2018(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffb097          	auipc	ra,0xffffb
    800054a2:	538080e7          	jalr	1336(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800054a6:	60e2                	ld	ra,24(sp)
    800054a8:	6442                	ld	s0,16(sp)
    800054aa:	64a2                	ld	s1,8(sp)
    800054ac:	6902                	ld	s2,0(sp)
    800054ae:	6105                	addi	sp,sp,32
    800054b0:	8082                	ret
    pi->readopen = 0;
    800054b2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800054b6:	21c48513          	addi	a0,s1,540
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	3ee080e7          	jalr	1006(ra) # 800028a8 <wakeup>
    800054c2:	b7e9                	j	8000548c <pipeclose+0x2c>
    release(&pi->lock);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffb097          	auipc	ra,0xffffb
    800054ca:	7b0080e7          	jalr	1968(ra) # 80000c76 <release>
}
    800054ce:	bfe1                	j	800054a6 <pipeclose+0x46>

00000000800054d0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800054d0:	711d                	addi	sp,sp,-96
    800054d2:	ec86                	sd	ra,88(sp)
    800054d4:	e8a2                	sd	s0,80(sp)
    800054d6:	e4a6                	sd	s1,72(sp)
    800054d8:	e0ca                	sd	s2,64(sp)
    800054da:	fc4e                	sd	s3,56(sp)
    800054dc:	f852                	sd	s4,48(sp)
    800054de:	f456                	sd	s5,40(sp)
    800054e0:	f05a                	sd	s6,32(sp)
    800054e2:	ec5e                	sd	s7,24(sp)
    800054e4:	e862                	sd	s8,16(sp)
    800054e6:	1080                	addi	s0,sp,96
    800054e8:	84aa                	mv	s1,a0
    800054ea:	8aae                	mv	s5,a1
    800054ec:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	a62080e7          	jalr	-1438(ra) # 80001f50 <myproc>
    800054f6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffb097          	auipc	ra,0xffffb
    800054fe:	6c8080e7          	jalr	1736(ra) # 80000bc2 <acquire>
  while(i < n){
    80005502:	0b405363          	blez	s4,800055a8 <pipewrite+0xd8>
  int i = 0;
    80005506:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005508:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000550a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000550e:	21c48b93          	addi	s7,s1,540
    80005512:	a089                	j	80005554 <pipewrite+0x84>
      release(&pi->lock);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffb097          	auipc	ra,0xffffb
    8000551a:	760080e7          	jalr	1888(ra) # 80000c76 <release>
      return -1;
    8000551e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005520:	854a                	mv	a0,s2
    80005522:	60e6                	ld	ra,88(sp)
    80005524:	6446                	ld	s0,80(sp)
    80005526:	64a6                	ld	s1,72(sp)
    80005528:	6906                	ld	s2,64(sp)
    8000552a:	79e2                	ld	s3,56(sp)
    8000552c:	7a42                	ld	s4,48(sp)
    8000552e:	7aa2                	ld	s5,40(sp)
    80005530:	7b02                	ld	s6,32(sp)
    80005532:	6be2                	ld	s7,24(sp)
    80005534:	6c42                	ld	s8,16(sp)
    80005536:	6125                	addi	sp,sp,96
    80005538:	8082                	ret
      wakeup(&pi->nread);
    8000553a:	8562                	mv	a0,s8
    8000553c:	ffffd097          	auipc	ra,0xffffd
    80005540:	36c080e7          	jalr	876(ra) # 800028a8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005544:	85a6                	mv	a1,s1
    80005546:	855e                	mv	a0,s7
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	1d4080e7          	jalr	468(ra) # 8000271c <sleep>
  while(i < n){
    80005550:	05495d63          	bge	s2,s4,800055aa <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005554:	2204a783          	lw	a5,544(s1)
    80005558:	dfd5                	beqz	a5,80005514 <pipewrite+0x44>
    8000555a:	0289a783          	lw	a5,40(s3)
    8000555e:	fbdd                	bnez	a5,80005514 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005560:	2184a783          	lw	a5,536(s1)
    80005564:	21c4a703          	lw	a4,540(s1)
    80005568:	2007879b          	addiw	a5,a5,512
    8000556c:	fcf707e3          	beq	a4,a5,8000553a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005570:	4685                	li	a3,1
    80005572:	01590633          	add	a2,s2,s5
    80005576:	faf40593          	addi	a1,s0,-81
    8000557a:	0509b503          	ld	a0,80(s3)
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	176080e7          	jalr	374(ra) # 800016f4 <copyin>
    80005586:	03650263          	beq	a0,s6,800055aa <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000558a:	21c4a783          	lw	a5,540(s1)
    8000558e:	0017871b          	addiw	a4,a5,1
    80005592:	20e4ae23          	sw	a4,540(s1)
    80005596:	1ff7f793          	andi	a5,a5,511
    8000559a:	97a6                	add	a5,a5,s1
    8000559c:	faf44703          	lbu	a4,-81(s0)
    800055a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800055a4:	2905                	addiw	s2,s2,1
    800055a6:	b76d                	j	80005550 <pipewrite+0x80>
  int i = 0;
    800055a8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800055aa:	21848513          	addi	a0,s1,536
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	2fa080e7          	jalr	762(ra) # 800028a8 <wakeup>
  release(&pi->lock);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffb097          	auipc	ra,0xffffb
    800055bc:	6be080e7          	jalr	1726(ra) # 80000c76 <release>
  return i;
    800055c0:	b785                	j	80005520 <pipewrite+0x50>

00000000800055c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800055c2:	715d                	addi	sp,sp,-80
    800055c4:	e486                	sd	ra,72(sp)
    800055c6:	e0a2                	sd	s0,64(sp)
    800055c8:	fc26                	sd	s1,56(sp)
    800055ca:	f84a                	sd	s2,48(sp)
    800055cc:	f44e                	sd	s3,40(sp)
    800055ce:	f052                	sd	s4,32(sp)
    800055d0:	ec56                	sd	s5,24(sp)
    800055d2:	e85a                	sd	s6,16(sp)
    800055d4:	0880                	addi	s0,sp,80
    800055d6:	84aa                	mv	s1,a0
    800055d8:	892e                	mv	s2,a1
    800055da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800055dc:	ffffd097          	auipc	ra,0xffffd
    800055e0:	974080e7          	jalr	-1676(ra) # 80001f50 <myproc>
    800055e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffb097          	auipc	ra,0xffffb
    800055ec:	5da080e7          	jalr	1498(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055f0:	2184a703          	lw	a4,536(s1)
    800055f4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055f8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055fc:	02f71463          	bne	a4,a5,80005624 <piperead+0x62>
    80005600:	2244a783          	lw	a5,548(s1)
    80005604:	c385                	beqz	a5,80005624 <piperead+0x62>
    if(pr->killed){
    80005606:	028a2783          	lw	a5,40(s4)
    8000560a:	ebc1                	bnez	a5,8000569a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000560c:	85a6                	mv	a1,s1
    8000560e:	854e                	mv	a0,s3
    80005610:	ffffd097          	auipc	ra,0xffffd
    80005614:	10c080e7          	jalr	268(ra) # 8000271c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005618:	2184a703          	lw	a4,536(s1)
    8000561c:	21c4a783          	lw	a5,540(s1)
    80005620:	fef700e3          	beq	a4,a5,80005600 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005624:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005626:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005628:	05505363          	blez	s5,8000566e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000562c:	2184a783          	lw	a5,536(s1)
    80005630:	21c4a703          	lw	a4,540(s1)
    80005634:	02f70d63          	beq	a4,a5,8000566e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005638:	0017871b          	addiw	a4,a5,1
    8000563c:	20e4ac23          	sw	a4,536(s1)
    80005640:	1ff7f793          	andi	a5,a5,511
    80005644:	97a6                	add	a5,a5,s1
    80005646:	0187c783          	lbu	a5,24(a5)
    8000564a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000564e:	4685                	li	a3,1
    80005650:	fbf40613          	addi	a2,s0,-65
    80005654:	85ca                	mv	a1,s2
    80005656:	050a3503          	ld	a0,80(s4)
    8000565a:	ffffc097          	auipc	ra,0xffffc
    8000565e:	00e080e7          	jalr	14(ra) # 80001668 <copyout>
    80005662:	01650663          	beq	a0,s6,8000566e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005666:	2985                	addiw	s3,s3,1
    80005668:	0905                	addi	s2,s2,1
    8000566a:	fd3a91e3          	bne	s5,s3,8000562c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000566e:	21c48513          	addi	a0,s1,540
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	236080e7          	jalr	566(ra) # 800028a8 <wakeup>
  release(&pi->lock);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffb097          	auipc	ra,0xffffb
    80005680:	5fa080e7          	jalr	1530(ra) # 80000c76 <release>
  return i;
}
    80005684:	854e                	mv	a0,s3
    80005686:	60a6                	ld	ra,72(sp)
    80005688:	6406                	ld	s0,64(sp)
    8000568a:	74e2                	ld	s1,56(sp)
    8000568c:	7942                	ld	s2,48(sp)
    8000568e:	79a2                	ld	s3,40(sp)
    80005690:	7a02                	ld	s4,32(sp)
    80005692:	6ae2                	ld	s5,24(sp)
    80005694:	6b42                	ld	s6,16(sp)
    80005696:	6161                	addi	sp,sp,80
    80005698:	8082                	ret
      release(&pi->lock);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	5da080e7          	jalr	1498(ra) # 80000c76 <release>
      return -1;
    800056a4:	59fd                	li	s3,-1
    800056a6:	bff9                	j	80005684 <piperead+0xc2>

00000000800056a8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800056a8:	de010113          	addi	sp,sp,-544
    800056ac:	20113c23          	sd	ra,536(sp)
    800056b0:	20813823          	sd	s0,528(sp)
    800056b4:	20913423          	sd	s1,520(sp)
    800056b8:	21213023          	sd	s2,512(sp)
    800056bc:	ffce                	sd	s3,504(sp)
    800056be:	fbd2                	sd	s4,496(sp)
    800056c0:	f7d6                	sd	s5,488(sp)
    800056c2:	f3da                	sd	s6,480(sp)
    800056c4:	efde                	sd	s7,472(sp)
    800056c6:	ebe2                	sd	s8,464(sp)
    800056c8:	e7e6                	sd	s9,456(sp)
    800056ca:	e3ea                	sd	s10,448(sp)
    800056cc:	ff6e                	sd	s11,440(sp)
    800056ce:	1400                	addi	s0,sp,544
    800056d0:	dea43c23          	sd	a0,-520(s0)
    800056d4:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	878080e7          	jalr	-1928(ra) # 80001f50 <myproc>
    800056e0:	84aa                	mv	s1,a0

  #ifndef NONE
  if(p->pid > 2){
    800056e2:	5918                	lw	a4,48(a0)
    800056e4:	4789                	li	a5,2
    800056e6:	04e7df63          	bge	a5,a4,80005744 <exec+0x9c>
    struct page_metadata *pg;
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    800056ea:	17050713          	addi	a4,a0,368
    800056ee:	37050793          	addi	a5,a0,880
    800056f2:	86be                	mv	a3,a5
      pg->state = 0;
    800056f4:	00072423          	sw	zero,8(a4)
      pg->va = 0;
    800056f8:	00073023          	sd	zero,0(a4)
      pg->age = 0;
    800056fc:	00073823          	sd	zero,16(a4)
      pg->creationOrder=0;
    80005700:	00073c23          	sd	zero,24(a4)
    for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    80005704:	02070713          	addi	a4,a4,32
    80005708:	fed716e3          	bne	a4,a3,800056f4 <exec+0x4c>
    }
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    8000570c:	57048713          	addi	a4,s1,1392
      pg->state = 0;
    80005710:	0007a423          	sw	zero,8(a5)
      pg->va = 0;
    80005714:	0007b023          	sd	zero,0(a5)
      pg->age = 0;
    80005718:	0007b823          	sd	zero,16(a5)
      pg->creationOrder=0;
    8000571c:	0007bc23          	sd	zero,24(a5)
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    80005720:	02078793          	addi	a5,a5,32
    80005724:	fee796e3          	bne	a5,a4,80005710 <exec+0x68>
    }
    p->num_pages_in_swapfile = 0;
    80005728:	5604aa23          	sw	zero,1396(s1)
    p->num_pages_in_psyc = 0;
    8000572c:	5604a823          	sw	zero,1392(s1)
    removeSwapFile(p);
    80005730:	8526                	mv	a0,s1
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	ddc080e7          	jalr	-548(ra) # 8000450e <removeSwapFile>
    createSwapFile(p);
    8000573a:	8526                	mv	a0,s1
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	f7a080e7          	jalr	-134(ra) # 800046b6 <createSwapFile>
  }
  #endif

  begin_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	250080e7          	jalr	592(ra) # 80004994 <begin_op>

  if((ip = namei(path)) == 0){
    8000574c:	df843503          	ld	a0,-520(s0)
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	d12080e7          	jalr	-750(ra) # 80004462 <namei>
    80005758:	8aaa                	mv	s5,a0
    8000575a:	c935                	beqz	a0,800057ce <exec+0x126>
    end_op();
    return -1;
  }
  ilock(ip);
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	550080e7          	jalr	1360(ra) # 80003cac <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005764:	04000713          	li	a4,64
    80005768:	4681                	li	a3,0
    8000576a:	e4840613          	addi	a2,s0,-440
    8000576e:	4581                	li	a1,0
    80005770:	8556                	mv	a0,s5
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	7ee080e7          	jalr	2030(ra) # 80003f60 <readi>
    8000577a:	04000793          	li	a5,64
    8000577e:	00f51a63          	bne	a0,a5,80005792 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005782:	e4842703          	lw	a4,-440(s0)
    80005786:	464c47b7          	lui	a5,0x464c4
    8000578a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000578e:	04f70663          	beq	a4,a5,800057da <exec+0x132>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005792:	8556                	mv	a0,s5
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	77a080e7          	jalr	1914(ra) # 80003f0e <iunlockput>
    end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	278080e7          	jalr	632(ra) # 80004a14 <end_op>
  }
  return -1;
    800057a4:	557d                	li	a0,-1
}
    800057a6:	21813083          	ld	ra,536(sp)
    800057aa:	21013403          	ld	s0,528(sp)
    800057ae:	20813483          	ld	s1,520(sp)
    800057b2:	20013903          	ld	s2,512(sp)
    800057b6:	79fe                	ld	s3,504(sp)
    800057b8:	7a5e                	ld	s4,496(sp)
    800057ba:	7abe                	ld	s5,488(sp)
    800057bc:	7b1e                	ld	s6,480(sp)
    800057be:	6bfe                	ld	s7,472(sp)
    800057c0:	6c5e                	ld	s8,464(sp)
    800057c2:	6cbe                	ld	s9,456(sp)
    800057c4:	6d1e                	ld	s10,448(sp)
    800057c6:	7dfa                	ld	s11,440(sp)
    800057c8:	22010113          	addi	sp,sp,544
    800057cc:	8082                	ret
    end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	246080e7          	jalr	582(ra) # 80004a14 <end_op>
    return -1;
    800057d6:	557d                	li	a0,-1
    800057d8:	b7f9                	j	800057a6 <exec+0xfe>
  if((pagetable = proc_pagetable(p)) == 0)
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffd097          	auipc	ra,0xffffd
    800057e0:	838080e7          	jalr	-1992(ra) # 80002014 <proc_pagetable>
    800057e4:	8b2a                	mv	s6,a0
    800057e6:	d555                	beqz	a0,80005792 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057e8:	e6842783          	lw	a5,-408(s0)
    800057ec:	e8045703          	lhu	a4,-384(s0)
    800057f0:	c735                	beqz	a4,8000585c <exec+0x1b4>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800057f2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057f4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800057f8:	6a05                	lui	s4,0x1
    800057fa:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800057fe:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005802:	6d85                	lui	s11,0x1
    80005804:	7d7d                	lui	s10,0xfffff
    80005806:	ac1d                	j	80005a3c <exec+0x394>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005808:	00003517          	auipc	a0,0x3
    8000580c:	f5050513          	addi	a0,a0,-176 # 80008758 <syscalls+0x2f0>
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	d1a080e7          	jalr	-742(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005818:	874a                	mv	a4,s2
    8000581a:	009c86bb          	addw	a3,s9,s1
    8000581e:	4581                	li	a1,0
    80005820:	8556                	mv	a0,s5
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	73e080e7          	jalr	1854(ra) # 80003f60 <readi>
    8000582a:	2501                	sext.w	a0,a0
    8000582c:	1aa91863          	bne	s2,a0,800059dc <exec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80005830:	009d84bb          	addw	s1,s11,s1
    80005834:	013d09bb          	addw	s3,s10,s3
    80005838:	1f74f263          	bgeu	s1,s7,80005a1c <exec+0x374>
    pa = walkaddr(pagetable, va + i);
    8000583c:	02049593          	slli	a1,s1,0x20
    80005840:	9181                	srli	a1,a1,0x20
    80005842:	95e2                	add	a1,a1,s8
    80005844:	855a                	mv	a0,s6
    80005846:	ffffc097          	auipc	ra,0xffffc
    8000584a:	806080e7          	jalr	-2042(ra) # 8000104c <walkaddr>
    8000584e:	862a                	mv	a2,a0
    if(pa == 0)
    80005850:	dd45                	beqz	a0,80005808 <exec+0x160>
      n = PGSIZE;
    80005852:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005854:	fd49f2e3          	bgeu	s3,s4,80005818 <exec+0x170>
      n = sz - i;
    80005858:	894e                	mv	s2,s3
    8000585a:	bf7d                	j	80005818 <exec+0x170>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000585c:	4481                	li	s1,0
  iunlockput(ip);
    8000585e:	8556                	mv	a0,s5
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	6ae080e7          	jalr	1710(ra) # 80003f0e <iunlockput>
  end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	1ac080e7          	jalr	428(ra) # 80004a14 <end_op>
  p = myproc();
    80005870:	ffffc097          	auipc	ra,0xffffc
    80005874:	6e0080e7          	jalr	1760(ra) # 80001f50 <myproc>
    80005878:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000587a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000587e:	6785                	lui	a5,0x1
    80005880:	17fd                	addi	a5,a5,-1
    80005882:	94be                	add	s1,s1,a5
    80005884:	77fd                	lui	a5,0xfffff
    80005886:	8fe5                	and	a5,a5,s1
    80005888:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000588c:	6609                	lui	a2,0x2
    8000588e:	963e                	add	a2,a2,a5
    80005890:	85be                	mv	a1,a5
    80005892:	855a                	mv	a0,s6
    80005894:	ffffc097          	auipc	ra,0xffffc
    80005898:	348080e7          	jalr	840(ra) # 80001bdc <uvmalloc>
    8000589c:	8c2a                	mv	s8,a0
  ip = 0;
    8000589e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800058a0:	12050e63          	beqz	a0,800059dc <exec+0x334>
  uvmclear(pagetable, sz-2*PGSIZE);
    800058a4:	75f9                	lui	a1,0xffffe
    800058a6:	95aa                	add	a1,a1,a0
    800058a8:	855a                	mv	a0,s6
    800058aa:	ffffc097          	auipc	ra,0xffffc
    800058ae:	d8c080e7          	jalr	-628(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800058b2:	7afd                	lui	s5,0xfffff
    800058b4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800058b6:	de843783          	ld	a5,-536(s0)
    800058ba:	6388                	ld	a0,0(a5)
    800058bc:	c925                	beqz	a0,8000592c <exec+0x284>
    800058be:	e8840993          	addi	s3,s0,-376
    800058c2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800058c6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058c8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	578080e7          	jalr	1400(ra) # 80000e42 <strlen>
    800058d2:	0015079b          	addiw	a5,a0,1
    800058d6:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058da:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800058de:	13596363          	bltu	s2,s5,80005a04 <exec+0x35c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058e2:	de843d83          	ld	s11,-536(s0)
    800058e6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800058ea:	8552                	mv	a0,s4
    800058ec:	ffffb097          	auipc	ra,0xffffb
    800058f0:	556080e7          	jalr	1366(ra) # 80000e42 <strlen>
    800058f4:	0015069b          	addiw	a3,a0,1
    800058f8:	8652                	mv	a2,s4
    800058fa:	85ca                	mv	a1,s2
    800058fc:	855a                	mv	a0,s6
    800058fe:	ffffc097          	auipc	ra,0xffffc
    80005902:	d6a080e7          	jalr	-662(ra) # 80001668 <copyout>
    80005906:	10054363          	bltz	a0,80005a0c <exec+0x364>
    ustack[argc] = sp;
    8000590a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000590e:	0485                	addi	s1,s1,1
    80005910:	008d8793          	addi	a5,s11,8
    80005914:	def43423          	sd	a5,-536(s0)
    80005918:	008db503          	ld	a0,8(s11)
    8000591c:	c911                	beqz	a0,80005930 <exec+0x288>
    if(argc >= MAXARG)
    8000591e:	09a1                	addi	s3,s3,8
    80005920:	fb9995e3          	bne	s3,s9,800058ca <exec+0x222>
  sz = sz1;
    80005924:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005928:	4a81                	li	s5,0
    8000592a:	a84d                	j	800059dc <exec+0x334>
  sp = sz;
    8000592c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000592e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005930:	00349793          	slli	a5,s1,0x3
    80005934:	f9040713          	addi	a4,s0,-112
    80005938:	97ba                	add	a5,a5,a4
    8000593a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffc8ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000593e:	00148693          	addi	a3,s1,1
    80005942:	068e                	slli	a3,a3,0x3
    80005944:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005948:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000594c:	01597663          	bgeu	s2,s5,80005958 <exec+0x2b0>
  sz = sz1;
    80005950:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005954:	4a81                	li	s5,0
    80005956:	a059                	j	800059dc <exec+0x334>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005958:	e8840613          	addi	a2,s0,-376
    8000595c:	85ca                	mv	a1,s2
    8000595e:	855a                	mv	a0,s6
    80005960:	ffffc097          	auipc	ra,0xffffc
    80005964:	d08080e7          	jalr	-760(ra) # 80001668 <copyout>
    80005968:	0a054663          	bltz	a0,80005a14 <exec+0x36c>
  p->trapframe->a1 = sp;
    8000596c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005970:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005974:	df843783          	ld	a5,-520(s0)
    80005978:	0007c703          	lbu	a4,0(a5)
    8000597c:	cf11                	beqz	a4,80005998 <exec+0x2f0>
    8000597e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005980:	02f00693          	li	a3,47
    80005984:	a039                	j	80005992 <exec+0x2ea>
      last = s+1;
    80005986:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000598a:	0785                	addi	a5,a5,1
    8000598c:	fff7c703          	lbu	a4,-1(a5)
    80005990:	c701                	beqz	a4,80005998 <exec+0x2f0>
    if(*s == '/')
    80005992:	fed71ce3          	bne	a4,a3,8000598a <exec+0x2e2>
    80005996:	bfc5                	j	80005986 <exec+0x2de>
  safestrcpy(p->name, last, sizeof(p->name));
    80005998:	4641                	li	a2,16
    8000599a:	df843583          	ld	a1,-520(s0)
    8000599e:	158b8513          	addi	a0,s7,344
    800059a2:	ffffb097          	auipc	ra,0xffffb
    800059a6:	46e080e7          	jalr	1134(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    800059aa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800059ae:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800059b2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800059b6:	058bb783          	ld	a5,88(s7)
    800059ba:	e6043703          	ld	a4,-416(s0)
    800059be:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800059c0:	058bb783          	ld	a5,88(s7)
    800059c4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059c8:	85ea                	mv	a1,s10
    800059ca:	ffffc097          	auipc	ra,0xffffc
    800059ce:	6e6080e7          	jalr	1766(ra) # 800020b0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059d2:	0004851b          	sext.w	a0,s1
    800059d6:	bbc1                	j	800057a6 <exec+0xfe>
    800059d8:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    800059dc:	df043583          	ld	a1,-528(s0)
    800059e0:	855a                	mv	a0,s6
    800059e2:	ffffc097          	auipc	ra,0xffffc
    800059e6:	6ce080e7          	jalr	1742(ra) # 800020b0 <proc_freepagetable>
  if(ip){
    800059ea:	da0a94e3          	bnez	s5,80005792 <exec+0xea>
  return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	bb5d                	j	800057a6 <exec+0xfe>
    800059f2:	de943823          	sd	s1,-528(s0)
    800059f6:	b7dd                	j	800059dc <exec+0x334>
    800059f8:	de943823          	sd	s1,-528(s0)
    800059fc:	b7c5                	j	800059dc <exec+0x334>
    800059fe:	de943823          	sd	s1,-528(s0)
    80005a02:	bfe9                	j	800059dc <exec+0x334>
  sz = sz1;
    80005a04:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a08:	4a81                	li	s5,0
    80005a0a:	bfc9                	j	800059dc <exec+0x334>
  sz = sz1;
    80005a0c:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a10:	4a81                	li	s5,0
    80005a12:	b7e9                	j	800059dc <exec+0x334>
  sz = sz1;
    80005a14:	df843823          	sd	s8,-528(s0)
  ip = 0;
    80005a18:	4a81                	li	s5,0
    80005a1a:	b7c9                	j	800059dc <exec+0x334>
    sz = sz1;
    80005a1c:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a20:	e0843783          	ld	a5,-504(s0)
    80005a24:	0017869b          	addiw	a3,a5,1
    80005a28:	e0d43423          	sd	a3,-504(s0)
    80005a2c:	e0043783          	ld	a5,-512(s0)
    80005a30:	0387879b          	addiw	a5,a5,56
    80005a34:	e8045703          	lhu	a4,-384(s0)
    80005a38:	e2e6d3e3          	bge	a3,a4,8000585e <exec+0x1b6>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a3c:	2781                	sext.w	a5,a5
    80005a3e:	e0f43023          	sd	a5,-512(s0)
    80005a42:	03800713          	li	a4,56
    80005a46:	86be                	mv	a3,a5
    80005a48:	e1040613          	addi	a2,s0,-496
    80005a4c:	4581                	li	a1,0
    80005a4e:	8556                	mv	a0,s5
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	510080e7          	jalr	1296(ra) # 80003f60 <readi>
    80005a58:	03800793          	li	a5,56
    80005a5c:	f6f51ee3          	bne	a0,a5,800059d8 <exec+0x330>
    if(ph.type != ELF_PROG_LOAD)
    80005a60:	e1042783          	lw	a5,-496(s0)
    80005a64:	4705                	li	a4,1
    80005a66:	fae79de3          	bne	a5,a4,80005a20 <exec+0x378>
    if(ph.memsz < ph.filesz)
    80005a6a:	e3843603          	ld	a2,-456(s0)
    80005a6e:	e3043783          	ld	a5,-464(s0)
    80005a72:	f8f660e3          	bltu	a2,a5,800059f2 <exec+0x34a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a76:	e2043783          	ld	a5,-480(s0)
    80005a7a:	963e                	add	a2,a2,a5
    80005a7c:	f6f66ee3          	bltu	a2,a5,800059f8 <exec+0x350>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a80:	85a6                	mv	a1,s1
    80005a82:	855a                	mv	a0,s6
    80005a84:	ffffc097          	auipc	ra,0xffffc
    80005a88:	158080e7          	jalr	344(ra) # 80001bdc <uvmalloc>
    80005a8c:	dea43823          	sd	a0,-528(s0)
    80005a90:	d53d                	beqz	a0,800059fe <exec+0x356>
    if(ph.vaddr % PGSIZE != 0)
    80005a92:	e2043c03          	ld	s8,-480(s0)
    80005a96:	de043783          	ld	a5,-544(s0)
    80005a9a:	00fc77b3          	and	a5,s8,a5
    80005a9e:	ff9d                	bnez	a5,800059dc <exec+0x334>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005aa0:	e1842c83          	lw	s9,-488(s0)
    80005aa4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005aa8:	f60b8ae3          	beqz	s7,80005a1c <exec+0x374>
    80005aac:	89de                	mv	s3,s7
    80005aae:	4481                	li	s1,0
    80005ab0:	b371                	j	8000583c <exec+0x194>

0000000080005ab2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005ab2:	7179                	addi	sp,sp,-48
    80005ab4:	f406                	sd	ra,40(sp)
    80005ab6:	f022                	sd	s0,32(sp)
    80005ab8:	ec26                	sd	s1,24(sp)
    80005aba:	e84a                	sd	s2,16(sp)
    80005abc:	1800                	addi	s0,sp,48
    80005abe:	892e                	mv	s2,a1
    80005ac0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005ac2:	fdc40593          	addi	a1,s0,-36
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	674080e7          	jalr	1652(ra) # 8000313a <argint>
    80005ace:	04054063          	bltz	a0,80005b0e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005ad2:	fdc42703          	lw	a4,-36(s0)
    80005ad6:	47bd                	li	a5,15
    80005ad8:	02e7ed63          	bltu	a5,a4,80005b12 <argfd+0x60>
    80005adc:	ffffc097          	auipc	ra,0xffffc
    80005ae0:	474080e7          	jalr	1140(ra) # 80001f50 <myproc>
    80005ae4:	fdc42703          	lw	a4,-36(s0)
    80005ae8:	01a70793          	addi	a5,a4,26
    80005aec:	078e                	slli	a5,a5,0x3
    80005aee:	953e                	add	a0,a0,a5
    80005af0:	611c                	ld	a5,0(a0)
    80005af2:	c395                	beqz	a5,80005b16 <argfd+0x64>
    return -1;
  if(pfd)
    80005af4:	00090463          	beqz	s2,80005afc <argfd+0x4a>
    *pfd = fd;
    80005af8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005afc:	4501                	li	a0,0
  if(pf)
    80005afe:	c091                	beqz	s1,80005b02 <argfd+0x50>
    *pf = f;
    80005b00:	e09c                	sd	a5,0(s1)
}
    80005b02:	70a2                	ld	ra,40(sp)
    80005b04:	7402                	ld	s0,32(sp)
    80005b06:	64e2                	ld	s1,24(sp)
    80005b08:	6942                	ld	s2,16(sp)
    80005b0a:	6145                	addi	sp,sp,48
    80005b0c:	8082                	ret
    return -1;
    80005b0e:	557d                	li	a0,-1
    80005b10:	bfcd                	j	80005b02 <argfd+0x50>
    return -1;
    80005b12:	557d                	li	a0,-1
    80005b14:	b7fd                	j	80005b02 <argfd+0x50>
    80005b16:	557d                	li	a0,-1
    80005b18:	b7ed                	j	80005b02 <argfd+0x50>

0000000080005b1a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b1a:	1101                	addi	sp,sp,-32
    80005b1c:	ec06                	sd	ra,24(sp)
    80005b1e:	e822                	sd	s0,16(sp)
    80005b20:	e426                	sd	s1,8(sp)
    80005b22:	1000                	addi	s0,sp,32
    80005b24:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b26:	ffffc097          	auipc	ra,0xffffc
    80005b2a:	42a080e7          	jalr	1066(ra) # 80001f50 <myproc>
    80005b2e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b30:	0d050793          	addi	a5,a0,208
    80005b34:	4501                	li	a0,0
    80005b36:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b38:	6398                	ld	a4,0(a5)
    80005b3a:	cb19                	beqz	a4,80005b50 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b3c:	2505                	addiw	a0,a0,1
    80005b3e:	07a1                	addi	a5,a5,8
    80005b40:	fed51ce3          	bne	a0,a3,80005b38 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b44:	557d                	li	a0,-1
}
    80005b46:	60e2                	ld	ra,24(sp)
    80005b48:	6442                	ld	s0,16(sp)
    80005b4a:	64a2                	ld	s1,8(sp)
    80005b4c:	6105                	addi	sp,sp,32
    80005b4e:	8082                	ret
      p->ofile[fd] = f;
    80005b50:	01a50793          	addi	a5,a0,26
    80005b54:	078e                	slli	a5,a5,0x3
    80005b56:	963e                	add	a2,a2,a5
    80005b58:	e204                	sd	s1,0(a2)
      return fd;
    80005b5a:	b7f5                	j	80005b46 <fdalloc+0x2c>

0000000080005b5c <sys_dup>:

uint64
sys_dup(void)
{
    80005b5c:	7179                	addi	sp,sp,-48
    80005b5e:	f406                	sd	ra,40(sp)
    80005b60:	f022                	sd	s0,32(sp)
    80005b62:	ec26                	sd	s1,24(sp)
    80005b64:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005b66:	fd840613          	addi	a2,s0,-40
    80005b6a:	4581                	li	a1,0
    80005b6c:	4501                	li	a0,0
    80005b6e:	00000097          	auipc	ra,0x0
    80005b72:	f44080e7          	jalr	-188(ra) # 80005ab2 <argfd>
    return -1;
    80005b76:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b78:	02054363          	bltz	a0,80005b9e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b7c:	fd843503          	ld	a0,-40(s0)
    80005b80:	00000097          	auipc	ra,0x0
    80005b84:	f9a080e7          	jalr	-102(ra) # 80005b1a <fdalloc>
    80005b88:	84aa                	mv	s1,a0
    return -1;
    80005b8a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b8c:	00054963          	bltz	a0,80005b9e <sys_dup+0x42>
  filedup(f);
    80005b90:	fd843503          	ld	a0,-40(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	27a080e7          	jalr	634(ra) # 80004e0e <filedup>
  return fd;
    80005b9c:	87a6                	mv	a5,s1
}
    80005b9e:	853e                	mv	a0,a5
    80005ba0:	70a2                	ld	ra,40(sp)
    80005ba2:	7402                	ld	s0,32(sp)
    80005ba4:	64e2                	ld	s1,24(sp)
    80005ba6:	6145                	addi	sp,sp,48
    80005ba8:	8082                	ret

0000000080005baa <sys_read>:

uint64
sys_read(void)
{
    80005baa:	7179                	addi	sp,sp,-48
    80005bac:	f406                	sd	ra,40(sp)
    80005bae:	f022                	sd	s0,32(sp)
    80005bb0:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bb2:	fe840613          	addi	a2,s0,-24
    80005bb6:	4581                	li	a1,0
    80005bb8:	4501                	li	a0,0
    80005bba:	00000097          	auipc	ra,0x0
    80005bbe:	ef8080e7          	jalr	-264(ra) # 80005ab2 <argfd>
    return -1;
    80005bc2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc4:	04054163          	bltz	a0,80005c06 <sys_read+0x5c>
    80005bc8:	fe440593          	addi	a1,s0,-28
    80005bcc:	4509                	li	a0,2
    80005bce:	ffffd097          	auipc	ra,0xffffd
    80005bd2:	56c080e7          	jalr	1388(ra) # 8000313a <argint>
    return -1;
    80005bd6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bd8:	02054763          	bltz	a0,80005c06 <sys_read+0x5c>
    80005bdc:	fd840593          	addi	a1,s0,-40
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	57a080e7          	jalr	1402(ra) # 8000315c <argaddr>
    return -1;
    80005bea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bec:	00054d63          	bltz	a0,80005c06 <sys_read+0x5c>
  return fileread(f, p, n);
    80005bf0:	fe442603          	lw	a2,-28(s0)
    80005bf4:	fd843583          	ld	a1,-40(s0)
    80005bf8:	fe843503          	ld	a0,-24(s0)
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	39e080e7          	jalr	926(ra) # 80004f9a <fileread>
    80005c04:	87aa                	mv	a5,a0
}
    80005c06:	853e                	mv	a0,a5
    80005c08:	70a2                	ld	ra,40(sp)
    80005c0a:	7402                	ld	s0,32(sp)
    80005c0c:	6145                	addi	sp,sp,48
    80005c0e:	8082                	ret

0000000080005c10 <sys_write>:

uint64
sys_write(void)
{
    80005c10:	7179                	addi	sp,sp,-48
    80005c12:	f406                	sd	ra,40(sp)
    80005c14:	f022                	sd	s0,32(sp)
    80005c16:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c18:	fe840613          	addi	a2,s0,-24
    80005c1c:	4581                	li	a1,0
    80005c1e:	4501                	li	a0,0
    80005c20:	00000097          	auipc	ra,0x0
    80005c24:	e92080e7          	jalr	-366(ra) # 80005ab2 <argfd>
    return -1;
    80005c28:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c2a:	04054163          	bltz	a0,80005c6c <sys_write+0x5c>
    80005c2e:	fe440593          	addi	a1,s0,-28
    80005c32:	4509                	li	a0,2
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	506080e7          	jalr	1286(ra) # 8000313a <argint>
    return -1;
    80005c3c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c3e:	02054763          	bltz	a0,80005c6c <sys_write+0x5c>
    80005c42:	fd840593          	addi	a1,s0,-40
    80005c46:	4505                	li	a0,1
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	514080e7          	jalr	1300(ra) # 8000315c <argaddr>
    return -1;
    80005c50:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c52:	00054d63          	bltz	a0,80005c6c <sys_write+0x5c>

  return filewrite(f, p, n);
    80005c56:	fe442603          	lw	a2,-28(s0)
    80005c5a:	fd843583          	ld	a1,-40(s0)
    80005c5e:	fe843503          	ld	a0,-24(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	3fa080e7          	jalr	1018(ra) # 8000505c <filewrite>
    80005c6a:	87aa                	mv	a5,a0
}
    80005c6c:	853e                	mv	a0,a5
    80005c6e:	70a2                	ld	ra,40(sp)
    80005c70:	7402                	ld	s0,32(sp)
    80005c72:	6145                	addi	sp,sp,48
    80005c74:	8082                	ret

0000000080005c76 <sys_close>:

uint64
sys_close(void)
{
    80005c76:	1101                	addi	sp,sp,-32
    80005c78:	ec06                	sd	ra,24(sp)
    80005c7a:	e822                	sd	s0,16(sp)
    80005c7c:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005c7e:	fe040613          	addi	a2,s0,-32
    80005c82:	fec40593          	addi	a1,s0,-20
    80005c86:	4501                	li	a0,0
    80005c88:	00000097          	auipc	ra,0x0
    80005c8c:	e2a080e7          	jalr	-470(ra) # 80005ab2 <argfd>
    return -1;
    80005c90:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c92:	02054463          	bltz	a0,80005cba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c96:	ffffc097          	auipc	ra,0xffffc
    80005c9a:	2ba080e7          	jalr	698(ra) # 80001f50 <myproc>
    80005c9e:	fec42783          	lw	a5,-20(s0)
    80005ca2:	07e9                	addi	a5,a5,26
    80005ca4:	078e                	slli	a5,a5,0x3
    80005ca6:	97aa                	add	a5,a5,a0
    80005ca8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005cac:	fe043503          	ld	a0,-32(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	1b0080e7          	jalr	432(ra) # 80004e60 <fileclose>
  return 0;
    80005cb8:	4781                	li	a5,0
}
    80005cba:	853e                	mv	a0,a5
    80005cbc:	60e2                	ld	ra,24(sp)
    80005cbe:	6442                	ld	s0,16(sp)
    80005cc0:	6105                	addi	sp,sp,32
    80005cc2:	8082                	ret

0000000080005cc4 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005cc4:	1101                	addi	sp,sp,-32
    80005cc6:	ec06                	sd	ra,24(sp)
    80005cc8:	e822                	sd	s0,16(sp)
    80005cca:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ccc:	fe840613          	addi	a2,s0,-24
    80005cd0:	4581                	li	a1,0
    80005cd2:	4501                	li	a0,0
    80005cd4:	00000097          	auipc	ra,0x0
    80005cd8:	dde080e7          	jalr	-546(ra) # 80005ab2 <argfd>
    return -1;
    80005cdc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cde:	02054563          	bltz	a0,80005d08 <sys_fstat+0x44>
    80005ce2:	fe040593          	addi	a1,s0,-32
    80005ce6:	4505                	li	a0,1
    80005ce8:	ffffd097          	auipc	ra,0xffffd
    80005cec:	474080e7          	jalr	1140(ra) # 8000315c <argaddr>
    return -1;
    80005cf0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cf2:	00054b63          	bltz	a0,80005d08 <sys_fstat+0x44>
  return filestat(f, st);
    80005cf6:	fe043583          	ld	a1,-32(s0)
    80005cfa:	fe843503          	ld	a0,-24(s0)
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	22a080e7          	jalr	554(ra) # 80004f28 <filestat>
    80005d06:	87aa                	mv	a5,a0
}
    80005d08:	853e                	mv	a0,a5
    80005d0a:	60e2                	ld	ra,24(sp)
    80005d0c:	6442                	ld	s0,16(sp)
    80005d0e:	6105                	addi	sp,sp,32
    80005d10:	8082                	ret

0000000080005d12 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005d12:	7169                	addi	sp,sp,-304
    80005d14:	f606                	sd	ra,296(sp)
    80005d16:	f222                	sd	s0,288(sp)
    80005d18:	ee26                	sd	s1,280(sp)
    80005d1a:	ea4a                	sd	s2,272(sp)
    80005d1c:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d1e:	08000613          	li	a2,128
    80005d22:	ed040593          	addi	a1,s0,-304
    80005d26:	4501                	li	a0,0
    80005d28:	ffffd097          	auipc	ra,0xffffd
    80005d2c:	456080e7          	jalr	1110(ra) # 8000317e <argstr>
    return -1;
    80005d30:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d32:	10054e63          	bltz	a0,80005e4e <sys_link+0x13c>
    80005d36:	08000613          	li	a2,128
    80005d3a:	f5040593          	addi	a1,s0,-176
    80005d3e:	4505                	li	a0,1
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	43e080e7          	jalr	1086(ra) # 8000317e <argstr>
    return -1;
    80005d48:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d4a:	10054263          	bltz	a0,80005e4e <sys_link+0x13c>

  begin_op();
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	c46080e7          	jalr	-954(ra) # 80004994 <begin_op>
  if((ip = namei(old)) == 0){
    80005d56:	ed040513          	addi	a0,s0,-304
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	708080e7          	jalr	1800(ra) # 80004462 <namei>
    80005d62:	84aa                	mv	s1,a0
    80005d64:	c551                	beqz	a0,80005df0 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	f46080e7          	jalr	-186(ra) # 80003cac <ilock>
  if(ip->type == T_DIR){
    80005d6e:	04449703          	lh	a4,68(s1)
    80005d72:	4785                	li	a5,1
    80005d74:	08f70463          	beq	a4,a5,80005dfc <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005d78:	04a4d783          	lhu	a5,74(s1)
    80005d7c:	2785                	addiw	a5,a5,1
    80005d7e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d82:	8526                	mv	a0,s1
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	e5e080e7          	jalr	-418(ra) # 80003be2 <iupdate>
  iunlock(ip);
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	fe0080e7          	jalr	-32(ra) # 80003d6e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005d96:	fd040593          	addi	a1,s0,-48
    80005d9a:	f5040513          	addi	a0,s0,-176
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	6e2080e7          	jalr	1762(ra) # 80004480 <nameiparent>
    80005da6:	892a                	mv	s2,a0
    80005da8:	c935                	beqz	a0,80005e1c <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	f02080e7          	jalr	-254(ra) # 80003cac <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005db2:	00092703          	lw	a4,0(s2)
    80005db6:	409c                	lw	a5,0(s1)
    80005db8:	04f71d63          	bne	a4,a5,80005e12 <sys_link+0x100>
    80005dbc:	40d0                	lw	a2,4(s1)
    80005dbe:	fd040593          	addi	a1,s0,-48
    80005dc2:	854a                	mv	a0,s2
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	5dc080e7          	jalr	1500(ra) # 800043a0 <dirlink>
    80005dcc:	04054363          	bltz	a0,80005e12 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005dd0:	854a                	mv	a0,s2
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	13c080e7          	jalr	316(ra) # 80003f0e <iunlockput>
  iput(ip);
    80005dda:	8526                	mv	a0,s1
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	08a080e7          	jalr	138(ra) # 80003e66 <iput>

  end_op();
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	c30080e7          	jalr	-976(ra) # 80004a14 <end_op>

  return 0;
    80005dec:	4781                	li	a5,0
    80005dee:	a085                	j	80005e4e <sys_link+0x13c>
    end_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	c24080e7          	jalr	-988(ra) # 80004a14 <end_op>
    return -1;
    80005df8:	57fd                	li	a5,-1
    80005dfa:	a891                	j	80005e4e <sys_link+0x13c>
    iunlockput(ip);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	110080e7          	jalr	272(ra) # 80003f0e <iunlockput>
    end_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	c0e080e7          	jalr	-1010(ra) # 80004a14 <end_op>
    return -1;
    80005e0e:	57fd                	li	a5,-1
    80005e10:	a83d                	j	80005e4e <sys_link+0x13c>
    iunlockput(dp);
    80005e12:	854a                	mv	a0,s2
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	0fa080e7          	jalr	250(ra) # 80003f0e <iunlockput>

bad:
  ilock(ip);
    80005e1c:	8526                	mv	a0,s1
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	e8e080e7          	jalr	-370(ra) # 80003cac <ilock>
  ip->nlink--;
    80005e26:	04a4d783          	lhu	a5,74(s1)
    80005e2a:	37fd                	addiw	a5,a5,-1
    80005e2c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e30:	8526                	mv	a0,s1
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	db0080e7          	jalr	-592(ra) # 80003be2 <iupdate>
  iunlockput(ip);
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	ffffe097          	auipc	ra,0xffffe
    80005e40:	0d2080e7          	jalr	210(ra) # 80003f0e <iunlockput>
  end_op();
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	bd0080e7          	jalr	-1072(ra) # 80004a14 <end_op>
  return -1;
    80005e4c:	57fd                	li	a5,-1
}
    80005e4e:	853e                	mv	a0,a5
    80005e50:	70b2                	ld	ra,296(sp)
    80005e52:	7412                	ld	s0,288(sp)
    80005e54:	64f2                	ld	s1,280(sp)
    80005e56:	6952                	ld	s2,272(sp)
    80005e58:	6155                	addi	sp,sp,304
    80005e5a:	8082                	ret

0000000080005e5c <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e5c:	4578                	lw	a4,76(a0)
    80005e5e:	02000793          	li	a5,32
    80005e62:	04e7fa63          	bgeu	a5,a4,80005eb6 <isdirempty+0x5a>
{
    80005e66:	7179                	addi	sp,sp,-48
    80005e68:	f406                	sd	ra,40(sp)
    80005e6a:	f022                	sd	s0,32(sp)
    80005e6c:	ec26                	sd	s1,24(sp)
    80005e6e:	e84a                	sd	s2,16(sp)
    80005e70:	1800                	addi	s0,sp,48
    80005e72:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e74:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e78:	4741                	li	a4,16
    80005e7a:	86a6                	mv	a3,s1
    80005e7c:	fd040613          	addi	a2,s0,-48
    80005e80:	4581                	li	a1,0
    80005e82:	854a                	mv	a0,s2
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	0dc080e7          	jalr	220(ra) # 80003f60 <readi>
    80005e8c:	47c1                	li	a5,16
    80005e8e:	00f51c63          	bne	a0,a5,80005ea6 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005e92:	fd045783          	lhu	a5,-48(s0)
    80005e96:	e395                	bnez	a5,80005eba <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e98:	24c1                	addiw	s1,s1,16
    80005e9a:	04c92783          	lw	a5,76(s2)
    80005e9e:	fcf4ede3          	bltu	s1,a5,80005e78 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005ea2:	4505                	li	a0,1
    80005ea4:	a821                	j	80005ebc <isdirempty+0x60>
      panic("isdirempty: readi");
    80005ea6:	00003517          	auipc	a0,0x3
    80005eaa:	8d250513          	addi	a0,a0,-1838 # 80008778 <syscalls+0x310>
    80005eae:	ffffa097          	auipc	ra,0xffffa
    80005eb2:	67c080e7          	jalr	1660(ra) # 8000052a <panic>
  return 1;
    80005eb6:	4505                	li	a0,1
}
    80005eb8:	8082                	ret
      return 0;
    80005eba:	4501                	li	a0,0
}
    80005ebc:	70a2                	ld	ra,40(sp)
    80005ebe:	7402                	ld	s0,32(sp)
    80005ec0:	64e2                	ld	s1,24(sp)
    80005ec2:	6942                	ld	s2,16(sp)
    80005ec4:	6145                	addi	sp,sp,48
    80005ec6:	8082                	ret

0000000080005ec8 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005ec8:	7155                	addi	sp,sp,-208
    80005eca:	e586                	sd	ra,200(sp)
    80005ecc:	e1a2                	sd	s0,192(sp)
    80005ece:	fd26                	sd	s1,184(sp)
    80005ed0:	f94a                	sd	s2,176(sp)
    80005ed2:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005ed4:	08000613          	li	a2,128
    80005ed8:	f4040593          	addi	a1,s0,-192
    80005edc:	4501                	li	a0,0
    80005ede:	ffffd097          	auipc	ra,0xffffd
    80005ee2:	2a0080e7          	jalr	672(ra) # 8000317e <argstr>
    80005ee6:	16054363          	bltz	a0,8000604c <sys_unlink+0x184>
    return -1;

  begin_op();
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	aaa080e7          	jalr	-1366(ra) # 80004994 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ef2:	fc040593          	addi	a1,s0,-64
    80005ef6:	f4040513          	addi	a0,s0,-192
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	586080e7          	jalr	1414(ra) # 80004480 <nameiparent>
    80005f02:	84aa                	mv	s1,a0
    80005f04:	c961                	beqz	a0,80005fd4 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	da6080e7          	jalr	-602(ra) # 80003cac <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f0e:	00002597          	auipc	a1,0x2
    80005f12:	74a58593          	addi	a1,a1,1866 # 80008658 <syscalls+0x1f0>
    80005f16:	fc040513          	addi	a0,s0,-64
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	25c080e7          	jalr	604(ra) # 80004176 <namecmp>
    80005f22:	c175                	beqz	a0,80006006 <sys_unlink+0x13e>
    80005f24:	00002597          	auipc	a1,0x2
    80005f28:	73c58593          	addi	a1,a1,1852 # 80008660 <syscalls+0x1f8>
    80005f2c:	fc040513          	addi	a0,s0,-64
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	246080e7          	jalr	582(ra) # 80004176 <namecmp>
    80005f38:	c579                	beqz	a0,80006006 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f3a:	f3c40613          	addi	a2,s0,-196
    80005f3e:	fc040593          	addi	a1,s0,-64
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	24c080e7          	jalr	588(ra) # 80004190 <dirlookup>
    80005f4c:	892a                	mv	s2,a0
    80005f4e:	cd45                	beqz	a0,80006006 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	d5c080e7          	jalr	-676(ra) # 80003cac <ilock>

  if(ip->nlink < 1)
    80005f58:	04a91783          	lh	a5,74(s2)
    80005f5c:	08f05263          	blez	a5,80005fe0 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f60:	04491703          	lh	a4,68(s2)
    80005f64:	4785                	li	a5,1
    80005f66:	08f70563          	beq	a4,a5,80005ff0 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005f6a:	4641                	li	a2,16
    80005f6c:	4581                	li	a1,0
    80005f6e:	fd040513          	addi	a0,s0,-48
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	d4c080e7          	jalr	-692(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f7a:	4741                	li	a4,16
    80005f7c:	f3c42683          	lw	a3,-196(s0)
    80005f80:	fd040613          	addi	a2,s0,-48
    80005f84:	4581                	li	a1,0
    80005f86:	8526                	mv	a0,s1
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	0d0080e7          	jalr	208(ra) # 80004058 <writei>
    80005f90:	47c1                	li	a5,16
    80005f92:	08f51a63          	bne	a0,a5,80006026 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005f96:	04491703          	lh	a4,68(s2)
    80005f9a:	4785                	li	a5,1
    80005f9c:	08f70d63          	beq	a4,a5,80006036 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005fa0:	8526                	mv	a0,s1
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	f6c080e7          	jalr	-148(ra) # 80003f0e <iunlockput>

  ip->nlink--;
    80005faa:	04a95783          	lhu	a5,74(s2)
    80005fae:	37fd                	addiw	a5,a5,-1
    80005fb0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fb4:	854a                	mv	a0,s2
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	c2c080e7          	jalr	-980(ra) # 80003be2 <iupdate>
  iunlockput(ip);
    80005fbe:	854a                	mv	a0,s2
    80005fc0:	ffffe097          	auipc	ra,0xffffe
    80005fc4:	f4e080e7          	jalr	-178(ra) # 80003f0e <iunlockput>

  end_op();
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	a4c080e7          	jalr	-1460(ra) # 80004a14 <end_op>

  return 0;
    80005fd0:	4501                	li	a0,0
    80005fd2:	a0a1                	j	8000601a <sys_unlink+0x152>
    end_op();
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	a40080e7          	jalr	-1472(ra) # 80004a14 <end_op>
    return -1;
    80005fdc:	557d                	li	a0,-1
    80005fde:	a835                	j	8000601a <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005fe0:	00002517          	auipc	a0,0x2
    80005fe4:	68850513          	addi	a0,a0,1672 # 80008668 <syscalls+0x200>
    80005fe8:	ffffa097          	auipc	ra,0xffffa
    80005fec:	542080e7          	jalr	1346(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ff0:	854a                	mv	a0,s2
    80005ff2:	00000097          	auipc	ra,0x0
    80005ff6:	e6a080e7          	jalr	-406(ra) # 80005e5c <isdirempty>
    80005ffa:	f925                	bnez	a0,80005f6a <sys_unlink+0xa2>
    iunlockput(ip);
    80005ffc:	854a                	mv	a0,s2
    80005ffe:	ffffe097          	auipc	ra,0xffffe
    80006002:	f10080e7          	jalr	-240(ra) # 80003f0e <iunlockput>

bad:
  iunlockput(dp);
    80006006:	8526                	mv	a0,s1
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	f06080e7          	jalr	-250(ra) # 80003f0e <iunlockput>
  end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	a04080e7          	jalr	-1532(ra) # 80004a14 <end_op>
  return -1;
    80006018:	557d                	li	a0,-1
}
    8000601a:	60ae                	ld	ra,200(sp)
    8000601c:	640e                	ld	s0,192(sp)
    8000601e:	74ea                	ld	s1,184(sp)
    80006020:	794a                	ld	s2,176(sp)
    80006022:	6169                	addi	sp,sp,208
    80006024:	8082                	ret
    panic("unlink: writei");
    80006026:	00002517          	auipc	a0,0x2
    8000602a:	65a50513          	addi	a0,a0,1626 # 80008680 <syscalls+0x218>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	4fc080e7          	jalr	1276(ra) # 8000052a <panic>
    dp->nlink--;
    80006036:	04a4d783          	lhu	a5,74(s1)
    8000603a:	37fd                	addiw	a5,a5,-1
    8000603c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006040:	8526                	mv	a0,s1
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	ba0080e7          	jalr	-1120(ra) # 80003be2 <iupdate>
    8000604a:	bf99                	j	80005fa0 <sys_unlink+0xd8>
    return -1;
    8000604c:	557d                	li	a0,-1
    8000604e:	b7f1                	j	8000601a <sys_unlink+0x152>

0000000080006050 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006050:	715d                	addi	sp,sp,-80
    80006052:	e486                	sd	ra,72(sp)
    80006054:	e0a2                	sd	s0,64(sp)
    80006056:	fc26                	sd	s1,56(sp)
    80006058:	f84a                	sd	s2,48(sp)
    8000605a:	f44e                	sd	s3,40(sp)
    8000605c:	f052                	sd	s4,32(sp)
    8000605e:	ec56                	sd	s5,24(sp)
    80006060:	0880                	addi	s0,sp,80
    80006062:	89ae                	mv	s3,a1
    80006064:	8ab2                	mv	s5,a2
    80006066:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006068:	fb040593          	addi	a1,s0,-80
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	414080e7          	jalr	1044(ra) # 80004480 <nameiparent>
    80006074:	892a                	mv	s2,a0
    80006076:	12050e63          	beqz	a0,800061b2 <create+0x162>
    return 0;

  ilock(dp);
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	c32080e7          	jalr	-974(ra) # 80003cac <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006082:	4601                	li	a2,0
    80006084:	fb040593          	addi	a1,s0,-80
    80006088:	854a                	mv	a0,s2
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	106080e7          	jalr	262(ra) # 80004190 <dirlookup>
    80006092:	84aa                	mv	s1,a0
    80006094:	c921                	beqz	a0,800060e4 <create+0x94>
    iunlockput(dp);
    80006096:	854a                	mv	a0,s2
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	e76080e7          	jalr	-394(ra) # 80003f0e <iunlockput>
    ilock(ip);
    800060a0:	8526                	mv	a0,s1
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	c0a080e7          	jalr	-1014(ra) # 80003cac <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800060aa:	2981                	sext.w	s3,s3
    800060ac:	4789                	li	a5,2
    800060ae:	02f99463          	bne	s3,a5,800060d6 <create+0x86>
    800060b2:	0444d783          	lhu	a5,68(s1)
    800060b6:	37f9                	addiw	a5,a5,-2
    800060b8:	17c2                	slli	a5,a5,0x30
    800060ba:	93c1                	srli	a5,a5,0x30
    800060bc:	4705                	li	a4,1
    800060be:	00f76c63          	bltu	a4,a5,800060d6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800060c2:	8526                	mv	a0,s1
    800060c4:	60a6                	ld	ra,72(sp)
    800060c6:	6406                	ld	s0,64(sp)
    800060c8:	74e2                	ld	s1,56(sp)
    800060ca:	7942                	ld	s2,48(sp)
    800060cc:	79a2                	ld	s3,40(sp)
    800060ce:	7a02                	ld	s4,32(sp)
    800060d0:	6ae2                	ld	s5,24(sp)
    800060d2:	6161                	addi	sp,sp,80
    800060d4:	8082                	ret
    iunlockput(ip);
    800060d6:	8526                	mv	a0,s1
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	e36080e7          	jalr	-458(ra) # 80003f0e <iunlockput>
    return 0;
    800060e0:	4481                	li	s1,0
    800060e2:	b7c5                	j	800060c2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800060e4:	85ce                	mv	a1,s3
    800060e6:	00092503          	lw	a0,0(s2)
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	a2a080e7          	jalr	-1494(ra) # 80003b14 <ialloc>
    800060f2:	84aa                	mv	s1,a0
    800060f4:	c521                	beqz	a0,8000613c <create+0xec>
  ilock(ip);
    800060f6:	ffffe097          	auipc	ra,0xffffe
    800060fa:	bb6080e7          	jalr	-1098(ra) # 80003cac <ilock>
  ip->major = major;
    800060fe:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006102:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006106:	4a05                	li	s4,1
    80006108:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000610c:	8526                	mv	a0,s1
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	ad4080e7          	jalr	-1324(ra) # 80003be2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006116:	2981                	sext.w	s3,s3
    80006118:	03498a63          	beq	s3,s4,8000614c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000611c:	40d0                	lw	a2,4(s1)
    8000611e:	fb040593          	addi	a1,s0,-80
    80006122:	854a                	mv	a0,s2
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	27c080e7          	jalr	636(ra) # 800043a0 <dirlink>
    8000612c:	06054b63          	bltz	a0,800061a2 <create+0x152>
  iunlockput(dp);
    80006130:	854a                	mv	a0,s2
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	ddc080e7          	jalr	-548(ra) # 80003f0e <iunlockput>
  return ip;
    8000613a:	b761                	j	800060c2 <create+0x72>
    panic("create: ialloc");
    8000613c:	00002517          	auipc	a0,0x2
    80006140:	65450513          	addi	a0,a0,1620 # 80008790 <syscalls+0x328>
    80006144:	ffffa097          	auipc	ra,0xffffa
    80006148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000614c:	04a95783          	lhu	a5,74(s2)
    80006150:	2785                	addiw	a5,a5,1
    80006152:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006156:	854a                	mv	a0,s2
    80006158:	ffffe097          	auipc	ra,0xffffe
    8000615c:	a8a080e7          	jalr	-1398(ra) # 80003be2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006160:	40d0                	lw	a2,4(s1)
    80006162:	00002597          	auipc	a1,0x2
    80006166:	4f658593          	addi	a1,a1,1270 # 80008658 <syscalls+0x1f0>
    8000616a:	8526                	mv	a0,s1
    8000616c:	ffffe097          	auipc	ra,0xffffe
    80006170:	234080e7          	jalr	564(ra) # 800043a0 <dirlink>
    80006174:	00054f63          	bltz	a0,80006192 <create+0x142>
    80006178:	00492603          	lw	a2,4(s2)
    8000617c:	00002597          	auipc	a1,0x2
    80006180:	4e458593          	addi	a1,a1,1252 # 80008660 <syscalls+0x1f8>
    80006184:	8526                	mv	a0,s1
    80006186:	ffffe097          	auipc	ra,0xffffe
    8000618a:	21a080e7          	jalr	538(ra) # 800043a0 <dirlink>
    8000618e:	f80557e3          	bgez	a0,8000611c <create+0xcc>
      panic("create dots");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	60e50513          	addi	a0,a0,1550 # 800087a0 <syscalls+0x338>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	390080e7          	jalr	912(ra) # 8000052a <panic>
    panic("create: dirlink");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	60e50513          	addi	a0,a0,1550 # 800087b0 <syscalls+0x348>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	380080e7          	jalr	896(ra) # 8000052a <panic>
    return 0;
    800061b2:	84aa                	mv	s1,a0
    800061b4:	b739                	j	800060c2 <create+0x72>

00000000800061b6 <sys_open>:

uint64
sys_open(void)
{
    800061b6:	7131                	addi	sp,sp,-192
    800061b8:	fd06                	sd	ra,184(sp)
    800061ba:	f922                	sd	s0,176(sp)
    800061bc:	f526                	sd	s1,168(sp)
    800061be:	f14a                	sd	s2,160(sp)
    800061c0:	ed4e                	sd	s3,152(sp)
    800061c2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061c4:	08000613          	li	a2,128
    800061c8:	f5040593          	addi	a1,s0,-176
    800061cc:	4501                	li	a0,0
    800061ce:	ffffd097          	auipc	ra,0xffffd
    800061d2:	fb0080e7          	jalr	-80(ra) # 8000317e <argstr>
    return -1;
    800061d6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061d8:	0c054163          	bltz	a0,8000629a <sys_open+0xe4>
    800061dc:	f4c40593          	addi	a1,s0,-180
    800061e0:	4505                	li	a0,1
    800061e2:	ffffd097          	auipc	ra,0xffffd
    800061e6:	f58080e7          	jalr	-168(ra) # 8000313a <argint>
    800061ea:	0a054863          	bltz	a0,8000629a <sys_open+0xe4>

  begin_op();
    800061ee:	ffffe097          	auipc	ra,0xffffe
    800061f2:	7a6080e7          	jalr	1958(ra) # 80004994 <begin_op>

  if(omode & O_CREATE){
    800061f6:	f4c42783          	lw	a5,-180(s0)
    800061fa:	2007f793          	andi	a5,a5,512
    800061fe:	cbdd                	beqz	a5,800062b4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006200:	4681                	li	a3,0
    80006202:	4601                	li	a2,0
    80006204:	4589                	li	a1,2
    80006206:	f5040513          	addi	a0,s0,-176
    8000620a:	00000097          	auipc	ra,0x0
    8000620e:	e46080e7          	jalr	-442(ra) # 80006050 <create>
    80006212:	892a                	mv	s2,a0
    if(ip == 0){
    80006214:	c959                	beqz	a0,800062aa <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006216:	04491703          	lh	a4,68(s2)
    8000621a:	478d                	li	a5,3
    8000621c:	00f71763          	bne	a4,a5,8000622a <sys_open+0x74>
    80006220:	04695703          	lhu	a4,70(s2)
    80006224:	47a5                	li	a5,9
    80006226:	0ce7ec63          	bltu	a5,a4,800062fe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000622a:	fffff097          	auipc	ra,0xfffff
    8000622e:	b7a080e7          	jalr	-1158(ra) # 80004da4 <filealloc>
    80006232:	89aa                	mv	s3,a0
    80006234:	10050263          	beqz	a0,80006338 <sys_open+0x182>
    80006238:	00000097          	auipc	ra,0x0
    8000623c:	8e2080e7          	jalr	-1822(ra) # 80005b1a <fdalloc>
    80006240:	84aa                	mv	s1,a0
    80006242:	0e054663          	bltz	a0,8000632e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006246:	04491703          	lh	a4,68(s2)
    8000624a:	478d                	li	a5,3
    8000624c:	0cf70463          	beq	a4,a5,80006314 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006250:	4789                	li	a5,2
    80006252:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006256:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000625a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000625e:	f4c42783          	lw	a5,-180(s0)
    80006262:	0017c713          	xori	a4,a5,1
    80006266:	8b05                	andi	a4,a4,1
    80006268:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000626c:	0037f713          	andi	a4,a5,3
    80006270:	00e03733          	snez	a4,a4
    80006274:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006278:	4007f793          	andi	a5,a5,1024
    8000627c:	c791                	beqz	a5,80006288 <sys_open+0xd2>
    8000627e:	04491703          	lh	a4,68(s2)
    80006282:	4789                	li	a5,2
    80006284:	08f70f63          	beq	a4,a5,80006322 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006288:	854a                	mv	a0,s2
    8000628a:	ffffe097          	auipc	ra,0xffffe
    8000628e:	ae4080e7          	jalr	-1308(ra) # 80003d6e <iunlock>
  end_op();
    80006292:	ffffe097          	auipc	ra,0xffffe
    80006296:	782080e7          	jalr	1922(ra) # 80004a14 <end_op>

  return fd;
}
    8000629a:	8526                	mv	a0,s1
    8000629c:	70ea                	ld	ra,184(sp)
    8000629e:	744a                	ld	s0,176(sp)
    800062a0:	74aa                	ld	s1,168(sp)
    800062a2:	790a                	ld	s2,160(sp)
    800062a4:	69ea                	ld	s3,152(sp)
    800062a6:	6129                	addi	sp,sp,192
    800062a8:	8082                	ret
      end_op();
    800062aa:	ffffe097          	auipc	ra,0xffffe
    800062ae:	76a080e7          	jalr	1898(ra) # 80004a14 <end_op>
      return -1;
    800062b2:	b7e5                	j	8000629a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800062b4:	f5040513          	addi	a0,s0,-176
    800062b8:	ffffe097          	auipc	ra,0xffffe
    800062bc:	1aa080e7          	jalr	426(ra) # 80004462 <namei>
    800062c0:	892a                	mv	s2,a0
    800062c2:	c905                	beqz	a0,800062f2 <sys_open+0x13c>
    ilock(ip);
    800062c4:	ffffe097          	auipc	ra,0xffffe
    800062c8:	9e8080e7          	jalr	-1560(ra) # 80003cac <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062cc:	04491703          	lh	a4,68(s2)
    800062d0:	4785                	li	a5,1
    800062d2:	f4f712e3          	bne	a4,a5,80006216 <sys_open+0x60>
    800062d6:	f4c42783          	lw	a5,-180(s0)
    800062da:	dba1                	beqz	a5,8000622a <sys_open+0x74>
      iunlockput(ip);
    800062dc:	854a                	mv	a0,s2
    800062de:	ffffe097          	auipc	ra,0xffffe
    800062e2:	c30080e7          	jalr	-976(ra) # 80003f0e <iunlockput>
      end_op();
    800062e6:	ffffe097          	auipc	ra,0xffffe
    800062ea:	72e080e7          	jalr	1838(ra) # 80004a14 <end_op>
      return -1;
    800062ee:	54fd                	li	s1,-1
    800062f0:	b76d                	j	8000629a <sys_open+0xe4>
      end_op();
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	722080e7          	jalr	1826(ra) # 80004a14 <end_op>
      return -1;
    800062fa:	54fd                	li	s1,-1
    800062fc:	bf79                	j	8000629a <sys_open+0xe4>
    iunlockput(ip);
    800062fe:	854a                	mv	a0,s2
    80006300:	ffffe097          	auipc	ra,0xffffe
    80006304:	c0e080e7          	jalr	-1010(ra) # 80003f0e <iunlockput>
    end_op();
    80006308:	ffffe097          	auipc	ra,0xffffe
    8000630c:	70c080e7          	jalr	1804(ra) # 80004a14 <end_op>
    return -1;
    80006310:	54fd                	li	s1,-1
    80006312:	b761                	j	8000629a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006314:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006318:	04691783          	lh	a5,70(s2)
    8000631c:	02f99223          	sh	a5,36(s3)
    80006320:	bf2d                	j	8000625a <sys_open+0xa4>
    itrunc(ip);
    80006322:	854a                	mv	a0,s2
    80006324:	ffffe097          	auipc	ra,0xffffe
    80006328:	a96080e7          	jalr	-1386(ra) # 80003dba <itrunc>
    8000632c:	bfb1                	j	80006288 <sys_open+0xd2>
      fileclose(f);
    8000632e:	854e                	mv	a0,s3
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	b30080e7          	jalr	-1232(ra) # 80004e60 <fileclose>
    iunlockput(ip);
    80006338:	854a                	mv	a0,s2
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	bd4080e7          	jalr	-1068(ra) # 80003f0e <iunlockput>
    end_op();
    80006342:	ffffe097          	auipc	ra,0xffffe
    80006346:	6d2080e7          	jalr	1746(ra) # 80004a14 <end_op>
    return -1;
    8000634a:	54fd                	li	s1,-1
    8000634c:	b7b9                	j	8000629a <sys_open+0xe4>

000000008000634e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000634e:	7175                	addi	sp,sp,-144
    80006350:	e506                	sd	ra,136(sp)
    80006352:	e122                	sd	s0,128(sp)
    80006354:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006356:	ffffe097          	auipc	ra,0xffffe
    8000635a:	63e080e7          	jalr	1598(ra) # 80004994 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000635e:	08000613          	li	a2,128
    80006362:	f7040593          	addi	a1,s0,-144
    80006366:	4501                	li	a0,0
    80006368:	ffffd097          	auipc	ra,0xffffd
    8000636c:	e16080e7          	jalr	-490(ra) # 8000317e <argstr>
    80006370:	02054963          	bltz	a0,800063a2 <sys_mkdir+0x54>
    80006374:	4681                	li	a3,0
    80006376:	4601                	li	a2,0
    80006378:	4585                	li	a1,1
    8000637a:	f7040513          	addi	a0,s0,-144
    8000637e:	00000097          	auipc	ra,0x0
    80006382:	cd2080e7          	jalr	-814(ra) # 80006050 <create>
    80006386:	cd11                	beqz	a0,800063a2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006388:	ffffe097          	auipc	ra,0xffffe
    8000638c:	b86080e7          	jalr	-1146(ra) # 80003f0e <iunlockput>
  end_op();
    80006390:	ffffe097          	auipc	ra,0xffffe
    80006394:	684080e7          	jalr	1668(ra) # 80004a14 <end_op>
  return 0;
    80006398:	4501                	li	a0,0
}
    8000639a:	60aa                	ld	ra,136(sp)
    8000639c:	640a                	ld	s0,128(sp)
    8000639e:	6149                	addi	sp,sp,144
    800063a0:	8082                	ret
    end_op();
    800063a2:	ffffe097          	auipc	ra,0xffffe
    800063a6:	672080e7          	jalr	1650(ra) # 80004a14 <end_op>
    return -1;
    800063aa:	557d                	li	a0,-1
    800063ac:	b7fd                	j	8000639a <sys_mkdir+0x4c>

00000000800063ae <sys_mknod>:

uint64
sys_mknod(void)
{
    800063ae:	7135                	addi	sp,sp,-160
    800063b0:	ed06                	sd	ra,152(sp)
    800063b2:	e922                	sd	s0,144(sp)
    800063b4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800063b6:	ffffe097          	auipc	ra,0xffffe
    800063ba:	5de080e7          	jalr	1502(ra) # 80004994 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063be:	08000613          	li	a2,128
    800063c2:	f7040593          	addi	a1,s0,-144
    800063c6:	4501                	li	a0,0
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	db6080e7          	jalr	-586(ra) # 8000317e <argstr>
    800063d0:	04054a63          	bltz	a0,80006424 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800063d4:	f6c40593          	addi	a1,s0,-148
    800063d8:	4505                	li	a0,1
    800063da:	ffffd097          	auipc	ra,0xffffd
    800063de:	d60080e7          	jalr	-672(ra) # 8000313a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063e2:	04054163          	bltz	a0,80006424 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800063e6:	f6840593          	addi	a1,s0,-152
    800063ea:	4509                	li	a0,2
    800063ec:	ffffd097          	auipc	ra,0xffffd
    800063f0:	d4e080e7          	jalr	-690(ra) # 8000313a <argint>
     argint(1, &major) < 0 ||
    800063f4:	02054863          	bltz	a0,80006424 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800063f8:	f6841683          	lh	a3,-152(s0)
    800063fc:	f6c41603          	lh	a2,-148(s0)
    80006400:	458d                	li	a1,3
    80006402:	f7040513          	addi	a0,s0,-144
    80006406:	00000097          	auipc	ra,0x0
    8000640a:	c4a080e7          	jalr	-950(ra) # 80006050 <create>
     argint(2, &minor) < 0 ||
    8000640e:	c919                	beqz	a0,80006424 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006410:	ffffe097          	auipc	ra,0xffffe
    80006414:	afe080e7          	jalr	-1282(ra) # 80003f0e <iunlockput>
  end_op();
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	5fc080e7          	jalr	1532(ra) # 80004a14 <end_op>
  return 0;
    80006420:	4501                	li	a0,0
    80006422:	a031                	j	8000642e <sys_mknod+0x80>
    end_op();
    80006424:	ffffe097          	auipc	ra,0xffffe
    80006428:	5f0080e7          	jalr	1520(ra) # 80004a14 <end_op>
    return -1;
    8000642c:	557d                	li	a0,-1
}
    8000642e:	60ea                	ld	ra,152(sp)
    80006430:	644a                	ld	s0,144(sp)
    80006432:	610d                	addi	sp,sp,160
    80006434:	8082                	ret

0000000080006436 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006436:	7135                	addi	sp,sp,-160
    80006438:	ed06                	sd	ra,152(sp)
    8000643a:	e922                	sd	s0,144(sp)
    8000643c:	e526                	sd	s1,136(sp)
    8000643e:	e14a                	sd	s2,128(sp)
    80006440:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006442:	ffffc097          	auipc	ra,0xffffc
    80006446:	b0e080e7          	jalr	-1266(ra) # 80001f50 <myproc>
    8000644a:	892a                	mv	s2,a0
  
  begin_op();
    8000644c:	ffffe097          	auipc	ra,0xffffe
    80006450:	548080e7          	jalr	1352(ra) # 80004994 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006454:	08000613          	li	a2,128
    80006458:	f6040593          	addi	a1,s0,-160
    8000645c:	4501                	li	a0,0
    8000645e:	ffffd097          	auipc	ra,0xffffd
    80006462:	d20080e7          	jalr	-736(ra) # 8000317e <argstr>
    80006466:	04054b63          	bltz	a0,800064bc <sys_chdir+0x86>
    8000646a:	f6040513          	addi	a0,s0,-160
    8000646e:	ffffe097          	auipc	ra,0xffffe
    80006472:	ff4080e7          	jalr	-12(ra) # 80004462 <namei>
    80006476:	84aa                	mv	s1,a0
    80006478:	c131                	beqz	a0,800064bc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000647a:	ffffe097          	auipc	ra,0xffffe
    8000647e:	832080e7          	jalr	-1998(ra) # 80003cac <ilock>
  if(ip->type != T_DIR){
    80006482:	04449703          	lh	a4,68(s1)
    80006486:	4785                	li	a5,1
    80006488:	04f71063          	bne	a4,a5,800064c8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000648c:	8526                	mv	a0,s1
    8000648e:	ffffe097          	auipc	ra,0xffffe
    80006492:	8e0080e7          	jalr	-1824(ra) # 80003d6e <iunlock>
  iput(p->cwd);
    80006496:	15093503          	ld	a0,336(s2)
    8000649a:	ffffe097          	auipc	ra,0xffffe
    8000649e:	9cc080e7          	jalr	-1588(ra) # 80003e66 <iput>
  end_op();
    800064a2:	ffffe097          	auipc	ra,0xffffe
    800064a6:	572080e7          	jalr	1394(ra) # 80004a14 <end_op>
  p->cwd = ip;
    800064aa:	14993823          	sd	s1,336(s2)
  return 0;
    800064ae:	4501                	li	a0,0
}
    800064b0:	60ea                	ld	ra,152(sp)
    800064b2:	644a                	ld	s0,144(sp)
    800064b4:	64aa                	ld	s1,136(sp)
    800064b6:	690a                	ld	s2,128(sp)
    800064b8:	610d                	addi	sp,sp,160
    800064ba:	8082                	ret
    end_op();
    800064bc:	ffffe097          	auipc	ra,0xffffe
    800064c0:	558080e7          	jalr	1368(ra) # 80004a14 <end_op>
    return -1;
    800064c4:	557d                	li	a0,-1
    800064c6:	b7ed                	j	800064b0 <sys_chdir+0x7a>
    iunlockput(ip);
    800064c8:	8526                	mv	a0,s1
    800064ca:	ffffe097          	auipc	ra,0xffffe
    800064ce:	a44080e7          	jalr	-1468(ra) # 80003f0e <iunlockput>
    end_op();
    800064d2:	ffffe097          	auipc	ra,0xffffe
    800064d6:	542080e7          	jalr	1346(ra) # 80004a14 <end_op>
    return -1;
    800064da:	557d                	li	a0,-1
    800064dc:	bfd1                	j	800064b0 <sys_chdir+0x7a>

00000000800064de <sys_exec>:

uint64
sys_exec(void)
{
    800064de:	7145                	addi	sp,sp,-464
    800064e0:	e786                	sd	ra,456(sp)
    800064e2:	e3a2                	sd	s0,448(sp)
    800064e4:	ff26                	sd	s1,440(sp)
    800064e6:	fb4a                	sd	s2,432(sp)
    800064e8:	f74e                	sd	s3,424(sp)
    800064ea:	f352                	sd	s4,416(sp)
    800064ec:	ef56                	sd	s5,408(sp)
    800064ee:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800064f0:	08000613          	li	a2,128
    800064f4:	f4040593          	addi	a1,s0,-192
    800064f8:	4501                	li	a0,0
    800064fa:	ffffd097          	auipc	ra,0xffffd
    800064fe:	c84080e7          	jalr	-892(ra) # 8000317e <argstr>
    return -1;
    80006502:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006504:	0c054a63          	bltz	a0,800065d8 <sys_exec+0xfa>
    80006508:	e3840593          	addi	a1,s0,-456
    8000650c:	4505                	li	a0,1
    8000650e:	ffffd097          	auipc	ra,0xffffd
    80006512:	c4e080e7          	jalr	-946(ra) # 8000315c <argaddr>
    80006516:	0c054163          	bltz	a0,800065d8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000651a:	10000613          	li	a2,256
    8000651e:	4581                	li	a1,0
    80006520:	e4040513          	addi	a0,s0,-448
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	79a080e7          	jalr	1946(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000652c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006530:	89a6                	mv	s3,s1
    80006532:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006534:	02000a13          	li	s4,32
    80006538:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000653c:	00391793          	slli	a5,s2,0x3
    80006540:	e3040593          	addi	a1,s0,-464
    80006544:	e3843503          	ld	a0,-456(s0)
    80006548:	953e                	add	a0,a0,a5
    8000654a:	ffffd097          	auipc	ra,0xffffd
    8000654e:	b56080e7          	jalr	-1194(ra) # 800030a0 <fetchaddr>
    80006552:	02054a63          	bltz	a0,80006586 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006556:	e3043783          	ld	a5,-464(s0)
    8000655a:	c3b9                	beqz	a5,800065a0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	576080e7          	jalr	1398(ra) # 80000ad2 <kalloc>
    80006564:	85aa                	mv	a1,a0
    80006566:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000656a:	cd11                	beqz	a0,80006586 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000656c:	6605                	lui	a2,0x1
    8000656e:	e3043503          	ld	a0,-464(s0)
    80006572:	ffffd097          	auipc	ra,0xffffd
    80006576:	b80080e7          	jalr	-1152(ra) # 800030f2 <fetchstr>
    8000657a:	00054663          	bltz	a0,80006586 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000657e:	0905                	addi	s2,s2,1
    80006580:	09a1                	addi	s3,s3,8
    80006582:	fb491be3          	bne	s2,s4,80006538 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006586:	10048913          	addi	s2,s1,256
    8000658a:	6088                	ld	a0,0(s1)
    8000658c:	c529                	beqz	a0,800065d6 <sys_exec+0xf8>
    kfree(argv[i]);
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	448080e7          	jalr	1096(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006596:	04a1                	addi	s1,s1,8
    80006598:	ff2499e3          	bne	s1,s2,8000658a <sys_exec+0xac>
  return -1;
    8000659c:	597d                	li	s2,-1
    8000659e:	a82d                	j	800065d8 <sys_exec+0xfa>
      argv[i] = 0;
    800065a0:	0a8e                	slli	s5,s5,0x3
    800065a2:	fc040793          	addi	a5,s0,-64
    800065a6:	9abe                	add	s5,s5,a5
    800065a8:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffc8e80>
  int ret = exec(path, argv);
    800065ac:	e4040593          	addi	a1,s0,-448
    800065b0:	f4040513          	addi	a0,s0,-192
    800065b4:	fffff097          	auipc	ra,0xfffff
    800065b8:	0f4080e7          	jalr	244(ra) # 800056a8 <exec>
    800065bc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065be:	10048993          	addi	s3,s1,256
    800065c2:	6088                	ld	a0,0(s1)
    800065c4:	c911                	beqz	a0,800065d8 <sys_exec+0xfa>
    kfree(argv[i]);
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	410080e7          	jalr	1040(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065ce:	04a1                	addi	s1,s1,8
    800065d0:	ff3499e3          	bne	s1,s3,800065c2 <sys_exec+0xe4>
    800065d4:	a011                	j	800065d8 <sys_exec+0xfa>
  return -1;
    800065d6:	597d                	li	s2,-1
}
    800065d8:	854a                	mv	a0,s2
    800065da:	60be                	ld	ra,456(sp)
    800065dc:	641e                	ld	s0,448(sp)
    800065de:	74fa                	ld	s1,440(sp)
    800065e0:	795a                	ld	s2,432(sp)
    800065e2:	79ba                	ld	s3,424(sp)
    800065e4:	7a1a                	ld	s4,416(sp)
    800065e6:	6afa                	ld	s5,408(sp)
    800065e8:	6179                	addi	sp,sp,464
    800065ea:	8082                	ret

00000000800065ec <sys_pipe>:

uint64
sys_pipe(void)
{
    800065ec:	7139                	addi	sp,sp,-64
    800065ee:	fc06                	sd	ra,56(sp)
    800065f0:	f822                	sd	s0,48(sp)
    800065f2:	f426                	sd	s1,40(sp)
    800065f4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800065f6:	ffffc097          	auipc	ra,0xffffc
    800065fa:	95a080e7          	jalr	-1702(ra) # 80001f50 <myproc>
    800065fe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006600:	fd840593          	addi	a1,s0,-40
    80006604:	4501                	li	a0,0
    80006606:	ffffd097          	auipc	ra,0xffffd
    8000660a:	b56080e7          	jalr	-1194(ra) # 8000315c <argaddr>
    return -1;
    8000660e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006610:	0e054063          	bltz	a0,800066f0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006614:	fc840593          	addi	a1,s0,-56
    80006618:	fd040513          	addi	a0,s0,-48
    8000661c:	fffff097          	auipc	ra,0xfffff
    80006620:	d6a080e7          	jalr	-662(ra) # 80005386 <pipealloc>
    return -1;
    80006624:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006626:	0c054563          	bltz	a0,800066f0 <sys_pipe+0x104>
  fd0 = -1;
    8000662a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000662e:	fd043503          	ld	a0,-48(s0)
    80006632:	fffff097          	auipc	ra,0xfffff
    80006636:	4e8080e7          	jalr	1256(ra) # 80005b1a <fdalloc>
    8000663a:	fca42223          	sw	a0,-60(s0)
    8000663e:	08054c63          	bltz	a0,800066d6 <sys_pipe+0xea>
    80006642:	fc843503          	ld	a0,-56(s0)
    80006646:	fffff097          	auipc	ra,0xfffff
    8000664a:	4d4080e7          	jalr	1236(ra) # 80005b1a <fdalloc>
    8000664e:	fca42023          	sw	a0,-64(s0)
    80006652:	06054863          	bltz	a0,800066c2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006656:	4691                	li	a3,4
    80006658:	fc440613          	addi	a2,s0,-60
    8000665c:	fd843583          	ld	a1,-40(s0)
    80006660:	68a8                	ld	a0,80(s1)
    80006662:	ffffb097          	auipc	ra,0xffffb
    80006666:	006080e7          	jalr	6(ra) # 80001668 <copyout>
    8000666a:	02054063          	bltz	a0,8000668a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000666e:	4691                	li	a3,4
    80006670:	fc040613          	addi	a2,s0,-64
    80006674:	fd843583          	ld	a1,-40(s0)
    80006678:	0591                	addi	a1,a1,4
    8000667a:	68a8                	ld	a0,80(s1)
    8000667c:	ffffb097          	auipc	ra,0xffffb
    80006680:	fec080e7          	jalr	-20(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006684:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006686:	06055563          	bgez	a0,800066f0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000668a:	fc442783          	lw	a5,-60(s0)
    8000668e:	07e9                	addi	a5,a5,26
    80006690:	078e                	slli	a5,a5,0x3
    80006692:	97a6                	add	a5,a5,s1
    80006694:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006698:	fc042503          	lw	a0,-64(s0)
    8000669c:	0569                	addi	a0,a0,26
    8000669e:	050e                	slli	a0,a0,0x3
    800066a0:	9526                	add	a0,a0,s1
    800066a2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066a6:	fd043503          	ld	a0,-48(s0)
    800066aa:	ffffe097          	auipc	ra,0xffffe
    800066ae:	7b6080e7          	jalr	1974(ra) # 80004e60 <fileclose>
    fileclose(wf);
    800066b2:	fc843503          	ld	a0,-56(s0)
    800066b6:	ffffe097          	auipc	ra,0xffffe
    800066ba:	7aa080e7          	jalr	1962(ra) # 80004e60 <fileclose>
    return -1;
    800066be:	57fd                	li	a5,-1
    800066c0:	a805                	j	800066f0 <sys_pipe+0x104>
    if(fd0 >= 0)
    800066c2:	fc442783          	lw	a5,-60(s0)
    800066c6:	0007c863          	bltz	a5,800066d6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800066ca:	01a78513          	addi	a0,a5,26
    800066ce:	050e                	slli	a0,a0,0x3
    800066d0:	9526                	add	a0,a0,s1
    800066d2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066d6:	fd043503          	ld	a0,-48(s0)
    800066da:	ffffe097          	auipc	ra,0xffffe
    800066de:	786080e7          	jalr	1926(ra) # 80004e60 <fileclose>
    fileclose(wf);
    800066e2:	fc843503          	ld	a0,-56(s0)
    800066e6:	ffffe097          	auipc	ra,0xffffe
    800066ea:	77a080e7          	jalr	1914(ra) # 80004e60 <fileclose>
    return -1;
    800066ee:	57fd                	li	a5,-1
}
    800066f0:	853e                	mv	a0,a5
    800066f2:	70e2                	ld	ra,56(sp)
    800066f4:	7442                	ld	s0,48(sp)
    800066f6:	74a2                	ld	s1,40(sp)
    800066f8:	6121                	addi	sp,sp,64
    800066fa:	8082                	ret
    800066fc:	0000                	unimp
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
    80006740:	82dfc0ef          	jal	ra,80002f6c <kerneltrap>
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
    800067dc:	74c080e7          	jalr	1868(ra) # 80001f24 <cpuid>
  
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
    80006814:	714080e7          	jalr	1812(ra) # 80001f24 <cpuid>
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
    8000683c:	6ec080e7          	jalr	1772(ra) # 80001f24 <cpuid>
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
    800068c6:	fe6080e7          	jalr	-26(ra) # 800028a8 <wakeup>
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
    80006aec:	c34080e7          	jalr	-972(ra) # 8000271c <sleep>
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
    80006bba:	b66080e7          	jalr	-1178(ra) # 8000271c <sleep>
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
    80006d40:	b6c080e7          	jalr	-1172(ra) # 800028a8 <wakeup>

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
