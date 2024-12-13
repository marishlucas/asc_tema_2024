/*


  */

.data 
  memory: .zero 1024
  formatAdd: .asciz "%d: (%d, %d)\n"
  formatGet: .asciz "(%d, %d)\n"
  formatScanf: .asciz "%ld"
  formatError: .asciz "%d: (0, 0)\n"
  operations: .space 4
  descriptor: .space 4
  blocks: .space 4
  blockSize: .long 8
  index: .space 4
  nr_files: .space 4
  counter: .long 0

.text
.global main 

main:
  pushl $operations
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit

process_ops:
  cmpl $1, operations
  je do_add
  cmpl $2, operations
  je do_get
  jmp exit

do_add:
  pushl $nr_files
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit
  
  movl $0, counter

add_files_loop:
  movl counter, %eax
  cmpl nr_files, %eax
  jge read_next_op

  pushl $descriptor
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit

  pushl $blocks
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit

  movl blocks, %eax
  movl $0, %edx
  divl blockSize
  cmpl $0, %edx
  je no_remainder
  incl %eax
no_remainder:
  movl %eax, blocks

  pushl blocks
  call find_position
  addl $4, %esp
  
  cmpl $-1, %eax
  je print_error

  movl %eax, index
  pushl blocks
  pushl descriptor
  call add_file
  addl $8, %esp
  jmp continue

print_error:
  pushl $0
  pushl $0
  pushl descriptor
  pushl $formatAdd
  call printf
  addl $16, %esp

continue:
  incl counter
  jmp add_files_loop

do_get:
  pushl $descriptor
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit

  pushl descriptor
  call get_file
  addl $4, %esp

read_next_op:
  pushl $operations
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  cmpl $0, %eax
  jle exit
  jmp process_ops

find_position:
  pushl %ebp
  movl %esp, %ebp
  pushl %ebx
  pushl %edi
  pushl %esi

  movl 8(%ebp), %ecx
  movl $0, %edi
  movl $1024, %esi
  subl %ecx, %esi

find_loop:
  cmpl %esi, %edi
  jg no_position
  
  movl %ecx, %ebx
  movl $0, %edx

check_consecutive:
  lea memory, %eax
  movb (%eax, %edi, 1), %al
  cmpb $0, %al
  jne next_position
  
  decl %ebx
  cmpl $0, %ebx
  je position_found
  
  incl %edi
  jmp check_consecutive

next_position:
  incl %edi
  jmp find_loop

position_found:
  movl %edi, %eax
  subl %ecx, %eax
  incl %eax
  jmp find_done

no_position:
  movl $-1, %eax

find_done:
  popl %esi
  popl %edi
  popl %ebx
  movl %ebp, %esp
  popl %ebp
  ret

get_file:
  pushl %ebp
  movl %esp, %ebp
  pushl %ebx
  pushl %edi
  pushl %esi

  movl 8(%ebp), %edx
  movl $0, %edi
  movl $-1, %esi

search_loop:
  cmpl $1024, %edi
  jge not_found

  lea memory, %ebx
  movb (%ebx, %edi, 1), %al
  cmpb %dl, %al
  jne next_byte

  cmpl $-1, %esi
  jne continue_interval
  movl %edi, %esi

continue_interval:
  incl %edi
  jmp search_loop

next_byte:
  cmpl $-1, %esi
  je no_interval
  
  decl %edi
  pushl %edi
  pushl %esi
  pushl $formatGet
  call printf
  addl $12, %esp
  jmp get_done

no_interval:
  incl %edi
  jmp search_loop

not_found:
  cmpl $-1, %esi
  je print_zero
  decl %edi
  pushl %edi
  pushl %esi
  pushl $formatGet
  call printf
  addl $12, %esp
  jmp get_done

print_zero:
  pushl $0
  pushl $0
  pushl $formatGet
  call printf
  addl $12, %esp

get_done:
  popl %esi
  popl %edi  
  popl %ebx
  movl %ebp, %esp
  popl %ebp
  ret

add_file:
  pushl %ebp
  movl %esp, %ebp
  
  movl 8(%ebp), %edx
  movl 12(%ebp), %ecx
  movl index, %edi
  lea memory, %esi

storing_loop:
  movb %dl, (%esi, %edi, 1)
  incl %edi
  decl %ecx 
  jnz storing_loop

  movl index, %eax
  decl %edi
  
  pushl %edi
  pushl %eax
  pushl %edx
  pushl $formatAdd
  call printf
  addl $16, %esp

  incl %edi
  movl %edi, index

  movl %ebp, %esp
  popl %ebp
  ret

exit:
  movl $1, %eax
  xorl %ebx, %ebx
  int $0x80
