import Contacts
import ContactsUI
import SwiftUI

enum ContactsService {
    private static let avatarFetchKeys: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactImageDataAvailableKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
    ]

    static var canReadContacts: Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return true
        default:
            return false
        }
    }

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

    /// Photo bytes from the contact card (full image, then thumbnail).
    static func avatarData(from contact: CNContact) -> Data? {
        if let full = contact.imageData, !full.isEmpty { return full }
        if let thumb = contact.thumbnailImageData, !thumb.isEmpty { return thumb }
        return nil
    }

    static func avatarData(forContactIdentifier identifier: String) -> Data? {
        guard canReadContacts else { return nil }
        let store = CNContactStore()
        guard let contact = try? store.unifiedContact(
            withIdentifier: identifier,
            keysToFetch: avatarFetchKeys
        ) else { return nil }
        return avatarData(from: contact)
    }

    /// Looks up a saved email/phone in Contacts and returns the card photo when present.
    static func avatarData(matching normalizedContact: String) -> Data? {
        guard canReadContacts, let contact = contact(matching: normalizedContact) else { return nil }
        return avatarData(from: contact)
    }

    static func friendLink(from contact: CNContact) -> FriendLink? {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Contact"
        let avatar = avatarData(forContactIdentifier: contact.identifier)
            ?? avatarData(from: contact)

        if let email = contact.emailAddresses.first?.value as String? {
            return FriendLink(name: name, contact: email, avatarData: avatar)
        }
        if let phone = contact.phoneNumbers.first?.value.stringValue {
            return FriendLink(name: name, contact: phone, avatarData: avatar)
        }
        return nil
    }

    /// Fills `avatarData` from the device address book when missing.
    static func linkWithContactPhoto(_ link: FriendLink) -> FriendLink {
        guard link.avatarData == nil else { return link }
        guard let data = avatarData(matching: link.contact) else { return link }
        var updated = link
        updated.avatarData = data
        return updated
    }

    // MARK: - Lookup

    private static func contact(matching normalizedContact: String) -> CNContact? {
        let store = CNContactStore()
        if ContactNormalizer.isEmail(normalizedContact) {
            let predicate = CNContact.predicateForContacts(matchingEmailAddress: normalizedContact)
            let matches = (try? store.unifiedContacts(matching: predicate, keysToFetch: avatarFetchKeys)) ?? []
            return matches.first
        }
        for variant in phoneLookupVariants(normalizedContact) {
            let number = CNPhoneNumber(stringValue: variant)
            let predicate = CNContact.predicateForContacts(matching: number)
            let matches = (try? store.unifiedContacts(matching: predicate, keysToFetch: avatarFetchKeys)) ?? []
            if let match = matches.first { return match }
        }
        return nil
    }

    private static func phoneLookupVariants(_ normalized: String) -> [String] {
        var variants: [String] = [normalized]
        let digits = normalized.filter(\.isNumber)
        guard !digits.isEmpty else { return variants }
        variants.append(digits)
        if !normalized.hasPrefix("+") {
            variants.append("+\(digits)")
        }
        if digits.count == 10 {
            variants.append("+1\(digits)")
        }
        return Array(Set(variants))
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
