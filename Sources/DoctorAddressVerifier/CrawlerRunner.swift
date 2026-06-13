import Foundation
import Combine

@MainActor
class CrawlerRunner: ObservableObject {
    @Published var isRunning = false
    @Published var progressText = ""
    @Published var currentDoctor = ""
    @Published var doneCount = 0
    @Published var totalCount = 0
    @Published var logEntries: [String] = []
    @Published var results: [VerificationResult] = []
    @Published var errorMessage: String?

    private var process: Process?
    private let maxLogEntries = 100

    func startVerification(filePath: String) {
        guard !isRunning else { return }
        isRunning = true
        progressText = "Starting verification..."
        doneCount = 0
        totalCount = 0
        logEntries.removeAll()
        results.removeAll()
        errorMessage = nil

        // 1. Find Node.js
        guard let nodePath = findNodePath() else {
            errorMessage = "Node.js not found.\n\nInstall Node.js:\n  brew install node\n\nOr download from nodejs.org"
            isRunning = false
            return
        }

        // 2. Find CLI
        guard let cliInfo = findCLIPath() else {
            errorMessage = "CLI not found.\n\nThe crawler engine was not found. Expected at:\n~/Downloads/02_AI_Agents/DoctorAddressVerifierCLI/"
            isRunning = false
            return
        }

        // 3. Check node_modules exist
        let nodeModulesPath = URL(fileURLWithPath: cliInfo.cliPath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("node_modules").path
        if !FileManager.default.fileExists(atPath: nodeModulesPath) {
            errorMessage = "Dependencies missing.\n\nRun this in Terminal:\n  cd \"\(cliInfo.cliDir)\" && npm install"
            isRunning = false
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: nodePath)
        process.arguments = [cliInfo.cliPath, filePath]

        // Inherit PATH so node can find its modules
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/sbin:/usr/sbin:" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] h in
            guard let data = try? h.readToEnd(), let str = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.handleOutput(str)
            }
        }

        process.terminationHandler = { [weak self] p in
            Task { @MainActor in
                self?.isRunning = false
                let code = p.terminationStatus
                if code == 127 {
                    self?.errorMessage = "Node.js command not found (exit 127).\n\nInstall Node.js:\n  brew install node"
                } else if code != 0 && self?.results.isEmpty == true {
                    self?.errorMessage = self?.errorMessage ?? "Process exited with code \(code)"
                }
                self?.progressText = "Done — \(self?.results.count ?? 0) verified"
            }
        }

        do {
            try process.run()
            self.process = process
        } catch {
            self.errorMessage = "Failed to start: \(error.localizedDescription)"
            self.isRunning = false
        }
    }

    func stop() {
        process?.terminate()
        isRunning = false
    }

    private func handleOutput(_ text: String) {
        for line in text.components(separatedBy: .newlines) where !line.isEmpty {
            if let data = line.data(using: .utf8),
               let event = try? JSONDecoder().decode(CrawlEvent.self, from: data) {
                handleEvent(event)
            } else {
                appendLog(line)
            }
        }
    }

    private func handleEvent(_ event: CrawlEvent) {
        if let msg = event.message {
            appendLog(msg)
        }
        if let doc = event.doctor, doc != "batch" {
            currentDoctor = doc
        }
        if let prog = event.progress {
            doneCount = prog.done
            totalCount = prog.total
            progressText = "\(prog.done) / \(prog.total) doctors"
        }
        if event.type == "complete" {
            progressText = "Complete — \(event.count ?? results.count) doctors"
            isRunning = false
        }
        if event.type == "error" {
            errorMessage = event.message ?? "Unknown error"
            isRunning = false
        }
        if event.type == "enrich-progress", let result = event.result {
            handleEnrichmentResult(result)
        }
    }

    private func handleEnrichmentResult(_ result: EnrichmentResult) {
        let verification = VerificationResult(
            id: UUID(),
            name: result.name,
            originalAddress: result.standardizedAddress ?? "Unknown",
            standardizedAddress: result.standardizedAddress ?? "",
            standardizedCity: result.standardizedCity ?? "",
            standardizedState: result.standardizedState ?? "",
            standardizedZip: result.standardizedZip ?? "",
            isValid: result.confidence == "high",
            confidence: VerificationConfidence(rawValue: result.confidence ?? "unknown") ?? .unknown,
            action: VerificationAction(rawValue: result.action ?? "needsReview") ?? .needsReview,
            territory: "US",
            evidence: result.evidence,
            notes: result.notes ?? "",
            sources: result.sources ?? [],
            npi: result.npi
        )
        results.append(verification)
    }

    private func appendLog(_ msg: String) {
        logEntries.append(msg)
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }

    // MARK: - Node.js Discovery

    private func findNodePath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node",
            "/usr/local/opt/node/bin/node",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // Search via PATH
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["node"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty,
               FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        } catch {
            // fall through
        }
        return nil
    }

    // MARK: - CLI Discovery

    private struct CLIInfo {
        let cliPath: String
        let cliDir: String
    }

    private func findCLIPath() -> CLIInfo? {
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/cli/dist/cli.js"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/02_AI_Agents/DoctorAddressVerifierCLI/dist/cli.js"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/cli.js"),
        ]
        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                let dir = URL(fileURLWithPath: url.path).deletingLastPathComponent().deletingLastPathComponent().path
                return CLIInfo(cliPath: url.path, cliDir: dir)
            }
        }
        // Deep search
        let fm = FileManager.default
        let paths = [
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path,
        ]
        for base in paths {
            if let enumerator = fm.enumerator(atPath: base) {
                for case let file as String in enumerator {
                    if file.hasSuffix("DoctorAddressVerifierCLI/dist/cli.js") {
                        let fullPath = (base as NSString).appendingPathComponent(file)
                        let dir = URL(fileURLWithPath: fullPath).deletingLastPathComponent().deletingLastPathComponent().path
                        return CLIInfo(cliPath: fullPath, cliDir: dir)
                    }
                }
            }
        }
        return nil
    }
}
