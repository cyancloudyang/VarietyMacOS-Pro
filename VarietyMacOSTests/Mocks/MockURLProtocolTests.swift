import Testing
import Foundation
@testable import VarietyMacOS

struct MockURLProtocolTests {

    @Test func testMockURLProtocolRegistersAndReturnsData() async throws {
        let testURL = URL(string: "https://example.com/test.jpg")!
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        
        MockURLProtocol.clearMockData()
        MockURLProtocol.register(
            urlString: testURL.absoluteString,
            data: testData,
            statusCode: 200
        )
        
        #expect(MockURLProtocol.mockData[testURL.absoluteString] != nil)
    }
    
    @Test func testMockURLProtocolClearsData() async throws {
        let testURL = URL(string: "https://example.com/clear.jpg")!
        
        MockURLProtocol.register(
            urlString: testURL.absoluteString,
            data: Data([0x00])
        )
        
        #expect(MockURLProtocol.mockData.count > 0)
        
        MockURLProtocol.clearMockData()
        
        #expect(MockURLProtocol.mockData.isEmpty)
    }
    
    @Test func testMockURLProtocolEnableDisable() async throws {
        MockURLProtocol.disable()
        #expect(MockURLProtocol.isEnabled == false)
        
        MockURLProtocol.enable()
        #expect(MockURLProtocol.isEnabled == true)
        
        MockURLProtocol.disable()
    }
    
    @Test func testMockURLProtocolPatternMatching() async throws {
        let testURL = URL(string: "https://api.example.com/images/123?size=large")!
        let testData = Data([0x10, 0x20, 0x30])
        
        MockURLProtocol.clearMockData()
        MockURLProtocol.register(
            urlString: "api.example.com/images",
            data: testData
        )
        
        #expect(MockURLProtocol.mockData["api.example.com/images"] != nil)
    }
    
    @Test func testMockURLProtocol404ForUnregisteredURL() async throws {
        MockURLProtocol.clearMockData()
        MockURLProtocol.enable()
        
        let unregisteredURL = URL(string: "https://example.com/not-registered.jpg")!
        
        let configuration = MockURLProtocol.createConfiguration()
        let session = URLSession(configuration: configuration)
        
        do {
            let (_, response) = try await session.data(from: unregisteredURL)
            let httpResponse = try #require(response as? HTTPURLResponse)
            #expect(httpResponse.statusCode == 404)
        } catch {
            #expect(error is URLError || (error as? NSError)?.code == 404)
        }
    }
    
    @Test func testMockURLProtocolCreateConfiguration() async throws {
        let configuration = MockURLProtocol.createConfiguration()
        
        #expect(configuration.protocolClasses?.contains {
            $0 == MockURLProtocol.self
        } == true)
    }
    
    @Test func testMockURLProtocolCreateSession() async throws {
        let session = MockURLProtocol.createSession()
        
        #expect(session.configuration.protocolClasses?.contains {
            $0 == MockURLProtocol.self
        } == true)
    }
    
    @Test func testMockURLProtocolImageData() async throws {
        let testURL = URL(string: "https://example.com/image.png")!
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        
        MockURLProtocol.clearMockData()
        MockURLProtocol.register(
            urlString: testURL.absoluteString,
            data: imageData,
            mimeType: "image/png"
        )
        
        let registered = MockURLProtocol.mockData[testURL.absoluteString]
        #expect(registered != nil)
        #expect(registered?.0 == imageData)
    }
    
    @Test func testMockURLProtocolCustomStatusCode() async throws {
        let testURL = URL(string: "https://example.com/error.jpg")!
        
        MockURLProtocol.clearMockData()
        MockURLProtocol.register(
            urlString: testURL.absoluteString,
            data: Data(),
            statusCode: 500
        )
        
        let registered = MockURLProtocol.mockData[testURL.absoluteString]
        #expect(registered?.1.statusCode == 500)
    }
}
