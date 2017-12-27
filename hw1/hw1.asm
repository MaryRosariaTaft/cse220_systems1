# Homework #1
# name: Mary Taft
# sbuid: 110505413


# loads args from "Program Arguments"
.macro load_args
	# $a0 - num args passed
	# $a1 - starting address of array of args passed (stored as strings)
	sw $a0 numargs #set numargs
	lw $t0 0($a1) #  $t0 = $a1 == $a1 + 0 bytes == $a1 + 0 words
	sw $t0 arg1 # arg1 = $t0
	lw $t0 4($a1) 
	sw $t0 arg2 # arg2 = $a1 + 4 bytes == $a1 + 1 word
	lw $t0 8($a1)
	sw $t0 arg3 # arg3 = $a1 + 8 bytes == $a1 + 2 words
	
.end_macro


.text
.globl main
main:
	load_args()

part_1:
	#if numargs <2 or >3, error
	lw $t0 numargs
	blt $t0 2 print_error
	bgt $t0 3 print_error
	
	#if arg1 has >1 char, error
	lw $t0 arg1
	lbu $t1 1($t0) #2nd byte (index 1) *should be* null terminator
	bnez $t1 print_error
	
	#base behavior on value of arg1
	lbu $t0 0($t0) #retrieve arg1's char
	#if arg1 == 'A' or 'a', part 2 
	beq $t0 65 part_2
	beq $t0 97 part_2
	#if arg1 == 'R' or 'r', part 3 
	beq $t0 82 part_3
	beq $t0 114 part_3
	#else error
	b print_error
	
	
part_2:
	#confirmation that part 1 branches here when desired
	#la $a0 part2_string
	#li $v0 4
	#syscall
	#b done
	
	#if numargs != 3, error
	lw $t0 numargs
	bne $t0 3 print_error
	
	#ASSUME that arg2 and arg3 are each 4+ ASCII chars in length
	#arg2: load values of first 4 chars into a register byte by byte
	lw $t0 arg2 # $t0 = address of the arg2 string
	lbu $t1 0($t0) #load 1st char of the arg2 string
	lbu $t2 1($t0) #load 2nd char of the arg2 string
	sll $t2 $t2 8 #then shift it left a byte such that
	or $t1 $t1 $t2 #it can be or'd with the the 1st char to append in reverse order (little endian)
	lbu $t2 2($t0) #repeat process to get all 4 chars
	sll $t2 $t2 16
	or $t1 $t1 $t2
	lbu $t2 3($t0)
	sll $t2 $t2 24
	or $t1 $t1 $t2
	move $s0 $t1 #move final value to a saved register
	#arg3: same as above
	lw $t0 arg3
	lbu $t1 0($t0)
	lbu $t2 1($t0)
	sll $t2 $t2 8
	or $t1 $t1 $t2
	lbu $t2 2($t0)
	sll $t2 $t2 16
	or $t1 $t1 $t2
	lbu $t2 3($t0)
	sll $t2 $t2 24
	or $t1 $t1 $t2
	move $s1 $t1
	#result of above: arg2 chars (reversed / little endian) are in $s0;
	#                 arg3 chars, in $s1
	

	#print different representations of the values in $s0 and $s1
	#---
	#I RECOGNIZE THAT THE FOLLOWING IS HORRIBLY, TERRIBLY INEFFICIENT
	# but I'm sleepy and I'll deal with it later, or at least
	# try not to repeat such abominations in future code.
	#---
	#"ARG2: "
	la $a0 arg2_string
	li $v0 4
	syscall
	#binary
	move $a0 $s0
	li $v0 35
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#hex
	move $a0 $s0
	li $v0 34
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#two's comp
	move $a0 $s0
	li $v0 1
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#one's comp
	move $a0 $s0
	li $v0 100
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#sign/mag
	move $a0 $s0
	li $v0 101
	syscall
	#"ARG3: "
	la $a0 arg3_string
	li $v0 4
	syscall
	#binary
	move $a0 $s1
	li $v0 35
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#hex
	move $a0 $s1
	li $v0 34
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#two's comp
	move $a0 $s1
	li $v0 1
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#one's comp
	move $a0 $s1
	li $v0 100
	syscall
	#space
	la $a0 space
	li $v0 4
	syscall
	#sign/mag
	move $a0 $s1
	li $v0 101
	syscall
	#end print, finally...
	
	#time for Hamming distance!
	
	#bitwise-xor'ing arg2 ($s0) and arg3 ($s1) will yield
	# a binary number whose digits will be 1 wherever
	# the corresponding digits of arg2 and arg3 differ,
	# and 0 elsewhere
	#to get the Hamming distance, tally the number of 1's in the xor'd number
	xor $t0 $s0 $s1 #the xor'd number
	#iterativestuffs:
	li $t1 00000000000000000000000000000001
	li $t3 0
	li $s2 0
	#above:
	# $t1: position (leading 0's for clarity) / bit being checked
	# $t2 (not initialized; see hamming_loop_part_a): result of and'ing
	# $t3: loop counter (loop should stop at 31 [inclusive],
	#       since words [like arg2 and arg3] are 32 bits long)
	# $s2: tally (sum of all 1's), initialized to 0
	
hamming_loop_part_a:
	and $t2 $t0 $t1
	beqz $t2 hamming_loop_part_b #skip tally increment if and'ing resulted false
	addi $s2 $s2 1 #tally++
	
hamming_loop_part_b:
	sll $t1 $t1 1 #move the position by 1 bit (e.g. 00000000000000000000000000000010)
	addi $t3 $t3 1 #loopcounter++
	blt $t3 32 hamming_loop_part_a
	
exit_loop_and_finish_part_2:
	#print "Hamming Distance: "
	la $a0 hamming_string
	li $v0 4
	syscall
	#print the distance
	move $a0 $s2
	li $v0 1
	syscall
	#done!
	b done
	
	
part_3:
	#confirmation that part 1 branches here when desired
	#la $a0 part3_string
	#li $v0 4
	#syscall
	#b done
	
	#if numargs != 2, error
	lw $t0 numargs
	bne $t0 2 print_error

setup_loop_to_extract_int:
	lw $t0 arg2 #address of string is now stored in $t0
	li $t1 0 #let $t1 be the loop counter; init to 0
	li $s0 0 #ans will go here; init to 0
	li $t3 10 #algorithm requires multiplying by 10, so stick it here

loop_to_extract_int:
	#get val of byte at counter/index
	lbu $t2 ($t0)
	#if null terminator, exit loop
	beqz $t2 continue
	#else, extract numerical val of char
	li $t4 48
	sub $t2 $t2 $t4
	#if byte is an invalid character, exit loop
	blt $t2 0 continue
	bgt $t2 9 continue
	#else, append to ans AND increment pointer by a byte AND loop (branch to self)
	mult $s0 $t3 #ans...
	mflo $s0 #...= 10*ans
	add $s0 $s0 $t2 #ans += new value
	addi $t0 $t0 1 #increment pointer
	b loop_to_extract_int

continue:
	#set seed (takes 2 args)
	li $v0 40
	li $a0 0
	move $a1 $s0
	syscall
	
	#clear save registers to be used in loop
	move $s1 $0
	move $s2 $0
	move $s3 $0
	move $s4 $0
	move $s5 $0
	# $s0: most recent val (reset each iteration)
	# $s1: total # vals drawn (increment by 1)
	# $s2: powers of 2
	# $s3: multiple of 2
	# $s4: multiple of 4
	# $s5: multiple of 8

random_num_loop:
	
	#generate a random number in range [1, 1024]
	li $v0 42
	li $a0 0
	li $a1 1024
	syscall
	move $s0 $a0
	addi $s0 $s0 1
		
	#increment total num vals drawn
	addi $s1 $s1 1
	
check_if_power_of_two_setup:
	#check if power of 2 by checking if one and only one
	# digit of its binary representation is 1
	li $t1 00000000001
	li $t3 0
	li $t4 0
	# $t1: position (leading 0's for clarity) / bit being checked
	# $t2 (not initialized yet; see check_if_power_of_two): result of and'ing
	# $t3: loop counter (loop should stop at 11 [inclusive],
	#       since random numbers in range [1, 1024] are <=11 bits long)
	# $t4: tally (sum of all 1's), initialized to 0

#note: see Hamming loop in part 2 for extra comments on this type of loop / bit-checking
check_if_power_of_two_part_a:
	and $t2 $s0 $t1
	beqz $t2 check_if_power_of_two_part_b
	addi $t4 $t4 1 #tally++
	
check_if_power_of_two_part_b:
	sll $t1 $t1 1 #move the position by 1 bit (e.g. 00000000010)
	addi $t3 $t3 1 #loopcounter++
	blt $t3 11 check_if_power_of_two_part_a

	# after loop has been exited:
	#  if value at $s0 is a power of two, $t4 == 1
	bne $t4 1 check_multiples_of_eight
	addi $s2 $s2 1 #increment $s2 iff $s0 is a power of two
	
#the following three checks are inefficient (e.g., if something is a multiple of
# 8 it is also a multiple of 4 and 2 and does not need to undergo subsequent checks);
# but this works, though not ideally
check_multiples_of_eight:
	li $t1 8
	div $s0 $t1
	mfhi $t2 #$t2 = $s0%8; if $t2==0, is a multiple of 8
	bnez $t2 check_multiples_of_four
	addi $s5 $s5 1
	
check_multiples_of_four:
	li $t1 4
	div $s0 $t1
	mfhi $t2 #$t2 = $s0%4; if $t2==0, is a multiple of 4
	bnez $t2 check_multiples_of_two
	addi $s4 $s4 1

check_multiples_of_two:
	li $t1 2
	div $s0 $t1
	mfhi $t2 #$t2 = $s0%2; if $t2==0, is a multiple of 2
	bnez $t2 iterate_maybe
	addi $s3 $s3 1

iterate_maybe:
	bge $s0 64 random_num_loop
	bne $t4 1 random_num_loop
	#exit loop IFF $t4==1 (power of two) AND $s0 < 64

exit_loop_and_finish_part_3:
	la $a0 last_value_drawn
	li $v0 4
	syscall
	move $a0 $s0
	li $v0 1
	syscall
	la $a0 total_values
	li $v0 4
	syscall
	move $a0 $s1
	li $v0 1
	syscall
	la $a0 num_even
	li $v0 4
	syscall
	move $a0 $s3
	li $v0 1
	syscall
	la $a0 num_odd
	li $v0 4
	syscall
	sub $a0 $s1 $s3
	li $v0 1
	syscall
	la $a0 power_of_2
	li $v0 4
	syscall
	move $a0 $s2
	li $v0 1
	syscall
	la $a0 multiple_of_2
	li $v0 4
	syscall
	move $a0 $s3
	li $v0 1
	syscall
	la $a0 multiple_of_4
	li $v0 4
	syscall
	move $a0 $s4
	li $v0 1
	syscall
	la $a0 multiple_of_8
	li $v0 4
	syscall
	move $a0 $s5
	li $v0 1
	syscall
	b done
	

print_error:
	la $a0 Err_string
	li $v0 4
	syscall
	b done


done:
	li $v0 10
	syscall


.data
.align 2
numargs: .word '0'
arg1: .word '1'
arg2: .word '2'
arg3: .word '3'
Err_string: .asciiz "ARGUMENT ERROR"
#part2_string: .asciiz "part 2\n"
arg2_string: .asciiz "ARG2: "
arg3_string: .asciiz "\nARG3: "
space: .asciiz " "
hamming_string: .asciiz "\nHamming Distance: "
#part3_string: .asciiz "part 3\n"
last_value_drawn: .asciiz "Last value drawn: "
total_values: .asciiz "\nTotal values: "
num_even: .asciiz "\n# of Even: "
num_odd: .asciiz "\n# of Odd: "
power_of_2: .asciiz "\nPower of 2: "
multiple_of_2: .asciiz "\nMultiple of 2: "
multiple_of_4: .asciiz "\nMultiple of 4: "
multiple_of_8: .asciiz "\nMultiple of 8: "