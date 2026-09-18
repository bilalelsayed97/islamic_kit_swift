import XCTest
import IslamicKitPlus

final class JSONValueTests: XCTestCase {
    func testObjectsKeepInsertionOrder() {
        var object: JSONObject = ["b": 1, "a": 2]
        object["c"] = 3
        object["b"] = 4 // replaced in place
        XCTAssertEqual(object.keys, ["b", "a", "c"])
        XCTAssertEqual(object.serialized(), "{\"b\":4,\"a\":2,\"c\":3}")
        object["a"] = nil
        XCTAssertEqual(object.keys, ["b", "c"])
        XCTAssertEqual(object["a"], nil)
        XCTAssertNotEqual(JSONObject(dictionaryLiteral: ("a", 1), ("b", 2)), ["b": 2, "a": 1])
    }

    func testNumbersEncodeLikeDart() {
        XCTAssertEqual(JSONValue.int(18).serialized(), "18")
        XCTAssertEqual(JSONValue.double(18).serialized(), "18.0")
        XCTAssertEqual(JSONValue.double(18.5).serialized(), "18.5")
        XCTAssertEqual(JSONValue.double(-0.1254872).serialized(), "-0.1254872")
        XCTAssertEqual(JSONValue.double(39.70421229999999).serialized(), "39.70421229999999")
    }

    func testStringEscaping() {
        XCTAssertEqual(JSONValue.string("a\"b\\c\n\t\u{01}/é").serialized(), "\"a\\\"b\\\\c\\n\\t\\u0001/é\"")
        XCTAssertEqual(JSONValue.string("الجمعة").serialized(), "\"الجمعة\"")
    }

    func testScalarsArraysAndNested() {
        let value: JSONValue = ["s": "x", "n": .null, "t": true, "list": [1, 2.5, "z", []], "empty": [:]]
        XCTAssertEqual(value.serialized(), "{\"s\":\"x\",\"n\":null,\"t\":true,\"list\":[1,2.5,\"z\",[]],\"empty\":{}}")
        XCTAssertEqual(value["list"]?[1], 2.5)
        XCTAssertEqual(value["list"]?[7], nil)
        XCTAssertEqual(value["s"]?.string, "x")
        XCTAssertEqual(value["t"]?.bool, true)
        XCTAssertEqual(value["list"]?[0]?.double, 1.0)
    }

    func testIndentedLayoutMatchesDartWithIndent() {
        let value: JSONValue = ["a": [1, [:]], "b": []]
        XCTAssertEqual(value.serialized(indent: "  "), "{\n  \"a\": [\n    1,\n    {}\n  ],\n  \"b\": []\n}")
    }
}
