//
//  SXRouter.swift
//  SXRouter
//
//  Created by charles on 2019/5/10.
//  Copyright © 2019 香辣虾. All rights reserved.
//

import UIKit

enum SXRouterType {
    case none
    case viewController
    case closure
}

typealias SXRouterClosure = ([String:Any]) -> Any

class SXRouter {
    
    private static let shared = SXRouter()
    
    private var routes:[String:Any] = [:]
    
    private var appUrlSchemes: [String] {
        var urlSchemes:[String] = []
        guard let infoDictionary = Bundle.main.infoDictionary
            , let schemes = infoDictionary["LSApplicationQueriesSchemes"] as? [String] else {
                return urlSchemes
        }
        
        for scheme in schemes {
            urlSchemes.append(scheme)
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
    
    private func filterAppUrlScheme(_ route: String) -> String {
        for urlScheme in appUrlSchemes {
            if route.hasPrefix(urlScheme + ":") {
                let index = route.index(route.startIndex, offsetBy: (urlScheme.count + 2))
                return String(route[index..<route.endIndex])
            }
        }
        return route
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
        
        guard let result = subRoutes["_"] else {
            return params
        }
        
        if result is UIViewController.Type {
            params["controller_class"] = subRoutes["_"]
        } else {
            params["closure"] = subRoutes["_"]
        }
        
        return params
    }
    
    private func map(route: String, value: Any) {
        let components = SXRouter.shared.pathComponents(from: route)
        var reversedRoute:[String:Any] = ["_": value]
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
    
    class func map(route: String, vcClass: UIViewController.Type) {
        SXRouter.shared.map(route: route, value: vcClass)
    }
    
    class func map(route: String, closure: @escaping SXRouterClosure) {
        SXRouter.shared.map(route: route, value: closure)
    }
    
    class func canRoute(_ route: String) -> SXRouterType {
        let params = SXRouter.shared.params(in: route)
        if params["controller_class"] != nil {
            return .viewController
        }
        if params["closure"] != nil {
            return .closure
        }
        return .none
    }
    
    class func matchToVC(route: String) -> UIViewController? {
        let params = SXRouter.shared.params(in: route)
        guard let ViewControllerClass = params["controller_class"] as? UIViewController.Type else {
            return nil
        }
        let vc = ViewControllerClass.init()
        vc.params = params
        return vc
    }
    
    class func matchToClosure(route: String) -> SXRouterClosure? {
        let params = SXRouter.shared.params(in: route)
        guard let closure = params["closure"] as? SXRouterClosure else {
            return nil
        }
        let returnClosure:SXRouterClosure = { aParams -> Any in
            let newParams:[String:Any] = params.merging(aParams){ (_, new) in new }
            return closure(newParams)
        }
        return returnClosure
    }
    
    class func callClosure(_ route: String) -> Any? {
        let params = SXRouter.shared.params(in: route)
        guard let closure = params["closure"] as? SXRouterClosure else {
            return nil
        }
        return closure(params)
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
