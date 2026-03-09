import Testing
@testable import UVMonitor

@Suite("UV Level Classification")
struct UVLevelTests {

    @Test("Low UV: index 0 to 2.9")
    func lowLevel() {
        #expect(UVLevel(index: 0) == .low)
        #expect(UVLevel(index: 1.5) == .low)
        #expect(UVLevel(index: 2.9) == .low)
    }

    @Test("Moderate UV: index 3 to 5.9")
    func moderateLevel() {
        #expect(UVLevel(index: 3.0) == .moderate)
        #expect(UVLevel(index: 4.5) == .moderate)
        #expect(UVLevel(index: 5.9) == .moderate)
    }

    @Test("High UV: index 6 to 7.9")
    func highLevel() {
        #expect(UVLevel(index: 6.0) == .high)
        #expect(UVLevel(index: 7.0) == .high)
        #expect(UVLevel(index: 7.9) == .high)
    }

    @Test("Very High UV: index 8 to 10.9")
    func veryHighLevel() {
        #expect(UVLevel(index: 8.0) == .veryHigh)
        #expect(UVLevel(index: 10.0) == .veryHigh)
        #expect(UVLevel(index: 10.9) == .veryHigh)
    }

    @Test("Extreme UV: index 11+")
    func extremeLevel() {
        #expect(UVLevel(index: 11.0) == .extreme)
        #expect(UVLevel(index: 15.0) == .extreme)
    }

    @Test("Negative UV index treated as low")
    func negativeIndex() {
        #expect(UVLevel(index: -1.0) == .low)
    }

    @Test("Protection not needed for low UV only")
    func protectionNeeded() {
        #expect(UVLevel.low.needsProtection == false)
        #expect(UVLevel.moderate.needsProtection == true)
        #expect(UVLevel.high.needsProtection == true)
        #expect(UVLevel.veryHigh.needsProtection == true)
        #expect(UVLevel.extreme.needsProtection == true)
    }

    @Test("All levels have non-empty advice")
    func adviceNotEmpty() {
        for level in [UVLevel.low, .moderate, .high, .veryHigh, .extreme] {
            #expect(!level.protectionAdvice.isEmpty)
        }
    }
}
