#!/usr/bin/env python3

"""
A script to vendor Rust crates

Copyright 2022-2024 Vladislav 'fsLeg' Borisov, Moscow, Russia
All rights reserved.

Redistribution and use of this script, with or without modification, is
permitted provided that the following conditions are met:

1. Redistributions of this script must retain the above copyright
   notice, this list of conditions and the following disclaimer.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
   EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

from os import makedirs, walk
from os.path import join
from hashlib import sha256
from glob import glob
import json
import tarfile

def createVendor(vendordir, cratedir):
    "We extract each crate, create an empty .cargo-ok file, calculate sha256 sum for every file inside the crate and crate file itself and put it into .cargo-checksum.json"
    crate_path = ""
    crate_checksums = []
    crate_files = []
    makedirs(vendordir, exist_ok=True)
    for crate in glob(f"{cratedir}/*.crate"):
        with tarfile.open(crate, 'r:*') as archive:
            archive.extractall(path=vendordir, filter='data')
            crate_path = f"{vendordir}/{crate[crate.rfind('/')+1:].replace('.crate', '')}"
            open(f"{crate_path}/.cargo-ok", "a").close()
            for root, dirs, files in walk(f"{crate_path}"):
                crate_files.extend(join(root, name) for name in files)
            for file in crate_files:
                with open(file, "rb") as opened_file:
                    crate_checksums.append(sha256(opened_file.read()).hexdigest())
            with open(f"{crate_path}/.cargo-checksum.json", "w") as crate_json:
                with open(crate, 'rb') as crate_file:
                    json.dump({"files": dict(zip([file.replace(f"{crate_path}/", "") for file in crate_files], crate_checksums)), "package": sha256(crate_file.read()).hexdigest()}, crate_json)
            crate_files = []
            crate_checksums = []

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
                        prog="mkvendor.py",
                        description="This scripts properly vendors downloaded crates for offline builds"
                        )
    parser.add_argument("-d", "--directory", help="Directory of a Rust program to vendor crates for")
    parser.add_argument("-c", "--crates",    help="Directory with downloaded .crate files to vendor")
    args = parser.parse_args()

    workdir = args.directory
    cratedir = args.crates

    createVendor(f"{workdir}/vendor", cratedir)
