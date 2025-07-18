import SwiftUI

struct ChatsView: View {
    var body: some View {
        NavigationView {
            Text("Chats")
                .navigationTitle("Chats")
        }
    }
}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView()
    }
} 