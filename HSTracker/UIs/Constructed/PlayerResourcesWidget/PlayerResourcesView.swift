//
//  PlayerResourcesView.swift
//  Arenasmith
//
//  Created by Francisco Moraes on 1/22/26.
//

import SwiftUI

@available(macOS 10.15.0, *)
struct PlayerResourcesView: View {
    @ObservedObject var viewModel: PlayerResourcesViewModel
    
    init(_ vm: PlayerResourcesViewModel) {
        viewModel = vm
    }
    
    var body: some View {
        if viewModel.visibility {
            HStack(spacing: 12) {
                ForEach(viewModel.resources) { resource in
                    HStack {
                        Image(resource.icon).resizable().frame(width: 20, height: 20)
                            .scaledToFit()
                        Text("\(resource.value)")
                    }
                }
            }
            .padding(8)
            .background(Color(hex: "#AA000000"))
            .cornerRadius(8)
        }
    }
}

@available(macOS 10.15.0, *)
#Preview {
    VStack {
        let vm = PlayerResourcesViewModel()
        vm.initialize(30, 10, 10)
        vm.updatePlayerResourcesWidget(35, 15, 12, 5)
        return PlayerResourcesView(vm)
    }
    .padding()
    .background(LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .top, endPoint: .bottom))
}
