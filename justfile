set shell := ['sh', '-cu']

LIMINE_DIR := "limine"
TARGET := "Zigumi"
KERNEL := "src/kernel.zig"
KERNEL_ELF := "bin/kernel.elf"
KERNEL_BIN := "bin/kernel.bin"
## ISO filename uses TARGET directly to avoid nested-template expansion issues

# Directory that will become the ISO tree. You can override this when invoking just
ISO_DIR := "iso"
# Project root (used for limine.conf path). Defaults to repository root.
PROJECT_ROOT := "."
# Kernel build folder if you produce a kernel at ${KERNEL_FOLDER}/build/kernel
KERNEL_FOLDER := "."

# Default target
default: iso

# Build kernel ELF (Zig)
kernel-elf:
	mkdir -p bin
	zig build-exe {{KERNEL}} \
		-target x86_64-freestanding \
		-mcmodel=kernel \
		-femit-bin={{KERNEL_ELF}} \
		-O ReleaseSmall \
		--script linker.ld \
		-fno-strip

# Create binary kernel image from ELF
kernel-bin: kernel-elf
	objcopy -O binary {{KERNEL_ELF}} {{KERNEL_BIN}}

# Create ISO (Limine) - copies Limine binaries and limine.conf, creates hybrid ISO and attempts installer
iso: kernel-elf
	# Prepare iso tree
	mkdir -p {{ISO_DIR}}/boot {{ISO_DIR}}/boot/limine {{ISO_DIR}}/limine {{ISO_DIR}}/EFI/BOOT
	rm -f {{ISO_DIR}}/boot/kernel.elf
	cp -v {{KERNEL_ELF}} {{ISO_DIR}}/boot/kernel.elf

	# Copy Limine artifacts: prefer ./Limine if present, else use {{LIMINE_DIR}}
	if [ -d "./Limine" ]; then \
		cp -v "./Limine/limine-bios.sys" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./Limine/limine-bios-cd.bin" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./Limine/limine-uefi-cd.bin" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./Limine/BOOTX64.EFI" "{{ISO_DIR}}/EFI/BOOT/" 2>/dev/null || true; \
		cp -v "./Limine/BOOTIA32.EFI" "{{ISO_DIR}}/EFI/BOOT/" 2>/dev/null || true; \
	else \
		cp -v "./{{LIMINE_DIR}}/limine-bios.sys" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./{{LIMINE_DIR}}/limine-bios-cd.bin" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./{{LIMINE_DIR}}/limine-uefi-cd.bin" "{{ISO_DIR}}/boot/limine/" 2>/dev/null || true; \
		cp -v "./{{LIMINE_DIR}}/BOOTX64.EFI" "{{ISO_DIR}}/EFI/BOOT/" 2>/dev/null || true; \
		cp -v "./{{LIMINE_DIR}}/BOOTIA32.EFI" "{{ISO_DIR}}/EFI/BOOT/" 2>/dev/null || true; \
	fi; \

	# Copy alternative kernel if present at ${KERNEL_FOLDER}/build/kernel
	if [ -f "{{KERNEL_FOLDER}}/build/kernel" ]; then \
		cp -v "{{KERNEL_FOLDER}}/build/kernel" "{{ISO_DIR}}/kernel"; \
	fi; \

	# Copy limine.conf from project root or fallback to cfg/limine.conf
	if [ -f "{{PROJECT_ROOT}}/limine.conf" ]; then \
		cp -v "{{PROJECT_ROOT}}/limine.conf" "{{ISO_DIR}}/limine.conf"; \
	else \
		cp -v cfg/limine.conf "{{ISO_DIR}}/limine.conf"; \
	fi; \

	# Create hybrid ISO with protective msdos label (recommended by Limine docs)
	xorriso -as mkisofs -R -r -J -o bin/{{TARGET}}.iso \
		-b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		--protective-msdos-label -isohybrid-mbr {{ISO_DIR}}/boot/limine/limine-bios-cd.bin {{ISO_DIR}}


run: iso
	qemu-system-x86_64 -no-reboot -no-shutdown -cdrom bin/{{TARGET}}.iso -serial stdio -display gtk

clean:
	rm -rf bin/ iso/
