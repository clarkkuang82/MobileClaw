import SwiftData
import Foundation

public enum ModelContainerSetup {
    public static func create(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            ConversationEntity.self,
            MessageEntity.self,
            AgentEntity.self,
            ProviderSettingEntity.self,
        ])

        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(
                "MobileClaw",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            config = ModelConfiguration(
                "MobileClaw",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        }

        return try ModelContainer(for: schema, configurations: [config])
    }
}
