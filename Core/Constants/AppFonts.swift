//
//  AppFonts.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import SwiftUI

enum AppFonts {
    
    enum Headline {
        static func bold(_ size: CGFloat) -> Font {
            .custom("SpaceGrotesk-Bold", size: size)
        }
    }
    
    enum Body {
        static func regular(_ size: CGFloat) -> Font {
            .custom("Manrope-Regular", size: size)
        }
        
        static func medium(_ size: CGFloat) -> Font {
            .custom("Manrope-Medium", size: size)
        }
        
        static func semibold(_ size: CGFloat) -> Font {
            .custom("Manrope-SemiBold", size: size)
        }
        
        static func bold(_ size: CGFloat) -> Font {
            .custom("Manrope-Bold", size: size)
        }
    }
}
