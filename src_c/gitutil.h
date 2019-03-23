struct git_show_info
{
  char *sha;
  char *datetime;
};
struct git_show_info parse_git_show(const char *output);
