/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */

import Foundation

let KFrameWidth = 220.0
let KFrameHeight = 700.0
let KRowHeight = 37.0

let KMediumRowHeight = 29.0
let KMediumFrameWidth = (KFrameWidth / KRowHeight * KMediumRowHeight)

let KSmallRowHeight = 23.0
let KSmallFrameWidth = (KFrameWidth / KRowHeight * KSmallRowHeight)

enum CardSize: Int {
    case Small,
         Medium,
         Big
}
