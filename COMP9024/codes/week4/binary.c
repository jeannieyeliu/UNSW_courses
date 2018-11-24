#include <stdlib.h>
#include <stdio.h>
#include "stack.h"

int main(int argc, char *argv[]) {
   int n;

   if (argc != 2) {
      printf("Usage: %s number\n", argv[0]);
      return 1;
   }

   stack S = newStack();
   n = atoi(argv[1]);
   while (n > 0) {
      StackPush(S, n % 2);
      n = n / 2;
   }
   while (!StackIsEmpty(S)) {
      printf("%d", StackPop(S));
   }
   putchar('\n');
   dropStack(S);
   return 0;
}
