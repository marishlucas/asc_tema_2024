/*

TODO: add remainder conversion for partial files

  */

.data 
  memory: .zero 1024
  formatAdd: .asciz "%d: (%d, %d)\n"
  formatScanf: .asciz "%ld"
  operations: .space 4
  descriptor: .space 4
  blocks: .space 4
  blockSize: .long 8
  index: .long 0
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

  pushl $nr_files
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

add_files_loop:
  movl counter, %eax
  cmpl nr_files, %eax
  jge exit

  pushl $descriptor
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  pushl $blocks
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  movl blocks, %eax
  movl $0, %edx
  divl blockSize
  movl %eax, blocks

  pushl blocks
  pushl descriptor
  call add_file
  addl $8, %esp

  incl counter
  jmp add_files_loop

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

storing_end:
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
