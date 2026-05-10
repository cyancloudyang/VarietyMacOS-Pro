import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for DownloadError enum
final class DownloadErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testInvalidResponseDescription() {
        let error = DownloadError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid response from server")
        XCTAssertEqual(error.localizedDescription, "Invalid response")
    }

    func testHTTPErrorDescription() {
        let error = DownloadError.httpError(404)
        XCTAssertEqual(error.errorDescription, "HTTP error: 404")
        XCTAssertEqual(error.localizedDescription, "HTTP error: 404")
        XCTAssertTrue(error.errorDescription?.contains("404") == true)
    }

    func testHTTPErrorVariousCodes() {
        let codes: [(Int, String)] = [
            (400, "HTTP error: 400"),
            (401, "HTTP error: 401"),
            (403, "HTTP error: 403"),
            (404, "HTTP error: 404"),
            (500, "HTTP error: 500"),
            (502, "HTTP error: 502"),
            (503, "HTTP error: 503"),
        ]

        for (code, expected) in codes {
            let error = DownloadError.httpError(code)
            XCTAssertEqual(error.errorDescription, expected)
        }
    }

    func testInvalidImageDataDescription() {
        let error = DownloadError.invalidImageData
        XCTAssertEqual(error.errorDescription, "Downloaded data is not a valid image")
        XCTAssertEqual(error.localizedDescription, "Invalid image data")
    }

    func testCancelledDescription() {
        let error = DownloadError.cancelled
        XCTAssertEqual(error.errorDescription, "Download was cancelled")
        XCTAssertEqual(error.localizedDescription, "Cancelled")
    }

    func testUnknownDescription() {
        let error = DownloadError.unknown
        XCTAssertEqual(error.errorDescription, "Unknown download error")
        XCTAssertEqual(error.localizedDescription, "Unknown error")
    }

    func testRateLimitedDescription() {
        let error = DownloadError.rateLimited
        XCTAssertEqual(error.errorDescription, "Rate limit exceeded. Please try again later.")
        XCTAssertEqual(error.localizedDescription, "Rate limit exceeded. Please try again later.")
    }

    func testServerErrorDescription() {
        let error = DownloadError.serverError(500)
        XCTAssertEqual(error.errorDescription, "Server error: 500")
        XCTAssertEqual(error.localizedDescription, "Server error: 500")
        XCTAssertTrue(error.errorDescription?.contains("500") == true)
    }

    func testServerErrorVariousCodes() {
        let codes = [500, 502, 503, 504]
        for code in codes {
            let error = DownloadError.serverError(code)
            XCTAssertTrue(error.errorDescription?.contains("\(code)") == true)
        }
    }

    func testNoRemoteURLDescription() {
        let error = DownloadError.noRemoteURL
        XCTAssertEqual(error.errorDescription, "No remote URL available for download")
        XCTAssertEqual(error.localizedDescription, "No remote URL")
    }

    func testDownloadFailedDescription() {
        let error = DownloadError.downloadFailed
        XCTAssertEqual(error.errorDescription, "Failed to download wallpaper")
        XCTAssertEqual(error.localizedDescription, "Download failed")
    }

    // MARK: - LocalizedError Conformance Tests

    func testAllErrorsHaveDescriptions() {
        let errors: [DownloadError] = [
            .invalidResponse,
            .httpError(404),
            .invalidImageData,
            .cancelled,
            .unknown,
            .rateLimited,
            .serverError(500),
            .noRemoteURL,
            .downloadFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.localizedDescription)
        }
    }

    func testErrorDescriptionsAreNotEmpty() {
        let errors: [DownloadError] = [
            .invalidResponse,
            .httpError(200),
            .invalidImageData,
            .cancelled,
            .unknown,
            .rateLimited,
            .serverError(500),
            .noRemoteURL,
            .downloadFailed
        ]

        for error in errors {
            XCTAssertFalse(error.errorDescription?.trimmingCharacters(in: .whitespaces).isEmpty == true)
        }
    }

    // MARK: - Equatable Tests

    func testErrorEquality() {
        XCTAssertEqual(DownloadError.invalidResponse, DownloadError.invalidResponse)
        XCTAssertEqual(DownloadError.httpError(404), DownloadError.httpError(404))
        XCTAssertEqual(DownloadError.rateLimited, DownloadError.rateLimited)
        XCTAssertEqual(DownloadError.unknown, DownloadError.unknown)
    }

    func testErrorInequality() {
        XCTAssertNotEqual(DownloadError.httpError(404), DownloadError.httpError(500))
        XCTAssertNotEqual(DownloadError.invalidResponse, DownloadError.invalidImageData)
        XCTAssertNotEqual(DownloadError.rateLimited, DownloadError.serverError(500))
    }

    // MARK: - Error Usage in Result Tests

    func testErrorInResult() {
        let result: Result<String, DownloadError> = .failure(.rateLimited)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .rateLimited)
        } else {
            XCTFail("Expected failure with rateLimited error")
        }
    }

    func testErrorOptional() {
        let error: DownloadError? = .cancelled
        XCTAssertNotNil(error)
        if let error = error {
            XCTAssertEqual(error, .cancelled)
        }
    }
}
