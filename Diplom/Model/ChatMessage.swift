//
//  ChatMessage.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 24.05.2023.
//

import Foundation
import FirebaseFirestoreSwift
struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
