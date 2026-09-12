import Foundation

@main
enum Launcher {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--diagnostics") {
            Diagnostics.printReport()
            return
        }
        if let index = CommandLine.arguments.firstIndex(of: "--render-check"),
           CommandLine.arguments.count > index + 1 {
            do {
                try RenderCheck.run(directory: CommandLine.arguments[index + 1])
            } catch {
                fputs("Render check failed: \(error)\n", stderr)
                exit(1)
            }
            return
        }
        MacDuoEffectApp.main()
    }
}
