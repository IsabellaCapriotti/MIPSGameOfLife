# Isabella Capriotti
# Assignment #13
# CS 218 Section 1001 
# Date Last Modified: 11/20/2020

#; Implements Conway's Game of Life on a wraparound board

.data
#;	System Service Codes
	SYSTEM_EXIT = 10
	SYSTEM_PRINT_INTEGER = 1
	SYSTEM_PRINT_STRING = 4
	SYSTEM_READ_INTEGER = 5
	
#;	Board Parameters
	MAXIMUM_WIDTH = 80
	MINIMUM_WIDTH = 5
	MAXIMUM_HEIGHT = 40
	MINIMUM_HEIGHT = 5
	MINIMUM_GENERATIONS = 1
	WORD_SIZE = 4
	gameBoard: .space MAXIMUM_WIDTH * MAXIMUM_HEIGHT * WORD_SIZE
	
#;	Strings
	heightPrompt: .asciiz "Board Height: "
	widthPrompt: .asciiz "Board Width: "
	generationsPrompt: .asciiz "Generations to Simulate: "
	errorWidth: .asciiz "Board width must be between 5 and 80.\n"
	errorHeight: .asciiz "Board height must be between 5 and 40.\n"
	errorGenerations: .asciiz "Generation count must be at least 1.\n"
	initialGenerationLabel: .asciiz "Initial Generation\n"
	generationLabel: .asciiz "Generation #"
	newLine: .asciiz "\n"
	livingCell: .asciiz "¤"
	deadCell: .asciiz "•"

#	User-specified game parameters
	gameBoardWidth: .word 0
	gameBoardHeight: .word 0 
	numGenerations: .word 0 

	
.text
.globl main
.ent main
main:
#;	Ask for width of gameboard
	
	getGameBoardWidth:

		#Print prompt
		li $v0, SYSTEM_PRINT_STRING
		la $a0, widthPrompt
		syscall

		# Get integer width in variable and $v0
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, gameBoardWidth 

		#;	Check that width is within specified bounds
		li $t0, MINIMUM_WIDTH
		bge $v0, $t0, widthAboveMinimum
			# Print error and prompt again if width below minimum
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorWidth
			syscall
			
			j getGameBoardWidth
		
		widthAboveMinimum: 
		li $t0, MAXIMUM_WIDTH
		ble $v0, $t0, getGameBoardHeight
			# Print error and prompt again if width above maximum
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorWidth
			syscall

			j getGameBoardWidth

#;	Ask for height of gameboard
	getGameBoardHeight:

		#Print prompt
		li $v0, SYSTEM_PRINT_STRING
		la $a0, heightPrompt
		syscall

		# Get integer height in variable and $v0
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, gameBoardHeight

		#;	Check that height is within specified bounds
		li $t0, MINIMUM_HEIGHT
		bge $v0, $t0, heightAboveMinimum
			# Print error and prompt again if height below minimum
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorHeight
			syscall
			
			j getGameBoardHeight
		
		heightAboveMinimum: 
		li $t0, MAXIMUM_HEIGHT
		ble $v0, $t0, initBoard
			# Print error and prompt again if height above maximum
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorHeight
			syscall

			j getGameBoardHeight


#;	Initialize Board Elements to 0
	initBoard: 

		# Get address of board in $t0
		la $t0, gameBoard
		# Initialize loop counter in $t1 to total # of elements
		lw $t1, gameBoardWidth
		lw $t2, gameBoardHeight
		mul $t1, $t1, $t2

		# Load 0 into $t2 for easy access
		li $t2, 0

		initBoardLoop: 
			
			# Move zero into current array address
			sw $t2, ($t0)
			# Increment array address
			add $t0, 4
			# Decrement loop counter
			sub $t1, 1

		# Check looping condition
		bnez $t1, initBoardLoop


#;	Insert Glider at 2,2
	la $a0, gameBoard
	lw $a1, gameBoardWidth
	li $a2, 2
	li $a3, 2
	jal insertGlider
	
#;	Ask for generations to calculate
	getGenerations: 

		# Print prompt
		li $v0, SYSTEM_PRINT_STRING
		la $a0, generationsPrompt
		syscall

		# Get integer in $v0 and numGenerations variable
		li $v0, SYSTEM_READ_INTEGER
		syscall
		sw $v0, numGenerations

		#;	Ensure # of generations is positive
		bgtz $v0, printInitBoard
			# If not positive, print error message and prompt again 
			li $v0, SYSTEM_PRINT_STRING
			la $a0, errorGenerations
			syscall

			j getGenerations

#;	Print Initial Board
	printInitBoard: 

		li $v0, SYSTEM_PRINT_STRING
		la $a0, initialGenerationLabel
		syscall
		
		la $a0, gameBoard
		lw $a1, gameBoardWidth
		lw $a2, gameBoardHeight
		jal printGameBoard


#;	For each generation:
#;		Play 1 Turn
#;		Print Generation Label
#;		Print Board

	# Initialize loop counter to number of generations
	lw $s0, numGenerations

	# Initialize generations printed counter to 1
	li $s1, 1

	gameplayLoop: 

		# Play turn 
		la $a0, gameBoard
		lw $a1, gameBoardWidth
		lw $a2, gameBoardHeight
		jal playTurn

		# Print label and generation number
		li $v0, SYSTEM_PRINT_STRING
		la $a0, generationLabel
		syscall

		li $v0, SYSTEM_PRINT_INTEGER
		move $a0, $s1
		syscall

		li $v0, SYSTEM_PRINT_STRING
		la $a0, newLine
		syscall

		# Print board
		la $a0, gameBoard
		lw $a1, gameBoardWidth
		lw $a2, gameBoardHeight
		jal printGameBoard

		# Decrement loop counter, increment generations printed counter
		subu $s0, $s0, 1
		addu $s1, $s1, 1

	# Check looping condition
	bnez $s0, gameplayLoop 

	
	endProgram:
	li $v0, SYSTEM_EXIT
	syscall
.end main

#;  Insert Glider Pattern
#;	••¤
#;	¤•¤
#;	•¤¤
#;	0,0 is in the top left of the gameboard
#;	Assume all cells are dead in the 3x3 space to start with.
#;	Argument 1: Address of Game Board
#;	Argument 2: Width of Game Board
#;	Argument 3: X Position of Top Left Square of Glider "•"
#;	Argument 4: Y Position of Top Left Square of Glider "•"
.globl insertGlider
.ent insertGlider
insertGlider:

	# Initialize temp indeces in $t2 (X) and $t3 (Y)
	move $t2, $a2
	move $t3, $a3

	# Initialize temp address in $t0
	move $t0, $a0 

	# Load 1 into $t4 for easy access
	li $t4, 1

	# Living cell #1 ([y][x+2]
	# Adjust index
	addu $t2, $t2, 2

	# Calculate offset
	mul $t1, $t3, $a1
	addu $t1, $t1, $t2
	mul $t1, $t1, WORD_SIZE
	addu $t0, $t0, $t1

	# Store value
	sw $t4, ($t0)


	# Living cell #2 ([y+1][x])
	# Reinitialize
	move $t2, $a2
	move $t3, $a3
	move $t0, $a0 

	# Adjust index
	addu $t3, 1

	# Calculate offset
	mul $t1, $t3, $a1
	addu $t1, $t1, $t2
	mul $t1, $t1, WORD_SIZE
	addu $t0, $t0, $t1

	# Store value
	sw $t4, ($t0)


	# Living cell #3 ([y+1][x+2])
	# Reinitialize
	move $t2, $a2
	move $t3, $a3
	move $t0, $a0 

	# Adjust index
	addu $t3, 1
	addu $t2, 2

	# Calculate offset
	mul $t1, $t3, $a1
	addu $t1, $t1, $t2
	mul $t1, $t1, WORD_SIZE
	addu $t0, $t0, $t1

	# Store value
	sw $t4, ($t0)


	# Living cell #4 ([y+2][x+1])
	# Reinitialize
	move $t2, $a2
	move $t3, $a3
	move $t0, $a0 

	# Adjust index
	addu $t3, 2
	addu $t2, 1

	# Calculate offset
	mul $t1, $t3, $a1
	addu $t1, $t1, $t2
	mul $t1, $t1, WORD_SIZE
	addu $t0, $t0, $t1

	# Store value
	sw $t4, ($t0)


	# Living cell #5 ([y+2][x+2])
	# Reinitialize
	move $t2, $a2
	move $t3, $a3
	move $t0, $a0 

	# Adjust index
	addu $t3, 2
	addu $t2, 2

	# Calculate offset
	mul $t1, $t3, $a1
	addu $t1, $t1, $t2
	mul $t1, $t1, WORD_SIZE
	addu $t0, $t0, $t1

	# Store value
	sw $t4, ($t0)

	jr $ra
.end insertGlider

#;	Updates the state of the gameboard
#;	For each Cell:
#;	Living: 2-3 Living Neighbors -> Stay Alive, otherwise Change to Dead
#;	Dead: Exactly 3 Living Neighbors -> Change to Alive 
#;	Cell States:
#;		0: Currently Dead, Stay Dead (00b)
#;		1: Currently Living, Change to Dead (01b)
#;		2: Currently Dead, Change to Living (10b)
#;		3: Currently Living, Stay Living (11b)
#;	Right Bit: Current State
#;	Left Bit: Next State
#;	All cells must maintain their current state until all next states have been determined.
#;	Argument 1: Address of Game Board
#;	Argument 2: Width of Game Board
#;	Argument 3: Height of Game Board

#;		Count the number of living neighbors (including diagonals)
		#;			The board wraps around, use remainder to find wrapped indice
		#;			Start each width/height register value offset by the size of the board
		#;				i.e. currentWidth = width instead of 0
		#;		Use the remainder instruction to extract current state
		#;		Update cell state
		#;			if cell is currently alive with 2-3 neighbors, change next bit to alive
		#;			if cell is currently dead with exactly 3 neighbors, change next bit to alive

		#;	For each cell on the gameboard:
		#;		Update each cell to its new state by dividing by 2
.globl playTurn
.ent playTurn
playTurn:

	# Initialize row loop counter in $t0 to height 
	move $t0, $a2
	# Initialize column loop counter in $t8 to width
	move $t8, $a1

	# Running X and Y in $t2 and $t3
	li $t2, 0 
	li $t3, 0 

	cellStateRowLoop:
		cellStateColumnLoop:  
			# Initialize living neighbor count in $t4
			li $t4, 0 

			upperLeftDiagonal: 
				# Upper left diagonal [y-1][x-1]
				# Update temp X and Y in $t5 and $t6
				sub $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				sub $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, adjacentAbove
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			adjacentAbove:
				# Adjacent above [y-1][x]
				# Update temp X and Y in $t5 and $t6
				move $t5, $t2

				sub $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, upperRightDiagonal
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			upperRightDiagonal: 
				# Upper right diagonal [y-1][x+1]
				# Update temp X and Y in $t5 and $t6
				add $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				sub $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, adjacentLeft
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			adjacentLeft: 
				# Adjacent left [y][x-1]
				# Update temp X and Y in $t5 and $t6
				sub $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				move $t6, $t3

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, adjacentRight
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			adjacentRight:
				# Adjacent right [y][x+1] 
				# Update temp X and Y in $t5 and $t6
				add $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				move $t6, $t3

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, bottomLeftDiagonal
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			bottomLeftDiagonal: 
				# Bottom left diagonal [y+1][x-1]
				# Update temp X and Y in $t5 and $t6
				sub $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				add $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, adjacentBottom
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			adjacentBottom: 
				# Adjacent bottom [y+1][x]
				# Update temp X and Y in $t5 and $t6
				move $t5, $t2 

				add $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, bottomRightDiagonal
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			bottomRightDiagonal: 
				# Bottom right diagonal [y+1][x+1]
				# Update temp X and Y in $t5 and $t6
				add $t5, $t2, 1
				add $t5, $t5, $a1
				rem $t5, $t5, $a1

				add $t6, $t3, 1
				add $t6, $t6, $a2
				rem $t6, $t6, $a2

				# Get adjusted address in $t7 
				mul $t7, $t6, $a1
				addu $t7, $t7, $t5
				mul $t7, $t7, WORD_SIZE
				addu $t7, $t7, $a0 

				# Get current state of cell at that address in $t5
				lw $t5, ($t7)
				rem $t5, $t5, 2

				# Check if cell is living or dead
				beqz $t5, sideCheckDone
					# If cell is living (not 0), increment living neighbor count
					addu $t4, $t4, 1 

			sideCheckDone: 

			# Get current state of current cell in $t5
			# Current address in $t1
			move $t1, $a0 
			
			move $t5, $t3
			mul $t5, $t5, $a1
			add $t5, $t5, $t2
			mul $t5, $t5, WORD_SIZE
			addu $t1, $t1, $t5

			lw $t5, ($t1) 

			# Mod 2 to get current state
			rem $t5, $t5, 2 

			# Logic for living cell
			beqz $t5, deadCellLogic
				# If current state was not 0, do checks for living cell
				bne $t4, 2, livingCellNotTwo
					# If living cell has 2 living neighbors, update
					# next bit to alive as well by adding 2
					add $t5, $t5, 2
					sw $t5, ($t1)
					j changeCellLogicDone

				livingCellNotTwo: 
				bne $t4, 3, changeCellLogicDone
					# If living cell has 3 living neighbors, update
					# next bit to alive as well by adding 2
					add $t5, $t5, 2
					sw $t5, ($t1) 
					j changeCellLogicDone

				# If cell is living and will change to dead, do nothing
				# as the bits are already set to 01 


			# Logic for dead cell
			deadCellLogic: 
				bne $t4, 3, changeCellLogicDone
					# If number of living neighbors was exactly 3, 
					# update next bit to alive by adding 2
					add $t5, $t5, 2
					sw $t5, ($t1) 
					j changeCellLogicDone
				
				# If the cell stays dead, you don't have to do anything; 
				# bits are already set to 00 

			changeCellLogicDone:
			# Get next X
			add $t2, $t2, 1
			add $t2, $t2, $a1
			rem $t2, $t2, $a1

			# Decrement column loop counter
			sub $t8, $t8, 1

		# Check looping condition for column loop
		bnez $t8, cellStateColumnLoop

		# At end of each column loop
		# Decrement row loop counter
		sub $t0, $t0, 1

		# Reset X to 0
		li $t2, 0 

		# Reset column loop counter to width
		move $t8, $a1 
		
		# Get next Y 
		add $t3, $t3, 1
		add $t3, $t3, $a2
		rem $t3, $t3, $a2 

	# Check looping condition for row loop
	bnez $t0, cellStateRowLoop


	# Update state of board
	# Initialize row loop counter in $t0 to height 
	move $t0, $a2
	# Initialize column loop counter in $t8 to width
	move $t8, $a1

	# Running X and Y in $t2 and $t3
	li $t2, 0 
	li $t3, 0 

	updateStateRowLoop: 
		updateStateColumnLoop: 
			# Get current address in $t4
			mul $t4, $t3, $a1
			add $t4, $t4, $t2
			mul $t4, $t4, WORD_SIZE
			add $t4, $t4, $a0 

			# Get cell at current address in $t5
			lw $t5, ($t4) 

			# Div by 2 to extract next state
			div $t5, $t5, 2

			# Update to next state
			sw $t5, ($t4) 

			# Go to next X 
			add $t2, $t2, 1
			add $t2, $t2, $a1
			rem $t2, $t2, $a1

			# Decrement column loop counter
			sub $t8, $t8, 1

		# Check column loop condition
		bnez $t8, updateStateColumnLoop

		# If column loop finished
		# Reset X to 0 
		li $t2, 0 

		# Go to next Y 
		add $t3, $t3, 1
		add $t3, $t3, $a2
		rem $t3, $t3, $a2

		# Decrement row loop counter
		sub $t0, $t0, 1 

		# Reset column loop counter to width
		move $t8, $a1 
	
	# Check row loop condition
	bnez $t0, updateStateRowLoop

	# Second to last assignment! You've got this, Reinhart. \^u^/
	# Thank you for taking the time to grade this lengthy 
	# project. 

	jr $ra
.end playTurn

#;	Prints the array using the specified dimensions
#;	For values of 1, print as a livingCell "¤"
#;	For values of 0, print as a deadCell "•"
#;	Argument 1: Address of Array
#;	Argument 2: Width of Array
#;	Argument 3: Height of Array
.globl printGameBoard
.ent printGameBoard
printGameBoard:

	# Get array address in $t4
	move $t4, $a0 

	# Initialize loop counter in $t0 to total # of elements
	move $t0, $a1
	mul $t0, $t0, $a2

	# Initialize chars printed in $t2 to 0 
	li $t2, 0 

	printGameBoardLoop: 
		# Get current array character in $t1
		lw $t1, ($t4)

		# Print appropriate character
		bnez $t1, printLivingCell
			# If current character is 0, print dead cell
			li $v0, SYSTEM_PRINT_STRING
			la $a0, deadCell
			syscall
			j checkPrintNewline

		# If current character is not 0, print living cell
		printLivingCell:
			li $v0, SYSTEM_PRINT_STRING
			la $a0, livingCell
			syscall

		checkPrintNewline:
			# Inc chars printed
			add $t2, $t2, 1

			# If chars printed % width == 0, print new line 
			rem $t3, $t2, $a1
			bnez $t3, printNextCharacter
				li $v0, SYSTEM_PRINT_STRING
				la $a0, newLine
				syscall

		printNextCharacter: 
			# Move to next array address
			add $t4, $t4, 4

			# Decrement loop counter
			sub $t0, $t0, 1

	# Check looping condition 
	bnez $t0, printGameBoardLoop

	# Print last new line
	li $v0, SYSTEM_PRINT_STRING
	la $a0, newLine
	syscall 
	
	jr $ra
.end printGameBoard
