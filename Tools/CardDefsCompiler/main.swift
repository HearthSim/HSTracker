//
//  main.swift
//  CardDefsCompiler
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//
//  Build-time tool: transcodes HearthSim's CardDefs.xml into the binary blob
//  Database.loadDatabase reads. Run from the "Compile CardDefs" build phase,
//  never from the app. It deliberately knows nothing about what the tags mean -
//  see CardDefsBinary.swift.
//
//  usage: CardDefsCompiler <CardDefs.xml> <CardDefs.bin>
//

import Foundation

final class Transcoder: NSObject, XMLParserDelegate {
    let writer = CardDefsWriter()

    private var localizedTagOpen = false
    private var language: String?
    private var text = ""

    private(set) var entities = 0
    private(set) var tags = 0
    private(set) var localized = 0

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "Entity":
            writer.beginEntity(cardId: attributeDict["CardID"] ?? "",
                               dbfId: Int32(attributeDict["ID"] ?? "0") ?? 0)
            entities += 1
        case "Tag":
            guard let enumID = attributeDict["enumID"], let id = Int32(enumID) else {
                break
            }
            if attributeDict["type"] == "LocString" {
                writer.beginLocalizedTag(id: id)
                localizedTagOpen = true
                localized += 1
            } else {
                writer.addTag(id: id, value: Int32(attributeDict["value"] ?? "0") ?? 0)
                tags += 1
            }
        case "ReferencedTag":
            guard let enumID = attributeDict["enumID"], let id = Int32(enumID) else {
                break
            }
            writer.addReferencedTag(id: id)
            tags += 1
        default:
            // The only elements nested inside a LocString tag are the language
            // ones; anything else in the file is ignored.
            if localizedTagOpen {
                language = elementName
                text = ""
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if language != nil {
            text += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "Entity":
            writer.endEntity()
        case "Tag":
            if localizedTagOpen {
                writer.endLocalizedTag()
                localizedTagOpen = false
            }
        default:
            if let language, language == elementName {
                writer.addLocalized(language: language, value: text)
                self.language = nil
                text = ""
            }
        }
    }
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: CardDefsCompiler <CardDefs.xml> <CardDefs.bin>\n".utf8))
    exit(2)
}
let source = URL(fileURLWithPath: arguments[1])
let destination = URL(fileURLWithPath: arguments[2])

guard let data = try? Data(contentsOf: source, options: .mappedIfSafe) else {
    FileHandle.standardError.write(Data("error: cannot read \(source.path)\n".utf8))
    exit(1)
}

let started = Date()
let transcoder = Transcoder()
let parser = XMLParser(data: data)
parser.delegate = transcoder
guard parser.parse() else {
    let reason = parser.parserError?.localizedDescription ?? "unknown error"
    FileHandle.standardError.write(Data("error: \(source.lastPathComponent): \(reason)\n".utf8))
    exit(1)
}

let blob = transcoder.writer.finish()
do {
    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try blob.write(to: destination, options: .atomic)
} catch {
    FileHandle.standardError.write(Data("error: cannot write \(destination.path): \(error)\n".utf8))
    exit(1)
}

print(String(format: "CardDefsCompiler: %d entities, %d tags, %d localized tags, %.1f MB -> %.1f MB in %.1fs",
             transcoder.entities, transcoder.tags, transcoder.localized,
             Double(data.count) / 1_048_576, Double(blob.count) / 1_048_576,
             -started.timeIntervalSinceNow))
