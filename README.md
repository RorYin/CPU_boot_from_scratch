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

The Makefile uses GNU ARM assembler, linker, and inspection tools to create
`main.elf`; QEMU emulates the board and GDB connects to its debug server.
