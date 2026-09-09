# This source file is part of the Swift.org open source project
#
# Copyright (c) 2025 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

cmake_minimum_required(VERSION 3.29)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(SwiftToolchainSarif LANGUAGES Swift)

# The subdirectory into which host libraries will be installed.
set(SWIFT_HOST_LIBRARIES_SUBDIRECTORY "swift/host")

if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}")
endif()
if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}")
endif()
if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()

set(CMAKE_MACOSX_RPATH YES)

include(AddSARIFLibrary)

# Package.swift declares 'swiftLanguageModes: [.v6]'. Applied per-target in
# 'add_sarif_library' rather than through CMAKE_Swift_LANGUAGE_VERSION, which
# would also be inherited by dependencies added below via FetchContent.
set(SARIF_SWIFT_LANGUAGE_VERSION 6)

if(NOT DEFINED SARIF_PACKAGE_NAME)
  set(SARIF_PACKAGE_NAME "${SWIFT_MODULE_ABI_NAME_PREFIX}${PROJECT_NAME}")
endif()

# Determine the module triple, used to lay out .swiftmodule directories.
if("${SWIFT_HOST_MODULE_TRIPLE}" STREQUAL "")
  set(module_triple_command "${CMAKE_Swift_COMPILER}" -print-target-info)
  if(CMAKE_Swift_COMPILER_TARGET)
    list(APPEND module_triple_command -target ${CMAKE_Swift_COMPILER_TARGET})
  endif()
  execute_process(COMMAND ${module_triple_command} OUTPUT_VARIABLE target_info_json)
  string(JSON SWIFT_HOST_MODULE_TRIPLE GET "${target_info_json}" "target" "moduleTriple")
endif()
message(STATUS "Module triple: ${SWIFT_HOST_MODULE_TRIPLE}")

# Matches the swift-collections pin in the Swift toolchain's
# update-checkout-config.json, which is also the floor in Package.swift. Only
# consulted when '_SwiftCollections_SourceDIR' is not supplied; the toolchain
# build always supplies it, which also keeps configuration free of network
# access.
set(SARIF_SWIFT_COLLECTIONS_TAG "1.1.6")

# Cached so that an enclosing build can read this and install the targets
# alongside this package's own libraries.
set(SARIF_SWIFT_COLLECTIONS_TARGETS
  OrderedCollections
  InternalCollectionsUtilities
  CACHE INTERNAL "swift-collections targets built for swift-toolchain-sarif")

# swift-collections provides the 'OrderedCollections' module. When this package
# is built as part of a larger build the enclosing project may already have made
# that target available, in which case reuse it rather than declaring a second
# copy. Note that this requires the enclosing project to have created the target
# before adding this package.
if(NOT TARGET OrderedCollections)
  include(FetchContent)
  if(_SwiftCollections_SourceDIR)
    message(STATUS "_SwiftCollections_SourceDIR provided, using swift-collections checkout at ${_SwiftCollections_SourceDIR}")
    FetchContent_Declare(SwiftCollections
      SOURCE_DIR ${_SwiftCollections_SourceDIR})
  else()
    message(STATUS "_SwiftCollections_SourceDIR not provided, checking out swift-collections ${SARIF_SWIFT_COLLECTIONS_TAG}")
    FetchContent_Declare(SwiftCollections
      GIT_REPOSITORY https://github.com/apple/swift-collections.git
      GIT_TAG ${SARIF_SWIFT_COLLECTIONS_TAG})
  endif()
  FetchContent_MakeAvailable(SwiftCollections)

  # Keep the modules this package does not use out of the default target;
  # 'OrderedCollections' is still built because our targets link it.
  FetchContent_GetProperties(SwiftCollections BINARY_DIR collections_binary_dir)
  set_property(DIRECTORY "${collections_binary_dir}" PROPERTY EXCLUDE_FROM_ALL TRUE)

  # swift-collections sets its own CMAKE_*_OUTPUT_DIRECTORY. This package's
  # libraries record a dependency on 'libOrderedCollections', so it has to be
  # built and installed next to them.
  foreach(collections_target ${SARIF_SWIFT_COLLECTIONS_TARGETS})
    set_target_properties(${collections_target} PROPERTIES
      LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
      ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")

    if(PROJECT_IS_TOP_LEVEL OR SARIF_INSTALL_TARGETS)
      install(TARGETS ${collections_target}
        ARCHIVE DESTINATION lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}
        LIBRARY DESTINATION lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}
        RUNTIME DESTINATION bin
      )
      install(FILES $<TARGET_PROPERTY:${collections_target},Swift_MODULE_DIRECTORY>/${collections_target}.swiftmodule
        DESTINATION lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}/${collections_target}.swiftmodule
        RENAME ${SWIFT_HOST_MODULE_TRIPLE}.swiftmodule)
      install(FILES $<TARGET_PROPERTY:${collections_target},Swift_MODULE_DIRECTORY>/${collections_target}.swiftdoc
        DESTINATION lib/${SWIFT_HOST_LIBRARIES_SUBDIRECTORY}/${collections_target}.swiftmodule
        RENAME ${SWIFT_HOST_MODULE_TRIPLE}.swiftdoc
        OPTIONAL)
    endif()
  endforeach()
endif()

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
