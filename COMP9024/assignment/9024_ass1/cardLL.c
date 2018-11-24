// Linked list of transport card records implementation ... Assignment 1 COMP9024 18s2
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "cardLL.h"
#include "cardRecord.h"

// linked list node type
// DO NOT CHANGE
typedef struct node {
    cardRecordT data;
    struct node *next;
} NodeT;

// linked list type
typedef struct ListRep {
	NodeT *head;
} ListRep;

/*** Your code for stages 2 & 3 starts here ***/

// Time complexity: O(1)
// Explanation: There's no loop in the funtion, just two assigning statement.
List newLL() {
	ListRep *cardlist = malloc(sizeof(ListRep));
	cardlist->head = NULL;
    return cardlist;
}

// Time complexity: O(n)
// Explanation: Traverse the list of length n and delete each node. Only a while loop
void dropLL(List listp) {
    if (listp->head != NULL){
	    NodeT *nextNode = listp->head->next;
	    NodeT *currentNode = listp->head;

	    //Traverse the list and delete each node
	    while ( nextNode != NULL) {
	    	//free(currentNode->data);
	    	free(currentNode);
	    	currentNode = nextNode;
	    	nextNode = currentNode->next;
	    }
	    //free(currentNode->data);
	    free(currentNode);
	}	
    free(listp);
    return; 
}

// Time complexity: O(n)
// Explanation: traverse the list of n nodes to find the card to remove.
// worst case is that the node to delete is the last element or could find card
// in that case it has to traverse n times. 
void removeLL(List listp, int cardID) {
	if (listp->head == NULL)
		return;

	NodeT *currentNode = listp->head;
	NodeT *nextNode = currentNode->next;

	//if the first node is the node to delete
	if (currentNode->data.cardID == cardID){
		listp->head = nextNode;
		free(currentNode);
		printf("Card removed.\n");
		return;
	}

	while( nextNode != NULL){
		if(nextNode->data.cardID == cardID){
			currentNode->next=nextNode->next;
			free(nextNode);
			printf("Card removed.\n");
			return;
		}
    	currentNode = nextNode;
    	nextNode = currentNode->next;
	}
	printf("Card not found.\n");
   	return;  /* needs to be replaced */
}

void insertBehind(List listp,NodeT *preNode, NodeT *newNode){

	if (preNode->data.cardID == newNode->data.cardID) {
		preNode->data.balance = preNode->data.balance  + newNode->data.balance;
		printCardData(preNode->data);
		free(newNode);
	}
	else {
		newNode->next = preNode->next;
		preNode->next = newNode;
		printf("Card added.\n");
	}

}

// Time complexity: O(1) for stage2, O(n) for state3
// Explanation: at stage 2, since always insert in the beginning, no loop, hence O(1)
//at stage 3 find the node to insert, need to traverse n times.
void insertLL(List listp, int cardID, float amount) {
	//create a new node
	NodeT *newrecord = malloc(sizeof(NodeT));

	//create the cardRecord
	cardRecordT cardRecord;
	cardRecord.cardID = cardID;
	cardRecord.balance = amount;
	newrecord->data = cardRecord;
	newrecord->next = NULL;

	/**
	//The below code is for stage2
	//insert in the beginning
	newrecord->next = listp->head;
	listp->head = newrecord;
	return;
	//The above code is for stage2
	**/

	/* the below code is only for stage3 */
	//if entered an existing card
	//1. list is empty
	if ( listp->head == NULL){
		listp->head = newrecord;
		printf("Card added.\n");
		return;
	}

	
	if (listp->head->data.cardID > cardID){
		newrecord->next = listp->head;
		listp->head = newrecord;
		printf("Card added.\n");
		return;
	} 
	

	NodeT *currentNode = listp->head;
	NodeT *nextNode = currentNode->next;

	while(nextNode != NULL ){
		// if (nextNode == NULL){
		// 	printf("arrived here 1 if nextNode is null ! %d,%.2f\n", currentNode->data.cardID, currentNode->data.balance);
		// 	break;
		// }

		if ( currentNode->data.cardID <= cardID 
			&&  nextNode->data.cardID > cardID){
			break;
		}
/*
		printf("arrived here 3 if ! \n" );
		if( preNode->next != NULL && currentNode->data.cardID > cardID ){
		printf("arrived here 4 if !\n" );
			break;
		}
*/
		currentNode = currentNode->next;
		nextNode = currentNode->next;
	}
	insertBehind(listp, currentNode, newrecord);

	return;
}



// Time complexity: O(n)
// Explanation: traverse the list of n once to get the total items and average balance
void getAverageLL(List listp, int *n, float *balance) {
	*balance=0.0;
	*n = 0;
    NodeT *node = listp->head;
	while (node !=NULL){
		(*n)++;
		*balance += node->data.balance;
        node = node->next;
	}
	if(*n != 0){
		*balance = (*balance) / (*n);
	}
	return;
}

// Time complexity: O(n)
// Explanation: travese a list of n nodes with print method each time in a loop.
void showLL(List listp) {
	NodeT *node = listp->head;
	while (node != NULL){
		printCardData(node->data);
		node = node->next;
	}
   return;
}
