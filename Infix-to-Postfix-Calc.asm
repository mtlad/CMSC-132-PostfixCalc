.data
input: .space 256
parenthesis_stack: .space 256
prompt: .asciiz "\n==========================================\nEnter expression: "
exit_string: .asciiz "exit" 
print_error: .asciiz "Syntax error. Try again"
invalid_input: .asciiz "Invalid input. Try again"

.text
	main_loop:
		la $a0, input
		li $a1, 256		# input buffer

	clear_input:
		sb $zero, ($a0)			# store null byte to current buffer location
		addi $a0, $a0, 1		# move next byte
		addi $a1, $a1, -1		# decrement buffer size
		bnez $a1, clear_input		# loop until buffer is cleared
		li $s7, 0			# reset state tracker # Status 
		# 0 = initially receive nothing

		la $s0, exit_string
		la $a0, prompt
		jal PrintString
		jal PromptString
		
		jal CheckExit
		bnez $v0, end_main_loop
		jal CheckInput
		beqz $v0, invalid_input_error
		
		la $t6, input
		la $t8, parenthesis_stack
		j first_level_validation
		li $s5, 0
		li $t7, 0
		li $s6, 0
		
		jal Level2Validation
		bnez $v0, first_level_validation_end
		
first_level_validation:
	lb $t7, 0($t6)
	beq $t7, 40, first_level_validation_storing
	beq $t7, 41, check_operator_before_closing
	addi $t6, $t6, 1
	addi $s5, $s5, 1
	beq $t7, '\0', first_level_validation_end
	beq $t7, '\n', first_level_validation_end
	beq $t7, 10, first_level_validation_end
	beq $t7, 0, first_level_validation_end
	b first_level_validation

check_operator_before_closing:
    lb $t9, -1($t6)      # Load the previous character
    beq $t9, '+', first_level_validation_end_with_error  # Check for operators
    beq $t9, '-', first_level_validation_end_with_error
    beq $t9, '*', first_level_validation_end_with_error
    beq $t9, '/', first_level_validation_end_with_error
    b first_level_validation_popping_1

first_level_validation_storing:
	sb $t7, 0($t8)
	addi $t6, $t6, 1
	addi $t8, $t8, 1
	addi $s5, $s5, 1
	addi $s6, $s6, 1		#stack_counter
	b first_level_validation

first_level_validation_popping_1:
 	beqz $s6, first_level_validation_end_with_error
	sub $t8, $t8, 1
	addi $s5, $s5, 1
	sub $s6, $s6, 1		#stack_counter
	addi $t6, $t6, 1
	b first_level_validation
	
first_level_validation_end_with_error:
	b error
	
first_level_validation_end:
		bgtz $s6, error
		
		li $s6, 0	 #clean
		sub $t6, $t6, $s5
		li $s5, 0
		
		
		jal postfix_start
		b main_loop
		
	error:
		#la $a0, print_error
		#jal PrintString
		li $v0, 4
		la $a0, print_error
		syscall
			
		li $s6, 0	#clean
		sub $t6, $t6, $s5
		li $s5, 0
		b main_loop

	end_main_loop:	
		jal main_exit

invalid_input_error:
	li $v0, 4
	la $a0, invalid_input
	syscall
	j main_loop

.data
	operators: .asciiz "+-*/"
	error_opr: .asciiz "  Syntax error. Try again"
.text
Level2Validation:
	la $t0, input
	
	check_expression:
    		lb $t1, 0($t0)         		# Load current character
    		beqz $t1, end_L2_vali	 	# If null terminator, end program
    		beq $t1, '\n',  error_out		# Skip newlines
		beq $t1, ' ', skip  		# Skip spaces
		
		li $t2, '0'
    		li $t3, '9'
    		blt $t1, $t2, check_operators 	# If less than '0', check operators/parentheses
    		ble $t1, $t3, skip 		# If between '0' and '9', valid
    		
    		check_operators:
			li $t2, '+'
			beq $t1, $t2, check_next_char
			li $t2, '-'
			beq $t1, $t2, check_next_char
			li $t2, '*'
			beq $t1, $t2, check_next_char
			li $t2, '/'
			beq $t1, $t2, check_next_char
			li $t2, '('
			beq $t1, $t2, skip
			li $t2, ')'
			beq $t1, $t2, skip
			
		check_next_char:
			lb $t2, 1($t0)         		# Load current character
    			beqz $t2, error_out	 	# If null terminator, end program
			beq $t2, ' ', skip 	# Skip spaces
		
			li $t3, '0'
    			li $t4, '9'
    			blt $t2, $t3, cnc_check_opr 	# If less than '0', check operators/parentheses
    			ble $t2, $t4, end_L2_vali 		# If between '0' and '9', valid
    		
    		cnc_check_opr:
			li $t3, '+'
			beq $t2, $t3, error_out
			li $t3, '-'
			beq $t2, $t3, check_after_sub
			li $t3, '*'
			beq $t2, $t3, error_out
			li $t3, '/'
			beq $t2, $t3, error_out
			li $t3, '('
			beq $t2, $t3, skip
			li $t3, ')'
			beq $t2, $t3, skip
		
		check_after_sub:
			lb $t3, 1($t0)         		# Load current character
    			beqz $t3, error_out	 	# If null terminator, end program
			beq $t3, ' ', skip_csub 	# Skip spaces
		
			li $t4, '0'
    			li $t5, '9'
    			blt $t3, $t4, error_out 	# If less than '0', check operators/parentheses
    			ble $t3, $t5, end_L2_vali 		# If between '0' and '9', valid
		
		skip:
    			# Move to the next character
    			addi $t0, $t0, 1
    			j check_expression
    		
    		skip_cnc:
    			# Move to the next character
    			addi $t0, $t0, 1
    			j check_next_char
    		
    		skip_csub:
    			# Move to the next character
    			addi $t0, $t0, 1
    			j check_after_sub

		error_out:
			li $t0, 0
    			li $t1, 0
    			li $t2, 0
    			li $t3, 0
    			li $t4, 0
    			li $t5, 0
    			li $t6, 0
    			
    			li $v0,1
    			jr $ra
    		
    		end_L2_vali:
    			li $t0, 0
    			li $t1, 0
    			li $t2, 0
    			li $t3, 0
    			li $t4, 0
    			li $t5, 0
    			li $t6, 0
    			
    			li $v0, 0
    			jr $ra
.text
PrintString:
	li $v0, 4
	syscall
	jr $ra

.text
main_exit:
	li $v0, 10
	syscall

.text
PromptString:
	li $v0, 8
	la $a0, input
	li $a1, 256
	syscall
	jr $ra

.text
CheckExit:
	la $t1, input
	la $t2, exit_string

	check_exit_loop:
		lb $a0, ($t1)				# load char on string input
		lb $a1, ($t2)				# load char on string exit
		beq $a0, '\n', check_exact_match 	# check if its input end
		beqz $a1, not_exit
		bne $a0, $a1, not_exit
		addi $t1, $t1, 1
		addi $t2, $t2, 1
		b check_exit_loop

	check_exact_match:
		beqz $a1, exit_check_exit

	not_exit:
		li $v0, 0
		jr $ra

	exit_check_exit:
		li $v0, 1
		jr $ra
.text
CheckInput:
	la $t0, input          # Load the address of the input string

	validate_loop:
		lb $t1, 0($t0)         # Load the current character
		beqz $t1, input_valid  # If null terminator, input is valid (end of string)
		beq $t1, '\n', move_next_char # Skip newlines
		beq $t1, ' ', move_next_char  # Skip spaces

    		li $t2, '0'
    		li $t3, '9'
    		blt $t1, $t2, check_operators_parentheses # If less than '0', check operators/parentheses
    		ble $t1, $t3, move_next_char # If between '0' and '9', valid

	check_operators_parentheses:
		li $t2, '+'
		beq $t1, $t2, move_next_char
		li $t2, '-'
		beq $t1, $t2, move_next_char
		li $t2, '*'
		beq $t1, $t2, move_next_char
		li $t2, '/'
		beq $t1, $t2, move_next_char
		li $t2, '('
		beq $t1, $t2, move_next_char
		li $t2, ')'
		beq $t1, $t2, move_next_char
		li $t2, '.'
		beq $t1, $t2, move_next_char
		j input_invalid
	
	move_next_char:
		addi $t0, $t0, 1       # Move to the next character
		j validate_loop         # Continue validation

	input_invalid:
		li $v0, 0              # Set v0 = 0 for invalid input
		jr $ra                 # Return

	input_valid:
    		li $v0, 1              # Set v0 = 1 for valid input
    		jr $ra                 # Return
				
.data
	postfix: .space 256                         # Space to store postfix expression
	stack: .space 256                           # Stack for operators
	div_zero_msg: .asciiz "\nError: Division by zero."
	infix_equation: .asciiz "Infix Equation: "
	postfix_equation: .asciiz "Postfix Equation: "
	e_result: .asciiz "\nResult: "
	newLine: .asciiz "\n"
.text
postfix_start:
	la $t0, input       	# Load address of infix expression
    	la $t1, postfix       	# Load address of postfix result
    	la $t2, stack         	# Load address of stack
start_checking:
	lb $t4, 0($t0)
	beqz $t4, process_end # End if null terminator

    	# Skip spaces
    	beq $t4, ' ', skip_space
    	beq $t4, '\n', process_end
    	#push digits to postfix stack
    	beq $t4, '0', push_2_postfix_stack
    	beq $t4, '1', push_2_postfix_stack
    	beq $t4, '2', push_2_postfix_stack
    	beq $t4, '3', push_2_postfix_stack
    	beq $t4, '4', push_2_postfix_stack
    	beq $t4, '5', push_2_postfix_stack
    	beq $t4, '6', push_2_postfix_stack
    	beq $t4, '7', push_2_postfix_stack
    	beq $t4, '8', push_2_postfix_stack
    	beq $t4, '9', push_2_postfix_stack
    	beq $t4, '*', check_top_priority_operator
    	beq $t4, '/', check_top_priority_operator
    	beq $t4, '-', check_if_negative
    	beq $t4, '+', check_lower_priority_operator
    	beq $t4, '(', push_2_operator_stack
    	beq $t4, ')', pop_until_open
    	beq $t4, '.', push_2_postfix_stack
    	
    	beq $t4, 10, end_conversion
    	j start_checking

push_2_postfix_stack:
	sb $t4, 0($t1)
	addi $t1, $t1, 1
	lb $t5, 1($t0)
	beq $t5, 32, add_space
	beq $t5, 40, add_space
	beq $t5, 41, add_space
	beq $t5, 42, add_space
	beq $t5, 43, add_space
	beq $t5, 45, add_space
	beq $t5, 47, add_space
	li $t5, 0		#clean
	addi $t0, $t0, 1
	b start_checking
	
add_space:
	li $t5, 32
	addi $t0, $t0, 1
	sb $t5, 0($t1)
	addi $t1, $t1, 1
	b start_checking

check_if_negative:
	lb $t5, 1($t0)
	beq $t5, '0', is_negative
	beq $t5, '1', is_negative
	beq $t5, '2', is_negative
	beq $t5, '3', is_negative
	beq $t5, '4', is_negative
	beq $t5, '5', is_negative
	beq $t5, '6', is_negative
	beq $t5, '7', is_negative
	beq $t5, '8', is_negative
	beq $t5, '9', is_negative
	li $t5,0
	j check_lower_priority_operator
	
is_negative:
	sb $t4, 0($t1)
	addi $t1, $t1, 1
	j next_char
	
check_top_priority_operator:
	lb $t5, -1($t2)
	beq $t5, 42, pop_operator_stack	#mul operator
	beq $t5, 47, pop_operator_stack	#div operator
	j push_2_operator_stack

check_lower_priority_operator:
	lb $t5, -1($t2)
	beq $t5, 42, pop_operator_stack	#mul operator
	beq $t5, 47, pop_operator_stack	#div operator
	beq $t5, 43, pop_operator_stack	#plus operator
	beq $t5, 45, pop_operator_stack	#minus operator
	j push_2_operator_stack


pop_operator_stack:
	sub $t2, $t2, 1       # Decrement stack pointer
    	lb $t5, 0($t2)        # Load top of stack
    	sb $t5, 0($t1)        # Append operator to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    	li $t8, 32            # ASCII for space
    	sb $t8, 0($t1)        # Append space to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    	
push_2_operator_stack:
	sb $t4, 0($t2)
	addi $t2, $t2, 1
	j next_char
	
pop_until_open:
    	sub $t2, $t2, 1       # Decrement stack pointer
    	lb $t5, 0($t2)        # Load top of stack
    	li $t6, 40            # ASCII for '('
    	beq $t5, $t6, next_char
    
   	sb $t5, 0($t1)        # Append operator to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    
    	li $t8, 32            # ASCII for space
    	sb $t8, 0($t1)        # Append space to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    	j pop_until_open

skip_space:							
next_char:
	addi $t0, $t0, 1
	j start_checking
	
process_end:
    	# Pop remaining operators from the stack
    	sub $t2, $t2, 1       # Decrement stack pointer
    	lb $t4, 0($t2)        # Load top of stack
    	beqz $t4, end_conversion         # If stack is empty, end
    	
    	li $t8, 32            # ASCII for space
    	sb $t8, 0($t1)        # Append space to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    	
    	sb $t4, 0($t1)        # Append operator to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer
    	li $t8, 32            # ASCII for space
    	sb $t8, 0($t1)        # Append space to postfix
    	addi $t1, $t1, 1      # Increment postfix pointer

    	j process_end
										
end_conversion:
	li $v0, 4
	la $a0, infix_equation
	syscall
	
	li $v0, 4
	la $a0, input
	syscall
	
	li $v0, 4
	la $a0, postfix_equation
	syscall
	
	li $v0, 4             # Print string syscall
    	la $a0, postfix       # Address of postfix result
    	syscall

main_postfix_result:
	#$f5 for temporary value
	#$f7 and $f6 for operands 1 and 2, respectively
	#currentMultiplier for parsing:
	li $v1, 1
	mtc1 $v1, $f1
	cvt.s.w $f1, $f1
	li $v1, 10 
	mtc1 $v1, $f2 
	cvt.s.w $f3,$f2 		#for decimals	
	cvt.s.w $f2,$f2 		#for whole numbers
	li $v1, 1
	mtc1 $v1, $f4
	cvt.s.w $f4, $f4
	li $v1, 0
	mtc1 $v1, $f30
	cvt.s.w $f30, $f30		
	
	la $t0, postfix
	#jal check_index
	
check_index:
	lb $t1, 0($t0)	#current index

	beq $t1, 10, exit
	beq $t1, 0, exit
	beq $t1, '*', multiplication
	beq $t1, '/', division
	beq $t1, '+', addition
	beq $t1, '-', negative
	beq $t1, '.', start_decimal1
	beq $t1, ' ', space_encountered
	beq $t1, '0', store_whole_numbers1
	beq $t1, '1', store_whole_numbers1
	beq $t1, '2', store_whole_numbers1
	beq $t1, '3', store_whole_numbers1
	beq $t1, '4', store_whole_numbers1
	beq $t1, '5', store_whole_numbers1
	beq $t1, '6', store_whole_numbers1
	beq $t1, '7', store_whole_numbers1
	beq $t1, '8', store_whole_numbers1
	beq $t1, '9', store_whole_numbers1
	
negative:
	addi $t0, $t0, 1 #go to next index
	lb $t1, 0($t0)
	beq $t1, ' ', subtraction
	beq $t1, 0, subtraction
	
	li $v1, -1
	mtc1 $v1, $f4
	cvt.s.w $f4, $f4


store_whole_numbers1:
	subi $t1, $t1, 48
	mtc1 $t1, $f5
	cvt.s.w $f5, $f5
	
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	
	beq $t1, '0', store_whole_numbers2
	beq $t1, '1', store_whole_numbers2
	beq $t1, '2', store_whole_numbers2
	beq $t1, '3', store_whole_numbers2
	beq $t1, '4', store_whole_numbers2
	beq $t1, '5', store_whole_numbers2
	beq $t1, '6', store_whole_numbers2
	beq $t1, '7', store_whole_numbers2
	beq $t1, '8', store_whole_numbers2
	beq $t1, '9', store_whole_numbers2
	beq $t1, '.', start_decimal1
	b end_storing_whole_numbers
	
store_whole_numbers2:
	mul.s $f5, $f5, $f2
	subi $t1, $t1, 48
	mtc1 $t1, $f6
	cvt.s.w $f6, $f6
	add.s $f5, $f5, $f6
	
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	
	beq $t1, '0', store_whole_numbers2
	beq $t1, '1', store_whole_numbers2
	beq $t1, '2', store_whole_numbers2
	beq $t1, '3', store_whole_numbers2
	beq $t1, '4', store_whole_numbers2
	beq $t1, '5', store_whole_numbers2
	beq $t1, '6', store_whole_numbers2
	beq $t1, '7', store_whole_numbers2
	beq $t1, '8', store_whole_numbers2
	beq $t1, '9', store_whole_numbers2
	
	b end_storing_whole_numbers
	
end_storing_whole_numbers:
	
	mul.s $f5, $f4, $f5
	
	addi $sp, $sp, -8
	s.s $f5, 0($sp)
	
	beq $t1, '.', start_decimal1
	
	li $v1, 1
	mtc1 $v1, $f4
	cvt.s.w $f4, $f4
	
	li $t9, 0
	mtc1 $t9, $f5
	cvt.s.w $f5, $f5			#clean $f5
	
	addi $t0, $t0, 1
	# storeeeeeeeeee please look at me
	j check_index
	
start_decimal1:
	addi $t0, $t0, 1

start_decimal2:
	lb $t1, 0($t0)
	subi $t1, $t1, 48
	mtc1 $t1, $f6
	cvt.s.w $f6, $f6
	div.s $f6, $f6, $f3
	mul.s $f3, $f3, $f2 
	add.s $f5, $f5, $f6
	
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	beq $t1, '0', start_decimal2
	beq $t1, '1', start_decimal2
	beq $t1, '2', start_decimal2
	beq $t1, '3', start_decimal2
	beq $t1, '4', start_decimal2
	beq $t1, '5', start_decimal2
	beq $t1, '6', start_decimal2
	beq $t1, '7', start_decimal2
	beq $t1, '8', start_decimal2
	beq $t1, '9', start_decimal2
	
	b end_decimal
	
end_decimal:
	mul.s $f5, $f4, $f5
	
	#addi $sp, $sp, -8
	s.s $f5, 0($sp)
	
	li $v1, 10 
	mtc1 $v1, $f2 
	cvt.s.w $f3,$f2 		#for decimals	
	cvt.s.w $f2,$f2 		#for whole 
	
	li $v1, 1
	mtc1 $v1, $f4
	cvt.s.w $f4, $f4
	
	li $t9, 0
	mtc1 $t9, $f5
	cvt.s.w $f5, $f5			#clean $f5
	
	addi $t0, $t0, 1
	# storeeeeeeeeee please look at me
	j check_index

multiplication:
	lwc1 $f8, 0($sp)
	
	addi $sp, $sp, 8
	lwc1 $f7, 0($sp)
	mul.s $f7, $f7, $f8
	s.s $f7, 0($sp)
	
	addi $t0, $t0, 1
	sub.s $f8, $f8, $f8
	sub.s $f7, $f7, $f7
	j check_index
division:
	lwc1 $f8, 0($sp)
	addi $sp, $sp, 8
	lwc1 $f7, 0($sp)
	
	c.eq.s 1, $f8, $f30
	bc1t 1, print_division_error
	div.s $f7, $f7, $f8
	s.s $f7, 0($sp)
	
	addi $t0, $t0, 1
	sub.s $f8, $f8, $f8
	sub.s $f7, $f7, $f7
	j check_index

print_division_error:
	li $v0, 4
	la $a0, div_zero_msg
	syscall
	
	j main_loop
	
subtraction:
	lwc1 $f8, 0($sp)
	
	addi $sp, $sp, 8
	lwc1 $f7, 0($sp)
	
	sub.s $f7, $f7, $f8
	
	s.s $f7, 0($sp)
	
	addi $t0, $t0, 1
	sub.s $f8, $f8, $f8
	sub.s $f7, $f7, $f7
	j check_index


addition:
	lwc1 $f8, 0($sp)
	
	addi $sp, $sp, 8
	lwc1 $f7, 0($sp)
	
	add.s $f7, $f7, $f8
	
	s.s $f7, 0($sp)
	
	addi $t0, $t0, 1
	sub.s $f8, $f8, $f8
	sub.s $f7, $f7, $f7

	j check_index

space_encountered: 
	addi $t0, $t0, 1
	b check_index

exit:
	li $v0, 4
	la $a0, e_result
	syscall
	
	li $v0, 2
	lwc1 $f12, 0($sp)
	syscall
	
	la $a0, postfix
	
	clear_postfix:
		sb $zero, ($a0)			# store null byte to current buffer location
		addi $a0, $a0, 1		# move next byte
		addi $a1, $a1, -1		# decrement buffer size
		bnez $a1, clear_postfix		# loop until buffer is cleared
	
	jr $ra