// URI.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Itsari

public struct URI {
    public struct UserInfo: Hashable, CustomStringConvertible {
        public let username: String
        public let password: String
        
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
        
        public var hashValue: Int {
            return description.hashValue
        }
        
        public var description: String {
            return "\(username):\(password)"
        }
    }

    public let scheme: String?
    public let userInfo: UserInfo?
    public let host: String?
    public let port: Int?
    public let path: String?
    public let query: [String: String]
    public let fragment: String?

    public init(scheme: String? = nil, userInfo: UserInfo? = nil, host: String? = nil, port: Int? = nil, path: String? = nil, query: [String: String] = [:], fragment: String? = nil) {
        self.scheme = scheme
        self.userInfo = userInfo
        self.host = host
        self.port = port
        self.path = path

        var parsedQuery: [String: String] = [:]

        for (key, value) in query {
            if let
                parsedKey = String(URLEncodedString: key),
                parsedValue = String(URLEncodedString: value) {
                    parsedQuery[parsedKey] = parsedValue
            }
        }

        self.query = parsedQuery
        self.fragment = fragment
    }
}

extension URI {
    public init(string: String) {
        let u = parse_uri(string)

        if u.field_set & 1 != 0 {
            scheme = URI.getSubstring(string, start: u.scheme_start, end: u.scheme_end)
        } else {
            scheme = nil
        }

        if u.field_set & 2 != 0 {
            host = URI.getSubstring(string, start: u.host_start, end: u.host_end)
        } else {
            host = nil
        }

        if u.field_set & 4 != 0 {
            port = Int(u.port)
        } else {
            port = nil
        }

        if u.field_set & 8 != 0 {
            path = URI.getSubstring(string, start: u.path_start, end: u.path_end)
        } else {
            path = nil
        }

        if u.field_set & 16 != 0 {
            let queryString = URI.getSubstring(string, start: u.query_start, end: u.query_end)
            query = URI.parseQueryString(queryString)
        } else {
            query = [:]
        }

        if u.field_set & 32 != 0 {
            fragment = URI.getSubstring(string, start: u.fragment_start, end: u.fragment_end)
        } else {
            fragment = nil
        }

        if u.field_set & 64 != 0 {
            let userInfoString = URI.getSubstring(string, start: u.user_info_start, end: u.user_info_end)
            userInfo = URI.parseUserInfoString(userInfoString)
        } else {
            userInfo = nil
        }
    }

    @inline(__always) private static func getSubstring(string: String, start: UInt16, end: UInt16) -> String {
        return string[string.startIndex.advancedBy(Int(start)) ..< string.startIndex.advancedBy(Int(end))]
    }

    @inline(__always) private static func parseUserInfoString(userInfoString: String) -> URI.UserInfo? {
        let userInfoElements = userInfoString.characters.split{$0 == ":"}.map(String.init)
        return URI.UserInfo(
            username: userInfoElements[0],
            password: userInfoElements[1]
        )
    }

    @inline(__always) private static func parseQueryString(queryString: String) -> [String: String] {
        var query: [String: String] = [:]
        let queryTuples = queryString.characters.split{$0 == "&"}.map(String.init)
        for tuple in queryTuples {
            let queryElements = tuple.characters.split{$0 == "="}.map(String.init)
            if queryElements.count == 1 {
                query[queryElements[0]] = ""
            } else if queryElements.count == 2 {
                query[queryElements[0]] = queryElements[1]
            }
        }
        return query
    }
}

extension URI: CustomStringConvertible {
    public var description: String {
        var string = ""

        if let scheme = scheme {
            string += "\(scheme)://"
        }

        if let userInfo = userInfo {
            string += "\(userInfo)@"
        }

        if let host = host {
            string += "\(host)"
        }

        if let port = port {
            string += ":\(port)"
        }

        if let path = path {
            string += "\(path)"
        }

        if query.count > 0 {
            string += "?"
        }

        for (name, value) in query {
            string += "\(name)=\(value)"
        }

        if let fragment = fragment {
            string += "#\(fragment)"
        }

        return string
    }
}

extension URI: Hashable {
    public var hashValue: Int {
        return description.hashValue
    }
}

public func ==(lhs: URI, rhs: URI) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public func ==(lhs: URI.UserInfo, rhs: URI.UserInfo) -> Bool {
    return lhs.hashValue == rhs.hashValue
}