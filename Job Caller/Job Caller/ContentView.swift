//
//  ContentView.swift
//  Job Caller
//
//  Created by Elliot Williams on 2025-07-18.
//

import SwiftUI
import AVFoundation

// MARK: - Main App
@main
struct JobCallerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CallManager())
        }
    }
}

// MARK: - Data Models
struct Contact: Identifiable, Codable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var company: String
}

struct CallRecord: Identifiable {
    let id = UUID()
    let contact: Contact
    let date: Date
    let duration: TimeInterval
}

// MARK: - Call Manager
class CallManager: ObservableObject {
    @Published var isOnCall = false
    @Published var callStatus = "Ready"
    
    // In real app: Connect to Twilio Voice SDK
    func startCall(to number: String) {
        isOnCall = true
        callStatus = "Calling..."
        
        // Simulate call initiation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.callStatus = "Connected"
        }
    }
    
    func endCall() {
        isOnCall = false
        callStatus = "Call ended"
    }
}

// MARK: - Views

// Main Tab View
struct ContentView: View {
    var body: some View {
        TabView {
            DialerView()
                .tabItem { Label("Dial", systemImage: "phone") }
            
            ContactsView()
                .tabItem { Label("Contacts", systemImage: "person.2") }
            
            CallHistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}

// Dialer Screen
struct DialerView: View {
    @EnvironmentObject var callManager: CallManager
    @State private var phoneNumber = ""
    
    let dialPad = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]
    
    var body: some View {
        VStack {
            // Number Display
            TextField("Enter number", text: $phoneNumber)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
                .keyboardType(.numberPad)
            
            // Dial Pad
            ForEach(dialPad, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { button in
                        DialButton(title: button) {
                            phoneNumber += button
                        }
                    }
                }
            }
            
            // Call Button
            Button(action: makeCall) {
                Image(systemName: "phone.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(25)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .padding()
            .disabled(phoneNumber.isEmpty)
            
            Spacer()
        }
        .navigationTitle("Job Caller")
        .sheet(isPresented: $callManager.isOnCall) {
            CallActiveView(phoneNumber: phoneNumber)
        }
    }
    
    private func makeCall() {
        callManager.startCall(to: phoneNumber)
    }
}

struct DialButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title)
                .frame(width: 80, height: 80)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Circle())
        }
        .padding(5)
    }
}

// Active Call Screen
struct CallActiveView: View {
    @EnvironmentObject var callManager: CallManager
    let phoneNumber: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(phoneNumber)
                .font(.largeTitle)
            
            Text(callManager.callStatus)
                .font(.title2)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
            
            Button(action: endCall) {
                Image(systemName: "phone.down.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(25)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding()
        .onDisappear(perform: endCall)
    }
    
    private func endCall() {
        callManager.endCall()
    }
}

// Contacts Management
struct ContactsView: View {
    @State private var contacts: [Contact] = []
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contacts) { contact in
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(.headline)
                        Text("\(contact.company) · \(contact.phoneNumber)")
                            .font(.subheadline)
                    }
                }
                .onDelete(perform: deleteContacts)
            }
            .navigationTitle("Job Contacts")
            .toolbar {
                Button(action: { showingAddContact = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView(contacts: $contacts)
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
    }
}

struct AddContactView: View {
    @Binding var contacts: [Contact]
    @State private var name = ""
    @State private var phone = ""
    @State private var company = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Company", text: $company)
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newContact = Contact(
                            name: name,
                            phoneNumber: phone,
                            company: company
                        )
                        contacts.append(newContact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
}

// Call History
struct CallHistoryView: View {
    @State private var callHistory: [CallRecord] = []
    
    var body: some View {
        NavigationView {
            List(callHistory) { record in
                VStack(alignment: .leading) {
                    Text(record.contact.name)
                    Text("\(record.date, style: .date) · \(formattedDuration(record.duration))")
                        .font(.caption)
                }
            }
            .navigationTitle("Call History")
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: duration) ?? ""
    }
}


#Preview {
    ContentView()
}
