import SwiftUI

struct NewCallView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var remoteUserID = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Remote User ID", text: $remoteUserID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                NavigationLink(
                    destination: {
                        if let myID = viewModel.userProfile?.uid,
                           let myName = viewModel.userProfile?.username {
                            VideoCallView(
                                roomID: UUID().uuidString,
                                userID: myID,
                                userName: myName,
                                remoteStreamID: remoteUserID,
                                onEndCall: {}
                            )
                        }
                    },
                    label: {
                        Text("Start Call")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                )

                Spacer()
            }
            .padding()
            .navigationTitle("New Call")
        }
    }
}
