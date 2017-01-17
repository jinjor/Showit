import System.Environment
import System.Directory
import System.IO
import System.Exit
import Parse
import Generate
import Evaluate

import Text.ParserCombinators.Parsec as Parsec
import Data.Map as Map

main = do
  parseTest module'   ":def | foo"
  parseTest module'   ":foo"
  parseTest module'   ":foo| bar "
  parseTest module'   ":foo|bar\n  baz"
  parseTest module'   "  :foo"
  parseTest module'   "  :foo|bar"
  parseTest module'   "  :foo|bar\n    baz"
  parseTest module'   ":foo\n  :bar\n    baz"
  parseTest module'   ".foo"
  parseTest module'   ".foo(1)"
  parseTest module'   "text"
  parseTest module'   "text bar"
  parseTest module'   ":foo\n  :bar\n    baz\n  hoge\n"
  parseTest module'   ":def\n  :bar\n    baz\n  hoge\n"
  parseTest module'   ":yey | show\n  .hide(1) | $2"
  parseTest nodeFuncName  ".hide(1)"
  parseTest animationIndex  "(1)"
  parseTest (expression "")  "1"
