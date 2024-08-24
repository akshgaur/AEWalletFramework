// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import PassKit

public struct AEWalletFramework{
    
    @State var provisioningCoordinator: AccessProvisioningCoordinator?
    @State var provisioningContext: ProvisioningContext?
    var watchDetector: AppleWatchDetector
    
    
    public init(prasentingVC: PresentingViewController?, identityId: String?, identityMobileCredentialId: String?, accessToken:String?, accessTokenExpiration:Double?) {
        watchDetector = AppleWatchDetector()
        
        let settingsManager = SettingsManager.shared()
        
        if let accessToken {
            settingsManager.setAccessToken(authToken: accessToken)
        }
        
        settingsManager.setServerURL(serverURL: "nfcqalocal.alertenterprise.com")
//        settingsManager.setServerPort(serverPort: String(serverConfig!.port))
        
        if let accessTokenExpiration {
            settingsManager.setAccessTokenExpiration(accessTokenExpiration: accessTokenExpiration)
        }
        
        if let prasentingVC {
            provisioningCoordinator = AccessProvisioningCoordinator(presentingVC: prasentingVC)
        }
        if let userId = identityId, let mobileCredentialId = identityMobileCredentialId {
            let context = ProvisioningContext(identityId: userId, identityMobileCredentialId: mobileCredentialId,passDefinitionIdentifier: nil)
            provisioningContext = context
        }
        
    }
    
//    func setInit(){
//        let settingsManager = SettingsManager.shared()
//        settingsManager.setAccessToken(authToken: accessToken)
//        settingsManager.setServerURL(serverURL: "nfcqalocal.alertenterprise.com")
////        settingsManager.setServerPort(serverPort: String(serverConfig!.port))
//        settingsManager.setAccessTokenExpiration(accessTokenExpiration: accessTokenExpiration)
//        provisioningCoordinator = AccessProvisioningCoordinator(presentingVC: prasentingVC)
//        let context = ProvisioningContext(identityId: identityId, identityMobileCredentialId: identityMobileCredentialId,passDefinitionIdentifier: nil)
//        provisioningContext = context
//    }
    
    public func addToWallet(prasentingVC: PresentingViewController, identityId: String, identityMobileCredentialId: String, accessToken:String, accessTokenExpiration:Double){
//        setInit(prasentingVC: prasentingVC, identityId: identityId, identityMobileCredentialId: identityMobileCredentialId, accessToken: accessToken, accessTokenExpiration: accessTokenExpiration)
        print("Started AE provisionning")
        provisioningCoordinator!.addToWallet(provisioningContext!)
    }
    
    public func canAddPass(prasentingVC: PresentingViewController, identityId: String, identityMobileCredentialId: String, accessToken:String, accessTokenExpiration:Double, completion:@escaping (Result<Bool,Error>)->Void) {
//        setInit(prasentingVC: prasentingVC, identityId: identityId, identityMobileCredentialId: identityMobileCredentialId, accessToken: accessToken, accessTokenExpiration: accessTokenExpiration)
        let provisionnningHelper = ProvisioningHelper()
        provisionnningHelper.canAddPass(provisioningContext!) { result in
            switch result {
            case .success(let canAdd):
                completion(.success(canAdd))
            case .failure(let failure):
                completion(.failure(failure))
                print("failure")
            }
        }
    }
    
    public func listRemoteSecureElementPasses() -> [PKPass]{
        let provisionnningHelper = ProvisioningHelper()
        let remotePasses = provisionnningHelper.getRemoteSecureElementPasses();
        return remotePasses
    }
    
    public func listDeviceSecureElementPasses() -> [PKPass]{
        let provisionnningHelper = ProvisioningHelper()
        let devicePasses = provisionnningHelper.getSecureElementPasses(of: .secureElement)
        return devicePasses
    }
    
    public func isWatchPaired() -> Bool{
        watchDetector.detect()
        return watchDetector.watchPaired
    }
    
    public func startProvisioning(completion:@escaping (Result<ProvisioningCredential,Error>)->Void){
        let provisioningHelper = ProvisioningHelper()
        provisioningHelper.startPassProvisioning(provisioningContext!) { reult in
            switch reult {
            case .success(let credential):
                completion(.success(credential))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    public func getPass(provisioningCredentialIdentifier: String)-> PKPass?{
        let provisioningHelper = ProvisioningHelper()
        return provisioningHelper.getPass(provisioningCredentialIdentifier: provisioningCredentialIdentifier)
    }
    
}
