//
//  Text+Localization.swift
//  Storage
//
//  Created by Татьяна Макеева on 16.01.2026.
//

import Foundation
import SwiftUI

extension Text {
    static func localized(
        _ key: String,
        _ args: CVarArg...
    ) -> Text {
        if args.isEmpty {
            return Text(key.localized)
        } else {
            return Text(key.localized(args))
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(
            self,
            bundle: .module,
            comment: ""
        )
    }

    func localized(_ args: CVarArg...) -> String {
        let format = NSLocalizedString(
            self,
            bundle: .module,
            comment: ""
        )
        return String(format: format, arguments: args)
    }
}

struct _TestView: View {
    var body: some View {
        Text.localized("Retry")
    }
}

#Preview {
    _TestView()
}
