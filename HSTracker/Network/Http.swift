//
//  Http.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna

struct Http {
    let url: String

    init(url: String) {
        self.url = url
    }

    func html(method: HttpMethod,
              parameters: [String: Any] = [:],
              headers: [String: String] = [:],
              completion: @escaping (HTMLDocument?) -> Void) {
        guard let urlRequest = prepareRequest(method: method,
                                              encoding: .html,
                                              parameters: parameters,
                                              headers: headers) else {
                                                completion(nil)
                                                return
        }

        Http.session.dataTask(with: urlRequest) { data, response, error in
            logger.info("Fetching \(self.url) complete")

            if let error = error {
                logger.error("html : \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            } else if let data = data {
                var usedEncoding = String.Encoding.utf8
                if let encodingName = response?.textEncodingName {
                    let encoding = CFStringConvertEncodingToNSStringEncoding(
                        CFStringConvertIANACharSetNameToEncoding(encodingName as CFString))
                    if encoding != UInt(kCFStringEncodingInvalidId) {
                        usedEncoding = String.Encoding(rawValue: encoding)
                    }
                }
                if let html = String(data: data, encoding: usedEncoding),
                    let doc = try? Kanna.HTML(html: html, encoding: usedEncoding) {
                    DispatchQueue.main.async {
                        completion(doc)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            }.resume()
    }

    func json(method: HttpMethod,
              parameters: [String: Any] = [:],
              headers: [String: String] = [:],
              completion: @escaping (Any?) -> Void) {
        guard let urlRequest = prepareRequest(method: method,
                                              encoding: .json,
                                              parameters: parameters,
                                              headers: headers) else {
                                                completion(nil)
                                                return
        }

        Http.session.dataTask(with: urlRequest) { data, response, error in
            logger.info("Fetching \(self.url) complete")

            if let error = error {
                logger.error("request error : \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            } else if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments)
                    DispatchQueue.main.async {
                        completion(json)
                    }
                    return
                } catch let error {
                    logger.error("json parsing : \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } else {
                logger.error("\(#function): \(String(describing: error)), "
                    + "\(String(describing: data)), \(String(describing: response))")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            }.resume()
    }

    func upload(method: HttpMethod,
                headers: [String: String] = [:],
                data: Data) {
        guard let urlRequest = prepareRequest(method: method,
                                              encoding: .multipart,
                                              parameters: [:],
                                              headers: headers) else {
                                                return
        }

        Http.session.uploadTask(with: urlRequest,
                                from: data) { data, response, error in
                                    if let error = error {
                                        logger.error("request error : \(error)")
                                    } else if let data = data {
                                        logger.verbose("upload result : \(data)")
                                    }
                                    
                                        logger.error("\(#function): "
                                            + "\(String(describing: error)), "
                                            + "data: \(String(describing: data)), "
                                            + "response: \(String(describing: response))")
                                    
            }.resume()
    }

    private func prepareRequest(method: HttpMethod,
                                encoding: HttpEncoding,
                                parameters: [String: Any] = [:],
                                headers: [String: String] = [:]) -> URLRequest? {
        var urlQuery = ""
        if method == .get {
            urlQuery = "?" + query(parameters: parameters)
        }

        guard let url = URL(string: url + urlQuery) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue.uppercased()

        if encoding == .json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            if method != .get {
                do {
                    let bodyData = try JSONSerialization.data(withJSONObject: parameters,
                                                              options: .prettyPrinted)
                    request.httpBody = bodyData
                } catch let error {
                    logger.error("json converting : \(error)")
                    return nil
                }
            }
        }

        for (headerField, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }

        return request
    }
}

// MARK: - Code copied from Alamofire
extension Http {
    func query(parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }

        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }

    private func queryComponents(_ key: String, _ value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    private func escape(_ string: String) -> String {
        // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let generalDelimitersToEncode = ":#[]@"

        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn:
            "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string

    }

    fileprivate static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHTTPHeaders
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        }()

    public static func userAgent() -> String {
        if let info = Bundle.main.infoDictionary {
            let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
            let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

            let osNameVersion: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                let versionString = "\(version.majorVersion)"
                    + ".\(version.minorVersion)"
                    + ".\(version.patchVersion)"

                return "macOS \(versionString)"
            }()

            return "\(executable)/\(appVersion) (build:\(appBuild); \(osNameVersion))"
        }

        return "HSTracker"
    }
    private static let defaultHTTPHeaders: [String: String] = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages
            .prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
            }.joined(separator: ", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        let ua = userAgent()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": ua
        ]
    }()
}
