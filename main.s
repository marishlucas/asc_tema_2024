.data 

.text
.global main

exit:
  movl $1, %eax
  xorl %ebx, %ebx
  int $0x80

main:
