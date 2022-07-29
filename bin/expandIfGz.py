#!/usr/bin/env python3

import argparse
import subprocess
import os, sys

args = argparse.ArgumentParser()
args.add_argument('-i', '--input', required=True, help='Input file')
args.add_argument('-o', '--output', required=True, help='Output file')
args.add_argument('--link', action='store_true', help='Link input file to output file')
args = args.parse_args()

decompressed = None

if args.input.endswith('.gz'):
    print("Decompressing {}".format(args.input), file=sys.stderr)
    input_resolved_path = os.path.abspath(args.input)
    try:
        subprocess.call(['gunzip', input_resolved_path])
        decompressed = args.input[:-3]
    except subprocess.CalledProcessError as e:
        print("Error decompressing {}: {}".format(args.input, e), file=sys.stderr)
        sys.exit(1)
else:
    print("Already decompressed {}".format(args.input), file=sys.stderr)
    decompressed = args.input

# Move decompressed to args.output
if args.link:
    try:
        print("Linking {}".format(args.input), file=sys.stderr)
        #os.rename(decompressed, args.output)
        os.link(decompressed, args.output)
    except OSError as e:
        print('Error: Could not link decompressed {} file to output file:\n{}'.format(decompressed, e), file=sys.stderr)
        sys.exit(1)
else:
    try:
        # Copy file
        print("Copying {}".format(args.input), file=sys.stderr)
        subprocess.call(['cp', decompressed, args.output])
    except OSError as e:
        print('Error: Could not copy decompressed {} file to output file:\n{}'.format(decompressed, e), file=sys.stderr)
        sys.exit(1)

