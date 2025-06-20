//
//  ContentView.swift
//  WardroAI
//
//  Created by Krish Tandon on 6/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingSignUpView = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView {
                    WardrobeView()
                        .environmentObject(authViewModel)
                        .tabItem {
                            Label("Wardrobe", systemImage: "tshirt.fill")
                        }

                    DailyOutfitsView()
                        .tabItem {
                            Label("Outfits", systemImage: "sparkles")
                        }

                    DiscoverView()
                        .tabItem {
                            Label("Discover", systemImage: "magnifyingglass")
                        }

                    ProfileSettingsView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                }
                .accentColor(.primary)
                .preferredColorScheme(.light)
            } else {
                if showingSignUpView {
                    SignUpView(showingSignUpView: $showingSignUpView)
                        .environmentObject(authViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    LoginView(showingSignUpView: $showingSignUpView)
                        .environmentObject(authViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: showingSignUpView)
    }
}

#Preview {
    ContentView()
}
