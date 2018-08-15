# 클로져와 메모리 해제 실험

## 배경

Closure 는 생성되는 시점에 클로져 내에서 접근하는 외부변수의 값을 캡춰해서 갖게 된다. struct같은 value 변수라면 복사되고 그만이겠지만, Object 라면 레퍼런스를 갖게되고, 레퍼런스 카운트가 증가하게 된다. <br/>
클로저 내에서 참조를 갖게되면서 서로를 참조하는 경우를 순환참조라고 한다. 이 경우 해제가 되지 않는 것을 우려하여 weak 레퍼런스를 갖도록 처리하기도 한다. (weak 레퍼런스는 레퍼런스 카운트를 증가시키지 않는다.)
``` swift
closure: { [weak self] in 
    self?.doSomething()
}
```
근데, 또 클로져가 실행되는 시점에서 self가 이미 메모리 해제되었을 수 있으니, 이를 unwrapping 하기위해
```swift
closure: { [weak self] in 
    guard let `self` = self else { return }
    self.doSomething()
}
```
와 같이 처리하는 것이 보통이다. <br/>
하지만.. 매우 귀. 찮. 다.

## 목표

Closure에서 메모리 캡춰의 범위와 유효 시간을 알아보고, 최대한 꼼수를 사용하여 귀찮은 일을 없애보자.<br/>

**주의 : 이 실험의 결과를 사용함으로 발생하는 다른 이슈들은 책임지지 않습니다.**

---

## 실험1

### 가설 : 클로져는 자신이 캡쳐한 레퍼런스를 동작이 완료된 후에 반환한다.

[소스1](https://github.com/iamchiwon/Closure_ARC_Experiment)의 [커밋 1번](https://github.com/iamchiwon/Closure_ARC_Experiment/tree/d616a1910a16bcf27adbc3246aa36da6cb0fe6f7)
```swift
class ViewController1: UIViewController {
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
```
1. `onBack`에서 클로져를 만들어 `self` 를 캡춰시켰다. 바로 pop을 하고 있지만, `ViewController1` 은 해제되지 않을 것이다.
2. 클로져가 끝나는 시점인 5초 후에 클로져의 종료와 함께 `self`의 레퍼런스가 반환되면서 `ViewController1` 은 비로소 해제될 것이다.

### 결과
```
ViewController1 - viewDidLoad (+1)
ViewController1 - onBack (+1)
ViewController1 - after 5 secs. (-1)
ViewController1 - deinit (-1)
```
* 예상대로 pop된 후 5초 후에 `ViewController1`이 해제되고 `deinit`이 불리는 것을 확인할 수 있다.

---

## 실험2
### 가설 : Rx에서 사용되는 클로져는 Rx가 종료되어야 끝난다.
<br/>
### 실험 2-1
[소스1](https://github.com/iamchiwon/Closure_ARC_Experiment)의 [커밋 2번](https://github.com/iamchiwon/Closure_ARC_Experiment/tree/3128e21c70cfe6602d2f513f0daeb7d9fa991a66)
```swift
tapButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.count += 1
            })
            .subscribe(onNext: { _ in
                self.countLabel.text = "\(self.count)"
            })
            .disposed(by: disposeBag)
```
1. `tapButton`의 rx.tap 은 컨트롤 이벤트로 `completed`되지 않는다. 그러므로 rx는 종료되지 않는다.
2. 이벤트 처리를 위해 사용된 클로져에서 self를 사용하고 있으므로 `self`의 레퍼런스가 증가하게 되고, pop되도 헤제되지 않을 것이다.

### 결과
```
ViewController2 - viewDidLoad (+1)
ViewController2 - do(onNext) (+1)
ViewController2 - subscribe(onNext) (+1)
ViewController2 - onBack
```
* `onBack`에 의해서 pop되었으나, `deinit`은 불리지 않는 것을 볼 수 있다.

---

#### 실험2-2

[소스1](https://github.com/iamchiwon/Closure_ARC_Experiment)의 [커밋 3번](https://github.com/iamchiwon/Closure_ARC_Experiment/tree/4cf947e9a5dc06b2839766d712c9937c28b634bb)
```swift
@objc func onBack() {
    print("ViewController2 - onBack")
    disposeBag = DisposeBag()
    navigationController?.popViewController(animated: true)
}
```
1. `onBack` 할 때 강제로 `disposeBag`을 없앤다면, 여기에 등록된 이벤트 `observable`도 종료될 것이다.
2. `observable`이 종료되면 함께 종료되는 클로져들에 의해 `self`의 레퍼런스도 반환될 것이다.
3. `ViewController2`는 `deinit`될 것이다.

### 결과
```
ViewController2 - viewDidLoad (+1)
ViewController2 - do(onNext) (+1)
ViewController2 - subscribe(onNext) (+1)
ViewController2 - onBack
ViewController2 - deinit (-1)
```
* `disposeBag` 을 삭제하는것으로 `ViewController2`가 제대로 해제되는 것을 볼 수 있다.

---

#### 실험2-3

[소스1](https://github.com/iamchiwon/Closure_ARC_Experiment)의 [커밋 4번](https://github.com/iamchiwon/Closure_ARC_Experiment/tree/355da9e9d74a13722114ed9646461d0e66a79b55)
```swift
//disposeBag에 등록시키지 않았다.
_ = Observable.from([1,2,3,4,5,6,7,8,9,10])
    .delay(0.5, scheduler: MainScheduler.instance)
    .do(onNext: { n in
        self.count = n
    })
    .map({ "\($0)" })
    .subscribe(onNext: { s in
        self.countLabel.text = s
    })
```
1. `Complete`되는 `Observable`이라면 `completed` 시점에 클로져가 종료될 것이다.
2. 클로져가 증가시킨 레퍼런스가 반환될 것이다.

### 결과
```
ViewController2 - viewDidLoad (+1)
ViewController2 - do(onNext) (+1)
ViewController2 - subscribe(onNext) (+1)
ViewController2 - onBack
ViewController2 - deinit (-1)
```
* 추가한 `Observable`은 `DisposeBag`에 등록하지도 않았고, 클로져의 구현에서 `self`를 사용했음에도, `completed` 됨에 따라 `self`의 레퍼런스가 반환되어 `deinit` 되는 것을 확인할 수 있다.

---

## 고찰

1. 클로져는 생성 시 내부에서 사용되는 외부변수의 값을 캡춰한다.
2. 캡춰하는 변수가 레퍼런스 타입일 경우 레퍼런스 카운트가 증가한다.
3. 클로져가 종료되면 레퍼런스 카운트가 다시 감소된다.
4. Rx를 사용하는 과정에서의 클로져는 Rx가 소유한다.
5. Rx가 dispose되거나 completed 되면 클로져가 함께 종료된다.

---

## 결론

1. `[weak self]` 와 같은 귀찮은 코드를 하지 않더라도, 종료조건이나 시점을 통제함으로써 메모리를 관리할 수 있다.
2. Rx의 경우 강제 `dispose` 시킴으로써 레퍼런스 카운트를 감소시킬 수 있다.
<br/>

#### 응용: 이 결과를 바탕으로 `self`를 맘껏 사용하지만 메모리 해제가 잘 되는 예제를 만들어 보자.

[소스1](https://github.com/iamchiwon/Closure_ARC_Experiment)의 [커밋 5번](https://github.com/iamchiwon/Closure_ARC_Experiment/tree/d36961d5f7c5ca9a1eaa7bfc017b275612d498c3)
```swift
override func didMove(toParentViewController parent: UIViewController?) {
    super.didMove(toParentViewController: parent)
    if parent == nil { disposeBag = DisposeBag() }
}
```
1. `ViewController`가 사라지는 시점을 잡아서 `dispose`를 강제시키면 메모리 해제를 통제할 수 있다.
2. (상세설명 생략 - 소스 참조)
<br/>

### 결과
```
ViewController3 - viewDidLoad (+1)
ViewController3 - deinit (-1)
```
* `self`를 맘껏 쓰고도 메모리 해제가 잘 되는 `ViewController`를 만들 수 있었다.

---

## 레퍼런스

* 소스1 :  https://github.com/iamchiwon/Closure_ARC_Experiment