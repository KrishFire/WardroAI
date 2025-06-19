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
        if authViewModel.isAuthenticated {
            TabView {
                WardrobeView()
                    .environmentObject(authViewModel)
                    .tabItem {
                        Label("Wardrobe", systemImage: "hanger")
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
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
        } else {
            // Placeholder for Login/Sign Up Views
            if showingSignUpView {
                SignUpView(showingSignUpView: $showingSignUpView)
                    .environmentObject(authViewModel)
            } else {
                LoginView(showingSignUpView: $showingSignUpView)
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
