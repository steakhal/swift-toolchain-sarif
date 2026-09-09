# This source file is part of the Swift.org open source project
#
# Copyright (c) 2025 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

add_sarif_library(SARIFMerge
  ArrayMerger.swift
  Merge.swift
  MergeHashable.swift
  MergeableWithIdentity.swift
  Merger.swift
  PropertyMerger.swift
)

target_link_sarif_libraries(SARIFMerge PUBLIC
  SARIF
  SARIFRecords)

target_link_libraries(${SARIF_TARGET_NAMESPACE}SARIFMerge PUBLIC
  OrderedCollections)
