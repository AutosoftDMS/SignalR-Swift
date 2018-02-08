
SignalR-Swift is a client library for iOS based on https://github.com/DyKnow/SignalR-ObjC by DyKnow.  It's built on top of [AlamoFire](https://github.com/Alamofire/Alamofire) and [Starscream](https://github.com/daltoniam/Starscream).
SignalR-Swift is intended to be used along side ASP.NET SignalR, a new library for ASP.NET developers that makes it incredibly simple to add real-time functionality to your applications. What is "real-time web" functionality? It's the ability to have your server-side code push content to the connected clients as it happens, in real-time.

## Installation

### Installation with CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like SignalR-Swift in your projects. See the ["Getting Started" guide for more information](https://guides.cocoapods.org/using/getting-started.html). You can install it with the following command:

```
$ gem install cocoapods
```

#### Podfile

To integrate SignalR-Swift into your Xcode project using CocoaPods, specify it in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'SignalRSwift', '~> 2.0.2'
 ```

Then, run the following command:

```
$ pod install
```

## Example Usage
### Persistent Connection
```c#
using System.Threading.Tasks;
using Microsoft.AspNet.SignalR;

//Server
public class MyConnection : PersistentConnection 
{
    protected override Task OnReceived(IRequest request, string connectionId, string data) 
    {
        // Broadcast data to all clients
        return Connection.Broadcast(data);
    }
}
```

```swift
import SignalRSwift

//Client
var connection = Connection(withUrl: "http://localhost/endpoint/");

// register for connection lifecycle events
connection.started = {
    print("Connected")
}

connection.reconnecting = {
    print("Reconnecting...")
}

connection.reconnected = {
    print("Reconnected.")
}

connection.closed = {
    print("Disconnected")
}

connection.connectionSlow = { print("Connection slow...") }

connection.error = { error in
  print("Error")
}

connection.start()

```
### Hubs
```c#
//Server
public class Chat : Hub 
{
    public void Send(string message)
    {
        // Call the addMessage method on all clients            
        Clients.All.addMessage(message);
    }
}
```

```Swift
//Client
import SignalRSwift

// Connect to the service
var hubConnection = HubConnection(withUrl: "http://localhost/endpoint")

var chat = hubConnection.createHubProxy(hubName: "chat")

chat.on(eventName: "addMessage") { (args) in
  if let message = args[0] {
    print("Message: \(message)")
  }
}

// register for connection lifecycle events
hubConnection.started = {
    print("Connected")
}

hubConnection.reconnecting = {
    print("Reconnecting...")
}

hubConnection.reconnected = {
    print("Reconnected.")
}

hubConnection.closed = {
    print("Disconnected")
}

hubConnection.connectionSlow = { print("Connection slow...") }

hubConnection.error = { error in
  print("Error")
}

hubConnection.start()
```

### Customizing Query Params

#### Persistent Connections
```Swift
let qs = [
   "param1": "1",
   "param2": "another"
}
var connection = Connection(withUrl: "http://localhost/endpoint", queryString: qs)
```

#### Hub Connections
```Swift
let qs = [
   "param1": "1",
   "param2": "another"
}
var hubConnection = HubConnection(withUrl: "http://localhost/endpoint", queryString: qs)
```

### Customizing Request Headers

#### Persistent Connections
```Swift
let headers = [
   "param1": "1",
   "param2": "another"
]
var connection = Connection(withUrl: "http://localhost/endpoint", queryString: qs)
connection.headers = headers

// alternative usage
var connection = Connection(withUrl: "http://localhost/endpoint", queryString: qs)
connection.addValue(value: "1", forHttpHeaderField: "param1")
connection.addValue(value: "another", forHttpHeaderField: "param2")
```

#### Hub Connections
```Swift
let headers = [
   "param1": "1",
   "param2": "another"
}
var hubConnection = HubConnection(withUrl: "http://localhost/endpoint", queryString: qs)
hubConnection.headers = headers

// alternative usage
var hubConnection = HubConnection(withUrl: "http://localhost/endpoint", queryString: qs)
hubConnection.addValue(value: "1", forHttpHeaderField: "param1")
hubConnection.addValue(value: "another", forHttpHeaderField: "param2")
```

### Networking

- SignalR-Swift uses [Alamofire](https://github.com/Alamofire/Alamofire).  The minimum supported version of AlamoFire is 4.2.x
- SignalR-Swift uses  [Starscream](https://github.com/daltoniam/Starscream).


## LICENSE

SignalR-Swift is available under the MIT license. See the [LICENSE](https://github.com/AutosoftDMS/SignalR-Swift/blob/master/LICENSE.md) file for more info.<br/>
SignalR-Swift uses 3rd-party code which each have specific licenses, see [ACKNOWLEDGEMENTS](https://github.com/AutosoftDMS/SignalR-Swift/blob/master/ACKNOWLEDGEMENTS.md) for contributions
