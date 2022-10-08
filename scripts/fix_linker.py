import sys

if len(sys.argv) != 3:
    exit()

if sys.argv[1] != 'TRUE':
    exit()

path = sys.argv[2]

with open(path, 'r') as file:
  filedata = file.read()

filedata = filedata.replace('/DISCARD/ : { *(.eh_frame) }', '')

with open(path, 'w') as file:
  file.write(filedata)
