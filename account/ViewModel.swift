import Foundation
class LoginViewModel {
    lazy var logins: [Login] = loadLoginsFromUserDefaults()
    private let userDefaults = UserDefaults.standard
    private let loginsKey = "Logins"
    var generatedPassword: String?
    init() {
        logins = loadLoginsFromUserDefaults()
    }
    func loadLoginsFromUserDefaults() -> [Login] {
        if let savedLoginsData = userDefaults.data(forKey: loginsKey),
           let savedLogins = try? JSONDecoder().decode([Login].self, from: savedLoginsData) {
            return savedLogins
        }
        return []
    }
    private func saveLoginsToUserDefaults() {
        if let loginsData = try? JSONEncoder().encode(logins) {
            userDefaults.set(loginsData, forKey: loginsKey)
        }
    }
    func createLogin(name: String, email: String, password: String) {
        let newLogin = Login(name: name, email: email, password: password)
        logins.append(newLogin)
        saveLoginsToUserDefaults()
    }
    func deleteLogin(at index: Int) {
        logins.remove(at: index)
        saveLoginsToUserDefaults()
    }
    func generatePassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()§±<>?:|/{[]-=+~;}"
        let passwordLength = 8
        var password = ""
        for _ in 0..<passwordLength {
            let randomIndex = Int(arc4random_uniform(UInt32(characters.count)))
            let randomCharacter = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            password.append(randomCharacter)
        }
        return password
    }
    func searchLogins(with name: String) {
        logins = logins.filter { $0.name.contains(name) }
    }
}
