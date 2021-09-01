//
//  Popover.swift
//  Popover
//
//  Created by corin8823 on 8/16/15.
//  Copyright (c) 2015 corin8823. All rights reserved.
//

import Foundation
import UIKit

public enum PopoverOption {
    case arrowSize(CGSize)
    case animationIn(TimeInterval)
    case animationOut(TimeInterval)
    case cornerRadius(CGFloat)
    case sideEdge(CGFloat)
    case blackOverlayColor(UIColor)
    case overlayBlur(UIBlurEffect.Style)
    case type(PopoverType)
    case color(UIColor)
    case dismissOnBlackOverlayTap(Bool)
    case showBlackOverlay(Bool)
    case springDamping(CGFloat)
    case initialSpringVelocity(CGFloat)
    case sideOffset(CGFloat)
    case borderColor(UIColor)
    case marginTop(CGFloat)
}

@objc public enum PopoverType: Int {
    case up
    case down
    case left
    case right
    case auto
}

@objcMembers
open class Popover: UIView {
    // custom property
    open var arrowSize = CGSize(width: 16.0, height: 10.0)
    open var animationIn: TimeInterval = 0.6
    open var animationOut: TimeInterval = 0.3
    open var cornerRadius: CGFloat = 6.0
    open var sideEdge: CGFloat = 20.0
    open var popoverType: PopoverType = .down
    open var blackOverlayColor = UIColor(white: 0.0, alpha: 0.2)
    open var overlayBlur: UIBlurEffect?
    open var popoverColor = UIColor.white
    open var dismissOnBlackOverlayTap: Bool = true
    open var showBlackOverlay: Bool = true
    open var highlightFromView: Bool = false
    open var highlightCornerRadius: CGFloat = 0
    open var springDamping: CGFloat = 0.7
    open var initialSpringVelocity: CGFloat = 3
    open var sideOffset: CGFloat = 6.0
    open var borderColor: UIColor?
    open var marginTop: CGFloat = 0.0

    // custom closure
    open var willShowHandler: (() -> ())?
    open var willDismissHandler: (() -> ())?
    open var didShowHandler: (() -> ())?
    open var didDismissHandler: (() -> ())?

    public fileprivate(set) var blackOverlay = UIControl()

    fileprivate var containerView: UIView!
    fileprivate var contentView: UIView!
    fileprivate var contentViewFrame: CGRect!
    fileprivate var arrowShowPoint: CGPoint!

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.accessibilityViewIsModal = true
    }

    public init(showHandler: (() -> ())?, dismissHandler: (() -> ())?) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.didShowHandler = showHandler
        self.didDismissHandler = dismissHandler
        self.accessibilityViewIsModal = true
    }

    public init(options: [PopoverOption]?, showHandler: (() -> ())? = nil, dismissHandler: (() -> ())? = nil) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.setOptions(options)
        self.didShowHandler = showHandler
        self.didDismissHandler = dismissHandler
        self.accessibilityViewIsModal = true
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = self.bounds
    }

    open func showAsDialog(_ contentView: UIView) {
        guard let rootView = UIApplication.shared.keyWindow else {
            return
        }
        self.showAsDialog(contentView, containerView: rootView)
    }

    open func showAsDialog(_ contentView: UIView, containerView: UIView) {
        self.arrowSize = .zero
        let point = CGPoint(x: containerView.center.x,
                            y: containerView.center.y - contentView.frame.height / 2)
        self.show(contentView, point: point, containerView: containerView)
    }

    /*
     指定视图位置展示自定义视图
     */
    open func show(_ contentView: UIView, fromView: UIView) {
        // 用keyWindow作为显示层
        guard let rootView = UIApplication.shared.keyWindow else {
            return
        }
        self.show(contentView, fromView: fromView, containerView: rootView)
    }

    open func show(_ contentView: UIView, fromView: UIView, containerView: UIView) {
        let point: CGPoint
        // 自动切换上下模式
        // TODO: add left/right auto
        if self.popoverType == .auto {
            if let point = fromView.superview?.convert(fromView.frame.origin, to: nil),
               point.y + fromView.frame.height + self.arrowSize.height + contentView.frame.height > containerView.frame.height
            {
                self.popoverType = .up
            } else {
                self.popoverType = .down
            }
        }
        // 将fromView的坐标转换为containerView的坐标
        switch self.popoverType {
        case .up:
            point = containerView.convert(
                CGPoint(x: fromView.frame.origin.x + (fromView.frame.size.width / 2), y: fromView.frame.origin.y),
                from: fromView.superview)
        case .down, .auto:
            point = containerView.convert(
                CGPoint(x: fromView.frame.origin.x + (fromView.frame.size.width / 2), y: fromView.frame.origin.y + fromView.frame.size.height + marginTop),
                from: fromView.superview)
        case .left:
            point = containerView.convert(
                CGPoint(x: fromView.frame.origin.x - sideOffset, y: fromView.frame.origin.y + 0.5 * fromView.frame.height),
                from: fromView.superview)
        case .right:
            point = containerView.convert(
                CGPoint(x: fromView.frame.origin.x + fromView.frame.size.width + sideOffset, y: fromView.frame.origin.y + 0.5 * fromView.frame.height),
                from: fromView.superview)
        }

        if self.highlightFromView {
            self.createHighlightLayer(fromView: fromView, containerView: containerView)
        }
        // 调用根据坐标显示自定义视图
        self.show(contentView, point: point, containerView: containerView)
    }

    /*
     指定坐标位置展示自定义视图
     */
    open func show(_ contentView: UIView, point: CGPoint) {
        // 用keyWindow作为显示层
        guard let rootView = UIApplication.shared.keyWindow else {
            return
        }
        self.show(contentView, point: point, containerView: rootView)
    }

    open func show(_ contentView: UIView, point: CGPoint, containerView: UIView) {
        self.containerView = containerView
        self.contentView = contentView
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.layer.cornerRadius = self.cornerRadius
        self.contentView.layer.masksToBounds = true
        self.arrowShowPoint = point
        self.show()
    }

    override open func accessibilityPerformEscape() -> Bool {
        self.dismiss()
        return true
    }
    
    /*
     只在重复展示同一个弹窗时调用
     */
    open func showOnly() {
        // 背景遮罩
        if self.dismissOnBlackOverlayTap || self.showBlackOverlay {
            self.blackOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.blackOverlay.frame = self.containerView.bounds
            self.containerView.addSubview(self.blackOverlay)

            if showBlackOverlay {
                if let overlayBlur = self.overlayBlur {
                    let effectView = UIVisualEffectView(effect: overlayBlur)
                    effectView.frame = self.blackOverlay.bounds
                    effectView.isUserInteractionEnabled = false
                    self.blackOverlay.addSubview(effectView)
                } else {
                    if !self.highlightFromView {
                        self.blackOverlay.backgroundColor = self.blackOverlayColor
                    }
                    self.blackOverlay.alpha = 0
                }
            }

            if self.dismissOnBlackOverlayTap {
                self.blackOverlay.addTarget(self, action: #selector(Popover.dismiss), for: .touchUpInside)
            }
        }
        
        // 将自定义视图放入自身自视图，并把自身放入要显示层视图
        self.addSubview(self.contentView)
        self.containerView.addSubview(self)
        // 动画效果
        self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        // 动画开始回调
        self.willShowHandler?()
        // 动画
        UIView.animate(
            withDuration: self.animationIn,
            delay: 0,
            usingSpringWithDamping: self.springDamping,
            initialSpringVelocity: self.initialSpringVelocity,
            options: UIView.AnimationOptions(),
            animations: {
                self.transform = CGAffineTransform.identity
            }) { _ in
            // 动画结束回调
            self.didShowHandler?()
        }
        UIView.animate(
            withDuration: self.animationIn / 3,
            delay: 0,
            options: .curveLinear,
            animations: {
                self.blackOverlay.alpha = 1
            }, completion: nil)
    }

    open func dismiss() {
        if self.superview != nil {
            self.willDismissHandler?()
            UIView.animate(withDuration: self.animationOut, delay: 0,
                           options: UIView.AnimationOptions(),
                           animations: {
                               self.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
                               self.blackOverlay.alpha = 0
                           }) { _ in
                self.contentView.removeFromSuperview()
                self.blackOverlay.removeFromSuperview()
                self.removeFromSuperview()
                self.transform = CGAffineTransform.identity
                self.didDismissHandler?()
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        let arrow = UIBezierPath()
        let color = self.popoverColor
        let arrowPoint = self.containerView.convert(self.arrowShowPoint, to: self)
        switch self.popoverType {
        case .up:
            arrow.move(to: CGPoint(x: arrowPoint.x, y: self.bounds.height))
            arrow.addLine(
                to: CGPoint(
                    x: arrowPoint.x - self.arrowSize.width * 0.5,
                    y: self.isCornerLeftArrow ? self.arrowSize.height : self.bounds.height - self.arrowSize.height)
            )

            arrow.addLine(to: CGPoint(x: self.cornerRadius, y: self.bounds.height - self.arrowSize.height))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.cornerRadius,
                    y: self.bounds.height - self.arrowSize.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(90),
                endAngle: self.radians(180),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: 0, y: self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.cornerRadius,
                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(180),
                endAngle: self.radians(270),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: self.bounds.width - self.cornerRadius, y: 0))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width - self.cornerRadius,
                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(270),
                endAngle: self.radians(0),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height - self.arrowSize.height - self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width - self.cornerRadius,
                    y: self.bounds.height - self.arrowSize.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(0),
                endAngle: self.radians(90),
                clockwise: true)

            arrow.addLine(
                to: CGPoint(
                    x: arrowPoint.x + self.arrowSize.width * 0.5,
                    y: self.isCornerRightArrow ? self.arrowSize.height : self.bounds.height - self.arrowSize.height)
            )

        case .down, .auto:
            arrow.move(to: CGPoint(x: arrowPoint.x, y: 0))

            if self.isCloseToCornerRightArrow, !self.isCornerRightArrow {
                if !isBehindCornerRightArrow {
                    arrow.addLine(to: CGPoint(x: self.bounds.width - self.cornerRadius, y: self.arrowSize.height))
                    arrow.addArc(
                        withCenter: CGPoint(x: self.bounds.width - self.cornerRadius, y: self.arrowSize.height + self.cornerRadius),
                        radius: self.cornerRadius,
                        startAngle: self.radians(270.0),
                        endAngle: self.radians(0),
                        clockwise: true)
                } else {
                    arrow.addLine(to: CGPoint(x: self.bounds.width, y: self.arrowSize.height + self.cornerRadius))
                    arrow.addLine(to: CGPoint(x: self.bounds.width, y: self.arrowSize.height))
                }
            } else {
                arrow.addLine(
                    to: CGPoint(
                        x: self.isBehindCornerLeftArrow ? self.frame.minX - self.arrowSize.width * 0.5 : arrowPoint.x + self.arrowSize.width * 0.5,
                        y: self.isCornerRightArrow ? self.arrowSize.height + self.bounds.height : self.arrowSize.height)
                )
                arrow.addLine(to: CGPoint(x: self.bounds.width - self.cornerRadius, y: self.arrowSize.height))
                arrow.addArc(
                    withCenter: CGPoint(
                        x: self.bounds.width - self.cornerRadius,
                        y: self.arrowSize.height + self.cornerRadius),
                    radius: self.cornerRadius,
                    startAngle: self.radians(270.0),
                    endAngle: self.radians(0),
                    clockwise: true)
            }

            arrow.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height - self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width - self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(0),
                endAngle: self.radians(90),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: 0, y: self.bounds.height))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(90),
                endAngle: self.radians(180),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: 0, y: self.arrowSize.height + self.cornerRadius))

            if !isBehindCornerLeftArrow {
                arrow.addArc(
                    withCenter: CGPoint(
                        x: self.cornerRadius,
                        y: self.arrowSize.height + self.cornerRadius),
                    radius: self.cornerRadius,
                    startAngle: self.radians(180),
                    endAngle: self.radians(270),
                    clockwise: true)
            }

            if isBehindCornerRightArrow {
                arrow.addLine(to: CGPoint(
                    x: self.bounds.width - self.arrowSize.width * 0.5,
                    y: self.isCornerLeftArrow ? self.arrowSize.height + self.bounds.height : self.arrowSize.height))
            } else if isCloseToCornerLeftArrow, !isCornerLeftArrow {
                () // skipping this line in that case
            } else {
                arrow.addLine(to: CGPoint(x: arrowPoint.x - self.arrowSize.width * 0.5,
                                          y: self.isCornerLeftArrow ? self.arrowSize.height + self.bounds.height : self.arrowSize.height))
            }

        case .left:
            arrow.move(to: CGPoint(x: self.bounds.width, y: self.bounds.height * 0.5))
            arrow.addLine(
                to: CGPoint(
                    x: self.bounds.width - self.arrowSize.height,
                    y: self.bounds.height * 0.5 + self.arrowSize.width * 0.5))

            arrow.addLine(to: CGPoint(x: self.bounds.width - self.arrowSize.height, y: self.bounds.height - self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width - self.arrowSize.height - self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(0.0),
                endAngle: self.radians(90),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: self.cornerRadius, y: self.bounds.height))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(90),
                endAngle: self.radians(180),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: 0, y: self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.cornerRadius,
                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(180),
                endAngle: self.radians(270),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: self.bounds.width - self.arrowSize.height - self.cornerRadius, y: 0))
            arrow.addArc(
                withCenter: CGPoint(x: self.bounds.width - self.arrowSize.height - self.cornerRadius,
                                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(270),
                endAngle: self.radians(0),
                clockwise: true)

            arrow.addLine(to: CGPoint(x: self.bounds.width - self.arrowSize.height,
                                      y: self.bounds.height * 0.5 - self.arrowSize.width * 0.5))
        case .right:
            arrow.move(to: CGPoint(x: arrowPoint.x, y: self.bounds.height * 0.5))
            arrow.addLine(
                to: CGPoint(
                    x: arrowPoint.x + self.arrowSize.height,
                    y: self.bounds.height * 0.5 + 0.5 * self.arrowSize.width))

            arrow.addLine(
                to: CGPoint(
                    x: arrowPoint.x + self.arrowSize.height,
                    y: self.bounds.height - self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: arrowPoint.x + self.arrowSize.height + self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(180.0),
                endAngle: self.radians(90),
                clockwise: false)

            arrow.addLine(to: CGPoint(x: self.bounds.width + arrowPoint.x - self.cornerRadius, y: self.bounds.height))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width + arrowPoint.x - self.cornerRadius,
                    y: self.bounds.height - self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(90),
                endAngle: self.radians(0),
                clockwise: false)

            arrow.addLine(to: CGPoint(x: self.bounds.width + arrowPoint.x, y: self.cornerRadius))
            arrow.addArc(
                withCenter: CGPoint(
                    x: self.bounds.width + arrowPoint.x - self.cornerRadius,
                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(0),
                endAngle: self.radians(-90),
                clockwise: false)

            arrow.addLine(to: CGPoint(x: arrowPoint.x + self.arrowSize.height - self.cornerRadius, y: 0))
            arrow.addArc(
                withCenter: CGPoint(x: arrowPoint.x + self.arrowSize.height + self.cornerRadius,
                                    y: self.cornerRadius),
                radius: self.cornerRadius,
                startAngle: self.radians(-90),
                endAngle: self.radians(-180),
                clockwise: false)

            arrow.addLine(to: CGPoint(x: arrowPoint.x + self.arrowSize.height,
                                      y: self.bounds.height * 0.5 - self.arrowSize.width * 0.5))
        }

        color.setFill()
        arrow.fill()
        if let borderColor = borderColor {
            borderColor.setStroke()
            arrow.stroke()
        }
    }
}

private extension Popover {
    func setOptions(_ options: [PopoverOption]?) {
        if let options = options {
            for option in options {
                switch option {
                case let .arrowSize(value):
                    self.arrowSize = value
                case let .animationIn(value):
                    self.animationIn = value
                case let .animationOut(value):
                    self.animationOut = value
                case let .cornerRadius(value):
                    self.cornerRadius = value
                case let .sideEdge(value):
                    self.sideEdge = value
                case let .blackOverlayColor(value):
                    self.blackOverlayColor = value
                case let .overlayBlur(style):
                    self.overlayBlur = UIBlurEffect(style: style)
                case let .type(value):
                    self.popoverType = value
                case let .color(value):
                    self.popoverColor = value
                case let .dismissOnBlackOverlayTap(value):
                    self.dismissOnBlackOverlayTap = value
                case let .showBlackOverlay(value):
                    self.showBlackOverlay = value
                case let .springDamping(value):
                    self.springDamping = value
                case let .initialSpringVelocity(value):
                    self.initialSpringVelocity = value
                case let .sideOffset(value):
                    self.sideOffset = value
                case let .borderColor(value):
                    self.borderColor = value
                case let .marginTop(value):
                    self.marginTop = value
                }
            }
        }
    }

    func create() {
        var frame = self.contentView.frame
        // 计算原点
        switch self.popoverType {
        case .up, .down, .auto:
            frame.origin.x = self.arrowShowPoint.x - frame.size.width * 0.5
        case .left, .right:
            frame.origin.y = self.arrowShowPoint.y - frame.size.height * 0.5
        }
        // 防止左右出界
        var sideEdge: CGFloat = 0.0
        if frame.size.width < self.containerView.frame.size.width {
            sideEdge = self.sideEdge
        }
        let outerSideEdge = frame.maxX - self.containerView.bounds.size.width
        if outerSideEdge > 0 {
            frame.origin.x -= (outerSideEdge + sideEdge)
        } else {
            if frame.minX < 0 {
                frame.origin.x += abs(frame.minX) + sideEdge
            }
        }
        
        self.frame = frame

        
        // 计算箭头偏移
        let arrowPoint = self.containerView.convert(self.arrowShowPoint, to: self)
        var anchorPoint: CGPoint
        switch self.popoverType {
        case .up:
            frame.origin.y = self.arrowShowPoint.y - frame.height - self.arrowSize.height
            anchorPoint = CGPoint(x: arrowPoint.x / frame.size.width, y: 1)
        case .down, .auto:
            frame.origin.y = self.arrowShowPoint.y
            anchorPoint = CGPoint(x: arrowPoint.x / frame.size.width, y: 0)
        case .left:
            frame.origin.x = self.arrowShowPoint.x - frame.size.width - self.arrowSize.height
            anchorPoint = CGPoint(x: 1, y: 0.5)
        case .right:
            frame.origin.x = self.arrowShowPoint.x
            anchorPoint = CGPoint(x: 0, y: 0.5)
        }

        if self.arrowSize == .zero {
            anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }

        let lastAnchor = self.layer.anchorPoint
        self.layer.anchorPoint = anchorPoint
        let x = self.layer.position.x + (anchorPoint.x - lastAnchor.x) * self.layer.bounds.size.width
        let y = self.layer.position.y + (anchorPoint.y - lastAnchor.y) * self.layer.bounds.size.height
        self.layer.position = CGPoint(x: x, y: y)

        switch self.popoverType {
        case .up, .down, .auto:
            frame.size.height += self.arrowSize.height
        case .left, .right:
            frame.size.width += self.arrowSize.height
        }

        self.frame = frame
    }

    func createHighlightLayer(fromView: UIView, containerView: UIView) {
        let path = UIBezierPath(rect: containerView.bounds)
        let highlightRect = containerView.convert(fromView.frame, from: fromView.superview)
        let highlightPath = UIBezierPath(roundedRect: highlightRect, cornerRadius: self.highlightCornerRadius)
        path.append(highlightPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = self.blackOverlayColor.cgColor
        self.blackOverlay.layer.addSublayer(fillLayer)
    }

    func show() {
        self.setNeedsDisplay()
        switch self.popoverType {
        case .up:
            self.contentView.frame.origin.y = 0.0
        case .down, .auto:
            self.contentView.frame.origin.y = self.arrowSize.height
        case .left, .right:
            self.contentView.frame.origin.x = 0
        }
        // 设置大小
        self.create()
        
        showOnly()
    }
    
    var isCloseToCornerLeftArrow: Bool {
        return self.arrowShowPoint.x < self.frame.origin.x + arrowSize.width / 2 + cornerRadius
    }

    var isCloseToCornerRightArrow: Bool {
        return self.arrowShowPoint.x > (self.frame.origin.x + self.bounds.width) - arrowSize.width / 2 - cornerRadius
    }

    var isCornerLeftArrow: Bool {
        return self.arrowShowPoint.x == self.frame.origin.x
    }

    var isCornerRightArrow: Bool {
        return self.arrowShowPoint.x == self.frame.origin.x + self.bounds.width
    }

    var isBehindCornerLeftArrow: Bool {
        return self.arrowShowPoint.x < self.frame.origin.x
    }

    var isBehindCornerRightArrow: Bool {
        return self.arrowShowPoint.x > self.frame.origin.x + self.bounds.width
    }

    func radians(_ degrees: CGFloat) -> CGFloat {
        return CGFloat.pi * degrees / 180
    }
}
