# the name of the target operating system
set(CMAKE_SYSTEM_NAME Windows)

# which tools to use
set(CMAKE_C_COMPILER /usr/bin/x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER /usr/bin/x86_64-w64-mingw32-windres)
# set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -lm
# -Isource_files/zlib_src/libzlibstatic.a -mwindows -lcomdlg32 -lole32 -luuid
# -lgdi32 -lcomctl32 -lwsock32 -lsupc++") Above line works on Ubuntu; below line
# works on OpenSUSE (my personal build platform), so switch between them as
# needed - Dasho
set(CMAKE_EXE_LINKER_FLAGS
    "-static -mwindows -Isource_files/zlib_src/libzlibstatic.a"
)

# here is where the target environment located
set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)

# adjust the default behaviour of the FIND_XXX() commands: search programs in
# the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# search headers and libraries in the target environment,
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_INSTALL_PREFIX
    ${CMAKE_FIND_ROOT_PATH}/usr
    CACHE FILEPATH "install path prefix"
)
