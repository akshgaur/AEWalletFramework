//
//  File.swift
//  
//
//  Created by aksh gaur on 13/08/24.
//

import PassKit

class ProvisioningHelper: NSObject {
     
    private var passLibrary:PKPassLibrary?
    var provisioningContext: ProvisioningContext?
    private var provisioningAPI: ProvisioningAPI

    override init() {
        self.provisioningAPI = AccessProvisioningAPI()
    }
    
    func getRemoteSecureElementPasses() -> [PKSecureElementPass] {
        passLibrary = PKPassLibrary()
        return passLibrary!.remoteSecureElementPasses
    }
    
    func passExists(provisioningCredentialIdentifier: String) -> Bool {
        var exists = false
        
        let passes = getSecureElementPasses(of: .secureElement)
        
        if passes.isEmpty { return false }
        
        exists = passes.contains {
            let sePass = $0 as! PKSecureElementPass
            return sePass.primaryAccountIdentifier.dropFirst(7) == provisioningCredentialIdentifier
        }
        
        return exists
    }
    
    func getPass(provisioningCredentialIdentifier: String) -> PKPass? {
        let passes = getSecureElementPasses(of: .secureElement)
        if passExists(provisioningCredentialIdentifier: provisioningCredentialIdentifier) {
            return passes.first{($0.paymentPass?.primaryAccountIdentifier.dropFirst(7))! == provisioningCredentialIdentifier}
        }
        return nil
    }
    
    func getSecureElementPasses(of passType: PKPassType) -> [PKPass] {
        if !PKPassLibrary.isPassLibraryAvailable() { return [] }
        
        let passesOfType = PKPassLibrary().passes(of: passType)
        
        if passesOfType.isEmpty { return [] }
        
        return passesOfType
    }
    
    func canAddPass(_ context: ProvisioningContext,completion:@escaping (Result<Bool,Error>)->Void){
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
                case .success(let config):
                    let canAddPass = self.canAddSePass(for: config)
                    completion(.success(canAddPass))
                case .failure(let failure):
                    completion(.failure(failure))
                    print("failure")
                }
            }
        }

    }
    
    func canAddSePass(for passConfig: PKAddShareablePassConfiguration) -> Bool
    {
        let canAddSePass = PKAddSecureElementPassViewController.canAddSecureElementPass(configuration: passConfig)
        guard canAddSePass else {
            return false
        }
        return canAddSePass
    }
    
    func initiateWalletProvisioning(with provisioningResponse: ProvisioningCredential, completion:@escaping (Result<PKAddShareablePassConfiguration,Error>)->Void)
    {
        
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
            
            completion(.success(config))
        }
    }
    
    private func getPassThumbnailImage(for context: ProvisioningContext) -> UIImage {
        // Unsafely unwrapping because there should always be default card art assets
        return UIImage(named: "hospitality" + "_card_art")!
    }
    
    
    func startPassProvisioning(_ context: ProvisioningContext, completion:@escaping (Result<ProvisioningCredential,Error>)->Void)  {
        
        provisioningAPI.preparePassProvisioning(context) { apiResponse in
            //            self.presentingViewController.spinnerView.startAnimating()
            
            guard let credential = apiResponse.credential else {
                // TODO: Handle nil credentials
                
                if apiResponse.error != nil {
                    //                    self.presentingViewController.showAlert(title: "Error", message: apiResponse.error != nil ? apiResponse.error! : "Error fetching Credential from Server", actionTitle: "OK")
                    //                    self.presentingViewController.spinnerView.stopAnimating()
                }
                completion(.failure(apiResponse.error as! Error))
                return;
            }
            
            if (self.passExists(provisioningCredentialIdentifier: credential.provisioningInformation.provisioningCredentialIdentifier)) {
                // TODO: Have this class return an error rather than present
                //                self.presentingViewController.showAlert(title: "Error", message: "Pass already provisioned in Wallet", actionTitle: "OK")
                completion(.failure(NSLocalizedString("Error", comment: "Pass already provisioned in Wallet") as! Error))
            }
            
            completion(.success(credential))
        }
    }
}


