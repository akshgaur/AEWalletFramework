//
//  PreparePushProvisioningResponse.swift
//  aria-mobile
//
//  Created by Kyle Wiltshire on 4/7/22.
//

import Foundation
import UIKit

// MARK: - Provisioning Credential Resource
public struct ProvisioningCredentialResource: APIResource {
//    var type: String
    
//    var path: String { return "/partner/v1/prepareProvisioning" }
    var path: String { return "/partner/" + "v1" + "/prepareProvisioning"  }
}

public struct ProvisioningCredentialResourceForPassDefinition: APIResource {
    var passDefintionIdentier: String
    var type: String
    var path: String { return "/api/mobile/" + "\(type)" + "/prepareProvisioning/pass/" + "\(passDefintionIdentier)/"  }
}

public struct PreparePassProvisioningRequest: APIRequest {
    var method: HTTPMethod
    var url: URL
    var body: Data?
}

public struct ProvisionAPIResponse {
    var credential: ProvisioningCredential?
    var error: String?
}

// MARK: - Provisoning Credential
public struct ProvisioningCredential: Codable {
    var provisioningInformation: ProvisioningInformation
}

struct ProvisioningResponse:Codable{
    let success:Bool
    let data : ProvisioningInformation!
    let numberOfElements : Int
    let totalPages : Int
    let totalElements : Int
    let pageNumber : Int
    let pageSize : Int
}

public struct ProvisioningInformation: Codable {
    var provisioningCredentialIdentifier: String
    var sharingInstanceIdentifier: String
    var cardTemplateIdentifier: String
    var environmentIdentifier: String?
    var accountHash: String?
    var relyingPartyIdentifier: String?
}

// MARK: - AppConfigResponse
public struct AppConfigResponse: Codable {
    var cardTemplates: [ProductCardTemplate]
}

public struct ProductCardTemplate: Codable {
    var product: String
    var templates: [CardTemplate]
}

// MARK: - Card Template
public struct CardTemplate: Codable {
    var templateName: String
    var templateIdentifier: String
}

public struct ServerNetworkConfiguration: Codable {
    var userId: Int
    var username: String
    var role: String
    var server: String
    var port: Int
    var accessToken: String
    var accessTokenExpiration: Double
    
    func getServerURL() -> String {
        return "https://" + server + ":" + String(port)
    }
}

// MARK: - Provisioning Context
//TODO: Turn this into a factory
public struct ProvisioningContext: Codable {
    var employeeId: String?
    var propertyId: String?
    var reservationId: String?
    
    var product: String?
    var credentialType: String?
    var cardTemplateIdentifier: String?
    var passDefinitionIdentifier: String?
    
    init(identityId:String?, identityMobileCredentialId: String?, passDefinitionIdentifier: String?) {
        self.employeeId = identityId
        self.propertyId = identityMobileCredentialId
//        self.product = product
//        self.credentialType = credentialType
//        self.cardTemplateIdentifier = cardTemplateIdentifier
        self.passDefinitionIdentifier = passDefinitionIdentifier
    }
    
    func toJSON() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
