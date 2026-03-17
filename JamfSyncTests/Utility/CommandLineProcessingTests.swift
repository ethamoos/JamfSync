//
//  Copyright 2026, Jamf
//

@testable import Jamf_Sync
import XCTest

final class CommandLineProcessingTests: XCTestCase {
    var commandLineProcessing: CommandLineProcessing!
    var mockDataModel: MockDataModel!
    var mockDataPersistence: MockDataPersistence!
    var srcDp: MockDistributionPointSync!
    var dstDp: MockDistributionPointSync!
    var jamfProInstance: MockJamfProInstance!

    override func setUp() {
        super.setUp()

        // Create mock distribution points
        srcDp = MockDistributionPointSync(name: "Source DP")
        dstDp = MockDistributionPointSync(name: "Destination DP")

        // Create mock Jamf Pro instance
        jamfProInstance = MockJamfProInstance()
        jamfProInstance.id = UUID()
        dstDp.jamfProInstanceId = jamfProInstance.id

        // Create mock data persistence
        mockDataPersistence = MockDataPersistence()

        // Create mock data model
        mockDataModel = MockDataModel()
        mockDataModel.distributionPoints = [srcDp, dstDp]
        mockDataModel.jamfProInstances = [jamfProInstance]

        // Create command line processing
        commandLineProcessing = CommandLineProcessing(dataModel: mockDataModel, dataPersistence: mockDataPersistence)
    }

    override func tearDown() {
        commandLineProcessing = nil
        mockDataModel = nil
        mockDataPersistence = nil
        srcDp = nil
        dstDp = nil
        jamfProInstance = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_process_happyPath() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(mockDataModel.loadCalled, "DataModel.load should be called")
        XCTAssertTrue(mockDataModel.loadingInProgressGroupWasCalled, "DispatchGroup.wait() should be called")
        XCTAssertTrue(srcDp.prepareDpCalled, "Source DP prepareDp should be called")
        XCTAssertTrue(dstDp.prepareDpCalled, "Destination DP prepareDp should be called")
    }

    func test_process_withForceSync() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-f"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.forceSync, "forceSync should be true")
        XCTAssertTrue(srcDp.copyFilesCalled, "copyFiles should be called")
    }

    func test_process_withProgress() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-p"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.showProgress, "showProgress should be true")
    }

    func test_process_withRemoveFilesNotOnSource() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-r"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.removeFilesNotOnSrc, "removeFilesNotOnSrc should be true")
    }

    func test_process_withRemovePackagesNotOnSource() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-rp"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.removePackagesNotOnSrc, "removePackagesNotOnSrc should be true")
    }

    func test_process_withDryRun() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-dr"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.dryRun, "dryRun should be true")
    }

    func test_process_withAllOptions() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP", "-f", "-r", "-rp", "-p", "-dr"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
        XCTAssertTrue(argumentParser.forceSync, "forceSync should be true")
        XCTAssertTrue(argumentParser.removeFilesNotOnSrc, "removeFilesNotOnSrc should be true")
        XCTAssertTrue(argumentParser.removePackagesNotOnSrc, "removePackagesNotOnSrc should be true")
        XCTAssertTrue(argumentParser.showProgress, "showProgress should be true")
        XCTAssertTrue(argumentParser.dryRun, "dryRun should be true")
    }

    func test_process_withCombinedDpName() throws {
        // Given
        let srcDpWithServer = MockDistributionPointSync(name: "JCDS")
        srcDpWithServer.jamfProInstanceName = "Stage"
        let dstDpWithServer = MockDistributionPointSync(name: "JCDS")
        dstDpWithServer.jamfProInstanceName = "Prod"

        mockDataModel.distributionPoints = [srcDpWithServer, dstDpWithServer]

        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "JCDS:Stage", "-d", "JCDS:Prod"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should return true on success")
    }

    // MARK: - Missing Parameters Tests

    func test_process_missingSourceDp() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when source DP is missing")
        XCTAssertFalse(mockDataModel.loadCalled, "DataModel.load should not be called")
    }

    func test_process_missingDestinationDp() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when destination DP is missing")
        XCTAssertFalse(mockDataModel.loadCalled, "DataModel.load should not be called")
    }

    func test_process_missingBothDps() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when both DPs are missing")
        XCTAssertFalse(mockDataModel.loadCalled, "DataModel.load should not be called")
    }

    // MARK: - DP Not Found Tests

    func test_process_sourceDpNotFound() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "NonExistent DP", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when source DP is not found")
        XCTAssertTrue(mockDataModel.loadCalled, "DataModel.load should be called")
    }

    func test_process_destinationDpNotFound() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "NonExistent DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when destination DP is not found")
        XCTAssertTrue(mockDataModel.loadCalled, "DataModel.load should be called")
    }

    func test_process_bothDpsNotFound() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "NonExistent Source", "-d", "NonExistent Dest"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false when both DPs are not found")
        XCTAssertTrue(mockDataModel.loadCalled, "DataModel.load should be called")
    }

    // MARK: - Synchronization Flags Tests

    func test_process_synchronizationInProgressFlag() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "Source DP", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        XCTAssertFalse(mockDataModel.synchronizationInProgress, "synchronizationInProgress should initially be false")

        // When
        _ = commandLineProcessing.process(argumentParser: argumentParser)

        // Then - synchronizationInProgress is set to true during processing and false after
        XCTAssertFalse(mockDataModel.synchronizationInProgress, "synchronizationInProgress should be false after completion")
    }

    // MARK: - Edge Cases

    func test_process_emptyDpNames() throws {
        // Given
        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "", "-d", ""])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertFalse(result, "Process should return false with empty DP names")
    }

    func test_process_dpNameWithSpecialCharacters() throws {
        // Given
        let specialDp = MockDistributionPointSync(name: "DP-Name_With.Special@Chars")
        mockDataModel.distributionPoints = [specialDp, dstDp]

        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "DP-Name_With.Special@Chars", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should handle DP names with special characters")
    }

    func test_process_dpNameWithSpaces() throws {
        // Given
        let spaceDp = MockDistributionPointSync(name: "DP With Spaces")
        mockDataModel.distributionPoints = [spaceDp, dstDp]

        let argumentParser = ArgumentParser(arguments: ["JamfSync", "-s", "DP With Spaces", "-d", "Destination DP"])
        _ = argumentParser.processArgs()

        // When
        let result = commandLineProcessing.process(argumentParser: argumentParser)

        // Then
        XCTAssertTrue(result, "Process should handle DP names with spaces")
    }
}

// MARK: - Mock Classes

class MockDataModel: DataModel {
    var distributionPoints: [DistributionPoint] = []
    var jamfProInstances: [JamfProInstance] = []
    var loadCalled = false
    var loadingInProgressGroupWasCalled = false

    override func load(dataPersistence: DataPersistence, isProcessingCommandLine: Bool = false) {
        loadCalled = true

        // Populate savableItems with jamfProInstances
        savableItems = SavableItems()
        for instance in jamfProInstances {
            savableItems.items.append(instance)
        }

        // Simulate the async loading behavior
        // The real DataModel.loadDps() enters the group, does async work, then leaves
        // We need to match this pattern: enter() then leave()
        if let group = loadingInProgressGroup {
            loadingInProgressGroupWasCalled = true
            group.enter()  // Must enter before we can leave
            group.leave()  // Immediately leave since we have no async work
        }
    }

    override func findDpByCombinedName(name: String) -> DistributionPoint? {
        let nameParts = name.components(separatedBy: ":")
        guard nameParts.count > 0 else { return nil }

        if nameParts.count == 1 {
            return distributionPoints.first { $0.name == name }
        }

        let dpName = nameParts[0]
        let serverName = nameParts[1]
        return distributionPoints.first { $0.name == dpName && $0.jamfProInstanceName == serverName }
    }

    override func findJamfProInstance(id: UUID?) -> JamfProInstance? {
        guard let id else { return nil }
        return jamfProInstances.first { $0.id == id }
    }
}

class MockDataPersistence: DataPersistence {
    init() {
        let dataManager = DataManager()
        super.init(dataManager: dataManager)
    }

    override func loadSavableItems() -> SavableItems {
        return SavableItems()
    }
}
