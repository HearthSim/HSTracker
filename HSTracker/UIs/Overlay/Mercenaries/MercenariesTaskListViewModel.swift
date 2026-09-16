//
//  MercenariesTaskListViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

// HDT's MercenariesTaskListViewModel, plus the visibility state its
// OverlayWindow keeps outside the view model (the two OverlayElementBehaviors
// for MercenariesTaskListButton and MercenariesTaskList). This replaces the
// pair of NSPanels - MercenariesTaskListButton and MercenariesTaskListView -
// that used to own the same state between them.
@available(macOS 10.15, *)
final class MercenariesTaskListViewModel: ObservableObject {
    // HDT's Tasks and GameNoticeVisibility.
    @Published private(set) var tasks: [MercenariesTaskViewModel] = []
    @Published private(set) var gameNoticeVisible = false

    // _mercenariesTaskListButtonBehavior.Show()/Hide() and
    // _mercenariesTaskListBehavior.Show()/Hide().
    @Published var isButtonShown = false
    @Published var isListShown = false

    // OverlayWindow.MercenariesButtonOffset reads _game.IsInMenu live to decide
    // whether the button has to clear Hearthstone's "Back" button; pushed in
    // from Game.updateMercenariesTaskListButton, which the GUI update loop
    // already calls on every tick.
    @Published var isInMenu = true

    // What the old MercenariesTaskListButton controller called `visible`: the
    // Mercenaries-scene gate LoadingScreenHandler sets, as opposed to the
    // settings/background gates Game applies on top of it. Not @Published -
    // it is only ever read by updateMercenariesTaskListButton, which folds it
    // into isButtonShown above.
    var isRequested = false

    // HDT's _taskData, read once and kept: the task *definitions* (title, text,
    // quota) never change within a session, only the per-visitor progress does.
    private var taskData: [MirrorMercenariesTaskData]?

    // The mirror reads below are blocking IPC into Hearthstone's memory. HDT
    // does them on its UI thread; here they would block the overlay's own
    // rendering, so they run on this queue and publish back to main.
    private let queue = DispatchQueue(label: "net.hearthsim.hstracker.mercenariestasks", attributes: [])

    func setGameNoticeVisible(_ flag: Bool) {
        DispatchQueue.main.async {
            self.gameNoticeVisible = flag
        }
    }

    // HDT's Update(), which returns false when it has nothing to show and the
    // caller then leaves the list hidden. Asynchronous here because of the
    // queue above, so the answer comes back through the completion instead.
    func update(completion: @escaping (Bool) -> Void) {
        queue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            if self.taskData == nil || self.taskData?.count == 0 {
                self.taskData = MirrorHelper.getMercenariesTaskData()
            }
            guard let taskData = self.taskData else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let visitorTasks = MirrorHelper.getMercenariesVisitorTasks(), visitorTasks.count > 0 else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let tasks = visitorTasks.compactMap { Self.viewModel(for: $0, taskData: taskData) }
            DispatchQueue.main.async {
                self.tasks = tasks
                completion(true)
            }
        }
    }

    // HDT's projection inside Update(). HSTracker resolves rather more of the
    // task text than HDT does: the mirror hands back the raw template, with
    // $owner_merc / $bounty_* / $additional_mercs placeholders still in it, and
    // these substitutions are HSTracker's own - kept as they were.
    private static func viewModel(for task: MirrorMercenariesVisitorTask,
                                  taskData: [MirrorMercenariesTaskData]) -> MercenariesTaskViewModel? {
        guard let td = taskData.first(where: { $0.id == task.taskId }) else {
            return nil
        }
        let cardId = td.mercenaryDefaultDbfId.intValue != 0
            ? td.mercenaryDefaultDbfId.intValue
            : task.visitorCardDbf.intValue
        guard let card = Cards.by(dbfId: cardId, collectible: false) else {
            return nil
        }
        let titleStr = td.title.replacingOccurrences(of: "$owner_merc", with: task.visitorName)
        let title = titleStr.contains(":")
            ? titleStr
            : String(format: String.localizedString("Task %d: %@", comment: ""),
                     task.taskChainProgress.intValue + 1, titleStr)
        let additionalMercs = task.additionalMercenaries.joined(separator: ", ")
        let bountyNd = task.bountyHeroic
            ? String(format: String.localizedString("%@ (Heroic)", comment: ""), task.bountyName)
            : task.bountyName
        let descStr = td.taskDescription
            .replacingOccurrences(of: "$bounty_nz",
                                  with: String(format: String.localizedString("BOUNTY_NZ", comment: ""),
                                               task.bountyName, task.bountySet))
            .replacingOccurrences(of: "$bounty_nd", with: bountyNd)
            .replacingOccurrences(of: "$bounty_n", with: task.bountyName)
            .replacingOccurrences(of: "$bounty_set", with: task.bountySet)
            .replacingOccurrences(of: "$bounty_diff",
                                  with: String.localizedString(task.bountyHeroic ? "BOUNTY_HEROIC" : "BOUNTY_NORMAL",
                                                               comment: ""))
            .replacingOccurrences(of: "$additional_mercs", with: additionalMercs)
        return MercenariesTaskViewModel(id: task.visitorID.intValue,
                                        mercCard: card,
                                        title: title,
                                        description: descStr,
                                        quota: td.quota.intValue,
                                        progress: task.progress.intValue)
    }
}
