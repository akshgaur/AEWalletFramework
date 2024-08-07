//
//  AccessProvisioningService.swift
//  aria-mobile
//
//  Created by Kyle Wiltshire on 4/7/22.
//

import Foundation
import PassKit
import SwiftUI

public class AccessProvisioningCoordinator: NSObject, ProvisioningManager {
    private var provisioningAPI: ProvisioningAPI
//    private var presentingViewController: AccessViewController
    private var presentingViewController = UIViewController()

//    private var passConfig: PKAddShareablePassConfiguration?
    private var provisioningContext: ProvisioningContext?
    
    var canAddSecureElementPass: Bool {
        return PKAddPassesViewController.canAddPasses()
    }
    
    override init(/*presentingVC: AccessViewController*/) {
        self.provisioningAPI          = AccessProvisioningAPI()
//        self.presentingViewController = presentingVC
    }
    
    func addToWallet(_ context: ProvisioningContext,completion:@escaping (Result<PKAddShareablePassConfiguration,Error>)-> Void) {
        provisioningContext = context
        provisioningAPI.preparePassProvisioning(context) { apiResponse in
//            self.presentingViewController.spinnerView.startAnimating()
            
            guard let credential = apiResponse.credential else {
                // TODO: Handle nil credentials
                
                if apiResponse.error != nil {
//                    self.presentingViewController.showAlert(title: "Error", message: apiResponse.error != nil ? apiResponse.error! : "Error fetching Credential from Server", actionTitle: "OK")
//                    self.presentingViewController.spinnerView.stopAnimating()
                }
                return;
            }
            
            if (self.passExists(provisioningCredentialIdentifier: credential.provisioningInformation.provisioningCredentialIdentifier)) {
                // TODO: Have this class return an error rather than present
//                self.presentingViewController.showAlert(title: "Error", message: "Pass already provisioned in Wallet", actionTitle: "OK")
                return
            }
            
            self.initiateWalletProvisioning(with: credential) { result in
                switch result {
                case .success(let passvc):
                    completion(.success(passvc))
                case .failure(_):
                    completion(.failure("something went wrong" as! Error))
                }
            }
//            passCV = self.initiateWalletProvisioning(with: credential)
            
        }
//        return passvc
    }
    
    private func getPassThumbnailImage(for context: ProvisioningContext) -> UIImage {
        // Unsafely unwrapping because there should always be default card art assets
        return UIImage(named: context.product + "_card_art")!
    }
}

extension AccessProvisioningCoordinator {
    private func initiateWalletProvisioning(with provisioningResponse: ProvisioningCredential, completion:@escaping (Result<PKAddShareablePassConfiguration,Error>)-> Void) {
        
        var provisioningInfo = provisioningResponse.provisioningInformation
        provisioningInfo.environmentIdentifier = "53b70cac-ec0c-4712-b7ba-995ddc119dfd"
        print("intiateWalletProvisioning:: provisioning info - ", provisioningInfo)
        
        let provisioningCredentialIdentifier = provisioningInfo.provisioningCredentialIdentifier
        let cardTemplateIdentifier = provisioningInfo.cardTemplateIdentifier
        let sharingInstanceIdentifier = provisioningInfo.sharingInstanceIdentifier
        let environmentIdentifier = provisioningInfo.environmentIdentifier
        let ownerDisplayName = "Johnny"
        let localizedDescription = "Pass"
        
        // Unsafely unwrapping because there should always be context during provisioning
        let passThumbnail = getPassThumbnailImage(for: provisioningContext!)
        
        let preview = PKShareablePassMetadata.Preview(
            passThumbnail: passThumbnail.cgImage!,
            localizedDescription: localizedDescription)
        
        preview.ownerDisplayName = ownerDisplayName
        
        let passMetadata = PKShareablePassMetadata(
            provisioningCredentialIdentifier: provisioningCredentialIdentifier,
            sharingInstanceIdentifier: sharingInstanceIdentifier,
            cardTemplateIdentifier: cardTemplateIdentifier,
            preview: preview)
                
        if let envId = environmentIdentifier {
          passMetadata.serverEnvironmentIdentifier = envId
        }
        
        if let accountHash = provisioningInfo.accountHash, let relyingPartyIdentifier = provisioningInfo.relyingPartyIdentifier {
            passMetadata.accountHash = accountHash
            passMetadata.relyingPartyIdentifier = relyingPartyIdentifier
        }
        
        print("intiateWalletProvisioning:: Pass metadata - ", passMetadata)

        PKAddShareablePassConfiguration.forPassMetadata([passMetadata], action: .add) { sePassConfig, err in
            guard let config = sePassConfig else {
                print("intiateWalletProvisioning:: error creating pass config - \(String(describing: err))")
                return
            }
            
            completion(.success(config))
//            guard let vc = self.createSEViewController(for: config) else { return }
//
//            completion(.success(vc))
        }
    }

    private func passExists(provisioningCredentialIdentifier: String) -> Bool {
        var exists = false
        
        let passes = getPasses(of: .secureElement)
        
        if passes.isEmpty { return false }
        
        exists = passes.contains {
            let sePass = $0 as! PKSecureElementPass
            return sePass.primaryAccountIdentifier.dropFirst(7) == provisioningCredentialIdentifier
        }
        
        return exists
    }
    
    private func getPasses(of passType: PKPassType) -> [PKPass] {
        if !PKPassLibrary.isPassLibraryAvailable() { return [] }
        
        let passesOfType = PKPassLibrary().passes(of: passType)
        
        if passesOfType.isEmpty { return [] }
        
        return passesOfType
    }
}


//extension AccessProvisioningCoordinator: PKAddSecureElementPassViewControllerDelegate {
//    public func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAddingSecureElementPasses passes: [PKSecureElementPass]?, error: Error?) {
//        // TODO: Handle specific error cases
//        if let error = error as? PKAddSecureElementPassError {
//            print("Add card error::\(error.localizedDescription)")
//        }
//        
////        passConfig          = nil
//        provisioningContext = nil
//        
//        presentingViewController.dismiss(animated: true)
//    }
//}
