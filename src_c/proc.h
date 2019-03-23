static inline bool contains_dir_separator(const char *str)
{
  return strchr(str, '/') != NULL;
}
err_t which_malloc(const char *prog, char **result);

int try_run(char *const argv[]);
static inline void run(const char *fail_prefix, char *const argv[])
{
  int result = try_run(argv);
  if (result != 0) {
    errorf("%s failed with exit code %d", fail_prefix, result);
    exit(1);
  }
}


struct run_stdout_result
{
  int status;
  struct read_data stdout;
};
err_t run_stdout(struct run_stdout_result *result, char *const argv[]);
