import SARIF
import SARIFMerge
import SARIFTests
import Testing

@Test
func mergeSingleFile() throws {
  let sink = StdOutValidationSink()

  let outputLog = SARIFLog()
  var merger = SARIFLogMerger(into: outputLog, sink: sink)

  let inputLog = try loadSarifLog(from: "test.sarif", sink: sink)
  try merger.merge(from: inputLog)

  // We don't handle `defaultConfiguration` yet.
  withKnownIssue {
    expectJSON(expected: inputLog, actual: outputLog)
  }
}

@Test
func mergeDuplicateFiles() throws {
  let sink = StdOutValidationSink()

  let outputLog = SARIFLog()
  var merger = SARIFLogMerger(into: outputLog, sink: sink)

  let inputLog1 = try loadSarifLog(from: "test.sarif", sink: sink)
  try merger.merge(from: inputLog1)
  let inputLog2 = try loadSarifLog(from: "test.sarif", sink: sink)
  try merger.merge(from: inputLog2)

  // We don't handle `defaultConfiguration` yet.
  withKnownIssue {
    expectJSON(expected: inputLog1, actual: outputLog)
  }
}

@Test
func mergePreservesCodeFlows() throws {
  let sink = StdOutValidationSink()

  let outputLog = SARIFLog()
  var merger = SARIFLogMerger(into: outputLog, sink: sink)

  // Merge the same file twice: its results deduplicate, and the surviving
  // result must keep the first input's code flow rather than dropping it.
  try merger.merge(from: loadSarifLog(from: "test.sarif", sink: sink))
  try merger.merge(from: loadSarifLog(from: "test.sarif", sink: sink))

  let steps =
    outputLog.runs
    .flatMap(\.results)
    .flatMap(\.codeFlows)
    .flatMap(\.threadFlows)
    .flatMap(\.locations)
    .compactMap { $0.location?.message?.defaultMessage?.text }
  #expect(steps.contains("Assuming pointer value is null"))
}
