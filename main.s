.data 
  memory: .zero 1024
  formatAdd: .asciz "%d: (%d, %d)\n"

.text
.global main 

main:
  movl $5, %eax
  movl $3, %ebx
  movl $0, %ecx    # pozitie de start blocks

  pushl %ebx
  pushl %eax
  call add_file
  popl %ebx
  popl %ebx
  jmp exit

add_file: 
  pushl %ebp
  movl %esp, %ebp
  # la 4(%ebp) se afla adresa de ret
  movl 8(%ebp), %edx
  movl 12(%ebp), %ecx
  movl $0, %edi
  lea memory, %esi

storing_loop:
  cmpl %ecx, %edi
  jge storing_end
  # descriptori de la 0-255 => putem folosi dl din edx
  movb %dl, (%esi, %edi, 1)   #base + index * scale
  incl %edi
  jmp storing_loop
  
storing_end:
  pushl %ecx 
  decl (%esp)
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
