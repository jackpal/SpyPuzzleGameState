public struct Node : Codable, Hashable, CustomStringConvertible {
  public var type: NodeType
  public var edges: [Direction : EdgeType]
  public var item: Item?
  public var enemies: [Enemy]
  
  public init(type: NodeType = .plain){
    self.type = type
    edges = [:]
    enemies = []
  }
  
  public var description: String {
    "\(type)\(item?.description ?? "")\(enemies.map(\.description).joined(separator: ", "))"
  }
    
  public func hash(into hasher: inout Hasher) {
    type.hash(into:&hasher)
    // Ignore edges as they are slow to hash and rarely change.
    item?.hash(into: &hasher)
    enemies.hash(into: &hasher)
  }
}
