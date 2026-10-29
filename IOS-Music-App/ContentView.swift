import SwiftUI
import MusicKit
import SwiftData

struct ContentView: View {
    
    @State private var status: MusicAuthorization.Status = MusicAuthorization.currentStatus
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            LibraryView()
        }
        .task {
            do {
                try SampleLibrary.seedIfEmpty(in: modelContext)
                print("Bundle ID:", Bundle.main.bundleIdentifier ?? "Missing")
            } catch {
                print("Failed to create sample library: \(error)")
            }
            
            status = await MusicAuthorization.request()
        }
    }
}
