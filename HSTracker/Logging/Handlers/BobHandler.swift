/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 19/02/16.
 */

import Foundation

class BobHandler {
    static func handle(line: String) {

        if !line.isMatch(NSRegularExpression.rx("---Register")) {
            return
        }

        if line.isMatch(NSRegularExpression.rx("---RegisterScreenBox---")) {
            if (Game.instance.gameMode == GameMode.Spectator) {
                Game.instance.gameEnd()
            }
        }
        /*else if ([line isMatch:RX(@"---RegisterScreenForge---")]) {
          game.gameMode = EGameMode_Arena;
        }
        else if ([line isMatch:RX(@"---RegisterScreenPractice---")]) {
          game.gameMode = EGameMode_Practice;
        }
        else if ([line isMatch:RX(@"---RegisterScreenTourneys---")]) {
          game.gameMode = EGameMode_Casual;
        }
        else if ([line isMatch:RX(@"---RegisterScreenFriendly---")]) {
          game.gameMode = EGameMode_Friendly;
        }*/
    }
}
