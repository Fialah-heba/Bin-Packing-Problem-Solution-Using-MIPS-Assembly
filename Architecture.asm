.data
fileName:       .space 100
buffer:         .space 1024
prompt_msg:     .asciiz "Enter the input file name or path: "
error_open:     .asciiz "Error opening the file.\n"
error_range:    .asciiz "Error: Found number out of range (0-1).\n"
error_format:   .asciiz "Error: Invalid number format in file.\n"
welcome_msg:    .asciiz "Welcome to the Bin PAcking Solver! .\n"
load_msg:       .asciiz "Loading Successful!! You are now inside the program!  .\n"
newline:        .asciiz "\n"
space:          .asciiz " "
comma:          .asciiz ", "
ff_result:      .asciiz "First Fit Results:\n"
bin_prefix:     .asciiz "Bin "
colon:          .asciiz ": "
sum_prefix:     .asciiz " (Sum: "
close_bracket:  .asciiz ")"
total_bins_msg: .asciiz "Total number of bins used: "
menu_prompt:    .asciiz "\nMenu:\n1. Read file\n2. Enter 2 to Run First Fit or (ff,Ff,fF,FF)\n3. Enter 3 to Run Best Fit or (bf,Bf,bF,BF)\n4. Enter (Q or q) to Exit\nEnter your choice:"
invalid_choice: .asciiz "Invalid choice. Please try again.\n" 
######

bf_result:      .asciiz "BEST Fit Results:\n"

saved_msg: .asciiz "Results saved to file: output.file\n"
output_filename: .asciiz "output.txt"

#####
# Floating point constants
one_float:      .float 1.0
zero_float:     .float 0.0
round_const:    .float 0.000005
hundred_thousand: .float 100000.0
epsilon:        .float 0.000001

# Data storage
items:          .space 400
bin_contents:   .space 4000     # 2D array for items in each bin (100 bins × 10 items)
bin_sums:       .space 400
bin_counts:     .space 400
item_count:     .word 0      # Total number of input items



.text
.globl main

main:
    # Initialize variables
    li $s7, 0           # Flag to indicate if file is loaded (0 = not loaded, 1 = loaded)



   #print Welcom Massege 
    li $v0, 4
    la $a0, welcome_msg
    syscall



################                                Menue                           ####################
menu:
     # Print menu
    li $v0, 4                                      # System call for print string
    la $a0, menu_prompt
    syscall                                        # Display menu to user

    # Read user input (string)
    li $v0, 8
    la $a0, buffer      
    li $a1, 10          
    syscall

    # Check first character of input
    lb $t0, buffer
    li $t1, '1'                                 # Load first character of input
    beq $t0, $t1, read_file_option             # If '1', go to file option
    li $t1, '2'
    beq $t0, $t1, ff_option                   # If '2', go to file option
    li $t1, '3'                              
    beq $t0, $t1, bf_start                   # If '3', go to file option   
    li $t1, '4'
    beq $t0, $t1, exit
    li $t1, 'q'
    beq $t0, $t1, exit                      # If 'q', exit (lowercase)
    li $t1, 'Q'
    beq $t0, $t1, exit                      # If 'Q', exit (uppercase)

    # Check first character of input
    lb $t0, buffer
    li $t1, 'f'                             # Load 'f' for comparison
    beq $t0, $t1, check_ff     
    li $t1, 'F'
    beq $t0, $t1, check_ff                   #If first char is 'F', check if it's "FF"
    li $t1, 'b'
    beq $t0, $t1, check_bf
    li $t1, 'B'
    beq $t0, $t1, check_bf                  # If first char is 'B', check if it's "BF"
  

   
    j invalid_option                       # Jump to invalid option handler
 
 
 
 # Check second character for First Fit command
check_ff:
    lb $t0, buffer+1
    li $t1, 'f'
    beq $t0, $t1, ff_option        # If "ff", go to First Fit
    li $t1, 'F'
    beq $t0, $t1, ff_option         # If "fF" or "FF", go to First Fit
    j invalid_option
# Check second character for Best Fit command
check_bf:
    lb $t0, buffer+1
    li $t1, 'f'
    beq $t0, $t1, bf_start         # If "bf", go to Best Fit
    li $t1, 'F'
    beq $t0, $t1, bf_start        # If "bF" or "BF", go to Best Fit    
    j invalid_option
    
    
    
    
    
    
    
    
    
    ######                     Choice 1            __ LOAD FILE AND READING ________          # ########

read_file_option:
    # Print prompt
    li $v0, 4
    la $a0, prompt_msg
    syscall

    # Read filename
    li $v0, 8
    la $a0, fileName
    li $a1, 100              # Maximum length of filename (100 chars)
    syscall
    sw $t2, item_count     # item_count


    # Remove newline from filename
    la $t0, fileName
    
    
     # Remove newline character from filename
remove_loop:
    lb $t1, 0($t0)
    beqz $t1, open_file                    # If null terminator, done
    li $t2, 10
    beq $t1, $t2, remove_newline               # # If newline found, remove it
    addi $t0, $t0, 1                               # Move to next character
    j remove_loop

remove_newline:
    sb $zero, 0($t0)

open_file:
    # Open file
    li $v0, 13
    la $a0, fileName                               # Load address of "Enter filename" message
    li $a1, 0
    li $a2, 0
    syscall                                        # Display prompt to user
    bltz $v0, file_error                            # If negative, opening failed (error)
    move $s0, $v0

    # Read file
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 1024                       # Maximum bytes to read
    syscall
    move $s1, $v0                          # Save number of bytes actually read

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

    # Parse numbers with validation
    la $t0, buffer
    la $t1, items
    li $t2, 0           # item count
    l.s $f20, zero_float
    l.s $f22, one_float

parse_loop:
    lb $t3, 0($t0)
    beqz $t3, parse_done  # end of file
    li $t4, 32          # space
    beq $t3, $t4, skip_space
    li $t4, 10          # newline
    beq $t3, $t4, skip_space
    li $t4, 9           # tab
    beq $t3, $t4, skip_space

    # Parse number
    li $t5, 0           # integer part
    li $t6, 0           # fraction part
    li $t7, 10          # base
    li $t8, 0           # after dot flag
    li $t9, 1           # fraction divisor
    li $s3, 0           # negative flag

    # Check for negative number
    li $t4, 45          # '-'
    bne $t3, $t4, parse_number
    li $s3, 1           # set negative flag
    addi $t0, $t0, 1    # skip '-'
    lb $t3, 0($t0)      # load next char
  
  
  
  
  # Load current character and check for terminators/delimiters
parse_number:
    lb $t3, 0($t0)
    beqz $t3, store_number
    li $t4, 32
    beq $t3, $t4, store_number                # End if space
    li $t4, 10
    beq $t3, $t4, store_number                # End if newline
    li $t4, 9
    beq $t3, $t4, store_number
    li $t4, 46
    beq $t3, $t4, set_frac_flag

    # Check if digit   # Validate digit (0-9)
    li $t4, 48
    blt $t3, $t4, format_error                # Error if < '0'
    li $t4, 57                   # 9
    bgt $t3, $t4, format_error                   # Error if > '9
    sub $t3, $t3, 48    # convert to digit
    
    
    
    
    # Handle fractional part

    beqz $t8, add_int_part
    mul $t6, $t6, 10
    add $t6, $t6, $t3
    mul $t9, $t9, 10
    j inc_ptr

add_int_part:
    mul $t5, $t5, 10                             # Shift existing integer left
    add $t5, $t5, $t3
    j inc_ptr

set_frac_flag:
    li $t8, 1
    j inc_ptr

inc_ptr:
    addi $t0, $t0, 1                     # Move to next character
    j parse_number

store_number:
    # Handle negative numbers
    beqz $s3, positive_num              # Skip if positive
    neg $t5, $t5
    neg $t6, $t6


    
    positive_num:
    # Convert to floating point format
    mtc1 $t5, $f4            # Move integer part to FPU
    mtc1 $t6, $f6            # Move fractional part to FPU
    mtc1 $t9, $f8            # Move denominator to FPU
    cvt.s.w $f4, $f4         # Convert integer to float
    cvt.s.w $f6, $f6         # Convert fractional part to float
    cvt.s.w $f8, $f8         # Convert denominator to float
    div.s $f6, $f6, $f8      # Calculate fractional value (0.xxx)
    add.s $f4, $f4, $f6      # Combine integer and fractional parts
    # Apply rounding
    jal round_float
    
    # Validate range (0 <= number <= 1)
    c.lt.s $f4, $f20     # compare with 0.0
    bc1t range_error
    c.lt.s $f22, $f4     # compare with 1.0
    bc1t range_error
    
    # Store valid number
    swc1 $f4, 0($t1)
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j skip_space

skip_space:
    addi $t0, $t0, 1
    j parse_loop

parse_done:
    sw $t2, item_count   

    # Set file loaded flag
    li $s7, 1
    sw $t2, item_count


  
    li $v0, 4
    la $a0, load_msg
    syscall
    

    j menu







########################                          choic 2 FF                            #########
ff_option:
lw $t2, item_count   # 


# Clear bin_counts
la $s4, bin_counts
li $t9, 0
ff_clear_counts:
    sw $zero, 0($s4)
    addi $s4, $s4, 4
    addi $t9, $t9, 1
    blt $t9, 100, ff_clear_counts

# Clear bin_sums
la $s2, bin_sums
li $t9, 0
ff_clear_sums:
    swc1 $f0, 0($s2)
    addi $s2, $s2, 4
    addi $t9, $t9, 1
    blt $t9, 100, ff_clear_sums

    # Check if file is loaded
    beqz $s7, no_file_loaded
    
    # Initialize variables for First Fit
    li $t3, 0            # Current item index
    li $t5, 0            # Bin count
    l.s $f12, one_float  # Bin capacity (1.0)
    l.s $f14, epsilon    # Small epsilon value for comparison

    # Initialize bin contents and counts
    la $s3, bin_contents
    la $s4, bin_counts                     # Load address of bin counts array
    li $t9, 0                             # Initialize counter to 0
init_bins:
    sw $zero, 0($s4)
    addi $s4, $s4, 4                    # Move to next bin count (4 bytes per count)
    addi $t9, $t9, 1
    blt $t9, 100, init_bins

ff_loop:
    bge $t3, $t2, ff_done                   # Exit if processed all items
    sll $t4, $t3, 2                         # Calculate item offset (index × 4 bytes)
    la $t6, items
    addu $t6, $t6, $t4
    lwc1 $f2, 0($t6)                         # Current item

    li $t7, -1                               # Best bin found
    li $t8, 0                               # Current bin index

search_bin:
# Search for a bin that can accommodate the item
    bge $t8, $t5, check_insert
    sll $t9, $t8, 2
    la $s2, bin_sums                      # Load base address of bin sums
    addu $s2, $s2, $t9
    lwc1 $f4, 0($s2)                    # Current bin sum

    # Calculate remaining space with epsilon
    sub.s $f6, $f12, $f4                  # remaining = 1.0 - current_sum
    add.s $f6, $f6, $f14 
    
    # Check if item fits
    c.lt.s $f2, $f6
    bc1t found_bin                         # If fits, mark this bin
    j next_bin                            # Otherwise try next bin

found_bin:
    move $t7, $t8
    j check_insert

next_bin:
    addi $t8, $t8, 1                  # Move to next bin index
    j search_bin                     # Continue searching

check_insert:
    bltz $t7, create_bin               #If no bin found ($t7 = -1), create new bin
    
    # Add to existing bin
    sll $t9, $t7, 2                   # Calculate offset for bin sum (index × 4 bytes)
    la $s2, bin_sums
    addu $s2, $s2, $t9               # Calculate address of this bin's sum
    lwc1 $f4, 0($s2)
    add.s $f4, $f4, $f2              # Add current item to the bin sum
    swc1 $f4, 0($s2)
    
    # Store item in bin contents
    la $s5, bin_counts
    addu $s5, $s5, $t9
    lw $t9, 0($s5)       # Current item count
    
    la $s6, bin_contents
    mul $t0, $t7, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0            # Calculate address of this bin's count
    sll $t1, $t9, 2               # Calculate item offset (count × 4 bytes)
    addu $s6, $s6, $t1
    swc1 $f2, 0($s6)     # Store the item
    
    # Update item count
    addi $t9, $t9, 1
    la $s5, bin_counts                 # Reload bin counts address
    sll $t0, $t7, 2
    addu $s5, $s5, $t0
    sw $t9, 0($s5)
    
    j ff_continue                       # Move to next item
 
create_bin:
    # Create new bin
    sll $t9, $t5, 2
    la $s2, bin_sums                           # Load bin sums address
    addu $s2, $s2, $t9                         # Get address for new bin's sum
    swc1 $f2, 0($s2)                       # Store item as initial sum of new bin
    
    # Store first item in new bin
    la $s5, bin_counts
    addu $s5, $s5, $t9
    li $t0, 1
    sw $t0, 0($s5)
    
    la $s6, bin_contents
    mul $t0, $t5, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0
    swc1 $f2, 0($s6)     # Store the item
    
    addi $t5, $t5, 1

ff_continue:
    addi $t3, $t3, 1
    j ff_loop

ff_done:
    # Print total number of bins first
    li $v0, 4
    la $a0, total_bins_msg
    syscall
    
    li $v0, 1
    move $a0, $t5
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    # Then print the results header
    li $v0, 4
    la $a0, ff_result
    syscall

    li $t3, 0
print_bins:
    bge $t3, $t5, menu
    
    # Print bin header
    li $v0, 4
    la $a0, bin_prefix
    syscall

    li $v0, 1
    addi $a0, $t3, 1      # prints bin number + 1 (1, 2, 3, ...)
    syscall

    li $v0, 4
    la $a0, colon
    syscall

    # Get bin item count
    la $s5, bin_counts
    sll $t4, $t3, 2
    addu $s5, $s5, $t4
    lw $t6, 0($s5)       # Item count
    
    # Get bin contents address
    la $s6, bin_contents
    mul $t0, $t3, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0
    
    # Print each item
    li $t7, 0           # Item counter
print_contents:
    bge $t7, $t6, print_sum
    
    # Print comma if not first item
    beqz $t7, no_comma
    li $v0, 4
    la $a0, comma
    syscall
 # This label is reached when printing the first item in a bin (no comma needed before it) 
no_comma:
    
     # Print the item (floating-point number)
    sll $t1, $t7, 2       # Calculate offset for current item (index * 4 bytes)
    addu $t2, $s6, $t1    # Get address of current item in bin_contents
    lwc1 $f12, 0($t2)      # Load the float value from memory to $f12
    
    jal round_float
    li $v0, 2     # System call code for printing float
    syscall       # Print the rounded float value
    
    addi $t7, $t7, 1      # Increment item counter
    j print_contents      # Jump back to continue printing remaining items
 
print_sum:
    # Print sum
    li $v0, 4
    la $a0, sum_prefix
    syscall
# Calculate address of current bin's sum (bin_sums[bin_index])
    la $s2, bin_sums
    sll $t4, $t3, 2
    addu $s2, $s2, $t4
    lwc1 $f12, 0($s2)
 # Print rounded sum value    
    jal round_float
    li $v0, 2
    syscall
# Print closing bracket and newline    
    li $v0, 4
    la $a0, close_bracket
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
 # Move to next bin and continue loop
    addi $t3, $t3, 1    # Increment bin counter
    j print_bins
    
# Error handler when no input file is loaded
no_file_loaded:
    li $v0, 4   # System call for print string
    la $a0, error_open
    syscall  # Print error message
    j menu    # Jump back to main menu

 # Error handler for invalid menu selections
invalid_option:
    li $v0, 4
    la $a0, invalid_choice
    syscall
    j menu
    
# Function to round floating-point number to 5 decimal places
round_float:


# Load rounding constant (0.000005) into $f , This small value helps with proper rounding
    l.s $f5, round_const
# Add rounding constant to original value ,This ensures values at midpoint round up    
    add.s $f12, $f12, $f5
# Load 100,000into $f7 (10^5 for 5 decimal places)
    l.s $f7, hundred_thousand
# Multiply by 100,000 to shift decimal point right    
    mul.s $f12, $f12, $f7
# Convert to integer (truncates decimal part)    
    cvt.w.s $f12, $f12
# Convert back to floating-point    
    cvt.s.w $f12, $f12
# Divide by 100,000 to restore original scale    
    div.s $f12, $f12, $f7
 #Return to caller with rounded value in $f12   
    jr $ra
    
# Handle file operation errors (opening/reading)
file_error:
    li $v0, 4
    la $a0, error_open
    syscall
    j menu
# Handle numbers outside valid range (0-1)
range_error:
    li $v0, 4
    la $a0, error_range
    syscall
    j menu
# Handle invalid number formats in input
format_error:
    li $v0, 4
    la $a0, error_format
    syscall
    j menu
# Terminate program execution
exit:
    li $v0, 10
    syscall  
   
                                     ##############################  Best Fit  ##########################

 # Best-Fit Bin Packing Algorithm Entry Point
bf_start:
   
    beqz $s7, no_file_loaded  # Check if file is loaded, jump to error if not

    lw $t2, item_count   # Load total number of items
    
    li $t3, 0            # Current item index
    li $t5, 0            # Bin count
    l.s $f12, one_float  # Bin capacity (1.0)
    l.s $f14, epsilon    # Small epsilon value for comparison

    # Initialize bin contents and counts
    la $s3, bin_contents
    la $s4, bin_counts
    li $t9, 0
    
init_bin:
 # Clear bin counts array (set all to 0)
    sw $zero, 0($s4)
    addi $s4, $s4, 4
    addi $t9, $t9, 1
    blt $t9, 100, init_bin  # Loop until all 100 bins cleared

 # Main Best-Fit algorithm loop
bf_loop:
    bge $t3, $t2, bf_done  # Exit loop if all items processed
    sll $t4, $t3, 2    # Calculate item offset (index × 4 bytes)
    la $t6, items
    addu $t6, $t6, $t4
    lwc1 $f2, 0($t6)     # Current item

    # Initialize Best-Fit search variables
    li $t7, -1           # Best bin index
    li $t8, 0            # Current bin index
    mov.s $f10, $f12     # Initialize min remaining space = bin capacity

# Best-Fit bin search algorithm
search_binbf:
    bge $t8, $t5, check_insertbf

    sll $t9, $t8, 2
    la $s2, bin_sums
    addu $s2, $s2, $t9
    lwc1 $f4, 0($s2)     # bin sum

 # Calculate remaining capacity in current bin
    sub.s $f6, $f12, $f4 # remaining capacity
    add.s $f6, $f6, $f14 # add epsilon
    
# Check if item fits in current bin
    c.lt.s $f2, $f6      # if item < remaining
    bc1f next_binbf

    # check if this is the best so far
    sub.s $f8, $f6, $f2  # space left after placing item
    c.lt.s $f8, $f10
    bc1t update_best
    j next_binbf
# Found a better fitting bin
update_best:
    mov.s $f10, $f8      # update best fit
    move $t7, $t8        # update best bin
# Move to next bin
next_binbf:
    addi $t8, $t8, 1
    j search_binbf

# Best-Fit item placement routine
check_insertbf:
    bltz $t7, create_binbf
    
    # Add to existing bin
    sll $t9, $t7, 2
    la $s2, bin_sums
    addu $s2, $s2, $t9
    lwc1 $f4, 0($s2)
    add.s $f4, $f4, $f2
    swc1 $f4, 0($s2)
    
    # Store item in bin contents
    la $s5, bin_counts
    addu $s5, $s5, $t9
    lw $t9, 0($s5)       # Current item count
    
    la $s6, bin_contents
    mul $t0, $t7, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0
    sll $t1, $t9, 2
    addu $s6, $s6, $t1
    swc1 $f2, 0($s6)     # Store the item
    
    # Update item count for this bin
    addi $t9, $t9, 1
    la $s5, bin_counts
    sll $t0, $t7, 2        # # Calculate item offset (count × 4 bytes)
    addu $s5, $s5, $t0     # # Get address for new item
    sw $t9, 0($s5)
    
    j bf_continue
    
 # Create new bin for item that didn't fit in existing bins
create_binbf:

    # Initialize new bin's sum
    sll $t9, $t5, 2
    la $s2, bin_sums
    addu $s2, $s2, $t9
    swc1 $f2, 0($s2)
    
    # Store first item in new bin
    la $s5, bin_counts
    addu $s5, $s5, $t9
    li $t0, 1
    sw $t0, 0($s5)
    
# Store the item in new bin's contents    
    la $s6, bin_contents
    mul $t0, $t5, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0
    swc1 $f2, 0($s6)     # Store the item
    
 # Update total bin count    
    addi $t5, $t5, 1

# Continue to next item in Best-Fit algorithm
bf_continue:
    addi $t3, $t3, 1
    j bf_loop
 # Best-Fit algorithm completion routine
bf_done:
    
    li $v0, 4 # System call for print string
    la $a0, total_bins_msg  # "Total number of bins used: "
    syscall
    
# Print actual bin count
    li $v0, 1   # System call for print integer
    move $a0, $t5        # Move bin count to argument register
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
# Print Best-Fit results header
    li $v0, 4
    la $a0, bf_result
    syscall
# Initialize bin printing counter
    li $t3, 0    # Reset bin counter for display loop

    li $t3, 0   #The duplicate 'li $t3, 0' appears to be redundant
    # and can likely be removed from the actual implementation
    
    
# Best-Fit bin display routine    
print_binsbf:
   # bge $t3, $t5, print_total_bins
       bge $t3, $t5, menu    # Exit if all bins printed (return to menu)

    # Print bin header
    li $v0, 4
    la $a0, bin_prefix
    syscall

    li $v0, 1
    addi $a0, $t3, 1    # Print bin number (1-based index)
    syscall

    li $v0, 4
    la $a0, colon   # Print ": "
    syscall

    # Get bin item count
    la $s5, bin_counts
    sll $t4, $t3, 2
    addu $s5, $s5, $t4
    lw $t6, 0($s5)       # Item count
    
    # Get bin contents address
    la $s6, bin_contents
    mul $t0, $t3, 40     # 10 items * 4 bytes per bin
    addu $s6, $s6, $t0
    
    # Print each item
    li $t7, 0           # Item counter
    
print_contentsbf:
    bge $t7, $t6, print_sumbf       # Exit loop if all items printed
    beqz $t6, print_sumbf         # Skip if empty bin
    
    # Print comma if not first item
    beqz $t7, no_comma
    li $v0, 4
    la $a0, comma
    syscall
    
# Print current item value    
no_commabf:
    
    # Print the item
    sll $t1, $t7, 2
    addu $t2, $s6, $t1
    lwc1 $f12, 0($t2)
    
    jal round_float   # Round to 5 decimal places
    li $v0, 2    # Print float syscall
    syscall
    
    addi $t7, $t7, 1  # Increment item counter
    j print_contentsbf    # Continue with next item
    
# Print bin's sum information
print_sumbf:
    # Print sum
    li $v0, 4
    la $a0, sum_prefix
    syscall
  # Load and print the bin's sum   
    la $s2, bin_sums
    sll $t4, $t3, 2
    addu $s2, $s2, $t4
    lwc1 $f12, 0($s2)
    
    jal round_float
    li $v0, 2
    syscall
# Print closing bracket and newline    
    li $v0, 4
    la $a0, close_bracket
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall

# Move to next bin
    addi $t3, $t3, 1
    j print_binsbf

# Print final summary information
print_total_bins:
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

# Print total bins message   
    li $v0, 4
    la $a0, total_bins_msg
    syscall

  # Print actual bin count   
    li $v0, 1
    move $a0, $t5
    syscall

    # Print newline    
    li $v0, 4
    la $a0, newline
    syscall

      # Print save confirmation message
  
    li $v0, 4
    la $a0, saved_msg
    syscall

    # Open output file for writing

    li $v0, 13
    la $a0, output_filename
    li $a1, 1          # write only
    li $a2, 0x1B6      # rw-rw-rw-
    syscall
    move $s7, $v0    # Save file descriptor
    bltz $s7, file_error

   # Allocate memory for string conversion  
    li $v0, 9
    li $a0, 20
    syscall
    move $s6, $v0

     # Convert bin count to ASCII character
    li $t0, 0x30     # '0' in ASCII
    add $t1, $t5, $t0  # Convert number to ASCII
    sb $t1, 0($s6)    # Store in buffer

    # Add newline and null terminator 
    li $t2, 10    # Newline character
    sb $t2, 1($s6)
    sb $zero, 2($s6)

     # Write to file
    li $v0, 15      
    move $a0, $s7     # File descriptor
    move $a1, $s6     # Buffer address
    li $a2, 2       # Number of bytes to write
    syscall

     # Close file
    li $v0, 16
    move $a0, $s7    # File descriptor
    syscall

    j exit    # Terminate program
    
     # Alternate rounding function (same as round_float)
round_floatbf:
    l.s $f5, round_const
    add.s $f12, $f12, $f5
    l.s $f7, hundred_thousand
    mul.s $f12, $f12, $f7
    cvt.w.s $f12, $f12
    cvt.s.w $f12, $f12
    div.s $f12, $f12, $f7
    jr $ra
    
# File error handler
file_errorbf:
    li $v0, 4
    la $a0, error_open
    syscall
    j  menu

# Program termination
exitbf:
    li $v0, 10
    syscall
