express = require 'express'
require '../bootstrap/runtime.pogo'

web server (methods, port: 3000) =
    app = express.create server()

    app context = object =>
        self.get (path, action) =>
            app.get (path) @(req, res)
                request context = object =>
                    self.request = req
                    self.response = res
                
                res.send (action.call (request context))
    
    methods.call (app context)
    app.listen (port)
    console.log "hosting at http://localhost:#(port)/"

web server (port: 4567) =>
    self.get '/' =>
        "Hello World\n"

