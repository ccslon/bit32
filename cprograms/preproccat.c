#define COMMAND(NAME)  { #NAME, NAME ## _command }
struct command
{
  char *name;
  void (*function)(void);
};
struct command commands[] =
{
  COMMAND(quit),
  COMMAND(help)
};