global: object (members) =
  c! =
    members: call (this)
    undefined
  
  new (c!)

global: object extending (base, members) =
  c! =
    members: call (this)
    undefined
  
  c: prototype = base
  
  new (c!)