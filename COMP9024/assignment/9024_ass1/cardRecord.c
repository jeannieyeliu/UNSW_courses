// Transport card record implementation ... Assignment 1 COMP9024 18s2
#include <stdio.h>
#include "cardRecord.h"

#define LINE_LENGTH 1024
#define NO_NUMBER -999

// scan input line for a positive integer, ignores the rest, returns NO_NUMBER if none
int readInt(void) {
   char line[LINE_LENGTH];
   int  n;

   fgets(line, LINE_LENGTH, stdin);
   if ( (sscanf(line, "%d", &n) != 1) || n <= 0 )
      return NO_NUMBER;
   else
      return n;
}

// scan input for a floating point number, ignores the rest, returns NO_NUMBER if none
float readFloat(void) {
   char  line[LINE_LENGTH];
   float f;

   fgets(line, LINE_LENGTH, stdin);
   if (sscanf(line, "%f", &f) != 1)
      return NO_NUMBER;
   else
      return f;
}

int readValidID(void) {
   int id = readInt();
   if ( id >= 100000000 || id < 10000000 )
      return NO_NUMBER;
   return id;
}

float readValidAmount(void) {
   float amount = readFloat();
   if (amount > 250.0 || amount < -2.3)
      return NO_NUMBER;
   return amount;
}

void printCardData(cardRecordT card) {
   printf("-----------------\n");
   printf("Card ID: %d\n", card.cardID);
   if(card.balance >=0)
      printf("Balance: $%.2f\n", card.balance);
   else 
      printf("Balance: -$%.2f\nLow balance\n", -card.balance);

   printf("-----------------\n");
   return; 
}
