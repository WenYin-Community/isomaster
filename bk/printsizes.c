#include <stdio.h>
#include <limits.h>

int main(void)
{
  printf("%X\n", 0xAABBCCDD);
  printf("variable sizes:\n");
  /* sizeof yields size_t: %d reads an int-sized argument and is undefined */
  printf("short: %zu\n", sizeof(short));
  printf("int: %zu\n", sizeof(int));
  printf("long: %zu\n", sizeof(long));
  printf("long long: %zu\n", sizeof(long long));

  return 0;
}

