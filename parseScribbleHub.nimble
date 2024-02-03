version       = "0.1.0"
author        = "levovix0"
description   = "scribblehub.com parser"
license       = "MIT"
srcDir        = "src"
bin           = @["parseScribbleHub"]

requires "nim >= 2.0.0"
requires "localize >= 0.3", "fusion", "argparse"
