//
//  CDPPopupContainer.swift
//  popupContainer_Swift
//
//  Created by CDP on 2022/4/13.
//  从下向上底部弹层容器
//
//  进入/退出弹层，调用相关 CDPPopupContainer.appear / CDPPopupContainer.disappear 类方法就行
//  或者 退出时 自己直接调用 -(void)dismissViewControllerAnimated:completion: 方法也可以

import UIKit

@objc protocol CDPPopupContainerDelegate: NSObjectProtocol {
    /// 拖动时，在手势方法最开始回调 (forbidPanGesture禁止则不回调)
    /// - container: 弹层容器
    /// - panGesture: 拖动手势
    @objc optional func popupContainer(container: CDPPopupContainer, handlePanGesture panGesture: UIPanGestureRecognizer)
    
    /// 拖动结束并即将退出弹层回调
    /// - container: 弹层容器
    @objc optional func popupContainerWillDisappearWhenPanGestureEnd(container: CDPPopupContainer)
    
    /// 点击背景蒙层回调
    /// - container: 弹层容器
    @objc optional func popupContainerDidClickDimming(container: CDPPopupContainer)
    
    /// 当 内容view里有scrollView且能滑动时，如果需要在scrollView上也要支持拖动关闭弹层，解决 拖动/滑动 手势冲突，则在此方法里返回该scrollView
    /// 如不实现该代理，则scrollView拖动时，哪怕此时内容已在最顶部，只会执行scrollView自己的内容滑动，不会执行弹层的拖动关闭效果，scrollView以外部分拖动仍可执行关闭效果
    /// - Returns: 内容view里的scrollView
    @objc optional func popupContainerNeedHandleScrollView() -> UIScrollView?
}

/// 主类：自下向上弹层容器
@objcMembers
class CDPPopupContainer: UIViewController {
    /// 代理
    public weak var delegate: CDPPopupContainerDelegate? = nil
    
    /// 整体弹出高度 (默认 300)
    public var popupHeight: CGFloat = 300 {
        didSet {
            preferredContentSize = CGSize(width: view.frame.width, height: max(0, popupHeight))
        }
    }
    /// 是否禁止拖动退出弹层手势 (默认 NO)
    public var forbidPanGesture: Bool = false
    /// 拖动结束时，弹层露出高度 / 整体弹出总高度 小于 disappearWhenPanGestureEnd，则弹层消失 (默认 0.5)
    public var disappearWhenPanGestureEnd: CGFloat = 0.5
    /// 背景蒙层透明度 (默认 0.5)
    public var dimmingAlpha: CGFloat = 0.5 {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.dimmingAlpha = dimmingAlpha
        }
    }
    /// 背景蒙层颜色，如果不想显示背景但需要点击消失，可设为.clear (默认 .black)
    public var dimmingColor: UIColor = .black {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.dimmingColor = dimmingColor
        }
    }
    /// 背景蒙层是否可点击使弹层消失 (默认 YES)
    public var dimmingCanClickDisappear: Bool = true {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.dimmingCanClickDisappear = dimmingCanClickDisappear
        }
    }
    /// 拖动结束时，未达到弹层消失条件，恢复原状所需动画时长 (默认 0.2)
    public var recoverDuration: CGFloat = 0.2
    /// 过渡动画时长 (默认 0.3)
    public var duration: TimeInterval = 0.3 {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.duration = duration
        }
    }
    /// 弹层顶部圆角 (默认 0)
    public var cornerRadius: CGFloat = 0 {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.cornerRadius = cornerRadius
        }
    }
    /// 顶部最外层是否拥有阴影 (默认 NO)
    public var haveShadow: Bool = false {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.haveShadow = haveShadow
        }
    }
    /// 阴影Opacity (默认 0.44)
    public var shadowOpacity: CGFloat = 0.44 {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.shadowOpacity = shadowOpacity
        }
    }
    /// 阴影Radius (默认 13)
    public var shadowRadius: CGFloat = 13 {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.shadowRadius = shadowRadius
        }
    }
    /// 阴影Offset (默认 CGSize(width: 0, height: -6))
    public var shadowOffset: CGSize = CGSize(width: 0, height: -6) {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.shadowOffset = shadowOffset
        }
    }
    /// 阴影颜色 (默认 .black)
    public var shadowColor: UIColor = .black {
        didSet {
            guard let delegate = transitioningDelegate as? CDPPopupPresentationController else { return }
            delegate.shadowColor = shadowColor
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //弹层整体背景色
        view.backgroundColor = .white

        //拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(panGesture:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        //设置内容size
        preferredContentSize = CGSize(width: view.bounds.size.width, height: max(0, popupHeight))
    }
    
    /// 即将进行过渡
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        preferredContentSize = CGSize(width: view.frame.width, height: max(0, popupHeight))
    }
}

//MARK: - 吊起弹层/退出弹层
extension CDPPopupContainer {
    /// 吊起弹层
    /// - Parameters:
    ///   - contentView: 弹层上要添加的内容view，自己设置frame
    ///   - fromVC: 吊起弹层的viewController
    ///   - popupHeight: 弹层整体弹出高度
    public class func appear(contentView: UIView, fromVC: UIViewController, popupHeight: CGFloat = 300) {
        appear(contentView: contentView, fromVC: fromVC) { container in
            container.popupHeight = max(0, popupHeight)
        }
    }
    
    /// 吊起弹层
    /// - Parameters:
    ///   - contentView: 弹层上要添加的内容view，自己设置frame 或 在 config回调 里设置自适应
    ///   - fromVC: 吊起弹层的viewController
    ///   - config: 配置回调，用于吊起弹层前的一些自定义设置
    public class func appear(contentView: UIView, fromVC: UIViewController, config: ((CDPPopupContainer) -> Void)?) {
        appear(contentView: contentView, fromVC: fromVC, config: config, completion: nil)
    }
    
    /// 吊起弹层
    /// - Parameters:
    ///   - contentView: 弹层上要添加的内容view，自己设置frame 或 在 config回调 里设置自适应
    ///   - fromVC: 吊起弹层的viewController
    ///   - config: 配置回调，用于吊起弹层前的一些自定义设置
    ///   - completion: 弹层吊起完成回调
    public class func appear(contentView: UIView, fromVC: UIViewController, config: ((CDPPopupContainer) -> Void)?, completion: (() -> Void)?) {
        //生成弹层容器
        let container = CDPPopupContainer()
        //添加内容view
        container.view.addSubview(contentView)
        //设置过渡处理类
        let presentationController = CDPPopupPresentationController(presentedViewController: container, presenting: fromVC)
        container.transitioningDelegate = presentationController
        //背景点击回调
        presentationController.dimmingClickBeforeDisappear = { [weak container] in
            guard let container = container else { return }
            container.delegate?.popupContainerDidClickDimming?(container: container)
        }
        //配置container
        config?(container)
        //吊起弹层
        fromVC.present(container, animated: true, completion: completion)
    }
    
    /// 退出最顶层的弹层
    /// - Parameters:
    ///   - animated: 是否进行动画
    ///   - completion: 弹层退出完成回调
    public class func disappear(animated: Bool, completion: (() -> Void)?) {
        guard let vc = getCurrentVC() else { return }
        vc.dismiss(animated: animated, completion: completion)
    }
}

//MARK: - 手势代理
extension CDPPopupContainer: UIGestureRecognizerDelegate {
    /// 手势是否可执行
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        //判断是否关闭拖动手势
        if forbidPanGesture {
            return false
        }
        let scrollView = delegate?.popupContainerNeedHandleScrollView?()
        guard let scrollView = scrollView, let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let point = gestureRecognizer.translation(in: gestureRecognizer.view)
        if abs(point.y) >= abs(point.x) {
            //竖向滑动
            return scrollView.contentOffset.y <= -max(scrollView.contentInset.top, 0) && point.y > 0 ? true : false
        } else {
            //横向滑动
            return scrollView.contentOffset.x <= -max(scrollView.contentInset.left, 0) && point.x > 0 ? true : false
        }
    }
    
    /// 手势冲突是否可同时执行
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let scrollView = delegate?.popupContainerNeedHandleScrollView?()
        guard let scrollView = scrollView, let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer, view.gestureRecognizers?.contains(gestureRecognizer) == true, scrollView.panGestureRecognizer == otherGestureRecognizer else {
            return false
        }
        //是scrollView的滑动手势则都允许
        return true
    }

    /// 其他冲突手势是否失败 (shouldRequireFailureOf 返回false系统才会调用此方法)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self) == true, delegate?.popupContainerNeedHandleScrollView?() != nil && view.gestureRecognizers?.contains(gestureRecognizer) == true else {
            return false
        }
        //将其他冲突滑动手势fail
        return true
    }
}

//MARK: - 手势
private extension CDPPopupContainer {
    /// 拖动手势
    @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        //回调
        delegate?.popupContainer?(container: self, handlePanGesture: panGesture)
        
        //手势位移
        let point = panGesture.translation(in: view)
        //更新最终拖动改变的值
        let endY = abs(point.y) >= abs(point.x) ? point.y : point.x
        
        if panGesture.state == .began || panGesture.state == .changed {
            //手势进行
            view.frame = CGRect(x: 0, y: max(0, endY), width: view.bounds.size.width, height: max(0, popupHeight))
        } else {
            //手势结束
            //当前弹层显示出的高度
            let showHeight = min(popupHeight, popupHeight - endY)
            //判断当前显示的高度是否达到消失条件
            if (showHeight / popupHeight) < disappearWhenPanGestureEnd {
                //回调
                delegate?.popupContainerWillDisappearWhenPanGestureEnd?(container: self)
                //退出
                dismiss(animated: true, completion: nil)
            } else {
                //恢复原状
                recover()
            }
        }
    }
    
    /// 使弹层恢复原状
    private func recover() {
        UIView.animate(withDuration: max(0, recoverDuration)) {
            self.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: max(0, self.popupHeight))
        }
    }
}

//MARK: - 获取VC方法
private extension CDPPopupContainer {
    /// 获取当前顶层VC
    /// - Returns: 当前顶层VC
    class private func getCurrentVC() -> UIViewController? {
        var keyWindow: UIWindow? = nil
        
        // 向下兼容iOS13之前创建的项目
        if let window = UIApplication.shared.delegate?.window {
            keyWindow = window
        } else {
            // iOS13及以后，可多窗口，优先使用活动窗口的keyWindow
            if #available(iOS 13.0, *) {
                let activeWindowScene = UIApplication.shared
                    .connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .first
                if let windowScene = activeWindowScene as? UIWindowScene {
                    keyWindow = windowScene.windows.first { $0.isKeyWindow }
                }
            } else {
                keyWindow = UIApplication.shared.keyWindow
            }
        }
        
        if keyWindow == nil {
            keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        }
        return getVisibleVC(viewController: keyWindow?.rootViewController)
    }
    
    /// 根据viewController获取其当前可见VC
    /// - Parameter viewController: 总VC
    /// - Returns: 可见VC
    class private func getVisibleVC(viewController: UIViewController?) -> UIViewController? {
        if let nvc =  viewController as? UINavigationController {
            return getVisibleVC(viewController: nvc.visibleViewController)
        } else if let tabbarController = viewController as? UITabBarController {
            return getVisibleVC(viewController: tabbarController.selectedViewController)
        } else {
            guard let presentedVC = viewController?.presentedViewController else {
                return viewController
            }
            return getVisibleVC(viewController: presentedVC)
        }
    }
}
