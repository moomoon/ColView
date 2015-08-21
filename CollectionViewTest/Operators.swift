//
//  Operators.swift
//  kaipai2
//
//  Created by Jia Jing on 7/22/15.
//  Copyright (c) 2015 Yang Yi. All rights reserved.
//

import Foundation
import Argo
import Runes
import QuartzCore
import ReactiveCocoa

infix operator <<- { associativity left precedence 150 }

func <<-<F, T>(lhs: F -> T, rhs: F) -> T {
    return lhs(rhs)
}


func <|<A, B, C>(lhs: B -> C, rhs: A -> B) -> A -> C{
    return { lhs(rhs($0)) }
}

//for curried functions
func <|<A, B, C, D>(lhs: C -> D, rhs: A -> B -> C) -> A -> B -> D{
    return { a in { b in lhs(rhs(a)(b))} }
}

infix operator ->> {
associativity left

// Lower precedence than the logical comparison operators
// (`&&` and `||`), but higher precedence than the assignment
// operator (`=`)
precedence 100
}

func ->><F, T>(lhs: F, rhs: F -> T) -> T {
    return rhs(lhs)
}



infix operator =~ {}
public func =~(str: String, pattern: String) -> Bool {
    return Regex(pattern).test(str)
}

infix operator ??= {
associativity right
precedence 90
}

func ??=<T>(inout assignTo: T?, @autoclosure defaultValue: () -> T?) -> T? {
    if assignTo == nil {
        assignTo = defaultValue()
    }
    return assignTo
}


extension String {
    public subscript(range: Range<Int>) -> String {
        var start = Swift.advance(startIndex, range.startIndex)
        var end = Swift.advance(startIndex, range.endIndex)
        return self.substringWithRange(Range(start: start, end: end))
    }
}

extension Array {
    func rest(numElements: Int = 1) -> [T] {
        var result : [T] = []
        if (numElements < self.count) {
            for index in numElements..<self.count {
                result.append(self[index])
            }
        }
        return result
    }
    
    func each(apply: T -> ()) {
        for element in self {
            apply(element)
        }
    }
    
    func findFirst(predicate: T -> Bool) -> T? {
        for t in self {
            if predicate(t){
                return t
            }
        }
        return nil
    }
    
    func reduceIfAny<U>(@noescape firstElementTransformer: T -> U, @noescape combine: (U, T) -> U) -> U? {
        return reduceAll(self, firstElementTransformer, combine)
    }
    
}

func reduceAll<S : SequenceType, U>(sequence: S, @noescape firstElementTransformer: S.Generator.Element -> U, @noescape combine: (U, S.Generator.Element) -> U) -> U? {
    var generator = sequence.generate()
    if var ret = optional(generator.next(), firstElementTransformer) {
        while let next = generator.next() {
            ret = combine(ret, next)
        }
        return ret
    }
    return nil
}


func pack<A, B>(a: A, b: [B]) -> [(A, B)] {
    return b.map{ (a, $0) }
}


func optional<A, B>(arg: A?, @noescape wrappedFunc: A -> B) -> B? {
    return arg == nil ? nil : wrappedFunc(arg!)
}


// eliminating @autoclosure
func &(lhs: Bool, rhs: Bool) -> Bool {
    return lhs && rhs
}

//func reversePack<A, B>(a: [A], b: B) -> [(A, B)] {
//    return a.map{ ($0, b) }
//}

internal func swap<A, B>(t: (A, B)) -> (B, A) {
    return (t.1, t.0)
}

internal func repack<A, B>(t: (A), value: B) -> (A, B) {
    return (t.0, value)
}


internal func repack<A, B, C>(t: (A, B), value: C) -> (A, B, C) {
    return (t.0, t.1, value)
}

internal func repack<A, B, C, D>(t: (A, B, C), value: D) -> (A, B, C, D) {
    return (t.0, t.1, t.2, value)
}

internal func repack<A, B, C, D, E>(t: (A, B, C, D), value: E) -> (A, B, C, D, E) {
    return (t.0, t.1, t.2, t.3, value)
}


func arrayProducer<T, ErrorType>(arr: [T]) -> SignalProducer<T, ErrorType> {
    return SignalProducer{
        sink, disposable in
        arr.each{ sendNext(sink, $0) }
    }
}

public func compact<T>(array: [T?]) -> [T] {
    var result: [T] = []
    for elem in array {
        if let val = elem {
            result.append(val)
        }
    }
    return result
}

func clamp(minVal: CGFloat, maxVal: CGFloat)(_ v: CGFloat) -> CGFloat {
    return min(max(v, minVal), maxVal)
}

func <~<T, ErrorType>(tag: String, sp: SignalProducer<T, ErrorType>) -> Disposable {
    return sp |> start(next: {println(tag + " \($0)")})
}

func <~<A, NoError>(prop: MutableProperty<A>, transform: SignalProducer<A -> A, NoError>) -> Disposable {
    return transform |> start(next: { let v = prop.value; prop.value = $0(v) })
}

func <~<A, NoError>(prop: MutableProperty<A>, transform: Signal<A -> A, NoError>) -> Disposable {
    return transform.observe(next: { let v = prop.value; prop.value = $0(v) })!
}

extension SignalProducer {
    func mutableProperty(initValue: T, skipCount: Int = 0) -> MutableProperty<T> {
        let prop = MutableProperty(initValue)
        prop <~ self |> skip(skipCount) |> ignoreError
        return prop
    }
}

func createSamplable<T, ErrorType>(input: SignalProducer<T, ErrorType>) -> (SignalProducer<T, ErrorType>, SignalProducer<(), NoError>) {
    let (sp, sink) = Signal<(), NoError>.pipe()
    return (input |> on(next: { _ in sendNext(sink, ()) } ), sp ->> coldSignalProducer)
}

func ignoreError<T, E>(input: ReactiveCocoa.SignalProducer<T, E>) -> ReactiveCocoa.SignalProducer<T, NoError>{
    return input |> catch{ _ in SignalProducer<T, NoError>.empty }
}

func shadow<A, ErrorType>(input: SignalProducer<A, ErrorType>) -> (SignalProducer<A, ErrorType>, SignalProducer<A, ErrorType>) {
    let (slave, sink) = SignalProducer<A, ErrorType>.buffer(1)
    let master = SignalProducer<A, ErrorType> { observer, disposable in
        input.startWithSignal{ signal, signalDisposable in
            disposable += signalDisposable
            signal.observe(observer)
            signal.observe(sink)
        }
    }
    return (master, slave)
}

func shadowSignal<A, ErrorType>(input: SignalProducer<A, ErrorType>) -> (SignalProducer<A, ErrorType>, Signal<A, ErrorType>) {
    var slave: Signal<A, ErrorType>! = nil
    let master = SignalProducer<A, ErrorType> { observer, disposable in
        input.startWithSignal{ signal, signalDisposable in
            disposable += signalDisposable
            signal.observe(observer)
            slave = signal
        }
    }
    return (master, slave)
}

func getOrElse<A, ErrorType>(elseVal: A)(input: SignalProducer<A?, ErrorType>) -> SignalProducer<A, ErrorType> {
    return input |> map { $0 ?? elseVal }
}

func getOrElse<A, ErrorType>(elseProducer: SignalProducer<A, ErrorType>)(input: SignalProducer<A?, ErrorType>) -> SignalProducer<A, ErrorType> {
    return input |> watch(elseProducer) |> map{ $0.0 ?? $0.1 }
}

func getOrElse<A, ErrorType>(elseProducer: SignalProducer<A?, ErrorType>)(input: SignalProducer<A?, ErrorType>) -> SignalProducer<A?, ErrorType> {
    return input |> watch(elseProducer) |> map{ $0.0 ?? $0.1 }
}

func compact<A, ErrorType>(input: SignalProducer<A?, ErrorType>) -> SignalProducer<A, ErrorType> {
    return input |> filter{ nil != $0 } |> map{ $0! }
}

func compactTuple<A, B, ErrorType>(input: SignalProducer<(A?, B?), ErrorType>) -> SignalProducer<(A, B), ErrorType> {
    return input |> filter { nil != $1 && nil != $0 } |> map { ($0.0!, $0.1!) }
}

func blockEdge<A, ErrorType>(count: Int, predicate: A -> Bool)(input: SignalProducer<A, ErrorType>) -> SignalProducer<A, ErrorType> {
    var hit = -1
    return input |> filter{ hit = predicate($0) ? hit + 1 : -1; return hit >= count || hit < 0 }
}

func passEdge<A, ErrorType>(count: Int, predicate: A -> Bool)(input: SignalProducer<A, ErrorType>) -> SignalProducer<A, ErrorType> {
    var hit = -1
    return input |> filter{ hit = predicate($0) ? hit + 1 : -1; return hit < count }
}

func watch<A, B, ErrorType>(watched: Signal<B, ErrorType>)(input: Signal<A, ErrorType>) -> Signal<(A, B), ErrorType> {
    return Signal{ observer in
        let lock = NSLock()
        lock.name = "tv.kaipai.ReactiveCocoa.watch"
        var lastSaw: B? = nil
        let onError = { sendError(observer, $0) }
        let watchedDisposable = watched.observe(
            error: onError,
            next: {
                lock.lock()
                lastSaw = $0
                lock.unlock()
        })
        let signalDisposable = input.observe(
            error: onError,
            completed: {
                sendCompleted(observer)
            }, interrupted: {
                sendInterrupted(observer)
            }, next: {
                lock.lock()
                if let lastSaw = lastSaw {
                    sendNext(observer, ($0, lastSaw))
                }
                lock.unlock()
        })
        return CompositeDisposable(compact([watchedDisposable, signalDisposable]))
    }
}

func watch<A, B, ErrorType>(watched: SignalProducer<B, ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<(A, B), ErrorType>{
    return input.lift(watch)(watched)
}

func observe<A, ErrorType>(receiver: Signal<A, ErrorType> -> Signal<(A, A -> ()), ErrorType>)(input: Signal<A, ErrorType>) -> Disposable? {
    return receiver(input) |> map(->>) |> observe()
}

func start<A, ErrorType>(receiver: Signal<A, ErrorType> -> Signal<(A, A -> ()), ErrorType>)(input: SignalProducer<A, ErrorType>) -> Disposable? {
    return input |> receiver |> start(next: ->>)
}

func start<A, ErrorType>(receiver: SignalProducer<A, ErrorType> -> SignalProducer<(A, A -> ()), ErrorType>)(input: SignalProducer<A, ErrorType>) -> Disposable? {
    return input |> receiver |> start(next: ->>)
}

func map<A, B, ErrorType>(transform: Signal<A, ErrorType> -> Signal<(A, A -> B), ErrorType>)(input: Signal<A, ErrorType>) -> Signal<B, ErrorType> {
    return input |> transform |> map(->>)
}

func map<A, B, ErrorType>(transform: Signal<A, ErrorType> -> Signal<(A, A -> B), ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<B, ErrorType> {
    return input.lift(map(transform))
}

func map<A, B, ErrorType>(transform: SignalProducer<A, ErrorType> -> SignalProducer<(A, A -> B), ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<B, ErrorType> {
    return input |> transform |> map(->>)
}

func filterByLast<A, ErrorType>(input: Signal<(A, Bool), ErrorType>) -> Signal<A, ErrorType> {
    return input |> filter{ $1 } |> map{ $0.0 }
}

func filterByLast<A, ErrorType>(input: Signal<(A, A -> Bool), ErrorType>) -> Signal<A, ErrorType> {
    return input |> map { ($0.0, $0.1($0.0)) } |> filterByLast
}

func filterByLast<A, B, ErrorType>(predicate: B -> Bool)(input: Signal<(A, B), ErrorType>) -> Signal<A, ErrorType> {
    return input |> filter { predicate($1) } |> map { $0.0 }
}

func filterByFirst<A, ErrorType>(input: Signal<(Bool, A), ErrorType>) -> Signal<A, ErrorType> {
    return input |> filter{ $0.0 } |> map{ $1 }
}

func filterByFirst<A, B, ErrorType>(predicate: A -> Bool)(input: Signal<(A, B), ErrorType>) -> Signal<B, ErrorType> {
    return input |> filter{ predicate($0.0) } |> map { $1 }
}

func filterByFirst<A, ErrorType>(input: Signal<(A -> Bool, A), ErrorType>) -> Signal<A, ErrorType> {
    return input |> map { ($0.0($0.1), $0.1) } |> filterByFirst
}

func filterWith<A, ErrorType>(pass: Signal<A, ErrorType> -> Signal<(A, Bool), ErrorType>)(input: Signal<A, ErrorType>) -> Signal<A, ErrorType> {
    return input |> pass |> filterByLast
}

func filterWith<A, ErrorType>(pass: Signal<A, ErrorType> -> Signal<(A, Bool), ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<A, ErrorType> {
    return input.lift(pass) |> filterByLast
}

func filterWith<A, ErrorType>(pass: SignalProducer<A, ErrorType> -> SignalProducer<(A, Bool), ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<A, ErrorType> {
    return input |> pass |> filterByLast
}

func mergeWith<A, B, C, ErrorType>(merger: Signal<A, ErrorType> -> Signal<(A, B), ErrorType>, transform: (A, B) -> C)(input: Signal<A, ErrorType>) -> Signal<C, ErrorType> {
    return input |> merger |> map(transform)
}

func mergeWith<A, B, C, ErrorType>(merger: Signal<A, ErrorType> -> Signal<(A, B), ErrorType>, transform: (A, B) -> C)(input: SignalProducer<A, ErrorType>) -> SignalProducer<C, ErrorType> {
    return input.lift(mergeWith(merger, transform))
}

func mergeWith<A, B, C, ErrorType>(merger: SignalProducer<A, ErrorType> -> SignalProducer<(A, B), ErrorType>, transform: (A, B) -> C)(input: SignalProducer<A, ErrorType>) -> SignalProducer<C, ErrorType> {
    return input |> merger |> map(transform)
}

func flatMapLatest<A, B, C, ErrorType>(strategy: FlattenStrategy, transform: A -> SignalProducer<B, ErrorType>, operate: SignalProducer<B -> C, ErrorType>)(input: SignalProducer<A, ErrorType>) -> SignalProducer<C, ErrorType> {
    return combineLatest(input, operate) |> flatMap(strategy){ inp, op in transform(inp) |> map(op) }
}

//func mergeWith<A, ErrorType>(mergedWith: Signal<A, ErrorType>)(input: Signal<A, ErrorType>) -> Signal<A, ErrorType> {
//    return Signal{ sink in
//        let compDis = CompositeDisposable()
//        compDis += input |> observe(sink)
//        compDis += mergedWith |> observe(sink)
//        return compDis
//    }
//}
//

func combineLatest<A, B>(prop1: MutableProperty<A>, prop2: MutableProperty<B>) -> MutableProperty<(A, B)> {
    let tuple = (prop1.value, prop2.value)
    let prop = MutableProperty(tuple)
    combineLatest(prop1.producer, prop2.producer) |> skip(1) |> start(next: prop.put)
    return prop
}

func coldSignalProducer<A, ErrorType>(signal: Signal<A, ErrorType>) -> SignalProducer<A, ErrorType> {
    return SignalProducer{ sink, disposable in
        disposable += signal.observe(sink)
    }
}





func racLogger<T, ErrorType>(tag: String)(input: SignalProducer<T, ErrorType>) -> SignalProducer<T, ErrorType> {
    return input |> on(next: { println(tag + " \($0)") })
}

func side<A, T>(@noescape startHandler: () -> A)(endHandler: A -> T ->()) -> T -> T {
    return Cont<T -> (), T -> T>.unit(endHandler(startHandler()))(){ handleEnd in { handleEnd($0); return $0 } }
}

func side<T>(handler: T ->()) -> T -> T{
    return { handler($0); return $0 }
}

func timeLogger<T>(_ prefix: String = "") -> T -> T {
    return Curry.c{ "\(prefix) used \(NSDate.timeIntervalSinceReferenceDate() - $0.0)" ->> println } ->> side(NSDate.timeIntervalSinceReferenceDate)
}

class LOGGER<T> {
    static func l(_ prefix: String = "") -> T -> T{
        return { prefix + " \($0)" ->> println } ->> side
    }
    
}



func logger<T>(_ prefix: String = "") -> T -> T{
    return { prefix + " \($0)" ->> println } ->> side
}


public func identity<T>(type: T.Type) -> T -> T {
    return { $0 }
}

public func identity<T>(t: T) -> T {
    return t
}

//Helper class for circumventing Swift's generic limits
public class Cont<A, Result> {
    public typealias Eval = A -> Result
    public typealias Continuation = Eval -> Result
    public typealias ResultMap = Result -> Result
    
    public static func create(f: Continuation) -> Continuation {
        return f
    }
    
    public static func unit(a: A) -> Continuation {
        return { $0(a) }
    }
    
    public static func bind<B> (lhs: Continuation, _ rhs: A -> Cont<B, Result>.Continuation) -> Cont<B, Result>.Continuation {
        return { b2c in lhs{ rhs($0)(b2c) } }
    }
    
    public static func map(lhs: Continuation, _ rhs: ResultMap) -> Continuation {
        return { rhs(lhs($0)) }
    }
    
    public static func with<B>(lhs: Continuation, _ rhs: Cont<B, Result>.Eval -> Eval) -> Cont<B, Result>.Continuation {
        return { lhs(rhs($0)) }
    }
    
    
    public static func exit<B>(f: (A -> Cont<B, Result>.Continuation) -> Continuation) -> Continuation {
        return { eval in f{ a in { _ in eval(a)} }(eval) }
    }
    
}


func ->><A, B, Result>(lhs: Cont<A, Result>.Continuation, rhs: Cont<B, Result>.Eval -> Cont<A, Result>.Eval) -> Cont<B, Result>.Continuation {
    return Cont<A, Result>.with(lhs, rhs)
}


public struct ContW<A, Result> {
    private typealias CP = Cont<A, Result>
    let c: CP.Continuation
    
    public static func create(c: CP.Continuation) -> ContW{
        return ContW(c: c)
    }
    
    func bind<B> (to: A -> ContW<B, Result>) -> ContW<B, Result> {
        return bind{ to($0).c }
    }
    
    func bind<B> (to: A -> Cont<B, Result>.Continuation) -> ContW<B, Result> {
        return ContW<B, Result>(c: CP.bind(c, to))
    }
    
    func map(to: CP.ResultMap) -> ContW {
        return ContW(c: CP.map(c, to))
    }
    
    func with<B>(with: Cont<B, Result>.Eval -> CP.Eval) -> ContW<B, Result> {
        return ContW<B, Result>(c: CP.with(c, with))
    }
}


//func test(name: String){
//    let res = Cont<String, String>.exit { ex in
//        ex(name) ->> { _ in Cont.unit("hello") }
//     }(identity)
//}


