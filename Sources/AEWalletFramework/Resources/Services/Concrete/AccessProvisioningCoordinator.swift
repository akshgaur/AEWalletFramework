//
//  AccessProvisioningService.swift
//  aria-mobile
//
//  Created by Kyle Wiltshire on 4/7/22.
//

import Foundation
import PassKit
import SwiftUI

class AccessProvisioningCoordinator: NSObject, ProvisioningManager {
    private var provisioningAPI: ProvisioningAPI
    private var presentingViewController: PresentingViewController
    
    private var passConfig: PKAddShareablePassConfiguration?
//    private var provisioningContext: ProvisioningContext?
    private var provisioningHelper: ProvisioningHelper
    
    
    var canAddSecureElementPass: Bool {
        return PKAddPassesViewController.canAddPasses()
    }
    
    init(presentingVC: PresentingViewController) {
        self.provisioningAPI          = AccessProvisioningAPI()
        self.provisioningHelper = ProvisioningHelper()
        self.presentingViewController = presentingVC
    }
    
    func addToWallet(_ context: ProvisioningContext) {
        provisioningHelper.provisioningContext = context
        
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
            
            self.initiateWalletProvisioning(with: credential)
        }
    }

}

extension AccessProvisioningCoordinator {
    
    private func initiateWalletProvisioning(with provisioningResponse: ProvisioningCredential) {
        
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
        let passThumbnail = getPassThumbnailImage(for: provisioningHelper.provisioningContext!)
        
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
            passMetadata.serverEnvironmentIdentifier = envId;
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
            
            guard let vc = self.createSEViewController(for: config) else { return }
            
            self.presentingViewController.present(vc, animated: true)
        }
    }
    
    private func createSEViewController(for passConfig: PKAddShareablePassConfiguration) -> PKAddSecureElementPassViewController? {
        let canAddSePass = provisioningHelper.canAddSePass(for: passConfig)
        guard canAddSePass else {
            print("intiateWalletProvisioning:: Unable to add an SE Pass with specified configuration")
            return nil
        }
        
        guard let vc = PKAddSecureElementPassViewController(configuration: passConfig, delegate: self) else {
            print("intiateWalletProvisioning:: Unable to create an SE Pass VC with specified configuration")
            return nil
        }
        
        return vc
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
    
    private func getPassThumbnailImage(for context: ProvisioningContext) -> UIImage {
        // Unsafely unwrapping because there should always be default card art assets
        return UIImage(named: "hospitality" + "_card_art")!
    }

}

extension AccessProvisioningCoordinator: PKAddSecureElementPassViewControllerDelegate {
    func addSecureElementPassViewController(_ controller: PKAddSecureElementPassViewController, didFinishAddingSecureElementPasses passes: [PKSecureElementPass]?, error: (any Error)?) {
        // TODO: Handle specific error cases
        print("AEWAlletFramework :: compeleted provisioning")
        
        if let error = error as? PKAddSecureElementPassError {
            print(error.localizedDescription)
        }
        
        passConfig          = nil
        provisioningHelper.provisioningContext = nil
        
        presentingViewController.dismiss(animated: true)
    }
}
