//
//  ContactsView.swift
//  VidCallApp
//

import SwiftUI
import FirebaseFirestore

struct ContactsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var contacts: [UserContact] = []
    @State private var showAddContact = false
    @State private var newUsername = ""
    @State private var selectedCall: CallData?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isInCall = false
    // --- New for live username search ---
    @State private var userSearchStatus: UserSearchStatus = .none
    @State private var foundUserDoc: DocumentSnapshot? = nil
    @State private var searchTask: DispatchWorkItem? = nil
    enum UserSearchStatus { case none, searching, found, notFound }

    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    struct CallData: Hashable {
        let roomID: String
        let userID: String
        let userName: String
        let remoteStreamID: String
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Text("Contacts")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top)

                    List {
                        ForEach(contacts) { contact in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .foregroundColor(.white)
                                        .font(.subheadline.bold())
                                    HStack(spacing: 4) {
                                        if isBlocked(contact) {
                                            Image(systemName: "slash.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text("BLOCKED")
                                                .foregroundColor(.red)
                                                .font(.caption.bold())
                                        } else {
                                            Image(systemName: "dollarsign.circle.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 12))
                                            Text(contact.subtitle.isEmpty ? "Press to call" : contact.subtitle)
                                                .foregroundColor(.white)
                                                .font(.caption.bold())
                                        }
                                    }
                                }
                                Spacer()
                                if !isBlocked(contact) {
                                    Button(action: {
                                        initiateCall(to: contact)
                                    }) {
                                        Text("Call")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 8)
                                            .background(appBlue)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if isBlocked(contact) {
                                    Button {
                                        unblockContact(contact)
                                    } label: {
                                        Label("Unblock", systemImage: "checkmark.circle.fill")
                                    }.tint(.green)
                                } else {
                                    Button {
                                        blockContact(contact)
                                    } label: {
                                        Label("Block", systemImage: "xmark.circle.fill")
                                    }.tint(.red)
                                }
                                Button {
                                    if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                        deleteContact(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                            .foregroundColor(.black)
                                    }
                                }
                                .tint(Color(UIColor.systemGray5))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Add Contact tapped")
                            showAddContact = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .padding(24)
                                .background(appBlue)
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        }
                        .padding()
                        .contentShape(Circle())
                    }
                }
                .zIndex(2)
            }
            .sheet(isPresented: $showAddContact) {
                AddContactSheet(
                    newUsername: $newUsername,
                    userSearchStatus: $userSearchStatus,
                    foundUserDoc: $foundUserDoc,
                    searchTask: $searchTask,
                    addContactWithDoc: addContactWithDoc,
                    searchForUsername: searchForUsername,
                    appBlue: appBlue
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Contact"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $isInCall) {
                if let call = selectedCall {
                VideoCallView(
                    roomID: call.roomID,
                    userID: call.userID,
                    userName: call.userName,
                    remoteStreamID: call.remoteStreamID,
                        onEndCall: {
                            isInCall = false
                            selectedCall = nil
                        }
                )
                }
            }
            .onAppear(perform: loadContacts)
        }
    }

    private func loadContacts() {
        guard let user = viewModel.userProfile else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("contacts").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Failed to load contacts: \(error.localizedDescription)")
                return
            }

            let contactDocs = snapshot?.documents ?? []
            var loadedContacts: [UserContact] = []
            let group = DispatchGroup()
            
            for doc in contactDocs {
                let data = doc.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String else {
                    continue
                }
                
                group.enter()
                // Fetch the contact's profile to get their rate
                db.collection("users").document(id).getDocument { profileSnapshot, profileError in
                    defer { group.leave() }
                    let data = profileSnapshot?.data() ?? [:]
                    let ratePerMinute = data["ratePerMinute"] as? Double
                    let sessionRate = data["sessionRate"] as? Double
                    let billingModeRaw = data["billingMode"] as? String
                    let billingMode = BillingMode(rawValue: billingModeRaw ?? "")
                    let initials = String(name.prefix(2)).uppercased()
                    let subtitle: String
                    if let mode = billingMode {
                        if mode == .perSession, let sessionRate = sessionRate {
                            subtitle = "$\(String(format: "%.2f", sessionRate))/session"
                        } else if let ratePerMinute = ratePerMinute {
                            subtitle = "$\(String(format: "%.2f", ratePerMinute))/min"
                        } else {
                            subtitle = "Press to call"
                        }
                    } else if let ratePerMinute = ratePerMinute {
                        subtitle = "$\(String(format: "%.2f", ratePerMinute))/min"
                    } else {
                        subtitle = "Press to call"
                    }
                    let contact = UserContact(
                        id: id,
                        name: name,
                        subtitle: subtitle,
                        imageData: ContactImageData.initials(initials),
                        ratePerMinute: ratePerMinute,
                        sessionRate: sessionRate,
                        billingMode: billingMode
                    )
                    DispatchQueue.main.async {
                        loadedContacts.append(contact)
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.contacts = loadedContacts.sorted { $0.name < $1.name }
            }
        }
    }

    // --- New helper for live username search ---
    private func searchForUsername(_ username: String) {
        let searchUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if searchUsername.isEmpty {
            userSearchStatus = .none
            foundUserDoc = nil
            return
        }
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: searchUsername).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                userSearchStatus = .found
                foundUserDoc = doc
            } else {
                userSearchStatus = .notFound
                foundUserDoc = nil
            }
        }
    }
    // --- Add contact using found doc (Bidirectional) ---
    private func addContactWithDoc() {
        guard let user = viewModel.userProfile else { print("❌ No user profile"); return }
        guard let doc = foundUserDoc else { print("❌ No found user doc"); return }
        let contactUID = doc.documentID
        let data = doc.data() ?? [:]
        let contactUsername = data["username"] as? String ?? newUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let contactRate = data["ratePerMinute"] as? Double
        let contactSessionRate = data["sessionRate"] as? Double
        let contactBillingMode = data["billingMode"] as? String
        
        // Create contact data for both users
        var contactData: [String: Any] = [
            "id": contactUID,
            "name": contactUsername,
            "addedAt": FieldValue.serverTimestamp()
        ]
        
        var reverseContactData: [String: Any] = [
            "id": user.uid,
            "name": user.username,
            "addedAt": FieldValue.serverTimestamp()
        ]
        
        // Add rate information if available
        if let rate = contactRate {
            contactData["ratePerMinute"] = rate
        }
        if let sessionRate = contactSessionRate {
            contactData["sessionRate"] = sessionRate
        }
        if let billingMode = contactBillingMode {
            contactData["billingMode"] = billingMode
        }
        
        // Add current user's rate info to reverse contact
        reverseContactData["ratePerMinute"] = user.ratePerMinute
        if let userSessionRate = user.sessionRate {
            reverseContactData["sessionRate"] = userSessionRate
        }
        reverseContactData["billingMode"] = user.billingMode.rawValue
        
        let db = Firestore.firestore()
        
        // Add to both users' contact lists simultaneously using batch
        let batch = db.batch()
        
        // Add target user to current user's contacts
        let currentUserContactRef = db.collection("users").document(user.uid)
            .collection("contacts").document(contactUID)
        batch.setData(contactData, forDocument: currentUserContactRef)
        
        // Add current user to target user's contacts
        let targetUserContactRef = db.collection("users").document(contactUID)
            .collection("contacts").document(user.uid)
        batch.setData(reverseContactData, forDocument: targetUserContactRef)
        
        // Commit both operations
        batch.commit { error in
            if let error = error {
                print("❌ Failed to add bidirectional contacts: \(error.localizedDescription)")
                alertMessage = "Failed to add contact: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("✅ Bidirectional contact added successfully!")
                print("📱 \(user.username) and \(contactUsername) are now mutual contacts")
                alertMessage = "Contact added successfully! You are now mutual contacts."
                showAlert = true
                showAddContact = false
                loadContacts()
            }
        }
    }

    private func initiateCall(to contact: UserContact) {
        guard let caller = viewModel.userProfile else { 
            print("❌ No caller profile available")
            return 
        }
        
        // Check if contact is blocked
        if isBlocked(contact) {
            print("❌ Cannot call blocked contact: \(contact.name)")
            alertMessage = "Cannot call blocked contact"
            showAlert = true
            return
        }
        
        print("📞 Initiating call from \(caller.username) (\(caller.uid)) to \(contact.name) (\(contact.id))")
        
        let roomID = "viddy_\(UUID().uuidString)"
        let callerInfo = UserContact(
            id: caller.uid,
            name: caller.username,
            subtitle: "",
            imageData: .initials(String(caller.username.prefix(2)).uppercased())
        )
        
        print("📞 Sending call request to UID: \(contact.id)")
        CallManager.shared.sendCall(to: contact.id, from: callerInfo, roomID: roomID)

        selectedCall = CallData(
            roomID: roomID,
            userID: caller.uid,
            userName: caller.username,
            remoteStreamID: "stream_\(contact.id)"
        )
        
        isInCall = true
        print("✅ Call initiated successfully")
    }

    private func deleteContact(at offsets: IndexSet) {
        guard let user = viewModel.userProfile else { return }
        let db = Firestore.firestore()
        for index in offsets {
            let contact = contacts[index]
            db.collection("users").document(user.uid).collection("contacts").document(contact.id).delete { error in
                if let error = error {
                    print("❌ Failed to delete contact: \(error.localizedDescription)")
                } else {
                    print("✅ Contact deleted")
                    loadContacts()
                }
            }
        }
    }

    // MARK: - Block/Unblock Functions
    private func blockContact(_ contact: UserContact) {
        print("🔒 Blocking contact: \(contact.name) (\(contact.id))")
        guard let user = viewModel.userProfile else { 
            print("❌ No user profile available for blocking")
            return 
        }
        let db = Firestore.firestore()
        
        // Add to current user's blocked list
        db.collection("users").document(user.uid).updateData([
            "blockedUsers": FieldValue.arrayUnion([contact.id])
        ]) { error in
            if let error = error {
                print("❌ Failed to block contact: \(error.localizedDescription)")
                alertMessage = "Failed to block contact: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("✅ Contact blocked: \(contact.name)")
                alertMessage = "\(contact.name) has been blocked"
                showAlert = true
                // Refresh user profile to update blockedUsers list
                viewModel.fetchUserProfile(for: user.uid)
            }
        }
    }
    
    private func unblockContact(_ contact: UserContact) {
        print("🔓 Unblocking contact: \(contact.name) (\(contact.id))")
        guard let user = viewModel.userProfile else { 
            print("❌ No user profile available for unblocking")
            return 
        }
        let db = Firestore.firestore()
        
        // Remove from current user's blocked list
        db.collection("users").document(user.uid).updateData([
            "blockedUsers": FieldValue.arrayRemove([contact.id])
        ]) { error in
            if let error = error {
                print("❌ Failed to unblock contact: \(error.localizedDescription)")
                alertMessage = "Failed to unblock contact: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("✅ Contact unblocked: \(contact.name)")
                alertMessage = "\(contact.name) has been unblocked"
                showAlert = true
                // Refresh user profile to update blockedUsers list
                viewModel.fetchUserProfile(for: user.uid)
            }
        }
    }
    
    private func isBlocked(_ contact: UserContact) -> Bool {
        guard let user = viewModel.userProfile else { 
            print("⚠️ No user profile available for block check")
            return false 
        }
        let blocked = user.blockedUsers.contains(contact.id)
        if blocked {
            print("🚫 Contact \(contact.name) is blocked")
        }
        return blocked
    }
    
    private func canCall(_ contact: UserContact) -> Bool {
        return !isBlocked(contact)
    }
}

struct AddContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newUsername: String
    @Binding var userSearchStatus: ContactsView.UserSearchStatus
    @Binding var foundUserDoc: DocumentSnapshot?
    @Binding var searchTask: DispatchWorkItem?
    var addContactWithDoc: () -> Void
    var searchForUsername: (String) -> Void
    var appBlue: Color

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Add Contact")
                    .font(.title.bold())
                    .padding(.top)

                TextField("Enter username", text: $newUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onChange(of: newUsername) {
                        userSearchStatus = .searching
                        foundUserDoc = nil
                        searchTask?.cancel()
                        let task = DispatchWorkItem {
                            searchForUsername(newUsername)
                        }
                        searchTask = task
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
                    }

                HStack(spacing: 8) {
                    if userSearchStatus == .found {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("User found")
                            .foregroundColor(.green)
                    } else if userSearchStatus == .notFound && !newUsername.isEmpty {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                        Text("User not found")
                            .foregroundColor(.red)
                    } else if userSearchStatus == .searching && !newUsername.isEmpty {
                        ProgressView().scaleEffect(0.7)
                        Text("Searching...")
                            .foregroundColor(.gray)
                    }
                }

                Button("Add") {
                    addContactWithDoc()
                }
                .disabled(userSearchStatus != .found)
                .padding()
                .frame(maxWidth: .infinity)
                .background(userSearchStatus == .found ? appBlue : Color.gray)
                .foregroundColor(.black)
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .hideKeyboardOnTap()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(appBlue)
                    }
                }
            }
        }
    }
}
