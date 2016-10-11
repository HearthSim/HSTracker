//
//  Http.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Kanna
import CleanroomLogger

struct Http {
    let url: String

    init(url: String) {
        self.url = url
    }

    func html(method: HttpMethod,
              parameters: [String: AnyObject] = [:],
              headers: [String: String] = [:],
              completion: (HTMLDocument?) -> Void) {
        guard let urlRequest = prepareRequest(method,
                                              encoding: .html,
                                              parameters: parameters,
                                              headers: headers) else {
                                                completion(nil)
                                                return
        }

        Http.session.dataTaskWithRequest(urlRequest) { data, response, error in
            Log.info?.message("Fetching \(self.url) complete")

            if let error = error {
                Log.error?.message("html : \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
            } else if let data = data {
                var convertedNSString: NSString?
                NSString.stringEncodingForData(data,
                                               encodingOptions: nil,
                                               convertedString: &convertedNSString,
                                               usedLossyConversion: nil)

                if let html = convertedNSString as? String,
                    let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(doc)
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(nil)
                    }
                }
            }
            }.resume()
    }

    func json(method: HttpMethod,
                      parameters: [String: AnyObject] = [:],
                      headers: [String: String] = [:],
                      completion: (AnyObject?) -> Void) {
        guard let urlRequest = prepareRequest(method,
                                              encoding: .json,
                                              parameters: parameters,
                                              headers: headers) else {
                                                completion(nil)
                                                return
        }

        Http.session.dataTaskWithRequest(urlRequest) { data, response, error in
            Log.info?.message("Fetching \(self.url) complete")

            if let error = error {
                Log.error?.message("request error : \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
                return
            } else if let data = data {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments)
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(json)
                    }
                    return
                } catch let error {
                    Log.error?.message("json parsing : \(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(nil)
                    }
                }
            } else {
                Log.error?.message("\(error), \(data), \(response)")
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
            }
            }.resume()
    }

    func upload(method: HttpMethod,
                headers: [String: String] = [:],
                data: NSData) {
        guard let urlRequest = prepareRequest(method,
                                              encoding: .multipart,
                                              parameters: [:],
                                              headers: headers) else {
                                                return
        }

        Http.session.uploadTaskWithRequest(urlRequest,
                                           fromData: data) { data, response, error in
                                            if let error = error {
                                                Log.error?.message("request error : \(error)")
                                            } else if let data = data {
                                                Log.verbose?.message("\(data)")
                                            } else {
                                                Log.error?.message("\(error), \(data), \(response)")
                                            }
        }.resume()
    }

    private func prepareRequest(method: HttpMethod,
                                encoding: HttpEncoding,
                                parameters: [String: AnyObject] = [:],
                                headers: [String: String] = [:]) -> NSURLRequest? {
        var urlQuery = ""
        if method == .get {
            urlQuery = "?" + query(parameters)
        }

        guard let url = NSURL(string: url + urlQuery) else { return nil }
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue.uppercaseString

        if encoding == .json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            if method != .get {
                do {
                    let bodyData = try NSJSONSerialization.dataWithJSONObject(parameters,
                                                              options: .PrettyPrinted)
                    request.HTTPBody = bodyData
                } catch let error {
                    Log.error?.message("json converting : \(error)")
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
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sort(<) {
            let value = parameters[key]!
            components += queryComponents(key, value)
        }

        return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }

    private func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    private func escape(string: String) -> String {
        // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let generalDelimitersToEncode = ":#[]@"

        let subDelimitersToEncode = "!$&'()*+,;="

        if let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet()
            .mutableCopy() as? NSMutableCharacterSet {
            allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode
                + subDelimitersToEncode)
            return string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet)
                ?? string
        }
        return string
    }

    private static let session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHTTPHeaders
        return NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        }()

    private static let defaultHTTPHeaders: [String: String] = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = NSLocale.preferredLanguages().prefix(6).enumerate().map {
            index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
            }.joinWithSeparator(", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        let userAgent: String = {
            if let info = NSBundle.mainBundle().infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

                let osNameVersion: String = {
                    let version = NSProcessInfo.processInfo().operatingSystemVersion
                    let versionString = "\(version.majorVersion)"
                        + ".\(version.minorVersion)"
                        + ".\(version.patchVersion)"

                    return "macOS \(versionString)"
                }()

                return "\(executable)/\(appVersion) (build:\(appBuild); \(osNameVersion))"
            }

            return "HSTracker"
        }()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent
        ]
    }()
}
