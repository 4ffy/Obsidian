
# COMPILING Obsidian

## Windows Dependencies (stub; in-progress)

1. MSVC Toolchain

2. ???

3. Profit

## Linux Dependencies (MSYS has some differences; see MSYS Cross-Compilation section below)

1. C++ compiler and associated tools
   * packages: `g++` `binutils`
   * if compiling with clang: `clang`
   * compiler and toolchain need C++17 capabilities

2. GNU make
   * package: `make`
   
3. CMake Utilities:
   * package: `cmake` 

4. FLTK 1.3 (optional)
   * website: http://www.fltk.org/
   * package: `libfltk1.3-dev`
   * You may also need: `libxft-dev` `libxinerama-dev` `libjpeg-dev` `libpng-dev` `libfontconfig1-dev`

5. zlib (optional)
   * website: http://www.zlib.net/
   * package: `zlib1g-dev`

6. FLEX
   * package: `flex`
   
7. Code formatting tools
   * package: `clang-tidy`
   * python package (optional, install with pip): `cmakelang`

## Linux Compilation

Assuming all those dependencies are met, then the following steps
will build the Obsidian binary. (The '>' is just the prompt)

    > cmake -B build
    > cmake --build build (-j# optional, with # being the number of cores you'd like to use)
    
Then, Obsidian can be launched with:

    > ./obsidian

## Windows Cross-Compilation on Linux using MinGW

You will need the `mingw-w64` package as well (or your distro's equivalent)

Similar to the above directions:

    > cmake -B build -DCMAKE_TOOLCHAIN_FILE=../Toolchain-mingw64.cmake (use Toolchain-mingw32.cmake for a 32-bit build)
    > cmake --build build (-j# optional, with # being the number of cores you'd like to use)

Then, Obsidian can be launched (in Windows) with:

    > obsidian.exe

## Windows Cross-Compilation using MSYS
You will need to install the following on top of the regular MSYS Mingw64 install:
   * package: `mingw-w64-(arch)-clang-tools-extra`
   * package: `mingw-w64-(arch)-cmake`

Similar to the above directions:

    > cmake -B build -G "MSYS Makefiles"
    > cmake --build build (-j# optional, with # being the number of cores you'd like to use)

Then, Obsidian can be launched (in Windows) with:

    > obsidian.exe
    
# INSTALLING Obsidian

This is a work-in-progress; needs to be revisited after the CMake conversion is finalized

