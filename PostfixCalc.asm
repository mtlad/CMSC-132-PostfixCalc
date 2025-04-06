.data
	input_msg: .asciiz "\n==========================================\nEnter expression: "
	exit_str: .asciiz "exit"
	error_msg: .asciiz "Invalid input. Try again\n"
	ans_msg  : .asciiz "Result: "
	input: .space 256
.text
	main:
		li $v0, 4
		la $a0, input_msg
		syscall

		li $v0, 8
		la $a0, input
		li $a1, 256
		syscall
		
		jal CheckExit
		bnez $v0, main_exit

		la $s1, input
		

		li $t1, 0
		
		addi $t0, $sp, -4

		loop:
			lb $t3, ($s1)

			beq $t3, 10, end
			beq $t3, 0, end
			
			beq $t3, '\n', move_next_char # Skip newlines
			beq $t3, ' ', move_next_char  # Skip spaces

			addi $s1, $s1, 1

			beq $t3, 42, multiply

			beq $t3, 43, addition

			beq $t3, 45, subtract

			blt $t3, 48, error
			bgt $t3, 57, error

			addi $t3, $t3, -48
			jal numeral

		end:
			bne $sp, $t0, error 

			li $v0, 4
			la $a0, ans_msg
			syscall

			li $v0, 1
			move $a0, $t1
			syscall
			
			li $v0, 11
			la $a0, '\n'
			syscall

			addi $sp, $t0, 4 

			j main
		numeral:
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			
			move $t1, $t3

			jal loop

		multiply:
			jal load_values_for_operator
			mul $t1, $t2, $t1

			jal loop

		addition:
			jal load_values_for_operator
			add $t1, $t2, $t1
			
			jal loop

		subtract:
			jal load_values_for_operator
			sub $t1, $t2, $t1
			
			jal loop
		
		load_values_for_operator: 
			beq $sp, $t0, error
			lw $t2, 0($sp)
			addi $sp, $sp, 4
			jr $ra

		error:
			li $v0, 4
			la $a0, error_msg
			syscall

			addi $sp, $t0, 4 

			j main
		
		move_next_char:
			addi $s1, $s1, 1       # Move to the next character
			j loop         # Continue validation
		
			
		CheckExit:
			la $t1, input
			la $t2, exit_str

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
		
		main_exit:
			li $v0, 10
			syscall
			
