#!/usr/bin/env python3
"""
Execute R (library virfinder) on a FASTA file
"""
import os
import sys
import argparse
import subprocess
import logging
import time
import tempfile
from string import Template

def has_r():
    """
    Check if R is installed
    """
    try:
        subprocess.call(['Rscript', '--version'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def has_virfinder():
    """
    Check if VirFinder is installed
    """
    try:
        stdin = ["echo", "library('VirFinder');"]
        rscript = ["Rscript", "--vanilla", "--no-save", "-"]
        # Pipe stdin to Rscript
        echocmd = subprocess.Popen(stdin, stdout=subprocess.PIPE)
        rscriptcmd = subprocess.Popen(rscript, stdin=echocmd.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        #Check exit code
        rscriptcmd.wait()
        return rscriptcmd.returncode == 0

    except subprocess.CalledProcessError:
        return False

def make_script(inputfile, outputfile):
    currentTimeStamp = time.strftime("%Y%m%d%H%M%S")
    template = Template("""
# Auto generated script, $DATE
library('VirFinder');
Result <- VF.pred('$INPUT');
write.csv(Result, file='$OUTPUT', row.names=TRUE);
""")

    script = template.substitute(
        INPUT=inputfile,
        OUTPUT=outputfile,
        DATE=currentTimeStamp)
    
    return script


if __name__ == "__main__":
    args = argparse.ArgumentParser(description="Execute R (library virfinder) on a FASTA file")
    args.add_argument("-i", "--input", required=True, help="Input FASTA file")
    args.add_argument("-o", "--output", required=True, help="Output file")
    args.add_argument("-t", "--tmpdir", help="Temporary directory [default: %(default)s]", default=tempfile.gettempdir())
    
    args.add_argument("--verbose", action="store_true", help="Enable verbose output")
    args = args.parse_args()

    logger = logging.getLogger(__name__)
    if args.verbose:
        DELETE=False
        logLevel = logging.DEBUG
    else:
        DELETE=True
        logLevel = logging.WARN
    logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=logLevel)

    

    if not has_r():
        print("Error: R is not installed", file=sys.stderr)
        sys.exit(1)
    else:
        logger.info("R is installed")

    if not has_virfinder():
        print("Error: VirFinder is not installed", file=sys.stderr)
        sys.exit(1)
    else:
        logger.info("VirFinder is installed")


    with tempfile.NamedTemporaryFile(delete=DELETE, suffix='.R', mode='w', dir=args.tmpdir) as tmp:
        logger.info("Writing R script to temporary file %s" % tmp.name)
        scriptText = make_script(args.input, args.output)

        tmp.write(scriptText)
        tmp.flush()
        process = subprocess.Popen(['Rscript', '--vanilla', '--no-save', tmp.name], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        process.wait()

        if process.returncode != 0:
            logger.error("Error: R script failed: %s %s" % (process.returncode, tmp.name))
            logger.warning("VirFinder output:\n%s" % process.stdout.read().decode('utf-8').replace('\n', '\n  '))
            logger.warning("VirFinder error:\n%s" % process.stderr.read().decode('utf-8').replace('\n', '\n  '))
            
            sys.exit(1)
        else:
            logger.info("VirFinder finished: %s" % args.output)
            logger.debug("VirFinder output:\n%s" % process.stdout.read().decode('utf-8').replace('\n', '\n  '))
            logger.debug("VirFinder messages:\n%s" % process.stderr.read().decode('utf-8').replace('\n', '\n  '))
            tmp.close()