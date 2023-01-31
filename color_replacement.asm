.eqv BMP_FILE_SIZE 230456
.eqv BYTES_PER_ROW 960

	.data
#space for the 320x240px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

fname:	.asciz "tiger.bmp"
oname:  .asciz "sepia.bmp"
	.text
main:
	jal	read_bmp
	
	#width
	li s2, 0
	li s3, 320
	#height
	li s4, 0
	li s5, 240
	addi s4,s4,-1
loop1:
	mv s10, s2
	addi s4, s4, 1
	bge s4, s5, save
	
	
loop2:
	mv a0, s10
	mv a1, s4
	li a7, 1
	jal change_to_sepia
	
	
	mv a2, a0
	mv a0, s10
	
	
	jal put_pixel
	

	addi s10, s10, 1
	bge s10, s3, loop1
	j loop2
	
save:	
	jal	save_bmp

exit:	li 	a7,10		#Terminate the program
	ecall
# ============================================================================
change_to_sepia:
#description: 
#	returns color after sepia tone modificiation
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - 0RGB - pixel color

	la t1, image		#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2		#adress of pixel array in $t2
	
	#pixel address calculation
	li a4,BYTES_PER_ROW
	mul t1, a1, a4 		#t1= y*BYTES_PER_ROW
	mv a3, a0		
	slli a0, a0, 1
	add a3, a3, a0		#$a3= 3*x
	add t1, t1, a3		#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1		#pixel address 
	
	#get color
	lbu a0,(t2)		#load B
	mv s6, a0
		
	lbu t1,1(t2)		#load G
	mv s7, t1
	
	lbu t1,2(t2)		#load R
	mv s8, t1
	
	
########################################################################	

	# DISTANCE CALCULATION

#######################################################################						
        #t3 - dist (0-442)
	#t4 - red
	#t5 - green
	#t6 - blue
	
	li t3, 442
	
	li t4, 44	
	li t5, 88
	li t6, 12
	
	mul t3, t3 , t3
	
	sub t4, s8, t4
	mul t4,t4,t4
	
	sub t5, s7, t5
	mul t5, t5, t5
	
	sub t6, s6, t6
	mul t6, t6, t6
	
	add t4, t4, t5
	add t4, t4, t6
	
#########################################################################
	#a5 - red output
	#a6 - green output
	#a7 - blue output
	
sepia:
	li s9, 1000
	########BLUE###########
	li s11, 131
	mul s11, s11, s6
	div s11,s11, s9
	li a7, 0
	add a7,a7,s11
	
	li s11, 534
	mul s11, s11, s7
	div s11,s11,s9
	add a7,a7,s11
	
	li s11, 272
	mul s11, s11, s8
	div s11, s11,s9
	add a7,a7,s11
	#div a7,a7,s9
	li s11,255
	bgt a7, s11, test_blue
back_blue:	
	mv a0, a7
	########GREEN###########
	li s11, 168			
	mul s11, s11, s6
	div s11,s11,s9
	li a6, 0
	add a6,a6,s11
	
	li s11, 686
	mul s11, s11, s7
	div s11,s11,s9
	add a6,a6,s11
	
	li s11, 349
	mul s11, s11, s8
	div s11,s11,s9
	add a6,a6,s11	
	#div a6,a6,s9
	li s11, 255
	bgt a6, s11, test_green
back_green:		
	slli a6,a6,8
	or a0, a0, a6							
	##########RED###########
	li s11, 189
	mul s11, s11, s6
	div s11,s11,s9
	li a5, 0
	add a5, a5, s11	
	
	li s11, 769
	mul s11, s11, s7
	div s11,s11,s9
	add a5,a5,s11
	
	li s11, 393
	mul s11, s11, s8
	div s11,s11,s9
	add a5,a5,s11
	#div a5,a5,s9
	li s11, 255
	bgt a5, s11, test_red
back_red:	
	slli a5,a5,16
	or a0, a0, a5	
	
	blt t3, t4, original_colour

							
	jr ra
	
	
	
test_red:
	li a5,255
	j back_red
	
test_green:
	li a6,255
	j back_green
test_blue:
	li a7, 255
	j back_blue
	
original_colour:
	mv a0, s6
	slli s7, s7, 8
	or a0, a0, s7
	slli s8, s8, 16
	or a0, a0, s8
	
jr ra


# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, fname		#file name 
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor
	
#read file
	li a7, 63
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, oname		#file name 
        li a1, 1		#flags: 1-write file
        ecall
	mv s1, a0      # save the file descriptor
	
#save file
	li a7, 64
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, (sp)		#restore (pop) $s1
	addi sp, sp, 4
	jr ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#	a2 - 0RGB - pixel color
#return value: none

	la t1, image	#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2	#adress of pixel array in $t2
	
	#pixel address calculation
	li a4,BYTES_PER_ROW
	mul t1, a1, a4 #t1= y*BYTES_PER_ROW
	mv a3, a0		
	slli a0, a0, 1
	add a3, a3, a0	#$a3= 3*x
	add t1, t1, a3	#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1	#pixel address 
	
	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R

	jr ra
