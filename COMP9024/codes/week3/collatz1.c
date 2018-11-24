// Apply Collatz's process to user input ... COMP9024 18s2
#include <stdio.h>

void collatz(int n) {
   printf("%d\n", n);
   while (n != 1) {
      if (n % 2 == 0)
	 n = n / 2;
      else
	 n = 3*n + 1;
      printf("%d\n", n);
   }
}

int main(void) {
   int n;
   printf("Enter a positive number: ");
   if (scanf("%d", &n) == 1 && (n > 0))  // test if scanf successful and returns positive number
      collatz(n);
   return 0;
}
