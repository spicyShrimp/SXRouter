//
//  ViewController.swift
//  SXRouter
//
//  Created by charles on 2019/5/10.
//  Copyright © 2019 香辣虾. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.blue
        
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        btn.backgroundColor = UIColor.red
        view.addSubview(btn)
        btn.addTarget(self, action: #selector(presents), for: .touchUpInside)
        
        SXRouter.map(route: "user/:id", vcClass: ViewController.self)
        
        SXRouter.map(route: "1111") { (parame) -> Any in
            print(parame)
            return "success"
        }
        
    }
    
    @objc func presents() {
        guard let closure = SXRouter.matchToClosure(route: "1111?abc=123") else { return }
        let result = closure(["1": "2"])
        print(result)
        
        guard let vc = SXRouter.matchToVC(route: "user/123?tab=1&name=香辣虾") else { return }
        print(vc.params)
        present(vc, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true, completion: nil)
    }
}

