
struct read_data
{
  char *ptr;
  size_t length;
};
static inline struct read_data make_read_data(char *ptr, size_t length)
{
  struct read_data result;
  result.ptr = ptr;
  result.length = length;
  return result;
}
err_t read_all_malloc(struct read_data *data, int fd, size_t initial_size);
