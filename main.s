.data 
  memory: .zero 1024
  formatAdd: .asciz "%d: (%d, %d)\n"
  formatScanf: .asciz "%d: (%d, %d)\n"
  operations: .space 4
  descriptor: .space 4
  blocks: .space 4
  blockSize: .long 8

.text
.global main 

main:
  pushl $operations
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

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
  popl %ebx
  popl %ebx
  jmp exit

add_file: 
  pushl %ebp
  movl %esp, %ebp
  movl 8(%ebp), %edx
  movl 12(%ebp), %ecx
  movl $0, %edi
  lea memory, %esi

storing_loop:
  cmpl %ecx, %edi
  jge storing_end
  movb %dl, (%esi, %edi, 1)
  incl %edi
  jmp storing_loop
  
storing_end:
  pushl %ecx 
  pushl $0
  pushl %edx
  pushl $formatAdd
  call printf

  popl %ebx
  popl %ebx
  popl %ebx
  popl %ebx

  movl %ebp, %esp
  popl %ebp
  ret

exit:
  movl $1, %eax
  xorl %ebx, %ebx
  int $0x80
