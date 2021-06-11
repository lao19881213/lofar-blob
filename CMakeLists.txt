cmake_minimum_required (VERSION 3.1.0)

project(lofar-blob VERSION 3.2.10)

# Reuse common cmake infrastructure
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/askap-cmake)
	execute_process(COMMAND git pull
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/askap-cmake)
else ()
	execute_process(COMMAND git clone https://bitbucket.csiro.au/scm/askapsdp/askap-cmake.git
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endif ()
set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/askap-cmake")

# uninstall target
if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()

set(LOFAR_RELEASE "LOFAR-Release-${PROJECT_VERSION_MAJOR}_${PROJECT_VERSION_MINOR}_${PROJECT_VERSION_PATCH}" )

# Checkout code from svn and patch it
execute_process(COMMAND rm -rf Blob
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	RESULT_VARIABLE RM_CODE)

unset(LOFAR_BLOB_PATCHED CACHE)

execute_process(
	COMMAND svn checkout https://svn.astron.nl/LOFAR/tags/${LOFAR_RELEASE}/LCS/Blob/
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	RESULT_VARIABLE SVN_CO_CODE)
if (NOT SVN_CO_CODE EQUAL 0)
	message(STATUS "Subversion checkout failed, check output and try again")
	set(LOFAR_BLOB_PATCHED DONE)
endif()
if (NOT LOFAR_BLOB_PATCHED)
	execute_process(
		COMMAND patch -p0 -i ../patches/std_namespace.patch
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Blob
		RESULT_VARIABLE PATCH_CODE)
	if (NOT PATCH_CODE EQUAL 0)
		message(FATAL_ERROR "Patch application failed, check output and try again")
	endif()
	set(LOFAR_BLOB_PATCHED ON CACHE BOOL "Blob sources have been patched")
endif()


# Process input files for Flex and Bison
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)

bison_target(KeyParse Blob/src/KeyParse.yy 
	${CMAKE_BINARY_DIR}/KeyParse.cc
  COMPILE_FLAGS "-y -pKeyParse")

flex_target(KeyTokenize Blob/src/KeyTokenize.ll 
  ${CMAKE_BINARY_DIR}/KeyTokenize.cc
  COMPILE_FLAGS "-PKeyTokenize")

add_flex_bison_dependency(KeyTokenize KeyParse)

# Create symbolic link from KeyParse.h -> KeyParse.hh, because KeyParser.cc
# #include's KeyParse.h.
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
  KeyParse.hh
  KeyParse.h
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

# On Apple, bison creates KeyParse.cc.h, instead of KeyParse.hh. So, when on
# Apple, we need to create another symbolic link KeyParse.hh -> KeyParse.cc.h
if(APPLE)
  execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
    KeyParse.cc.h
    KeyParse.hh
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif(APPLE)


# Add current binary directory to include, because that's where flex/bison
# will output the files they generate.
include_directories(${CMAKE_CURRENT_BINARY_DIR})


#this should have dowloaded the whole package - should add a check.

include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})
find_package(LofarCommon REQUIRED)
include_directories( ${LofarCommon_INCLUDE_DIR} )
find_package(Casacore REQUIRED COMPONENTS casa)

include_directories(${CASACORE_INCLUDE_DIRS})
add_definitions(-DHAVE_AIPSPP)
add_definitions(-Dcasa=casacore)


if (CASACORE3 OR CXX11)
	set(CMAKE_CXX_STANDARD 11)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

option (ENABLE_SHARED "Build shared libraries" YES)
option (ENABLE_RPATH "Include rpath in executables and shared libraries" YES)

if (ENABLE_SHARED)
option (BUILD_SHARED_LIBS "" YES)
    if (ENABLE_RPATH)
        # Set RPATH to use for installed targets; append linker search path
        set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib" )
        set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
        set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    endif (ENABLE_RPATH)
endif(ENABLE_SHARED)

message (STATUS "CMAKE_SYSTEM .......... = ${CMAKE_SYSTEM}")
message (STATUS "CMAKE_BUILD_TYPE ...... = ${CMAKE_BUILD_TYPE}")
message (STATUS "Modules to be built ... = ${_modules}")
message (STATUS "BUILD_SHARED_LIBS ..... = ${BUILD_SHARED_LIBS}")
message (STATUS "ENABLE_RPATH .......... = ${ENABLE_RPATH}")
message (STATUS "CMAKE_CXX_COMPILER .... = ${CMAKE_CXX_COMPILER}")
message (STATUS "CMAKE_CXX_FLAGS ....... = ${CMAKE_CXX_FLAGS}")
message (STATUS "C++11 support ......... = ${CXX11}")
message (STATUS "LOFAR Common .......... = ${LOFAR_COMMON_LIBRARY}:${LOFAR_COMMON_INCLUDE_DIR}")

add_library(Blob  
Blob/src/BlobIBufStream.cc
Blob/src/BlobStreamable.cc
Blob/src/KeyValueMap.cc
Blob/src/BlobString.cc
Blob/src/BlobOBufStream.cc
Blob/src/BlobStringType.cc
Blob/src/BlobAipsIO.cc
Blob/src/BlobIBufChar.cc
Blob/src/BlobArray.cc
Blob/src/BlobOStream.cc
Blob/src/BlobOBufNull.cc
Blob/src/BlobOBufChar.cc
Blob/src/BlobHeader.cc
Blob/src/BlobIStream.cc
${BISON_KeyParse_OUTPUTS}
${FLEX_KeyTokenize_OUTPUTS}
Blob/src/KeyParser.cc
Blob/src/BlobOBufString.cc
Blob/src/BlobFieldSet.cc
Blob/src/BlobField2.cc
Blob/src/KeyValue.cc
)

include_directories( Blob/include )

install (
TARGETS Blob
RUNTIME DESTINATION bin
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
LIBRARY PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

target_link_libraries(
	Blob
        ${LofarCommon_LIBRARY}
	${CASACORE_LIBRARIES}
)
install (FILES

  Blob/include/Blob/BlobAipsIO.h
  Blob/include/Blob/BlobArray.h
  Blob/include/Blob/BlobArray.tcc
  Blob/include/Blob/BlobArrayHeader.h
  Blob/include/Blob/BlobException.h
  Blob/include/Blob/BlobField.h
  Blob/include/Blob/BlobField.tcc
  Blob/include/Blob/BlobFieldSet.h
  Blob/include/Blob/BlobHeader.h
  Blob/include/Blob/BlobIBufChar.h
  Blob/include/Blob/BlobIBuffer.h
  Blob/include/Blob/BlobIBufStream.h
  Blob/include/Blob/BlobIBufString.h
  Blob/include/Blob/BlobIBufVector.h
  Blob/include/Blob/BlobIStream.h
  Blob/include/Blob/BlobOBufChar.h
  Blob/include/Blob/BlobOBuffer.h
  Blob/include/Blob/BlobOBufNull.h
  Blob/include/Blob/BlobOBufStream.h
  Blob/include/Blob/BlobOBufString.h
  Blob/include/Blob/BlobOBufVector.h
  Blob/include/Blob/BlobOStream.h
  Blob/include/Blob/BlobSTL.h
  Blob/include/Blob/BlobSTL.tcc
  Blob/include/Blob/BlobStreamable.h
  Blob/include/Blob/BlobString.h
  Blob/include/Blob/BlobStringTraits.h
  Blob/include/Blob/BlobStringType.h
  Blob/include/Blob/KeyParser.h
  Blob/include/Blob/KeyValue.h
  Blob/include/Blob/KeyValueMap.h
  
  DESTINATION include/Blob
  )




