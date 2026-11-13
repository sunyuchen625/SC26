#!/usr/bin/env python3
import codecs
import errno
import fcntl
import json
import os
import pty
import struct
import sys
import termios
import time

destination, title = sys.argv[1:3]
command = sys.argv[3:]
width, height = 144, 35
with open(destination, 'x', encoding='utf-8', buffering=1) as output:
    header = dict(version=2, width=width, height=height, timestamp=int(time.time()),
                  title=title, env={'TERM': 'xterm-256color', 'SHELL': '/bin/bash'})
    output.write(json.dumps(header) + '\n')
    start = time.monotonic()
    pid, terminal = pty.fork()
    if pid == 0:
        output.close()
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', height, width, 0, 0))
        os.environ['TERM'] = 'xterm-256color'
        os.execvp(command[0], command)
    decoder = codecs.getincrementaldecoder('utf-8')('replace')
    while True:
        try:
            data = os.read(terminal, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        decoded = decoder.decode(data, final=not data)
        if decoded:
            event = [round(time.monotonic()-start, 6), 'o', decoded]
            output.write(json.dumps(event, ensure_ascii=False) + '\n')
        if not data:
            break
    os.close(terminal)
    _, status = os.waitpid(pid, 0)
sys.exit(os.WEXITSTATUS(status) if os.WIFEXITED(status) else 128 + os.WTERMSIG(status))
