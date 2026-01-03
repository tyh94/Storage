//
//  Factory.swift
//  Storage
//
//  Created by Татьяна Макеева on 02.01.2026.
//

import Foundation

public class Factory<Arg, Item>: ObservableObject {
    @usableFromInline
    let block: (Arg) -> Item

    public init(constant: Item) {
        self.block = { _ in constant }
    }

    public init(block: @escaping (Arg) -> Item) {
        self.block = block
    }

    @inlinable
    public func make(_ parameters: Arg) -> Item {
        block(parameters)
    }

    @inlinable
    public func callAsFunction(_ args: Arg) -> Item {
        make(args)
    }
}

extension Factory where Arg == Void {
    @inlinable
    public func make() -> Item {
        block(())
    }

    @inlinable
    public func callAsFunction() -> Item {
        make()
    }
}
