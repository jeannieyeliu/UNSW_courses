//Insertion sort ... COMP9024 18s2

#include <stdio.h>

#define SIZE 6

void insertionSort(int array[], int n){
	int i;
	for (i = 1; i < n; i++){
		int element = array[i];
		int j = i-1;
		while (j>=0 && array[j] > element){
			array[j+1] = array[j];
			j--;
		}
		array[j+1]=element;
	}
}

int main(void){
	int number[SIZE] = {3,6,8,4,23,4};
	int i;
	insertionSort(number,SIZE);
	for ( i = 0; i < SIZE; i++)
		printf("%d\n",number[i]);
	return 0;
}