cg = require '../src/bootstrap/codeGenerator/codeGenerator'.code generator ()
require './assertions'
term = (require '../lib/terms') {}.term
_ = require 'underscore'
assert = require 'assert'

(actual list) should only have (expected list) =
    actual list.length.should.equal (expected list.length)

    for each @(item) in (expected list)
        _.include(actual list, item).should.be

/* terms:
  
   terms are objects (aka hashes)
   terms can contain arrays, numbers and strings, or other things, but
   only objects are terms.
  
   terms can have prototypes, in in fact prototypes are where terms
   get most of their behaviour.

   Terms can be cloned. This means that their prototype is copied,
   as well as any subterms (object fields). Arrays are copied too.

   Terms can have a location. And terms that derive from that term
   take a copy of that location, so they can be traced back to the
   originating source code.

   Terms can be derived from another term.

   Terms can be rewritten while they are cloned. Rewriting a term
   effectively derives the term's rewrite.
*/

describe 'terms'
    describe 'cloning'
        it 'creates a new object'
            t = new (term)

            new term = t.clone ()

            new term.should.not.equal (t)

        it 'copies all members when cloning'
            t = new (term)
            t.a = 1
            t.b = "b"

            clone = t.clone ()
            (clone) should contain fields {
                a = 1
                b = "b"
            }

        it 'arrays are also cloned'
            t = new (term)
            t.array = [1]

            clone = t.clone ()
            
            clone.array.should.not.equal (t.array)
            (clone) should contain fields {
                array = [1]
            }

        it "an object's prototype is also copied"
            t = new (term)
            t.a = 'a'

            clone = t.clone ()
            Object.get prototype of (clone).should.equal (Object.get prototype of (t))

        it "clones sub-objects"
            t = new (term)
            t.a = {name = "jack"}

            clone = t.clone ()
            
            (clone) should contain fields {
                a = {name = "jack"}
            }

        it "doesn't clone objects that have 'dont clone' field"
            t = new (term)
            t.a = {name = "jack"}
            t.dont clone = true

            clone = t.clone ()
            
            clone.should.equal (t)

        it "can rewrite an object while being cloned"
            t = new (term)
            t.a = new (term {name = "jack"})

            clone = t.clone (
                rewrite (old term):
                    if (old term.name)
                        new term = new (term)
                        new term.name = "jill"
                        new term
            )
            
            (clone) should contain fields {
                a = {name = "jill"}
            }

        it "rewrite is passed the clone function, which can be used to clone further members"
            t = new (term)
            t.a = new (term {
                name = "jack"
                b = new (term {
                    name = "john"
                })
            })

            clone = t.clone (
                rewrite (old term, clone: nil):
                    if (old term.name)
                        new term = new (term)
                        new term.name = "jill"
                        
                        if (old term.b)
                            new term.b = clone (old term.b)

                        new term
            )
            
            (clone) should contain fields {
                a = {
                    name = "jill"
                    b = {name = "jill"}
                }
            }

        it "doesn't rewrite beyond rewrite limit"
            t = new (term {
                a = new (term {name = "jack"})
                b = new (term {
                    is limit
                    c = new (term {name = "jack"})
                })
                d = new (term {name = "jason"})
            })

            clone = t.clone (
                rewrite (old term):
                    if (old term.name)
                        new (term {name = "jill"})

                limit (t):
                    t.is limit
            )
            
            (clone) should contain fields {
                a = {name = "jill"}
                b = {
                    c = {name = "jack"}
                }
                d = {name = "jill"}
            }

        it "throws an exception when the new term is not an instance of 'term'"
            t = new (term)
            t.a = new (term {name = "jack"})

            @{t.clone (
                rewrite (old term):
                    if (old term.name)
                        {name = "jill"}
            )}.should.throw "rewritten term not an instance of term"
            
        it 'copies the location when a term is rewritten'
            t = new (term)
            t.set location {first line = 1, last line = 1, first column = 20, last column = 30}
            
            clone = t.clone (
                rewrite (old term): 
                    t = new (term)
                    t.rewritten = true
                    t
            )

            (clone) should contain fields {
                rewritten = true
            }
            (clone.location ()) should contain fields {
                first line = 1
                last line = 1
                first column = 20
                last column = 30
            }
            
        it 'passes path of terms to limit'
            c = new (term)
            b = new (term {
                c = c
            })
            a = new (term {
                b = b
            })

            y = new (term)
            x = new (term {
                y = y
            })

            t = new (term {
                a = a
                x = x
            })

            paths = []

            clone = t.clone (
                limit (old term, path: nil): 
                    paths.push (path.slice ())
                    false
            )

            (paths) should only have [
                []
                [t]
                [t, a]
                [t, a, b]
                [t, x]
                [t, x, y]
            ]
            
        it 'passes path of terms to rewrite'
            c = new (term)
            b = new (term {
                c = c
            })
            a = new (term {
                b = b
            })

            y = new (term)
            x = new (term {
                y = y
            })

            t = new (term {
                a = a
                x = x
            })

            paths = []

            clone = t.clone (
                rewrite (old term, path: nil): 
                    paths.push (path.slice ())
                    nil
            )

            (paths) should only have [
                []
                [t]
                [t, a]
                [t, a, b]
                [t, x]
                [t, x, y]
            ]

    describe 'location'
        it 'can set location'
            t = new (term)
            t.set location {first line = 1, last line = 2, first column = 20, last column = 30}

            (t.location ()) should contain fields {
                first line = 1
                last line = 2
                first column = 20
                last column = 30
            }

        it 'can compute location from children, first column is from first line, last column is from last line'
            left = new (term)
            left.set location {first line = 1, last line = 2, first column = 20, last column = 30}

            right = new (term)
            right.set location {first line = 2, last line = 4, first column = 30, last column = 10}

            t = new (term {
                left = left
                right = right
            })

            (t.location ()) should contain fields {
                first line = 1
                last line = 4
                first column = 20
                last column = 10
            }

        it 'if there are no children then the location is nil'
            t = new (term)

            assert.(t.location ()) strict equal (nil)

        it 'if there are no children with locations then the location is nil'
            left = new (term)
            right = new (term)

            t = new (term {
                left = left
                right = right
            })

            assert.(t.location ()) strict equal (nil)

        it 'can compute location from children, smallest first column, largest last column when on same line'
            left = new (term)
            left.set location {first line = 1, last line = 2, first column = 20, last column = 30}

            right = new (term)
            right.set location {first line = 1, last line = 2, first column = 10, last column = 40}

            t = new (term {
                left = left
                right = right
            })

            (t.location ()) should contain fields {
                first line = 1
                last line = 2
                first column = 10
                last column = 40
            }

    describe 'children'
        it 'returns immediate subterms'
            a = new (term)
            b = new (term)

            t = new (term {
                a = a
                b = b
            })

            (t.children ()) should only have [a, b]

    describe 'children'
        it 'returns terms in arrays'
            a = new (term)
            b = new (term)

            t = new (term {
                array = [a, b]
            })

            (t.children ()) should only have [a, b]

    describe 'children'
        it 'returns terms in objects'
            a = new (term)
            b = new (term)

            t = new (term {
                array = {a = a, b = b}
            })

            (t.children ()) should only have [a, b]

    describe 'walk descendants'
        it "walks descendants, children, children's children, etc"
            b = new (term)
            c = new (term)
            d = new (term)
            a = new (term {
                c = c
                d = [d]
            })

            t = new (term {
                a = a
                b = b
            })

            descendants = []

            t.walk descendants @(subterm)
                descendants.push (subterm)

            (descendants) should only have [a, b, c, d]

        it "walks descendants, but not beyond the limit"
            b = new (term)
            c = new (term)
            d = new (term)
            a = new (term {
                is a
                c = c
                d = [d]
            })

            t = new (term {
                a = a
                b = b
            })

            descendants = []

            t.walk descendants @(subterm)
                descendants.push (subterm)
            not below @(subterm) if
                subterm.is a

            (descendants) should only have [a, b]
