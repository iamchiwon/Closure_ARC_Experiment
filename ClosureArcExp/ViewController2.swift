//
//  ViewController2.swift
//  ClosureArcExp
//
//  Created by iamchiwon on 2018. 8. 13..
//  Copyright © 2018년 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController2: UIViewController {

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var tapButton: UIButton!

    var count: Int = 0
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ViewController2 - viewDidLoad (+1)")

        print("ViewController2 - do(onNext) (+1)")
        print("ViewController2 - subscribe(onNext) (+1)")
        tapButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.count += 1
            })
            .subscribe(onNext: { _ in
                self.countLabel.text = "\(self.count)"
            })
            .disposed(by: disposeBag)
        
        let backButton = UIBarButtonItem(barButtonSystemItem: .rewind,
                                         target: self,
                                         action: #selector(onBack))
        navigationItem.setLeftBarButton(backButton, animated: true)
    }
    
    @objc func onBack() {
        print("ViewController2 - onBack")
        navigationController?.popViewController(animated: true)
    }
    
    deinit {
        print("ViewController2 - deinit (-1)")
    }
}
