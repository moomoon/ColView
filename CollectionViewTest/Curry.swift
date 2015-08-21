//
//  Curry.swift
//  kaipai2
//
//  Created by Jia Jing on 7/22/15.
//  Copyright (c) 2015 Yang Yi. All rights reserved.
//

import Foundation


class Curry {
    static func c<A, B, C>(function: (A, B) -> C) -> A -> B -> C {
        return { a in { b in function(a, b) } }
    }
    
    static func c<A, B, C, D>(function: (A, B, C) -> D) -> A -> B -> C -> D {
        return { a in { b in { c in function(a, b, c) } } }
    }
    
    static func c<A, B, C, D, E>(function: (A, B, C, D) -> E) -> A -> B -> C -> D -> E {
        return { a in { b in { c in { d in function(a, b, c, d) } } } }
    }
    
    static func c<A, B, C, D, E, F>(function: (A, B, C, D, E) -> F) -> A -> B -> C -> D -> E -> F {
        return { a in { b in { c in { d in { e in function(a, b, c, d, e) } } } } }
    }
    
    static func c<A, B, C, D, E, F, G>(function: (A, B, C, D, E, F) -> G) -> A -> B -> C -> D -> E -> F -> G {
        return { a in { b in { c in { d in { e in { f in function(a, b, c, d, e, f) } } } } } }
    }
    
}