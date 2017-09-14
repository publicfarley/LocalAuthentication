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

    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var authenticationButton: UIButton!
    
    @IBOutlet weak var authenticationStatus: UILabel!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    
    let validPassword = "password"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticationStatus.isHidden = true
        tryAgainButton.isHidden = true
        
        doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        doAuthenticateViaStrongesAvailableMethod()
    }
    
    @IBAction func authenticationButtonPressed(_ sender: Any) {
        doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: true)
        
        guard let enteredPassword = passwordTextField.text else { return }
        
        passwordTextField.resignFirstResponder()
        usernameTextField.text = ""
        passwordTextField.text = ""
        
        if enteredPassword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == validPassword {
            doRenderSuccessfulAuthentication()
        }
        else {
            doRenderFailedAuthentication()
        }
    }
    
    @IBAction func tryAgainButtonPressed(_ sender: Any) {
        tryAgainButton.isHidden = true
        doAuthenticateViaStrongesAvailableMethod()
    }
    
    private func doRenderSuccessfulAuthentication() {
        
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
        
        doAnimateAuthenticationResult(animations, completion: completion)
    }

    private func doRenderFailedAuthentication() {

        let animations = { [weak self] () -> Void in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationStatus.textColor = UIColor.red
            strongSelf.authenticationStatus.text = "Authentication Attempt Failed!"
            strongSelf.authenticationStatus.isHidden = false
        }
        
        let completion: (Bool) -> Void = { [weak self] (Bool) -> Void in
            guard let strongSelf = self else { return }
            
            strongSelf.authenticationStatus.isHidden = true
            strongSelf.tryAgainButton.isHidden = false
        }

        
        doAnimateAuthenticationResult(animations, completion: completion)
    }
    
    private func doAnimateAuthenticationResult(_ animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 3.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: animations, completion: completion)
    }

    private func doAuthenticateViaStrongesAvailableMethod() {
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
                doRenderAuthorizationError(error: authError)
            }
        } else {
            // Fallback on UID/PWD
            doAnimateAuthenticationResult({[weak self] in
                guard let strongSelf = self else { return }
                strongSelf.doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: false)
            })
        }
    }
    

    private func handleBiometricsAuthenticationResult(for authVC: AuthenticationViewController,
                                                      successIndicator isSuccess: Bool,
                                                      withError evaluateError: Error?) {
        
        if isSuccess {
            DispatchQueue.main.async { [weak authVC] in
                guard let strongAuthVC = authVC else { return }
                strongAuthVC.doRenderSuccessfulAuthentication()
            }
        } else {
            if (evaluateError as NSError?)?.code == -2 {
                DispatchQueue.main.async { [weak authVC] in
                    authVC?.doAnimateAuthenticationResult({ [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: false)
                    })
                }
            }
            else {
                DispatchQueue.main.async { [weak authVC] in
                    guard let strongAuthVC = authVC else { return }
                    strongAuthVC.doRenderFailedAuthentication()
                }
            }
        }
    }
    
    private func doRenderAuthorizationError(error: NSError?) {
        
        let errorMessage = error == nil ? "Undefinied error" : "\(error!)"
        
        let alertController = UIAlertController(title: "Authentication Error", message: "An authentication error occured: \(errorMessage)", preferredStyle: .alert)

        let OKAction = UIAlertAction(title: "OK", style: .default) {
            [weak self] (action: UIAlertAction!) in
            guard let strongSelf = self else { return }
            
            strongSelf.doAnimateAuthenticationResult({
                [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: false)
            })

        }
        
        alertController.addAction(OKAction)

        self.present(alertController, animated: true, completion:nil)
    }
    
    
    private func doSetVisibilityOfUIDPasswordAuthenticationElements(isHidden: Bool) {
        usernameTextField.isHidden = isHidden
        passwordTextField.isHidden = isHidden
        authenticationButton.isHidden = isHidden
    }
}

