import Foundation
import Socket

// MARK: Protocols

/// Delegate for service discovery
public protocol SSDPDiscoveryDelegate {
    /// Tells the delegate a requested service has been discovered.
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didDiscoverService service: SSDPService)

    /// Tells the delegate that the discovery ended due to an error.
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didFinishWithError error: Error)

    /// Tells the delegate that the discovery has started.
    func ssdpDiscoveryDidStart(_ discovery: SSDPDiscovery)

    /// Tells the delegate that the discovery has finished.
    func ssdpDiscoveryDidFinish(_ discovery: SSDPDiscovery)
}

// public extension SSDPDiscoveryDelegate {
//    func ssdpDiscovery(_: SSDPDiscovery, didDiscoverService _: SSDPService) {}
//
//    func ssdpDiscovery(_: SSDPDiscovery, didFinishWithError _: Error) {}
//
//    func ssdpDiscoveryDidStart(_: SSDPDiscovery) {}
//
//    func ssdpDiscoveryDidFinish(_: SSDPDiscovery) {}
// }

/// SSDP discovery for UPnP devices on the LAN
public class SSDPDiscovery {
    /// The UDP socket
    private var socket: Socket?

    /// Delegate for service discovery
    public var delegate: SSDPDiscoveryDelegate?

    /// The client is discovering
    public var isDiscovering: Bool {
        return socket != nil
    }

    // MARK: Initialisation

    public init() {}

    deinit {
        self.stop()
    }

    // MARK: Private functions

    /// Read responses.
    private func readResponses() {
        do {
            var data = Data()
            let (bytesRead, address) = try socket!.readDatagram(into: &data)

            if bytesRead > 0 {
                let response = String(data: data, encoding: .utf8)
                let (remoteHost, _) = Socket.hostnameAndPort(from: address!)!
                delegate?.ssdpDiscovery(self, didDiscoverService: SSDPService(host: remoteHost, response: response!))
            }

        } catch {
            forceStop()
            delegate?.ssdpDiscovery(self, didFinishWithError: error)
        }
    }

    /// Read responses with timeout.
    private func readResponses(forDuration duration: TimeInterval) {
        let queue = DispatchQueue.global()

        queue.async {
            while self.isDiscovering {
                self.readResponses()
            }
        }

        queue.asyncAfter(deadline: .now() + duration) { [unowned self] in
            self.stop()
        }
    }

    /// Force stop discovery closing the socket.
    private func forceStop() {
        if isDiscovering {
            socket?.close()
        }
        socket = nil
    }

    // MARK: Public functions

    /**
     Discover SSDP services for a duration.
     - Parameters:
         - duration: The amount of time to wait.
         - searchTarget: The type of the searched service.
     */
    open func discoverService(forDuration duration: TimeInterval = 10, searchTarget: String = "ssdp:all") {
        delegate?.ssdpDiscoveryDidStart(self)

        let message = "M-SEARCH * HTTP/1.1\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "ST: \(searchTarget)\r\n" + "ST: ssdp:all" + "\r\n" +
            "MX: \(Int(duration))\r\n\r\n"

        do {
            socket = try Socket.create(type: .datagram, proto: .udp)
            try socket?.listen(on: 0)

            readResponses(forDuration: duration)
            try socket?.write(from: message, to: Socket.createAddress(for: "239.255.255.250", on: 1900)!)

        } catch {
            forceStop()
            delegate?.ssdpDiscovery(self, didFinishWithError: error)
        }
    }

    /// Stop the discovery before the timeout.
    open func stop() {
        if socket != nil {
            forceStop()
            delegate?.ssdpDiscoveryDidFinish(self)
        }
    }
}
