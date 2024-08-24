//
//  AccessProvisioningAPI.swift
//  aria-mobile
//
//  Created by Kyle Wiltshire on 4/17/22.
//

import Foundation
import os.log

public class AccessProvisioningAPI: NSObject, ProvisioningAPI {
    private let pinnedPublicKeyHash = Trust.hash
    private let prepareProvisioningUrl = Trust.endpoint
    
    func preparePassProvisioning(_ context: ProvisioningContext, withCompletion completion: @escaping (ProvisionAPIResponse) -> Void) {
        
        var resource: APIResource

//        if(context.passDefinitionIdentifier != nil) {
//            resource = ProvisioningCredentialResourceForPassDefinition(passDefintionIdentier: "\(context.passDefinitionIdentifier!)", type: context.product)
//        } else {
            resource = ProvisioningCredentialResource()
//        }
        
        let payloadData =  ["identityId": context.employeeId, "identityMobileCredentialId": context.propertyId]
        let payload = try? JSONEncoder().encode(payloadData)
        NSLog("URL for preparePassProvisioning: \(resource.url)")
        
        let request  = PreparePassProvisioningRequest(method: .post, url: resource.url, body: payload)//context.toJSON())
        
        
        let session  = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        session.dataTask(with: request.urlRequest) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if(httpResponse.statusCode == 401) {
                    NSLog("Server returned unauthorized error code")
                    completion(ProvisionAPIResponse(error: "Server returned unauthorized error code"))
                    return
                } else if(httpResponse.statusCode != 200) {
                    NSLog("Server non-success code: ", httpResponse.statusCode)
                    completion(ProvisionAPIResponse(error: "Server returned non-success code"))
                    return
                }
            }
            
            if let data = data {
                let decoder = JSONDecoder()
                let bodyString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "Can't render body; not utf8 encoded"
                NSLog(bodyString as String)
                NSLog(error.debugDescription as String)
                let decoded = try? decoder.decode(ProvisioningResponse.self, from: data)
                
                
                if decoded != nil {
                    let credential = ProvisioningCredential(provisioningInformation: decoded!.data)
                    print(credential.provisioningInformation.cardTemplateIdentifier)
                    completion(ProvisionAPIResponse(credential: credential))
                }
            }
            
            completion(ProvisionAPIResponse())
        }.resume()
    }
}

extension AccessProvisioningAPI: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod ==
                NSURLAuthenticationMethodServerTrust,
              protectionSpace.host.contains("kdub.local") else { 
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(serverTrust, DispatchQueue.global()) { trust, result, error in
                // unsafely unwrapping because we own the server
                
                if result {
                    let certs: [SecCertificate] = SecTrustCopyCertificateChain(serverTrust) as! [SecCertificate]
                    let ca = certs.last!
                    let publicKey = SecCertificateCopyKey(ca)!
                    let keyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data
                    
                    let hash = Crypto.sha256(data: keyData)
                    
                    if self.pinnedPublicKeyHash == hash {
                        // Successfully pinned server ca public key, hooray!
                        completionHandler(.useCredential, URLCredential(trust: serverTrust))
                        return
                    }
                    
                }
                
                var trustResult = SecTrustResultType.invalid
                SecTrustGetTrustResult(trust, &trustResult)
                print("Trust failed: \(error)")
                
                // Unsuccessfully pinned server ca public key, booo!
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}
