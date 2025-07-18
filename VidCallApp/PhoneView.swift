import SwiftUI

struct PhoneView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Blue banner area
                    Rectangle()
                        .fill(Color(red: 0, green: 0.8, blue: 1.0))
                        .frame(height: 200)
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Credit balance card
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.white)
                            Text("Credit balance: $0.00")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0, green: 0.8, blue: 1.0), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Contacts section
                        Text("Contacts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Contact list
                        ScrollView {
                            VStack(spacing: 16) {
                                ContactListItem(
                                    name: "User 1",
                                    phoneNumber: "+19092626295"
                                )
                                // Add more contacts here
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Dial pad button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Show dial pad
                        }) {
                            Image(systemName: "circle.grid.3x3.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color(red: 0, green: 0.8, blue: 1.0))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContactListItem: View {
    let name: String
    let phoneNumber: String
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        HStack {
            Circle()
                .fill(appBlue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(appBlue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundColor(.white)
                    .font(.system(size: 17))
                Text(phoneNumber)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            
            Spacer()
            
            Image(systemName: "phone")
                .foregroundColor(appBlue)
                .font(.system(size: 20))
        }
        .padding(.vertical, 8)
    }
}

struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView()
            .preferredColorScheme(.dark)
    }
} 