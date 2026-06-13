import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var runner = CrawlerRunner()
    @State private var selectedFile: URL?
    @State private var isTargeted = false
    @State private var showingExportPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doctor Address Verifier")
                        .font(.system(size: 24, weight: .bold))
                    Text("Local Ollama-powered address verification")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if runner.isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(runner.progressText)
                            .font(.system(size: 12, design: .monospaced))
                        Text(runner.currentDoctor)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            if let error = runner.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            // Drop zone / File picker
            if selectedFile == nil {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTargeted ? Color.blue : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .background(Color.gray.opacity(0.05))
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Drop an Excel file here")
                            .font(.headline)
                        Text("or click to browse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Choose File...") {
                            chooseFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(height: 200)
                .padding()
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers)
                }
            } else {
                // File selected + controls
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text(selectedFile?.lastPathComponent ?? "")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Button("Change File") {
                        selectedFile = nil
                        runner.results.removeAll()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                HStack(spacing: 16) {
                    Button(runner.isRunning ? "Stop" : "Verify All Addresses") {
                        if runner.isRunning {
                            runner.stop()
                        } else if let file = selectedFile {
                            runner.startVerification(filePath: file.path)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(runner.isRunning ? .red : .blue)
                    .disabled(selectedFile == nil)

                    if !runner.results.isEmpty {
                        Button("Export Results...") {
                            showingExportPicker = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Text("\(runner.results.count) verified")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Results table
                if !runner.results.isEmpty {
                    ResultsTable(results: runner.results)
                        .padding(.horizontal)
                } else if runner.isRunning {
                    // Live log
                    LogView(entries: runner.logEntries)
                        .padding(.horizontal)
                } else {
                    Spacer()
                    Text("Click \"Verify All Addresses\" to start")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            Spacer(minLength: 0)
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: ExportDocument(results: runner.results),
            contentType: .plainText,
            defaultFilename: "verified_addresses"
        ) { result in
            // handled
        }
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(filenameExtension: "xlsx") ?? .data, .commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            selectedFile = url
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            if let url = url {
                Task { @MainActor in
                    self.selectedFile = url
                }
            }
        }
        return true
    }
}

struct ResultsTable: View {
    let results: [VerificationResult]

    var body: some View {
        Table(of: VerificationResult.self, selection: .constant(nil)) {
            TableColumn("Doctor") { r in
                Text(r.name).font(.system(size: 12, weight: .medium))
            }
            TableColumn("Original Address") { r in
                Text(r.originalAddress).font(.system(size: 11)).foregroundColor(.secondary)
            }
            TableColumn("Verified Address") { r in
                Text("\(r.standardizedAddress), \(r.standardizedCity), \(r.standardizedState) \(r.standardizedZip)")
                    .font(.system(size: 11))
            }
            TableColumn("Sources") { r in
                Text(r.sources.joined(separator: ", "))
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
            .width(min: 100, ideal: 150)
            TableColumn("NPI") { r in
                if let npi = r.npi {
                    Text(npi).font(.system(size: 10, design: .monospaced))
                } else {
                    Text("-").font(.system(size: 10)).foregroundColor(.secondary)
                }
            }
            .width(min: 60, ideal: 80)
            TableColumn("Action") { r in
                Text(r.action.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(actionColor(r.action.rawValue))
                    .cornerRadius(4)
            }
            .width(min: 80, ideal: 100)
            TableColumn("Confidence") { r in
                Text(r.confidence.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(confidenceColor(r.confidence.rawValue))
            }
            .width(min: 60, ideal: 80)
        } rows: {
            ForEach(results) { r in
                TableRow(r)
            }
        }
        .tableStyle(.bordered)
    }

    private func actionColor(_ action: String) -> Color {
        switch action {
        case "keep": return Color.green.opacity(0.2)
        case "reassign": return Color.orange.opacity(0.2)
        case "remove": return Color.red.opacity(0.2)
        case "update-bronx-route": return Color.blue.opacity(0.2)
        default: return Color.gray.opacity(0.2)
        }
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence {
        case "high": return .green
        case "medium": return .orange
        case "low": return .red
        default: return .secondary
        }
    }
}

struct LogView: View {
    let entries: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Live Agent Log")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(entries.indices, id: \.self) { i in
                        Text(entries[i])
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.03))
        .cornerRadius(8)
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    static var writableContentTypes: [UTType] { [.plainText] }

    let results: [VerificationResult]

    init(results: [VerificationResult]) {
        self.results = results
    }

    init(configuration: ReadConfiguration) throws {
        self.results = []
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var lines = ["Name,OriginalAddress,VerifiedAddress,City,State,Zip,Action,Confidence,Evidence,Notes"]
        for r in results {
            let verified = "\(r.standardizedAddress), \(r.standardizedCity), \(r.standardizedState) \(r.standardizedZip)"
            lines.append("\"\(r.name)\",\"\(r.originalAddress)\",\"\(verified)\",\"\(r.action.rawValue)\",\"\(r.confidence.rawValue)\",\"\(r.evidence ?? "")\",\"\(r.notes)\"")
        }
        let data = lines.joined(separator: "\n").data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
