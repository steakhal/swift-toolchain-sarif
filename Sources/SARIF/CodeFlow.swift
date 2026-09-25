public import SARIFRecords

/// A SARIF `codeFlow`: an ordered account of how the analysis reached a result,
/// as one or more thread flows.
///
/// Only the properties Clang's ordinary diagnostics emit are modeled -- an
/// optional message and the thread flows -- which is enough to carry a
/// diagnostic's reasoning through a merge. The inner locations reuse the
/// ``Location`` model, so their artifact references are resolved on load and
/// re-emitted like any other location; a location whose artifact is not present
/// in the merged run is written by URI, which ``ArtifactLocationReference``
/// already does.
public struct CodeFlow: JSONRepresentableWithContext<CodeFlowRecord> {
  public var message: Message?
  public var threadFlows: [ThreadFlow]

  public init(message: Message? = nil, threadFlows: [ThreadFlow] = []) {
    self.message = message
    self.threadFlows = threadFlows
  }

  internal init(
    from record: CodeFlowRecord, sink: any ValidationSink,
    artifacts: ArtifactReferenceResolver,
    logicalLocations: LogicalLocationLoadMap
  ) throws {
    self.message = try record.message.map { try .init(from: $0, sink: sink) }
    self.threadFlows = try (record.threadFlows ?? []).map {
      try ThreadFlow(
        from: $0, sink: sink, artifacts: artifacts,
        logicalLocations: logicalLocations)
    }
  }

  internal func toJSON(with context: LocationSaveContext) throws
    -> CodeFlowRecord
  {
    .init(
      message: try message.toJSON(),
      threadFlows: try threadFlows.ifNotEmpty?.toJSON(with: context))
  }
}

/// A SARIF `threadFlow`: a sequence of locations along a single path.
public struct ThreadFlow: JSONRepresentableWithContext<ThreadFlowRecord> {
  public var message: Message?
  public var locations: [ThreadFlowLocation]

  public init(message: Message? = nil, locations: [ThreadFlowLocation] = []) {
    self.message = message
    self.locations = locations
  }

  internal init(
    from record: ThreadFlowRecord, sink: any ValidationSink,
    artifacts: ArtifactReferenceResolver,
    logicalLocations: LogicalLocationLoadMap
  ) throws {
    self.message = try record.message.map { try .init(from: $0, sink: sink) }
    self.locations = try record.locations.map {
      try ThreadFlowLocation(
        from: $0, sink: sink, artifacts: artifacts,
        logicalLocations: logicalLocations)
    }
  }

  internal func toJSON(with context: LocationSaveContext) throws
    -> ThreadFlowRecord
  {
    .init(
      message: try message.toJSON(),
      locations: try locations.toJSON(with: context))
  }
}

/// A SARIF `threadFlowLocation`: one step of a thread flow.
public struct ThreadFlowLocation: JSONRepresentableWithContext<
  ThreadFlowLocationRecord
>
{
  public var location: Location?
  public var importance: Importance?

  public init(location: Location? = nil, importance: Importance? = nil) {
    self.location = location
    self.importance = importance
  }

  internal init(
    from record: ThreadFlowLocationRecord, sink: any ValidationSink,
    artifacts: ArtifactReferenceResolver,
    logicalLocations: LogicalLocationLoadMap
  ) throws {
    self.location = try record.location.map {
      try Location(
        from: $0, sink: sink, artifacts: artifacts,
        logicalLocations: logicalLocations)
    }
    self.importance = record.importance
  }

  internal func toJSON(with context: LocationSaveContext) throws
    -> ThreadFlowLocationRecord
  {
    .init(location: try location.toJSON(with: context), importance: importance)
  }
}
