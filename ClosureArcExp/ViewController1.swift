//
//  ViewController.swift
//  ClosureArcExp
//
//  Created by iamchiwon on 2018. 8. 13..
//  Copyright © 2018년 iamchiwon. All rights reserved.
//

import UIKit

class ViewController1: UIViewController {
    
    //0: push
    //1: navigationController가 인스턴스를 갖고 있으므로 (ref +1)
    //2: onBack 에서 클로져가 self를 갖고 있으므로 (ref +1)
    //1: popViewController에 의해서 (ref -1)
    //0: 클로져가 끝나면서 self를 놓아서 (ref -1)
    //0: deinit 됨

    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(barButtonSystemItem: .rewind,
                                         target: self,
                                         action: #selector(onBack))
        navigationItem.setLeftBarButton(backButton, animated: true)
        
        print("ViewController1 - viewDidLoad (+1)")
    }

    @objc func onBack() {
        print("ViewController1 - onBack (+1)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.view.backgroundColor = UIColor.red
            print("ViewController1 - after 5 secs. (-1)")
        })

        navigationController?.popViewController(animated: true)
    }

    deinit {
        print("ViewController1 - deinit (-1)")
    }
}

