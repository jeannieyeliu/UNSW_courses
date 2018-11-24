#include <stdio.h>

#define SIZE 6

void insertionSort(int array[], int n){
	for (int i=1; i<n; i++){
		int ele = array[i];
		int j=i-1;
		while(j>=0 && array[j]>ele){
			array[j+1]=array[j];
			j--;
		}
		array[j+1] = ele;

	}
}

int main(void){
	int array[SIZE]= {3,6,8,2,5,1};
	insertionSort(array, SIZE);
	for(int i=0; i<SIZE;i++){
		printf("%d\n",array[i]);
	}
	return 0;
}