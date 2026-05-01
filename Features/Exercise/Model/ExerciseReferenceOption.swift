//
//  ExerciseReferenceOption.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct ExerciseReferenceOption: Identifiable, Hashable, Decodable, Sendable {
    let id: String
    let name: String

    nonisolated init(id: String? = nil, name: String) {
        self.name = name
        self.id = id ?? name
    }

    nonisolated init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.init(name: value)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try Self.firstString(in: container, keys: [.id, .mongoID])
        let name = try Self.firstString(
            in: container,
            keys: [.name, .label, .title, .value, .category, .muscle, .equipment, .difficulty]
        ) ?? ""

        self.init(id: id, name: name)
    }

    private static func firstString(
        in container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key) {
                return value
            }
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case name
        case label
        case title
        case value
        case category
        case muscle
        case equipment
        case difficulty
    }
}

nonisolated struct ExerciseReferencePayload: Decodable, Sendable {
    let values: [ExerciseReferenceOption]

    nonisolated init(from decoder: Decoder) throws {
        if let options = try? [ExerciseReferenceOption](from: decoder) {
            values = options.filteredForDisplay
            return
        }

        if let strings = try? [String](from: decoder) {
            values = strings.map { ExerciseReferenceOption(name: $0) }.filteredForDisplay
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedValues: [ExerciseReferenceOption] = []

        for key in container.allKeys {
            if let options = try? container.decode([ExerciseReferenceOption].self, forKey: key) {
                decodedValues.append(contentsOf: options)
            } else if let strings = try? container.decode([String].self, forKey: key) {
                decodedValues.append(contentsOf: strings.map { ExerciseReferenceOption(name: $0) })
            }
        }

        values = decodedValues.filteredForDisplay
    }
}

nonisolated private extension Array where Element == ExerciseReferenceOption {
    var filteredForDisplay: [ExerciseReferenceOption] {
        filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
