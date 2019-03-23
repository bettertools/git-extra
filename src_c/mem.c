#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>

#include "err_t.h"
#include "mem.h"

void *increase_malloc_buffer(void *buffer, size_t new_capacity, size_t save_size)
{
  void *new_buffer = realloc(buffer, new_capacity);
  if (!new_buffer) {
    new_buffer = malloc(new_capacity);
    if (!new_buffer)
      return NULL;
    memcpy(new_buffer, buffer, save_size);
    free(buffer);
  }
  return new_buffer;
}
