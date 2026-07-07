import Foundation
import os

enum Log {
    static let statusBar = Logger(subsystem: "com.tonmoybishwas.tuck", category: "statusbar")
    static let app = Logger(subsystem: "com.tonmoybishwas.tuck", category: "app")
    static let settings = Logger(subsystem: "com.tonmoybishwas.tuck", category: "settings")

    /// DEBUG builds also append events to a trace file so behavior can be
    /// verified from the command line.
    static func trace(_ message: String) {
        #if DEBUG
        let line = "\(Date()) \(message)\n"
        let path = "/tmp/tuck-debug-events.log"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            try? handle.close()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
        #endif
    }
}
