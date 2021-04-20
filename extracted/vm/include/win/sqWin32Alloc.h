#ifndef __SQ_WIN32_ALLOC_H
#define __SQ_WIN32_ALLOC_H

#ifndef NO_VIRTUAL_MEMORY
#include "sqMemoryAccess.h"

/*
   Limit the default size for virtual memory to 512MB to avoid nasty
   spurious problems when large dynamic libraries are loaded later.
   Applications needing more virtual memory can increase the size by
   defining it appropriately - here we try to cater for the common
   case by using a "reasonable" size that will leave enough space for
   other libraries. 
*/
#ifndef MAX_VIRTUAL_MEMORY
#define MAX_VIRTUAL_MEMORY 512*1024*1024
#endif

/* Memory initialize-release */
#undef sqAllocateMemory
#undef sqMemoryExtraBytesLeft

extern usqInt sqAllocateMemory(usqInt minHeapSize, usqInt desiredHeapSize, usqInt baseAddress);
extern void* allocateJITMemory(usqInt desiredSize, usqInt desiredPosition);

#define allocateMemoryMinimumImageFileHeaderSizeBaseAddress(heapSize, minimumMemory, fileStream, headerSize, baseAddress) \
sqAllocateMemory(minimumMemory, heapSize, baseAddress)

int sqMemoryExtraBytesLeft(int includingSwap);

#endif /* NO_VIRTUAL_MEMORY */
#endif /* __SQ_WIN32_ALLOC_H */
