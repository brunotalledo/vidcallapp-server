import Foundation

let sampleContacts: [UserContact] = [
    UserContact(id: "1", name: "@alice", subtitle: "Online", imageData: ContactImageData.initials("AL")),
    UserContact(id: "2", name: "@bob", subtitle: "Last seen 2h ago", imageData: ContactImageData.initials("BO")),
    UserContact(id: "3", name: "@carol", subtitle: "Available", imageData: ContactImageData.initials("CA")),
    UserContact(id: "4", name: "@dave", subtitle: "Last seen yesterday", imageData: ContactImageData.initials("DA")),
    UserContact(id: "5", name: "@eve", subtitle: "Online", imageData: ContactImageData.initials("EV"))
]
