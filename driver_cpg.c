/*
 * This is a C program that should be used to test your heap.c toward your 
 * Part 1 report.
 *
 * printf( ): included
 * 
 * You should implement _malloc( ) and _free() in heap.c
 * You should compile your code as gcc driver_cpg.c heap.c 
 * Compile in Linux server

Expected output
*************************
stringA=
stringB=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabc
array[26624]=16384
mem1 = 20001000
mem2 = 20001400
mem3 = 20003000
mem4 = 20002000
mem5 = 20001800
mem6 = 20001c00
mem7 = 20001a00
mem8 = 20001000

*************************
 */

#include <string.h> // bzero, strncpy
#include <stdlib.h>  // malloc, free
#include <stdio.h>   // printf

extern void *_malloc( int size );  // you need to implement it in heap.c
extern void *_free( void *ptr );   // you need to implement it in heap.c

int main( ) {
  char stringA[40] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabc\0";
  char stringB[40];
  
  bzero( stringB, 40 );
  strncpy( stringB, stringA, 40 );  // Provide a snapshot of stringA and stringB memory view after this instruction
  bzero( stringA, 40 );  // Provide a snapshot of stringA and stringB memory view after this instructions
  printf( "stringA = %s\n", stringA );
  printf( "stringB = %s\n", stringB );
  
  void* mem1 = _malloc( 1024 );
  printf( "mem1 = %x\n", mem1 );

  void* mem2 = _malloc( 1024 );
  printf( "mem2 = %x\n", mem2 );

  void* mem3 = _malloc( 8192 );
  printf( "mem3 = %x\n", mem3 );
  
  void* mem4 = _malloc( 4096 );
  printf( "mem4 = %x\n", mem4 );
  
  void* mem5 = _malloc( 512 );
  printf( "mem5 = %x\n", mem5 );
  
  void* mem6 = _malloc( 1024 );
  printf( "mem6 = %x\n", mem6 );
  
  void* mem7 = _malloc( 512 );
  printf( "mem7 = %x\n", mem7 );

  _free( mem6 );
  _free( mem5 );
  _free( mem1 );
  _free( mem7 );
  _free( mem2 );
  
  void* mem8 = _malloc( 4096 );
  printf( "mem8 = %x\n", mem8 );
  
  _free( mem4 );
  _free( mem3 );
  _free( mem8 );
  
  return 0;
}
