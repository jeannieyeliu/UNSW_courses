// Insertion sort ... COMP9024 18s2

#include <stdio.h>

#define SIZE 6

void insertionSort(int array[], int n) {
   int i;
   for (i = 1; i < n; i++) {
      int element = array[i];                 // for this element ...
      int j = i-1;
      while (j >= 0 && array[j] > element) {  // ... work down the ordered list
         array[j+1] = array[j];               // ... moving elements up
         j--;
      }
      array[j+1] = element;                   // and insert in correct position
   }
}

int main(void) {
   int numbers[SIZE] = { 3, 6, 5, 2, 4, 1 };
   int i;
   
   insertionSort(numbers, SIZE);
   for (i = 0; i < SIZE; i++)
      printf("%d\n", numbers[i]);

   return 0;
}
