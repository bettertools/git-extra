static inline void *need_malloc(size_t size)
{
  void *buffer = malloc(size);
  if (!buffer) {
    printf("Error: malloc(%llu) failed (e=%d)\n", (unsigned long long)size, errno);
    exit(1);
  }
  return buffer;
}

void *increase_malloc_buffer(void *buffer, size_t new_capacity, size_t save_size);
static inline void *need_increase_malloc_buffer(void *buffer, size_t new_capacity, size_t save_size)
{
  void *result = increase_malloc_buffer(buffer, new_capacity, save_size);
  if (!result) {
    printf("Error: malloc(%llu) failed (e=%d)\n", (unsigned long long)new_capacity, errno);
    exit(1);
  }
  return result;
}
