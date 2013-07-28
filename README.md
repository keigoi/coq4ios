#Coq4iOS
Coq4iOS is a prototypic implementation of [Coq](http://coq.inria.fr/) interactive environment on iPad.

Note that this software is still under heavy (re)construction. 
I just put them here now, because it may interest some future developers.
Often it even won't compile. Feel free to contact me if so.


## How to build
### Prerequisites 1: Xcode 4.6.3 & iOS SDK 6.1

- Available from Mac App Store and [Apple Developer](https://developer.apple.com/)

### Prerequisites 2: OCaml on iOS

- Available from [my clone repo](https://github.com/keigoi/ocaml-ios-psellos/) of [original OCaml on iOS](http://psellos.com/ocaml/). 
  - [OCaml on iOS](https://github.com/keigoi/ocaml-ios-psellos/releases/tag/4.00.1+xarm-3.1.8-v7+ios-sdk-6.1) 
    (if you have your own iPad)
  - [OCaml on iOS Simulator](https://github.com/keigoi/ocaml-ios-psellos/releases/tag/4.00.1+xsim-3.1.7+ios-sdk-6.1) 
    (if you want to run it on iOS Simulator)
  - Both are based on OCaml 4.00.1 and customized to be built with the latest Xcode and iOS SDK

- They are originally developed by [Psellos](http://psellos.com/ocaml/).  
  - To see what I changed from the original patch, check [commit log for OCamlXARM](https://github.com/keigoi/ocaml-ios-psellos/commits/psellos-ocamlxarm) and [OCamlXSIM](https://github.com/keigoi/ocaml-ios-psellos/commits/psellos-ocamlxsim) 

### Prerequisites 3: Host OCaml and Camlp5

If you don't have one, and are using [Homebrew](http://brew.sh/), type

	brew install ocaml camlp5

or if you are a [MacPorts](http://www.macports.org/) user:

	port install ocaml camlp5

__Caution__ install the same OCaml version as cross-compiler (`4.00.1` in this instruction).


### Step 1. Install OCamlXARM and/or OCamlXSIM

OCamlXARM: Follow the instructions from [psellos](http://psellos.com/ocaml/compile-to-iphone.html#buildocamlxarm).

	wget https://github.com/keigoi/ocaml-ios-psellos/archive/4.00.1+xarm-3.1.8-v7+ios-sdk-6.1.tar.gz
	tar zxf 4.00.1+xarm-3.1.8-v7+ios-sdk-6.1.tar.gz
	cd ocaml-ios-psellos-4.00.1-xarm-3.1.8-v7+ios-sdk-6.1/
	sh xarm-build all > xarm-build.log 2>&1
	make install

OCamlXSIM: Similarly, [psellos provides nicely detailed instructions](http://psellos.com/ocaml/compile-to-iossim.html#buildocamlxsim).

	wget https://github.com/keigoi/ocaml-ios-psellos/archive/4.00.1+xsim-3.1.7+ios-sdk-6.1.tar.gz
	tar zxf 4.00.1+xsim-3.1.7+ios-sdk-6.1.tar.gz
	cd ocaml-ios-psellos-4.00.1-xsim-3.1.7+ios-sdk-6.1
	sh xsim-build all > xsim-build.log 2>&1
	make install

### Step 2. Install Camlp5

	wget http://pauillac.inria.fr/~ddr/camlp5/distrib/src/camlp5-6.07.tgz

OCamlXARM:

	tar zxf camlp5-6.07.tgz
	mv camlp5-6.07 camlp5-6.07.xarm
	cd camlp5-6.07.xarm
	export PATH=/usr/local/ocamlxarm/v7/bin:$PATH
	./configure
	make -j8 world.opt
	make install

OCamlXSIM:	

	tar zxf camlp5-6.07.tgz
	mv camlp5-6.07 camlp5-6.07.xsim
	cd camlp5-6.07.xsim
	export PATH=/usr/local/ocamlxsim/bin:$PATH
	./configure
	make -j8 world.opt
	make install

### Step 3. Get Coq4iOS from repo

	git clone https://github.com/keigoi/coq4ios.git
	git submodule update --init

(The second step also fetches submodules - Coq and 7z source)

### Step 4. Edit Makefile.config

Change OCAMLHOST and CAMLP5HOST to point to your host-version OCaml and Camlp5.

	OCAMLHOST=/Users/keigoi/.opam/4.00.1+annot
	CAMLP5HOST=/Users/keigoi/.opam/4.00.1+annot/lib/camlp5
	OCAMLXARM=/usr/local/ocamlxarm/v7
	OCAMLXSIM=/usr/local/ocamlxsim


### Step 4. Cross-compile Coq

This step installs Coq's all *.cmxa files and some other stuff into `/usr/local/ocamlxarm/v7/lib/ocaml/coqlib` (or `/usr/local/ocamlxsim/lib/ocaml/coqlib`).

If you have installed OCamlXARM:

	cd coq4ios
	sh build-coqcross.sh xarm 2>&1 |tee coq-xarm-build.log
	sh build-coqcross.sh install_xarm

OCamlXSIM:

	cd coq4ios
	sh build-coqcross.sh xsim 2>&1 |tee coq-xsim-build.log
	sh build-coqcross.sh install_xsim


### Step 5. Build Coq Standard Library

This step will make `coq-8.4pl2-standard-libs-for-coq4ios.7z` at the project root, which contains Coq Standard Library files (`*.vo`) compressed by [7zip](http://www.7-zip.org/).

	sh build-coqcross.sh host 2>&1 |tee coq-host-build.log
	sh create_coqlib.sh

### Step 6. Build OCaml-part of Coq4iOS

This step prepares all files required by the next Xcode-build step.

- OCaml-part of Coq4iOS (built from ``src/*.ml``)
  - `obj-(armv7|i386)/libcoqios.a`
- OCaml's header files & runtime libraries (symbolic links)
  - `ocaml/(armv7|i386)/caml/*.h`
  - `ocaml/(armv7|i386)/lib*.a`
  - `ocaml/(armv7|i386)/coqlib/libcoqrun.a`

OCamlXARM:

	omake xarm
	
OCamlXSIM:

	omake xsim

### Step 7. Build Coq4iOS on Xcode

	open Coq4iOS/Coq4iOS.xcodeproj

Then build & run your own Coq on your device/simiulator :-)



----
author: Keigo IMAI (@keigoi on Twitter / keigo.imai __AT__ gmail.com)

