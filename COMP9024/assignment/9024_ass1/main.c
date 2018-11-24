/**
     main.c

     Program supplied as a starting point for
     Assignment 1: Transport card manager

     COMP9024 18s2
**/
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>

#include "cardRecord.h"
#include "cardLL.h"

#define NO_NUMBER -999
void printHelp();
void CardLinkedListProcessing();
void getRecord(cardRecordT*);

int main(int argc, char *argv[]) {
   if (argc == 2) {

      // if n is not an integer. or n is non-positive, just exit
      int i,n = atoi(argv[1]);
      if (n <=0)
         return 1;

      /* allocate memory for the card records */
      cardRecordT *records = malloc(n * sizeof(cardRecordT));

      /* prompt the user to input data*/
      for (i = 0; i < n; i++){
         getRecord(&(records[i]));
      }
      
      /* print the records */
      for (i = 0; i < n; i ++) {
         printCardData(records[i]);
      }
      float sum = 0, avg=0;
      for (i = 0; i < n; i++) {
         sum += records[i].balance;
      }
      avg = sum / n;
      printf("Number of cards on file: %d\n", n );
      if(avg >=0)
         printf("Average balance: $%.2f\n", avg);
      else
         printf("Average balance: -$%.2f\n", -avg);

      /* don't forget to free the memory!!! */
      free(records);
   } else {
      CardLinkedListProcessing();
   }
   return 0;
}

void getRecord(cardRecordT *record){
   /* 1. Enter card ID */
   printf("Enter card ID: ");
   (*record).cardID = readValidID();
   while ((*record).cardID == NO_NUMBER){
      printf("Not valid. Enter a valid value: ");
      (*record).cardID = readValidID();
   }

   /* 2. Enter amount  */
   printf("Enter amount: ");
   (*record).balance = readValidAmount();
   while( (*record).balance == NO_NUMBER){
      printf("Not valid. Enter a valid value: ");
      (*record).balance = readValidAmount();
   }
}

/* Code for Stages 2 and 3 starts here */

void CardLinkedListProcessing() {
   int op, ch;

   List list = newLL();   // create a new linked list
   
   while (1) {
      printf("Enter command (a,g,p,q,r, h for Help)> ");

      do {
    ch = getchar();
      } while (!isalpha(ch) && ch != '\n');  // isalpha() defined in ctype.h
      op = ch;
      // skip the rest of the line until newline is encountered
      while (ch != '\n') {
    ch = getchar();
      }

      switch (op) {
         // prompts the user to input valid data for a transport card record as above,
         case 'a':
         case 'A':{
            // inserts the record into the linked list and outputs  "Card added."
            cardRecordT record;
            getRecord(&record);
            insertLL(list, record.cardID, record.balance);
         }
       break;

         case 'g':
         case 'G':{
            //outputs the total number of card records and the average balance across all transport cards in the list
            int n; 
            float balance;
            getAverageLL(list, &n, &balance);
            printf("Number of cards on file: %d\n", n);
            if(balance >=0)
               printf("Average balance: $%.2f\n", balance);
            else
               printf("Average balance: -$%.2f\n", -balance);

         }
       break;
       
         case 'h':
         case 'H':
            printHelp();
       break;

         case 'p':
         case 'P':
            //prints all transport card records 
            showLL(list);
       break;

         case 'r':
         case 'R':
            /*** removing a card record ***/
            /*  Enter card ID */
            printf("Enter card ID: ");
            int cardID = readValidID();
            while (cardID == NO_NUMBER){
               printf("Not valid. Enter a valid value: ");
               cardID = readValidID();
            }
            removeLL(list,cardID);
       break;

    case 'q':
         case 'Q':
            dropLL(list);       // destroy linked list before returning
       printf("Bye.\n");
       return;
      }
   }
}

void printHelp() {
   printf("\n");
   printf(" a - Add card record\n" );
   printf(" g - Get average balance\n" );
   printf(" h - Help\n");
   printf(" p - Print all records\n" );
   printf(" r - Remove card\n");
   printf(" q - Quit\n");
   printf("\n");
}
