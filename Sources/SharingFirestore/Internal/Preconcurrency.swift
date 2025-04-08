import FirebaseFirestore

extension DocumentID: @retroactive @unchecked Sendable
where Value: Sendable {}

extension Firestore: @retroactive @unchecked Sendable {}
