/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import KituraNet

import Foundation
import XCTest

@testable import KituraSession

let sessionTestKey = "sessionKey"
let sessionTestValue = "sessionValue"
let cookie1Name = "cookie1Name"
let cookieDefaultName = "kitura-session-id"

class TestSession: XCTestCase, KituraTest {

    static var allTests: [(String, (TestSession) -> () throws -> Void)] {
        return [
                   ("testCookieParams1", testCookieParams1),
                   ("testCookieParams2", testCookieParams2),
                   ("testSimpleSession", testSimpleSession),
                   ("testCookieName", testCookieName),
                   ("testCookieValue", testCookieValue),
        ]
    }

    func testCookieParams1() {
        let router = setupAdvancedSessionRouter()
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "get", path: "/1/session", callback: {response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                XCTAssertEqual(response.statusCode, HTTPStatusCode.noContent, "Session route did not match single path request")
                let (cookie1, cookie1Expire) = CookieUtils.cookieFrom(response: response, named: cookie1Name)
                guard let cookie = cookie1 else {
                    return XCTFail("Cookie \(cookie1Name) wasn't found in the response.")
                }
                XCTAssertEqual(cookie.path, "/1", "Path of Cookie \(cookie1Name) is not /1, was \(cookie.path)")
                XCTAssertNotNil(cookie1Expire, "\(cookie1Name) had no expiration date. It should have had one")
            })
        })
    }

    func setupAdvancedSessionRouter() -> Router {
        let router = Router()

        router.all(middleware: Session(secret: "Very very secret.....", cookie: [.name(cookie1Name), .path("/1"), .maxAge(2)]))

        router.get("/1/session") {request, response, next in
            request.session?[sessionTestKey] = sessionTestValue
            response.status(.noContent)

            next()
        }

        return router
    }

    func testCookieParams2() {
        let router = setupBasicSessionRouter()
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "get", path: "/2/session", callback: {response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                XCTAssertEqual(response.statusCode, HTTPStatusCode.noContent, "Session route did not match single path request")
                let (cookie2, cookie2Expire) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookie = cookie2 else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                XCTAssertNotNil(cookie.path, "ERROR!!! cookie2!.path is nil")
                XCTAssertEqual(cookie.path, "/", "Path of Cookie \(cookieDefaultName) is not /, was \(cookie.path)")
                XCTAssertNil(cookie2Expire, "\(cookieDefaultName) has expiration date. It shouldn't have had one")
            })
        })
    }

    func testSimpleSession() {
        let router = setupBasicSessionRouter()
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/3/session", callback: {response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                let (cookie3, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookie3value = cookie3?.value else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                self.performRequest(method: "get", path: "/3/session", callback: {response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString() else {
                            XCTFail("No response body")
                            return
                        }
                        XCTAssertEqual(body, sessionTestValue, "Body \(body) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookie3value); Zxcv=tyuiop"])
           })
        })
    }
    
    func testCookieName() {
        let router = setupBasicSessionRouter()
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/3/session", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return
                }
                let (cookie3, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie3, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard (cookie3 != nil) else {
                    return
                }
                let cookie3value = cookie3!.value
                self.performRequest(method: "get", path: "/3/session", callback: {response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.noContent, "Session route did not match single path request")
                    }, headers: ["Cookie": "\(cookie1Name)=\(cookie3value); Zxcv=tyuiop"])
            })
        })
    }


    func testCookieValue() {
        let router = setupBasicSessionRouter()
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/3/session", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return
                }
                let (cookie3, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie3, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard (cookie3 != nil) else {
                    return
                }
                self.performRequest(method: "get", path: "/3/session", callback: {response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.noContent, "Session route did not match single path request")
                    }, headers: ["Cookie": "\(cookieDefaultName)=lalala; Zxcv=tyuiop"])
            })
        })
    }

    func setupBasicSessionRouter() -> Router {
        let router = Router()

        router.all(middleware: Session(secret: "Very very secret....."))

        router.get("/2/session") {request, response, next in
            request.session?[sessionTestKey] = sessionTestValue
            response.status(.noContent)

            next()
        }

        router.post("/3/session") {request, response, next in
            request.session?[sessionTestKey] = sessionTestValue
            response.status(.noContent)
            next()
        }

        router.get("/3/session") {request, response, next in
            response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
            do {
                if let value = request.session?[sessionTestKey] as? String {
                    try response.status(.OK).send("\(value)").end()
                } else {
                    response.status(.noContent)
                }
            } catch {}
            next()

        }
        return router
    }
}
