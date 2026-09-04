import Foundation
import AuthenticationServices

@Observable
final class AuthManager {
    var isSignedIn = false
    var userID: String?
    var userName: String?
    var isGuest = false

    private let keychainKey = "com.gymapp1.appleUserID"
    private let nameKey = "com.gymapp1.userName"
    private let guestModeKey = "com.gymapp1.isGuestMode"

    init() {
        checkExistingSignIn()
    }

    /// Checks for a previously saved guest choice or Apple sign-in,
    /// and verifies with Apple that a saved sign-in is still valid.
    func checkExistingSignIn() {
        if UserDefaults.standard.bool(forKey: guestModeKey) {
            isGuest = true
            isSignedIn = true
            return
        }

        guard let savedID = KeychainHelper.read(forKey: keychainKey) else {
            isSignedIn = false
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: savedID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.userID = savedID
                    self?.userName = KeychainHelper.read(forKey: self?.nameKey ?? "")
                    self?.isSignedIn = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            let id = credential.user
            KeychainHelper.save(id, forKey: keychainKey)
            userID = id

            if let given = credential.fullName?.givenName {
                KeychainHelper.save(given, forKey: nameKey)
                userName = given
            } else {
                userName = KeychainHelper.read(forKey: nameKey)
            }

            isGuest = false
            isSignedIn = true

        case .failure(let error):
            #if DEBUG
            print("Sign in with Apple failed: \(error)")
            #endif
        }
    }

    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: guestModeKey)
        isGuest = true
        isSignedIn = true
    }

    func signOut() {
        KeychainHelper.delete(forKey: keychainKey)
        KeychainHelper.delete(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: guestModeKey)
        userID = nil
        userName = nil
        isGuest = false
        isSignedIn = false
    }
}
