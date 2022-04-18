# CDPPopupContainer
## A pop-up container that gives your custom view the ability to pop up from the bottom of the screen.
## 自下而上弹层容器，可使你的 自定义view 自动拥有从屏幕底部弹出的 弹层能力，且支持各种自定义设置，如 向右/向下 拖动退出弹层手势，背景蒙层自定义，弹层圆角，弹层阴影 等等。
## 详情看 demo 演示。

//吊起弹层 (其中一种appear类方法，根据自己需求选择对应的appear方法)
CDPPopupContainer.appear(contentView: customView, fromVC: self) { container in
    container.popupHeight = 400 //弹层总高度
    container.cornerRadius = 15 //弹层顶部圆角
    container.dimmingColor = .red //背景蒙层颜色
    container.dimmingAlpha = 0.7 //背景蒙层透明度
    container.haveShadow = true //弹层顶部是否带阴影
    container.dimmingCanClickDisappear = false //背景蒙层是否可点击退出弹层
    container.delegate = self //代理
    //仅列出部分可配置参数，其他自定义参数具体查看 CDPPopupContainer.swift
    
    //如果需要用Autolayout布局 或 不想弹层吊起前设置frame，可在此回调里对内容view进行布局
    //此时内容view已被添加进容器，父view为container.view
 } completion: nil
