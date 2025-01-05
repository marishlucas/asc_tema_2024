.data 
  memory: .zero 8388608  # 8MB = 8 * 1024 * 1024 bytes
  temp: .zero 8388608
  formatAdd: .asciz "%d: (%d, %d)\n"
  formatGet: .asciz "(%d, %d)\n"
  formatScanf: .asciz "%ld"
  formatError: .asciz "%d: (0, 0)\n"
  operations: .space 4
  remaining_ops: .space 4
  descriptor: .space 4
  blocks: .space 4
  blockSize: .long 8192
  index: .space 4
  nr_files: .space 4
  counter: .long 0
  current_pos: .long 0
  memsize: .long 8388608
  min_blocks: .long 2

.text
.global main 

main:
  pushl $operations
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  
  movl operations, %eax
  movl %eax, remaining_ops

process_ops:
  cmpl $0, remaining_ops
  jle exit

  pushl $operations
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  cmpl $1, operations
  je do_add
  cmpl $2, operations
  je do_get
  cmpl $3, operations
  je do_delete
  cmpl $4, operations
  je do_defrag
  jmp read_next_op

do_defrag:
  call defragment
  jmp read_next_op

defragment:
  pushl %ebp
  movl %esp, %ebp
  pushl %ebx
  pushl %edi
  pushl %esi

  movl $0, %edi
copy_to_temp:
  cmpl memsize, %edi
  jge copy_done
  movb memory(,%edi,1), %al
  movb %al, temp(,%edi,1)
  movb $0, memory(,%edi,1)
  incl %edi
  jmp copy_to_temp

copy_done:
  movl $0, current_pos
  movl $0, %edi
  movl $-1, %esi
  movl $0, %ebx

scan_loop:
  cmpl memsize, %edi
  jge done_scan
  
  movb temp(,%edi,1), %al
  
  cmpl $-1, %esi
  jne check_current_file
  
  cmpb $0, %al
  je next_byte
  
  movl %edi, %esi
  movb %al, %bl
  jmp next_byte
  
check_current_file:
  cmpb %bl, %al
  je next_byte
  
  pushl %edi
  decl %edi
  
  movl %edi, %eax
  subl %esi, %eax
  incl %eax
  
  pushl %eax
  
  movl %esi, %ecx
  movl current_pos, %edx

copy_file:
  cmpl %edi, %ecx
  jg copy_file_done
  
  movb temp(,%ecx,1), %al
  movb %al, memory(,%edx,1)
  incl %ecx
  incl %edx
  jmp copy_file
  
copy_file_done:
  movl current_pos, %ecx
  popl %eax
  pushl %eax
  
  movl %ecx, %edx
  addl %eax, %edx
  decl %edx
  
  pushl %edx
  pushl %ecx
  movzbl %bl, %eax
  pushl %eax
  pushl $formatAdd
  call printf
  
  pushl $0
  call fflush
  popl %eax
  
  addl $16, %esp
  
  popl %eax
  addl %eax, current_pos
  
  movl $-1, %esi
  
  popl %edi
  decl %edi
  
next_byte:
  incl %edi
  jmp scan_loop
  
done_scan:
  cmpl $-1, %esi
  je finish_defrag
  
  decl %edi
  
  movl %edi, %eax
  subl %esi, %eax
  incl %eax
  pushl %eax
  
  movl %esi, %ecx
  movl current_pos, %edx

copy_last:
  cmpl %edi, %ecx
  jg copy_last_done
  
  movb temp(,%ecx,1), %al
  movb %al, memory(,%edx,1)
  incl %ecx
  incl %edx
  jmp copy_last
  
copy_last_done:
  movl current_pos, %ecx
  popl %eax
  
  movl %ecx, %edx
  addl %eax, %edx
  decl %edx
  
  pushl %edx
  pushl %ecx
  movzbl %bl, %eax
  pushl %eax
  pushl $formatAdd
  call printf
  
  pushl $0
  call fflush
  popl %eax
  
  addl $16, %esp

finish_defrag:
  movl current_pos, %edi

clear_remaining:
  cmpl memsize, %edi
  jge defrag_done
  movb $0, memory(,%edi,1)
  incl %edi
  jmp clear_remaining

defrag_done:
  popl %esi
  popl %edi
  popl %ebx
  movl %ebp, %esp
  popl %ebp
  ret

do_delete:
  pushl $descriptor 
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  pushl descriptor
  call delete_file
  addl $4, %esp
  jmp read_next_op

delete_file:
  pushl %ebp
  movl %esp, %ebp
  pushl %ebx
  pushl %edi
  pushl %esi

  movl 8(%ebp), %edx
  movl $0, %edi
    
delete_pass:
  cmpl memsize, %edi
  jge print_remaining
    
  lea memory, %ebx
  movb (%ebx, %edi, 1), %al
  cmpb %dl, %al
  jne delete_continue
    
  movb $0, (%ebx, %edi, 1)
    
delete_continue:
  incl %edi
  jmp delete_pass

print_remaining:
  movl $0, %edi
  movl $-1, %esi
  movl $0, %edx
    
delete_scan_loop:
  cmpl memsize, %edi
  jge delete_check_final
    
  lea memory, %ebx
  movb (%ebx, %edi, 1), %al
    
  cmpl $-1, %esi
  je delete_check_new
    
  cmpb %dl, %al
  je delete_continue_interval
    
  decl %edi
  pushl %edi
  pushl %esi
  movzbl %dl, %eax
  pushl %eax
  pushl $formatAdd
  call printf
  
  pushl $0
  call fflush
  popl %ebx
  
  addl $16, %esp
    
  movl $-1, %esi
  jmp delete_scan_continue
    
delete_check_new:
  cmpb $0, %al
  je delete_scan_continue
    
  movl %edi, %esi
  movb %al, %dl
    
delete_continue_interval:
  incl %edi
  jmp delete_scan_loop
    
delete_scan_continue:
  incl %edi
  jmp delete_scan_loop
    
delete_check_final:
  cmpl $-1, %esi
  je delete_done
    
  decl %edi
  pushl %edi
  pushl %esi
  movzbl %dl, %eax
  pushl %eax
  pushl $formatAdd
  call printf
  
  pushl $0
  call fflush
  popl %ebx
  
  addl $16, %esp

delete_done:
  popl %esi
  popl %edi
  popl %ebx
  movl %ebp, %esp
  popl %ebp
  ret

do_add:
  pushl $nr_files
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx
  
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

  pushl $blocks
  pushl $formatScanf
  call scanf
  popl %ebx
  popl %ebx

  movl blocks, %eax
  movl $0, %edx
  movl $8, %ecx
  divl %ecx
  cmpl $0, %edx
  je check_min_blocks
  incl %eax

check_min_blocks:
  cmpl $2, %eax
  jl print_error
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
  
  pushl $0
  call fflush
  popl %ebx
  
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

  pushl descriptor
  call get_file
  addl $4, %esp
  jmp read_next_op

read_next_op:
  decl remaining_ops
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

get_search_loop:
  cmpl memsize, %edi
  jge get_not_found

  lea memory, %ebx
  movb (%ebx, %edi, 1), %al
  cmpb %dl, %al
  jne get_next_byte

  cmpl $-1, %esi
  jne get_continue_interval
  movl %edi, %esi

get_continue_interval:
  incl %edi
  jmp get_search_loop

get_next_byte:
  cmpl $-1, %esi
  je get_no_interval
  
  decl %edi
  pushl %edi
  pushl %esi
  pushl $formatGet
  call printf
  
  pushl $0
  call fflush
  popl %ebx
  
  addl $12, %esp
  jmp get_done

get_no_interval:
  incl %edi
  jmp get_search_loop

get_not_found:
  cmpl $-1, %esi
  je get_print_zero
  decl %edi
  pushl %edi
  pushl %esi
  pushl $formatGet
  call printf
  
  pushl $0
  call fflush
  popl %ebx
  
  addl $12, %esp
  jmp get_done

get_print_zero:
  pushl $0
  pushl $0
  pushl $formatGet
  call printf
  
  pushl $0
  call fflush
  popl %ebx
  
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
  
  pushl $0
  call fflush
  popl %ebx
  
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
