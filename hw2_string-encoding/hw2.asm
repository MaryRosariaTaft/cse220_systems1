##############################################################
# Homework #2
# name: Mary Taft
# sbuid: 110505413
##############################################################
.text

##############################
# PART 1 FUNCTIONS
##############################

#int atoui(char[] input)
# $a0 - char[] input: to be converted to int
# $v0 - int: the converted int
atoui:
	move $t0 $a0 #address of string is now stored in $t0
	li $t1 10 #algorithm requires multiplying by 10, so stick it here
	li $v0 0 #ans will go here; init to 0

atoui_loop:
	#get val of byte at counter/index
	lbu $t2 ($t0)
	#if null terminator, exit loop
	beqz $t2 exit_atoui
	#else, extract numerical val of char
	li $t4 48
	sub $t2 $t2 $t4
	#if byte is an invalid character, exit loop
	blt $t2 0 exit_atoui
	bgt $t2 9 exit_atoui
	#else, append to ans AND increment pointer by a byte AND loop (branch to self)
	mult $v0 $t1 #ans...
	mflo $v0 #...= 10*ans
	add $v0 $v0 $t2 #ans += new value
	addi $t0 $t0 1 #increment pointer
	b atoui_loop

exit_atoui:
	jr $ra
	

#(char[], int) uitoa(int value, char[] output, int outputSize)
# $a0 - int value: thing to be converted; must be > 0
# $a1 - char[] output: address where converted number will be stored
# $a2 - int outputSize: # bytes of output string
# $v0 - char[]: {output} if conversion failed; pointer to byte immediately following the last byte written otherwise
# $v1 - int: 0 if failed; 1 if successful
#NOTE: does NOT write a null-terminator
uitoa:
	move $v0 $a1
	li $v1 0
	blez $a0 exit_uitoa #return if value <= 0

uitoa_numdigits_loop_setup:
	move $t0 $a0 #value
	li $t1 0 #loop counter
	li $t2 10 #for division
	
uitoa_numdigits_loop:
	beqz $t0 continue_uitoa
	div $t0 $t2 #divide value by 10
	mflo $t0 #... then assign it
	addi $t1 $t1 1 #increment loop counter
	b uitoa_numdigits_loop

continue_uitoa:
	bgt $t1 $a2 exit_uitoa #if not enough space was allotted, return
	li $v1 1
	move $t0 $a0
	move $t3 $a1
	add $t3 $t3 $t1 #address += loop counter
	addi $t3 $t3 -1 #then decrease by 1 because of 0-indexing
	
#the following loop writes each digit of {value} to its corresponding index of the string {output}
#the loop works in reverse order: for example, given the {value} 723 and {output} address 0x000
# it will first write '3' to address 0x002
# then '2' to 0x001
# and finally '7' to 0x000
uitoa_write_string_loop:
	beqz $t1 exit_uitoa #exit once counter has decremented down to 0
	div $t0 $t2 #divide value by 10
	mflo $t0 #... then assign it
	mfhi $t4 #and put the remainder (rightmost digit) here
	addi $t4 $t4 48 #ascii value of the digit ('0' == 48, '1' == 49, etc.)
	sb $t4 ($t3)
	addi $t3 $t3 -1 #decrement string pointer
	addi $v0 $v0 1 #add 1 bye to address for every digit/char appended to output
	addi $t1 $t1 -1 #decrement counter
	b uitoa_write_string_loop
	
exit_uitoa:
	jr $ra

##############################
# PART 2 FUNCTIONS
##############################

#int decodedLength(char[] input, char runFlag)
# $a0 - char[] input: a properly-formatted run-length-encoded string
# $a1 - char runFlag: a single char which *should* be in the set !#$%^&* which indicates start of a run
# $v0 - int: length of the run
#NOTE: do NOT alter the contents of {input}
decodedLength:
	#saving registers is important!
	addi $sp $sp -16
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)

	li $s0 0 #default return val is 0

	move $s1 $a0 #make the address/pointer a variable s.t. can increment byte-by-byte
	lb $s2 ($a1) #set value of $t0 to the runFlag (the char at address ($a1))
	
	beq $s2 33 continue_decodedLength # !
	beq $s2 35 continue_decodedLength # #
	beq $s2 36 continue_decodedLength # $
	beq $s2 37 continue_decodedLength # %
	beq $s2 94 continue_decodedLength # ^
	beq $s2 38 continue_decodedLength # &
	beq $s2 42 continue_decodedLength # *
	beq $s2 64 continue_decodedLength # @
	b exit_decodedLength #exit if flag is invalid
	
continue_decodedLength:
	lb $t0 ($s1) #check if first byte is already a null terminator (i.e., run-length-encoded string is empty)
	beqz $t0 exit_decodedLength #if so, return 0
	
decodedLength_loop:
	lb $t0 ($s1) #put char @ current pointer location into $t0
	beqz $t0 account_for_null_terminator #exit loop if null terminator is reached
	beq $t0 $s2 encountered_flag #do stuffs if you hit a flag
	addi $s0 $s0 1 #else, you have a single alpha character, so add 1 to ans/length
	addi $s1 $s1 1 #advance the pointer by one byte (one char)
	b decodedLength_loop

encountered_flag:
	#do whatever
	addi $s1 $s1 2 #advance the pointer by 2 bytes
	#run atoui on ($a0)
	move $a0 $s1 #load input for atoui
	move $s3 $ra #save jump address
	jal atoui
	move $ra $s3 #restore jump address
	add $s0 $s0 $v0 #add result of atoui to ans/length
	#ASSUMPTION: no run is greater than 99 chars in length;
	# therefore, the decimal value will always be either 1 or 2 digits[/chars] in length
	bge $v0 10 extra_digit #advance pointer by 2 bytes/chars if length is >=10, or 2 digits/chars lon
	addi $s1 $s1 1 #else, just advance the pointer by 1 byte/char
	b decodedLength_loop	

extra_digit:
	addi $s1 $s1 2
	b decodedLength_loop

account_for_null_terminator:
	addi $s0 $s0 1 #for null terminator

exit_decodedLength:
	move $v0 $s0 #put return value in proper register
	#then restore save registers
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	addi $sp $sp 16 #reset stack pointer
	jr $ra #and jump back to main

#(char[], int) decodeRun(char letter, int runLength, char[] output)
# $a0 - char letter: letter to be run
# $a1 - int runLength: length of the run to be generated
# $a2 - char[] output: address whereat the run should be placed
# $v0 - char[]: {output} if failed; pointer to byte immediately following the last byte written otherwise
# $v1 - int: 1 if successful, 0 if failed
#NOTE: *no* null terminator
#NOTE: assume that enough memory has been set aside in {output} to store the run
decodeRun:
	lb $t0 ($a0) #letter to run
	move $t1 $a1 #length of run
	move $t2 $a2 #address of run
	
	blez $t1 decodeRun_failed #fail if runLength<=0
	blt $t0 65 decodeRun_failed #[0, 64] are non-alpha chars
	#[91,96] are non-alpha chars
	#should do this more efficiently but the tradeoff time to figure it out is not worthwhile as of now
	beq $t0 91 decodeRun_failed
	beq $t0 92 decodeRun_failed
	beq $t0 93 decodeRun_failed
	beq $t0 94 decodeRun_failed
	beq $t0 95 decodeRun_failed
	beq $t0 96 decodeRun_failed
	bgt $t0 122 decodeRun_failed #[122, ] are non-alpha chars
	
	li $v1 1 #params are valid!

decodeRun_loop:
	beqz $t1 exit_decodeRun
	sb $t0 ($t2) #write char to string
	addi $t2 $t2 1 #advance pointer
	move $v0 $t2 #and update return val
	addi $t1 $t1 -1 #decrement counter (runLength)
	b decodeRun_loop

decodeRun_failed:
	move $v0 $t2
	li $v1 0
	b exit_decodeRun

exit_decodeRun:
	jr $ra

#int runLengthDecode(char[] input, char[] output, int outputSize, char runFlag)
# $a0 - char[] input: run-length-encoded string; assumed to be properly formatted
# $a1 - char[] output: address whereat the expansion/decoding should be stored
# $a2 - int outputSize: # bytes allotted for the output string, *including* one byte for the null terminator; assumed to be positive
# $a3 - char runFlag: flag char; *not* assumed to be valid
# $v0 - 1 if successful, 0 otherwise
runLengthDecode:
	addi $sp $sp -24
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)
	sw $s4 16($sp)
	sw $s5 20($sp)
	
	move $s0 $a0 #input address
	move $s1 $a1 #output address
	move $s2 $a2 #output size
	lb $s3 ($a3) #flag char
	
	beq $s3 33 continue_runLengthDecode # !
	beq $s3 35 continue_runLengthDecode # #
	beq $s3 36 continue_runLengthDecode # $
	beq $s3 37 continue_runLengthDecode # %
	beq $s3 94 continue_runLengthDecode # ^
	beq $s3 38 continue_runLengthDecode # &
	beq $s3 42 continue_runLengthDecode # *
	beq $s3 64 continue_runLengthDecode # @
	
	li $v0 0 #flag is invalid
	b exit_runLengthDecode #therefore exit

continue_runLengthDecode:
	#call decodedLength
	move $a0 $s0 #input
	move $a1 $a3 #runFlag
	move $s4 $ra #save address of caller's register
	jal decodedLength
	move $ra $s4 #and restore it // now, $s4 is "free"
	move $s4 $v0 #put result (length of the string-to-be whence decoded) in $s4
	sge $v0 $s2 $s4 #if # bytes allotted > needed, success... (& skip over next line)
	beqz $v0 exit_runLengthDecode #if failure ($v0 == 0), exit
	
runLengthDecode_loop:
	#iterate through INPUT to dictate the loop behavior (e.g., when it terminates)
	#but make sure to properly update values for OUTPUT as output itself is generated
	
	lb $t0 ($s0) #put char @ current input-pointer location into $t0
	beqz $t0 add_null_terminator #exit loop if null terminator of input-string is reached
	
	#otherwise, keep going..  still have input to parse
	beq $t0 $s3 runLengthDecode_encountered_flag #do stuffs if you hit a flag
	#if it's not a flag, it's a single char!, so just plop it into the output-string
	sb $t0 ($s1)
	addi $s0 $s0 1 #move to next char in input
	addi $s1 $s1 1 #and set up pointer for next thing-to-be-written in output
	
	b runLengthDecode_loop #loop

runLengthDecode_encountered_flag:
	#$s0 += 1 (skip over flag)
	addi $s0 $s0 1
		
	#load args for decodeRun:
	#$a0 = 0($s0) //load {letter}
	move $s4 $s0 #but need $a0 for atoui, so keep in $s4 for now
	#
	#$s0 += 1 // advance input-pointer
	addi $s0 $s0 1
	#
	#$a1 = atoui($s0) //load {runLength} as an int
	move $a0 $s0 #load atoui arg
	move $s5 $ra
	jal atoui
	move $ra $s5 #note: $s5 is now "free"
	move $s5 $v0 #move result of atoui into $a1
	#s4 contains {letter} -> put in a0
	#s5 contains {runLength} -> put in a1; increment s0 [input-string] based on # digits
	#s1 contains {output} -> put in a2
	move $a0 $s4
	move $a1 $s5
	move $a2 $s1

	move $s2 $ra
	jal decodeRun
	move $ra $s2
	
	#advance pointers:

	#assign $s1 (output) to return value of decodeRun
	move $s1 $v0
	
	#$s0 (input) by 1 if runLength<10, by 2 if runLength>=10 (# digits)
	bge $s5 10 extra_digit_runLengthDecode #advance pointer by 2 bytes/chars if length is >=10, or 2 digits/chars lon
	addi $s0 $s0 1 #else, just advance the pointer by 1 byte/char
	b runLengthDecode_loop	

extra_digit_runLengthDecode:
	addi $s0 $s0 2
	b runLengthDecode_loop

add_null_terminator:
	sb $0 ($s1) #add null terminator to end of output string
	li $v0 1 #return success
	b exit_runLengthDecode
			
exit_runLengthDecode:
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	lw $s4 16($sp)
	lw $s5 20($sp)
	addi $sp $sp 24 #reset stack pointer
	
	jr $ra


##############################
# PART 3 FUNCTIONS
##############################

#int encodedLength(char[] input)
# $a0 - char[] input: pointer to the null-terminated string to be evaluated for encoding
# $v0 - int: length upon encoding
encodedLength:
	li $t0 383 #totally arbitrary char-comparison initialization
	li $t2 0 #number of repeated chars in a given sequence (sort of a counter variable)
	li $t3 0 #num bytes in total
	move $t9 $a0 #so as not to directly edit the argument
	
	lb $t1 ($t9) #if the very first byte is a null terminator (i.e., empty string input)..
	beqz $t1 exit_encodedLength_failed #return 0
	
encodedLength_loop:
	lb $t1 ($t9) #$t1 = byte currently being evaluated
	beqz $t1 new_letter #proceed to exit (but not immediately!) if hit null terminator
	
	bne $t1 $t0 new_letter #handle new letter
	#
	#otherwise, *this* letter {$t1} is the same as the previous {$t0}
	addi $t2 $t2 1
	
	addi $t9 $t9 1 #advance pointer by a byte
	b encodedLength_loop

new_letter:
	#(update $t0, add to $t3 based on $t2*, reset $t2, advance pointer $t9)

	move $t0 $t1

	#*if $t2 <= 3, add $t3 $t3 $t2
	# else (if $t2 > 3):
	#      if $t2 < 10, add 3 (flag + char + 1 digit)
	#      if $t2 >= 10, add 4 (flag + char + 2 digits)
	bgt $t2 3 actually_encoded
	add $t3 $t3 $t2 #not fancily encoded, just plopping chars as-is..

	li $t2 1
	addi $t9 $t9 1
	beqz $t0 exit_encodedLength
	b encodedLength_loop

actually_encoded:
	#do stuff
	#      if $t2 < 10, add 3 (flag + char + 1 digit)
	#      if $t2 >= 10, add 4 (flag + char + 2 digits)
	addi $t3 $t3 3
	li $t5 10
	sge $t4 $t2 $t5
	add $t3 $t3 $t4
	
	li $t2 1
	addi $t9 $t9 1
	beqz $t0 exit_encodedLength
	b encodedLength_loop
	
exit_encodedLength_failed:
	li $v0 0
	jr $ra
	
exit_encodedLength:
	addi $v0 $t3 1
	jr $ra

#(char[], int) encodeRun(char letter, int runLength, char[] output, char runFlag)
# $a0 - char letter: letter to encode
# $a1 - int runLength: length of the run
# $a2 - char[] output: location of result
# $a3 - char runFlag: flag with which to encode
# $v0 - char[]: {output} if letter is NON-alpha, if runFlag IS alpha, or runLength <= 0
#	OR, if successful, address immediately following last byte edited
# $v1 - 1 if successful, 0 otherwise
#NOTE: do *not* include a null terminator in the result
#precon: enough space has been allocated at {output} to store whatever may result from this function
encodeRun:
	addi $sp $sp -24
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)
	sw $s4 16($sp)
	sw $s5 20($sp)

	lb $s0 ($a0) #letter to encode
	move $s1 $a1 #length
	move $s2 $a2 #output pointer
	lb $s3 ($a3) #flag to use (if necessary)
	li $s4 0 #successful or not (defaults to fail)
	
	#EXIT IF {letter} $t0 is non-alpha
	blt $s0 65 exit_encodeRun #[0, 64] are non-alpha chars
	beq $s0 91 exit_encodeRun #[91,96] are non-alpha chars
	beq $s0 92 exit_encodeRun
	beq $s0 93 exit_encodeRun
	beq $s0 94 exit_encodeRun
	beq $s0 95 exit_encodeRun
	beq $s0 96 exit_encodeRun
	bgt $s0 122 exit_encodeRun #[122, ] are non-alpha chars

	#EXIT IF {length} $t1 <= 0
	blez $s1 exit_encodeRun
	
	#CONTINUE IF flag is valid...
	beq $s3 33 continue_e # !
	beq $s3 35 continue_e # #
	beq $s3 36 continue_e # $
	beq $s3 37 continue_e # %
	beq $s3 94 continue_e # ^
	beq $s3 38 continue_e # &
	beq $s3 42 continue_e # *
	beq $s3 64 continue_e # @
	
	#...BUT EXIT otherwise:
	b exit_encodeRun

continue_e:
	li $s4 1 #if we've gotten this far, success; just have actually produce the result now
	bgt $s1 3 use_flag_encoding
	#else, just write 1, 2, or 3 copies of the char into {output}
	#gonna do this horribly efficiently now.........
	beq $s1 1 one_char
	beq $s1 2 two_chars
	beq $s1 3 three_chars
	
one_char:
	sb $s0 0($s2)
	addi $s2 $s2 1
	b exit_encodeRun

two_chars:
	sb $s0 0($s2)
	sb $s0 1($s2)
	addi $s2 $s2 2
	b exit_encodeRun

three_chars:
	sb $s0 0($s2)
	sb $s0 1($s2)
	sb $s0 2($s2)
	addi $s2 $s2 3
	b exit_encodeRun
	
use_flag_encoding:
	#do whatever
	sb $s3 0($s2) #first char: flag
	sb $s0 1($s2) #second char: letter
	
	addi $s2 $s2 2 #advance the output pointer by 2 bytes
	
	#third and maybe fourth chars: length
	#use uitoa!
	move $a0 $s1
	move $a1 $s2
	blt $s1 10 fewer_than_ten
	b more_than_ten
	
fewer_than_ten:
	li $a2 1 #1 digit -> 1 byte
	b almostDone_encodeRun

more_than_ten:
	li $a2 2 #2 digits -> 2 bytes
	
almostDone_encodeRun:
	move $s5 $ra
	jal uitoa
	move $ra $s5
	move $s2 $v0
	
exit_encodeRun:
	move $v0 $s2
	move $v1 $s4
	
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	lw $s4 16($sp)
	lw $s5 20($sp)
	addi $sp $sp 24

	jr $ra

#int runLengthEncode(char[] input, char[] output, int outputSize, char runFlag)
# $a0 - char[] input: thing to be encoded
# $a1 - char[] output: place whereat it should be encoded
# $a2 - int outputSize: allotted space
# $a3 - char runFlag: flag to be used in encoding
# $v0 - int: 1 if successful, 0 otherwise
#NOTE: do not edit input
runLengthEncode:
	addi $sp $sp -32
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)
	sw $s4 16($sp)
	sw $s5 20($sp)
	sw $s6 24($sp)
	sw $s7 28($sp)

	move $s0 $a0 #input
	move $s1 $a1 #output
	lb $s2 ($a3) #flag
	
	li $s3 0 #return val: 0 if failed (this is the default)
	
	#fail case: not enough space was allotted; $s4 < $v0
	move $s4 $a2 #outputSize
	#check using encodedLength; arg0 is already set properly by coincidence
	move $s5 $ra
	jal encodedLength
	move $ra $s5
	blt $s4 $v0 exit_runLengthEncode
	
	#note: now $s4 and $s5 are "free"
	
	#check if flag is valid:
	beq $s2 33 continue_runLengthEncode # !
	beq $s2 35 continue_runLengthEncode # #
	beq $s2 36 continue_runLengthEncode # $
	beq $s2 37 continue_runLengthEncode # %
	beq $s2 94 continue_runLengthEncode # ^
	beq $s2 38 continue_runLengthEncode # &
	beq $s2 42 continue_runLengthEncode # *
	beq $s2 64 continue_runLengthEncode # @

	b exit_runLengthEncode #not valid, wa-wa-waaahhhahah...

continue_runLengthEncode:
	#move forward! yay.
	li $s3 1 #success!, excpet said success hasn't been implemented yet...
	
	
	#LAST BITS OF STUFF [[placeholder]]
	#iterate through the input string
	
	#when to terminate:
	# when hit null terminator
	
	#things to save:
	# (in $s4) previous char
	# (in $s5) char at the byte to which the pointer points
	# (in $s6) the number of occurrences (reset when a new char is found)
	
	li $s4 383 #ARBITRARY, non-alpha comparison value
	li $s6 0 #start off with 0 occurrences of any letter/char
	
runLengthEncode_loop:
	lb $s5 ($s0) #laod new byte into $s5
	beqz $s5 done_finally
	
	bne $s5 $s4 diff_letter_from_last #s4 (prev) not eq to $s5 (current)
	
	addi $s6 $s6 1 #add 1 to the number of occurrences of this letter
	addi $s0 $s0 1
	b runLengthEncode_loop
	
diff_letter_from_last: #use encodeRun
	addi $s0 $s0 -1
	move $a0 $s0
	move $a1 $s6
	move $a2 $s1
	#$a3 already contains pointer to flag
	move $s7 $ra
	jal encodeRun
	move $ra $s7
	
	#update things:
	addi $s0 $s0 1
	lb $s4 ($s0) #update the 'previous char' register
	addi $s0 $s0 1 #then advance the input pointer
	move $s1 $v0 #edit $s1 (output) via encodeRun's return value
	li $s6 1 #and reset the number of occurrences (of 'prev char') to 1 (since by virtue of visiting it, there is at least 1)
	b runLengthEncode_loop

done_finally:
	sb $0 ($s1) #add null terminator to the output

exit_runLengthEncode:
	move $v0 $s3
	
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	lw $s4 16($sp)
	lw $s5 20($sp)
	lw $s6 24($sp)
	lw $s7 28($sp)
	addi $sp $sp 32
	
	jr $ra


#################################################################
# Student-defined data section
#################################################################
.data
.align 2  # Align next items to word boundary

#Place all data declarations here
