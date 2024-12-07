.data 
  memory: .zero 1024
  formatAdd: .asciz "%d: (%d, %d)\n"
  formatScanf: .asciz "%ld"
  operations: .space 4
  descriptor: .space 4
  blocks: .space 4
  nr_files: .space 4
  size: .space 4
  start_pos: .space 4
  counter: .space 4

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

  pushl $nr_files
  pushl $formatScanf  
  call scanf
  popl %ebx
  popl %ebx

  movl $0, start_pos
  movl $0, counter

add_files_loop:
  movl counter, %ecx
  cmpl nr_files, %ecx
  jge exit 

  pushl $descriptor
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  pushl $size
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  pushl size
  pushl descriptor
  call add_file
  addl $8, %esp

  incl counter
  jmp add_files_loop

add_file: 
  pushl %ebp
  movl %esp, %ebp
  
  movl 8(%ebp), %edx   # descriptor
  movl 12(%ebp), %ecx  # size
  movl start_pos, %edi
  lea memory, %esi

storing_loop:
  cmpl %ecx, %edi
  jge storing_end
  movb %dl, (%esi, %edi, 1)
  incl %edi
  jmp storing_loop
  
storing_end:
  movl start_pos, %edi
  addl %ecx, %edi
  decl %edi
  
  pushl %edi
  pushl start_pos
  pushl %edx
  pushl $formatAdd
  call printf
  addl $16, %esp

  incl %edi
  movl %edi, start_pos
  
  pushl $0
  call fflush
  popl %ebx

  movl %ebp, %esp
  popl %ebp
  ret

exit:
  movl $1, %eax
  xorl %ebx, %ebx
  int $0x80
