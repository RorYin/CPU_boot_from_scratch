# CPU boot from scratch

A tiny Cortex-M3 bare-metal program that boots on QEMU's STM32VLDISCOVERY
machine. The reset handler sets `r1` to 1, `r2` to 2, adds them into `r3`,
then loops forever. GDB Dashboard lets you inspect the CPU while it runs.

## Install on Windows

Open PowerShell and install the assembler toolchain, emulator, build tool, and
MSYS2:

```powershell
winget install --id Arm.GnuArmEmbeddedToolchain --exact
winget install --id SoftwareFreedomConservancy.QEMU --exact
winget install --id GnuWin32.Make --exact
winget install --id MSYS2.MSYS2 --exact
```

Open the **MSYS2 UCRT64** terminal from the Start menu and install a
Python-enabled, ARM-capable GDB and Pygments:

```bash
pacman -Syu
```

If MSYS2 asks you to close the terminal, do so, reopen **MSYS2 UCRT64**, and
run:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-gdb-multiarch mingw-w64-ucrt-x86_64-python-pygments
```

GDB Dashboard is a GDB startup script. In PowerShell, download it into your
Windows home folder:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/cyrus-and/gdb-dashboard/master/.gdbinit" `
  -OutFile "$HOME\.gdbinit"
```

Add these installed tool folders to your **user `Path`** using Windows'
Environment Variables settings, adjusting the ARM toolchain version folder if
it differs:

```text
C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.2 rel1\bin
C:\Program Files\qemu
C:\Program Files (x86)\GnuWin32\bin
C:\msys64\ucrt64\bin
```

Add a user environment variable named `TERMINFO` with this value so the
dashboard renders correctly in the Windows terminal:

```text
C:\msys64\ucrt64\share\terminfo
```

Restart VS Code after changing environment variables.

## Build and run

Open a terminal in this project folder:

```powershell
make
```

In the first terminal, start the emulated STM32:

```powershell
make qemu
```

In a second terminal in the project folder, connect GDB:

```powershell
make gdb
```

GDB starts halted on the first instruction, `reset_handler` at `boot.S:13`,
before it executes. Use `stepi` to execute one instruction at a time, or
`continue` to run. The register panel should show `r1`, `r2`, and `r3` as
1, 2, and 3 after those instructions execute.

Other useful commands:

```powershell
make clean
```

## What the project does

This project demonstrates the earliest steps of starting a bare-metal
Cortex-M3 program, without an operating system or C runtime. The linker puts a
vector table and a reset handler into the ELF image. QEMU loads that image as
an emulated STM32VLDiscovery program, and GDB lets you inspect execution and
registers. The reset handler sets `r1` to 1 and `r2` to 2, adds them into `r3`,
and then loops forever. The small calculation is just a visible way to confirm
that the processor reached and executed the program.

## `boot.S`: vectors and reset code

`boot.S` is GNU assembler source for the code that runs at startup:

- `.section .vectors` starts the interrupt/reset vector table section.
- `vector_table:` labels its first entry. The first `.word` stores
  `0x20002000`, the initial stack pointer value. The next `.word` stores the
  address of `reset_handler`, the reset vector the processor uses to begin
  executing the program.
- `.zero 400` reserves 400 zero-filled bytes after those two entries for the
  remaining vector-table space. This example does not define handlers for
  those other exceptions or interrupts.
- `.section .text` starts the executable-code section. `.align 1` aligns the
  following code, and `.type reset_handler, %function` marks the label as a
  function for assembler/linker metadata.
- `reset_handler:` is the entry point. `mov r1, #1` and `mov r2, #2` put the
  two values in registers; `add r3, r1, r2` computes their sum; `b .` branches
  back to the same instruction forever so the result remains available to
  inspect.

## `map.ld`: placing sections in memory

`map.ld` is the linker script. It tells the linker where the program's sections
belong in the target memory map:

- `MEMORY` declares a `FLASH` region beginning at address `0x0` with a
  capacity of 128 KiB.
- The `SECTIONS` block places the output `.text` section in `FLASH`.
- `*(.vectors)` gathers input sections named `.vectors`, and `*(.text)` gathers
  input sections named `.text`. The order puts the vector table at the start
  of the output `.text` section, followed by the reset code.

This is intentionally a minimal memory map for the demonstration. It does not
set up RAM sections, copy initialized data, clear a BSS section, or provide a
runtime startup routine.

## `Makefile`: building, running, and debugging

The Makefile defines the build inputs, tool commands, and convenience targets:

- `PROJ = main` sets the output name, so the linked program is `main.elf`.
- `CPU ?= cortex-m3` and `BOARD ?= stm32vldiscovery` set default processor and
  QEMU machine names. `?=` means a value passed to `make`, such as
  `make CPU=cortex-m3`, takes precedence.
- `OBJ = boot.o` lists the object file that goes into the ELF.
- `.PHONY: all` declares `all` to be a command target rather than a file.
  `all: $(PROJ).elf` makes the ELF the default build result.
- `%.o: %.S` is a pattern rule for assembling a `.S` source file into an
  object file. Its recipe runs
  `arm-none-eabi-as -mthumb -mcpu=$(CPU) -g -c $< -o $@`: select Thumb
  instructions and the configured CPU, include debug information, assemble
  without linking (`-c`), use `$<` for the source prerequisite, and write the
  result to `$@`.
- `$(PROJ).elf: $(OBJ)` says the ELF depends on the object file. The recipe
  first runs
  `arm-none-eabi-ld -T map.ld -o $@ $^`, linking with `map.ld`; `$@` is the
  ELF target and `$^` is the list of prerequisites. It then generates
  `main.elf.lst` with `arm-none-eabi-objdump -D -S` (a disassembly annotated
  with source where available), and `main.elf.debug` with
  `arm-none-eabi-readelf -a` (ELF metadata and section/program information).
- `qemu` starts the emulator with the selected board and CPU. `-S` holds the
  CPU at startup, `-nographic` uses the terminal instead of a graphical
  display, `-kernel $(PROJ).elf` supplies the image, and
  `-gdb tcp::1234` opens a GDB remote-debug connection on port 1234.
- `gdb` starts `gdb-multiarch` with the ELF's symbols, sets the OS ABI to
  `none`, and connects to QEMU at `localhost:1234`. Run `make qemu` first so
  the remote debugging endpoint is available.
- `clean` removes generated `.out`, `.elf`, `.lst`, and `.debug` files, the
  object file, and `.gdb_history` so the project can be rebuilt from source.

In short, `make` turns `boot.S` into an inspectable ARM ELF according to
`map.ld`; `make qemu` runs that image on an emulated board; and `make gdb`
connects a debugger so you can observe the reset sequence and verify the
register calculation.
