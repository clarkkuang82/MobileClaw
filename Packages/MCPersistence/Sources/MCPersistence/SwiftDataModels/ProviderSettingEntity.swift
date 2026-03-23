import SwiftData
import Foundation

@Model
public final class ProviderSettingEntity {
    public var id: UUID = UUID()
    public var providerRawValue: String = ""
    public var displayName: String = ""
    public var baseURL: String = ""
    public var isEnabled: Bool = true
    public var defaultModelID: String?

    public init(
        providerRawValue: String = "",
        displayName: String = "",
        baseURL: String = ""
    ) {
        self.id = UUID()
        self.providerRawValue = providerRawValue
        self.displayName = displayName
        self.baseURL = baseURL
    }
}
