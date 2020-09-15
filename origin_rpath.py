import sys
import os
import subprocess

def chrpath(path):
    depth = path.count('/') - 1
    libdir = '$ORIGIN/%slib' % ('../' * depth,)
    subprocess.Popen(['chrpath', path, '-cr', libdir]).wait()

def main():
    for dirpath, dirnames, filenames in os.walk('.'):
        for filename in filenames:
            path = os.path.join(dirpath, filename)
            if path.endswith('.so') or 'bin/' in path:
                chrpath(path)

if __name__ == '__main__':
    main()

