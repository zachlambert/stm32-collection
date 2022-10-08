import sys

if len(sys.argv) != 2:
    exit()

arch = sys.argv[1].upper()
if not 'CORTEX-' in arch:
    exit()

arch = arch.replace('CORTEX-', 'ARM_C')
print(arch, end='')
