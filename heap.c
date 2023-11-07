/*
 * This is a C implementation of malloc( ) and free( ), based on the buddy
 * memory allocation algorithm.
 *
 * Rename this file to heap.c before adding your comments
 *
 * Compile: gcc heap.c driver_cpg.c
 * Execute: ./a.out
 *
 */
#include <assert.h>
#include <stdio.h> // printf
/*
 * The following global variables are used to simulate memory allocation
 * Cortex-M's SRAM space.
 */
// Heap
char array[0x8000];          // simulate SRAM: 0x2000.0000 - 0x2000.7FFF
int heap_top = 0x20001000;   // the top of heap space
int heap_bot = 0x20004FE0;   // the address of the last 32B in heap
short max_size = 0x00004000; // maximum allocation: 16KB = 2^14
short min_size = 0x00000020; // minimum allocation: 32B = 2^5

// Memory Control Block: 2^10B = 1KB space
int mcb_top = 0x20006800;    // the top of MCB
int mcb_bot = 0x20006BFE;    // the address of the last MCB entry
int mcb_ent_sz = 0x00000002; // 2B per MCB entry
int mcb_total = 512;         // # MCB entries: 2^9 = 512 entries

/*
 * Convert a Cortex SRAM address to the corresponding array index.
 * @param  sram_addr address of Cortex-M's SRAM space starting at 0x20000000.
 * @return array index.
 */
int m2a(int sram_addr) {
  int index = sram_addr - 0x20000000; // maps sram_addr to an array index by subtracting by the base SRAM address (0x20000000)
  return index; // returns the mapped address
}

/*
 * Reverse an array index back to the corresponding Cortex SRAM address.
 * @param  array index.
 * @return the corresponding Cortex-M's SRAM address in an integer.
 */
int a2m(int array_index) {
  return array_index + 0x20000000; // converts an array index into a memory address and returns it
}

/*
 * In case if you want to print out, all array elements that correspond
 * to MCB: 0x2006800 - 0x20006C00.
 */
void printArray() {
  printf("memory ............................\n");
  // TODO(student): add comment to each of the following line of code
  for (int i = 0; i < 0x8000; i += 4) { // iterates through the MCB (each MCB entry is 16 bits)
    if (a2m(i) >= 0x20006800) {
      printf("%x = %x(%d)\n", a2m(i), *(short *)&array[i], *(short *)&array[i]);
    }
    if (a2m(i + 2) >= 0x20006800) {
      printf("%x = %x(%d)\n", a2m(i + 2), *(short *)&array[i + 2],
            *(short *)&array[i + 2]);
    }
  }
}

/*
 * Print out the memory managed by mcb, showing used segments
 * and the value of the mcb's
 */
void printMemory() {
  printf("memory map ............................\n");
  int segment_size = 512;
  char memory[0x8000];
  for (int i = 0; i < 0x8000; i++) {
    memory[i] = '.';
  }
  // for each mcb, mark corresponding memory as used
  for (int mcb_addr = mcb_top; mcb_addr <= mcb_bot; mcb_addr += 2) {
    if ((*(short *)&array[m2a(mcb_addr)] & 0x01) != 0) {
      int heap_val = *(short *)&array[m2a(mcb_addr)];
      heap_val = (heap_val / 2) * 2;
      int heap_start = heap_top + (mcb_addr - mcb_top) * 16;
      int heap_end = heap_start + heap_val;
      for (int x = heap_start; x < heap_end; x += segment_size) {
        memory[m2a(x)] = 'X';
      }
    }
  }
  printf("mcb\t\tmcb Address\tHeap Address\tUsed?\tmcb Value\n");
  for (int addr = heap_top; addr < heap_bot; addr += segment_size) {
    int mcb_addr = mcb_top + (addr - heap_top) / 16;
    int mcb_index = (mcb_addr - mcb_top) / mcb_ent_sz;
    int heap_value = *(short *)&array[m2a(mcb_addr)];
    printf("mcb[%3d]\t%x\t%x\t%3c\t%4d\n", mcb_index, mcb_addr, addr,
           memory[m2a(addr)], heap_value);
  }
}

/*
 * _ralloc is _kalloc's helper function that is recursively called to
 * allocate a requested space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  size  the size of a requested memory space
 * @param  left_mcb_addr  the address of the left boundary of MCB entries to
 examine
 * @param  right_mcb_addr the address of the right boundary of MCB entries to
 examine
 * @return the address of Cortex-M's SRAM space. While the computation is
 *         made in integers, cast it to (void *). The gcc compiler gives
 *         a warning sign:
                cast to 'void *' from smaller integer type 'int'
 *         Simply ignore it.
 */
void *_ralloc(int size, int left_mcb_addr, int right_mcb_addr) {
  // initial parameter computation
  //  DOUBLE CHECK
  int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz; //calculates current MCB size
  int half_mcb_addr_space = entire_mcb_addr_space / 2; // divides MCB in half for buddy allocation
  int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space; // calculates the midpoint for the current MCB addr space (in hex)
  int heap_addr = 0; // initialize heap address to zero
  int act_entire_heap_size = entire_mcb_addr_space * 16; // converts entire heap size into hex (actual size)
  int act_half_heap_size = half_mcb_addr_space * 16; // converts half heap size into hex (actual size0)

  // base case
  //  DOUBLE CHECK
  if (size <= act_half_heap_size) { // if the size is in the first half of the MCB
    void *heap_addr =
        _ralloc(size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz); // try to allocate memory in first half of the heap
    if (heap_addr == 0) { // if allocation fails
      return _ralloc(size, midpoint_mcb_addr, right_mcb_addr); // try to allocate memory in the second half of the heap
    }
    if ((array[m2a(midpoint_mcb_addr)] & 0x01) == 0) { // if midpoint is unallocated memory
      *(short *)&array[m2a(midpoint_mcb_addr)] = act_half_heap_size; // update MCB with actual size
    }
    return heap_addr; // return allocated address
  }
  // (size > act_half_heap_size)
  if ((array[m2a(left_mcb_addr)] & 0x01) != 0) { // if left address is in use
    return 0; // indicates left address is in use
  }
  if (*(short *)&array[m2a(left_mcb_addr)] < act_entire_heap_size) { // if left side of the heap has less memory than requested
    return 0; // MCB in left address has less memory than requested
  }
  *(short *)&array[m2a(left_mcb_addr)] = act_entire_heap_size | 0x01; // indicate that left address is in use
  return (void *)(heap_top + (left_mcb_addr - mcb_top) * 16); // return pointer to allocated memory
}

/*
 * _rfree is _kfree's helper function that is recursively called to
 * deallocate a space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  mcb_addr that corresponds to a SRAM space to deallocate
 * @return the same as the mcb_addr argument in success, otherwise 0.
 */
int _rfree(int mcb_addr) {
  //  DOUBLE CHECK
  short mcb_contents = *(short *)&array[m2a(mcb_addr)]; // get contents of MCB entry at specified address
  int mcb_index = mcb_addr - mcb_top; // calculate the index of MCB entry
  short mcb_disp = (mcb_contents /= 16);
  short my_size = (mcb_contents *= 16);

  // mcb_addr's used bit was cleared
  *(short *)&array[m2a(mcb_addr)] = mcb_contents;

  //  DOUBLE CHECK
  if ((mcb_index / mcb_disp) % 2 == 0) { // if MCB index is even (right child)
    if (mcb_addr + mcb_disp >= mcb_bot) { // if the buddy is beyond MCB bottom boundary
      return 0; // my buddy is beyond mcb_bot!
    }
    short mcb_buddy = *(short *)&array[m2a(mcb_addr + mcb_disp)]; // get MCB entry's buddy's content
    if ((mcb_buddy & 0x0001) == 0) { // if buddy's memory is available
      mcb_buddy = (mcb_buddy / 32) * 32; // calculate buddy size
      if (mcb_buddy == my_size) { // if buddy can merge with MCB entry
        *(short *)&array[m2a(mcb_addr + mcb_disp)] = 0; // clear buddy's used bit
        my_size *= 2; // add buddy's size to MCB entry's size
        *(short *)&array[m2a(mcb_addr)] = my_size; // update MCB entry's size
        return _rfree(mcb_addr); // deallocate merged space
      }
    }
  } else { // if MCB index is odd (left child)
    if (mcb_addr - mcb_disp < mcb_top) { // if buddy is beyond MCB top boundary
      return 0; // my buddy is below mcb_top!
    }
    short mcb_buddy = *(short *)&array[m2a(mcb_addr - mcb_disp)]; // get MCB entry's buddy's content 
    if ((mcb_buddy & 0x0001) == 0) { // if buddy's memory is available
      mcb_buddy = (mcb_buddy / 32) * 32; // calculate buddy size
      if (mcb_buddy == my_size) { // if buddy can merge with MCB entry
        *(short *)&array[m2a(mcb_addr)] = 0; // clear buddy's used bit
        my_size *= 2; // add buddy's size to MCB entry's size
        *(short *)&array[m2a(mcb_addr - mcb_disp)] = my_size; // update MCB entry's size
        return _rfree(mcb_addr - mcb_disp); // deallocate merged space
      }
    }
  }
  return mcb_addr; // return original address if merges or buddy checks fail
}

/*
 * Initializes MCB entries. In step 2's assembly coding, this routine must
 * be called from Reset_Handler in startup_TM4C129.s before you invoke
 * driver.c's main( ).
 */
void _kinit() {
  //  DOUBLE CHECK
  for (int i = 0x20001000; i < 0x20005000; i++) { // traverse heap space from 0x20001000 to 0x20004FFF
    array[m2a(i)] = 0; // initialize each memory address to 0 to indicate unallocated memory
  }

  *(short *)&array[m2a(mcb_top)] = max_size; // initialize first MCB entry with the maximum allocation size
  for (int i = 0x20006802; i < 0x20006C00; i += 2) { // traverse MCB entries from 0x20006802 to 0x20006BFE
    array[m2a(i)] = 0; // initialize the current MCB to 0 to indicate unallocated memory
    array[m2a(i + 1)] = 0; // initialize the contiguous MCB to 0 to indicate unallocated memory
  }
}

/*
 * Step 2 should call _kalloc from SVC_Handler.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_kalloc(int size) { return _ralloc(size, mcb_top, mcb_bot); }

/*
 * Step 2 should call _kfree from SVC_Handler.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_kfree(void *ptr) {
  // DOUBLE CHECK
  int addr = (int)ptr; // convert pointer into int memory address

  if (addr < heap_top || addr > heap_bot) { // if address is outside of heap range
    return NULL; // cannot dellocate
  }
  int mcb_addr = mcb_top + (addr - heap_top) / 16; // calculate corresponding MCB entry from memory address

  if (_rfree(mcb_addr) == 0) { // deallocate the memory at corresponding MCB entry
    return NULL; // deallocation was unsuccessful
  }
  return ptr; // return pointer as deallocated address
}

/*
 * _malloc should be implemented in stdlib.s in step 2.
 * _kalloc must be invoked through SVC in step 2.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_malloc(int size) {
  assert(size >= min_size);
  static int init = 0;
  if (init == 0) {
    init = 1;
    _kinit();
  }
  return _kalloc(size);
}

/*
 * _free should be implemented in stdlib.s in step 2.
 * _kfree must be invoked through SVC in step 2.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_free(void *ptr) { return _kfree(ptr); }
