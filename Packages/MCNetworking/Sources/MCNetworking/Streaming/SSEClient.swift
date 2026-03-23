import Foundation
import MCCore

public struct SSEEvent: Sendable {
    public let event: String?
    public let data: String
    public let id: String?

    public init(event: String? = nil, data: String, id: String? = nil) {
        self.event = event
        self.data = data
        self.id = id
    }
}

public enum SSEClientFactory {
    public static func stream(request: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let buffer = SSEBuffer()
            let delegate = SSEStreamDelegate(continuation: continuation, buffer: buffer)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let task = session.dataTask(with: request)
            continuation.onTermination = { _ in
                task.cancel()
                session.invalidateAndCancel()
            }
            task.resume()
        }
    }
}

final class SSEStreamDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let continuation: AsyncThrowingStream<SSEEvent, Error>.Continuation
    private let buffer: SSEBuffer
    private let lock = NSLock()

    init(continuation: AsyncThrowingStream<SSEEvent, Error>.Continuation, buffer: SSEBuffer) {
        self.continuation = continuation
        self.buffer = buffer
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        lock.lock()
        let events = buffer.append(text)
        lock.unlock()
        for event in events {
            continuation.yield(event)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            if (error as NSError).code == NSURLErrorCancelled {
                continuation.finish()
            } else {
                continuation.finish(throwing: error)
            }
        } else {
            continuation.finish()
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            continuation.finish(throwing: MCError.apiError(
                statusCode: httpResponse.statusCode,
                message: "HTTP \(httpResponse.statusCode)"
            ))
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }
}

// SSEBuffer is only accessed under the delegate's lock - not Sendable itself
final class SSEBuffer {
    private var buffer = ""
    private var currentEvent: String?
    private var currentData: [String] = []
    private var currentID: String?

    func append(_ text: String) -> [SSEEvent] {
        buffer += text
        var events: [SSEEvent] = []

        while let newlineRange = buffer.range(of: "\n") {
            let line = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])

            if line.isEmpty {
                if !currentData.isEmpty {
                    let event = SSEEvent(
                        event: currentEvent,
                        data: currentData.joined(separator: "\n"),
                        id: currentID
                    )
                    events.append(event)
                }
                currentEvent = nil
                currentData = []
                currentID = nil
            } else if line.hasPrefix("data:") {
                let value = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                currentData.append(value)
            } else if line.hasPrefix("event:") {
                currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("id:") {
                currentID = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            }
        }

        return events
    }
}
