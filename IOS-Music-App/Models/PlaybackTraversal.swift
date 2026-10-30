enum PlaybackTraversal: String, CaseIterable, Codable {
    case depthFirst
    case breadthFirst

    static let storageKey = "playbackTraversal"

    var title: String {
        switch self {
        case .depthFirst:
            return "By branch — DFS"
        case .breadthFirst:
            return "By level — BFS"
        }
    }

    var explanation: String {
        switch self {
        case .depthFirst:
            return """
            Finish each playlist and its descendants before \
            moving to the next sibling.
            """

        case .breadthFirst:
            return """
            Play the direct songs from each playlist level \
            before moving deeper.
            """
        }
    }
}
