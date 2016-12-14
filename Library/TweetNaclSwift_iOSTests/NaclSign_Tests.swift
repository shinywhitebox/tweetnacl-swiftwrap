//
//  NaclSign_Tests.swift
//  NaclSign_Tests
//
//  Created by Anh Nguyen on 12/12/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import XCTest
import TweetNaclSwift_iOS
@testable import TweetNaclSwift_iOS

class NaclSign_Test: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testKeyPair() {
        do {
            let keypair = try NaclSign.KeyPair.keyPair()
            XCTAssertEqual(keypair.publicKey.length, crypto_sign_PUBLICKEYBYTES)
            XCTAssertEqual(keypair.secretKey.length, crypto_sign_SECRETKEYBYTES)
            XCTAssertNotEqual(keypair.secretKey.length, keypair.publicKey.length)
            XCTAssertNotEqual(NaclUtil.encodeBase64(data: keypair.secretKey), NaclUtil.encodeBase64(data: keypair.publicKey))
        }
        catch {
            XCTFail()
        }

    }
    
    func testKeyPairFromSecret() {
        do {
            let k1 = try NaclSign.KeyPair.keyPair()
            let k2 = try NaclSign.KeyPair.keyPair(fromSecretKey: k1.secretKey)
            XCTAssertEqual(NaclUtil.encodeBase64(data: k1.secretKey), NaclUtil.encodeBase64(data: k2.secretKey))
            XCTAssertEqual(NaclUtil.encodeBase64(data: k1.publicKey), NaclUtil.encodeBase64(data: k2.publicKey))
        }
        catch {
            XCTFail()
        }
    }
    
    func testSignOpen() {
        do {
            let keypair = try NaclSign.KeyPair.keyPair()
            
            let bytes = [UInt32](repeating: 0, count: 100).map { _ in 0xff }
            let data = Data(bytes: bytes, count: 100)
            let message = NSData(data: data)
            
            let signedMessage = try NaclSign.sign(message: message, secretKey: keypair.secretKey)
            XCTAssertNotNil(signedMessage, "Message must be signed")
            
            let openedMessage = try NaclSign.signOpen(signedMessage: signedMessage, publicKey: keypair.publicKey)
            XCTAssertNotNil(openedMessage, "Signed Message must be opened")
        }
        catch {
            XCTFail()
        }
    }
    
//    func testSignFromSeed() {
//        do {
//            let seed = try NaclUtil.randomBytes(crypto_sign_SEEDBYTES)
//            let k1 = try NaclSign.KeyPair.keyPair(fromSeed: seed)
//            let k2 = try NaclSign.KeyPair.keyPair(fromSeed: seed)
//            
//            XCTAssertEqual(k1.secretKey.length, crypto_box_SECRETKEYBYTES)
//            XCTAssertEqual(k1.publicKey.length, crypto_box_PUBLICKEYBYTES)
//            XCTAssertEqual(k2.secretKey.length, crypto_box_SECRETKEYBYTES)
//            XCTAssertEqual(k2.publicKey.length, crypto_box_PUBLICKEYBYTES)
//            XCTAssertEqual(NaclUtil.encodeBase64(data: k1.secretKey), NaclUtil.encodeBase64(data: k2.secretKey))
//            XCTAssertEqual(NaclUtil.encodeBase64(data: k1.publicKey), NaclUtil.encodeBase64(data: k2.publicKey))
//        }
//        catch {
//            XCTFail()
//        }
//    }
    
    func testDetachedAndVerify() {
        do {
            let k = try NaclSign.KeyPair.keyPair()
            var bytes = [UInt32](repeating: 0, count: 100)
            for index in 0..<bytes.count {
                bytes[index] = UInt32(index) & 0xff
            }
            let data = Data(bytes: bytes, count: 100)
            let message = NSData(data: data)
            
            let sig = try NaclSign.signDetached(message: message, secretKey: k.secretKey)
            XCTAssertEqual(sig.length, crypto_sign_BYTES)
            
            let result = try NaclSign.signDetachedVerify(message: message, sig: sig, publicKey: k.publicKey)
            XCTAssertNotNil(result, "signature must be verified")
            
            XCTAssertThrowsError(try NaclSign.signDetachedVerify(message: message, sig: sig, publicKey: k.publicKey.subdata(with: NSMakeRange(0, 1)) as NSData))
            XCTAssertThrowsError(try NaclSign.signDetachedVerify(message: message, sig: sig.subdata(with: NSMakeRange(0, 1)) as NSData, publicKey: k.publicKey))
            
            let badPublicKey = try NaclUtil.randomBytes(k.publicKey.length)
            XCTAssertEqual(try NaclSign.signDetachedVerify(message: message, sig: sig, publicKey: badPublicKey), false)
            
            let badSigKey = try NaclUtil.randomBytes(sig.length)
            XCTAssertEqual(try NaclSign.signDetachedVerify(message: message, sig: badSigKey, publicKey: k.publicKey), false)
        }
        catch {
            XCTFail()
        }
    }
}
