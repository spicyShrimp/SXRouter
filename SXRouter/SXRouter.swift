//
//  SXRouter.swift
//  SXRouter
//
//  Created by charles on 2019/5/10.
//  Copyright © 2019 香辣虾. All rights reserved.
//

import UIKit

class SXRouter {
    
    private static let shared = SXRouter()
    
    private var routes:[String:Any] = [:]
    
    private var appUrlSchemes: [String] {
        var urlSchemes:[String] = []
        
        guard let infoDictionary = Bundle.main.infoDictionary
            , let types = infoDictionary["CFBundleURLTypes"] as? [Any] else {
                return urlSchemes
        }
        
        for type in types {
            guard let schemes = type as? [String: Any] else {
                return urlSchemes
            }
            let schemeArr = schemes["CFBundleURLSchemes"] as? [String]
            if let scheme = schemeArr?.first! {
                urlSchemes.append(scheme)
            }
        }
        return urlSchemes
    }
    
    private func pathComponents(from route: String) -> [String] {
        var components:[String] = []
        guard let route = route.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            , let url = URL(string: route) else { return components }
        for component in url.pathComponents {
            guard let component = component.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            if component == "/" { continue }
            if component.first == "?" { break }
            components.append(component)
        }
        return components
    }
    
    private func filterAppUrlScheme(_ string: String) -> String {
        // filter out the app URL compontents.
        for urlScheme in appUrlSchemes {
            if string.hasPrefix("\(urlScheme):") {
                let index = string.index(string.startIndex, offsetBy: (urlScheme.count + 2))
                return String(string[index..<string.endIndex])
            }
        }
        return string
    }
    
    private func params(in route: String) -> [String: Any] {
        var params:[String:Any] = [:]
        let fiterRoute = filterAppUrlScheme(route)
        params["route"] = fiterRoute
        
        var subRoutes:[String:Any] = routes
        let components = pathComponents(from: fiterRoute)
        var found = false
        for component in components {
            let subRoutesKeys = subRoutes.keys
            for key in subRoutesKeys {
                if subRoutesKeys.contains(component) {
                    found = true
                    subRoutes = subRoutes[component] as! [String : Any]
                    break
                } else if key.hasPrefix(":") {
                    found = true
                    subRoutes = subRoutes[key] as! [String : Any]
                    let index = key.index(key.startIndex, offsetBy: 1)
                    let tempKey = String(key[index..<key.endIndex])
                    params[tempKey] = component
                    break
                }
            }
            if found == false {
                return params
            }
        }
        
        // Extract Params From Query.
        if let index = route.firstIndex(of: "?") {
            let start = route.index(index, offsetBy: 1)
            let paramsString = route[start...]
            let paramsStringArr = paramsString.components(separatedBy: "&")
            for tempParam in paramsStringArr {
                let paramArr = tempParam.components(separatedBy: "=")
                if paramArr.count > 1 {
                    let key = paramArr[0], value = paramArr[1]
                    params[key] = value
                }
            }
        }
        
        guard let cla = subRoutes["_"] else {
            return params
        }
        
        if cla is UIViewController.Type {
            params["controller_class"] = subRoutes["_"]
        }
        
        return params
    }
    
    class func map(route: String, vcClass: UIViewController.Type) {
        let components = SXRouter.shared.pathComponents(from: route)
        var reversedRoute:[String:Any] = ["_": vcClass]
        for (index, component) in components.enumerated().reversed() {
            let temp = reversedRoute
            reversedRoute = [:]
            if index == 0 {
                SXRouter.shared.routes[component] = temp
            } else {
                reversedRoute[component] = temp
            }
        }
    }
    
    class func match(route: String) -> UIViewController? {
        let params = SXRouter.shared.params(in: route)
        guard let ViewControllerClass = params["controller_class"] as? UIViewController.Type else {
            return nil
        }
        let vc = ViewControllerClass.init()
        vc.params = params
        return vc
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var params: Void?
    }
    
    var params: Dictionary<String, Any> {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.params) as? [String: Any] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.params, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
