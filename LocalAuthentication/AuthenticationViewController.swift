//
//  ViewController.swift
//  LocalAuthentication
//
//  Created by Farley Caesar on 2017-09-12.
//  Copyright © 2017 AppObject. All rights reserved.
//

import UIKit
import LocalAuthentication

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var authenticationButton: UIButton!
    
    @IBOutlet weak var authenticationStatus: UILabel!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    
    @IBOutlet var authenticationUIElements: [UIView]!
    
    enum AuthenticationRenderState {
        case initial
        case strongestAvaiableMethod
        case userIDPassword
        case successfullyAuthenticated
        case authenticationFailed(withError: Error, andCompletion: ((Bool) -> Void)?)
    }
    
    enum AuthenticationError: Error, CustomStringConvertible {
        case unknownError
        
        var description: String { return "" }
    }

    let validPassword = "password"
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        doRender(state: .initial)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        doRender(state: .strongestAvaiableMethod)
    }
    
    @IBAction func authenticationButtonPressed(_ sender: Any) {
        guard let enteredPassword = passwordTextField.text else { return }
        
        passwordTextField.resignFirstResponder()
        usernameTextField.text = ""
        passwordTextField.text = ""
        
        if enteredPassword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == validPassword {
            doRender(state: .successfullyAuthenticated)
        }
        else {
            doRender(state: .authenticationFailed(withError: AuthenticationError.unknownError, andCompletion: nil))
        }
    }
    
    @IBAction func tryAgainButtonPressed(_ sender: Any) {
        doRender(state: .strongestAvaiableMethod)
    }
    

    private func handleBiometricsAuthenticationResult(for authVC: AuthenticationViewController,
                                                      successIndicator isSuccess: Bool,
                                                      withError evaluationError: Error?) {
        
        if isSuccess {
            doRender(state: .successfullyAuthenticated)
        } else {
            doRender(state: .authenticationFailed(withError: evaluationError ?? AuthenticationError.unknownError,
                andCompletion: nil))
        }
    }
    
    
    private func doRender(state: AuthenticationRenderState) {
        
        let renderActivites: () -> Void = { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationUIElements.forEach {
                $0.isHidden = true
            }
            
            switch state {
                
            case .initial:
                return
                
            case .strongestAvaiableMethod:
                strongSelf.doRenderStrongestAvaiableMethodState()
                
            case .userIDPassword:
                strongSelf.doRenderUserIDPasswordState()
                
            case .successfullyAuthenticated:
                strongSelf.doRenderSuccessfullyAuthenticatedState()
                
            case .authenticationFailed(let error, let completion):
                strongSelf.doRenderAuthenticationFailedState(with: error, andCompletion: completion)
            }
        }
        
        if Thread.isMainThread {
            renderActivites()
        } else {
            DispatchQueue.main.async {
                renderActivites()
            }
        }
    }
    
    
    func doRenderStrongestAvaiableMethodState() {
        let myContext = LAContext()
        let myLocalizedReasonString = "Authenticate to login to your account."
        
        var authError: NSError?
        
        if #available(iOS 8.0, *) {
            if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: myLocalizedReasonString) {
                    [weak self] (isSuccess,error) -> Void in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.handleBiometricsAuthenticationResult(for: strongSelf,successIndicator: isSuccess,withError: error)
                }
            } else {
                // Could not evaluate policy; look at authError and present an appropriate message to user
                doRender(state: .authenticationFailed(withError: authError ?? AuthenticationError.unknownError,
                                        andCompletion: nil))
            }
        } else {
            // Fallback on UID/PWD
            doRender(state: .userIDPassword)
        }
    }

    
    func doRenderUserIDPasswordState() {
        doAnimate({
            [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.doMakeVisibileUIDPasswordAuthenticationElements()
        })
    }
    
    func doRenderSuccessfullyAuthenticatedState() {
        let animations = { [weak self] () -> Void in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationStatus.textColor = UIColor.green
            strongSelf.authenticationStatus.text = "Successfully Authenticated!"
            strongSelf.authenticationStatus.isHidden = false
        }
        
        let completion: (Bool) -> Void = { [weak self] (Bool) -> Void in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationStatus.isHidden = true
            
            strongSelf.performSegue(withIdentifier: "AuthToMain", sender: self)
        }
        
        doAnimate(animations, withCompletion: completion)
    }
    
    func doRenderAuthenticationFailedState(with error: Error, andCompletion completion: ((Bool) -> Void)?) {
        print(error)
        
        let errorMessage = (error as NSError).prettifiedDescription

        let errorDomain = (error as NSError).domain

        authenticationStatus.textColor = UIColor.red
        authenticationStatus.text = "Authentication Failure!\n\(errorMessage)"
        authenticationStatus.isHidden = false

        guard errorDomain != "com.apple.LocalAuthentication" else {
            
            let noIdentitiesEnrolledLocalAuthenticationError = -7
            if (error as NSError).code == noIdentitiesEnrolledLocalAuthenticationError {
                authenticationStatus.text = "To use biometric authentication with this app, please enroll an identity in your device settings."
            }
            
            doFadeOut(view: authenticationStatus, withCompletion: {[weak self] _ in
                self?.doRender(state: .userIDPassword)
            })
            return
        }
        
        let defaultCompletion: (Bool) -> Void = { [weak self] (Bool) -> Void in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationStatus.isHidden = true
            strongSelf.tryAgainButton.isHidden = false
        }
        
        doFadeOut(view: authenticationStatus, withCompletion: completion ?? defaultCompletion)
    }
    
    private func doMakeVisibileUIDPasswordAuthenticationElements() {
        usernameTextField.isHidden = false
        passwordTextField.isHidden = false
        authenticationButton.isHidden = false
    }
    
    private func doAnimate(_ animations: @escaping () -> Void, withCompletion completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: animations, completion: completion)
    }

    private func doFadeOut(view uiview: UIView, withCompletion completion: ((Bool) -> Void)?) {
        uiview.alpha = 1.0
        
        UIView.animate(withDuration: 1.0, delay: 4.0, options: .curveEaseOut, animations: {
            uiview.alpha = 0.0
        }, completion: {bool in
            uiview.isHidden = true
            uiview.alpha = 1.0
            completion?(bool)
        })
    }
}

extension NSError {
    var prettifiedDescription: String {
        guard !self.domain.starts(with: "LocalAuthenticationDemo.AuthenticationViewController") else {
            return ""
        }
        
        return "Error Domain: \(self.domain)\nError Code: \(self.code) \(self.userInfo[NSLocalizedDescriptionKey] ?? String())"
    }
}




