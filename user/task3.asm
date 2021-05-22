
user/_task3:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test1>:

#define PGSIZE 4096

//Test1 - Allocating 18 pages, some of them on disk, some in memory.
// then trying to access all arrays that was allocated.
void test1(){
   0:	7155                	addi	sp,sp,-208
   2:	e586                	sd	ra,200(sp)
   4:	e1a2                	sd	s0,192(sp)
   6:	fd26                	sd	s1,184(sp)
   8:	f94a                	sd	s2,176(sp)
   a:	f54e                	sd	s3,168(sp)
   c:	f152                	sd	s4,160(sp)
   e:	ed56                	sd	s5,152(sp)
  10:	e95a                	sd	s6,144(sp)
  12:	0980                	addi	s0,sp,208
    fprintf(2,"-------------test1 start ---------------------\n");
  14:	00001597          	auipc	a1,0x1
  18:	a6458593          	addi	a1,a1,-1436 # a78 <malloc+0xea>
  1c:	4509                	li	a0,2
  1e:	00001097          	auipc	ra,0x1
  22:	884080e7          	jalr	-1916(ra) # 8a2 <fprintf>
    int i;
    int j;
    int pid = fork();
  26:	00000097          	auipc	ra,0x0
  2a:	52a080e7          	jalr	1322(ra) # 550 <fork>
    if(!pid){
  2e:	cd0d                	beqz	a0,68 <test1+0x68>
            fprintf(2,"Filled array num=%d with chars\n", i);
        }
        exit(0);
    }else{
        int status;
        pid = wait(&status);
  30:	f3040513          	addi	a0,s0,-208
  34:	00000097          	auipc	ra,0x0
  38:	52c080e7          	jalr	1324(ra) # 560 <wait>
  3c:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
  3e:	f3042683          	lw	a3,-208(s0)
  42:	00001597          	auipc	a1,0x1
  46:	af658593          	addi	a1,a1,-1290 # b38 <malloc+0x1aa>
  4a:	4509                	li	a0,2
  4c:	00001097          	auipc	ra,0x1
  50:	856080e7          	jalr	-1962(ra) # 8a2 <fprintf>
    }
}
  54:	60ae                	ld	ra,200(sp)
  56:	640e                	ld	s0,192(sp)
  58:	74ea                	ld	s1,184(sp)
  5a:	794a                	ld	s2,176(sp)
  5c:	79aa                	ld	s3,168(sp)
  5e:	7a0a                	ld	s4,160(sp)
  60:	6aea                	ld	s5,152(sp)
  62:	6b4a                	ld	s6,144(sp)
  64:	6169                	addi	sp,sp,208
  66:	8082                	ret
  68:	84aa                	mv	s1,a0
  6a:	f3040993          	addi	s3,s0,-208
    if(!pid){
  6e:	8a4e                	mv	s4,s3
        for(i = 0; i<18; i++){
  70:	892a                	mv	s2,a0
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  72:	00001b17          	auipc	s6,0x1
  76:	a36b0b13          	addi	s6,s6,-1482 # aa8 <malloc+0x11a>
        for(i = 0; i<18; i++){
  7a:	4ac9                	li	s5,18
           malloc_array[i] = sbrk(PGSIZE); 
  7c:	6505                	lui	a0,0x1
  7e:	00000097          	auipc	ra,0x0
  82:	562080e7          	jalr	1378(ra) # 5e0 <sbrk>
  86:	86aa                	mv	a3,a0
  88:	00aa3023          	sd	a0,0(s4)
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  8c:	864a                	mv	a2,s2
  8e:	85da                	mv	a1,s6
  90:	4509                	li	a0,2
  92:	00001097          	auipc	ra,0x1
  96:	810080e7          	jalr	-2032(ra) # 8a2 <fprintf>
        for(i = 0; i<18; i++){
  9a:	2905                	addiw	s2,s2,1
  9c:	0a21                	addi	s4,s4,8
  9e:	fd591fe3          	bne	s2,s5,7c <test1+0x7c>
        fprintf(2,"Allocated 18 pages, some of them on disk\n");
  a2:	00001597          	auipc	a1,0x1
  a6:	a2658593          	addi	a1,a1,-1498 # ac8 <malloc+0x13a>
  aa:	4509                	li	a0,2
  ac:	00000097          	auipc	ra,0x0
  b0:	7f6080e7          	jalr	2038(ra) # 8a2 <fprintf>
        fprintf(2,"Lets try to access all pages:\n");
  b4:	00001597          	auipc	a1,0x1
  b8:	a4458593          	addi	a1,a1,-1468 # af8 <malloc+0x16a>
  bc:	4509                	li	a0,2
  be:	00000097          	auipc	ra,0x0
  c2:	7e4080e7          	jalr	2020(ra) # 8a2 <fprintf>
        for(i = 0; i<18; i++){
  c6:	6b05                	lui	s6,0x1
                malloc_array[i][j] = 'x'; 
  c8:	07800913          	li	s2,120
            fprintf(2,"Filled array num=%d with chars\n", i);
  cc:	00001a97          	auipc	s5,0x1
  d0:	a4ca8a93          	addi	s5,s5,-1460 # b18 <malloc+0x18a>
        for(i = 0; i<18; i++){
  d4:	4a49                	li	s4,18
            for(j = 0; j<PGSIZE; j++)
  d6:	0009b783          	ld	a5,0(s3)
  da:	01678733          	add	a4,a5,s6
                malloc_array[i][j] = 'x'; 
  de:	01278023          	sb	s2,0(a5)
            for(j = 0; j<PGSIZE; j++)
  e2:	0785                	addi	a5,a5,1
  e4:	fef71de3          	bne	a4,a5,de <test1+0xde>
            fprintf(2,"Filled array num=%d with chars\n", i);
  e8:	8626                	mv	a2,s1
  ea:	85d6                	mv	a1,s5
  ec:	4509                	li	a0,2
  ee:	00000097          	auipc	ra,0x0
  f2:	7b4080e7          	jalr	1972(ra) # 8a2 <fprintf>
        for(i = 0; i<18; i++){
  f6:	2485                	addiw	s1,s1,1
  f8:	09a1                	addi	s3,s3,8
  fa:	fd449ee3          	bne	s1,s4,d6 <test1+0xd6>
        exit(0);
  fe:	4501                	li	a0,0
 100:	00000097          	auipc	ra,0x0
 104:	458080e7          	jalr	1112(ra) # 558 <exit>

0000000000000108 <test2>:

//Test2 testing alloc and dealloc (testing that delloa works fine, 
//and we dont recieve panic: more that 32 pages for process)
void test2(){
 108:	1141                	addi	sp,sp,-16
 10a:	e406                	sd	ra,8(sp)
 10c:	e022                	sd	s0,0(sp)
 10e:	0800                	addi	s0,sp,16
    fprintf(2,"-------------test2 start ---------------------\n");
 110:	00001597          	auipc	a1,0x1
 114:	a5058593          	addi	a1,a1,-1456 # b60 <malloc+0x1d2>
 118:	4509                	li	a0,2
 11a:	00000097          	auipc	ra,0x0
 11e:	788080e7          	jalr	1928(ra) # 8a2 <fprintf>
    char* i;
    i = sbrk(20*PGSIZE);
 122:	6551                	lui	a0,0x14
 124:	00000097          	auipc	ra,0x0
 128:	4bc080e7          	jalr	1212(ra) # 5e0 <sbrk>
 12c:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 12e:	00001597          	auipc	a1,0x1
 132:	98258593          	addi	a1,a1,-1662 # ab0 <malloc+0x122>
 136:	4509                	li	a0,2
 138:	00000097          	auipc	ra,0x0
 13c:	76a080e7          	jalr	1898(ra) # 8a2 <fprintf>
    i = sbrk(-20*PGSIZE);
 140:	7531                	lui	a0,0xfffec
 142:	00000097          	auipc	ra,0x0
 146:	49e080e7          	jalr	1182(ra) # 5e0 <sbrk>
 14a:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 14c:	00001597          	auipc	a1,0x1
 150:	a4458593          	addi	a1,a1,-1468 # b90 <malloc+0x202>
 154:	4509                	li	a0,2
 156:	00000097          	auipc	ra,0x0
 15a:	74c080e7          	jalr	1868(ra) # 8a2 <fprintf>
    i = sbrk(20*PGSIZE);
 15e:	6551                	lui	a0,0x14
 160:	00000097          	auipc	ra,0x0
 164:	480080e7          	jalr	1152(ra) # 5e0 <sbrk>
 168:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 16a:	00001597          	auipc	a1,0x1
 16e:	94658593          	addi	a1,a1,-1722 # ab0 <malloc+0x122>
 172:	4509                	li	a0,2
 174:	00000097          	auipc	ra,0x0
 178:	72e080e7          	jalr	1838(ra) # 8a2 <fprintf>
    i = sbrk(-20*PGSIZE);
 17c:	7531                	lui	a0,0xfffec
 17e:	00000097          	auipc	ra,0x0
 182:	462080e7          	jalr	1122(ra) # 5e0 <sbrk>
 186:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 188:	00001597          	auipc	a1,0x1
 18c:	a0858593          	addi	a1,a1,-1528 # b90 <malloc+0x202>
 190:	4509                	li	a0,2
 192:	00000097          	auipc	ra,0x0
 196:	710080e7          	jalr	1808(ra) # 8a2 <fprintf>
    i = sbrk(20*PGSIZE);
 19a:	6551                	lui	a0,0x14
 19c:	00000097          	auipc	ra,0x0
 1a0:	444080e7          	jalr	1092(ra) # 5e0 <sbrk>
 1a4:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 1a6:	00001597          	auipc	a1,0x1
 1aa:	90a58593          	addi	a1,a1,-1782 # ab0 <malloc+0x122>
 1ae:	4509                	li	a0,2
 1b0:	00000097          	auipc	ra,0x0
 1b4:	6f2080e7          	jalr	1778(ra) # 8a2 <fprintf>
    i = sbrk(-20*PGSIZE);
 1b8:	7531                	lui	a0,0xfffec
 1ba:	00000097          	auipc	ra,0x0
 1be:	426080e7          	jalr	1062(ra) # 5e0 <sbrk>
 1c2:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 1c4:	00001597          	auipc	a1,0x1
 1c8:	9cc58593          	addi	a1,a1,-1588 # b90 <malloc+0x202>
 1cc:	4509                	li	a0,2
 1ce:	00000097          	auipc	ra,0x0
 1d2:	6d4080e7          	jalr	1748(ra) # 8a2 <fprintf>

}
 1d6:	60a2                	ld	ra,8(sp)
 1d8:	6402                	ld	s0,0(sp)
 1da:	0141                	addi	sp,sp,16
 1dc:	8082                	ret

00000000000001de <test3>:

//Test3 - parent allocates a lot of memory, forks, 
//and child can access all his data
void test3(){
 1de:	715d                	addi	sp,sp,-80
 1e0:	e486                	sd	ra,72(sp)
 1e2:	e0a2                	sd	s0,64(sp)
 1e4:	fc26                	sd	s1,56(sp)
 1e6:	f84a                	sd	s2,48(sp)
 1e8:	f44e                	sd	s3,40(sp)
 1ea:	f052                	sd	s4,32(sp)
 1ec:	ec56                	sd	s5,24(sp)
 1ee:	e85a                	sd	s6,16(sp)
 1f0:	0880                	addi	s0,sp,80
    fprintf(2,"-------------test3 start ---------------------\n");
 1f2:	00001597          	auipc	a1,0x1
 1f6:	9be58593          	addi	a1,a1,-1602 # bb0 <malloc+0x222>
 1fa:	4509                	li	a0,2
 1fc:	00000097          	auipc	ra,0x0
 200:	6a6080e7          	jalr	1702(ra) # 8a2 <fprintf>
    uint64 i;
    char* arr = malloc(PGSIZE*17);
 204:	6545                	lui	a0,0x11
 206:	00000097          	auipc	ra,0x0
 20a:	788080e7          	jalr	1928(ra) # 98e <malloc>
 20e:	89aa                	mv	s3,a0
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 210:	4481                	li	s1,0
        arr[i] = 'a';
 212:	06100913          	li	s2,97
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 216:	00001b17          	auipc	s6,0x1
 21a:	9cab0b13          	addi	s6,s6,-1590 # be0 <malloc+0x252>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 21e:	6a85                	lui	s5,0x1
 220:	6a45                	lui	s4,0x11
        arr[i] = 'a';
 222:	009987b3          	add	a5,s3,s1
 226:	01278023          	sb	s2,0(a5)
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 22a:	86ca                	mv	a3,s2
 22c:	8626                	mv	a2,s1
 22e:	85da                	mv	a1,s6
 230:	4509                	li	a0,2
 232:	00000097          	auipc	ra,0x0
 236:	670080e7          	jalr	1648(ra) # 8a2 <fprintf>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 23a:	94d6                	add	s1,s1,s5
 23c:	ff4493e3          	bne	s1,s4,222 <test3+0x44>
    }
    int pid = fork();
 240:	00000097          	auipc	ra,0x0
 244:	310080e7          	jalr	784(ra) # 550 <fork>
    if(!pid){
 248:	c131                	beqz	a0,28c <test3+0xae>
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
        }
        exit(i);
    }else{
        int status;
        pid = wait(&status);
 24a:	fbc40513          	addi	a0,s0,-68
 24e:	00000097          	auipc	ra,0x0
 252:	312080e7          	jalr	786(ra) # 560 <wait>
 256:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
 258:	fbc42683          	lw	a3,-68(s0)
 25c:	00001597          	auipc	a1,0x1
 260:	8dc58593          	addi	a1,a1,-1828 # b38 <malloc+0x1aa>
 264:	4509                	li	a0,2
 266:	00000097          	auipc	ra,0x0
 26a:	63c080e7          	jalr	1596(ra) # 8a2 <fprintf>
        sbrk(-17*PGSIZE);
 26e:	753d                	lui	a0,0xfffef
 270:	00000097          	auipc	ra,0x0
 274:	370080e7          	jalr	880(ra) # 5e0 <sbrk>
    }
}
 278:	60a6                	ld	ra,72(sp)
 27a:	6406                	ld	s0,64(sp)
 27c:	74e2                	ld	s1,56(sp)
 27e:	7942                	ld	s2,48(sp)
 280:	79a2                	ld	s3,40(sp)
 282:	7a02                	ld	s4,32(sp)
 284:	6ae2                	ld	s5,24(sp)
 286:	6b42                	ld	s6,16(sp)
 288:	6161                	addi	sp,sp,80
 28a:	8082                	ret
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 28c:	4481                	li	s1,0
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 28e:	00001a97          	auipc	s5,0x1
 292:	96aa8a93          	addi	s5,s5,-1686 # bf8 <malloc+0x26a>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 296:	6a05                	lui	s4,0x1
 298:	6945                	lui	s2,0x11
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 29a:	009987b3          	add	a5,s3,s1
 29e:	0007c683          	lbu	a3,0(a5)
 2a2:	8626                	mv	a2,s1
 2a4:	85d6                	mv	a1,s5
 2a6:	4509                	li	a0,2
 2a8:	00000097          	auipc	ra,0x0
 2ac:	5fa080e7          	jalr	1530(ra) # 8a2 <fprintf>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2b0:	94d2                	add	s1,s1,s4
 2b2:	ff2494e3          	bne	s1,s2,29a <test3+0xbc>
        exit(i);
 2b6:	6545                	lui	a0,0x11
 2b8:	00000097          	auipc	ra,0x0
 2bc:	2a0080e7          	jalr	672(ra) # 558 <exit>

00000000000002c0 <main>:

int main(int argc, char** argv){
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e406                	sd	ra,8(sp)
 2c4:	e022                	sd	s0,0(sp)
 2c6:	0800                	addi	s0,sp,16
    test1();
 2c8:	00000097          	auipc	ra,0x0
 2cc:	d38080e7          	jalr	-712(ra) # 0 <test1>
    test2();
 2d0:	00000097          	auipc	ra,0x0
 2d4:	e38080e7          	jalr	-456(ra) # 108 <test2>
    test3();
 2d8:	00000097          	auipc	ra,0x0
 2dc:	f06080e7          	jalr	-250(ra) # 1de <test3>

    exit(0);
 2e0:	4501                	li	a0,0
 2e2:	00000097          	auipc	ra,0x0
 2e6:	276080e7          	jalr	630(ra) # 558 <exit>

00000000000002ea <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2ea:	1141                	addi	sp,sp,-16
 2ec:	e422                	sd	s0,8(sp)
 2ee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2f0:	87aa                	mv	a5,a0
 2f2:	0585                	addi	a1,a1,1
 2f4:	0785                	addi	a5,a5,1
 2f6:	fff5c703          	lbu	a4,-1(a1)
 2fa:	fee78fa3          	sb	a4,-1(a5)
 2fe:	fb75                	bnez	a4,2f2 <strcpy+0x8>
    ;
  return os;
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret

0000000000000306 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 306:	1141                	addi	sp,sp,-16
 308:	e422                	sd	s0,8(sp)
 30a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 30c:	00054783          	lbu	a5,0(a0) # 11000 <__global_pointer$+0xfbd7>
 310:	cb91                	beqz	a5,324 <strcmp+0x1e>
 312:	0005c703          	lbu	a4,0(a1)
 316:	00f71763          	bne	a4,a5,324 <strcmp+0x1e>
    p++, q++;
 31a:	0505                	addi	a0,a0,1
 31c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 31e:	00054783          	lbu	a5,0(a0)
 322:	fbe5                	bnez	a5,312 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 324:	0005c503          	lbu	a0,0(a1)
}
 328:	40a7853b          	subw	a0,a5,a0
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret

0000000000000332 <strlen>:

uint
strlen(const char *s)
{
 332:	1141                	addi	sp,sp,-16
 334:	e422                	sd	s0,8(sp)
 336:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 338:	00054783          	lbu	a5,0(a0)
 33c:	cf91                	beqz	a5,358 <strlen+0x26>
 33e:	0505                	addi	a0,a0,1
 340:	87aa                	mv	a5,a0
 342:	4685                	li	a3,1
 344:	9e89                	subw	a3,a3,a0
 346:	00f6853b          	addw	a0,a3,a5
 34a:	0785                	addi	a5,a5,1
 34c:	fff7c703          	lbu	a4,-1(a5)
 350:	fb7d                	bnez	a4,346 <strlen+0x14>
    ;
  return n;
}
 352:	6422                	ld	s0,8(sp)
 354:	0141                	addi	sp,sp,16
 356:	8082                	ret
  for(n = 0; s[n]; n++)
 358:	4501                	li	a0,0
 35a:	bfe5                	j	352 <strlen+0x20>

000000000000035c <memset>:

void*
memset(void *dst, int c, uint n)
{
 35c:	1141                	addi	sp,sp,-16
 35e:	e422                	sd	s0,8(sp)
 360:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 362:	ca19                	beqz	a2,378 <memset+0x1c>
 364:	87aa                	mv	a5,a0
 366:	1602                	slli	a2,a2,0x20
 368:	9201                	srli	a2,a2,0x20
 36a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 36e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 372:	0785                	addi	a5,a5,1
 374:	fee79de3          	bne	a5,a4,36e <memset+0x12>
  }
  return dst;
}
 378:	6422                	ld	s0,8(sp)
 37a:	0141                	addi	sp,sp,16
 37c:	8082                	ret

000000000000037e <strchr>:

char*
strchr(const char *s, char c)
{
 37e:	1141                	addi	sp,sp,-16
 380:	e422                	sd	s0,8(sp)
 382:	0800                	addi	s0,sp,16
  for(; *s; s++)
 384:	00054783          	lbu	a5,0(a0)
 388:	cb99                	beqz	a5,39e <strchr+0x20>
    if(*s == c)
 38a:	00f58763          	beq	a1,a5,398 <strchr+0x1a>
  for(; *s; s++)
 38e:	0505                	addi	a0,a0,1
 390:	00054783          	lbu	a5,0(a0)
 394:	fbfd                	bnez	a5,38a <strchr+0xc>
      return (char*)s;
  return 0;
 396:	4501                	li	a0,0
}
 398:	6422                	ld	s0,8(sp)
 39a:	0141                	addi	sp,sp,16
 39c:	8082                	ret
  return 0;
 39e:	4501                	li	a0,0
 3a0:	bfe5                	j	398 <strchr+0x1a>

00000000000003a2 <gets>:

char*
gets(char *buf, int max)
{
 3a2:	711d                	addi	sp,sp,-96
 3a4:	ec86                	sd	ra,88(sp)
 3a6:	e8a2                	sd	s0,80(sp)
 3a8:	e4a6                	sd	s1,72(sp)
 3aa:	e0ca                	sd	s2,64(sp)
 3ac:	fc4e                	sd	s3,56(sp)
 3ae:	f852                	sd	s4,48(sp)
 3b0:	f456                	sd	s5,40(sp)
 3b2:	f05a                	sd	s6,32(sp)
 3b4:	ec5e                	sd	s7,24(sp)
 3b6:	1080                	addi	s0,sp,96
 3b8:	8baa                	mv	s7,a0
 3ba:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3bc:	892a                	mv	s2,a0
 3be:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3c0:	4aa9                	li	s5,10
 3c2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3c4:	89a6                	mv	s3,s1
 3c6:	2485                	addiw	s1,s1,1
 3c8:	0344d863          	bge	s1,s4,3f8 <gets+0x56>
    cc = read(0, &c, 1);
 3cc:	4605                	li	a2,1
 3ce:	faf40593          	addi	a1,s0,-81
 3d2:	4501                	li	a0,0
 3d4:	00000097          	auipc	ra,0x0
 3d8:	19c080e7          	jalr	412(ra) # 570 <read>
    if(cc < 1)
 3dc:	00a05e63          	blez	a0,3f8 <gets+0x56>
    buf[i++] = c;
 3e0:	faf44783          	lbu	a5,-81(s0)
 3e4:	00f90023          	sb	a5,0(s2) # 11000 <__global_pointer$+0xfbd7>
    if(c == '\n' || c == '\r')
 3e8:	01578763          	beq	a5,s5,3f6 <gets+0x54>
 3ec:	0905                	addi	s2,s2,1
 3ee:	fd679be3          	bne	a5,s6,3c4 <gets+0x22>
  for(i=0; i+1 < max; ){
 3f2:	89a6                	mv	s3,s1
 3f4:	a011                	j	3f8 <gets+0x56>
 3f6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3f8:	99de                	add	s3,s3,s7
 3fa:	00098023          	sb	zero,0(s3)
  return buf;
}
 3fe:	855e                	mv	a0,s7
 400:	60e6                	ld	ra,88(sp)
 402:	6446                	ld	s0,80(sp)
 404:	64a6                	ld	s1,72(sp)
 406:	6906                	ld	s2,64(sp)
 408:	79e2                	ld	s3,56(sp)
 40a:	7a42                	ld	s4,48(sp)
 40c:	7aa2                	ld	s5,40(sp)
 40e:	7b02                	ld	s6,32(sp)
 410:	6be2                	ld	s7,24(sp)
 412:	6125                	addi	sp,sp,96
 414:	8082                	ret

0000000000000416 <stat>:

int
stat(const char *n, struct stat *st)
{
 416:	1101                	addi	sp,sp,-32
 418:	ec06                	sd	ra,24(sp)
 41a:	e822                	sd	s0,16(sp)
 41c:	e426                	sd	s1,8(sp)
 41e:	e04a                	sd	s2,0(sp)
 420:	1000                	addi	s0,sp,32
 422:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 424:	4581                	li	a1,0
 426:	00000097          	auipc	ra,0x0
 42a:	172080e7          	jalr	370(ra) # 598 <open>
  if(fd < 0)
 42e:	02054563          	bltz	a0,458 <stat+0x42>
 432:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 434:	85ca                	mv	a1,s2
 436:	00000097          	auipc	ra,0x0
 43a:	17a080e7          	jalr	378(ra) # 5b0 <fstat>
 43e:	892a                	mv	s2,a0
  close(fd);
 440:	8526                	mv	a0,s1
 442:	00000097          	auipc	ra,0x0
 446:	13e080e7          	jalr	318(ra) # 580 <close>
  return r;
}
 44a:	854a                	mv	a0,s2
 44c:	60e2                	ld	ra,24(sp)
 44e:	6442                	ld	s0,16(sp)
 450:	64a2                	ld	s1,8(sp)
 452:	6902                	ld	s2,0(sp)
 454:	6105                	addi	sp,sp,32
 456:	8082                	ret
    return -1;
 458:	597d                	li	s2,-1
 45a:	bfc5                	j	44a <stat+0x34>

000000000000045c <atoi>:

int
atoi(const char *s)
{
 45c:	1141                	addi	sp,sp,-16
 45e:	e422                	sd	s0,8(sp)
 460:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 462:	00054603          	lbu	a2,0(a0)
 466:	fd06079b          	addiw	a5,a2,-48
 46a:	0ff7f793          	andi	a5,a5,255
 46e:	4725                	li	a4,9
 470:	02f76963          	bltu	a4,a5,4a2 <atoi+0x46>
 474:	86aa                	mv	a3,a0
  n = 0;
 476:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 478:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 47a:	0685                	addi	a3,a3,1
 47c:	0025179b          	slliw	a5,a0,0x2
 480:	9fa9                	addw	a5,a5,a0
 482:	0017979b          	slliw	a5,a5,0x1
 486:	9fb1                	addw	a5,a5,a2
 488:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 48c:	0006c603          	lbu	a2,0(a3)
 490:	fd06071b          	addiw	a4,a2,-48
 494:	0ff77713          	andi	a4,a4,255
 498:	fee5f1e3          	bgeu	a1,a4,47a <atoi+0x1e>
  return n;
}
 49c:	6422                	ld	s0,8(sp)
 49e:	0141                	addi	sp,sp,16
 4a0:	8082                	ret
  n = 0;
 4a2:	4501                	li	a0,0
 4a4:	bfe5                	j	49c <atoi+0x40>

00000000000004a6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4a6:	1141                	addi	sp,sp,-16
 4a8:	e422                	sd	s0,8(sp)
 4aa:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4ac:	02b57463          	bgeu	a0,a1,4d4 <memmove+0x2e>
    while(n-- > 0)
 4b0:	00c05f63          	blez	a2,4ce <memmove+0x28>
 4b4:	1602                	slli	a2,a2,0x20
 4b6:	9201                	srli	a2,a2,0x20
 4b8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4bc:	872a                	mv	a4,a0
      *dst++ = *src++;
 4be:	0585                	addi	a1,a1,1
 4c0:	0705                	addi	a4,a4,1
 4c2:	fff5c683          	lbu	a3,-1(a1)
 4c6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4ca:	fee79ae3          	bne	a5,a4,4be <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4ce:	6422                	ld	s0,8(sp)
 4d0:	0141                	addi	sp,sp,16
 4d2:	8082                	ret
    dst += n;
 4d4:	00c50733          	add	a4,a0,a2
    src += n;
 4d8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4da:	fec05ae3          	blez	a2,4ce <memmove+0x28>
 4de:	fff6079b          	addiw	a5,a2,-1
 4e2:	1782                	slli	a5,a5,0x20
 4e4:	9381                	srli	a5,a5,0x20
 4e6:	fff7c793          	not	a5,a5
 4ea:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4ec:	15fd                	addi	a1,a1,-1
 4ee:	177d                	addi	a4,a4,-1
 4f0:	0005c683          	lbu	a3,0(a1)
 4f4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4f8:	fee79ae3          	bne	a5,a4,4ec <memmove+0x46>
 4fc:	bfc9                	j	4ce <memmove+0x28>

00000000000004fe <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4fe:	1141                	addi	sp,sp,-16
 500:	e422                	sd	s0,8(sp)
 502:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 504:	ca05                	beqz	a2,534 <memcmp+0x36>
 506:	fff6069b          	addiw	a3,a2,-1
 50a:	1682                	slli	a3,a3,0x20
 50c:	9281                	srli	a3,a3,0x20
 50e:	0685                	addi	a3,a3,1
 510:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 512:	00054783          	lbu	a5,0(a0)
 516:	0005c703          	lbu	a4,0(a1)
 51a:	00e79863          	bne	a5,a4,52a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 51e:	0505                	addi	a0,a0,1
    p2++;
 520:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 522:	fed518e3          	bne	a0,a3,512 <memcmp+0x14>
  }
  return 0;
 526:	4501                	li	a0,0
 528:	a019                	j	52e <memcmp+0x30>
      return *p1 - *p2;
 52a:	40e7853b          	subw	a0,a5,a4
}
 52e:	6422                	ld	s0,8(sp)
 530:	0141                	addi	sp,sp,16
 532:	8082                	ret
  return 0;
 534:	4501                	li	a0,0
 536:	bfe5                	j	52e <memcmp+0x30>

0000000000000538 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 538:	1141                	addi	sp,sp,-16
 53a:	e406                	sd	ra,8(sp)
 53c:	e022                	sd	s0,0(sp)
 53e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 540:	00000097          	auipc	ra,0x0
 544:	f66080e7          	jalr	-154(ra) # 4a6 <memmove>
}
 548:	60a2                	ld	ra,8(sp)
 54a:	6402                	ld	s0,0(sp)
 54c:	0141                	addi	sp,sp,16
 54e:	8082                	ret

0000000000000550 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 550:	4885                	li	a7,1
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <exit>:
.global exit
exit:
 li a7, SYS_exit
 558:	4889                	li	a7,2
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <wait>:
.global wait
wait:
 li a7, SYS_wait
 560:	488d                	li	a7,3
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 568:	4891                	li	a7,4
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <read>:
.global read
read:
 li a7, SYS_read
 570:	4895                	li	a7,5
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <write>:
.global write
write:
 li a7, SYS_write
 578:	48c1                	li	a7,16
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <close>:
.global close
close:
 li a7, SYS_close
 580:	48d5                	li	a7,21
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <kill>:
.global kill
kill:
 li a7, SYS_kill
 588:	4899                	li	a7,6
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <exec>:
.global exec
exec:
 li a7, SYS_exec
 590:	489d                	li	a7,7
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <open>:
.global open
open:
 li a7, SYS_open
 598:	48bd                	li	a7,15
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5a0:	48c5                	li	a7,17
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5a8:	48c9                	li	a7,18
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5b0:	48a1                	li	a7,8
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <link>:
.global link
link:
 li a7, SYS_link
 5b8:	48cd                	li	a7,19
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5c0:	48d1                	li	a7,20
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5c8:	48a5                	li	a7,9
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5d0:	48a9                	li	a7,10
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5d8:	48ad                	li	a7,11
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5e0:	48b1                	li	a7,12
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5e8:	48b5                	li	a7,13
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5f0:	48b9                	li	a7,14
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5f8:	1101                	addi	sp,sp,-32
 5fa:	ec06                	sd	ra,24(sp)
 5fc:	e822                	sd	s0,16(sp)
 5fe:	1000                	addi	s0,sp,32
 600:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 604:	4605                	li	a2,1
 606:	fef40593          	addi	a1,s0,-17
 60a:	00000097          	auipc	ra,0x0
 60e:	f6e080e7          	jalr	-146(ra) # 578 <write>
}
 612:	60e2                	ld	ra,24(sp)
 614:	6442                	ld	s0,16(sp)
 616:	6105                	addi	sp,sp,32
 618:	8082                	ret

000000000000061a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 61a:	7139                	addi	sp,sp,-64
 61c:	fc06                	sd	ra,56(sp)
 61e:	f822                	sd	s0,48(sp)
 620:	f426                	sd	s1,40(sp)
 622:	f04a                	sd	s2,32(sp)
 624:	ec4e                	sd	s3,24(sp)
 626:	0080                	addi	s0,sp,64
 628:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 62a:	c299                	beqz	a3,630 <printint+0x16>
 62c:	0805c863          	bltz	a1,6bc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 630:	2581                	sext.w	a1,a1
  neg = 0;
 632:	4881                	li	a7,0
 634:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 638:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 63a:	2601                	sext.w	a2,a2
 63c:	00000517          	auipc	a0,0x0
 640:	5dc50513          	addi	a0,a0,1500 # c18 <digits>
 644:	883a                	mv	a6,a4
 646:	2705                	addiw	a4,a4,1
 648:	02c5f7bb          	remuw	a5,a1,a2
 64c:	1782                	slli	a5,a5,0x20
 64e:	9381                	srli	a5,a5,0x20
 650:	97aa                	add	a5,a5,a0
 652:	0007c783          	lbu	a5,0(a5)
 656:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 65a:	0005879b          	sext.w	a5,a1
 65e:	02c5d5bb          	divuw	a1,a1,a2
 662:	0685                	addi	a3,a3,1
 664:	fec7f0e3          	bgeu	a5,a2,644 <printint+0x2a>
  if(neg)
 668:	00088b63          	beqz	a7,67e <printint+0x64>
    buf[i++] = '-';
 66c:	fd040793          	addi	a5,s0,-48
 670:	973e                	add	a4,a4,a5
 672:	02d00793          	li	a5,45
 676:	fef70823          	sb	a5,-16(a4)
 67a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 67e:	02e05863          	blez	a4,6ae <printint+0x94>
 682:	fc040793          	addi	a5,s0,-64
 686:	00e78933          	add	s2,a5,a4
 68a:	fff78993          	addi	s3,a5,-1
 68e:	99ba                	add	s3,s3,a4
 690:	377d                	addiw	a4,a4,-1
 692:	1702                	slli	a4,a4,0x20
 694:	9301                	srli	a4,a4,0x20
 696:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 69a:	fff94583          	lbu	a1,-1(s2)
 69e:	8526                	mv	a0,s1
 6a0:	00000097          	auipc	ra,0x0
 6a4:	f58080e7          	jalr	-168(ra) # 5f8 <putc>
  while(--i >= 0)
 6a8:	197d                	addi	s2,s2,-1
 6aa:	ff3918e3          	bne	s2,s3,69a <printint+0x80>
}
 6ae:	70e2                	ld	ra,56(sp)
 6b0:	7442                	ld	s0,48(sp)
 6b2:	74a2                	ld	s1,40(sp)
 6b4:	7902                	ld	s2,32(sp)
 6b6:	69e2                	ld	s3,24(sp)
 6b8:	6121                	addi	sp,sp,64
 6ba:	8082                	ret
    x = -xx;
 6bc:	40b005bb          	negw	a1,a1
    neg = 1;
 6c0:	4885                	li	a7,1
    x = -xx;
 6c2:	bf8d                	j	634 <printint+0x1a>

00000000000006c4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6c4:	7119                	addi	sp,sp,-128
 6c6:	fc86                	sd	ra,120(sp)
 6c8:	f8a2                	sd	s0,112(sp)
 6ca:	f4a6                	sd	s1,104(sp)
 6cc:	f0ca                	sd	s2,96(sp)
 6ce:	ecce                	sd	s3,88(sp)
 6d0:	e8d2                	sd	s4,80(sp)
 6d2:	e4d6                	sd	s5,72(sp)
 6d4:	e0da                	sd	s6,64(sp)
 6d6:	fc5e                	sd	s7,56(sp)
 6d8:	f862                	sd	s8,48(sp)
 6da:	f466                	sd	s9,40(sp)
 6dc:	f06a                	sd	s10,32(sp)
 6de:	ec6e                	sd	s11,24(sp)
 6e0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6e2:	0005c903          	lbu	s2,0(a1)
 6e6:	18090f63          	beqz	s2,884 <vprintf+0x1c0>
 6ea:	8aaa                	mv	s5,a0
 6ec:	8b32                	mv	s6,a2
 6ee:	00158493          	addi	s1,a1,1
  state = 0;
 6f2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6f4:	02500a13          	li	s4,37
      if(c == 'd'){
 6f8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6fc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 700:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 704:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 708:	00000b97          	auipc	s7,0x0
 70c:	510b8b93          	addi	s7,s7,1296 # c18 <digits>
 710:	a839                	j	72e <vprintf+0x6a>
        putc(fd, c);
 712:	85ca                	mv	a1,s2
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	ee2080e7          	jalr	-286(ra) # 5f8 <putc>
 71e:	a019                	j	724 <vprintf+0x60>
    } else if(state == '%'){
 720:	01498f63          	beq	s3,s4,73e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 724:	0485                	addi	s1,s1,1
 726:	fff4c903          	lbu	s2,-1(s1)
 72a:	14090d63          	beqz	s2,884 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 72e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 732:	fe0997e3          	bnez	s3,720 <vprintf+0x5c>
      if(c == '%'){
 736:	fd479ee3          	bne	a5,s4,712 <vprintf+0x4e>
        state = '%';
 73a:	89be                	mv	s3,a5
 73c:	b7e5                	j	724 <vprintf+0x60>
      if(c == 'd'){
 73e:	05878063          	beq	a5,s8,77e <vprintf+0xba>
      } else if(c == 'l') {
 742:	05978c63          	beq	a5,s9,79a <vprintf+0xd6>
      } else if(c == 'x') {
 746:	07a78863          	beq	a5,s10,7b6 <vprintf+0xf2>
      } else if(c == 'p') {
 74a:	09b78463          	beq	a5,s11,7d2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 74e:	07300713          	li	a4,115
 752:	0ce78663          	beq	a5,a4,81e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 756:	06300713          	li	a4,99
 75a:	0ee78e63          	beq	a5,a4,856 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 75e:	11478863          	beq	a5,s4,86e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 762:	85d2                	mv	a1,s4
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	e92080e7          	jalr	-366(ra) # 5f8 <putc>
        putc(fd, c);
 76e:	85ca                	mv	a1,s2
 770:	8556                	mv	a0,s5
 772:	00000097          	auipc	ra,0x0
 776:	e86080e7          	jalr	-378(ra) # 5f8 <putc>
      }
      state = 0;
 77a:	4981                	li	s3,0
 77c:	b765                	j	724 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 77e:	008b0913          	addi	s2,s6,8
 782:	4685                	li	a3,1
 784:	4629                	li	a2,10
 786:	000b2583          	lw	a1,0(s6)
 78a:	8556                	mv	a0,s5
 78c:	00000097          	auipc	ra,0x0
 790:	e8e080e7          	jalr	-370(ra) # 61a <printint>
 794:	8b4a                	mv	s6,s2
      state = 0;
 796:	4981                	li	s3,0
 798:	b771                	j	724 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 79a:	008b0913          	addi	s2,s6,8
 79e:	4681                	li	a3,0
 7a0:	4629                	li	a2,10
 7a2:	000b2583          	lw	a1,0(s6)
 7a6:	8556                	mv	a0,s5
 7a8:	00000097          	auipc	ra,0x0
 7ac:	e72080e7          	jalr	-398(ra) # 61a <printint>
 7b0:	8b4a                	mv	s6,s2
      state = 0;
 7b2:	4981                	li	s3,0
 7b4:	bf85                	j	724 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7b6:	008b0913          	addi	s2,s6,8
 7ba:	4681                	li	a3,0
 7bc:	4641                	li	a2,16
 7be:	000b2583          	lw	a1,0(s6)
 7c2:	8556                	mv	a0,s5
 7c4:	00000097          	auipc	ra,0x0
 7c8:	e56080e7          	jalr	-426(ra) # 61a <printint>
 7cc:	8b4a                	mv	s6,s2
      state = 0;
 7ce:	4981                	li	s3,0
 7d0:	bf91                	j	724 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7d2:	008b0793          	addi	a5,s6,8
 7d6:	f8f43423          	sd	a5,-120(s0)
 7da:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7de:	03000593          	li	a1,48
 7e2:	8556                	mv	a0,s5
 7e4:	00000097          	auipc	ra,0x0
 7e8:	e14080e7          	jalr	-492(ra) # 5f8 <putc>
  putc(fd, 'x');
 7ec:	85ea                	mv	a1,s10
 7ee:	8556                	mv	a0,s5
 7f0:	00000097          	auipc	ra,0x0
 7f4:	e08080e7          	jalr	-504(ra) # 5f8 <putc>
 7f8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7fa:	03c9d793          	srli	a5,s3,0x3c
 7fe:	97de                	add	a5,a5,s7
 800:	0007c583          	lbu	a1,0(a5)
 804:	8556                	mv	a0,s5
 806:	00000097          	auipc	ra,0x0
 80a:	df2080e7          	jalr	-526(ra) # 5f8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 80e:	0992                	slli	s3,s3,0x4
 810:	397d                	addiw	s2,s2,-1
 812:	fe0914e3          	bnez	s2,7fa <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 816:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 81a:	4981                	li	s3,0
 81c:	b721                	j	724 <vprintf+0x60>
        s = va_arg(ap, char*);
 81e:	008b0993          	addi	s3,s6,8
 822:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 826:	02090163          	beqz	s2,848 <vprintf+0x184>
        while(*s != 0){
 82a:	00094583          	lbu	a1,0(s2)
 82e:	c9a1                	beqz	a1,87e <vprintf+0x1ba>
          putc(fd, *s);
 830:	8556                	mv	a0,s5
 832:	00000097          	auipc	ra,0x0
 836:	dc6080e7          	jalr	-570(ra) # 5f8 <putc>
          s++;
 83a:	0905                	addi	s2,s2,1
        while(*s != 0){
 83c:	00094583          	lbu	a1,0(s2)
 840:	f9e5                	bnez	a1,830 <vprintf+0x16c>
        s = va_arg(ap, char*);
 842:	8b4e                	mv	s6,s3
      state = 0;
 844:	4981                	li	s3,0
 846:	bdf9                	j	724 <vprintf+0x60>
          s = "(null)";
 848:	00000917          	auipc	s2,0x0
 84c:	3c890913          	addi	s2,s2,968 # c10 <malloc+0x282>
        while(*s != 0){
 850:	02800593          	li	a1,40
 854:	bff1                	j	830 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 856:	008b0913          	addi	s2,s6,8
 85a:	000b4583          	lbu	a1,0(s6)
 85e:	8556                	mv	a0,s5
 860:	00000097          	auipc	ra,0x0
 864:	d98080e7          	jalr	-616(ra) # 5f8 <putc>
 868:	8b4a                	mv	s6,s2
      state = 0;
 86a:	4981                	li	s3,0
 86c:	bd65                	j	724 <vprintf+0x60>
        putc(fd, c);
 86e:	85d2                	mv	a1,s4
 870:	8556                	mv	a0,s5
 872:	00000097          	auipc	ra,0x0
 876:	d86080e7          	jalr	-634(ra) # 5f8 <putc>
      state = 0;
 87a:	4981                	li	s3,0
 87c:	b565                	j	724 <vprintf+0x60>
        s = va_arg(ap, char*);
 87e:	8b4e                	mv	s6,s3
      state = 0;
 880:	4981                	li	s3,0
 882:	b54d                	j	724 <vprintf+0x60>
    }
  }
}
 884:	70e6                	ld	ra,120(sp)
 886:	7446                	ld	s0,112(sp)
 888:	74a6                	ld	s1,104(sp)
 88a:	7906                	ld	s2,96(sp)
 88c:	69e6                	ld	s3,88(sp)
 88e:	6a46                	ld	s4,80(sp)
 890:	6aa6                	ld	s5,72(sp)
 892:	6b06                	ld	s6,64(sp)
 894:	7be2                	ld	s7,56(sp)
 896:	7c42                	ld	s8,48(sp)
 898:	7ca2                	ld	s9,40(sp)
 89a:	7d02                	ld	s10,32(sp)
 89c:	6de2                	ld	s11,24(sp)
 89e:	6109                	addi	sp,sp,128
 8a0:	8082                	ret

00000000000008a2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8a2:	715d                	addi	sp,sp,-80
 8a4:	ec06                	sd	ra,24(sp)
 8a6:	e822                	sd	s0,16(sp)
 8a8:	1000                	addi	s0,sp,32
 8aa:	e010                	sd	a2,0(s0)
 8ac:	e414                	sd	a3,8(s0)
 8ae:	e818                	sd	a4,16(s0)
 8b0:	ec1c                	sd	a5,24(s0)
 8b2:	03043023          	sd	a6,32(s0)
 8b6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8ba:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8be:	8622                	mv	a2,s0
 8c0:	00000097          	auipc	ra,0x0
 8c4:	e04080e7          	jalr	-508(ra) # 6c4 <vprintf>
}
 8c8:	60e2                	ld	ra,24(sp)
 8ca:	6442                	ld	s0,16(sp)
 8cc:	6161                	addi	sp,sp,80
 8ce:	8082                	ret

00000000000008d0 <printf>:

void
printf(const char *fmt, ...)
{
 8d0:	711d                	addi	sp,sp,-96
 8d2:	ec06                	sd	ra,24(sp)
 8d4:	e822                	sd	s0,16(sp)
 8d6:	1000                	addi	s0,sp,32
 8d8:	e40c                	sd	a1,8(s0)
 8da:	e810                	sd	a2,16(s0)
 8dc:	ec14                	sd	a3,24(s0)
 8de:	f018                	sd	a4,32(s0)
 8e0:	f41c                	sd	a5,40(s0)
 8e2:	03043823          	sd	a6,48(s0)
 8e6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8ea:	00840613          	addi	a2,s0,8
 8ee:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8f2:	85aa                	mv	a1,a0
 8f4:	4505                	li	a0,1
 8f6:	00000097          	auipc	ra,0x0
 8fa:	dce080e7          	jalr	-562(ra) # 6c4 <vprintf>
}
 8fe:	60e2                	ld	ra,24(sp)
 900:	6442                	ld	s0,16(sp)
 902:	6125                	addi	sp,sp,96
 904:	8082                	ret

0000000000000906 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 906:	1141                	addi	sp,sp,-16
 908:	e422                	sd	s0,8(sp)
 90a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 90c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 910:	00000797          	auipc	a5,0x0
 914:	3207b783          	ld	a5,800(a5) # c30 <freep>
 918:	a805                	j	948 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 91a:	4618                	lw	a4,8(a2)
 91c:	9db9                	addw	a1,a1,a4
 91e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 922:	6398                	ld	a4,0(a5)
 924:	6318                	ld	a4,0(a4)
 926:	fee53823          	sd	a4,-16(a0)
 92a:	a091                	j	96e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 92c:	ff852703          	lw	a4,-8(a0)
 930:	9e39                	addw	a2,a2,a4
 932:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 934:	ff053703          	ld	a4,-16(a0)
 938:	e398                	sd	a4,0(a5)
 93a:	a099                	j	980 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 93c:	6398                	ld	a4,0(a5)
 93e:	00e7e463          	bltu	a5,a4,946 <free+0x40>
 942:	00e6ea63          	bltu	a3,a4,956 <free+0x50>
{
 946:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 948:	fed7fae3          	bgeu	a5,a3,93c <free+0x36>
 94c:	6398                	ld	a4,0(a5)
 94e:	00e6e463          	bltu	a3,a4,956 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 952:	fee7eae3          	bltu	a5,a4,946 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 956:	ff852583          	lw	a1,-8(a0)
 95a:	6390                	ld	a2,0(a5)
 95c:	02059813          	slli	a6,a1,0x20
 960:	01c85713          	srli	a4,a6,0x1c
 964:	9736                	add	a4,a4,a3
 966:	fae60ae3          	beq	a2,a4,91a <free+0x14>
    bp->s.ptr = p->s.ptr;
 96a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 96e:	4790                	lw	a2,8(a5)
 970:	02061593          	slli	a1,a2,0x20
 974:	01c5d713          	srli	a4,a1,0x1c
 978:	973e                	add	a4,a4,a5
 97a:	fae689e3          	beq	a3,a4,92c <free+0x26>
  } else
    p->s.ptr = bp;
 97e:	e394                	sd	a3,0(a5)
  freep = p;
 980:	00000717          	auipc	a4,0x0
 984:	2af73823          	sd	a5,688(a4) # c30 <freep>
}
 988:	6422                	ld	s0,8(sp)
 98a:	0141                	addi	sp,sp,16
 98c:	8082                	ret

000000000000098e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 98e:	7139                	addi	sp,sp,-64
 990:	fc06                	sd	ra,56(sp)
 992:	f822                	sd	s0,48(sp)
 994:	f426                	sd	s1,40(sp)
 996:	f04a                	sd	s2,32(sp)
 998:	ec4e                	sd	s3,24(sp)
 99a:	e852                	sd	s4,16(sp)
 99c:	e456                	sd	s5,8(sp)
 99e:	e05a                	sd	s6,0(sp)
 9a0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9a2:	02051493          	slli	s1,a0,0x20
 9a6:	9081                	srli	s1,s1,0x20
 9a8:	04bd                	addi	s1,s1,15
 9aa:	8091                	srli	s1,s1,0x4
 9ac:	0014899b          	addiw	s3,s1,1
 9b0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9b2:	00000517          	auipc	a0,0x0
 9b6:	27e53503          	ld	a0,638(a0) # c30 <freep>
 9ba:	c515                	beqz	a0,9e6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9be:	4798                	lw	a4,8(a5)
 9c0:	02977f63          	bgeu	a4,s1,9fe <malloc+0x70>
 9c4:	8a4e                	mv	s4,s3
 9c6:	0009871b          	sext.w	a4,s3
 9ca:	6685                	lui	a3,0x1
 9cc:	00d77363          	bgeu	a4,a3,9d2 <malloc+0x44>
 9d0:	6a05                	lui	s4,0x1
 9d2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9d6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9da:	00000917          	auipc	s2,0x0
 9de:	25690913          	addi	s2,s2,598 # c30 <freep>
  if(p == (char*)-1)
 9e2:	5afd                	li	s5,-1
 9e4:	a895                	j	a58 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 9e6:	00000797          	auipc	a5,0x0
 9ea:	25278793          	addi	a5,a5,594 # c38 <base>
 9ee:	00000717          	auipc	a4,0x0
 9f2:	24f73123          	sd	a5,578(a4) # c30 <freep>
 9f6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9f8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9fc:	b7e1                	j	9c4 <malloc+0x36>
      if(p->s.size == nunits)
 9fe:	02e48c63          	beq	s1,a4,a36 <malloc+0xa8>
        p->s.size -= nunits;
 a02:	4137073b          	subw	a4,a4,s3
 a06:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a08:	02071693          	slli	a3,a4,0x20
 a0c:	01c6d713          	srli	a4,a3,0x1c
 a10:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a12:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a16:	00000717          	auipc	a4,0x0
 a1a:	20a73d23          	sd	a0,538(a4) # c30 <freep>
      return (void*)(p + 1);
 a1e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a22:	70e2                	ld	ra,56(sp)
 a24:	7442                	ld	s0,48(sp)
 a26:	74a2                	ld	s1,40(sp)
 a28:	7902                	ld	s2,32(sp)
 a2a:	69e2                	ld	s3,24(sp)
 a2c:	6a42                	ld	s4,16(sp)
 a2e:	6aa2                	ld	s5,8(sp)
 a30:	6b02                	ld	s6,0(sp)
 a32:	6121                	addi	sp,sp,64
 a34:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a36:	6398                	ld	a4,0(a5)
 a38:	e118                	sd	a4,0(a0)
 a3a:	bff1                	j	a16 <malloc+0x88>
  hp->s.size = nu;
 a3c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a40:	0541                	addi	a0,a0,16
 a42:	00000097          	auipc	ra,0x0
 a46:	ec4080e7          	jalr	-316(ra) # 906 <free>
  return freep;
 a4a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a4e:	d971                	beqz	a0,a22 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a50:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a52:	4798                	lw	a4,8(a5)
 a54:	fa9775e3          	bgeu	a4,s1,9fe <malloc+0x70>
    if(p == freep)
 a58:	00093703          	ld	a4,0(s2)
 a5c:	853e                	mv	a0,a5
 a5e:	fef719e3          	bne	a4,a5,a50 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a62:	8552                	mv	a0,s4
 a64:	00000097          	auipc	ra,0x0
 a68:	b7c080e7          	jalr	-1156(ra) # 5e0 <sbrk>
  if(p == (char*)-1)
 a6c:	fd5518e3          	bne	a0,s5,a3c <malloc+0xae>
        return 0;
 a70:	4501                	li	a0,0
 a72:	bf45                	j	a22 <malloc+0x94>
