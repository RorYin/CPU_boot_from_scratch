PROJ = main
CPU ?= cortex-m3
BOARD ?= stm32vldiscovery

OBJ = boot.o

.PHONY: all
all: $(PROJ).elf

%.o: %.S
	arm-none-eabi-as -mthumb -mcpu=$(CPU) -g -c $< -o $@

$(PROJ).elf: $(OBJ)
	arm-none-eabi-ld -T map.ld -o $@ $^
	arm-none-eabi-objdump -D -S $@ > $@.lst
	arm-none-eabi-readelf -a $@ > $@.debug

qemu:
	qemu-system-arm -S -M $(BOARD) -cpu $(CPU) -nographic -kernel \
	$(PROJ).elf -gdb tcp::1234

gdb:
	gdb-multiarch -q -iex "set osabi none" $(PROJ).elf -ex "target remote localhost:1234"

clean:
	if exist *.out del /Q *.out
	if exist *.elf del /Q *.elf
	if exist .gdb_history del /Q .gdb_history
	if exist *.lst del /Q *.lst
	if exist *.debug del /Q *.debug
	if exist $(OBJ) del /Q $(OBJ)