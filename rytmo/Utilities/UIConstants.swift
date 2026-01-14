//
//  UIConstants.swift
//  rytmo
//
//  Created by hippoo on 12/8/25.
//

import Foundation

struct UIConstants {
    struct MainWindow {
        static let minWidth: CGFloat = 1100
        static let idealWidth: CGFloat = 1390
        static let minHeight: CGFloat = 600
        static let idealHeight: CGFloat = 800
    }
    
    struct Notch {
        static var openWidth: CGFloat { openNotchSize.width }
        static var openHeight: CGFloat { openNotchSize.height }
        static let shadowPadding: CGFloat = 20
        
        static var windowSize: CGSize {
            CGSize(width: openWidth, height: openHeight + shadowPadding)
        }
        
        struct CornerRadius {
            static let openedTop: CGFloat = 19
            static let openedBottom: CGFloat = 24
            static let closedTop: CGFloat = 6
            static let closedBottom: CGFloat = 14
        }
        
        struct Closed {
            static let defaultWidth: CGFloat = 185
            static let defaultHeight: CGFloat = 32
        }
    }
}
