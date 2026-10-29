import MusicKit
import Foundation

struct AppleMusicService {
    func searchSongs(term: String) async throws -> [Song] {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTerm.isEmpty else { return [] }
        
        var request = MusicCatalogSearchRequest(
            term: term,
            types: [Song.self]
        )
        
        request.limit = 25
        
        let response = try await request.response()
        return Array(response.songs)
    }
}
