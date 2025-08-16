# **Bin-Packing-Problem-Solution-Using-MIPS-Assembly**
## **Project Overview**
In this project, you will implement a Bin Packing Solver using MIPS assembly language. The goal is to pack a 
list of items into the minimum number of bins using two heuristic approaches: First Fit (FF) and Best Fit (BF). 
The bin packing problem is defined as follows: Given a collection of items I1, I2,… In with corresponding sizes 
S1, S2,… Sn. The size of each item is a floating-point number between 0 and 1. The goal is to pack these n items 
into the minimum number of bins of unit capacity, which means the capacity of each bin is one. In this project, 
we will solve the bin packing problem using the following two heuristics:                                                                                                                                              

**1. First Fit (FF):** the bins are indexed sequentially as 1, 2, …All bins are initially empty. The items are 
considered for packing in the order I1, I2,… In. To pack an item Ii, find the least index j such that bin j 
has enough remaining capacity, i.e., it contains at most 1 - Si, then add the item Ii to the items packed in 
the bin j. 

**2. Best Fit (BF):** it is the same as FF except that when item Ii is packed, we pack it into the fullest bin that 
still has enough space to accommodate the item Ii. 



