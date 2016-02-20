/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

class Entity: Equatable {
    var id: Int
    var isPlayer: Bool = false
    var cardId: String?
    var name: String?
    var tags = [GameTag: Int]()

    init(_ id: Int) {
        self.id = id
    }

    subscript(tag: GameTag) -> Int? {
        get {
            return tags[tag];
        }
        set {
            tags[tag] = newValue
        }
    }

    func isInZone(zone: Zone) -> Bool {
        return self[GameTag.ZONE] == nil ? false : self[GameTag.ZONE]! == zone.rawValue
    }

    func isControllerBy(controller: Int) -> Bool {
        return self[GameTag.CONTROLLER] == nil ? false : self[GameTag.CONTROLLER]! == controller;
    }

    var isSecret: Bool {
        return self[GameTag.SECRET] == nil
    }
}

func ==(lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

class TempEntity {
    var tag: String
    var id: Int
    var value: String

    init(_ tag: String, _ id: Int, _ value: String) {
        self.tag = tag;
        self.id = id;
        self.value = value;
    }
}
