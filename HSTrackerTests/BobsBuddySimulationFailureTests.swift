//
//  BobsBuddySimulationFailureTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// Every BobsBuddy failure that is not an unsupported interaction used to reach Sentry as the
/// same `System.AggregateException` string, so unrelated bugs shared one issue and one broken
/// .NET install could send hundreds of copies of a single event. These cover the parsing that
/// splits them apart, using the exception text of real reported events.
class BobsBuddySimulationFailureTests: HSTrackerTests {

    /// A genuine simulator bug: Bronze Timewalker's Rally trigger passing a null list into a
    /// helper. The helper is shared, so the frame below it is the one that names the card.
    private let nullReference = """
System.AggregateException: One or more errors occurred. (One or more errors occurred. (Object reference not set to an instance of an object))
 ---> System.AggregateException: One or more errors occurred. (Object reference not set to an instance of an object)
 ---> System.NullReferenceException: Object reference not set to an instance of an object
   at BobsBuddy.Utils.SafeRandom.TryGetRandom[String](List`1 list, String& item)
   at BobsBuddy.Minions.Dragon.BronzeTimewalker.<>c__DisplayClass5_0.<OnRally>b__0(Minion minion)
   at BobsBuddy.Simulation.Simulator.<>c__DisplayClass15_1.<PerformAttack>b__0()
   at BobsBuddy.Simulation.Trigger.Invoke()
   at BobsBuddy.Simulation.Simulator.PerformAttack(Minion attacker, Minion target)
   --- End of inner exception stack trace ---
   at System.Threading.Tasks.Task.Wait()
"""

    /// An incomplete .NET runtime. The simulator cannot run at all, so this repeats on every
    /// combat for as long as the app is open.
    private let missingAssembly = """
System.AggregateException: One or more errors occurred. (One or more errors occurred. (Could not load file or assembly 'System.Runtime.Intrinsics, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies.))
 ---> System.AggregateException: One or more errors occurred. (Could not load file or assembly 'System.Runtime.Intrinsics, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies.)
 ---> System.IO.FileNotFoundException: Could not load file or assembly 'System.Runtime.Intrinsics, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies.
File name: 'System.Runtime.Intrinsics, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'
   at System.Linq.Enumerable.Max(IEnumerable`1 source)
   at BobsBuddy.Simulation.Simulator.ResetPlayerStateAndUnbuffCloningGallery(PlayerState playerState, CloningGallery cloningGallery)
   at BobsBuddy.Simulation.Simulator.SetupFightCached(Input input)
   at BobsBuddy.Simulation.SimulationRunner.<>c__DisplayClass0_0.<SimulateMultiThreaded>g__RunSimulator|1(Int32 _)
 ---> (Inner Exception #1) System.IO.FileNotFoundException: Could not load file or assembly 'System.Runtime.Intrinsics, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies.
   at System.Linq.Enumerable.Max(IEnumerable`1 source)
"""

    // MARK: - The innermost exception

    /// The type has to come from the innermost exception of the primary chain, not from the
    /// AggregateException wrappers above it and not from the copies an AggregateException
    /// appends below the stacktrace.
    func testUsesTheInnermostExceptionType() {
        XCTAssertEqual(BobsBuddySimulationFailure(text: nullReference).exceptionType, "System.NullReferenceException")
        XCTAssertEqual(BobsBuddySimulationFailure(text: missingAssembly).exceptionType, "System.IO.FileNotFoundException")
    }

    /// `File name: '...'` sits between the innermost header and the frames, and reads like a
    /// header itself. Taking it would replace the real exception type.
    func testIgnoresNonExceptionHeaders() {
        let text = """
 ---> System.IO.FileNotFoundException: Could not load file or assembly 'System.Runtime.Intrinsics'
File name: 'System.Runtime.Intrinsics, Version=8.0.0.0'
   at BobsBuddy.Simulation.Simulator.SetupFightCached(Input input)
"""
        XCTAssertEqual(BobsBuddySimulationFailure(text: text).exceptionType, "System.IO.FileNotFoundException")
    }

    func testUnparseableTextDoesNotCrash() {
        let failure = BobsBuddySimulationFailure(text: "something went wrong")
        XCTAssertEqual(failure.exceptionType, "Unknown")
        XCTAssertNil(failure.failureFrame)
    }

    // MARK: - The frame

    /// Compiler-generated closure names carry numbers that change from build to build, so
    /// they are folded back to the method that declared them or the group fragments.
    func testFrameSkipsSharedHelpersAndNormalizesClosures() {
        XCTAssertEqual(BobsBuddySimulationFailure(text: nullReference).failureFrame,
                       "BobsBuddy.Minions.Dragon.BronzeTimewalker.OnRally")
    }

    /// With no frame outside Utils, the helper itself is still better than nothing.
    func testFallsBackToAHelperFrame() {
        let text = """
 ---> System.NullReferenceException: Object reference not set to an instance of an object
   at BobsBuddy.Utils.SafeRandom.TryGetRandom[String](List`1 list, String& item)
   at System.Threading.Tasks.Task.Wait()
"""
        XCTAssertEqual(BobsBuddySimulationFailure(text: text).failureFrame,
                       "BobsBuddy.Utils.SafeRandom.TryGetRandom")
    }

    /// System frames come first here, and the first BobsBuddy frame below them is the one
    /// worth grouping on.
    func testIgnoresSystemFrames() {
        XCTAssertEqual(BobsBuddySimulationFailure(text: missingAssembly).failureFrame,
                       "BobsBuddy.Simulation.Simulator.ResetPlayerStateAndUnbuffCloningGallery")
    }

    func testNormalizesLocalFunctionFrames() {
        let text = """
 ---> System.NullReferenceException: Object reference not set to an instance of an object
   at BobsBuddy.Simulation.SimulationRunner.<>c__DisplayClass0_0.<SimulateMultiThreaded>g__RunSimulator|1(Int32 _)
"""
        XCTAssertEqual(BobsBuddySimulationFailure(text: text).failureFrame,
                       "BobsBuddy.Simulation.SimulationRunner.SimulateMultiThreaded.RunSimulator")
    }

    // MARK: - What gets reported

    /// A missing assembly is the user's install, not a bug we can act on.
    func testMissingAssemblyIsAnEnvironmentFailure() {
        let failure = BobsBuddySimulationFailure(text: missingAssembly)
        XCTAssertTrue(failure.isEnvironmentFailure)
        XCTAssertEqual(failure.errorState, .failedToLoad)
    }

    func testSimulatorBugIsReportedAndLeavesTheErrorStateAlone() {
        let failure = BobsBuddySimulationFailure(text: nullReference)
        XCTAssertFalse(failure.isEnvironmentFailure)
        XCTAssertEqual(failure.errorState, .none)
    }

    /// The signature is what Sentry groups by, so two runs of the same bug have to agree and
    /// two different bugs have to differ.
    func testSignatureGroupsByExceptionAndFrame() {
        XCTAssertEqual(BobsBuddySimulationFailure(text: nullReference).signature,
                       BobsBuddySimulationFailure(text: nullReference).signature)
        XCTAssertNotEqual(BobsBuddySimulationFailure(text: nullReference).signature,
                          BobsBuddySimulationFailure(text: missingAssembly).signature)
    }
}
