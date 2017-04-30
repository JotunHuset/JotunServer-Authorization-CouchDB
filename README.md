# JotunServer-Authorization-CouchDB
JotunServer-Authorization store using CouchDB as the backing store

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Example

First of all please take alook at [JotunServer-Authorization plugin usage](https://github.com/JotunHuset/JotunServer-Authorization)

At first you have to create a properties for CouchDB connection. You can [find more information about CouchDB here](https://github.com/IBM-Swift/Kitura-CouchDB).
It could be like this:
```swift
let connectionProperties = ConnectionProperties(host: "127.0.0.1", port: 5984, secured: false, username: nil, password: nil)
```
So then you can create persistor
```swift
let usersProvider = JotunUsersStoreProvider(persistor: EventsPersistor(connectionProperties: connectionProperties))
router.all("api/your_end_point", middleware: TokenAuthMiddleware(userStore: usersProvider))
```

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).
