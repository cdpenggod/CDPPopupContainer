//
//  ViewController.swift
//  popupContainer_Swift
//
//  Created by CDP on 2022/4/13.
//

import UIKit

class ViewController: UIViewController {
    /// 宽度
    let customWidth: CGFloat = UIScreen.main.bounds.width - 60
    
    /// 随便自定义的内嵌UIView,位置根据frame自定义,可以填充满弹层，也可以留有边距
    private lazy var customView: UIView = {
        let view = UIView(frame: CGRect(x: 30, y: 20, width: customWidth, height: 200))
        view.backgroundColor = .red
        view.addSubview(label)
        return view
    }()
    private lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: customWidth - 20, height: 180))
        label.numberOfLines = 0
        return label
    }()
    /// 随便自定义的tableView
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect(x: 30, y: 30, width: customWidth, height: 400), style: .plain)
        view.rowHeight = 50
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .red
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "CDPTableViewCell")
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton(frame: CGRect(x: 30, y: 80, width: customWidth, height: 30), title: "吊起弹层", action: #selector(buttonClick1))
        
        addButton(frame: CGRect(x: 30, y: 120, width: customWidth, height: 30), title: "弹层-改变弹层高度", action: #selector(buttonClick2))
        
        addButton(frame: CGRect(x: 30, y: 160, width: customWidth, height: 30), title: "弹层-部分参数自定义(仅可拖动退出)", action: #selector(buttonClick3))
        
        addButton(frame: CGRect(x: 30, y: 200, width: customWidth, height: 30), title: "弹层-scrollView及其子类", action: #selector(buttonClick4))
        
        addButton(frame: CGRect(x: 30, y: 240, width: customWidth, height: 30), title: "弹层-scrollView及其子类(手势冲突)", action: #selector(buttonClick5))
        
        addButton(frame: CGRect(x: 30, y: 280, width: customWidth, height: 30), title: "弹层-关闭拖动手势", action: #selector(buttonClick6))
    }
    
    /// 添加button
    /// - Parameters:
    ///   - frame: 布局
    ///   - title: title
    ///   - action: 执行方法
    func addButton(frame: CGRect, title: String, action: Selector) {
        let button = UIButton(frame: frame)
        button.adjustsImageWhenHighlighted = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }
}

//MARK: - CDPPopupContainerDelegate 弹层容器代理
extension ViewController: CDPPopupContainerDelegate {
    /// 点击背景蒙层退出前回调
    func popupContainerDidClickDimming(container: CDPPopupContainer) {
        print("点击了背景蒙层")
    }
    
    /// 拖动手势结束，达到退出条件，退出弹层前回调
    func popupContainerWillDisappearWhenPanGestureEnd(container: CDPPopupContainer) {
        print("拖动弹层结束后达到退出条件，退出弹层")
    }
    
    /// 拖动弹层中
    func popupContainer(container: CDPPopupContainer, handlePanGesture panGesture: UIPanGestureRecognizer) {
        print("拖动弹层中")
    }
    
    /// 当内嵌view中包含scrollView及其子类，如果在scrollView上滑动也要 支持拖动退出弹层，则将scrollView返回，内部会处理手势冲突
    func popupContainerNeedHandleScrollView() -> UIScrollView? {
        return tableView
    }
}

//MARK: - tableView代理
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    /// 行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    /// cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CDPTableViewCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255, green: CGFloat(arc4random() % 256) / 255, blue: CGFloat(arc4random() % 256) / 255, alpha: 1)
        return cell
    }
    
    /// 点击cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row % 2 == 0 {
            print("用 CDPPopupContainer.disappear 退出的")
            CDPPopupContainer.disappear(animated: true, completion: nil)
        } else {
            print("外部用 dismiss 方法退出的")
            self.dismiss(animated: true, completion: nil)
        }
    }
}

//MARK: - 点击事件
private extension ViewController {
    /// 按钮1点击
    @objc private func buttonClick1() {
        label.text = "红色为自定义内嵌UIView\n\n位置根据frame自定义,可以填充满弹层，也可以留有边距，往下往右手势拖动可关闭弹层"
        //吊起弹层
        CDPPopupContainer.appear(contentView: customView, fromVC: self)
    }
    
    /// 按钮2点击
    @objc private func buttonClick2() {
        customView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 230)
        label.text = "红色为自定义内嵌UIView\n\n内嵌view.frame调整为与弹层一样，且弹层高度调整为230"
        //吊起弹层
        CDPPopupContainer.appear(contentView: customView, fromVC: self, popupHeight: 230)
    }
    
    /// 按钮3点击
    @objc private func buttonClick3() {
        customView.frame = CGRect(x: 30, y: 20, width: customWidth, height: 300)
        label.frame = CGRect(x: 10, y: 10, width: customWidth - 20, height: 280)
        label.text = "红色为自定义内嵌UIView\n\n弹层高度调整为 400，弹层圆角 15，背景蒙层变色为 .red，背景蒙层透明度变为 0.7，点击背景蒙层不消失，顶部开启阴影，阴影可根据参数自定义\n\n其他自定义参数see CDPPopupContainer.swift"
        //吊起弹层
        //(如果不想用frame，需要用Autolayout布局，可在config回调里进行)
        CDPPopupContainer.appear(contentView: customView, fromVC: self) { container in
            container.popupHeight = 400
            container.cornerRadius = 15
            container.dimmingColor = .red
            container.dimmingAlpha = 0.7
            container.haveShadow = true
            container.dimmingCanClickDisappear = false
            //如果需要用Autolayout布局，可在此回调里对contentView与container.view进行布局
        }
    }
    
    /// 按钮4点击
    @objc private func buttonClick4() {
        //吊起弹层
        //因为tableView自带拖动手势，所以不实现弹层代理的话，在tableView上面拖动弹层，只会走tabelView的手势，而不会走弹层的拖动退出手势
        CDPPopupContainer.appear(contentView: tableView, fromVC: self) { container in
            container.popupHeight = self.tableView.frame.maxY + 50
            container.cornerRadius = 15
            container.haveShadow = true
        } completion: {
            print("弹层吊起完成回调")
        }
    }
    
    /// 按钮5点击
    @objc private func buttonClick5() {
        //吊起弹层
        //此时当scrollView的contentOffset在最左或最顶部时，在scrollView范围 往右或往下继续拖动，弹层支持退出手势
        CDPPopupContainer.appear(contentView: tableView, fromVC: self) { container in
            container.popupHeight = self.tableView.frame.maxY + 50
            container.cornerRadius = 15
            container.haveShadow = true
            
            //设置弹层容器代理
            container.delegate = self
        } completion: {
            print("弹层吊起完成回调")
        }
    }
    
    /// 按钮6点击
    @objc private func buttonClick6() {
        //吊起弹层
        //因为关闭了拖动手势关闭弹层，所以仅能点击cell或蒙层关闭
        CDPPopupContainer.appear(contentView: tableView, fromVC: self) { container in
            container.popupHeight = self.tableView.frame.maxY + 50
            container.cornerRadius = 15
            container.haveShadow = true
            container.delegate = self
            
            //关闭弹层拖动退出手势
            container.forbidPanGesture = true
        } completion: {
            print("弹层吊起完成回调")
        }
    }
}

