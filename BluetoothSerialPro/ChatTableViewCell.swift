//
//  ChatTableViewCell.swift
//  BluetoothSerialPro
//
//  Created by Alex on 21/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

fileprivate let textTopMargin: CGFloat = 10
fileprivate let textLeftMargin: CGFloat = 15
fileprivate let bubbleTopMargin: CGFloat = 5
fileprivate let bubbleAngleWidth: CGFloat = 6
fileprivate let outgoingColor = UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
fileprivate let cornerRadius: CGFloat = 16

class ChatTableViewCell: UITableViewCell {
    private let label = UILabel()
    private var bubbleLayer: CAShapeLayer?
    var messageText = ""
    var isSent = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        selectionStyle = .none
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let tw = ChatTableViewCell.calculateWidth(forText: messageText)
        let w: CGFloat = tw - textLeftMargin*2 - bubbleAngleWidth
        let h: CGFloat = bounds.height - textTopMargin*2
        let x: CGFloat = isSent ? bounds.width - tw + textLeftMargin : textLeftMargin + bubbleAngleWidth
        let y: CGFloat = textTopMargin
        label.frame = CGRect(x: x, y: y, width: w, height: h)
        label.text = messageText
        label.textAlignment = isSent ? .right : .left
        label.textColor = isSent ? UIColor.black : UIColor.white
        
        let px: CGFloat = isSent ? bounds.width - tw : bubbleAngleWidth
        let py: CGFloat = bubbleTopMargin
        let pw: CGFloat = tw - bubbleAngleWidth
        let ph: CGFloat = bounds.height - bubbleTopMargin*2
        let pm: CGFloat = bubbleAngleWidth/4
        let pd: CGFloat = sqrt(pow(cornerRadius, 2)/2)
        let path = UIBezierPath()
        
        if isSent {
            path.move(to: CGPoint(x: px+pw-cornerRadius, y: py)) // top right before corner. cw from here
            path.addArc(withCenter: CGPoint(x: px+pw-cornerRadius, y: py+cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi*1.5, endAngle: CGFloat(0), clockwise: true)
            path.addLine(to: CGPoint(x: px+pw, y: py+ph-cornerRadius))
            path.addQuadCurve(to: CGPoint(x: px+pw+bubbleAngleWidth, y: py+ph), controlPoint: CGPoint(x: px+pw-pm, y: py+ph))
            path.addQuadCurve(to: CGPoint(x: px+pw+pd-cornerRadius, y: py+ph+pd-cornerRadius), controlPoint: CGPoint(x: px+pw+pd-cornerRadius, y: py+ph))
            path.addArc(withCenter: CGPoint(x: px+pw-cornerRadius, y: py+ph-cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi/4, endAngle: CGFloat.pi/2, clockwise: true)
            path.addLine(to: CGPoint(x: px+cornerRadius, y: py+ph))
            path.addArc(withCenter: CGPoint(x: px+cornerRadius, y: py+ph-cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true)
            path.addLine(to: CGPoint(x: px, y: py+cornerRadius))
            path.addArc(withCenter: CGPoint(x: px+cornerRadius, y: py+cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi, endAngle: CGFloat.pi*1.5, clockwise: true)
            path.close()
        } else {
            path.move(to: CGPoint(x: px+pw-cornerRadius, y: py)) // top right before corner. cw from here
            path.addArc(withCenter: CGPoint(x: px+pw-cornerRadius, y: py+cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi*1.5, endAngle: 0, clockwise: true)
            path.addLine(to: CGPoint(x: px+pw, y: py+ph-cornerRadius))
            path.addArc(withCenter: CGPoint(x: px+pw-cornerRadius, y: py+ph-cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
            path.addLine(to: CGPoint(x: px+cornerRadius, y: py+ph))
            path.addArc(withCenter: CGPoint(x: px+cornerRadius, y: py+ph-cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi*0.75, clockwise: true)
            path.addQuadCurve(to: CGPoint(x: px-bubbleAngleWidth, y: py+ph), controlPoint: CGPoint(x: px+cornerRadius-pd, y: py+ph))
            path.addQuadCurve(to: CGPoint(x: px, y: py+ph-cornerRadius), controlPoint: CGPoint(x: px+pm, y: py+ph))
            path.addLine(to: CGPoint(x: px, y: py+cornerRadius))
            path.addArc(withCenter: CGPoint(x: px+cornerRadius, y: py+cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi, endAngle: CGFloat.pi*1.5, clockwise: true)
            path.close()
        }
        
        /*
        let pr: CGRect  = CGRect(x: px, y: py, width: pw, height: ph)
        let pd: CGFloat = (cornerRadius-pm)/sqrt(2)
        let path = UIBezierPath(roundedRect: pr, cornerRadius: cornerRadius)
        
        if isSent {
            path.move(to: CGPoint(x: px+pw+pd-cornerRadius, y: py-pd+cornerRadius))
            path.addQuadCurve(to: CGPoint(x: px+pw+bubbleAngleWidth, y: py), controlPoint: CGPoint(x: px+pw, y: py))
            path.addQuadCurve(to: CGPoint(x: px+pw, y: py+cornerRadius), controlPoint: CGPoint(x: px+pw+pm, y: py))
        } else {
            path.move(to: CGPoint(x: px, y: py+cornerRadius))
            path.addQuadCurve(to: CGPoint(x: px-bubbleAngleWidth, y: py), controlPoint: CGPoint(x: px-pm, y: py))
            path.addQuadCurve(to: CGPoint(x: px-pd+cornerRadius, y: py-pd+cornerRadius), controlPoint: CGPoint(x: px, y: py))
        }*/
        
        if isSent {
            //let bg = UIView()
            //bg.backgroundColor = UIColor.white
            //backgroundView = bg
            contentView.backgroundColor = UIColor.white

            bubbleLayer?.removeFromSuperlayer()
            bubbleLayer = CAShapeLayer()
            bubbleLayer!.path = path.cgPath
            bubbleLayer!.fillColor = outgoingColor.cgColor
            contentView.layer.addSublayer(bubbleLayer!)
        } else {
            //backgroundView = nil
            contentView.backgroundColor = UIColor.clear
            let stencil = UIBezierPath(roundedRect: bounds.insetBy(dx: -2, dy: -2), cornerRadius: 0) // make it a little larger to prevent superthin blue lines
            stencil.append(path)
            stencil.usesEvenOddFillRule = true
            bubbleLayer?.removeFromSuperlayer()
            bubbleLayer = CAShapeLayer()
            bubbleLayer!.path = stencil.cgPath
            bubbleLayer!.fillRule = kCAFillRuleEvenOdd
            bubbleLayer!.fillColor = UIColor.white.cgColor
            contentView.layer.addSublayer(bubbleLayer!)
        }
    }
}

extension ChatTableViewCell {
    class func calculateHeight(forText text: String) -> CGFloat {
        let nss = NSString(string: text)
        let textRect = nss.boundingRect(with: CGSize(width: CGFloat(UIScreen.main.bounds.width*0.65), height: CGFloat(MAXFLOAT)),
                                     options: .usesLineFragmentOrigin,
                                  attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)/*,
                                               NSParagraphStyleAttributeName: paragraphStyle*/],
                                     context: nil)
        return max(textRect.height + textTopMargin*2, cornerRadius*2 + bubbleTopMargin*2)
    }
    
    class func calculateWidth(forText text: String) -> CGFloat {
        let nss = NSString(string: text)
        let textRect = nss.boundingRect(with: CGSize(width: CGFloat(UIScreen.main.bounds.width*0.65), height: CGFloat(MAXFLOAT)),
                                        options: .usesLineFragmentOrigin,
                                        attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)/*,
                                             NSParagraphStyleAttributeName: paragraphStyle*/],
                                        context: nil)
        return textRect.width + textLeftMargin*2 + bubbleAngleWidth
    }
}
