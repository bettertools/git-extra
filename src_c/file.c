#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>

#include "err_t.h"
#include "mem.h"
#include "file.h"

err_t read_all_malloc(struct read_data *data, int fd, size_t initial_size)
{
  size_t capacity = initial_size;
  char *buffer = need_malloc(initial_size);

  size_t total_read = 0;
  for (;;) {
    {
      int result = read(fd, buffer + total_read, capacity - total_read);
      if (result <= 0) {
        if (result < 0) {
          free(buffer);
          return err_fail;
        }
        // make sure it is null-terminated
        if (total_read == capacity) {
          buffer = need_increase_malloc_buffer(buffer, capacity + 1, total_read);
        }
        buffer[total_read] = '\0';
        data->ptr = buffer;
        data->length = total_read;
        return err_pass;
      }
      total_read += result;
      if (total_read >= capacity)
        buffer = need_increase_malloc_buffer(buffer, capacity * 2, total_read);
    }
  }
}

