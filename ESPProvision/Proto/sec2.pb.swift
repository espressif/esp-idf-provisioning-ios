// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: sec2.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// A message must be of type Cmd0 / Cmd1 / Resp0 / Resp1 
enum Sec2MsgType: SwiftProtobuf.Enum {
  typealias RawValue = Int
  case s2SessionCommand0 // = 0
  case s2SessionResponse0 // = 1
  case s2SessionCommand1 // = 2
  case s2SessionResponse1 // = 3
  case UNRECOGNIZED(Int)

  init() {
    self = .s2SessionCommand0
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .s2SessionCommand0
    case 1: self = .s2SessionResponse0
    case 2: self = .s2SessionCommand1
    case 3: self = .s2SessionResponse1
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .s2SessionCommand0: return 0
    case .s2SessionResponse0: return 1
    case .s2SessionCommand1: return 2
    case .s2SessionResponse1: return 3
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Sec2MsgType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static let allCases: [Sec2MsgType] = [
    .s2SessionCommand0,
    .s2SessionResponse0,
    .s2SessionCommand1,
    .s2SessionResponse1,
  ]
}

#endif  // swift(>=4.2)

/// Data structure of Session command0 packet 
struct S2SessionCmd0 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var clientUsername: Data = Data()

  var clientPubkey: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// Data structure of Session response0 packet 
struct S2SessionResp0 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var status: Status = .success

  var devicePubkey: Data = Data()

  var deviceSalt: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// Data structure of Session command1 packet 
struct S2SessionCmd1 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var clientProof: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// Data structure of Session response1 packet 
struct S2SessionResp1 {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var status: Status = .success

  var deviceProof: Data = Data()

  var deviceNonce: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// Payload structure of session data 
struct Sec2Payload {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  ///!< Type of message 
  var msg: Sec2MsgType = .s2SessionCommand0

  var payload: Sec2Payload.OneOf_Payload? = nil

  ///!< Payload data interpreted as Cmd0 
  var sc0: S2SessionCmd0 {
    get {
      if case .sc0(let v)? = payload {return v}
      return S2SessionCmd0()
    }
    set {payload = .sc0(newValue)}
  }

  ///!< Payload data interpreted as Resp0 
  var sr0: S2SessionResp0 {
    get {
      if case .sr0(let v)? = payload {return v}
      return S2SessionResp0()
    }
    set {payload = .sr0(newValue)}
  }

  ///!< Payload data interpreted as Cmd1 
  var sc1: S2SessionCmd1 {
    get {
      if case .sc1(let v)? = payload {return v}
      return S2SessionCmd1()
    }
    set {payload = .sc1(newValue)}
  }

  ///!< Payload data interpreted as Resp1 
  var sr1: S2SessionResp1 {
    get {
      if case .sr1(let v)? = payload {return v}
      return S2SessionResp1()
    }
    set {payload = .sr1(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_Payload: Equatable {
    ///!< Payload data interpreted as Cmd0 
    case sc0(S2SessionCmd0)
    ///!< Payload data interpreted as Resp0 
    case sr0(S2SessionResp0)
    ///!< Payload data interpreted as Cmd1 
    case sc1(S2SessionCmd1)
    ///!< Payload data interpreted as Resp1 
    case sr1(S2SessionResp1)

  #if !swift(>=4.1)
    static func ==(lhs: Sec2Payload.OneOf_Payload, rhs: Sec2Payload.OneOf_Payload) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.sc0, .sc0): return {
        guard case .sc0(let l) = lhs, case .sc0(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sr0, .sr0): return {
        guard case .sr0(let l) = lhs, case .sr0(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sc1, .sc1): return {
        guard case .sc1(let l) = lhs, case .sc1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sr1, .sr1): return {
        guard case .sr1(let l) = lhs, case .sr1(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Sec2MsgType: @unchecked Sendable {}
extension S2SessionCmd0: @unchecked Sendable {}
extension S2SessionResp0: @unchecked Sendable {}
extension S2SessionCmd1: @unchecked Sendable {}
extension S2SessionResp1: @unchecked Sendable {}
extension Sec2Payload: @unchecked Sendable {}
extension Sec2Payload.OneOf_Payload: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension Sec2MsgType: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "S2Session_Command0"),
    1: .same(proto: "S2Session_Response0"),
    2: .same(proto: "S2Session_Command1"),
    3: .same(proto: "S2Session_Response1"),
  ]
}

extension S2SessionCmd0: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "S2SessionCmd0"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "client_username"),
    2: .standard(proto: "client_pubkey"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.clientUsername) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.clientPubkey) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.clientUsername.isEmpty {
      try visitor.visitSingularBytesField(value: self.clientUsername, fieldNumber: 1)
    }
    if !self.clientPubkey.isEmpty {
      try visitor.visitSingularBytesField(value: self.clientPubkey, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: S2SessionCmd0, rhs: S2SessionCmd0) -> Bool {
    if lhs.clientUsername != rhs.clientUsername {return false}
    if lhs.clientPubkey != rhs.clientPubkey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension S2SessionResp0: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "S2SessionResp0"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "status"),
    2: .standard(proto: "device_pubkey"),
    3: .standard(proto: "device_salt"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.status) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.devicePubkey) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.deviceSalt) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.status != .success {
      try visitor.visitSingularEnumField(value: self.status, fieldNumber: 1)
    }
    if !self.devicePubkey.isEmpty {
      try visitor.visitSingularBytesField(value: self.devicePubkey, fieldNumber: 2)
    }
    if !self.deviceSalt.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceSalt, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: S2SessionResp0, rhs: S2SessionResp0) -> Bool {
    if lhs.status != rhs.status {return false}
    if lhs.devicePubkey != rhs.devicePubkey {return false}
    if lhs.deviceSalt != rhs.deviceSalt {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension S2SessionCmd1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "S2SessionCmd1"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "client_proof"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.clientProof) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.clientProof.isEmpty {
      try visitor.visitSingularBytesField(value: self.clientProof, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: S2SessionCmd1, rhs: S2SessionCmd1) -> Bool {
    if lhs.clientProof != rhs.clientProof {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension S2SessionResp1: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "S2SessionResp1"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "status"),
    2: .standard(proto: "device_proof"),
    3: .standard(proto: "device_nonce"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.status) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.deviceProof) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.deviceNonce) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.status != .success {
      try visitor.visitSingularEnumField(value: self.status, fieldNumber: 1)
    }
    if !self.deviceProof.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceProof, fieldNumber: 2)
    }
    if !self.deviceNonce.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceNonce, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: S2SessionResp1, rhs: S2SessionResp1) -> Bool {
    if lhs.status != rhs.status {return false}
    if lhs.deviceProof != rhs.deviceProof {return false}
    if lhs.deviceNonce != rhs.deviceNonce {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Sec2Payload: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Sec2Payload"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "msg"),
    20: .same(proto: "sc0"),
    21: .same(proto: "sr0"),
    22: .same(proto: "sc1"),
    23: .same(proto: "sr1"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.msg) }()
      case 20: try {
        var v: S2SessionCmd0?
        var hadOneofValue = false
        if let current = self.payload {
          hadOneofValue = true
          if case .sc0(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.payload = .sc0(v)
        }
      }()
      case 21: try {
        var v: S2SessionResp0?
        var hadOneofValue = false
        if let current = self.payload {
          hadOneofValue = true
          if case .sr0(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.payload = .sr0(v)
        }
      }()
      case 22: try {
        var v: S2SessionCmd1?
        var hadOneofValue = false
        if let current = self.payload {
          hadOneofValue = true
          if case .sc1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.payload = .sc1(v)
        }
      }()
      case 23: try {
        var v: S2SessionResp1?
        var hadOneofValue = false
        if let current = self.payload {
          hadOneofValue = true
          if case .sr1(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.payload = .sr1(v)
        }
      }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.msg != .s2SessionCommand0 {
      try visitor.visitSingularEnumField(value: self.msg, fieldNumber: 1)
    }
    switch self.payload {
    case .sc0?: try {
      guard case .sc0(let v)? = self.payload else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 20)
    }()
    case .sr0?: try {
      guard case .sr0(let v)? = self.payload else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 21)
    }()
    case .sc1?: try {
      guard case .sc1(let v)? = self.payload else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 22)
    }()
    case .sr1?: try {
      guard case .sr1(let v)? = self.payload else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 23)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Sec2Payload, rhs: Sec2Payload) -> Bool {
    if lhs.msg != rhs.msg {return false}
    if lhs.payload != rhs.payload {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
