.section .data
pickup : .word 0xffff
dta: .word 0x80120000,   0x000c0000
@ -1.01e2
@ 1.1e1
.section .text
.global _start
check :
stmfd sp!, {r7-r9,lr}
cmp r6,r3
movlt r7,r0
movlt r8,r2
movlt r9,r3
movlt r0,r4
movlt r2,r5
movlt r3,r6
movlt r4,r7
movlt r5,r8
movlt r6,r9
ldmfd sp!, {r7-r9,pc}

swap:
stmfd sp!, {r7-r9,lr}
mov r7,r0
mov r8,r2
mov r9,r3
mov r0,r4
mov r2,r5
mov r3,r6
mov r4,r7
mov r5,r8
mov r6,r9
ldmfd sp!, {r7-r9,pc}

Normalize: @In case of addition of numbers with opposite signs, normalise till the msb of mantissa becomes 1 
stmfd sp!, {r8,lr}
and r8,r3,#0b1000000000000000000
cmp r8,#0b1000000000000000000
lslne r3,#1
subne r5,r5,#1
bne Normalize
ldmfd sp!, {r8,pc}

nfpAdd :
stmfd sp!, {r0-r11,lr}
add r3,r3,#0x80000                  @principal of 1st number
add r6,r6,#0x80000
sub r8,r5,r2				@no. of bits to shift
lsr r3,r8					@shifted principal of number with smaller exponent
mov r11,#0x100000              	@for calculating two's complement
cmp r0,r4     			 	@comparinng signs of both numbers
movne r9,#1					@if signs of numbers are different make r9 1 to store this result
subne r3,r11,r3			      @if signs of numbers are different take twos complement the smaller numbers principal
add r3,r3,r6				@add principles of both numbers
cmp r9,#1
biceq r3,#0x100000 
cmp r3,#0x100000                    @ due to addition of same sign numbers if the principal result in value...
lsrge r3,#1					@ ....greater than one normalise by right shifting and increment the exponent
addge r5,r5,#1
bic r3,#0x100000
cmp r9,#1					
bleq Normalize 				@ if signs of numbers are opposite normalisation by left shifting is needed
lsleq r3,#1    				@ after msb of mantissa becomes 1 left shift it once more so that the number get the principle bit
subeq r5,r5,#1 
bic r3,r3,#0b10000000000000000000   @ clear the principle bit now
cmp r5,#0
addlt r5,r5,#0b1000000000000		@if exponent of resultant is negative change it to twos complement form
lsl r4,#31
lsl r5,#19					@shifts the sign , mantissa and exponent accordingly so as to add them to make up 32 bit nfp form
add r10,r3,r5
add r10,r10,r4
str r10,[r1]
ldmfd sp!, {r0-r11,pc}

nfpMultiply:
stmfd sp!, {r0-r11,lr}
add r5,r5,r2			     @resultant exponent = exp of A + exp of B
eor r4,r4,r0			     @sign bit of answer = sign bit of A xor sign bit of B
add r3,r3,#0b10000000000000000000  @principal of 1st number
add r6,r6,#0b10000000000000000000  
ldr r2,=pickup
ldr r0,[r2]
and r7,r3,#0xf0000   		    @first four bits of 20 bit number    @ A*B= (x.2^16 + m)*(y.2^16 + n) 
lsr r7,#16										     @       r7       r8  r9       r10
and r8,r3,r0			    @last 16 bits of 20 bit number
and r9,r6,#0xf0000
lsr r9,#16
and r10,r6,r0
mul r11,r8,r10
lsr r11,#16
mul r3,r7,r10
mul r6,r8,r9
mul r7,r7,r9
lsl r7,#16
add r8,r11,r3
add r8,r8,r6
add r8,r8,r7
lsr r8,#3
and r6,r8,#0x100000
cmp r6,#0x100000
lsreq r8,#1
addeq r5,r5,#1
bic r8,r8,#0b10000000000000000000
cmp r5,#0 				     @if exponent is negative convert it to two's complement form
addlt r5,r5,#0b1000000000000
lsl r4,#31
lsl r5,#19
add r2,r4,r5
add r2,r8
str r2,[r1]
ldmfd sp!, {r0-r11,pc}

_start:
ldr r1,=dta		@.............address of numbers
ldr r0,[r1] 
ldr r2,[r1] 
ldr r3,[r1]
lsr r0,#31 		@.............sign bit of first number
lsl r2,#1  
lsr r2,#20 		@.............exponent of first number
lsl r3,#13
lsr r3,#13 		@.............mantissa of first number
add r1,r1,#4
ldr r4,[r1]
ldr r5,[r1]
ldr r6,[r1]
add r1,r1,#4
lsr r4,#31 		@.............sign bit of 2nd number
lsl r5,#1  
lsr r5,#20		@.............exponent of 2nd number
lsl r6,#13 	
lsr r6,#13		@.............mantissa of 2nd number
mov r8,#0b10000000000000
and r7,r2,#0b1000000000  @ If first bit of this number is 1 then it is negative (convert it to signed form)
cmp r7,#0b1000000000
subeq r2,r2,r8		 @ taking twos complement of that number to get signed number
and r7,r5,#0b1000000000  @ do same for sign of 2nd number
cmp r7,#0b1000000000    
subeq r5,r5,r8
cmp r5,r2
bllt swap     	@ swap values in registers inorder to get the number with larger exponent in second register
bleq check
bl nfpAdd
add r1,r1,#4
bl nfpMultiply








