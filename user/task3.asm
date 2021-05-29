
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
  18:	c3458593          	addi	a1,a1,-972 # c48 <malloc+0xea>
  1c:	4509                	li	a0,2
  1e:	00001097          	auipc	ra,0x1
  22:	a54080e7          	jalr	-1452(ra) # a72 <fprintf>
    int i;
    int j;
    int pid = fork();
  26:	00000097          	auipc	ra,0x0
  2a:	6fa080e7          	jalr	1786(ra) # 720 <fork>
    if(!pid){
  2e:	c531                	beqz	a0,7a <test1+0x7a>
            fprintf(2,"Filled array num=%d with chars\n", i);
        }
        exit(0);
    }else{
        int status;
        pid = wait(&status);
  30:	f3040513          	addi	a0,s0,-208
  34:	00000097          	auipc	ra,0x0
  38:	6fc080e7          	jalr	1788(ra) # 730 <wait>
  3c:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
  3e:	f3042683          	lw	a3,-208(s0)
  42:	00001597          	auipc	a1,0x1
  46:	cc658593          	addi	a1,a1,-826 # d08 <malloc+0x1aa>
  4a:	4509                	li	a0,2
  4c:	00001097          	auipc	ra,0x1
  50:	a26080e7          	jalr	-1498(ra) # a72 <fprintf>
    }
        fprintf(2,"-------------test1 finished ---------------------\n");
  54:	00001597          	auipc	a1,0x1
  58:	cdc58593          	addi	a1,a1,-804 # d30 <malloc+0x1d2>
  5c:	4509                	li	a0,2
  5e:	00001097          	auipc	ra,0x1
  62:	a14080e7          	jalr	-1516(ra) # a72 <fprintf>

}
  66:	60ae                	ld	ra,200(sp)
  68:	640e                	ld	s0,192(sp)
  6a:	74ea                	ld	s1,184(sp)
  6c:	794a                	ld	s2,176(sp)
  6e:	79aa                	ld	s3,168(sp)
  70:	7a0a                	ld	s4,160(sp)
  72:	6aea                	ld	s5,152(sp)
  74:	6b4a                	ld	s6,144(sp)
  76:	6169                	addi	sp,sp,208
  78:	8082                	ret
  7a:	84aa                	mv	s1,a0
  7c:	f3040993          	addi	s3,s0,-208
    if(!pid){
  80:	8a4e                	mv	s4,s3
        for(i = 0; i<18; i++){
  82:	892a                	mv	s2,a0
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  84:	00001b17          	auipc	s6,0x1
  88:	bf4b0b13          	addi	s6,s6,-1036 # c78 <malloc+0x11a>
        for(i = 0; i<18; i++){
  8c:	4ac9                	li	s5,18
           malloc_array[i] = sbrk(PGSIZE); 
  8e:	6505                	lui	a0,0x1
  90:	00000097          	auipc	ra,0x0
  94:	720080e7          	jalr	1824(ra) # 7b0 <sbrk>
  98:	86aa                	mv	a3,a0
  9a:	00aa3023          	sd	a0,0(s4)
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  9e:	864a                	mv	a2,s2
  a0:	85da                	mv	a1,s6
  a2:	4509                	li	a0,2
  a4:	00001097          	auipc	ra,0x1
  a8:	9ce080e7          	jalr	-1586(ra) # a72 <fprintf>
        for(i = 0; i<18; i++){
  ac:	2905                	addiw	s2,s2,1
  ae:	0a21                	addi	s4,s4,8
  b0:	fd591fe3          	bne	s2,s5,8e <test1+0x8e>
        fprintf(2,"Allocated 18 pages, some of them on disk\n");
  b4:	00001597          	auipc	a1,0x1
  b8:	be458593          	addi	a1,a1,-1052 # c98 <malloc+0x13a>
  bc:	4509                	li	a0,2
  be:	00001097          	auipc	ra,0x1
  c2:	9b4080e7          	jalr	-1612(ra) # a72 <fprintf>
        fprintf(2,"Lets try to access all pages:\n");
  c6:	00001597          	auipc	a1,0x1
  ca:	c0258593          	addi	a1,a1,-1022 # cc8 <malloc+0x16a>
  ce:	4509                	li	a0,2
  d0:	00001097          	auipc	ra,0x1
  d4:	9a2080e7          	jalr	-1630(ra) # a72 <fprintf>
        for(i = 0; i<18; i++){
  d8:	6b05                	lui	s6,0x1
                malloc_array[i][j] = 'x'; 
  da:	07800913          	li	s2,120
            fprintf(2,"Filled array num=%d with chars\n", i);
  de:	00001a97          	auipc	s5,0x1
  e2:	c0aa8a93          	addi	s5,s5,-1014 # ce8 <malloc+0x18a>
        for(i = 0; i<18; i++){
  e6:	4a49                	li	s4,18
            for(j = 0; j<PGSIZE; j++)
  e8:	0009b783          	ld	a5,0(s3)
  ec:	01678733          	add	a4,a5,s6
                malloc_array[i][j] = 'x'; 
  f0:	01278023          	sb	s2,0(a5)
            for(j = 0; j<PGSIZE; j++)
  f4:	0785                	addi	a5,a5,1
  f6:	fef71de3          	bne	a4,a5,f0 <test1+0xf0>
            fprintf(2,"Filled array num=%d with chars\n", i);
  fa:	8626                	mv	a2,s1
  fc:	85d6                	mv	a1,s5
  fe:	4509                	li	a0,2
 100:	00001097          	auipc	ra,0x1
 104:	972080e7          	jalr	-1678(ra) # a72 <fprintf>
        for(i = 0; i<18; i++){
 108:	2485                	addiw	s1,s1,1
 10a:	09a1                	addi	s3,s3,8
 10c:	fd449ee3          	bne	s1,s4,e8 <test1+0xe8>
        exit(0);
 110:	4501                	li	a0,0
 112:	00000097          	auipc	ra,0x0
 116:	616080e7          	jalr	1558(ra) # 728 <exit>

000000000000011a <test2>:

//Test2 testing alloc and dealloc (testing that delloa works fine, 
//and we dont recieve panic: more that 32 pages for process)
void test2(){
 11a:	1141                	addi	sp,sp,-16
 11c:	e406                	sd	ra,8(sp)
 11e:	e022                	sd	s0,0(sp)
 120:	0800                	addi	s0,sp,16
    fprintf(2,"-------------test2 start ---------------------\n");
 122:	00001597          	auipc	a1,0x1
 126:	c4658593          	addi	a1,a1,-954 # d68 <malloc+0x20a>
 12a:	4509                	li	a0,2
 12c:	00001097          	auipc	ra,0x1
 130:	946080e7          	jalr	-1722(ra) # a72 <fprintf>
    char* i;
    i = sbrk(20*PGSIZE);
 134:	6551                	lui	a0,0x14
 136:	00000097          	auipc	ra,0x0
 13a:	67a080e7          	jalr	1658(ra) # 7b0 <sbrk>
 13e:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 140:	00001597          	auipc	a1,0x1
 144:	b4058593          	addi	a1,a1,-1216 # c80 <malloc+0x122>
 148:	4509                	li	a0,2
 14a:	00001097          	auipc	ra,0x1
 14e:	928080e7          	jalr	-1752(ra) # a72 <fprintf>
    i = sbrk(-20*PGSIZE);
 152:	7531                	lui	a0,0xfffec
 154:	00000097          	auipc	ra,0x0
 158:	65c080e7          	jalr	1628(ra) # 7b0 <sbrk>
 15c:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 15e:	00001597          	auipc	a1,0x1
 162:	c3a58593          	addi	a1,a1,-966 # d98 <malloc+0x23a>
 166:	4509                	li	a0,2
 168:	00001097          	auipc	ra,0x1
 16c:	90a080e7          	jalr	-1782(ra) # a72 <fprintf>
    i = sbrk(20*PGSIZE);
 170:	6551                	lui	a0,0x14
 172:	00000097          	auipc	ra,0x0
 176:	63e080e7          	jalr	1598(ra) # 7b0 <sbrk>
 17a:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 17c:	00001597          	auipc	a1,0x1
 180:	b0458593          	addi	a1,a1,-1276 # c80 <malloc+0x122>
 184:	4509                	li	a0,2
 186:	00001097          	auipc	ra,0x1
 18a:	8ec080e7          	jalr	-1812(ra) # a72 <fprintf>
    i = sbrk(-20*PGSIZE);
 18e:	7531                	lui	a0,0xfffec
 190:	00000097          	auipc	ra,0x0
 194:	620080e7          	jalr	1568(ra) # 7b0 <sbrk>
 198:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 19a:	00001597          	auipc	a1,0x1
 19e:	bfe58593          	addi	a1,a1,-1026 # d98 <malloc+0x23a>
 1a2:	4509                	li	a0,2
 1a4:	00001097          	auipc	ra,0x1
 1a8:	8ce080e7          	jalr	-1842(ra) # a72 <fprintf>
    i = sbrk(20*PGSIZE);
 1ac:	6551                	lui	a0,0x14
 1ae:	00000097          	auipc	ra,0x0
 1b2:	602080e7          	jalr	1538(ra) # 7b0 <sbrk>
 1b6:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 1b8:	00001597          	auipc	a1,0x1
 1bc:	ac858593          	addi	a1,a1,-1336 # c80 <malloc+0x122>
 1c0:	4509                	li	a0,2
 1c2:	00001097          	auipc	ra,0x1
 1c6:	8b0080e7          	jalr	-1872(ra) # a72 <fprintf>
    i = sbrk(-20*PGSIZE);
 1ca:	7531                	lui	a0,0xfffec
 1cc:	00000097          	auipc	ra,0x0
 1d0:	5e4080e7          	jalr	1508(ra) # 7b0 <sbrk>
 1d4:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 1d6:	00001597          	auipc	a1,0x1
 1da:	bc258593          	addi	a1,a1,-1086 # d98 <malloc+0x23a>
 1de:	4509                	li	a0,2
 1e0:	00001097          	auipc	ra,0x1
 1e4:	892080e7          	jalr	-1902(ra) # a72 <fprintf>

    fprintf(2,"-------------test2 finished ---------------------\n");
 1e8:	00001597          	auipc	a1,0x1
 1ec:	bd058593          	addi	a1,a1,-1072 # db8 <malloc+0x25a>
 1f0:	4509                	li	a0,2
 1f2:	00001097          	auipc	ra,0x1
 1f6:	880080e7          	jalr	-1920(ra) # a72 <fprintf>


}
 1fa:	60a2                	ld	ra,8(sp)
 1fc:	6402                	ld	s0,0(sp)
 1fe:	0141                	addi	sp,sp,16
 200:	8082                	ret

0000000000000202 <test3>:

//Test3 - parent allocates a lot of memory, forks, 
//and child can access all his data
void test3(){
 202:	715d                	addi	sp,sp,-80
 204:	e486                	sd	ra,72(sp)
 206:	e0a2                	sd	s0,64(sp)
 208:	fc26                	sd	s1,56(sp)
 20a:	f84a                	sd	s2,48(sp)
 20c:	f44e                	sd	s3,40(sp)
 20e:	f052                	sd	s4,32(sp)
 210:	ec56                	sd	s5,24(sp)
 212:	e85a                	sd	s6,16(sp)
 214:	0880                	addi	s0,sp,80
    fprintf(2,"-------------test3 start ---------------------\n");
 216:	00001597          	auipc	a1,0x1
 21a:	bda58593          	addi	a1,a1,-1062 # df0 <malloc+0x292>
 21e:	4509                	li	a0,2
 220:	00001097          	auipc	ra,0x1
 224:	852080e7          	jalr	-1966(ra) # a72 <fprintf>
    uint64 i;
    char* arr = malloc(PGSIZE*17);
 228:	6545                	lui	a0,0x11
 22a:	00001097          	auipc	ra,0x1
 22e:	934080e7          	jalr	-1740(ra) # b5e <malloc>
 232:	89aa                	mv	s3,a0
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 234:	4481                	li	s1,0
        arr[i] = 'a';
 236:	06100913          	li	s2,97
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 23a:	00001b17          	auipc	s6,0x1
 23e:	be6b0b13          	addi	s6,s6,-1050 # e20 <malloc+0x2c2>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 242:	6a85                	lui	s5,0x1
 244:	6a45                	lui	s4,0x11
        arr[i] = 'a';
 246:	009987b3          	add	a5,s3,s1
 24a:	01278023          	sb	s2,0(a5)
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 24e:	86ca                	mv	a3,s2
 250:	8626                	mv	a2,s1
 252:	85da                	mv	a1,s6
 254:	4509                	li	a0,2
 256:	00001097          	auipc	ra,0x1
 25a:	81c080e7          	jalr	-2020(ra) # a72 <fprintf>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 25e:	94d6                	add	s1,s1,s5
 260:	ff4493e3          	bne	s1,s4,246 <test3+0x44>
    }
    int pid = fork();
 264:	00000097          	auipc	ra,0x0
 268:	4bc080e7          	jalr	1212(ra) # 720 <fork>
    if(!pid){
 26c:	c939                	beqz	a0,2c2 <test3+0xc0>
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
        }
        exit(i);
    }else{
        int status;
        pid = wait(&status);
 26e:	fbc40513          	addi	a0,s0,-68
 272:	00000097          	auipc	ra,0x0
 276:	4be080e7          	jalr	1214(ra) # 730 <wait>
 27a:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
 27c:	fbc42683          	lw	a3,-68(s0)
 280:	00001597          	auipc	a1,0x1
 284:	a8858593          	addi	a1,a1,-1400 # d08 <malloc+0x1aa>
 288:	4509                	li	a0,2
 28a:	00000097          	auipc	ra,0x0
 28e:	7e8080e7          	jalr	2024(ra) # a72 <fprintf>
        sbrk(-17*PGSIZE);
 292:	753d                	lui	a0,0xfffef
 294:	00000097          	auipc	ra,0x0
 298:	51c080e7          	jalr	1308(ra) # 7b0 <sbrk>
    }
        fprintf(2,"-------------test3 finished ---------------------\n");
 29c:	00001597          	auipc	a1,0x1
 2a0:	bb458593          	addi	a1,a1,-1100 # e50 <malloc+0x2f2>
 2a4:	4509                	li	a0,2
 2a6:	00000097          	auipc	ra,0x0
 2aa:	7cc080e7          	jalr	1996(ra) # a72 <fprintf>

}
 2ae:	60a6                	ld	ra,72(sp)
 2b0:	6406                	ld	s0,64(sp)
 2b2:	74e2                	ld	s1,56(sp)
 2b4:	7942                	ld	s2,48(sp)
 2b6:	79a2                	ld	s3,40(sp)
 2b8:	7a02                	ld	s4,32(sp)
 2ba:	6ae2                	ld	s5,24(sp)
 2bc:	6b42                	ld	s6,16(sp)
 2be:	6161                	addi	sp,sp,80
 2c0:	8082                	ret
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2c2:	4481                	li	s1,0
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 2c4:	00001a97          	auipc	s5,0x1
 2c8:	b74a8a93          	addi	s5,s5,-1164 # e38 <malloc+0x2da>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2cc:	6a05                	lui	s4,0x1
 2ce:	6945                	lui	s2,0x11
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 2d0:	009987b3          	add	a5,s3,s1
 2d4:	0007c683          	lbu	a3,0(a5)
 2d8:	8626                	mv	a2,s1
 2da:	85d6                	mv	a1,s5
 2dc:	4509                	li	a0,2
 2de:	00000097          	auipc	ra,0x0
 2e2:	794080e7          	jalr	1940(ra) # a72 <fprintf>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2e6:	94d2                	add	s1,s1,s4
 2e8:	ff2494e3          	bne	s1,s2,2d0 <test3+0xce>
        exit(i);
 2ec:	6545                	lui	a0,0x11
 2ee:	00000097          	auipc	ra,0x0
 2f2:	43a080e7          	jalr	1082(ra) # 728 <exit>

00000000000002f6 <test4>:


// this test does a lot of calculations with a malloced array
// each calculation need the previous ones
// need to read and write to the array
void test4(){
 2f6:	7139                	addi	sp,sp,-64
 2f8:	fc06                	sd	ra,56(sp)
 2fa:	f822                	sd	s0,48(sp)
 2fc:	f426                	sd	s1,40(sp)
 2fe:	f04a                	sd	s2,32(sp)
 300:	ec4e                	sd	s3,24(sp)
 302:	e852                	sd	s4,16(sp)
 304:	e456                	sd	s5,8(sp)
 306:	e05a                	sd	s6,0(sp)
 308:	0080                	addi	s0,sp,64
    fprintf(2,"-------------test4 start ---------------------\n");
 30a:	00001597          	auipc	a1,0x1
 30e:	b7e58593          	addi	a1,a1,-1154 # e88 <malloc+0x32a>
 312:	4509                	li	a0,2
 314:	00000097          	auipc	ra,0x0
 318:	75e080e7          	jalr	1886(ra) # a72 <fprintf>
    int *arr = (int *)malloc(2000 * sizeof(int));
 31c:	6509                	lui	a0,0x2
 31e:	f4050513          	addi	a0,a0,-192 # 1f40 <__global_pointer$+0x787>
 322:	00001097          	auipc	ra,0x1
 326:	83c080e7          	jalr	-1988(ra) # b5e <malloc>
 32a:	8a2a                	mv	s4,a0
 32c:	872a                	mv	a4,a0
    int i, j;
    uint counter = 0;

    for(i = 0; i < 2000; i++){
 32e:	4781                	li	a5,0
 330:	7d000693          	li	a3,2000
        *(arr + i) = i;
 334:	c31c                	sw	a5,0(a4)
    for(i = 0; i < 2000; i++){
 336:	2785                	addiw	a5,a5,1
 338:	0711                	addi	a4,a4,4
 33a:	fed79de3          	bne	a5,a3,334 <test4+0x3e>
 33e:	004a0913          	addi	s2,s4,4 # 1004 <__BSS_END__+0x2c>
    uint counter = 0;
 342:	4481                	li	s1,0
    }
    for(i = 0; i < 2000; i++){
 344:	4981                	li	s3,0
        for(j = 0; j <= i; j ++){
            counter += *(arr + j);
        }
        printf("%d: counter is %d\n", i, counter);
 346:	00001b17          	auipc	s6,0x1
 34a:	b72b0b13          	addi	s6,s6,-1166 # eb8 <malloc+0x35a>
    for(i = 0; i < 2000; i++){
 34e:	7d000a93          	li	s5,2000
 352:	a00d                	j	374 <test4+0x7e>
            counter += *(arr + j);
 354:	4398                	lw	a4,0(a5)
 356:	9cb9                	addw	s1,s1,a4
        for(j = 0; j <= i; j ++){
 358:	0791                	addi	a5,a5,4
 35a:	ff279de3          	bne	a5,s2,354 <test4+0x5e>
        printf("%d: counter is %d\n", i, counter);
 35e:	8626                	mv	a2,s1
 360:	85ce                	mv	a1,s3
 362:	855a                	mv	a0,s6
 364:	00000097          	auipc	ra,0x0
 368:	73c080e7          	jalr	1852(ra) # aa0 <printf>
    for(i = 0; i < 2000; i++){
 36c:	2985                	addiw	s3,s3,1
 36e:	0911                	addi	s2,s2,4
 370:	01598663          	beq	s3,s5,37c <test4+0x86>
        for(j = 0; j <= i; j ++){
 374:	87d2                	mv	a5,s4
 376:	fc09dfe3          	bgez	s3,354 <test4+0x5e>
 37a:	b7d5                	j	35e <test4+0x68>
    }
    printf("final counter is %d\n",  counter);
 37c:	85a6                	mv	a1,s1
 37e:	00001517          	auipc	a0,0x1
 382:	b5250513          	addi	a0,a0,-1198 # ed0 <malloc+0x372>
 386:	00000097          	auipc	ra,0x0
 38a:	71a080e7          	jalr	1818(ra) # aa0 <printf>
    fprintf(2,"-------------test4 finished ---------------------\n");
 38e:	00001597          	auipc	a1,0x1
 392:	b5a58593          	addi	a1,a1,-1190 # ee8 <malloc+0x38a>
 396:	4509                	li	a0,2
 398:	00000097          	auipc	ra,0x0
 39c:	6da080e7          	jalr	1754(ra) # a72 <fprintf>
} 
 3a0:	70e2                	ld	ra,56(sp)
 3a2:	7442                	ld	s0,48(sp)
 3a4:	74a2                	ld	s1,40(sp)
 3a6:	7902                	ld	s2,32(sp)
 3a8:	69e2                	ld	s3,24(sp)
 3aa:	6a42                	ld	s4,16(sp)
 3ac:	6aa2                	ld	s5,8(sp)
 3ae:	6b02                	ld	s6,0(sp)
 3b0:	6121                	addi	sp,sp,64
 3b2:	8082                	ret

00000000000003b4 <aprint>:

void aprint(int num){
 3b4:	1141                	addi	sp,sp,-16
 3b6:	e406                	sd	ra,8(sp)
 3b8:	e022                	sd	s0,0(sp)
 3ba:	0800                	addi	s0,sp,16
 3bc:	85aa                	mv	a1,a0
    printf("%d a!\n", num);
 3be:	00001517          	auipc	a0,0x1
 3c2:	b6250513          	addi	a0,a0,-1182 # f20 <malloc+0x3c2>
 3c6:	00000097          	auipc	ra,0x0
 3ca:	6da080e7          	jalr	1754(ra) # aa0 <printf>
}
 3ce:	60a2                	ld	ra,8(sp)
 3d0:	6402                	ld	s0,0(sp)
 3d2:	0141                	addi	sp,sp,16
 3d4:	8082                	ret

00000000000003d6 <bprint>:

void bprint(int num){
 3d6:	1141                	addi	sp,sp,-16
 3d8:	e406                	sd	ra,8(sp)
 3da:	e022                	sd	s0,0(sp)
 3dc:	0800                	addi	s0,sp,16
 3de:	85aa                	mv	a1,a0
    printf("%d b!\n", num);
 3e0:	00001517          	auipc	a0,0x1
 3e4:	b4850513          	addi	a0,a0,-1208 # f28 <malloc+0x3ca>
 3e8:	00000097          	auipc	ra,0x0
 3ec:	6b8080e7          	jalr	1720(ra) # aa0 <printf>
}
 3f0:	60a2                	ld	ra,8(sp)
 3f2:	6402                	ld	s0,0(sp)
 3f4:	0141                	addi	sp,sp,16
 3f6:	8082                	ret

00000000000003f8 <cprint>:

void cprint(int num){
 3f8:	1141                	addi	sp,sp,-16
 3fa:	e406                	sd	ra,8(sp)
 3fc:	e022                	sd	s0,0(sp)
 3fe:	0800                	addi	s0,sp,16
 400:	85aa                	mv	a1,a0
    printf("%d c!\n", num);
 402:	00001517          	auipc	a0,0x1
 406:	b2e50513          	addi	a0,a0,-1234 # f30 <malloc+0x3d2>
 40a:	00000097          	auipc	ra,0x0
 40e:	696080e7          	jalr	1686(ra) # aa0 <printf>
}
 412:	60a2                	ld	ra,8(sp)
 414:	6402                	ld	s0,0(sp)
 416:	0141                	addi	sp,sp,16
 418:	8082                	ret

000000000000041a <test5>:

// print a lot of things to screen - call 3 different functions 
// the process will need to swap pages
void test5(){
 41a:	1101                	addi	sp,sp,-32
 41c:	ec06                	sd	ra,24(sp)
 41e:	e822                	sd	s0,16(sp)
 420:	e426                	sd	s1,8(sp)
 422:	e04a                	sd	s2,0(sp)
 424:	1000                	addi	s0,sp,32
        fprintf(2,"-------------test5 start ---------------------\n");
 426:	00001597          	auipc	a1,0x1
 42a:	b1258593          	addi	a1,a1,-1262 # f38 <malloc+0x3da>
 42e:	4509                	li	a0,2
 430:	00000097          	auipc	ra,0x0
 434:	642080e7          	jalr	1602(ra) # a72 <fprintf>
    for(int i = 0; i < 1000; i ++){
 438:	4481                	li	s1,0
 43a:	3e800913          	li	s2,1000
        aprint(i);
 43e:	8526                	mv	a0,s1
 440:	00000097          	auipc	ra,0x0
 444:	f74080e7          	jalr	-140(ra) # 3b4 <aprint>
        bprint(i);
 448:	8526                	mv	a0,s1
 44a:	00000097          	auipc	ra,0x0
 44e:	f8c080e7          	jalr	-116(ra) # 3d6 <bprint>
        cprint(i);
 452:	8526                	mv	a0,s1
 454:	00000097          	auipc	ra,0x0
 458:	fa4080e7          	jalr	-92(ra) # 3f8 <cprint>
    for(int i = 0; i < 1000; i ++){
 45c:	2485                	addiw	s1,s1,1
 45e:	ff2490e3          	bne	s1,s2,43e <test5+0x24>
    }
        fprintf(2,"-------------test5 finished ---------------------\n");
 462:	00001597          	auipc	a1,0x1
 466:	b0658593          	addi	a1,a1,-1274 # f68 <malloc+0x40a>
 46a:	4509                	li	a0,2
 46c:	00000097          	auipc	ra,0x0
 470:	606080e7          	jalr	1542(ra) # a72 <fprintf>
}
 474:	60e2                	ld	ra,24(sp)
 476:	6442                	ld	s0,16(sp)
 478:	64a2                	ld	s1,8(sp)
 47a:	6902                	ld	s2,0(sp)
 47c:	6105                	addi	sp,sp,32
 47e:	8082                	ret

0000000000000480 <main>:


int main(int argc, char** argv){
 480:	1141                	addi	sp,sp,-16
 482:	e406                	sd	ra,8(sp)
 484:	e022                	sd	s0,0(sp)
 486:	0800                	addi	s0,sp,16
    test1();
 488:	00000097          	auipc	ra,0x0
 48c:	b78080e7          	jalr	-1160(ra) # 0 <test1>
    test2();
 490:	00000097          	auipc	ra,0x0
 494:	c8a080e7          	jalr	-886(ra) # 11a <test2>
    test3();
 498:	00000097          	auipc	ra,0x0
 49c:	d6a080e7          	jalr	-662(ra) # 202 <test3>
    test4();
 4a0:	00000097          	auipc	ra,0x0
 4a4:	e56080e7          	jalr	-426(ra) # 2f6 <test4>
    test5();
 4a8:	00000097          	auipc	ra,0x0
 4ac:	f72080e7          	jalr	-142(ra) # 41a <test5>
    exit(0);
 4b0:	4501                	li	a0,0
 4b2:	00000097          	auipc	ra,0x0
 4b6:	276080e7          	jalr	630(ra) # 728 <exit>

00000000000004ba <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 4ba:	1141                	addi	sp,sp,-16
 4bc:	e422                	sd	s0,8(sp)
 4be:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4c0:	87aa                	mv	a5,a0
 4c2:	0585                	addi	a1,a1,1
 4c4:	0785                	addi	a5,a5,1
 4c6:	fff5c703          	lbu	a4,-1(a1)
 4ca:	fee78fa3          	sb	a4,-1(a5)
 4ce:	fb75                	bnez	a4,4c2 <strcpy+0x8>
    ;
  return os;
}
 4d0:	6422                	ld	s0,8(sp)
 4d2:	0141                	addi	sp,sp,16
 4d4:	8082                	ret

00000000000004d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 4d6:	1141                	addi	sp,sp,-16
 4d8:	e422                	sd	s0,8(sp)
 4da:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 4dc:	00054783          	lbu	a5,0(a0)
 4e0:	cb91                	beqz	a5,4f4 <strcmp+0x1e>
 4e2:	0005c703          	lbu	a4,0(a1)
 4e6:	00f71763          	bne	a4,a5,4f4 <strcmp+0x1e>
    p++, q++;
 4ea:	0505                	addi	a0,a0,1
 4ec:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 4ee:	00054783          	lbu	a5,0(a0)
 4f2:	fbe5                	bnez	a5,4e2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 4f4:	0005c503          	lbu	a0,0(a1)
}
 4f8:	40a7853b          	subw	a0,a5,a0
 4fc:	6422                	ld	s0,8(sp)
 4fe:	0141                	addi	sp,sp,16
 500:	8082                	ret

0000000000000502 <strlen>:

uint
strlen(const char *s)
{
 502:	1141                	addi	sp,sp,-16
 504:	e422                	sd	s0,8(sp)
 506:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 508:	00054783          	lbu	a5,0(a0)
 50c:	cf91                	beqz	a5,528 <strlen+0x26>
 50e:	0505                	addi	a0,a0,1
 510:	87aa                	mv	a5,a0
 512:	4685                	li	a3,1
 514:	9e89                	subw	a3,a3,a0
 516:	00f6853b          	addw	a0,a3,a5
 51a:	0785                	addi	a5,a5,1
 51c:	fff7c703          	lbu	a4,-1(a5)
 520:	fb7d                	bnez	a4,516 <strlen+0x14>
    ;
  return n;
}
 522:	6422                	ld	s0,8(sp)
 524:	0141                	addi	sp,sp,16
 526:	8082                	ret
  for(n = 0; s[n]; n++)
 528:	4501                	li	a0,0
 52a:	bfe5                	j	522 <strlen+0x20>

000000000000052c <memset>:

void*
memset(void *dst, int c, uint n)
{
 52c:	1141                	addi	sp,sp,-16
 52e:	e422                	sd	s0,8(sp)
 530:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 532:	ca19                	beqz	a2,548 <memset+0x1c>
 534:	87aa                	mv	a5,a0
 536:	1602                	slli	a2,a2,0x20
 538:	9201                	srli	a2,a2,0x20
 53a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 53e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 542:	0785                	addi	a5,a5,1
 544:	fee79de3          	bne	a5,a4,53e <memset+0x12>
  }
  return dst;
}
 548:	6422                	ld	s0,8(sp)
 54a:	0141                	addi	sp,sp,16
 54c:	8082                	ret

000000000000054e <strchr>:

char*
strchr(const char *s, char c)
{
 54e:	1141                	addi	sp,sp,-16
 550:	e422                	sd	s0,8(sp)
 552:	0800                	addi	s0,sp,16
  for(; *s; s++)
 554:	00054783          	lbu	a5,0(a0)
 558:	cb99                	beqz	a5,56e <strchr+0x20>
    if(*s == c)
 55a:	00f58763          	beq	a1,a5,568 <strchr+0x1a>
  for(; *s; s++)
 55e:	0505                	addi	a0,a0,1
 560:	00054783          	lbu	a5,0(a0)
 564:	fbfd                	bnez	a5,55a <strchr+0xc>
      return (char*)s;
  return 0;
 566:	4501                	li	a0,0
}
 568:	6422                	ld	s0,8(sp)
 56a:	0141                	addi	sp,sp,16
 56c:	8082                	ret
  return 0;
 56e:	4501                	li	a0,0
 570:	bfe5                	j	568 <strchr+0x1a>

0000000000000572 <gets>:

char*
gets(char *buf, int max)
{
 572:	711d                	addi	sp,sp,-96
 574:	ec86                	sd	ra,88(sp)
 576:	e8a2                	sd	s0,80(sp)
 578:	e4a6                	sd	s1,72(sp)
 57a:	e0ca                	sd	s2,64(sp)
 57c:	fc4e                	sd	s3,56(sp)
 57e:	f852                	sd	s4,48(sp)
 580:	f456                	sd	s5,40(sp)
 582:	f05a                	sd	s6,32(sp)
 584:	ec5e                	sd	s7,24(sp)
 586:	1080                	addi	s0,sp,96
 588:	8baa                	mv	s7,a0
 58a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 58c:	892a                	mv	s2,a0
 58e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 590:	4aa9                	li	s5,10
 592:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 594:	89a6                	mv	s3,s1
 596:	2485                	addiw	s1,s1,1
 598:	0344d863          	bge	s1,s4,5c8 <gets+0x56>
    cc = read(0, &c, 1);
 59c:	4605                	li	a2,1
 59e:	faf40593          	addi	a1,s0,-81
 5a2:	4501                	li	a0,0
 5a4:	00000097          	auipc	ra,0x0
 5a8:	19c080e7          	jalr	412(ra) # 740 <read>
    if(cc < 1)
 5ac:	00a05e63          	blez	a0,5c8 <gets+0x56>
    buf[i++] = c;
 5b0:	faf44783          	lbu	a5,-81(s0)
 5b4:	00f90023          	sb	a5,0(s2) # 11000 <__global_pointer$+0xf847>
    if(c == '\n' || c == '\r')
 5b8:	01578763          	beq	a5,s5,5c6 <gets+0x54>
 5bc:	0905                	addi	s2,s2,1
 5be:	fd679be3          	bne	a5,s6,594 <gets+0x22>
  for(i=0; i+1 < max; ){
 5c2:	89a6                	mv	s3,s1
 5c4:	a011                	j	5c8 <gets+0x56>
 5c6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 5c8:	99de                	add	s3,s3,s7
 5ca:	00098023          	sb	zero,0(s3)
  return buf;
}
 5ce:	855e                	mv	a0,s7
 5d0:	60e6                	ld	ra,88(sp)
 5d2:	6446                	ld	s0,80(sp)
 5d4:	64a6                	ld	s1,72(sp)
 5d6:	6906                	ld	s2,64(sp)
 5d8:	79e2                	ld	s3,56(sp)
 5da:	7a42                	ld	s4,48(sp)
 5dc:	7aa2                	ld	s5,40(sp)
 5de:	7b02                	ld	s6,32(sp)
 5e0:	6be2                	ld	s7,24(sp)
 5e2:	6125                	addi	sp,sp,96
 5e4:	8082                	ret

00000000000005e6 <stat>:

int
stat(const char *n, struct stat *st)
{
 5e6:	1101                	addi	sp,sp,-32
 5e8:	ec06                	sd	ra,24(sp)
 5ea:	e822                	sd	s0,16(sp)
 5ec:	e426                	sd	s1,8(sp)
 5ee:	e04a                	sd	s2,0(sp)
 5f0:	1000                	addi	s0,sp,32
 5f2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 5f4:	4581                	li	a1,0
 5f6:	00000097          	auipc	ra,0x0
 5fa:	172080e7          	jalr	370(ra) # 768 <open>
  if(fd < 0)
 5fe:	02054563          	bltz	a0,628 <stat+0x42>
 602:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 604:	85ca                	mv	a1,s2
 606:	00000097          	auipc	ra,0x0
 60a:	17a080e7          	jalr	378(ra) # 780 <fstat>
 60e:	892a                	mv	s2,a0
  close(fd);
 610:	8526                	mv	a0,s1
 612:	00000097          	auipc	ra,0x0
 616:	13e080e7          	jalr	318(ra) # 750 <close>
  return r;
}
 61a:	854a                	mv	a0,s2
 61c:	60e2                	ld	ra,24(sp)
 61e:	6442                	ld	s0,16(sp)
 620:	64a2                	ld	s1,8(sp)
 622:	6902                	ld	s2,0(sp)
 624:	6105                	addi	sp,sp,32
 626:	8082                	ret
    return -1;
 628:	597d                	li	s2,-1
 62a:	bfc5                	j	61a <stat+0x34>

000000000000062c <atoi>:

int
atoi(const char *s)
{
 62c:	1141                	addi	sp,sp,-16
 62e:	e422                	sd	s0,8(sp)
 630:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 632:	00054603          	lbu	a2,0(a0)
 636:	fd06079b          	addiw	a5,a2,-48
 63a:	0ff7f793          	andi	a5,a5,255
 63e:	4725                	li	a4,9
 640:	02f76963          	bltu	a4,a5,672 <atoi+0x46>
 644:	86aa                	mv	a3,a0
  n = 0;
 646:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 648:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 64a:	0685                	addi	a3,a3,1
 64c:	0025179b          	slliw	a5,a0,0x2
 650:	9fa9                	addw	a5,a5,a0
 652:	0017979b          	slliw	a5,a5,0x1
 656:	9fb1                	addw	a5,a5,a2
 658:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 65c:	0006c603          	lbu	a2,0(a3)
 660:	fd06071b          	addiw	a4,a2,-48
 664:	0ff77713          	andi	a4,a4,255
 668:	fee5f1e3          	bgeu	a1,a4,64a <atoi+0x1e>
  return n;
}
 66c:	6422                	ld	s0,8(sp)
 66e:	0141                	addi	sp,sp,16
 670:	8082                	ret
  n = 0;
 672:	4501                	li	a0,0
 674:	bfe5                	j	66c <atoi+0x40>

0000000000000676 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 676:	1141                	addi	sp,sp,-16
 678:	e422                	sd	s0,8(sp)
 67a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 67c:	02b57463          	bgeu	a0,a1,6a4 <memmove+0x2e>
    while(n-- > 0)
 680:	00c05f63          	blez	a2,69e <memmove+0x28>
 684:	1602                	slli	a2,a2,0x20
 686:	9201                	srli	a2,a2,0x20
 688:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 68c:	872a                	mv	a4,a0
      *dst++ = *src++;
 68e:	0585                	addi	a1,a1,1
 690:	0705                	addi	a4,a4,1
 692:	fff5c683          	lbu	a3,-1(a1)
 696:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 69a:	fee79ae3          	bne	a5,a4,68e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 69e:	6422                	ld	s0,8(sp)
 6a0:	0141                	addi	sp,sp,16
 6a2:	8082                	ret
    dst += n;
 6a4:	00c50733          	add	a4,a0,a2
    src += n;
 6a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6aa:	fec05ae3          	blez	a2,69e <memmove+0x28>
 6ae:	fff6079b          	addiw	a5,a2,-1
 6b2:	1782                	slli	a5,a5,0x20
 6b4:	9381                	srli	a5,a5,0x20
 6b6:	fff7c793          	not	a5,a5
 6ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6bc:	15fd                	addi	a1,a1,-1
 6be:	177d                	addi	a4,a4,-1
 6c0:	0005c683          	lbu	a3,0(a1)
 6c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 6c8:	fee79ae3          	bne	a5,a4,6bc <memmove+0x46>
 6cc:	bfc9                	j	69e <memmove+0x28>

00000000000006ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 6ce:	1141                	addi	sp,sp,-16
 6d0:	e422                	sd	s0,8(sp)
 6d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 6d4:	ca05                	beqz	a2,704 <memcmp+0x36>
 6d6:	fff6069b          	addiw	a3,a2,-1
 6da:	1682                	slli	a3,a3,0x20
 6dc:	9281                	srli	a3,a3,0x20
 6de:	0685                	addi	a3,a3,1
 6e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 6e2:	00054783          	lbu	a5,0(a0)
 6e6:	0005c703          	lbu	a4,0(a1)
 6ea:	00e79863          	bne	a5,a4,6fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 6ee:	0505                	addi	a0,a0,1
    p2++;
 6f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 6f2:	fed518e3          	bne	a0,a3,6e2 <memcmp+0x14>
  }
  return 0;
 6f6:	4501                	li	a0,0
 6f8:	a019                	j	6fe <memcmp+0x30>
      return *p1 - *p2;
 6fa:	40e7853b          	subw	a0,a5,a4
}
 6fe:	6422                	ld	s0,8(sp)
 700:	0141                	addi	sp,sp,16
 702:	8082                	ret
  return 0;
 704:	4501                	li	a0,0
 706:	bfe5                	j	6fe <memcmp+0x30>

0000000000000708 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 708:	1141                	addi	sp,sp,-16
 70a:	e406                	sd	ra,8(sp)
 70c:	e022                	sd	s0,0(sp)
 70e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 710:	00000097          	auipc	ra,0x0
 714:	f66080e7          	jalr	-154(ra) # 676 <memmove>
}
 718:	60a2                	ld	ra,8(sp)
 71a:	6402                	ld	s0,0(sp)
 71c:	0141                	addi	sp,sp,16
 71e:	8082                	ret

0000000000000720 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 720:	4885                	li	a7,1
 ecall
 722:	00000073          	ecall
 ret
 726:	8082                	ret

0000000000000728 <exit>:
.global exit
exit:
 li a7, SYS_exit
 728:	4889                	li	a7,2
 ecall
 72a:	00000073          	ecall
 ret
 72e:	8082                	ret

0000000000000730 <wait>:
.global wait
wait:
 li a7, SYS_wait
 730:	488d                	li	a7,3
 ecall
 732:	00000073          	ecall
 ret
 736:	8082                	ret

0000000000000738 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 738:	4891                	li	a7,4
 ecall
 73a:	00000073          	ecall
 ret
 73e:	8082                	ret

0000000000000740 <read>:
.global read
read:
 li a7, SYS_read
 740:	4895                	li	a7,5
 ecall
 742:	00000073          	ecall
 ret
 746:	8082                	ret

0000000000000748 <write>:
.global write
write:
 li a7, SYS_write
 748:	48c1                	li	a7,16
 ecall
 74a:	00000073          	ecall
 ret
 74e:	8082                	ret

0000000000000750 <close>:
.global close
close:
 li a7, SYS_close
 750:	48d5                	li	a7,21
 ecall
 752:	00000073          	ecall
 ret
 756:	8082                	ret

0000000000000758 <kill>:
.global kill
kill:
 li a7, SYS_kill
 758:	4899                	li	a7,6
 ecall
 75a:	00000073          	ecall
 ret
 75e:	8082                	ret

0000000000000760 <exec>:
.global exec
exec:
 li a7, SYS_exec
 760:	489d                	li	a7,7
 ecall
 762:	00000073          	ecall
 ret
 766:	8082                	ret

0000000000000768 <open>:
.global open
open:
 li a7, SYS_open
 768:	48bd                	li	a7,15
 ecall
 76a:	00000073          	ecall
 ret
 76e:	8082                	ret

0000000000000770 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 770:	48c5                	li	a7,17
 ecall
 772:	00000073          	ecall
 ret
 776:	8082                	ret

0000000000000778 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 778:	48c9                	li	a7,18
 ecall
 77a:	00000073          	ecall
 ret
 77e:	8082                	ret

0000000000000780 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 780:	48a1                	li	a7,8
 ecall
 782:	00000073          	ecall
 ret
 786:	8082                	ret

0000000000000788 <link>:
.global link
link:
 li a7, SYS_link
 788:	48cd                	li	a7,19
 ecall
 78a:	00000073          	ecall
 ret
 78e:	8082                	ret

0000000000000790 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 790:	48d1                	li	a7,20
 ecall
 792:	00000073          	ecall
 ret
 796:	8082                	ret

0000000000000798 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 798:	48a5                	li	a7,9
 ecall
 79a:	00000073          	ecall
 ret
 79e:	8082                	ret

00000000000007a0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 7a0:	48a9                	li	a7,10
 ecall
 7a2:	00000073          	ecall
 ret
 7a6:	8082                	ret

00000000000007a8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7a8:	48ad                	li	a7,11
 ecall
 7aa:	00000073          	ecall
 ret
 7ae:	8082                	ret

00000000000007b0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 7b0:	48b1                	li	a7,12
 ecall
 7b2:	00000073          	ecall
 ret
 7b6:	8082                	ret

00000000000007b8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 7b8:	48b5                	li	a7,13
 ecall
 7ba:	00000073          	ecall
 ret
 7be:	8082                	ret

00000000000007c0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7c0:	48b9                	li	a7,14
 ecall
 7c2:	00000073          	ecall
 ret
 7c6:	8082                	ret

00000000000007c8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 7c8:	1101                	addi	sp,sp,-32
 7ca:	ec06                	sd	ra,24(sp)
 7cc:	e822                	sd	s0,16(sp)
 7ce:	1000                	addi	s0,sp,32
 7d0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 7d4:	4605                	li	a2,1
 7d6:	fef40593          	addi	a1,s0,-17
 7da:	00000097          	auipc	ra,0x0
 7de:	f6e080e7          	jalr	-146(ra) # 748 <write>
}
 7e2:	60e2                	ld	ra,24(sp)
 7e4:	6442                	ld	s0,16(sp)
 7e6:	6105                	addi	sp,sp,32
 7e8:	8082                	ret

00000000000007ea <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 7ea:	7139                	addi	sp,sp,-64
 7ec:	fc06                	sd	ra,56(sp)
 7ee:	f822                	sd	s0,48(sp)
 7f0:	f426                	sd	s1,40(sp)
 7f2:	f04a                	sd	s2,32(sp)
 7f4:	ec4e                	sd	s3,24(sp)
 7f6:	0080                	addi	s0,sp,64
 7f8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 7fa:	c299                	beqz	a3,800 <printint+0x16>
 7fc:	0805c863          	bltz	a1,88c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 800:	2581                	sext.w	a1,a1
  neg = 0;
 802:	4881                	li	a7,0
 804:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 808:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 80a:	2601                	sext.w	a2,a2
 80c:	00000517          	auipc	a0,0x0
 810:	79c50513          	addi	a0,a0,1948 # fa8 <digits>
 814:	883a                	mv	a6,a4
 816:	2705                	addiw	a4,a4,1
 818:	02c5f7bb          	remuw	a5,a1,a2
 81c:	1782                	slli	a5,a5,0x20
 81e:	9381                	srli	a5,a5,0x20
 820:	97aa                	add	a5,a5,a0
 822:	0007c783          	lbu	a5,0(a5)
 826:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 82a:	0005879b          	sext.w	a5,a1
 82e:	02c5d5bb          	divuw	a1,a1,a2
 832:	0685                	addi	a3,a3,1
 834:	fec7f0e3          	bgeu	a5,a2,814 <printint+0x2a>
  if(neg)
 838:	00088b63          	beqz	a7,84e <printint+0x64>
    buf[i++] = '-';
 83c:	fd040793          	addi	a5,s0,-48
 840:	973e                	add	a4,a4,a5
 842:	02d00793          	li	a5,45
 846:	fef70823          	sb	a5,-16(a4)
 84a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 84e:	02e05863          	blez	a4,87e <printint+0x94>
 852:	fc040793          	addi	a5,s0,-64
 856:	00e78933          	add	s2,a5,a4
 85a:	fff78993          	addi	s3,a5,-1
 85e:	99ba                	add	s3,s3,a4
 860:	377d                	addiw	a4,a4,-1
 862:	1702                	slli	a4,a4,0x20
 864:	9301                	srli	a4,a4,0x20
 866:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 86a:	fff94583          	lbu	a1,-1(s2)
 86e:	8526                	mv	a0,s1
 870:	00000097          	auipc	ra,0x0
 874:	f58080e7          	jalr	-168(ra) # 7c8 <putc>
  while(--i >= 0)
 878:	197d                	addi	s2,s2,-1
 87a:	ff3918e3          	bne	s2,s3,86a <printint+0x80>
}
 87e:	70e2                	ld	ra,56(sp)
 880:	7442                	ld	s0,48(sp)
 882:	74a2                	ld	s1,40(sp)
 884:	7902                	ld	s2,32(sp)
 886:	69e2                	ld	s3,24(sp)
 888:	6121                	addi	sp,sp,64
 88a:	8082                	ret
    x = -xx;
 88c:	40b005bb          	negw	a1,a1
    neg = 1;
 890:	4885                	li	a7,1
    x = -xx;
 892:	bf8d                	j	804 <printint+0x1a>

0000000000000894 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 894:	7119                	addi	sp,sp,-128
 896:	fc86                	sd	ra,120(sp)
 898:	f8a2                	sd	s0,112(sp)
 89a:	f4a6                	sd	s1,104(sp)
 89c:	f0ca                	sd	s2,96(sp)
 89e:	ecce                	sd	s3,88(sp)
 8a0:	e8d2                	sd	s4,80(sp)
 8a2:	e4d6                	sd	s5,72(sp)
 8a4:	e0da                	sd	s6,64(sp)
 8a6:	fc5e                	sd	s7,56(sp)
 8a8:	f862                	sd	s8,48(sp)
 8aa:	f466                	sd	s9,40(sp)
 8ac:	f06a                	sd	s10,32(sp)
 8ae:	ec6e                	sd	s11,24(sp)
 8b0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 8b2:	0005c903          	lbu	s2,0(a1)
 8b6:	18090f63          	beqz	s2,a54 <vprintf+0x1c0>
 8ba:	8aaa                	mv	s5,a0
 8bc:	8b32                	mv	s6,a2
 8be:	00158493          	addi	s1,a1,1
  state = 0;
 8c2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 8c4:	02500a13          	li	s4,37
      if(c == 'd'){
 8c8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 8cc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 8d0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 8d4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8d8:	00000b97          	auipc	s7,0x0
 8dc:	6d0b8b93          	addi	s7,s7,1744 # fa8 <digits>
 8e0:	a839                	j	8fe <vprintf+0x6a>
        putc(fd, c);
 8e2:	85ca                	mv	a1,s2
 8e4:	8556                	mv	a0,s5
 8e6:	00000097          	auipc	ra,0x0
 8ea:	ee2080e7          	jalr	-286(ra) # 7c8 <putc>
 8ee:	a019                	j	8f4 <vprintf+0x60>
    } else if(state == '%'){
 8f0:	01498f63          	beq	s3,s4,90e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 8f4:	0485                	addi	s1,s1,1
 8f6:	fff4c903          	lbu	s2,-1(s1)
 8fa:	14090d63          	beqz	s2,a54 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 8fe:	0009079b          	sext.w	a5,s2
    if(state == 0){
 902:	fe0997e3          	bnez	s3,8f0 <vprintf+0x5c>
      if(c == '%'){
 906:	fd479ee3          	bne	a5,s4,8e2 <vprintf+0x4e>
        state = '%';
 90a:	89be                	mv	s3,a5
 90c:	b7e5                	j	8f4 <vprintf+0x60>
      if(c == 'd'){
 90e:	05878063          	beq	a5,s8,94e <vprintf+0xba>
      } else if(c == 'l') {
 912:	05978c63          	beq	a5,s9,96a <vprintf+0xd6>
      } else if(c == 'x') {
 916:	07a78863          	beq	a5,s10,986 <vprintf+0xf2>
      } else if(c == 'p') {
 91a:	09b78463          	beq	a5,s11,9a2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 91e:	07300713          	li	a4,115
 922:	0ce78663          	beq	a5,a4,9ee <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 926:	06300713          	li	a4,99
 92a:	0ee78e63          	beq	a5,a4,a26 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 92e:	11478863          	beq	a5,s4,a3e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 932:	85d2                	mv	a1,s4
 934:	8556                	mv	a0,s5
 936:	00000097          	auipc	ra,0x0
 93a:	e92080e7          	jalr	-366(ra) # 7c8 <putc>
        putc(fd, c);
 93e:	85ca                	mv	a1,s2
 940:	8556                	mv	a0,s5
 942:	00000097          	auipc	ra,0x0
 946:	e86080e7          	jalr	-378(ra) # 7c8 <putc>
      }
      state = 0;
 94a:	4981                	li	s3,0
 94c:	b765                	j	8f4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 94e:	008b0913          	addi	s2,s6,8
 952:	4685                	li	a3,1
 954:	4629                	li	a2,10
 956:	000b2583          	lw	a1,0(s6)
 95a:	8556                	mv	a0,s5
 95c:	00000097          	auipc	ra,0x0
 960:	e8e080e7          	jalr	-370(ra) # 7ea <printint>
 964:	8b4a                	mv	s6,s2
      state = 0;
 966:	4981                	li	s3,0
 968:	b771                	j	8f4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 96a:	008b0913          	addi	s2,s6,8
 96e:	4681                	li	a3,0
 970:	4629                	li	a2,10
 972:	000b2583          	lw	a1,0(s6)
 976:	8556                	mv	a0,s5
 978:	00000097          	auipc	ra,0x0
 97c:	e72080e7          	jalr	-398(ra) # 7ea <printint>
 980:	8b4a                	mv	s6,s2
      state = 0;
 982:	4981                	li	s3,0
 984:	bf85                	j	8f4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 986:	008b0913          	addi	s2,s6,8
 98a:	4681                	li	a3,0
 98c:	4641                	li	a2,16
 98e:	000b2583          	lw	a1,0(s6)
 992:	8556                	mv	a0,s5
 994:	00000097          	auipc	ra,0x0
 998:	e56080e7          	jalr	-426(ra) # 7ea <printint>
 99c:	8b4a                	mv	s6,s2
      state = 0;
 99e:	4981                	li	s3,0
 9a0:	bf91                	j	8f4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 9a2:	008b0793          	addi	a5,s6,8
 9a6:	f8f43423          	sd	a5,-120(s0)
 9aa:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 9ae:	03000593          	li	a1,48
 9b2:	8556                	mv	a0,s5
 9b4:	00000097          	auipc	ra,0x0
 9b8:	e14080e7          	jalr	-492(ra) # 7c8 <putc>
  putc(fd, 'x');
 9bc:	85ea                	mv	a1,s10
 9be:	8556                	mv	a0,s5
 9c0:	00000097          	auipc	ra,0x0
 9c4:	e08080e7          	jalr	-504(ra) # 7c8 <putc>
 9c8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 9ca:	03c9d793          	srli	a5,s3,0x3c
 9ce:	97de                	add	a5,a5,s7
 9d0:	0007c583          	lbu	a1,0(a5)
 9d4:	8556                	mv	a0,s5
 9d6:	00000097          	auipc	ra,0x0
 9da:	df2080e7          	jalr	-526(ra) # 7c8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 9de:	0992                	slli	s3,s3,0x4
 9e0:	397d                	addiw	s2,s2,-1
 9e2:	fe0914e3          	bnez	s2,9ca <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 9e6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 9ea:	4981                	li	s3,0
 9ec:	b721                	j	8f4 <vprintf+0x60>
        s = va_arg(ap, char*);
 9ee:	008b0993          	addi	s3,s6,8
 9f2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 9f6:	02090163          	beqz	s2,a18 <vprintf+0x184>
        while(*s != 0){
 9fa:	00094583          	lbu	a1,0(s2)
 9fe:	c9a1                	beqz	a1,a4e <vprintf+0x1ba>
          putc(fd, *s);
 a00:	8556                	mv	a0,s5
 a02:	00000097          	auipc	ra,0x0
 a06:	dc6080e7          	jalr	-570(ra) # 7c8 <putc>
          s++;
 a0a:	0905                	addi	s2,s2,1
        while(*s != 0){
 a0c:	00094583          	lbu	a1,0(s2)
 a10:	f9e5                	bnez	a1,a00 <vprintf+0x16c>
        s = va_arg(ap, char*);
 a12:	8b4e                	mv	s6,s3
      state = 0;
 a14:	4981                	li	s3,0
 a16:	bdf9                	j	8f4 <vprintf+0x60>
          s = "(null)";
 a18:	00000917          	auipc	s2,0x0
 a1c:	58890913          	addi	s2,s2,1416 # fa0 <malloc+0x442>
        while(*s != 0){
 a20:	02800593          	li	a1,40
 a24:	bff1                	j	a00 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 a26:	008b0913          	addi	s2,s6,8
 a2a:	000b4583          	lbu	a1,0(s6)
 a2e:	8556                	mv	a0,s5
 a30:	00000097          	auipc	ra,0x0
 a34:	d98080e7          	jalr	-616(ra) # 7c8 <putc>
 a38:	8b4a                	mv	s6,s2
      state = 0;
 a3a:	4981                	li	s3,0
 a3c:	bd65                	j	8f4 <vprintf+0x60>
        putc(fd, c);
 a3e:	85d2                	mv	a1,s4
 a40:	8556                	mv	a0,s5
 a42:	00000097          	auipc	ra,0x0
 a46:	d86080e7          	jalr	-634(ra) # 7c8 <putc>
      state = 0;
 a4a:	4981                	li	s3,0
 a4c:	b565                	j	8f4 <vprintf+0x60>
        s = va_arg(ap, char*);
 a4e:	8b4e                	mv	s6,s3
      state = 0;
 a50:	4981                	li	s3,0
 a52:	b54d                	j	8f4 <vprintf+0x60>
    }
  }
}
 a54:	70e6                	ld	ra,120(sp)
 a56:	7446                	ld	s0,112(sp)
 a58:	74a6                	ld	s1,104(sp)
 a5a:	7906                	ld	s2,96(sp)
 a5c:	69e6                	ld	s3,88(sp)
 a5e:	6a46                	ld	s4,80(sp)
 a60:	6aa6                	ld	s5,72(sp)
 a62:	6b06                	ld	s6,64(sp)
 a64:	7be2                	ld	s7,56(sp)
 a66:	7c42                	ld	s8,48(sp)
 a68:	7ca2                	ld	s9,40(sp)
 a6a:	7d02                	ld	s10,32(sp)
 a6c:	6de2                	ld	s11,24(sp)
 a6e:	6109                	addi	sp,sp,128
 a70:	8082                	ret

0000000000000a72 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a72:	715d                	addi	sp,sp,-80
 a74:	ec06                	sd	ra,24(sp)
 a76:	e822                	sd	s0,16(sp)
 a78:	1000                	addi	s0,sp,32
 a7a:	e010                	sd	a2,0(s0)
 a7c:	e414                	sd	a3,8(s0)
 a7e:	e818                	sd	a4,16(s0)
 a80:	ec1c                	sd	a5,24(s0)
 a82:	03043023          	sd	a6,32(s0)
 a86:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a8a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a8e:	8622                	mv	a2,s0
 a90:	00000097          	auipc	ra,0x0
 a94:	e04080e7          	jalr	-508(ra) # 894 <vprintf>
}
 a98:	60e2                	ld	ra,24(sp)
 a9a:	6442                	ld	s0,16(sp)
 a9c:	6161                	addi	sp,sp,80
 a9e:	8082                	ret

0000000000000aa0 <printf>:

void
printf(const char *fmt, ...)
{
 aa0:	711d                	addi	sp,sp,-96
 aa2:	ec06                	sd	ra,24(sp)
 aa4:	e822                	sd	s0,16(sp)
 aa6:	1000                	addi	s0,sp,32
 aa8:	e40c                	sd	a1,8(s0)
 aaa:	e810                	sd	a2,16(s0)
 aac:	ec14                	sd	a3,24(s0)
 aae:	f018                	sd	a4,32(s0)
 ab0:	f41c                	sd	a5,40(s0)
 ab2:	03043823          	sd	a6,48(s0)
 ab6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 aba:	00840613          	addi	a2,s0,8
 abe:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 ac2:	85aa                	mv	a1,a0
 ac4:	4505                	li	a0,1
 ac6:	00000097          	auipc	ra,0x0
 aca:	dce080e7          	jalr	-562(ra) # 894 <vprintf>
}
 ace:	60e2                	ld	ra,24(sp)
 ad0:	6442                	ld	s0,16(sp)
 ad2:	6125                	addi	sp,sp,96
 ad4:	8082                	ret

0000000000000ad6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 ad6:	1141                	addi	sp,sp,-16
 ad8:	e422                	sd	s0,8(sp)
 ada:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 adc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ae0:	00000797          	auipc	a5,0x0
 ae4:	4e07b783          	ld	a5,1248(a5) # fc0 <freep>
 ae8:	a805                	j	b18 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 aea:	4618                	lw	a4,8(a2)
 aec:	9db9                	addw	a1,a1,a4
 aee:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 af2:	6398                	ld	a4,0(a5)
 af4:	6318                	ld	a4,0(a4)
 af6:	fee53823          	sd	a4,-16(a0)
 afa:	a091                	j	b3e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 afc:	ff852703          	lw	a4,-8(a0)
 b00:	9e39                	addw	a2,a2,a4
 b02:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b04:	ff053703          	ld	a4,-16(a0)
 b08:	e398                	sd	a4,0(a5)
 b0a:	a099                	j	b50 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b0c:	6398                	ld	a4,0(a5)
 b0e:	00e7e463          	bltu	a5,a4,b16 <free+0x40>
 b12:	00e6ea63          	bltu	a3,a4,b26 <free+0x50>
{
 b16:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b18:	fed7fae3          	bgeu	a5,a3,b0c <free+0x36>
 b1c:	6398                	ld	a4,0(a5)
 b1e:	00e6e463          	bltu	a3,a4,b26 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b22:	fee7eae3          	bltu	a5,a4,b16 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 b26:	ff852583          	lw	a1,-8(a0)
 b2a:	6390                	ld	a2,0(a5)
 b2c:	02059813          	slli	a6,a1,0x20
 b30:	01c85713          	srli	a4,a6,0x1c
 b34:	9736                	add	a4,a4,a3
 b36:	fae60ae3          	beq	a2,a4,aea <free+0x14>
    bp->s.ptr = p->s.ptr;
 b3a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b3e:	4790                	lw	a2,8(a5)
 b40:	02061593          	slli	a1,a2,0x20
 b44:	01c5d713          	srli	a4,a1,0x1c
 b48:	973e                	add	a4,a4,a5
 b4a:	fae689e3          	beq	a3,a4,afc <free+0x26>
  } else
    p->s.ptr = bp;
 b4e:	e394                	sd	a3,0(a5)
  freep = p;
 b50:	00000717          	auipc	a4,0x0
 b54:	46f73823          	sd	a5,1136(a4) # fc0 <freep>
}
 b58:	6422                	ld	s0,8(sp)
 b5a:	0141                	addi	sp,sp,16
 b5c:	8082                	ret

0000000000000b5e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b5e:	7139                	addi	sp,sp,-64
 b60:	fc06                	sd	ra,56(sp)
 b62:	f822                	sd	s0,48(sp)
 b64:	f426                	sd	s1,40(sp)
 b66:	f04a                	sd	s2,32(sp)
 b68:	ec4e                	sd	s3,24(sp)
 b6a:	e852                	sd	s4,16(sp)
 b6c:	e456                	sd	s5,8(sp)
 b6e:	e05a                	sd	s6,0(sp)
 b70:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b72:	02051493          	slli	s1,a0,0x20
 b76:	9081                	srli	s1,s1,0x20
 b78:	04bd                	addi	s1,s1,15
 b7a:	8091                	srli	s1,s1,0x4
 b7c:	0014899b          	addiw	s3,s1,1
 b80:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b82:	00000517          	auipc	a0,0x0
 b86:	43e53503          	ld	a0,1086(a0) # fc0 <freep>
 b8a:	c515                	beqz	a0,bb6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b8c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b8e:	4798                	lw	a4,8(a5)
 b90:	02977f63          	bgeu	a4,s1,bce <malloc+0x70>
 b94:	8a4e                	mv	s4,s3
 b96:	0009871b          	sext.w	a4,s3
 b9a:	6685                	lui	a3,0x1
 b9c:	00d77363          	bgeu	a4,a3,ba2 <malloc+0x44>
 ba0:	6a05                	lui	s4,0x1
 ba2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 ba6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 baa:	00000917          	auipc	s2,0x0
 bae:	41690913          	addi	s2,s2,1046 # fc0 <freep>
  if(p == (char*)-1)
 bb2:	5afd                	li	s5,-1
 bb4:	a895                	j	c28 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 bb6:	00000797          	auipc	a5,0x0
 bba:	41278793          	addi	a5,a5,1042 # fc8 <base>
 bbe:	00000717          	auipc	a4,0x0
 bc2:	40f73123          	sd	a5,1026(a4) # fc0 <freep>
 bc6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 bc8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 bcc:	b7e1                	j	b94 <malloc+0x36>
      if(p->s.size == nunits)
 bce:	02e48c63          	beq	s1,a4,c06 <malloc+0xa8>
        p->s.size -= nunits;
 bd2:	4137073b          	subw	a4,a4,s3
 bd6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 bd8:	02071693          	slli	a3,a4,0x20
 bdc:	01c6d713          	srli	a4,a3,0x1c
 be0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 be2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 be6:	00000717          	auipc	a4,0x0
 bea:	3ca73d23          	sd	a0,986(a4) # fc0 <freep>
      return (void*)(p + 1);
 bee:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 bf2:	70e2                	ld	ra,56(sp)
 bf4:	7442                	ld	s0,48(sp)
 bf6:	74a2                	ld	s1,40(sp)
 bf8:	7902                	ld	s2,32(sp)
 bfa:	69e2                	ld	s3,24(sp)
 bfc:	6a42                	ld	s4,16(sp)
 bfe:	6aa2                	ld	s5,8(sp)
 c00:	6b02                	ld	s6,0(sp)
 c02:	6121                	addi	sp,sp,64
 c04:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c06:	6398                	ld	a4,0(a5)
 c08:	e118                	sd	a4,0(a0)
 c0a:	bff1                	j	be6 <malloc+0x88>
  hp->s.size = nu;
 c0c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c10:	0541                	addi	a0,a0,16
 c12:	00000097          	auipc	ra,0x0
 c16:	ec4080e7          	jalr	-316(ra) # ad6 <free>
  return freep;
 c1a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c1e:	d971                	beqz	a0,bf2 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c20:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c22:	4798                	lw	a4,8(a5)
 c24:	fa9775e3          	bgeu	a4,s1,bce <malloc+0x70>
    if(p == freep)
 c28:	00093703          	ld	a4,0(s2)
 c2c:	853e                	mv	a0,a5
 c2e:	fef719e3          	bne	a4,a5,c20 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 c32:	8552                	mv	a0,s4
 c34:	00000097          	auipc	ra,0x0
 c38:	b7c080e7          	jalr	-1156(ra) # 7b0 <sbrk>
  if(p == (char*)-1)
 c3c:	fd5518e3          	bne	a0,s5,c0c <malloc+0xae>
        return 0;
 c40:	4501                	li	a0,0
 c42:	bf45                	j	bf2 <malloc+0x94>
