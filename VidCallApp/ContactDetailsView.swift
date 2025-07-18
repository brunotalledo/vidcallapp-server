

import SwiftUI

struct ContactDetailsView: View {
    let contact: UserContact

    var body: some View {
        VStack(spacing: 20) {
            Text(contact.name)
                .font(.title)
                .foregroundColor(.white)

            Text(contact.subtitle)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
