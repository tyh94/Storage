# Storage

Storage setup module for connecting cloud storages like Yandex Disk and Google Drive.

---

# Installation

## Swift Package Manager

Add package dependency in Xcode:

1. Open your project in Xcode
2. Select **File → Add Packages**
3. Enter package URL
4. Choose version
5. Add package to your target

Example:

```text
https://github.com/tyh94/Storage.git
```

Or add dependency manually in `Package.swift`.

```swift
dependencies: [
    .package(
        url: "https://github.com/tyh94/Storage.git",
        from: "1.0.0"
    )
]
```

Add products to your target.

```swift
.target(
    name: "YourApp",
    dependencies: [
        "Storage",
        "MKVNetwork"
    ]
)
```

Import modules where needed.

```swift
import Storage
import MKVNetwork
```

---

# Setup

## Create storage factory

Create token and storage factories.

```swift
import Storage
import MKVNetwork

let fileTokenStorageFactory = FileStorageTokenFactory()

let storageFactory = FileStorageFactory(
    network: NetworkManager(),
    tokenFactory: fileTokenStorageFactory,
    logger: logger
)
```

Create available storage activators.

```swift
var availableStorages: [any AvailableStorageSetup] {
    [
        AvailableStorageSetupGoogleDrive(
            fileStorageFactory: storageFactory,
            tokenStorage: fileTokenStorageFactory.make(.googleDrive),
            logger: logger
        ),
        AvailableStorageSetupYandex(
            fileStorageFactory: storageFactory,
            tokenStorage: fileTokenStorageFactory.make(.yandex),
            logger: logger
        ),
    ]
}
```

---

# Storage setup screen

You can present the storage setup screen using `sheet`.

```swift
.sheet(isPresented: $showingStorageSetup) {
    AvailableStorageSetupView(
        viewModel: AvailableStorageSetupViewModel(
            storages: availableStorages,
            completion: { resource, type in
                // Save selected resource and storage type
            }
        )
    )
}
```

`completion` returns:

- `resource` — selected folder or storage resource
- `type` — selected storage type

You should save these values in your application storage.

---

# Yandex Disk

## Create Yandex OAuth application

Create your application at:

https://oauth.yandex.ru

---

## Configure Info.plist

Add URL query schemes.

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>primaryyandexloginsdk</string>
    <string>secondaryyandexloginsdk</string>
</array>
```

---

## Add URL Type

```xml
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>

    <key>CFBundleURLName</key>
    <string>YandexLoginSDK</string>

    <key>CFBundleURLSchemes</key>
    <array>
        <string>yxYOUR_CLIENT_ID</string>
    </array>
</dict>
```

Replace `YOUR_CLIENT_ID` with your Yandex application client ID.

---

## Create Yandex storage activator

```swift
import Foundation
import Storage
import MKVNetwork
import SwiftUI

final class AvailableStorageSetupYandex: AvailableStorageSetup {

    let id: String = UUID().uuidString
    let name: LocalizedStringKey = "Yandex Disk"

    let fileStorageFactory: FileStorageFactory

    lazy var storageBuilder: (StorageResource?) -> FileStorage = { folder in
        self.fileStorageFactory.make(
            .yandex(
                rootPath: folder.path
            )
        )
    }

    let activator: DiskStorageActivator

    init(
        fileStorageFactory: FileStorageFactory,
        tokenStorage: TokenStorage,
        logger: Storage.Logger?
    ) {
        self.fileStorageFactory = fileStorageFactory

        activator = DiskStorageActivatorFactory.build(
            .yandexDisk(clientID: "YOUR_CLIENT_ID"),
            tokenStorage: tokenStorage,
            logger: logger
        )
    }
}
```

Replace `YOUR_CLIENT_ID` with your Yandex application client ID.

---

# Google Drive

## Configure Google Cloud project

1. Create project in Google Cloud Console
2. Enable Google Drive API
3. Create OAuth credentials
4. Add iOS bundle identifier

---

## Create Google Drive storage activator

```swift
import Foundation
import Storage
import MKVNetwork
import SwiftUI

final class AvailableStorageSetupGoogleDrive: AvailableStorageSetup {

    let id: String = UUID().uuidString
    let name: LocalizedStringKey = "Google Drive"

    let fileStorageFactory: FileStorageFactory

    lazy var storageBuilder: (StorageResource?) -> FileStorage = { folder in
        self.fileStorageFactory.make(
            .googleDrive(
                apiKey: "YOUR_API_KEY",
                parentID: folder.id
            )
        )
    }

    let activator: DiskStorageActivator

    init(
        fileStorageFactory: FileStorageFactory,
        tokenStorage: TokenStorage,
        logger: Storage.Logger?
    ) {
        self.fileStorageFactory = fileStorageFactory

        activator = DiskStorageActivatorFactory.build(
            .googleDrive(clientID: "YOUR_CLIENT_ID"),
            tokenStorage: tokenStorage,
            logger: logger
        )
    }
}
```

Replace:

- `YOUR_API_KEY` — Google API key
- `YOUR_CLIENT_ID` — Google OAuth client ID

---

# Result

After successful authorization and folder selection you will receive:

- authorized storage access
- selected storage resource
- configured `FileStorage`

Example:

```swift
let storage = storageBuilder(resource)
```

You can use `storage` for uploading, downloading and managing files.

```swift
try await storage.upload(data, path: "example.txt")
```
