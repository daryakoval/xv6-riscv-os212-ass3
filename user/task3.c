#include "kernel/types.h"
#include "user.h"

#define PGSIZE 4096

//Test1 - Allocating 18 pages, some of them on disk, some in memory.
// then trying to access all arrays that was allocated.
void test1(){
    fprintf(2,"-------------test1 start ---------------------\n");
    int i;
    int j;
    int pid = fork();
    if(!pid){
        char* malloc_array[18];
        for(i = 0; i<18; i++){
           malloc_array[i] = sbrk(PGSIZE); 
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
        }
        fprintf(2,"Allocated 18 pages, some of them on disk\n");
        fprintf(2,"Lets try to access all pages:\n");
        for(i = 0; i<18; i++){
            for(j = 0; j<PGSIZE; j++)
                malloc_array[i][j] = 'x'; 
            fprintf(2,"Filled array num=%d with chars\n", i);
        }
        exit(0);
    }else{
        int status;
        pid = wait(&status);
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
    }
        fprintf(2,"-------------test1 finished ---------------------\n");

}

//Test2 testing alloc and dealloc (testing that delloa works fine, 
//and we dont recieve panic: more that 32 pages for process)
void test2(){
    fprintf(2,"-------------test2 start ---------------------\n");
    char* i;
    i = sbrk(20*PGSIZE);
    fprintf(2,"allocated memory = %p\n", i);
    i = sbrk(-20*PGSIZE);
    fprintf(2,"deallocated memory = %p\n", i);
    i = sbrk(20*PGSIZE);
    fprintf(2,"allocated memory = %p\n", i);
    i = sbrk(-20*PGSIZE);
    fprintf(2,"deallocated memory = %p\n", i);
    i = sbrk(20*PGSIZE);
    fprintf(2,"allocated memory = %p\n", i);
    i = sbrk(-20*PGSIZE);
    fprintf(2,"deallocated memory = %p\n", i);

    fprintf(2,"-------------test2 finished ---------------------\n");


}

//Test3 - parent allocates a lot of memory, forks, 
//and child can access all his data
void test3(){
    fprintf(2,"-------------test3 start ---------------------\n");
    uint64 i;
    char* arr = malloc(PGSIZE*17);
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
        arr[i] = 'a';
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
    }
    int pid = fork();
    if(!pid){
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
        }
        exit(i);
    }else{
        int status;
        pid = wait(&status);
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
        sbrk(-17*PGSIZE);
    }
        fprintf(2,"-------------test3 finished ---------------------\n");

}


// this test does a lot of calculations with a malloced array
// each calculation need the previous ones
// need to read and write to the array
void test4(){
    fprintf(2,"-------------test4 start ---------------------\n");
    int *arr = (int *)malloc(2000 * sizeof(int));
    int i, j;
    uint counter = 0;

    for(i = 0; i < 2000; i++){
        *(arr + i) = i;
    }
    for(i = 0; i < 2000; i++){
        for(j = 0; j <= i; j ++){
            counter += *(arr + j);
        }
        printf("%d: counter is %d\n", i, counter);
    }
    printf("final counter is %d\n",  counter);
    fprintf(2,"-------------test4 finished ---------------------\n");
} 

void aprint(int num){
    printf("%d a!\n", num);
}

void bprint(int num){
    printf("%d b!\n", num);
}

void cprint(int num){
    printf("%d c!\n", num);
}

// print a lot of things to screen - call 3 different functions 
// the process will need to swap pages
void test5(){
        fprintf(2,"-------------test5 start ---------------------\n");
    for(int i = 0; i < 1000; i ++){
        aprint(i);
        bprint(i);
        cprint(i);
    }
        fprintf(2,"-------------test5 finished ---------------------\n");
}


int main(int argc, char** argv){
    test1();
    test2();
    test3();
    test4();
    test5();
    exit(0);
}