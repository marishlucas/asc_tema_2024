set disassembly-flavor att
set tui active-border-mode bold

tui enable
layout regs

define hook-stop
  regs
end