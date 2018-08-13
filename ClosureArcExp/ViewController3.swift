//
//  ViewController3.swift
//  ClosureArcExp
//
//  Created by iamchiwon on 2018. 8. 13..
//  Copyright © 2018년 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewModel: Disposable {

    var disposeBag = DisposeBag()
    let count = BehaviorRelay<Int>(value: 0)

    func dispose() {
        disposeBag = DisposeBag()
    }

    func addCount() {
        let current = count.value
        Observable.just(current)
            .map({ $0 + 1 })
            .subscribe(onNext: { newValue in
                self.count.accept(newValue)
            })
            .disposed(by: disposeBag)
    }

}

class ViewController3: UIViewController {

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var tapButton: UIButton!

    var disposeBag = DisposeBag()
    var viewModel: ViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ViewController3 - viewDidLoad (+1)")

        viewModel = ViewModel()
        disposeBag.insert(viewModel)

        tapButton.rx.tap.asObservable()
            .subscribe(onNext: { _ in
                self.viewModel.addCount()
            })
            .disposed(by: disposeBag)

        viewModel.count
            .map({ "\($0)" })
            .bind(to: countLabel.rx.text)
            .disposed(by: disposeBag)
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        if parent == nil { disposeBag = DisposeBag() }
    }

    deinit {
        print("ViewController3 - deinit (-1)")
    }
}
