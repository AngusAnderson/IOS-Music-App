enum ReorderDirection {
    case up
    case down

    var offset: Int {
        switch self {
        case .up:
            return -1
        case .down:
            return 1
        }
    }
}
