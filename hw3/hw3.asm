##############################################################
# Homework #3
# name: Mary Taft
# sbuid: 110505413
##############################################################
.text

##############################
# PART 1 FUNCTIONS
##############################

#params:
	#n/a
#return vals:
	#n/a
smiley:
	addi $sp,$sp,-4 #stack pointer yada yada
	sw $ra,0($sp) #callee-saved stuffs

	lw $t0,base_address #$t0 = base_address
	addi $t1,$t0,200 #$t1 = final_address

	move $t2,$t0 #$t2 = current_address (init to base_address)
	li $t3,'\0' #$t3 = ASCII_char (init to null char)
	li $t4,0x0f #$t4 = color_info (init to black bg, white fg)
	
smiley_set_defaults:
	beq $t2,$t1,smiley_draw_face #done if current byte has passed final byte
	sb $t3,0($t2) #store ASCII in lower byte
	sb $t4,1($t2) #store colors in upper byte
	addi $t2,$t2,2 #increment current address by 2 bytes == 1 half-word
	b smiley_set_defaults

smiley_draw_face:
	#load args for bomb, yellow bg, gray fg
	li $a2,'b'
	li $a3,0xb7
	#load indexes and draw 'em
	li $a0,2
	li $a1,3
	jal fill
	li $a0,3
	li $a1,3
	jal fill
	li $a0,2
	li $a1,6
	jal fill
	li $a0,3
	li $a1,6
	jal fill
	#args for exploded bomb, red bg, white fg
	li $a2,'e'
	li $a3,0x1f
	#and indexes
	li $a0,6
	li $a1,2
	jal fill
	li $a0,7
	li $a1,3
	jal fill
	li $a0,8
	li $a1,4
	jal fill
	li $a0,8
	li $a1,5
	jal fill
	li $a0,7
	li $a1,6
	jal fill
	li $a0,6
	li $a1,7
	jal fill

smiley_finish:
	lw $ra,0($sp) #callee no more!
	addi $sp,$sp,4 #reset stack pointer
	jr $ra #jumpjumpjump


#params:
	#$a0 - row#
	#$a1 - col#
	#$a2 - ASCII
	#$a3 - colors
#return vals:
	#$v0 - address of element being edited
fill:
	li $v0,10
	mul $v0,$v0,$a0 #$v0 = row*num_cols
	add $v0,$v0,$a1 #$v0 = row*num_cols+col
	li $t0,2
	mul $v0,$v0,$t0 #$v0 = element_size*(row*num_cols+col)
	lw $t0,base_address #$t0 = base_address
	add $v0,$v0,$t0 #$v0 = base_address + element_size*(row*num_cols+col)
	sb $a2,0($v0) #store ASCII in lower byte
	sb $a3,1($v0) #store colors in upper byte	
	jr $ra



##############################
# PART 2 FUNCTIONS
##############################

#params:
	#$a0 - name of the file to open
#return vals:
	#$v0 - return val of syscall13 (file descriptor of the opened file)
open_file:
	li $v0,13 #setup syscall13
	#arg0 for syscall13 == arg0 for open_file; no need to edit
	li $a1,0 #arg1 for syscall13; sets flag to read-only
	syscall
	#return val for open_file == return val for syscall13; no need to edit
	jr $ra

#params:
	#$a0 - file descriptor of the file to close
#return vals:
	#$v0 - return val of of syscall16
close_file:
	li $v0,16
	#arg0 for syscall16 == arg0 for close_file; no need to edit
	syscall
	#return val for close_file == return val for syscall16; no need to edit
	jr $ra

#params:
	#$a0 - file descriptor of the file to read
	#$a1 - array in which to store the data from the file
#return vals:
	#$v0 - 0 if success, -1 if failure
load_map:
	#stackpointerstuffs
	addi $sp,$sp,-24
	sw $ra,0($sp)
	sw $s0,4($sp) #int unpaired
	sw $s1,8($sp) #int prev_val
	sw $s7,12($sp) #file descriptor ($a0)
	sw $s6,16($sp) #cells array ($a1)
	sw $s5,20($sp) #a_coordinate_has_been_read
	
	sw $a1,cells_array_local
	
	#init the "variables":
	li $s0,-1 #int unpaired
		#-1 if an even number of values have been parsed
		#[0,9] if there's an unpaired value lingering
	li $s1,-1 #int prev_val
		#-1 if previous char was whitespace
		#[0,9] if previous char was ['0','9']
	move $s7,$a0 #save the file descriptor, b/c there's a nested function call
	move $s6,$a1 #save cells_array for the same reason
	li $s5,0 #1 if at least one coordinate has been provided
		#(0 until a numeric character is provided;
		#an empty/whitespace file will fail)
	

load_map_clear_cells_array_setup:
	move $t0,$a1 #$t0 = base_address
	addi $t1,$t0,100 #$t1 = final_address
	move $t2,$t0 #$t2 = current_address (init to base_address)

load_map_clear_cells_array_loop:
	beq $t2,$t1,load_map_read_file #done if current byte has passed final byte
	sb $0,0($t2) #store 0 in current byte
	addi $t2,$t2,1 #increment current_address by 1 byte
	b load_map_clear_cells_array_loop
	
load_map_read_file:
	li $v0,14
	move $a0,$s7
	la $a1,buffer #buffer address
	li $a2,1 #buffer size
	syscall #read 1 byte of file into buffer

	beqz $v0,load_map_done_reading #exit loop once end of file has been reached

	lb $t0,buffer #$t0 = byte which was read in from file
	#handle different values of aforementioned byte:
	#failure if ASCII val is greater than that of '9':
	bgt $t0,'9',load_map_failure
	#also failure if ASCII val if less than that of '0', but...
	#...first, check if it's [valid] whitespace:
	beq $t0,'\t',load_map_handle_whitespace #tab
	beq $t0,'\n',load_map_handle_whitespace #newline
	beq $t0,'\r',load_map_handle_whitespace #carriage return
	beq $t0,' ',load_map_handle_whitespace #space
	blt $t0,'0',load_map_failure
	#hurrah! if you're here, the value in buffer is in ['0','9'], so:

load_map_handle_numeric_char:
	bgtz $s1,load_map_failure #previous char wasn't whitespace or a leading 0
		#(that means there were two adjacent numeric chars)
	#else, previous char *was* whitespace/leadingzero, so set *this* to be prev_val
	li $s5,1 #at least one number has been read (use: check for empty file)
	lb $s1,buffer #prev_val = ASCII value in buffer (in range ['0','9'])
	li $t0,'0'
	sub $s1,$s1,$t0 #prev_val = numeric val in buffer (in range [0,9])
	b load_map_read_file #and loop
	
load_map_handle_whitespace:
	bltz $s1,load_map_read_file #last value was also whitespace,
		#so do nothing and loop
	bgez $s0,load_map_bombs_ahoy #process bomb coordinates
	#else, prev_val was the first of two coordinates. so:
	move $s0,$s1 #unpaired = prev_val
	li $s1,-1 #prev_val = -1 (indicating whitespace char)
	b load_map_read_file #loop

load_map_bombs_ahoy:
	move $a0,$s0 #row (#)
	move $a1,$s6 #cells_array
	move $a2,$s1 #col (#)
	jal bombs_ahoy #if there isn't already a bomb in (row, col),
		#(a) put one there
		#(b) increment # bombs of adjacent cells
		#note: if there *is* one there already (meaning
		# this is a duplicate), do nothing
	li $s0,-1 #unpaired = -1 (i.e., all coodinates so far have been paired)
	li $s1,-1 #pre_val = -1 (indicating whitespace char)
	b load_map_read_file

load_map_done_reading:
	beqz $s5,load_map_failure #the file was empty or all whitespace; invalid; fail
	beq $s1,-1,load_map_ended_with_whitespace #if the last char of the file was whitespace...
	b load_map_ended_with_a_number

load_map_ended_with_whitespace:
	bgez $s0,load_map_failure #e.g., "1_3_5_"; $s0 (unpaired) == 5
	b load_map_success #e.g., "1_3_5_6_"; $s0 (unpaired) == -1
	
load_map_ended_with_a_number:
	beq $s0,-1,load_map_failure #e.g., "1_3_5"; $s0 == -1
	move $a0,$s0 #row = unpaired_val
	move $a1,$s6 #cells array
	move $a2,$s1 #col = prev_val
	jal bombs_ahoy

load_map_success:
	li $v0,0
	b load_map_finish
	
load_map_failure:
	li $v0,-1

load_map_finish:
	#initialize the default cursor values (setup for gameplay)
	sw $0,cursor_row
	sw $0,cursor_col
	#stackpointerstuffs
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s7,12($sp)
	lw $s6,16($sp)
	lw $s5,20($sp)
	addi $sp,$sp,24
	jr $ra


#params:
	#$a0 - row
	#$a1 - array in which to store the data from the file (base address)
	#$a2 - col
#return vals:
	#n/a
bombs_ahoy:
	addi $sp,$sp,-4
	sw $ra 0($sp)

	#get index (byte #) of the arg-provided bomb & put in $t2
	li $t2,10
	mul $t2,$t2,$a0 #$t2 = row*num_cols
	add $t2,$t2,$a2 #$t2 = row*num_cols+col
	add $t2,$t2,$a1 #$t2 = base_address + element_size*(row*num_cols+col)
	
	#stick value of the desired byte into a temp reg
	lb $t0,0($t2)

	#check if its bit 5 is already set
	#if so, this is a duplicate, so return
	andi $t1,$t0,32 #32 == 0b00100000
	beq $t1,32,bombs_ahoy_return
	
	#else, set bomb_bit and write to memory...
	ori $t0,$t0,32
	sb $t0,0($t2)
	
	#...then increment num_adj of adjacent cells
	addi $a0,$a0,-1
	addi $a2,$a2,-1
	jal increment_adjacent #(i-1,j-1) top-left
	addi $a2,$a2,1
	jal increment_adjacent #(i-1,j-0) top-center
	addi $a2,$a2,1
	jal increment_adjacent #(i-1,j+1) top-right
	addi $a0,$a0,1
	jal increment_adjacent #(i-0,j+1) center-right
	addi $a2,$a2,-2
	jal increment_adjacent #(i-0,j-1) center-left
	addi $a0,$a0,1
	jal increment_adjacent #(i+1,j-1) bottom-left
	addi $a2,$a2,1
	jal increment_adjacent #(i+1,j-0) bottom-center
	addi $a2,$a2,1
	jal increment_adjacent #(i+1,j-1) bottom-right
	
bombs_ahoy_return:
	lw $ra 0($sp)
	addi $sp,$sp,4
	jr $ra
	
	
#params:
	#$a0 - row
	#$a1 - base address
	#$a2 - col
#return vals:
	#$v0 - 1 if incremented, 0 if ignored
	#(n/a here though, as I don't even use the return value for anything)
increment_adjacent:
	li $v0,0 #cases to ignore:
	bltz $a0,increment_adjacent_return
	bgt $a0,9,increment_adjacent_return
	bltz $a2,increment_adjacent_return
	bgt $a2,9,increment_adjacent_return
	
	li $v0,1 #increment the bits which indicate the number of adjacent bombs
	#get index:
	li $t0,10 #$t0 = num_cols
	mul $t0,$t0,$a0 #$t0 = row*num_cols
	add $t0,$t0,$a2 #$t0 = row*num_cols+col
	add $t0,$t0,$a1 #$t0 = base_address + element_size*(row*num_cols+col)
	#load byte:
	lb $t1,0($t0)
	#increment:
	addi $t1,$t1,1
	#store byte:
	sb $t1,0($t0)
	
increment_adjacent_return:
	jr $ra

##############################
# PART 3 FUNCTIONS
##############################

#params:
	#n/a
#return vals:
	#n/a
init_display:
	lw $t0,base_address #$t0 = base_address
	addi $t1,$t0,200 #$t1 = final_address

	move $t2,$t0 #$t2 = current_address (init to base_address)
	li $t3,'\0' #$t3 = ASCII_char (init to null char)
	li $t4,0x77 #$t4 = color_info (init to gray bg, gray fg)
	
init_display_loop:
	beq $t2,$t1,init_display_set_cursor #done if current byte has passed final byte
	sb $t3,0($t2) #store ASCII in lower byte
	sb $t4,1($t2) #store colors in upper byte
	addi $t2,$t2,2 #increment current address by 2 bytes == 1 half-word
	b init_display_loop

init_display_set_cursor:
	#set bg color of cursor position to yellow
	#hard-coding (0,0) as the cursor position is acceptable here because
	# this function is only called at the beginning of a new game; and
	# the default cursor location of a new game is always (0,0).
	li $t4,0xb7
	sb $t4,1($t0)

	jr $ra


#params:
	#$a0 - row
	#$a1 - col
	#$a2 - ASCII char
	#$a3 - fg color
	#lb $t0,0($sp) - bg color
#return vals:
	#$v0 - 0 if args (sans ASCII) are valid, -1 if invalid
set_cell:
	li $v0,0
	bltz $a0,set_cell_failure
	bgt $a0,9,set_cell_failure
	bltz $a1,set_cell_failure
	bgt $a1,9,set_cell_failure
	bltz $a3,set_cell_failure
	bgt $a3,15,set_cell_failure
	lb $t0,0($sp) #more args than there are arg registers
	bltz $t0,set_cell_failure
	bgt $t0,15,set_cell_failure
	
	#stackpointerthings
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	sll $t0,$t0,4 #put bg color in upper 4 bits
	add $a3,$a3,$t0 #then add the fg color s.t. it is in the lower 4 bits
	#note: args a0-a2 are the same as those of set_cell; no need to edit
	jal fill
	
	#stackstackstack (I want pancakes)
	lw $ra,0($sp)
	addi $sp,$sp,4

	b set_cell_finish
	
set_cell_failure:
	li $v0,-1

set_cell_finish:
	jr $ra

#params:
	#$a0 - int game_status (-1:lost,0:ongoing,1:won)
	#the following two are only relevant if $a0 == -1:
	#$a1 - cells array address
#return vals:
	#n/a
reveal_map:
	addi $sp,$sp,-16
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)

	beqz $a0,reveal_map_return
	bgtz $a0,reveal_map_won
	#else, lost the game
	
	move $s0,$a1 #base_address
	move $s1,$a1 #current_address (init to base_address)
	addi $s2,$s0,100 #final_address

reveal_map_lost:
	beq $s1,$s2,reveal_map_return #exit loop if all cells have been revealed
	
	#get row & col arguments based on array index
	sub $t0,$s1,$s0 #$t0 = current_address - base_address == array_index
	li $t1,10 #to be used in next calculation
	div $t0,$t1 #division will give us...
	mflo $a0 #quotient==row
	mfhi $a1 #remainder==col
	
	#get ASCII & fg & bg arguments based on info contained in cells_array
	#(adjust $a3, $a4, and addi $sp,$sp,-1 / sb $t0,0($sp) / ??addi $sp,$sp,1??)
	lb $t0,0($s1) #$t0 = 8-bit information thingy from cells_array
	andi $t1,$t0,16 #$t1 = 16 if flag, 0 if not flag
	bgtz $t1,reveal_map_handle_flag
	andi $t1,$t0,32 #$t1 = 32 if flag, 0 if not flag
	bgtz $t1,reveal_map_handle_bomb
	#else... cell should display num_adj (or nothing if num_adj==0)
	b reveal_map_handle_number
	
#t0 has bit info thing
#a2 = ascii to be displayed
#a3 = fg color
#stackthingy = bg color
reveal_map_handle_flag:
	li $a2,'f' #ASCII
	li $a3,0xc #fg color
	#if bomb (andi with 32),
		#bg==bright green(0xa)
	#else,
		#bg==bright red(0x9)
	andi $t1,$t0,32
	bgtz $t1,reveal_map_flag_correct
	b reveal_map_flag_incorrect
	
reveal_map_flag_correct:
	li $t1,0xa #bg
	addi $sp,$sp,-4
	sb $t1,0($sp)
	b reveal_map_set_cell

reveal_map_flag_incorrect:
	li $t1,0x9 #bg
	addi $sp,$sp,-4
	sb $t1,0($sp)
	b reveal_map_set_cell

reveal_map_handle_bomb: #UNFINISHED/todo/tmp
	#if this location == cursor location (in .data section),
		#exploded bomb:
		#ascii=='e'
		#fg==white(0xf)
		#bg==bright red(0x9)
	#else,
		#regular bomb:
		#ascii=='b'
		#fg==gray(0x7)
		#bg==black(0x0)
	
	lw $t1,cursor_row
	lw $t2,cursor_col
	sub $t1,$t1,$a0 #cursor_row - current_row; 0 if equal
	sub $t2,$t2,$a1 #cursor_col - current_col; 0 if equal
	add $t1,$t1,$t2 #sum of above; 0 if both are 0
	beqz $t1,reveal_map_handle_exploded_bomb
	
	li $a2,'b' #ASCII
	li $a3,0x7 #fg
	li $t1,0x0 #bg
	addi $sp,$sp,-4
	sb $t1,0($sp)
	
	b reveal_map_set_cell
	
reveal_map_handle_exploded_bomb:
	li $a2,'e'
	li $a3,0xf #fg
	li $t1,0x9 #bg
	addi $sp,$sp,-4
	sb $t1,0($sp)
	
	b reveal_map_set_cell

reveal_map_handle_number:
	#extract lower 4 bits (andi $t0 with 0b00001111) and add '0' to get ASCII
	andi $a2,$t0,15 #(==0b00001111)
	addi $a2,$a2,'0' #ASCII
	li $a3,0xd #fg
	li $t1,0x0 #bg
	addi $sp,$sp,-4
	sb $t1,0($sp)
	beq $a2,'0',reveal_map_do_not_display #special case for num_adj == 0
	b reveal_map_set_cell
	
reveal_map_do_not_display:
	li $a2,'\0'

reveal_map_set_cell:
	jal set_cell
	addi $sp,$sp,4 #reset stack pointer
	addi $s1,$s1,1 #increment
	b reveal_map_lost #and loop
	
reveal_map_won:
	jal smiley
	
reveal_map_return:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	addi $sp,$sp,16
	jr $ra


##############################
# PART 4 FUNCTIONS
##############################

#params:
	#$a0 - cells array == base_address
	#$a1 - action (see below)
#*list of actions:
	#WASD - arrows
	#'f' - toggle flag
	#'r' - "click" (reveal the cell)
#return vals:
	#v0 - 0 for a valid move, -1 for an invalid move
#*some valid things:
	#revealing a cell with a flag on it (ignore the flag, basically)
#*list of invalid moves:
	#moving beyond board edges
	#flagging an already-revealed cell
	#trying to reveal an already-revealed cell
#**note: 'r', when valid, will perform a function call to search_cells
#also yeah use set_cell here to change color of highlighted cell, toggle flags or, reveal cells
perform_action:
	addi $sp,$sp,-20
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)
	sw $s3,16($sp)

	move $s0,$a0 #base_address (cells_array)
	lw $s1,cursor_row #row #
	lw $s2,cursor_col #col #
	#s3 will be the resulting index
	
	#get index (byte # in cells_array) of the cursor & put it in $s3
	li $s3,10
	mul $s3,$s3,$s1 #row*num_cols
	add $s3,$s3,$s2 #row*num_cols+col
	add $s3,$s3,$s0 #base_address + element_size*(row*num_cols+col)
	
	#then stick the value of that byte into a temp reg
	lb $t0,0($s3)

	beq $a1,'f',perform_action_handle_f
	beq $a1,'F',perform_action_handle_f
	beq $a1,'r',perform_action_handle_r
	beq $a1,'R',perform_action_handle_r
	beq $a1,'w',perform_action_handle_w
	beq $a1,'W',perform_action_handle_w
	beq $a1,'a',perform_action_handle_a
	beq $a1,'A',perform_action_handle_a
	beq $a1,'s',perform_action_handle_s
	beq $a1,'S',perform_action_handle_s
	beq $a1,'d',perform_action_handle_d
	beq $a1,'D',perform_action_handle_d
	
perform_action_handle_w: #up
	addi $t1,$s1,-1
	bltz $t1,perform_action_failure
	move $t2,$s2
	b perform_action_move_cursor
	
perform_action_handle_a: #left
	addi $t2,$s2,-1
	bltz $t2,perform_action_failure
	move $t1,$s1
	b perform_action_move_cursor

perform_action_handle_s: #down
	addi $t1,$s1,1
	bgt $t1,9,perform_action_failure
	move $t2,$s2
	b perform_action_move_cursor

perform_action_handle_d: #right
	addi $t2,$s2,1
	bgt $t2,9,perform_action_failure
	move $t1,$s1
	b perform_action_move_cursor
	
perform_action_move_cursor:
	#agggghhhhh I didn't do the graphical stuff for this :'(
	#should be:
	#remove yellow bg from the current cursor location...
	#move $a0,$s1
	#move $a1,$s2
	#li $a2,??? #have to extract from MMIO or calculate from cells_array
	#li $a3,??? #maintain the foreground color
	#li $t0,??? #and set the background color to its default (rather than selected) color
	#addi $sp,$sp,-4
	#sb $t1,0($sp)
	#jal set_cell
	#addi $sp,$sp,4 #reset stack pointer

	#update .data things
	sw $t1,cursor_row
	sw $t2,cursor_col
	
	#... then apply yellow bg to the updated cursor location
	#move $a0,$t1
	#move $a1,$t2
	#li $a2,??? #again, figuring this (ASCII) out takes some effort
	#li $a3,??? #fg color is maintained
	#li $t0,0xb #set bg color to yellow
	#addi $sp,$sp,-4
	#sb $t1,0($sp)
	#jal set_cell
	#addi $sp,$sp,4 #reset stack pointer	
	
	b perform_action_success
	
perform_action_handle_f:
	#if revealed, error (andi w/ 0b01000000)
	andi $t1,$t0,64
	bgtz $t1,perform_action_failure

	#else,
	#invert(-not-) the flag bit (xor w/ 0b00010000)...
	xori $t0,$t0,16
	#...write it to memory...
	sb $t0,0($s3)
	#...and update graphical display accordingly
	andi $t0,$t0,16 #0 if flag is cleared, 1 if flag is set
	beqz $t0,perform_action_toggle_flag_off
	#else continue onto _toggle_flag_on
	
perform_action_toggle_flag_on:
	move $a0,$s1
	move $a1,$s2
	li $a2,'f'
	li $a3,0xc
	li $t0,0x7
	addi $sp,$sp,-4
	sb $t1,0($sp)
	jal set_cell
	addi $sp,$sp,4 #reset stack pointer
	b perform_action_success
	
perform_action_toggle_flag_off:
	move $a0,$s1
	move $a1,$s2
	li $a2,'\0'
	li $a3,0xf
	li $t0,0x0
	addi $sp,$sp,-4
	sb $t1,0($sp)
	jal set_cell
	addi $sp,$sp,4 #reset stack pointer
	b perform_action_success
		
perform_action_handle_r:
	#if revealed, error (andi w/ 0b01000000)
	andi $t1,$t0,64
	bgtz $t1,perform_action_failure

	#if flag, remove flag and reveal
	andi $t1,$t0,16
	bgtz $t1,perform_action_remove_flag

	#else, just reveal
	b perform_action_reveal
	
perform_action_remove_flag:
	#invert(-not-) the flag bit (xor w/ 0b00010000)
	xori $t0,$t0,16
	#and just continue onto perform_action_reveal
	
perform_action_reveal:
	ori $t0,$t0,64 #set revealed bit
	sb $t0,0($s3) #then write to cells_array
	move $a0,$s0
	move $a1,$s1
	move $a2,$s2
	jal search_cells
	#and just continue onto perform_action_success
	
perform_action_success:
	li $v0,0
	b perform_action_return
	
perform_action_failure:
	li $v0,-1

perform_action_return:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	lw $s3,16($sp)
	addi $sp,$sp,20

	jr $ra

game_status:
	#O, sorrow!
	li $v0, -200
	jr $ra

##############################
# PART 5 FUNCTIONS
##############################

search_cells:
	#O, agony!
	jr $ra


#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1
#place any additional data declarations here
base_address: .word 0xffff0000 #base address of MMIO
element_size: .word 2 #size of element in MMIO
buffer: .space 1 #buffer for reading map files into program
.align 2
cells_array_local: .space 4