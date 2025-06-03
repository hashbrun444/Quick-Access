// ContentView.swift
// Quick Access
//
// Created by Cristian Matache on 6/2/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct FolderOpenerApp: App {
    @AppStorage("folderPath") var folderPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    
    // No default window
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            PreferencesView(folderPath: $folderPath)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    var preferencesWindow: NSWindow?

    // Add/ensure @AppStorage properties for all bindings needed by PreferencesView
    @AppStorage("folderPath") var folderPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateStatusBarIcon()
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        statusMenu = NSMenu()
        statusMenu?.addItem(NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ","))
        statusMenu?.addItem(NSMenuItem.separator())
        statusMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    func updateStatusBarIcon() {
        statusItem?.button?.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Open Folder")
        // If using a default system symbol, you might want it to be a template image
        // statusItem?.button?.image?.isTemplate = true
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            if let button = statusItem?.button, let menu = statusMenu {
                statusItem?.menu = menu
                button.performClick(nil)
                statusItem?.menu = nil
            }
        } else if event.type == .leftMouseUp {
            openFolder()
        }
    }
    
    @objc func openFolder() {
        // Use the @AppStorage property from AppDelegate for consistency
        let currentFolderPath = self.folderPath
        let url = URL(fileURLWithPath: currentFolderPath)
        NSWorkspace.shared.open(url)
    }
    
    @objc func openPreferences() {
        if preferencesWindow == nil {
            // Use bindings from AppDelegate's @AppStorage properties
            let preferencesView = PreferencesView(
                folderPath: self.$folderPath
            )
            let hostingController = NSHostingController(rootView: preferencesView)
            preferencesWindow = NSWindow(contentViewController: hostingController)
            preferencesWindow?.title = "Preferences"
            preferencesWindow?.setContentSize(NSSize(width: 400, height: 150))
            preferencesWindow?.styleMask = [.titled, .closable, .miniaturizable]
            preferencesWindow?.isReleasedWhenClosed = false // Important for reusing the window
            preferencesWindow?.center()
            
            NotificationCenter.default.addObserver(self, selector: #selector(preferencesWindowClosed), name: NSWindow.willCloseNotification, object: preferencesWindow)
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func preferencesWindowClosed(notification: Notification) {
        // This ensures that if the specific window that was our preferencesWindow is closed, we nil it out.
        if let window = notification.object as? NSWindow, window == preferencesWindow {
            preferencesWindow = nil // Allow a new window to be created next time
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// No changes needed for PreferencesView or FolderOpenerApp main struct
// (assuming PreferencesView uses the bindings as passed)

struct PreferencesView: View {
    @Binding var folderPath: String
    @State private var refreshToggle = false // This can potentially be removed if bindings are fully reactive
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 48)
                    .foregroundColor(Color(red: 1.0, green: 0.26, blue: 0.13))
                    .cornerRadius(4) // Optional: for the icon look
                VStack(alignment: .leading) {
                    Text("Quick Access")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("hashbrun444")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Version: 1.0") // Consider making this dynamic if you plan updates
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }.padding(.bottom, 16)
            
            Text("Select Folder")
                .font(.headline)
            HStack(spacing: 4) {
                Text(folderPath)
                    .id(refreshToggle) // May not be needed with @AppStorage bindings
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Choose...") {
                    showFolderPicker()
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 150)
    }
    
    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.directoryURL = URL(fileURLWithPath: folderPath, isDirectory: true) // Ensure isDirectory is true for path
        if panel.runModal() == .OK, let url = panel.url {
            folderPath = url.path
            refreshToggle.toggle() // Keep for now, test if it's still needed
        }
    }
}
