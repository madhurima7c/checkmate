import Contacts
import ContactsUI
import SwiftUI

enum ContactsService {
    static func requestAccessIfNeeded() async -> Bool {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                store.requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    static func friendLink(from contact: CNContact) -> FriendLink? {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Contact"
        let avatar = contact.imageData
        if let email = contact.emailAddresses.first?.value as String? {
            return FriendLink(name: name, contact: email, avatarData: avatar)
        }
        if let phone = contact.phoneNumbers.first?.value.stringValue {
            return FriendLink(name: name, contact: phone, avatarData: avatar)
        }
        return nil
    }
}

struct SystemContactPicker: UIViewControllerRepresentable {
    var onPick: (FriendLink) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(
            format: "emailAddresses.@count > 0 OR phoneNumbers.@count > 0"
        )
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (FriendLink) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (FriendLink) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if let link = ContactsService.friendLink(from: contact) {
                onPick(link)
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
    }
}
