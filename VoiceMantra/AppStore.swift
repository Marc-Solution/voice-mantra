import Foundation
import Combine

struct AffirmationList: Identifiable, Hashable {
  let id: UUID
  var name: String
  var affirmations: [Affirmation]

  init(id: UUID = UUID(), name: String, affirmations: [Affirmation] = []) {
    self.id = id
    self.name = name
    self.affirmations = affirmations
  }
}

struct Affirmation: Identifiable, Hashable {
  let id: UUID
  var title: String
  var transcript: String?
  var durationSeconds: Int?
  var listId: UUID?
  var createdAt: Date = Date()
}

typealias Draft = Affirmation

final class AppStore: ObservableObject {
  @Published var lists: [AffirmationList] = []
  @Published var drafts: [Draft] = []

  // MARK: - List operations
  @discardableResult
  func createList(name: String) -> AffirmationList {
    let newList = AffirmationList(name: name)
    lists.append(newList)
    return newList
  }

  // MARK: - Affirmation creation
  @discardableResult
  func createAffirmation(title: String, listId: UUID?) -> Affirmation {
    let a = Affirmation(id: UUID(), title: title, transcript: nil, durationSeconds: nil, listId: listId)

    if let listId = listId {
      if let index = lists.firstIndex(where: { $0.id == listId }) {
        lists[index].affirmations.append(a)
      } else {
        drafts.append(a)
      }
    } else {
      drafts.append(a)
    }

    return a
  }

  // MARK: - Update / Save
  func saveAffirmation(_ updated: Affirmation, toListId targetListId: UUID?) {
    // Remove from drafts if present
    if let draftIndex = drafts.firstIndex(where: { $0.id == updated.id }) {
      drafts.remove(at: draftIndex)
    }

    // Save into a specific list if provided
    if let listId = targetListId {
      if let index = lists.firstIndex(where: { $0.id == listId }) {
        if let aIndex = lists[index].affirmations.firstIndex(where: { $0.id == updated.id }) {
          lists[index].affirmations[aIndex] = updated
        } else {
          lists[index].affirmations.append(updated)
        }
        return
      }
    }

    // If no target list or not found -> keep as draft
    drafts.append(updated)
  }
  
  // MARK: - List Management
  func renameList(id: UUID, newName: String) {
    if let index = lists.firstIndex(where: { $0.id == id }) {
      lists[index].name = newName
    }
  }
  
  func deleteList(id: UUID) {
    lists.removeAll { $0.id == id }
  }
  
  // MARK: - Affirmation Deletion
  func deleteAffirmation(id: UUID, fromListId listId: UUID) {
    if let listIndex = lists.firstIndex(where: { $0.id == listId }) {
      lists[listIndex].affirmations.removeAll { $0.id == id }
    }
  }
}

