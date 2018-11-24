// Exercise #4 Week 4 ... COMP9024 18s2
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

int main(void) {
   int n;

   printf("Enter a number: ");
   scanf("%d", &n);

   float *a = malloc(n * sizeof(float));
   assert(a != NULL);
   float *b = malloc(n * sizeof(float));
   assert(b != NULL);
   
   int i;
   for (i=0; i<n; i++) {
      printf("Enter a value: ");
      scanf("%f", &a[i]);
   }
   for (i=0; i<n; i++) {
      printf("Enter a value: ");
      scanf("%f", &b[i]);
   }
   float prod = 0.0;
   for (i=0; i<n; i++) {
      prod += a[i]*b[i];
   }
   printf("Inner product is %f\n", prod);
   free(a);
   free(b);
   return 0;
}
