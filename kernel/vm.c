#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "spinlock.h"
#include "proc.h"

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

void add_to_memory(uint64 a, char *mem, pagetable_t pagetable);

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc();
  memset(kpgtbl, 0, PGSIZE);

  // uart registers
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // map kernel stacks
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// Initialize the one kernel_pagetable
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    #ifndef NONE
    if(myproc()->pid > 2 && myproc()->pagetable == pagetable){
      struct proc *p = myproc();
      struct page_metadata *pg;
      for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
        if(pg->va == va){
          pg->state = 0;
          pg->va = 0;
          p->num_pages_in_psyc--;
          break;
        }
      }
      for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
        if(pg->va == va){
          pg->state = 0;
          pg->va = 0;
          p->num_pages_in_swapfile--;
          break;
        }
      }
    }
    #endif
    *pte = 0;
  }
}

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    #ifndef NONE
    //check if there is free space in memory
    //if no - swap_into_file
    //after this - find free page_metadata and fill it with new allocated page details
    if(myproc()->pid > 2){
      add_to_memory(a, mem, pagetable);
    }
    #endif
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if(!(*pte & PTE_V) && !(*pte & PTE_PG))
      panic("uvmcopy: page not present");
    #ifndef NONE
    //If page was swaped out to file, new proccess will have it in swapfile too
    if(myproc()->pid > 2 && *pte & PTE_PG){
      pte_t *npte = walk(new, i, 1);
      *npte = *pte;
      continue;
    }
    #endif
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}

int find_free_index_in_memory_array(){
  struct proc *p = myproc();
  struct page_metadata *pg;
  for(pg = p->pages_in_memory; pg < &p->pages_in_memory[MAX_PSYC_PAGES]; pg++){
    if(!pg->state){
      return (int)(pg - p->pages_in_memory);
    }
  }
  return -1;
}

int get_page_scfifo(){
  return 1;
}
// get page that will be swaped out (Task 2)
// Returns page index in pages_in_memory array, this page will be swapped out

int get_page_by_alg(){
  #ifdef SCFIFO
  return get_page_scfifo();
  #endif
  #ifdef NFUA
  //return
  #endif
  #ifndef LAPA
  //return
  #endif
  #ifdef NONE
  return 0; //will never got here
  #endif
}


//Chose page to remove from main memory (using one of task2 algorithms) 
//and swap this page into file
void swap_into_file(pagetable_t pagetable){
  struct proc *p = myproc();
  if(p->num_pages_in_psyc + p->num_pages_in_swapfile == MAX_TOTAL_PAGES){
    panic("more than 32 pages per proccess");
  }
  int page_index_to_swap = get_page_by_alg(); //Index1

  #ifdef YES
  printf("swap into: page index to swap out: %d\n", page_index_to_swap);
  #endif

  struct page_metadata *pg_to_swap = &p->pages_in_memory[page_index_to_swap];

  //find free space in swaped pages array,
  //add selected to swap out page to this array 
  //and write this page to swapfile.
  struct page_metadata *pg;
  for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
    if(!pg->state){
      pg->state = 1;
      pg->va = pg_to_swap->va;
      int offset = (pg - p->pages_in_swapfile)*PGSIZE;

      #ifdef YES
      printf("swap into: write to file: \n");
      #endif

      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
      uint64 pa = PTE2PA(*pte);

      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 

      p->num_pages_in_swapfile++;

      kfree((void*)pa); 

      //set pte flags:
      #ifdef YES
      printf("swap into: turn off pte bits\n");
      #endif

      *pte |= PTE_PG;     //paged out to secondary storage
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
                          // it should be marked in the process' page table entry that the page is not present.
                          //This is done by clearing the valid (PTE_V) flag. 

      pg_to_swap->state = 0;
      pg_to_swap->va = 0;
      p->num_pages_in_psyc--;
      
      #ifdef YES
      printf("finish swap into: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
      #endif
      sfence_vma();  // todo : sfence_vma() where todo it?
      break;
    }
  }

}

//Adding new page created by uvmalloc() to proccess pages
void add_to_memory(uint64 a, char *mem, pagetable_t pagetable){
  struct proc *p = myproc();
  //No free space in the psyc memory,
  //Chose page to remove from main memory (using one of task2 algorithms) 
  //and swap this page into file
  if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
    #ifdef YES
    printf("add to memory: too much pchyc pages: swap into file\n");
    #endif

    swap_into_file(pagetable);
    #ifdef YES
    printf("add to memory: finished page swap into\n");
    #endif

  }

  //Now we have free space in psyc memory (maybe we had free space before too):
  //just add all page information to pages_in_memory array:
  int free_index_memory_array = find_free_index_in_memory_array();
  struct page_metadata *pg = &p->pages_in_memory[free_index_memory_array];
  
  pg->state = 1;
  pg->va = a;

  p->num_pages_in_psyc++;

  #ifdef YES
  printf("add to file: turn on pte bits\n");
  #endif
  pte_t* pte = walk(pagetable, pg->va, 0);
  //set pte flags:
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
  *pte |= PTE_V;
  #ifdef YES
  printf("finish add to memory: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
  #endif
}

//Handle page fault - called from trap.c
int handle_pagefault(){
  struct proc *p = myproc();
  uint64 va = r_stval();
  
  pte_t* pte = walk(p->pagetable, va, 0);
  //If the page was swaped out, we should bring it back to memory
  if(*pte & PTE_PG){
    #ifdef YES
    printf("inside if pte: %p\n", *pte);
    #endif
    //If no place in memory - swap out page
    if(p->num_pages_in_psyc == MAX_PSYC_PAGES){
      swap_into_file(p->pagetable);
      #ifdef YES
      printf("handle_pagefault: finished page swap into\n");
      #endif
    }

    //Now we have free space in psyc memory (maybe we had free space before too):
    //bring page from swapFile and put it into physic memory
    uint64 va1 = PGROUNDDOWN(va);
    char *mem = kalloc();
    
    struct page_metadata *pg;
    for(pg = p->pages_in_swapfile; pg < &p->pages_in_swapfile[MAX_PSYC_PAGES]; pg++){
      if(pg->va == va1){
        pte_t* pte = walk(p->pagetable, va1, 0);
        int offset = (pg - p->pages_in_swapfile)*PGSIZE;

        //mappages(p->pagetable, va1, PGSIZE ,(uint64)mem, PTE_W | PTE_U);
        readFromSwapFile(p, mem, offset, PGSIZE);

        int free_index_memory_array = find_free_index_in_memory_array();
        
        struct page_metadata *free_memory_page = &p->pages_in_memory[free_index_memory_array];

        //fill free page in memory with current page
        free_memory_page->state = 1;
        free_memory_page->va = pg->va;

        //now this page in swapfile is free:
        p->num_pages_in_swapfile--;
        pg->state = 0;
        pg->va = 0;
        p->num_pages_in_psyc++;

        //set pte flags:
        #ifdef YES
        printf("handle_page: turn on pte bits\n");
        #endif
        //pte_t* pte = walk(p->pagetable, va1, 0); //maybe we have to go throw this 
        *pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress? 
        *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
        *pte |= PTE_V;
        #ifdef YES
        printf("finish handle_page: pages in swapfile: %d, pages in memory: %d\n", p->num_pages_in_swapfile, p->num_pages_in_psyc);
        #endif
        break;
      }
    }
    sfence_vma();
    #ifdef YES
    printf("finish handle_page\n");
    #endif
    return 3;
  }else{
    printf("segfault: pte: %p\n", *pte);
    return 0; //this is segfault
  }
}