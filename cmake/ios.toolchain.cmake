# This file is based off of the Platform/Darwin.cmake and Platform/UnixPaths.cmake
# files which are included with CMake 2.8.4
# It has been altered for iOS development
# Initial source: https://code.google.com/p/ios-cmake/

# Options:
#
# IOS_PLATFORM = OS (default) or SIMULATOR
#   This decides if SDKS will be selected from the iPhoneOS.platform or iPhoneSimulator.platform folders
#   OS - the default, used to build for iPhone and iPad physical devices, which have an arm arch.
#   SIMULATOR - used to build for the Simulator platforms, which have an x86 arch.
#
# CMAKE_IOS_PLATFORM_DEVELOPER_ROOT = automatic(default) or /path/to/platform/Developer folder
#   By default this location is automatcially chosen based on the IOS_PLATFORM value above.
#   If set manually, it will override the default location and force the user of a particular Developer Platform
#
# CMAKE_IOS_SDK_ROOT = automatic(default) or /path/to/platform/Developer/SDKs/SDK folder
#   By default this location is automatcially chosen based on the CMAKE_IOS_PLATFORM_DEVELOPER_ROOT value.
#   In this case it will always be the most up-to-date SDK found in the CMAKE_IOS_PLATFORM_DEVELOPER_ROOT path.
#   If set manually, this will force the use of a specific SDK version

# Macros:
#
# set_xcode_property (TARGET XCODE_PROPERTY XCODE_VALUE)
#  A convenience macro for setting xcode specific properties on targets
#  example: set_xcode_property (myioslib IPHONEOS_DEPLOYMENT_TARGET "3.1")
#
# find_host_package (PROGRAM ARGS)
#  A macro used to find executable programs on the host system, not within the iOS environment.
#  Thanks to the android-cmake project for providing the command

# Standard settings
set (PLATFORM_NAME "iOS" CACHE STRING "Platform name")

set (CMAKE_SYSTEM_NAME Darwin)
set (CMAKE_SYSTEM_VERSION 1)
set (UNIX True)
set (APPLE True)
set (IOS True)

# Required as of cmake 2.8.10
set (CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING "Force unset of the deployment target for iOS" FORCE)

# Determine the cmake host system version so we know where to find the iOS SDKs
find_program (CMAKE_UNAME uname /bin /usr/bin /usr/local/bin)
if (CMAKE_UNAME)
    exec_program(uname ARGS -r OUTPUT_VARIABLE CMAKE_HOST_SYSTEM_VERSION)
    string (REGEX REPLACE "^([0-9]+)\\.([0-9]+).*$" "\\1" DARWIN_MAJOR_VERSION "${CMAKE_HOST_SYSTEM_VERSION}")
endif (CMAKE_UNAME)

# Setup iOS platform unless specified manually with IOS_PLATFORM
if (NOT DEFINED IOS_PLATFORM)
    set (IOS_PLATFORM "OS")
endif (NOT DEFINED IOS_PLATFORM)
set (IOS_PLATFORM ${IOS_PLATFORM} CACHE STRING "Type of iOS Platform")

# All iOS/Darwin specific settings - some may be redundant
set (CMAKE_SHARED_LIBRARY_PREFIX "lib")
set (CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set (CMAKE_SHARED_MODULE_PREFIX "lib")
set (CMAKE_SHARED_MODULE_SUFFIX ".so")
set (CMAKE_MODULE_EXISTS 1)
set (CMAKE_DL_LIBS "")

set (CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set (CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set (CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set (CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

# hack: if a new cmake (which uses CMAKE_INSTALL_NAME_TOOL) runs on an old build tree
# (where install_name_tool was hardcoded) and where CMAKE_INSTALL_NAME_TOOL isn't in the cache
# and still cmake didn't fail in CMakeFindBinUtils.cmake (because it isn't rerun)
# hardcode CMAKE_INSTALL_NAME_TOOL here to install_name_tool, so it behaves as it did before, Alex
if (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
    find_program(CMAKE_INSTALL_NAME_TOOL install_name_tool)
endif (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)

# Setup building for arm64 or not
if (NOT DEFINED BUILD_ARM64)
    set (BUILD_ARM64 true)
endif (NOT DEFINED BUILD_ARM64)
set (BUILD_ARM64 ${BUILD_ARM64} CACHE STRING "Build arm64 arch or not")

# Check the platform selection and setup for developer root
if (${IOS_PLATFORM} STREQUAL "OS")
    set (IOS_PLATFORM_LOCATION "iPhoneOS.platform")

    # This causes the installers to properly locate the output libraries
    set (CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos")
elseif (${IOS_PLATFORM} STREQUAL "SIMULATOR")
    set (IOS_PLATFORM_LOCATION "iPhoneSimulator.platform")

    # This causes the installers to properly locate the output libraries
    set (CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphonesimulator")
else (${IOS_PLATFORM} STREQUAL "OS")
    message (FATAL_ERROR "Unsupported IOS_PLATFORM value selected. Please choose OS or SIMULATOR")
endif (${IOS_PLATFORM} STREQUAL "OS")

# Setup iOS developer location unless specified manually with CMAKE_IOS_PLATFORM_DEVELOPER_ROOT
# Xcode 4.3 changed the installation location, so choose the most recent one available
set (CMAKE_IOS_DEVELOPER_ROOT "/Applications/Xcode.app/Contents/Developer")
if (NOT DEFINED CMAKE_IOS_PLATFORM_DEVELOPER_ROOT)
    set (CMAKE_IOS_PLATFORM_DEVELOPER_ROOT "${CMAKE_IOS_DEVELOPER_ROOT}/Platforms/${IOS_PLATFORM_LOCATION}/Developer")
endif (NOT DEFINED CMAKE_IOS_PLATFORM_DEVELOPER_ROOT)
set (CMAKE_IOS_PLATFORM_DEVELOPER_ROOT ${CMAKE_IOS_PLATFORM_DEVELOPER_ROOT} CACHE PATH "Location of iOS Platform")

# Find and use the most recent iOS sdk unless specified manually with CMAKE_IOS_SDK_ROOT
if (NOT DEFINED CMAKE_IOS_SDK_ROOT)
    file (GLOB _CMAKE_IOS_SDKS "${CMAKE_IOS_PLATFORM_DEVELOPER_ROOT}/SDKs/*")
    if (_CMAKE_IOS_SDKS)
        list (SORT _CMAKE_IOS_SDKS)
        list (REVERSE _CMAKE_IOS_SDKS)
        list (GET _CMAKE_IOS_SDKS 0 CMAKE_IOS_SDK_ROOT)
    else (_CMAKE_IOS_SDKS)
        message (FATAL_ERROR "No iOS SDK's found in default search path ${CMAKE_IOS_PLATFORM_DEVELOPER_ROOT}."
                " Manually set CMAKE_IOS_SDK_ROOT or install the iOS SDK.")
    endif (_CMAKE_IOS_SDKS)
    message (STATUS "Toolchain using default iOS SDK: ${CMAKE_IOS_SDK_ROOT}")
endif (NOT DEFINED CMAKE_IOS_SDK_ROOT)
set (CMAKE_IOS_SDK_ROOT ${CMAKE_IOS_SDK_ROOT} CACHE PATH "Location of the selected iOS SDK")

# Set the sysroot default to the most recent SDK
set (CMAKE_OSX_SYSROOT ${CMAKE_IOS_SDK_ROOT} CACHE PATH "Sysroot used for iOS support")

# set the architecture for iOS
if (${IOS_PLATFORM} STREQUAL "OS")
    set (IOS_ARCH armv7 armv7s arm64)
elseif (${IOS_PLATFORM} STREQUAL "SIMULATOR")
    set (IOS_ARCH i386 x86_64)
endif (${IOS_PLATFORM} STREQUAL "OS")
set (CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE STRING  "Build architecture for iOS")

# set installation folder
if (${IOS_PLATFORM} STREQUAL "OS")
    set (INSTALL_LIB_DIR_NAME "lib/device")
elseif (${IOS_PLATFORM} STREQUAL "SIMULATOR")
    set (INSTALL_LIB_DIR_NAME "lib/simulator")
endif (${IOS_PLATFORM} STREQUAL "OS")
set (INSTALL_LIB_DIR_NAME ${INSTALL_LIB_DIR_NAME} CACHE STRING  "Installation directory name for all components")

# Set IOS Min Version
set (IOS_VERSION_MIN "7.0" CACHE STRING "Minimum supported iOS version.")

if (${IOS_PLATFORM} STREQUAL "OS")
    set (IOS_VERSION_FLAG "-miphoneos-version-min=${IOS_VERSION_MIN}")
elseif (${IOS_PLATFORM} STREQUAL "SIMULATOR")
    set (IOS_VERSION_FLAG "-mios-simulator-version-min=${IOS_VERSION_MIN}")
endif (${IOS_PLATFORM} STREQUAL "OS")

# Set the find root to the iOS developer roots and to user defined paths
set (CMAKE_FIND_ROOT_PATH
    ${CMAKE_IOS_PLATFORM_DEVELOPER_ROOT}
    ${CMAKE_IOS_DEVELOPER_ROOT}
    ${CMAKE_IOS_DEVELOPER_ROOT}/usr/bin
    ${CMAKE_IOS_SDK_ROOT}
    ${CMAKE_PREFIX_PATH}
    CACHE string  "iOS find search path root"
)

# default to searching for frameworks first
set (CMAKE_FIND_FRAMEWORK FIRST)

# set up the default search directories for frameworks
set (CMAKE_SYSTEM_FRAMEWORK_PATH
    ${CMAKE_IOS_SDK_ROOT}/System/Library/Frameworks
    ${CMAKE_IOS_SDK_ROOT}/System/Library/PrivateFrameworks
    ${CMAKE_IOS_SDK_ROOT}/Developer/Library/Frameworks
)

# only search the iOS sdks, not the remainder of the host filesystem
set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Force the compilers to clang for iOS
include (CMakeForceCompiler)
CMAKE_FORCE_C_COMPILER (/usr/bin/clang Apple)
CMAKE_FORCE_CXX_COMPILER (/usr/bin/clang++ Apple)

# Force ar
set (CMAKE_AR /usr/bin/ar CACHE FILEPATH "" FORCE)
set (CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> <LINK_FLAGS> crs <TARGET> <OBJECTS>")
set (CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> <LINK_FLAGS> rs <TARGET> <OBJECTS>")
set (CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> <LINK_FLAGS> crs <TARGET> <OBJECTS>")
set (CMAKE_CXX_ARCHIVE_APPEND "<CMAKE_AR> <LINK_FLAGS> rs <TARGET> <OBJECTS>")


# Skip the platform compiler checks for cross compiling
set (CMAKE_CXX_COMPILER_WORKS TRUE)
set (CMAKE_C_COMPILER_WORKS TRUE)

# Hidden visibilty is required for cxx on iOS
set (CMAKE_C_FLAGS "${IOS_VERSION_FLAG} -isysroot ${CMAKE_OSX_SYSROOT}" CACHE STRING "")
set (CMAKE_CXX_FLAGS
    "${IOS_VERSION_FLAG} -fvisibility=hidden -fvisibility-inlines-hidden -std=gnu++11 -isysroot ${CMAKE_OSX_SYSROOT}"
    CACHE STRING ""
)

set (CMAKE_C_LINK_FLAGS "-Wl,-search_paths_first ${CMAKE_C_LINK_FLAGS}")
set (CMAKE_CXX_LINK_FLAGS "-Wl,-search_paths_first ${CMAKE_CXX_LINK_FLAGS}")

set (CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set (CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -headerpad_max_install_names")
set (CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -headerpad_max_install_names")
set (CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set (CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set (CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a")

# This little macro lets you set any XCode specific property
macro (set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE)
    set_property (TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY} ${XCODE_VALUE})
endmacro (set_xcode_property)

# This macro lets you find executable programs on the host system
macro (find_host_package)
    set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
    set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
    set (IOS FALSE)

    find_package(${ARGN})

    set (IOS TRUE)
    set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
    set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro (find_host_package)
