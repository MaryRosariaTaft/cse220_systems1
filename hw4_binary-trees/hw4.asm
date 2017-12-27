##############################################################
# Homework #4
# name: Mary Taft
# sbuid: 110505413
##############################################################
.text

##############################
# PART 1 FUNCTIONS
##############################

#TODOTODOTODO
#takes a 2's-comp and writes it to file as a string of chars
#args:
	#a2 - file descriptor
	#a3 - a two's complement number
itof:
	addi $sp,$sp,-12
	sw $a0,0($sp)
	sw $a1,4($sp)
	sw $a2,8($sp)
	
	#set up syscall15 args
	move $a0,$a2 #$a0 = file descriptor
	la $a1,buffer
	li $a2,1 #$a2 = number of characters to write
	
	andi $t6,$a3,0x8000
	move $t7,$a3
	beqz $t6,ten_thousands
	
	#else, number is negative, so handle that
	#write the negative character
	li $v0,15 #setup syscall15
	li $t9,45 #hyphen character
	sb $t9,buffer
	syscall
	#convert the number to positive by taking its two's-comp
	not $t9,$a3
	andi $t9,$t9,0x0000ffff
	addi $t7,$t9,1
	
	#calculate each digit...
ten_thousands:
	li $v0,15 #setup syscall15
	li $t8,10000
	div $t7,$t8
	mflo $t9
	beqz $t9,thousands
	addi $t9,$t9,48
	sb $t9,buffer
	syscall
	
	
thousands:
	li $v0,15 #setup syscall15
	mfhi $t7
	li $t8,1000
	div $t7,$t8
	mflo $t9
	beqz $t9,hundreds
	addi $t9,$t9,48
	sb $t9,buffer
	syscall
	
	
hundreds:
	li $v0,15 #setup syscall15
	mfhi $t7
	li $t8,100
	div $t7,$t8
	mflo $t9
	beqz $t9,tens
	addi $t9,$t9,48
	sb $t9,buffer
	syscall

tens:
	li $v0,15 #setup syscall15
	mfhi $t7
	li $t8,10
	div $t7,$t8
	mflo $t9
	beqz $t9,ones
	addi $t9,$t9,48
	sb $t9,buffer
	syscall
	
ones:
	li $v0,15 #setup syscall15
	mfhi $t9
	addi $t9,$t9,48
	sb $t9,buffer
	syscall
	
newline:
	li $v0,15 #setup syscall15
	li $t9,10 #newline character
	sb $t9,buffer
	syscall

	#print--for testing
	#li $v0,1
	#move $a0,$a3
	#syscall
	
	lw $a0,0($sp)
	lw $a1,4($sp)
	lw $a2,8($sp)
	addi $sp,$sp,12

	jr $ra

#args:
	#$a0 - address of node being traversed
	#$a1 - base address of nodes array
	#$a2 - file descriptor of opened file
#return vals:
	#n/a
preorder:
	#stackpointerstuffs
	addi $sp,$sp,-8
	sw $ra,0($sp) #store $ra of the caller function
	sw $s0,4($sp) #store $s0 of the caller function
	
	#load itof's args & call itof
	#$a2, the file descriptor, is already loaded
	#$a3 should contain the 16-bit two's-comp num to write
	lw $a3,0($a0)
	andi $a3,$a3,0x0000ffff #the two's-comp num stored in current node
	jal itof #NOTE: itof preserves the argument registers
	
preorder_left:
	#call preorder on left subtree
	move $s0,$a0 #preserve the root node's address in $s0
	lw $a0,0($s0) #and proceed to make left child, if there is one, the new root for the recursive call
	andi $a0,$a0,0xff000000
	srl $a0,$a0,24 #$t0 now contains index of left child (or 255 if no left child)
	beq $a0,255,preorder_right
	li $t0,4
	mul $a0,$a0,$t0 #$t0 = left-child index * 4
	add $a0,$a0,$a1 #a0 = left-child index * 4 + base address
	jal preorder
	#upon return, $s0 should have been restored
	
preorder_right:
	#call preorder on right subtree
	lw $a0,0($s0) #current node's value
	andi $a0,$a0,0x00ff0000
	srl $a0,$a0,16 #$t0 now contains index of right child (or 255 if no right child)
	beq $a0,255,preorder_done
	li $t0,4
	mul $a0,$a0,$t0 #$t0 = left-child index * 4
	add $a0,$a0,$a1 #a0 = left-child index * 4 + base address
	jal preorder

preorder_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addi $sp,$sp,8
	jr $ra

##############################
# PART 2 FUNCTIONS
##############################

#args:
	#$a0 - base address of flags array
	#$a1 - max size
#return vals:
	#$v0 - index of the first free index in the flags array
		#range: [0, maxSize)
		#returns -1 if there is no free index
linear_search:
	li $t0,0
	
linear_search_loop:
	sub $t1,$a1,$t0 #$t1 = max size - current index
	beqz $t1,linear_search_failed #fail if reached end
	li $t1,8
	div $t0,$t1
	mflo $t1 #$t1 = byte offset = current index / 8 (integer division)
	add $t1,$t1,$a0 #$t1 = base + byte offset
	lb $t1,0($t1) #$t1 = 8-bit chunk of flags array
	mfhi $t2 #$t2 = bit offset
	beq $t2,0,linear_search_0
	beq $t2,1,linear_search_1
	beq $t2,2,linear_search_2
	beq $t2,3,linear_search_3
	beq $t2,4,linear_search_4
	beq $t2,5,linear_search_5
	beq $t2,6,linear_search_6
	beq $t2,7,linear_search_7

linear_search_0:
	andi $t1,$t1,1
	b linear_search_continue
	
linear_search_1:
	andi $t1,$t1,2
	b linear_search_continue
	
linear_search_2:
	andi $t1,$t1,4
	b linear_search_continue
	
linear_search_3:
	andi $t1,$t1,8
	b linear_search_continue
	
linear_search_4:
	andi $t1,$t1,16
	b linear_search_continue
	
linear_search_5:
	andi $t1,$t1,32
	b linear_search_continue
	
linear_search_6:
	andi $t1,$t1,64
	b linear_search_continue
	
linear_search_7:
	andi $t1,$t1,128
	b linear_search_continue
	
linear_search_continue:
	beqz $t1,linear_search_succeeded
	addi $t0,$t0,1
	b linear_search_loop
	
linear_search_succeeded:
	move $v0,$t0
	b linear_search_done
	
linear_search_failed:
	li $v0,-1

linear_search_done:
	jr $ra


#args:
	#$a0 - flags array
	#$a1 - index
	#$a2 - value
	#$a3 - max size
#return vals:
	#$v0 - 1 if success, 0 if index is out of range [0, max size)
set_flag:
	#failure conditions:
	bltz $a1,set_flag_failed
	bge $a1,$a3,set_flag_failed
	#else, set value as requested
	andi $a2,$a2,1 #$a2 = LSB of the input value
	li $t0,8
	div $a1,$t0
	mflo $t0 #$t0 = byte offset = current index / 8 (integer division)
	add $t2,$t0,$a0 #$t2 = base + byte offset
	lb $t0,0($t2) #$t0 = 8-bit chunk of flags array
	mfhi $t1 #$t1 = bit offset
	
	beqz $a2,set_flag_to_0
	b set_flag_to_1
	
set_flag_to_0:
	beq $t1,0,set_flag_to_0_bit_0
	beq $t1,1,set_flag_to_0_bit_1
	beq $t1,2,set_flag_to_0_bit_2
	beq $t1,3,set_flag_to_0_bit_3
	beq $t1,4,set_flag_to_0_bit_4
	beq $t1,5,set_flag_to_0_bit_5
	beq $t1,6,set_flag_to_0_bit_6
	beq $t1,7,set_flag_to_0_bit_7
	
set_flag_to_0_bit_0:
	andi $t0,$t0,1
	b set_flag_store_value

set_flag_to_0_bit_1:
	andi $t0,$t0,2
	b set_flag_store_value

set_flag_to_0_bit_2:
	andi $t0,$t0,4
	b set_flag_store_value

set_flag_to_0_bit_3:
	andi $t0,$t0,8
	b set_flag_store_value

set_flag_to_0_bit_4:
	andi $t0,$t0,16
	b set_flag_store_value

set_flag_to_0_bit_5:
	andi $t0,$t0,32
	b set_flag_store_value

set_flag_to_0_bit_6:
	andi $t0,$t0,64
	b set_flag_store_value

set_flag_to_0_bit_7:
	andi $t0,$t0,128
	b set_flag_store_value

set_flag_to_1:
	beq $t1,0,set_flag_to_1_bit_0
	beq $t1,1,set_flag_to_1_bit_1
	beq $t1,2,set_flag_to_1_bit_2
	beq $t1,3,set_flag_to_1_bit_3
	beq $t1,4,set_flag_to_1_bit_4
	beq $t1,5,set_flag_to_1_bit_5
	beq $t1,6,set_flag_to_1_bit_6
	beq $t1,7,set_flag_to_1_bit_7
	
set_flag_to_1_bit_0:
	ori $t0,$t0,1
	b set_flag_store_value
	
set_flag_to_1_bit_1:
	ori $t0,$t0,2
	b set_flag_store_value
	
set_flag_to_1_bit_2:
	ori $t0,$t0,4
	b set_flag_store_value
	
set_flag_to_1_bit_3:
	ori $t0,$t0,8
	b set_flag_store_value
	
set_flag_to_1_bit_4:
	ori $t0,$t0,16
	b set_flag_store_value
	
set_flag_to_1_bit_5:
	ori $t0,$t0,32
	b set_flag_store_value
	
set_flag_to_1_bit_6:
	ori $t0,$t0,64
	b set_flag_store_value
	
set_flag_to_1_bit_7:
	ori $t0,$t0,128
	b set_flag_store_value
	
set_flag_store_value:
	sb $t0,0($t2)

set_flag_succeeded:
	li $v0,1
	b set_flag_done

set_flag_failed:
	li $v0,0
	
set_flag_done:
	jr $ra


#RECURSIVE
#args:
	#$a0 - base address of nodes array
	#$a1 - current index
	#$a2 - 32-bit value to be added to the BST
#return vals:
	#$v0 - index of the parent-to-be of the node being inserted
	#$v1 - 0 if left child, 1 if right child
find_position:
to_signed_half_word:
	#convert 32-bit val to 16-bit signed two's-comp
	andi $a2,$a2,0x00ff #get the lower 16 bits
	andi $t0,$a2,0x80 #check the MSB of those lower 16 bits
	bnez $t0,one_extend
	b find_position_start

one_extend:
	ori $a2,$a2,0xff00
	
find_position_start:
	#now the proper value to be added to the BST should be stored in $a2
	
	#get node data at current index
	#$a0 - base address
	#$a1 - index
	li $t0,4
	mul $t0,$t0,$a1 #$t0 = byte offset = index * 4
	add $t0,$t0,$a0 #$t0 = base address + index * 4
	lw $t0,0($t0) #$t0 = node data at current index
	
	addi $sp,$sp,-8
	#save return register
	sw $ra,0($sp)
	#save caller's $s0 and move the just-extracted node data into $s0
	sw $s0,4($sp)
	move $s0,$t0
	
	#if value-to-be-added < current val, recurse left; else, right
	andi $t0,$s0,0x0000ffff #$t0 = two's-comp num stored in current node
	blt $a2,$t0,find_position_left
	b find_position_right
	
find_position_left:
	andi $t0,$s0,0xff000000
	srl $t0,$t0,24 #$t0 now contains index of left child
	#if reached leaf, add
	beq $t0,255,find_position_done_left
	#else, call function on left subtree
	move $a1,$t0
	jal find_position_start
	b find_position_done

find_position_right:
	andi $t0,$s0,0x00ff0000
	srl $t0,$t0,16 #$t0 now contains index of right child
	#if reached leaf, add
	beq $t0,255,find_position_done_right
	#else, call function on right subtree
	move $a1,$t0
	jal find_position_start
	b find_position_done

find_position_done_left:
	move $v0,$a1
	li $v1,0
	b find_position_done
	
find_position_done_right:
	move $v0,$a1
	li $v1,1
	b find_position_done
	
find_position_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addi $sp,$sp,8
	jr $ra

#args:
	#$a1 - root index
	#$t0 - base address of flags array
#return vals:
	#$v0 - some power of 2 if exists, 0 if not
#determines whether an index in the nodes array is a valid BST node (flag is 1)
node_exists:
	li $t2,8
	div $a1,$t2
	mflo $t2 #$t2 = byte offset = root index / 8 (integer division)
	add $t2,$t0,$t2 #$t2 = base + byte offset
	lb $t2,0($t2) #$t0 = 8-bit chunk of flags array
	mfhi $t3 #$t3 = bit offset
	beq $t3,0,node_exists_0
	beq $t3,1,node_exists_1
	beq $t3,2,node_exists_2
	beq $t3,3,node_exists_3
	beq $t3,4,node_exists_4
	beq $t3,5,node_exists_5
	beq $t3,6,node_exists_6
	beq $t3,7,node_exists_7
	
node_exists_0:
	andi $v0,$t2,1
	jr $ra

node_exists_1:
	andi $v0,$t2,2
	jr $ra

node_exists_2:
	andi $v0,$t2,4
	jr $ra

node_exists_3:
	andi $v0,$t2,8
	jr $ra

node_exists_4:
	andi $v0,$t2,16
	jr $ra

node_exists_5:
	andi $v0,$t2,32
	jr $ra

node_exists_6:
	andi $v0,$t2,64
	jr $ra

node_exists_7:
	andi $v0,$t2,128
	jr $ra


#args:
	#$a0 - base address of nodes array
	#$a1 - index of the root node
	#$a2 - value to be added to the BST
	#$a3 - index whereat said value should be added
	#lw $t0,4($sp) - base address of flags array
	#lb $t1,0($sp) - max size [1, 255]

#return vals:
	#$v0 - 1 if success, 0 if failure
add_node:
	lw $t0,4($sp) #base address of flags array
	lb $t1,0($sp) #max size of the BST
	
	addi $sp,$sp,-4
	sw $ra,0($sp)

	andi $a1,$a1,0x000f #lower 8 bits of root node index
	andi $a3,$a3,0x000f #lower 8 bits of new node index
	bge $a1,$t1,add_node_failed
	bge $a3,$t1,add_node_failed
	
	andi $a2,$a2,0x00ff #get the lower 16 bits
	andi $t2,$a2,0x80 #check the MSB of those lower 16 bits
	bnez $t2,one_extend_again
	b add_node_continue

one_extend_again:
	ori $a2,$a2,0xff00

add_node_continue:
	jal node_exists
	beqz $v0,add_node_new_root

	#store all of the argument values (except root index, b/c it's no longer needed)
	addi $sp,$sp,-20
	sw $a0,0($sp)
	sw $a2,4($sp)
	sb $a3,8($sp)
	sw $t0,12($sp)
	sw $t1,16($sp)
	
	jal find_position
	
	lw $a0,0($sp)
	lw $a2,4($sp)
	lb $a3,8($sp)
	lw $t0,12($sp)
	lw $t1,16($sp)
	addi $sp,$sp,20
	
	beqz $v1,add_node_on_left
	b add_node_on_right
	
add_node_on_left:
	li $t2,4
	mul $t2,$t2,$v0
	add $t2,$t2,$a0 #$t2 = base + offset which yields parent node
	lw $t3,0($t2) #$t3 = node val of parent
	andi $t3,$t3,0x00ffffff #clear left-child index of parent node
	sll $t4,$a3,24
	or $t3,$t3,$t4 #left-child index has been updated in parent node
	sw $t3,0($t2) #store said updated value back into nodes array
	b add_node_succeeded

add_node_on_right:
	li $t2,4
	mul $t2,$t2,$v0
	add $t2,$t2,$a0 #$t2 = base + offset which yields parent node
	lw $t3,0($t2) #$t3 = node val of parent
	andi $t3,$t3,0xff00ffff #clear left-child index of parent node
	sll $t4,$a3,16
	or $t3,$t3,$t4 #left-child index has been updated in parent node
	sw $t3,0($t2) #store said updated value back into nodes array
	b add_node_succeeded
	
add_node_new_root:
	move $a2,$a1
	
add_node_succeeded:
	move $t2,$a2 #move new value (i.e., value to store) into $t2
	ori $t2,$t2,0xffff0000 #and set left-child and right-child indexes to ff==255==null
	li $t3,4
	mul $t3,$t3,$a3
	add $t3,$t3,$a0 #$t3 = base + byte offset = base + index * 4
	sw $t2,0($t3) #store new value at calculated address
	li $v0,1
	
	move $a0,$t0
	move $a1,$a3
	li $a2,1
	move $a3,$t1
	jal set_flag
	b add_node_done
	
add_node_failed:
	li $v0,0
	
add_node_done:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

##############################
# PART 3 FUNCTIONS
##############################

#args:
	#$a0 - base address of nodes array
	#$a1 - index of current node
	#$a2 - child value
	#$a3 - child index
#return vals:
	#$v0 - index of the parent node, -1 if child node is not in tree OR child is root from the first call
	#$v1 - 0 if child node is left, 1 if right (don't care if no parent found)
get_parent:
	andi $a3,$a3,0x000f #get lower 8 bits of child index (unsigned)
	andi $a2,$a2,0x00ff #get lower 16 bits of child value
	andi $t0,$a2,0x80 #check the MSB of those lower 16 bits
	bnez $t0,one_extend_yet_again #sign-extend if necessary
	b get_parent_continue

one_extend_yet_again:
	ori $a2,$a2,0xff00
	
get_parent_continue:
	addi $sp,$sp,-8
	sw $ra,0($sp)
	sw $a1,4($sp)

	li $t0,4
	mul $t0,$t0,$a1
	add $t0,$t0,$a0 #$t0 = base + offset
	lw $t0,0($t0) #$t0 = stuff stored in node at current index
	andi $t1,$t0,0x0000ffff #$t1 = value of aforementioned node
	blt $a2,$t1,get_parent_left
	b get_parent_right
	
get_parent_left:
	andi $t1,$t0,0xff000000
	srl $t1,$t1,24 #$t1 = index of curren't left child
	beq $t1,255,get_parent_failed
	li $v1,0
	beq $t1,$a3,get_parent_succeeded
	move $a1,$t1
	jal get_parent_continue
	b get_parent_done

get_parent_right:
	andi $t1,$t0,0x00ff0000
	srl $t1,$t1,16 #$t1 = index of curren't right child
	beq $t1,255,get_parent_failed
	li $v1,1
	beq $t1,$a3,get_parent_succeeded
	move $a1,$t1
	jal get_parent_continue
	b get_parent_done
	
get_parent_succeeded:
	move $v0,$a1
	b get_parent_done
	
get_parent_failed:
	li $v0,-1
	
get_parent_done:
	lw $ra,0($sp)
	lw $a1,4($sp)
	addi $sp,$sp,8
	jr $ra

#args:
	#$a0 - base address of nodes array
	#$a1 - index of current node
#return vals:
	#$v0 - index of the first minimum value
	#$v1 - 1 if first minimum node is a leaf, 0 otherwise
find_min:
	li $t0,4
	mul $t0,$t0,$a1
	add $t0,$t0,$a0
	lw $t0,0($t0) #$t0 = data of current node
	andi $t1,$t0,0xff000000
	srl $t1,$t1,24 #$t1 = index of current node's left child
	
	beq $t1,255,find_min_done
	
	addi $sp,$sp,-8
	sw $ra,0($sp)
	sw $a1,4($sp)
	move $a1,$t1
	jal find_min
	lw $ra,0($sp)
	lw $a1,4($sp)
	addi $sp,$sp,8
	b find_min_not_leaf
	
find_min_done:
	move $v0,$a1 #return value $v0 = current index
	andi $t1,$t0,0x00ff0000
	srl $t1,$t1,16
	beq $t1,255,find_min_is_leaf
	li $v1,0
	b find_min_not_leaf
	
find_min_is_leaf:
	li $v1,1
	
find_min_not_leaf:
	jr $ra


#args:
	#$a0 - base address of nodes array
	#$a1 - index of root node
	#$a2 - index of the node to be deleted
	#$a3 - base address of flags array
	#$t0 - max size of BST / nodes/flags arrays
#return vals:
	#$v0 - 1 if success, 0 if failure
		#failure conditions: root-index or delete-index are
		#	out of range [0, max size)
		#	or, if in range, are invalid (flag 0)
delete_node:
	andi $a1,$a1,0x000f #lower 8 bits, unsigned
	andi $a2,$a2,0x000f #lower 8 bits, unsigned
	lb $t0,0($sp) #max size of the BST
	
	addi $sp,$sp,-24
	sw $s0,0($sp)
	sw $s1,4($sp)
	sw $s2,8($sp)
	sw $s3,12($sp)
	sw $s4,16($sp)
	sw $ra,20($sp)
	
	bge $a1,$t0,delete_node_failed #root index >= max size
	bge $a2,$t0,delete_node_failed #delete index >= max size

	move $s0,$a0
	move $s1,$a1
	move $s2,$a2
	move $s3,$a3
	move $s4,$t0
	
	move $t0,$s3
	jal node_exists
	beqz $v0,delete_node_failed
	move $a1,$s2
	jal node_exists
	beqz $v0,delete_node_failed
	
	li $t0,4
	mul $t0,$t0,$s2
	add $t0,$t0,$s0 #$t0 = address of node at delete index
	lw $t1,0($t0) #$t1 = value of node at delete index
	
	li $t3,0xffff0000
	and $t2,$t1,$t3
	beq $t2,$t3,delete_node_is_leaf
	
	li $t3,0xff000000
	and $t2,$t1,$t3
	beq $t2,$t3,delete_node_right_child_only
	
	li $t3,0x00ff0000
	and $t2,$t1,$t3
	beq $t2,$t3,delete_node_left_child_only
	
	b delete_node_two_children
	
delete_node_is_leaf:
	#load args for set_flag
	move $a0,$s3
	move $a1,$s2
	li $a2,0
	move $a3,$s4
	#save tmp regs for access after set_flag call
	addi $sp,$sp,-8
	sw $t0,0($sp)
	sw $t1,4($sp)
	#do the function call
	jal set_flag
	#restore temp regs
	lw $t0,0($sp)
	lw $t1,4($sp)
	addi $sp,$sp,8
	
	beq $s2,$s1,delete_node_succeeded
	
	#load args for get_parent
	move $a0,$s0
	move $a1,$s1
	andi $a2,$t1,0x0000ffff
	move $a3,$s2
	#function call
	jal get_parent
	
	li $t0,4
	mul $t0,$t0,$v0
	add $t0,$t0,$s0
	lw $t1,0($t0) #get nodes[parent_index]
	beqz $v1,delete_node_delete_left
	b delete_node_delete_right
	
delete_node_delete_left:
	ori $t1,$t1,0xff000000 #set left child to null
	sw $t1,0($t0) #store back into array
	b delete_node_succeeded

delete_node_delete_right:
	ori $t1,$t1,0x00ff0000 #set right child to null
	sw $t1,0($t0) #store back into array
	b delete_node_succeeded

delete_node_right_child_only:
	andi $t2,$t1,0x00ff0000 #$t2 = index of right child
	b delete_node_one_child

delete_node_left_child_only:
	andi $t2,$t1,0xff000000 #$t2 = index of left child
	b delete_node_one_child #implied

delete_node_one_child:
	beq $s1,$s2,delete_node_one_child_root
	
	#load args for get_parent
	move $a0,$s0
	move $a1,$s1
	andi $a2,$t1,0x0000ffff
	move $a3,$s2
	jal get_parent
	
	beqz $v1,oy_left
	b oy_right
	
oy_left:
	li $t0,4
	mul $t0,$t0,$v0
	add $t0,$t0,$s0 #$t0 = address of parent
	lw $t1,0($t0) #$t1 = parent node stuffs
	andi $t1,$t1,0x00ffffff #clear left child
	sll $t2,$t2,24
	or $t1,$t1,$t2 #insert new left child
	sw $t1,0($t0) #store back into array
	b vey

oy_right:
	li $t0,4
	mul $t0,$t0,$v0
	add $t0,$t0,$s0 #$t0 = address of parent
	lw $t1,0($t0) #$t1 = parent node stuffs
	andi $t1,$t1,0xff00ffff #clear right child
	sll $t2,$t2,16
	or $t1,$t1,$t2 #insert new right child
	sw $t1,0($t0) #store back into array
	b vey
	
vey:
	move $a0,$s3
	move $a1,$s2
	li $a2,0
	move $a3,$s4
	b delete_node_succeeded
	
delete_node_one_child_root:
	li $t3,4
	mul $t3,$t3,$t2
	add $t3,$t3,$s0
	lw $t3,0($t3) #child_node = nodes[child_index]
	sw $t3,0($t0) #nodes[delete_index] = child_node
	
	#load args for set_flag
	move $a0,$s3
	move $a1,$t2
	li $a2,0
	move $a3,$s4
	jal set_flag
	b delete_node_succeeded

delete_node_two_children:
	move $a0,$s0
	andi $a1,$t1,0x00ff0000
	srl $a1,$a1,16
	jal find_min
	addi $sp,$sp,-8
	sw $s5,0($sp)
	sw $s6,0($sp)
	move $s5,$v0 #min index
	move $s6,$v1 #min is leaf
	
	#load args for get_parent
	li $t4,4
	mul $t4,$t4,$s5
	add $t4,$t4,$s0 #$t4 = address of node with min index
	lw $t4,0($t4) #$t4 = node with min index
	
	move $a0,$s0
	move $a1,$s2
	andi $a2,$t4,0x0000ffff
	move $a3,$s5
	jal get_parent
	
	beq $s6,0,min_is_leaf
	b min_not_leaf
	
min_is_leaf:
	li $t4,4
	mul $t4,$t4,$v0
	add $t4,$t4,$s0 #$t4 = address of parent node
	lw $t5,0($t4) #$t5 = parent node
	beqz $v1,min_left_of_parent
	b min_right_of_parent
	
min_left_of_parent:
	#nodes[parentIndex].left = null
	ori $t5,$t5,0xff000000
	sw $t5,0($t4)
	b two_children_continue

min_right_of_parent:
	#nodes[parentIndex].right = null
	ori $t5,$t5,0x00ff0000
	sw $t5,0($t4)
	b two_children_continue

min_not_leaf:
	li $t4,4
	mul $t4,$t4,$v0
	add $t4,$t4,$s0 #$t4 = address of parent node
	lw $t5,0($t4) #$t5 = parent node

	li $t6,4
	mul $t6,$t6,$s5
	add $t6,$t6,$s0 #$t6 = address of min node
	lw $t7,0($t6) #$t7 = value of the min node
	andi $t7,$t7,0x00ff0000 #$t7 = right-child index shifted bleh

	beqz $v1,change_left_ref
	b change_right_ref
	
change_left_ref:
	#nodes[parentIndex].left = nodes[minIndex].right
	sll $t7,$t7,8 #put min node's right-child index into MSBs
	andi $t5,$t5,0x00ffffff
	or $t5,$t5,$t7
	sw $t5,0($t4)
	b two_children_continue

change_right_ref:
	#nodex[parentIndex].right = nodes[minIndex].right
	andi $t5,$t5,0xff00ffff
	or $t5,$t5,$t7
	sw $t5,0($t4)
	b two_children_continue

two_children_continue:
	#nodes[deleteIndex].value = nodes[minIndex].value
	li $t4,4
	mul $t4,$t4,$s5
	add $t4,$t4,$s0
	lw $t4,0($t4)
	andi $t4,$t4,0x0000ffff
	or $t1,$t1,$t4
	sw $t1,0($t0)

	#set_flag(flags,minIndex,0,maxSize) #TODO
	move $a0,$s3
	move $a1,$s5
	li $a2,0
	move $a3,$s4
	
	lw $s5,0($sp)
	lw $s6,4($sp)
	addi $sp,$sp,8
	b delete_node_succeeded

delete_node_succeeded:
	li $v0,1
	b delete_node_done
	
delete_node_failed:
	li $v0,0
	
delete_node_done:
	lw $s0,0($sp)
	lw $s1,4($sp)
	lw $s2,8($sp)
	lw $s3,12($sp)
	lw $s4,16($sp)
	lw $ra,20($sp)
	addi $sp,$sp,24
	jr $ra

##############################
# EXTRA CREDIT FUNCTION
##############################

add_random_nodes:
	jr $ra



#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary

#place any additional data declarations here

buffer: .byte 0