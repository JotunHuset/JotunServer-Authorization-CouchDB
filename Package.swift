
import PackageDescription

let package = Package(
    name: "JotunServer-Authorization-CouchDB",
    targets: [
    ],
    dependencies: [
        .Package(url: "https://github.com/JotunHuset/JotunServer-Authorization.git", majorVersion: 0),
        .Package(url: "https://github.com/JotunHuset/JotunServer-CouchDBManagement.git", majorVersion: 0)
    ]
)
