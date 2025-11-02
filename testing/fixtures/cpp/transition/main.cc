#include <stdio.h>

int main() {
#ifdef FOO
  printf("FOO\n");
#endif
#ifdef BAR
  printf("BAR\n");
#endif
  return 0;
}
