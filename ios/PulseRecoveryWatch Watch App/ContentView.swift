//
//  ContentView.swift
//  PulseRecoveryWatch Watch App
//
//  Created by Malcolm Lightbody on 21/05/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sender = WatchSessionSender.shared

    var body: some View {
        VStack(spacing: 12) {
            Text("Pulse Recovery")
                .font(.headline)

            Text(sender.statusMessage)
                .font(.caption)
                .multilineTextAlignment(.center)

            Button("Send Fake Session") {
                sender.sendFakeRecoverySession()
            }
        }
        .padding()
    }
}
