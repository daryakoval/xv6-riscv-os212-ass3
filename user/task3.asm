
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
  18:	cdc58593          	addi	a1,a1,-804 # cf0 <malloc+0xea>
  1c:	4509                	li	a0,2
  1e:	00001097          	auipc	ra,0x1
  22:	afc080e7          	jalr	-1284(ra) # b1a <fprintf>
    int i;
    int j;
    int pid = fork();
  26:	00000097          	auipc	ra,0x0
  2a:	7a2080e7          	jalr	1954(ra) # 7c8 <fork>
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
  38:	7a4080e7          	jalr	1956(ra) # 7d8 <wait>
  3c:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
  3e:	f3042683          	lw	a3,-208(s0)
  42:	00001597          	auipc	a1,0x1
  46:	d6e58593          	addi	a1,a1,-658 # db0 <malloc+0x1aa>
  4a:	4509                	li	a0,2
  4c:	00001097          	auipc	ra,0x1
  50:	ace080e7          	jalr	-1330(ra) # b1a <fprintf>
    }
        fprintf(2,"-------------test1 finished ---------------------\n");
  54:	00001597          	auipc	a1,0x1
  58:	d8458593          	addi	a1,a1,-636 # dd8 <malloc+0x1d2>
  5c:	4509                	li	a0,2
  5e:	00001097          	auipc	ra,0x1
  62:	abc080e7          	jalr	-1348(ra) # b1a <fprintf>

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
  88:	c9cb0b13          	addi	s6,s6,-868 # d20 <malloc+0x11a>
        for(i = 0; i<18; i++){
  8c:	4ac9                	li	s5,18
           malloc_array[i] = sbrk(PGSIZE); 
  8e:	6505                	lui	a0,0x1
  90:	00000097          	auipc	ra,0x0
  94:	7c8080e7          	jalr	1992(ra) # 858 <sbrk>
  98:	86aa                	mv	a3,a0
  9a:	00aa3023          	sd	a0,0(s4)
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  9e:	864a                	mv	a2,s2
  a0:	85da                	mv	a1,s6
  a2:	4509                	li	a0,2
  a4:	00001097          	auipc	ra,0x1
  a8:	a76080e7          	jalr	-1418(ra) # b1a <fprintf>
        for(i = 0; i<18; i++){
  ac:	2905                	addiw	s2,s2,1
  ae:	0a21                	addi	s4,s4,8
  b0:	fd591fe3          	bne	s2,s5,8e <test1+0x8e>
        fprintf(2,"Allocated 18 pages, some of them on disk\n");
  b4:	00001597          	auipc	a1,0x1
  b8:	c8c58593          	addi	a1,a1,-884 # d40 <malloc+0x13a>
  bc:	4509                	li	a0,2
  be:	00001097          	auipc	ra,0x1
  c2:	a5c080e7          	jalr	-1444(ra) # b1a <fprintf>
        fprintf(2,"Lets try to access all pages:\n");
  c6:	00001597          	auipc	a1,0x1
  ca:	caa58593          	addi	a1,a1,-854 # d70 <malloc+0x16a>
  ce:	4509                	li	a0,2
  d0:	00001097          	auipc	ra,0x1
  d4:	a4a080e7          	jalr	-1462(ra) # b1a <fprintf>
        for(i = 0; i<18; i++){
  d8:	6b05                	lui	s6,0x1
                malloc_array[i][j] = 'x'; 
  da:	07800913          	li	s2,120
            fprintf(2,"Filled array num=%d with chars\n", i);
  de:	00001a97          	auipc	s5,0x1
  e2:	cb2a8a93          	addi	s5,s5,-846 # d90 <malloc+0x18a>
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
 104:	a1a080e7          	jalr	-1510(ra) # b1a <fprintf>
        for(i = 0; i<18; i++){
 108:	2485                	addiw	s1,s1,1
 10a:	09a1                	addi	s3,s3,8
 10c:	fd449ee3          	bne	s1,s4,e8 <test1+0xe8>
        exit(0);
 110:	4501                	li	a0,0
 112:	00000097          	auipc	ra,0x0
 116:	6be080e7          	jalr	1726(ra) # 7d0 <exit>

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
 126:	cee58593          	addi	a1,a1,-786 # e10 <malloc+0x20a>
 12a:	4509                	li	a0,2
 12c:	00001097          	auipc	ra,0x1
 130:	9ee080e7          	jalr	-1554(ra) # b1a <fprintf>
    char* i;
    i = sbrk(20*PGSIZE);
 134:	6551                	lui	a0,0x14
 136:	00000097          	auipc	ra,0x0
 13a:	722080e7          	jalr	1826(ra) # 858 <sbrk>
 13e:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 140:	00001597          	auipc	a1,0x1
 144:	be858593          	addi	a1,a1,-1048 # d28 <malloc+0x122>
 148:	4509                	li	a0,2
 14a:	00001097          	auipc	ra,0x1
 14e:	9d0080e7          	jalr	-1584(ra) # b1a <fprintf>
    i = sbrk(-20*PGSIZE);
 152:	7531                	lui	a0,0xfffec
 154:	00000097          	auipc	ra,0x0
 158:	704080e7          	jalr	1796(ra) # 858 <sbrk>
 15c:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 15e:	00001597          	auipc	a1,0x1
 162:	ce258593          	addi	a1,a1,-798 # e40 <malloc+0x23a>
 166:	4509                	li	a0,2
 168:	00001097          	auipc	ra,0x1
 16c:	9b2080e7          	jalr	-1614(ra) # b1a <fprintf>
    i = sbrk(20*PGSIZE);
 170:	6551                	lui	a0,0x14
 172:	00000097          	auipc	ra,0x0
 176:	6e6080e7          	jalr	1766(ra) # 858 <sbrk>
 17a:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 17c:	00001597          	auipc	a1,0x1
 180:	bac58593          	addi	a1,a1,-1108 # d28 <malloc+0x122>
 184:	4509                	li	a0,2
 186:	00001097          	auipc	ra,0x1
 18a:	994080e7          	jalr	-1644(ra) # b1a <fprintf>
    i = sbrk(-20*PGSIZE);
 18e:	7531                	lui	a0,0xfffec
 190:	00000097          	auipc	ra,0x0
 194:	6c8080e7          	jalr	1736(ra) # 858 <sbrk>
 198:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 19a:	00001597          	auipc	a1,0x1
 19e:	ca658593          	addi	a1,a1,-858 # e40 <malloc+0x23a>
 1a2:	4509                	li	a0,2
 1a4:	00001097          	auipc	ra,0x1
 1a8:	976080e7          	jalr	-1674(ra) # b1a <fprintf>
    i = sbrk(20*PGSIZE);
 1ac:	6551                	lui	a0,0x14
 1ae:	00000097          	auipc	ra,0x0
 1b2:	6aa080e7          	jalr	1706(ra) # 858 <sbrk>
 1b6:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 1b8:	00001597          	auipc	a1,0x1
 1bc:	b7058593          	addi	a1,a1,-1168 # d28 <malloc+0x122>
 1c0:	4509                	li	a0,2
 1c2:	00001097          	auipc	ra,0x1
 1c6:	958080e7          	jalr	-1704(ra) # b1a <fprintf>
    i = sbrk(-20*PGSIZE);
 1ca:	7531                	lui	a0,0xfffec
 1cc:	00000097          	auipc	ra,0x0
 1d0:	68c080e7          	jalr	1676(ra) # 858 <sbrk>
 1d4:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 1d6:	00001597          	auipc	a1,0x1
 1da:	c6a58593          	addi	a1,a1,-918 # e40 <malloc+0x23a>
 1de:	4509                	li	a0,2
 1e0:	00001097          	auipc	ra,0x1
 1e4:	93a080e7          	jalr	-1734(ra) # b1a <fprintf>

    fprintf(2,"-------------test2 finished ---------------------\n");
 1e8:	00001597          	auipc	a1,0x1
 1ec:	c7858593          	addi	a1,a1,-904 # e60 <malloc+0x25a>
 1f0:	4509                	li	a0,2
 1f2:	00001097          	auipc	ra,0x1
 1f6:	928080e7          	jalr	-1752(ra) # b1a <fprintf>


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
 21a:	c8258593          	addi	a1,a1,-894 # e98 <malloc+0x292>
 21e:	4509                	li	a0,2
 220:	00001097          	auipc	ra,0x1
 224:	8fa080e7          	jalr	-1798(ra) # b1a <fprintf>
    uint64 i;
    char* arr = malloc(PGSIZE*17);
 228:	6545                	lui	a0,0x11
 22a:	00001097          	auipc	ra,0x1
 22e:	9dc080e7          	jalr	-1572(ra) # c06 <malloc>
 232:	89aa                	mv	s3,a0
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 234:	4481                	li	s1,0
        arr[i] = 'a';
 236:	06100913          	li	s2,97
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 23a:	00001b17          	auipc	s6,0x1
 23e:	c8eb0b13          	addi	s6,s6,-882 # ec8 <malloc+0x2c2>
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
 25a:	8c4080e7          	jalr	-1852(ra) # b1a <fprintf>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 25e:	94d6                	add	s1,s1,s5
 260:	ff4493e3          	bne	s1,s4,246 <test3+0x44>
    }
    int pid = fork();
 264:	00000097          	auipc	ra,0x0
 268:	564080e7          	jalr	1380(ra) # 7c8 <fork>
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
 276:	566080e7          	jalr	1382(ra) # 7d8 <wait>
 27a:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
 27c:	fbc42683          	lw	a3,-68(s0)
 280:	00001597          	auipc	a1,0x1
 284:	b3058593          	addi	a1,a1,-1232 # db0 <malloc+0x1aa>
 288:	4509                	li	a0,2
 28a:	00001097          	auipc	ra,0x1
 28e:	890080e7          	jalr	-1904(ra) # b1a <fprintf>
        sbrk(-17*PGSIZE);
 292:	753d                	lui	a0,0xfffef
 294:	00000097          	auipc	ra,0x0
 298:	5c4080e7          	jalr	1476(ra) # 858 <sbrk>
    }
        fprintf(2,"-------------test3 finished ---------------------\n");
 29c:	00001597          	auipc	a1,0x1
 2a0:	c5c58593          	addi	a1,a1,-932 # ef8 <malloc+0x2f2>
 2a4:	4509                	li	a0,2
 2a6:	00001097          	auipc	ra,0x1
 2aa:	874080e7          	jalr	-1932(ra) # b1a <fprintf>

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
 2c8:	c1ca8a93          	addi	s5,s5,-996 # ee0 <malloc+0x2da>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2cc:	6a05                	lui	s4,0x1
 2ce:	6945                	lui	s2,0x11
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 2d0:	009987b3          	add	a5,s3,s1
 2d4:	0007c683          	lbu	a3,0(a5)
 2d8:	8626                	mv	a2,s1
 2da:	85d6                	mv	a1,s5
 2dc:	4509                	li	a0,2
 2de:	00001097          	auipc	ra,0x1
 2e2:	83c080e7          	jalr	-1988(ra) # b1a <fprintf>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2e6:	94d2                	add	s1,s1,s4
 2e8:	ff2494e3          	bne	s1,s2,2d0 <test3+0xce>
        exit(i);
 2ec:	6545                	lui	a0,0x11
 2ee:	00000097          	auipc	ra,0x0
 2f2:	4e2080e7          	jalr	1250(ra) # 7d0 <exit>

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
 30e:	c2658593          	addi	a1,a1,-986 # f30 <malloc+0x32a>
 312:	4509                	li	a0,2
 314:	00001097          	auipc	ra,0x1
 318:	806080e7          	jalr	-2042(ra) # b1a <fprintf>
    int *arr = (int *)malloc(2000 * sizeof(PGSIZE));
 31c:	6509                	lui	a0,0x2
 31e:	f4050513          	addi	a0,a0,-192 # 1f40 <__global_pointer$+0x697>
 322:	00001097          	auipc	ra,0x1
 326:	8e4080e7          	jalr	-1820(ra) # c06 <malloc>
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
 33e:	004a0913          	addi	s2,s4,4 # 1004 <malloc+0x3fe>
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
 34a:	c1ab0b13          	addi	s6,s6,-998 # f60 <malloc+0x35a>
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
 368:	7e4080e7          	jalr	2020(ra) # b48 <printf>
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
 382:	bfa50513          	addi	a0,a0,-1030 # f78 <malloc+0x372>
 386:	00000097          	auipc	ra,0x0
 38a:	7c2080e7          	jalr	1986(ra) # b48 <printf>
    fprintf(2,"-------------test4 finished ---------------------\n");
 38e:	00001597          	auipc	a1,0x1
 392:	c0258593          	addi	a1,a1,-1022 # f90 <malloc+0x38a>
 396:	4509                	li	a0,2
 398:	00000097          	auipc	ra,0x0
 39c:	782080e7          	jalr	1922(ra) # b1a <fprintf>
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
 3c2:	c0a50513          	addi	a0,a0,-1014 # fc8 <malloc+0x3c2>
 3c6:	00000097          	auipc	ra,0x0
 3ca:	782080e7          	jalr	1922(ra) # b48 <printf>
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
 3e4:	bf050513          	addi	a0,a0,-1040 # fd0 <malloc+0x3ca>
 3e8:	00000097          	auipc	ra,0x0
 3ec:	760080e7          	jalr	1888(ra) # b48 <printf>
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
 406:	bd650513          	addi	a0,a0,-1066 # fd8 <malloc+0x3d2>
 40a:	00000097          	auipc	ra,0x0
 40e:	73e080e7          	jalr	1854(ra) # b48 <printf>
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
 422:	1000                	addi	s0,sp,32
        fprintf(2,"-------------test5 start ---------------------\n");
 424:	00001597          	auipc	a1,0x1
 428:	bbc58593          	addi	a1,a1,-1092 # fe0 <malloc+0x3da>
 42c:	4509                	li	a0,2
 42e:	00000097          	auipc	ra,0x0
 432:	6ec080e7          	jalr	1772(ra) # b1a <fprintf>
    // for(int i = 0; i < 1000; i ++){
    //     aprint(i);
    //     bprint(i);
    //     cprint(i);
    // }
        int f = fork();
 436:	00000097          	auipc	ra,0x0
 43a:	392080e7          	jalr	914(ra) # 7c8 <fork>

    if(f == 0){
 43e:	e171                	bnez	a0,502 <test5+0xe8>
        char* arr = (char*)(malloc(sizeof(char)*PGSIZE*12));
 440:	6531                	lui	a0,0xc
 442:	00000097          	auipc	ra,0x0
 446:	7c4080e7          	jalr	1988(ra) # c06 <malloc>
 44a:	84aa                	mv	s1,a0
        for(int i=PGSIZE*0; i<PGSIZE*1; i++){
 44c:	6705                	lui	a4,0x1
 44e:	972a                	add	a4,a4,a0
        char* arr = (char*)(malloc(sizeof(char)*PGSIZE*12));
 450:	87aa                	mv	a5,a0
            arr[i]='a';
 452:	06100693          	li	a3,97
 456:	00d78023          	sb	a3,0(a5)
        for(int i=PGSIZE*0; i<PGSIZE*1; i++){
 45a:	0785                	addi	a5,a5,1
 45c:	fee79de3          	bne	a5,a4,456 <test5+0x3c>
        }
        printf("Create child #1\n");
 460:	00001517          	auipc	a0,0x1
 464:	bb050513          	addi	a0,a0,-1104 # 1010 <malloc+0x40a>
 468:	00000097          	auipc	ra,0x0
 46c:	6e0080e7          	jalr	1760(ra) # b48 <printf>
        int f2 = fork();
 470:	00000097          	auipc	ra,0x0
 474:	358080e7          	jalr	856(ra) # 7c8 <fork>
        if(f2 == 0){
 478:	c139                	beqz	a0,4be <test5+0xa4>
            for(int i=PGSIZE*1; i<PGSIZE*2; i++){
                arr[i]='b';
            }
            exit(0);
        }else{
            wait(0);
 47a:	4501                	li	a0,0
 47c:	00000097          	auipc	ra,0x0
 480:	35c080e7          	jalr	860(ra) # 7d8 <wait>
        }
        printf("Create child #2\n");
 484:	00001517          	auipc	a0,0x1
 488:	ba450513          	addi	a0,a0,-1116 # 1028 <malloc+0x422>
 48c:	00000097          	auipc	ra,0x0
 490:	6bc080e7          	jalr	1724(ra) # b48 <printf>
        int f3 = fork();
 494:	00000097          	auipc	ra,0x0
 498:	334080e7          	jalr	820(ra) # 7c8 <fork>
        if(f3 == 0){
 49c:	e129                	bnez	a0,4de <test5+0xc4>
 49e:	6789                	lui	a5,0x2
 4a0:	97a6                	add	a5,a5,s1
 4a2:	670d                	lui	a4,0x3
 4a4:	9726                	add	a4,a4,s1
            for(int i=PGSIZE*2; i<PGSIZE*3; i++){
                arr[i]='c';
 4a6:	06300693          	li	a3,99
 4aa:	00d78023          	sb	a3,0(a5) # 2000 <__global_pointer$+0x757>
            for(int i=PGSIZE*2; i<PGSIZE*3; i++){
 4ae:	0785                	addi	a5,a5,1
 4b0:	fee79de3          	bne	a5,a4,4aa <test5+0x90>
            }
            exit(0);
 4b4:	4501                	li	a0,0
 4b6:	00000097          	auipc	ra,0x0
 4ba:	31a080e7          	jalr	794(ra) # 7d0 <exit>
 4be:	6785                	lui	a5,0x1
 4c0:	97a6                	add	a5,a5,s1
 4c2:	6709                	lui	a4,0x2
 4c4:	9726                	add	a4,a4,s1
                arr[i]='b';
 4c6:	06200693          	li	a3,98
 4ca:	00d78023          	sb	a3,0(a5) # 1000 <malloc+0x3fa>
            for(int i=PGSIZE*1; i<PGSIZE*2; i++){
 4ce:	0785                	addi	a5,a5,1
 4d0:	fee79de3          	bne	a5,a4,4ca <test5+0xb0>
            exit(0);
 4d4:	4501                	li	a0,0
 4d6:	00000097          	auipc	ra,0x0
 4da:	2fa080e7          	jalr	762(ra) # 7d0 <exit>
        }else{
            wait(0);
 4de:	4501                	li	a0,0
 4e0:	00000097          	auipc	ra,0x0
 4e4:	2f8080e7          	jalr	760(ra) # 7d8 <wait>
        }
        printf("Create child #3\n");
 4e8:	00001517          	auipc	a0,0x1
 4ec:	b5850513          	addi	a0,a0,-1192 # 1040 <malloc+0x43a>
 4f0:	00000097          	auipc	ra,0x0
 4f4:	658080e7          	jalr	1624(ra) # b48 <printf>
        exit(0);
 4f8:	4501                	li	a0,0
 4fa:	00000097          	auipc	ra,0x0
 4fe:	2d6080e7          	jalr	726(ra) # 7d0 <exit>
    }else{
        wait(0);
 502:	4501                	li	a0,0
 504:	00000097          	auipc	ra,0x0
 508:	2d4080e7          	jalr	724(ra) # 7d8 <wait>
    }
        fprintf(2,"-------------test5 finished ---------------------\n");
 50c:	00001597          	auipc	a1,0x1
 510:	b4c58593          	addi	a1,a1,-1204 # 1058 <malloc+0x452>
 514:	4509                	li	a0,2
 516:	00000097          	auipc	ra,0x0
 51a:	604080e7          	jalr	1540(ra) # b1a <fprintf>
}
 51e:	60e2                	ld	ra,24(sp)
 520:	6442                	ld	s0,16(sp)
 522:	64a2                	ld	s1,8(sp)
 524:	6105                	addi	sp,sp,32
 526:	8082                	ret

0000000000000528 <main>:


int main(int argc, char** argv){
 528:	1141                	addi	sp,sp,-16
 52a:	e406                	sd	ra,8(sp)
 52c:	e022                	sd	s0,0(sp)
 52e:	0800                	addi	s0,sp,16
    test1();
 530:	00000097          	auipc	ra,0x0
 534:	ad0080e7          	jalr	-1328(ra) # 0 <test1>
    test2();
 538:	00000097          	auipc	ra,0x0
 53c:	be2080e7          	jalr	-1054(ra) # 11a <test2>
    test3();
 540:	00000097          	auipc	ra,0x0
 544:	cc2080e7          	jalr	-830(ra) # 202 <test3>
    test4();
 548:	00000097          	auipc	ra,0x0
 54c:	dae080e7          	jalr	-594(ra) # 2f6 <test4>
    test5();
 550:	00000097          	auipc	ra,0x0
 554:	eca080e7          	jalr	-310(ra) # 41a <test5>
    exit(0);
 558:	4501                	li	a0,0
 55a:	00000097          	auipc	ra,0x0
 55e:	276080e7          	jalr	630(ra) # 7d0 <exit>

0000000000000562 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 562:	1141                	addi	sp,sp,-16
 564:	e422                	sd	s0,8(sp)
 566:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 568:	87aa                	mv	a5,a0
 56a:	0585                	addi	a1,a1,1
 56c:	0785                	addi	a5,a5,1
 56e:	fff5c703          	lbu	a4,-1(a1)
 572:	fee78fa3          	sb	a4,-1(a5)
 576:	fb75                	bnez	a4,56a <strcpy+0x8>
    ;
  return os;
}
 578:	6422                	ld	s0,8(sp)
 57a:	0141                	addi	sp,sp,16
 57c:	8082                	ret

000000000000057e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 57e:	1141                	addi	sp,sp,-16
 580:	e422                	sd	s0,8(sp)
 582:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 584:	00054783          	lbu	a5,0(a0)
 588:	cb91                	beqz	a5,59c <strcmp+0x1e>
 58a:	0005c703          	lbu	a4,0(a1)
 58e:	00f71763          	bne	a4,a5,59c <strcmp+0x1e>
    p++, q++;
 592:	0505                	addi	a0,a0,1
 594:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 596:	00054783          	lbu	a5,0(a0)
 59a:	fbe5                	bnez	a5,58a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 59c:	0005c503          	lbu	a0,0(a1)
}
 5a0:	40a7853b          	subw	a0,a5,a0
 5a4:	6422                	ld	s0,8(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret

00000000000005aa <strlen>:

uint
strlen(const char *s)
{
 5aa:	1141                	addi	sp,sp,-16
 5ac:	e422                	sd	s0,8(sp)
 5ae:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 5b0:	00054783          	lbu	a5,0(a0)
 5b4:	cf91                	beqz	a5,5d0 <strlen+0x26>
 5b6:	0505                	addi	a0,a0,1
 5b8:	87aa                	mv	a5,a0
 5ba:	4685                	li	a3,1
 5bc:	9e89                	subw	a3,a3,a0
 5be:	00f6853b          	addw	a0,a3,a5
 5c2:	0785                	addi	a5,a5,1
 5c4:	fff7c703          	lbu	a4,-1(a5)
 5c8:	fb7d                	bnez	a4,5be <strlen+0x14>
    ;
  return n;
}
 5ca:	6422                	ld	s0,8(sp)
 5cc:	0141                	addi	sp,sp,16
 5ce:	8082                	ret
  for(n = 0; s[n]; n++)
 5d0:	4501                	li	a0,0
 5d2:	bfe5                	j	5ca <strlen+0x20>

00000000000005d4 <memset>:

void*
memset(void *dst, int c, uint n)
{
 5d4:	1141                	addi	sp,sp,-16
 5d6:	e422                	sd	s0,8(sp)
 5d8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 5da:	ca19                	beqz	a2,5f0 <memset+0x1c>
 5dc:	87aa                	mv	a5,a0
 5de:	1602                	slli	a2,a2,0x20
 5e0:	9201                	srli	a2,a2,0x20
 5e2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 5e6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 5ea:	0785                	addi	a5,a5,1
 5ec:	fee79de3          	bne	a5,a4,5e6 <memset+0x12>
  }
  return dst;
}
 5f0:	6422                	ld	s0,8(sp)
 5f2:	0141                	addi	sp,sp,16
 5f4:	8082                	ret

00000000000005f6 <strchr>:

char*
strchr(const char *s, char c)
{
 5f6:	1141                	addi	sp,sp,-16
 5f8:	e422                	sd	s0,8(sp)
 5fa:	0800                	addi	s0,sp,16
  for(; *s; s++)
 5fc:	00054783          	lbu	a5,0(a0)
 600:	cb99                	beqz	a5,616 <strchr+0x20>
    if(*s == c)
 602:	00f58763          	beq	a1,a5,610 <strchr+0x1a>
  for(; *s; s++)
 606:	0505                	addi	a0,a0,1
 608:	00054783          	lbu	a5,0(a0)
 60c:	fbfd                	bnez	a5,602 <strchr+0xc>
      return (char*)s;
  return 0;
 60e:	4501                	li	a0,0
}
 610:	6422                	ld	s0,8(sp)
 612:	0141                	addi	sp,sp,16
 614:	8082                	ret
  return 0;
 616:	4501                	li	a0,0
 618:	bfe5                	j	610 <strchr+0x1a>

000000000000061a <gets>:

char*
gets(char *buf, int max)
{
 61a:	711d                	addi	sp,sp,-96
 61c:	ec86                	sd	ra,88(sp)
 61e:	e8a2                	sd	s0,80(sp)
 620:	e4a6                	sd	s1,72(sp)
 622:	e0ca                	sd	s2,64(sp)
 624:	fc4e                	sd	s3,56(sp)
 626:	f852                	sd	s4,48(sp)
 628:	f456                	sd	s5,40(sp)
 62a:	f05a                	sd	s6,32(sp)
 62c:	ec5e                	sd	s7,24(sp)
 62e:	1080                	addi	s0,sp,96
 630:	8baa                	mv	s7,a0
 632:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 634:	892a                	mv	s2,a0
 636:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 638:	4aa9                	li	s5,10
 63a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 63c:	89a6                	mv	s3,s1
 63e:	2485                	addiw	s1,s1,1
 640:	0344d863          	bge	s1,s4,670 <gets+0x56>
    cc = read(0, &c, 1);
 644:	4605                	li	a2,1
 646:	faf40593          	addi	a1,s0,-81
 64a:	4501                	li	a0,0
 64c:	00000097          	auipc	ra,0x0
 650:	19c080e7          	jalr	412(ra) # 7e8 <read>
    if(cc < 1)
 654:	00a05e63          	blez	a0,670 <gets+0x56>
    buf[i++] = c;
 658:	faf44783          	lbu	a5,-81(s0)
 65c:	00f90023          	sb	a5,0(s2) # 11000 <__global_pointer$+0xf757>
    if(c == '\n' || c == '\r')
 660:	01578763          	beq	a5,s5,66e <gets+0x54>
 664:	0905                	addi	s2,s2,1
 666:	fd679be3          	bne	a5,s6,63c <gets+0x22>
  for(i=0; i+1 < max; ){
 66a:	89a6                	mv	s3,s1
 66c:	a011                	j	670 <gets+0x56>
 66e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 670:	99de                	add	s3,s3,s7
 672:	00098023          	sb	zero,0(s3)
  return buf;
}
 676:	855e                	mv	a0,s7
 678:	60e6                	ld	ra,88(sp)
 67a:	6446                	ld	s0,80(sp)
 67c:	64a6                	ld	s1,72(sp)
 67e:	6906                	ld	s2,64(sp)
 680:	79e2                	ld	s3,56(sp)
 682:	7a42                	ld	s4,48(sp)
 684:	7aa2                	ld	s5,40(sp)
 686:	7b02                	ld	s6,32(sp)
 688:	6be2                	ld	s7,24(sp)
 68a:	6125                	addi	sp,sp,96
 68c:	8082                	ret

000000000000068e <stat>:

int
stat(const char *n, struct stat *st)
{
 68e:	1101                	addi	sp,sp,-32
 690:	ec06                	sd	ra,24(sp)
 692:	e822                	sd	s0,16(sp)
 694:	e426                	sd	s1,8(sp)
 696:	e04a                	sd	s2,0(sp)
 698:	1000                	addi	s0,sp,32
 69a:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 69c:	4581                	li	a1,0
 69e:	00000097          	auipc	ra,0x0
 6a2:	172080e7          	jalr	370(ra) # 810 <open>
  if(fd < 0)
 6a6:	02054563          	bltz	a0,6d0 <stat+0x42>
 6aa:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 6ac:	85ca                	mv	a1,s2
 6ae:	00000097          	auipc	ra,0x0
 6b2:	17a080e7          	jalr	378(ra) # 828 <fstat>
 6b6:	892a                	mv	s2,a0
  close(fd);
 6b8:	8526                	mv	a0,s1
 6ba:	00000097          	auipc	ra,0x0
 6be:	13e080e7          	jalr	318(ra) # 7f8 <close>
  return r;
}
 6c2:	854a                	mv	a0,s2
 6c4:	60e2                	ld	ra,24(sp)
 6c6:	6442                	ld	s0,16(sp)
 6c8:	64a2                	ld	s1,8(sp)
 6ca:	6902                	ld	s2,0(sp)
 6cc:	6105                	addi	sp,sp,32
 6ce:	8082                	ret
    return -1;
 6d0:	597d                	li	s2,-1
 6d2:	bfc5                	j	6c2 <stat+0x34>

00000000000006d4 <atoi>:

int
atoi(const char *s)
{
 6d4:	1141                	addi	sp,sp,-16
 6d6:	e422                	sd	s0,8(sp)
 6d8:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 6da:	00054603          	lbu	a2,0(a0)
 6de:	fd06079b          	addiw	a5,a2,-48
 6e2:	0ff7f793          	andi	a5,a5,255
 6e6:	4725                	li	a4,9
 6e8:	02f76963          	bltu	a4,a5,71a <atoi+0x46>
 6ec:	86aa                	mv	a3,a0
  n = 0;
 6ee:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 6f0:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 6f2:	0685                	addi	a3,a3,1
 6f4:	0025179b          	slliw	a5,a0,0x2
 6f8:	9fa9                	addw	a5,a5,a0
 6fa:	0017979b          	slliw	a5,a5,0x1
 6fe:	9fb1                	addw	a5,a5,a2
 700:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 704:	0006c603          	lbu	a2,0(a3)
 708:	fd06071b          	addiw	a4,a2,-48
 70c:	0ff77713          	andi	a4,a4,255
 710:	fee5f1e3          	bgeu	a1,a4,6f2 <atoi+0x1e>
  return n;
}
 714:	6422                	ld	s0,8(sp)
 716:	0141                	addi	sp,sp,16
 718:	8082                	ret
  n = 0;
 71a:	4501                	li	a0,0
 71c:	bfe5                	j	714 <atoi+0x40>

000000000000071e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 71e:	1141                	addi	sp,sp,-16
 720:	e422                	sd	s0,8(sp)
 722:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 724:	02b57463          	bgeu	a0,a1,74c <memmove+0x2e>
    while(n-- > 0)
 728:	00c05f63          	blez	a2,746 <memmove+0x28>
 72c:	1602                	slli	a2,a2,0x20
 72e:	9201                	srli	a2,a2,0x20
 730:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 734:	872a                	mv	a4,a0
      *dst++ = *src++;
 736:	0585                	addi	a1,a1,1
 738:	0705                	addi	a4,a4,1
 73a:	fff5c683          	lbu	a3,-1(a1)
 73e:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0x756>
    while(n-- > 0)
 742:	fee79ae3          	bne	a5,a4,736 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 746:	6422                	ld	s0,8(sp)
 748:	0141                	addi	sp,sp,16
 74a:	8082                	ret
    dst += n;
 74c:	00c50733          	add	a4,a0,a2
    src += n;
 750:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 752:	fec05ae3          	blez	a2,746 <memmove+0x28>
 756:	fff6079b          	addiw	a5,a2,-1
 75a:	1782                	slli	a5,a5,0x20
 75c:	9381                	srli	a5,a5,0x20
 75e:	fff7c793          	not	a5,a5
 762:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 764:	15fd                	addi	a1,a1,-1
 766:	177d                	addi	a4,a4,-1
 768:	0005c683          	lbu	a3,0(a1)
 76c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 770:	fee79ae3          	bne	a5,a4,764 <memmove+0x46>
 774:	bfc9                	j	746 <memmove+0x28>

0000000000000776 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 776:	1141                	addi	sp,sp,-16
 778:	e422                	sd	s0,8(sp)
 77a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 77c:	ca05                	beqz	a2,7ac <memcmp+0x36>
 77e:	fff6069b          	addiw	a3,a2,-1
 782:	1682                	slli	a3,a3,0x20
 784:	9281                	srli	a3,a3,0x20
 786:	0685                	addi	a3,a3,1
 788:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 78a:	00054783          	lbu	a5,0(a0)
 78e:	0005c703          	lbu	a4,0(a1)
 792:	00e79863          	bne	a5,a4,7a2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 796:	0505                	addi	a0,a0,1
    p2++;
 798:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 79a:	fed518e3          	bne	a0,a3,78a <memcmp+0x14>
  }
  return 0;
 79e:	4501                	li	a0,0
 7a0:	a019                	j	7a6 <memcmp+0x30>
      return *p1 - *p2;
 7a2:	40e7853b          	subw	a0,a5,a4
}
 7a6:	6422                	ld	s0,8(sp)
 7a8:	0141                	addi	sp,sp,16
 7aa:	8082                	ret
  return 0;
 7ac:	4501                	li	a0,0
 7ae:	bfe5                	j	7a6 <memcmp+0x30>

00000000000007b0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 7b0:	1141                	addi	sp,sp,-16
 7b2:	e406                	sd	ra,8(sp)
 7b4:	e022                	sd	s0,0(sp)
 7b6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 7b8:	00000097          	auipc	ra,0x0
 7bc:	f66080e7          	jalr	-154(ra) # 71e <memmove>
}
 7c0:	60a2                	ld	ra,8(sp)
 7c2:	6402                	ld	s0,0(sp)
 7c4:	0141                	addi	sp,sp,16
 7c6:	8082                	ret

00000000000007c8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 7c8:	4885                	li	a7,1
 ecall
 7ca:	00000073          	ecall
 ret
 7ce:	8082                	ret

00000000000007d0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 7d0:	4889                	li	a7,2
 ecall
 7d2:	00000073          	ecall
 ret
 7d6:	8082                	ret

00000000000007d8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 7d8:	488d                	li	a7,3
 ecall
 7da:	00000073          	ecall
 ret
 7de:	8082                	ret

00000000000007e0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 7e0:	4891                	li	a7,4
 ecall
 7e2:	00000073          	ecall
 ret
 7e6:	8082                	ret

00000000000007e8 <read>:
.global read
read:
 li a7, SYS_read
 7e8:	4895                	li	a7,5
 ecall
 7ea:	00000073          	ecall
 ret
 7ee:	8082                	ret

00000000000007f0 <write>:
.global write
write:
 li a7, SYS_write
 7f0:	48c1                	li	a7,16
 ecall
 7f2:	00000073          	ecall
 ret
 7f6:	8082                	ret

00000000000007f8 <close>:
.global close
close:
 li a7, SYS_close
 7f8:	48d5                	li	a7,21
 ecall
 7fa:	00000073          	ecall
 ret
 7fe:	8082                	ret

0000000000000800 <kill>:
.global kill
kill:
 li a7, SYS_kill
 800:	4899                	li	a7,6
 ecall
 802:	00000073          	ecall
 ret
 806:	8082                	ret

0000000000000808 <exec>:
.global exec
exec:
 li a7, SYS_exec
 808:	489d                	li	a7,7
 ecall
 80a:	00000073          	ecall
 ret
 80e:	8082                	ret

0000000000000810 <open>:
.global open
open:
 li a7, SYS_open
 810:	48bd                	li	a7,15
 ecall
 812:	00000073          	ecall
 ret
 816:	8082                	ret

0000000000000818 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 818:	48c5                	li	a7,17
 ecall
 81a:	00000073          	ecall
 ret
 81e:	8082                	ret

0000000000000820 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 820:	48c9                	li	a7,18
 ecall
 822:	00000073          	ecall
 ret
 826:	8082                	ret

0000000000000828 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 828:	48a1                	li	a7,8
 ecall
 82a:	00000073          	ecall
 ret
 82e:	8082                	ret

0000000000000830 <link>:
.global link
link:
 li a7, SYS_link
 830:	48cd                	li	a7,19
 ecall
 832:	00000073          	ecall
 ret
 836:	8082                	ret

0000000000000838 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 838:	48d1                	li	a7,20
 ecall
 83a:	00000073          	ecall
 ret
 83e:	8082                	ret

0000000000000840 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 840:	48a5                	li	a7,9
 ecall
 842:	00000073          	ecall
 ret
 846:	8082                	ret

0000000000000848 <dup>:
.global dup
dup:
 li a7, SYS_dup
 848:	48a9                	li	a7,10
 ecall
 84a:	00000073          	ecall
 ret
 84e:	8082                	ret

0000000000000850 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 850:	48ad                	li	a7,11
 ecall
 852:	00000073          	ecall
 ret
 856:	8082                	ret

0000000000000858 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 858:	48b1                	li	a7,12
 ecall
 85a:	00000073          	ecall
 ret
 85e:	8082                	ret

0000000000000860 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 860:	48b5                	li	a7,13
 ecall
 862:	00000073          	ecall
 ret
 866:	8082                	ret

0000000000000868 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 868:	48b9                	li	a7,14
 ecall
 86a:	00000073          	ecall
 ret
 86e:	8082                	ret

0000000000000870 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 870:	1101                	addi	sp,sp,-32
 872:	ec06                	sd	ra,24(sp)
 874:	e822                	sd	s0,16(sp)
 876:	1000                	addi	s0,sp,32
 878:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 87c:	4605                	li	a2,1
 87e:	fef40593          	addi	a1,s0,-17
 882:	00000097          	auipc	ra,0x0
 886:	f6e080e7          	jalr	-146(ra) # 7f0 <write>
}
 88a:	60e2                	ld	ra,24(sp)
 88c:	6442                	ld	s0,16(sp)
 88e:	6105                	addi	sp,sp,32
 890:	8082                	ret

0000000000000892 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 892:	7139                	addi	sp,sp,-64
 894:	fc06                	sd	ra,56(sp)
 896:	f822                	sd	s0,48(sp)
 898:	f426                	sd	s1,40(sp)
 89a:	f04a                	sd	s2,32(sp)
 89c:	ec4e                	sd	s3,24(sp)
 89e:	0080                	addi	s0,sp,64
 8a0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 8a2:	c299                	beqz	a3,8a8 <printint+0x16>
 8a4:	0805c863          	bltz	a1,934 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 8a8:	2581                	sext.w	a1,a1
  neg = 0;
 8aa:	4881                	li	a7,0
 8ac:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 8b0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 8b2:	2601                	sext.w	a2,a2
 8b4:	00000517          	auipc	a0,0x0
 8b8:	7e450513          	addi	a0,a0,2020 # 1098 <digits>
 8bc:	883a                	mv	a6,a4
 8be:	2705                	addiw	a4,a4,1
 8c0:	02c5f7bb          	remuw	a5,a1,a2
 8c4:	1782                	slli	a5,a5,0x20
 8c6:	9381                	srli	a5,a5,0x20
 8c8:	97aa                	add	a5,a5,a0
 8ca:	0007c783          	lbu	a5,0(a5)
 8ce:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 8d2:	0005879b          	sext.w	a5,a1
 8d6:	02c5d5bb          	divuw	a1,a1,a2
 8da:	0685                	addi	a3,a3,1
 8dc:	fec7f0e3          	bgeu	a5,a2,8bc <printint+0x2a>
  if(neg)
 8e0:	00088b63          	beqz	a7,8f6 <printint+0x64>
    buf[i++] = '-';
 8e4:	fd040793          	addi	a5,s0,-48
 8e8:	973e                	add	a4,a4,a5
 8ea:	02d00793          	li	a5,45
 8ee:	fef70823          	sb	a5,-16(a4)
 8f2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 8f6:	02e05863          	blez	a4,926 <printint+0x94>
 8fa:	fc040793          	addi	a5,s0,-64
 8fe:	00e78933          	add	s2,a5,a4
 902:	fff78993          	addi	s3,a5,-1
 906:	99ba                	add	s3,s3,a4
 908:	377d                	addiw	a4,a4,-1
 90a:	1702                	slli	a4,a4,0x20
 90c:	9301                	srli	a4,a4,0x20
 90e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 912:	fff94583          	lbu	a1,-1(s2)
 916:	8526                	mv	a0,s1
 918:	00000097          	auipc	ra,0x0
 91c:	f58080e7          	jalr	-168(ra) # 870 <putc>
  while(--i >= 0)
 920:	197d                	addi	s2,s2,-1
 922:	ff3918e3          	bne	s2,s3,912 <printint+0x80>
}
 926:	70e2                	ld	ra,56(sp)
 928:	7442                	ld	s0,48(sp)
 92a:	74a2                	ld	s1,40(sp)
 92c:	7902                	ld	s2,32(sp)
 92e:	69e2                	ld	s3,24(sp)
 930:	6121                	addi	sp,sp,64
 932:	8082                	ret
    x = -xx;
 934:	40b005bb          	negw	a1,a1
    neg = 1;
 938:	4885                	li	a7,1
    x = -xx;
 93a:	bf8d                	j	8ac <printint+0x1a>

000000000000093c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 93c:	7119                	addi	sp,sp,-128
 93e:	fc86                	sd	ra,120(sp)
 940:	f8a2                	sd	s0,112(sp)
 942:	f4a6                	sd	s1,104(sp)
 944:	f0ca                	sd	s2,96(sp)
 946:	ecce                	sd	s3,88(sp)
 948:	e8d2                	sd	s4,80(sp)
 94a:	e4d6                	sd	s5,72(sp)
 94c:	e0da                	sd	s6,64(sp)
 94e:	fc5e                	sd	s7,56(sp)
 950:	f862                	sd	s8,48(sp)
 952:	f466                	sd	s9,40(sp)
 954:	f06a                	sd	s10,32(sp)
 956:	ec6e                	sd	s11,24(sp)
 958:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 95a:	0005c903          	lbu	s2,0(a1)
 95e:	18090f63          	beqz	s2,afc <vprintf+0x1c0>
 962:	8aaa                	mv	s5,a0
 964:	8b32                	mv	s6,a2
 966:	00158493          	addi	s1,a1,1
  state = 0;
 96a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 96c:	02500a13          	li	s4,37
      if(c == 'd'){
 970:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 974:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 978:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 97c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 980:	00000b97          	auipc	s7,0x0
 984:	718b8b93          	addi	s7,s7,1816 # 1098 <digits>
 988:	a839                	j	9a6 <vprintf+0x6a>
        putc(fd, c);
 98a:	85ca                	mv	a1,s2
 98c:	8556                	mv	a0,s5
 98e:	00000097          	auipc	ra,0x0
 992:	ee2080e7          	jalr	-286(ra) # 870 <putc>
 996:	a019                	j	99c <vprintf+0x60>
    } else if(state == '%'){
 998:	01498f63          	beq	s3,s4,9b6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 99c:	0485                	addi	s1,s1,1
 99e:	fff4c903          	lbu	s2,-1(s1)
 9a2:	14090d63          	beqz	s2,afc <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 9a6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 9aa:	fe0997e3          	bnez	s3,998 <vprintf+0x5c>
      if(c == '%'){
 9ae:	fd479ee3          	bne	a5,s4,98a <vprintf+0x4e>
        state = '%';
 9b2:	89be                	mv	s3,a5
 9b4:	b7e5                	j	99c <vprintf+0x60>
      if(c == 'd'){
 9b6:	05878063          	beq	a5,s8,9f6 <vprintf+0xba>
      } else if(c == 'l') {
 9ba:	05978c63          	beq	a5,s9,a12 <vprintf+0xd6>
      } else if(c == 'x') {
 9be:	07a78863          	beq	a5,s10,a2e <vprintf+0xf2>
      } else if(c == 'p') {
 9c2:	09b78463          	beq	a5,s11,a4a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 9c6:	07300713          	li	a4,115
 9ca:	0ce78663          	beq	a5,a4,a96 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 9ce:	06300713          	li	a4,99
 9d2:	0ee78e63          	beq	a5,a4,ace <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 9d6:	11478863          	beq	a5,s4,ae6 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 9da:	85d2                	mv	a1,s4
 9dc:	8556                	mv	a0,s5
 9de:	00000097          	auipc	ra,0x0
 9e2:	e92080e7          	jalr	-366(ra) # 870 <putc>
        putc(fd, c);
 9e6:	85ca                	mv	a1,s2
 9e8:	8556                	mv	a0,s5
 9ea:	00000097          	auipc	ra,0x0
 9ee:	e86080e7          	jalr	-378(ra) # 870 <putc>
      }
      state = 0;
 9f2:	4981                	li	s3,0
 9f4:	b765                	j	99c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 9f6:	008b0913          	addi	s2,s6,8
 9fa:	4685                	li	a3,1
 9fc:	4629                	li	a2,10
 9fe:	000b2583          	lw	a1,0(s6)
 a02:	8556                	mv	a0,s5
 a04:	00000097          	auipc	ra,0x0
 a08:	e8e080e7          	jalr	-370(ra) # 892 <printint>
 a0c:	8b4a                	mv	s6,s2
      state = 0;
 a0e:	4981                	li	s3,0
 a10:	b771                	j	99c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a12:	008b0913          	addi	s2,s6,8
 a16:	4681                	li	a3,0
 a18:	4629                	li	a2,10
 a1a:	000b2583          	lw	a1,0(s6)
 a1e:	8556                	mv	a0,s5
 a20:	00000097          	auipc	ra,0x0
 a24:	e72080e7          	jalr	-398(ra) # 892 <printint>
 a28:	8b4a                	mv	s6,s2
      state = 0;
 a2a:	4981                	li	s3,0
 a2c:	bf85                	j	99c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a2e:	008b0913          	addi	s2,s6,8
 a32:	4681                	li	a3,0
 a34:	4641                	li	a2,16
 a36:	000b2583          	lw	a1,0(s6)
 a3a:	8556                	mv	a0,s5
 a3c:	00000097          	auipc	ra,0x0
 a40:	e56080e7          	jalr	-426(ra) # 892 <printint>
 a44:	8b4a                	mv	s6,s2
      state = 0;
 a46:	4981                	li	s3,0
 a48:	bf91                	j	99c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a4a:	008b0793          	addi	a5,s6,8
 a4e:	f8f43423          	sd	a5,-120(s0)
 a52:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a56:	03000593          	li	a1,48
 a5a:	8556                	mv	a0,s5
 a5c:	00000097          	auipc	ra,0x0
 a60:	e14080e7          	jalr	-492(ra) # 870 <putc>
  putc(fd, 'x');
 a64:	85ea                	mv	a1,s10
 a66:	8556                	mv	a0,s5
 a68:	00000097          	auipc	ra,0x0
 a6c:	e08080e7          	jalr	-504(ra) # 870 <putc>
 a70:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a72:	03c9d793          	srli	a5,s3,0x3c
 a76:	97de                	add	a5,a5,s7
 a78:	0007c583          	lbu	a1,0(a5)
 a7c:	8556                	mv	a0,s5
 a7e:	00000097          	auipc	ra,0x0
 a82:	df2080e7          	jalr	-526(ra) # 870 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a86:	0992                	slli	s3,s3,0x4
 a88:	397d                	addiw	s2,s2,-1
 a8a:	fe0914e3          	bnez	s2,a72 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 a8e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a92:	4981                	li	s3,0
 a94:	b721                	j	99c <vprintf+0x60>
        s = va_arg(ap, char*);
 a96:	008b0993          	addi	s3,s6,8
 a9a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 a9e:	02090163          	beqz	s2,ac0 <vprintf+0x184>
        while(*s != 0){
 aa2:	00094583          	lbu	a1,0(s2)
 aa6:	c9a1                	beqz	a1,af6 <vprintf+0x1ba>
          putc(fd, *s);
 aa8:	8556                	mv	a0,s5
 aaa:	00000097          	auipc	ra,0x0
 aae:	dc6080e7          	jalr	-570(ra) # 870 <putc>
          s++;
 ab2:	0905                	addi	s2,s2,1
        while(*s != 0){
 ab4:	00094583          	lbu	a1,0(s2)
 ab8:	f9e5                	bnez	a1,aa8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 aba:	8b4e                	mv	s6,s3
      state = 0;
 abc:	4981                	li	s3,0
 abe:	bdf9                	j	99c <vprintf+0x60>
          s = "(null)";
 ac0:	00000917          	auipc	s2,0x0
 ac4:	5d090913          	addi	s2,s2,1488 # 1090 <malloc+0x48a>
        while(*s != 0){
 ac8:	02800593          	li	a1,40
 acc:	bff1                	j	aa8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 ace:	008b0913          	addi	s2,s6,8
 ad2:	000b4583          	lbu	a1,0(s6)
 ad6:	8556                	mv	a0,s5
 ad8:	00000097          	auipc	ra,0x0
 adc:	d98080e7          	jalr	-616(ra) # 870 <putc>
 ae0:	8b4a                	mv	s6,s2
      state = 0;
 ae2:	4981                	li	s3,0
 ae4:	bd65                	j	99c <vprintf+0x60>
        putc(fd, c);
 ae6:	85d2                	mv	a1,s4
 ae8:	8556                	mv	a0,s5
 aea:	00000097          	auipc	ra,0x0
 aee:	d86080e7          	jalr	-634(ra) # 870 <putc>
      state = 0;
 af2:	4981                	li	s3,0
 af4:	b565                	j	99c <vprintf+0x60>
        s = va_arg(ap, char*);
 af6:	8b4e                	mv	s6,s3
      state = 0;
 af8:	4981                	li	s3,0
 afa:	b54d                	j	99c <vprintf+0x60>
    }
  }
}
 afc:	70e6                	ld	ra,120(sp)
 afe:	7446                	ld	s0,112(sp)
 b00:	74a6                	ld	s1,104(sp)
 b02:	7906                	ld	s2,96(sp)
 b04:	69e6                	ld	s3,88(sp)
 b06:	6a46                	ld	s4,80(sp)
 b08:	6aa6                	ld	s5,72(sp)
 b0a:	6b06                	ld	s6,64(sp)
 b0c:	7be2                	ld	s7,56(sp)
 b0e:	7c42                	ld	s8,48(sp)
 b10:	7ca2                	ld	s9,40(sp)
 b12:	7d02                	ld	s10,32(sp)
 b14:	6de2                	ld	s11,24(sp)
 b16:	6109                	addi	sp,sp,128
 b18:	8082                	ret

0000000000000b1a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 b1a:	715d                	addi	sp,sp,-80
 b1c:	ec06                	sd	ra,24(sp)
 b1e:	e822                	sd	s0,16(sp)
 b20:	1000                	addi	s0,sp,32
 b22:	e010                	sd	a2,0(s0)
 b24:	e414                	sd	a3,8(s0)
 b26:	e818                	sd	a4,16(s0)
 b28:	ec1c                	sd	a5,24(s0)
 b2a:	03043023          	sd	a6,32(s0)
 b2e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 b32:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 b36:	8622                	mv	a2,s0
 b38:	00000097          	auipc	ra,0x0
 b3c:	e04080e7          	jalr	-508(ra) # 93c <vprintf>
}
 b40:	60e2                	ld	ra,24(sp)
 b42:	6442                	ld	s0,16(sp)
 b44:	6161                	addi	sp,sp,80
 b46:	8082                	ret

0000000000000b48 <printf>:

void
printf(const char *fmt, ...)
{
 b48:	711d                	addi	sp,sp,-96
 b4a:	ec06                	sd	ra,24(sp)
 b4c:	e822                	sd	s0,16(sp)
 b4e:	1000                	addi	s0,sp,32
 b50:	e40c                	sd	a1,8(s0)
 b52:	e810                	sd	a2,16(s0)
 b54:	ec14                	sd	a3,24(s0)
 b56:	f018                	sd	a4,32(s0)
 b58:	f41c                	sd	a5,40(s0)
 b5a:	03043823          	sd	a6,48(s0)
 b5e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b62:	00840613          	addi	a2,s0,8
 b66:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b6a:	85aa                	mv	a1,a0
 b6c:	4505                	li	a0,1
 b6e:	00000097          	auipc	ra,0x0
 b72:	dce080e7          	jalr	-562(ra) # 93c <vprintf>
}
 b76:	60e2                	ld	ra,24(sp)
 b78:	6442                	ld	s0,16(sp)
 b7a:	6125                	addi	sp,sp,96
 b7c:	8082                	ret

0000000000000b7e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b7e:	1141                	addi	sp,sp,-16
 b80:	e422                	sd	s0,8(sp)
 b82:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b84:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b88:	00000797          	auipc	a5,0x0
 b8c:	5287b783          	ld	a5,1320(a5) # 10b0 <freep>
 b90:	a805                	j	bc0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b92:	4618                	lw	a4,8(a2)
 b94:	9db9                	addw	a1,a1,a4
 b96:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b9a:	6398                	ld	a4,0(a5)
 b9c:	6318                	ld	a4,0(a4)
 b9e:	fee53823          	sd	a4,-16(a0)
 ba2:	a091                	j	be6 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 ba4:	ff852703          	lw	a4,-8(a0)
 ba8:	9e39                	addw	a2,a2,a4
 baa:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 bac:	ff053703          	ld	a4,-16(a0)
 bb0:	e398                	sd	a4,0(a5)
 bb2:	a099                	j	bf8 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bb4:	6398                	ld	a4,0(a5)
 bb6:	00e7e463          	bltu	a5,a4,bbe <free+0x40>
 bba:	00e6ea63          	bltu	a3,a4,bce <free+0x50>
{
 bbe:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 bc0:	fed7fae3          	bgeu	a5,a3,bb4 <free+0x36>
 bc4:	6398                	ld	a4,0(a5)
 bc6:	00e6e463          	bltu	a3,a4,bce <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 bca:	fee7eae3          	bltu	a5,a4,bbe <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 bce:	ff852583          	lw	a1,-8(a0)
 bd2:	6390                	ld	a2,0(a5)
 bd4:	02059813          	slli	a6,a1,0x20
 bd8:	01c85713          	srli	a4,a6,0x1c
 bdc:	9736                	add	a4,a4,a3
 bde:	fae60ae3          	beq	a2,a4,b92 <free+0x14>
    bp->s.ptr = p->s.ptr;
 be2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 be6:	4790                	lw	a2,8(a5)
 be8:	02061593          	slli	a1,a2,0x20
 bec:	01c5d713          	srli	a4,a1,0x1c
 bf0:	973e                	add	a4,a4,a5
 bf2:	fae689e3          	beq	a3,a4,ba4 <free+0x26>
  } else
    p->s.ptr = bp;
 bf6:	e394                	sd	a3,0(a5)
  freep = p;
 bf8:	00000717          	auipc	a4,0x0
 bfc:	4af73c23          	sd	a5,1208(a4) # 10b0 <freep>
}
 c00:	6422                	ld	s0,8(sp)
 c02:	0141                	addi	sp,sp,16
 c04:	8082                	ret

0000000000000c06 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c06:	7139                	addi	sp,sp,-64
 c08:	fc06                	sd	ra,56(sp)
 c0a:	f822                	sd	s0,48(sp)
 c0c:	f426                	sd	s1,40(sp)
 c0e:	f04a                	sd	s2,32(sp)
 c10:	ec4e                	sd	s3,24(sp)
 c12:	e852                	sd	s4,16(sp)
 c14:	e456                	sd	s5,8(sp)
 c16:	e05a                	sd	s6,0(sp)
 c18:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c1a:	02051493          	slli	s1,a0,0x20
 c1e:	9081                	srli	s1,s1,0x20
 c20:	04bd                	addi	s1,s1,15
 c22:	8091                	srli	s1,s1,0x4
 c24:	0014899b          	addiw	s3,s1,1
 c28:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 c2a:	00000517          	auipc	a0,0x0
 c2e:	48653503          	ld	a0,1158(a0) # 10b0 <freep>
 c32:	c515                	beqz	a0,c5e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c34:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c36:	4798                	lw	a4,8(a5)
 c38:	02977f63          	bgeu	a4,s1,c76 <malloc+0x70>
 c3c:	8a4e                	mv	s4,s3
 c3e:	0009871b          	sext.w	a4,s3
 c42:	6685                	lui	a3,0x1
 c44:	00d77363          	bgeu	a4,a3,c4a <malloc+0x44>
 c48:	6a05                	lui	s4,0x1
 c4a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c4e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c52:	00000917          	auipc	s2,0x0
 c56:	45e90913          	addi	s2,s2,1118 # 10b0 <freep>
  if(p == (char*)-1)
 c5a:	5afd                	li	s5,-1
 c5c:	a895                	j	cd0 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 c5e:	00000797          	auipc	a5,0x0
 c62:	45a78793          	addi	a5,a5,1114 # 10b8 <base>
 c66:	00000717          	auipc	a4,0x0
 c6a:	44f73523          	sd	a5,1098(a4) # 10b0 <freep>
 c6e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c70:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c74:	b7e1                	j	c3c <malloc+0x36>
      if(p->s.size == nunits)
 c76:	02e48c63          	beq	s1,a4,cae <malloc+0xa8>
        p->s.size -= nunits;
 c7a:	4137073b          	subw	a4,a4,s3
 c7e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c80:	02071693          	slli	a3,a4,0x20
 c84:	01c6d713          	srli	a4,a3,0x1c
 c88:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c8a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c8e:	00000717          	auipc	a4,0x0
 c92:	42a73123          	sd	a0,1058(a4) # 10b0 <freep>
      return (void*)(p + 1);
 c96:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c9a:	70e2                	ld	ra,56(sp)
 c9c:	7442                	ld	s0,48(sp)
 c9e:	74a2                	ld	s1,40(sp)
 ca0:	7902                	ld	s2,32(sp)
 ca2:	69e2                	ld	s3,24(sp)
 ca4:	6a42                	ld	s4,16(sp)
 ca6:	6aa2                	ld	s5,8(sp)
 ca8:	6b02                	ld	s6,0(sp)
 caa:	6121                	addi	sp,sp,64
 cac:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 cae:	6398                	ld	a4,0(a5)
 cb0:	e118                	sd	a4,0(a0)
 cb2:	bff1                	j	c8e <malloc+0x88>
  hp->s.size = nu;
 cb4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 cb8:	0541                	addi	a0,a0,16
 cba:	00000097          	auipc	ra,0x0
 cbe:	ec4080e7          	jalr	-316(ra) # b7e <free>
  return freep;
 cc2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 cc6:	d971                	beqz	a0,c9a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cc8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cca:	4798                	lw	a4,8(a5)
 ccc:	fa9775e3          	bgeu	a4,s1,c76 <malloc+0x70>
    if(p == freep)
 cd0:	00093703          	ld	a4,0(s2)
 cd4:	853e                	mv	a0,a5
 cd6:	fef719e3          	bne	a4,a5,cc8 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 cda:	8552                	mv	a0,s4
 cdc:	00000097          	auipc	ra,0x0
 ce0:	b7c080e7          	jalr	-1156(ra) # 858 <sbrk>
  if(p == (char*)-1)
 ce4:	fd5518e3          	bne	a0,s5,cb4 <malloc+0xae>
        return 0;
 ce8:	4501                	li	a0,0
 cea:	bf45                	j	c9a <malloc+0x94>
