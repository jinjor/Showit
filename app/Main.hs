module Main where

import System.Environment
import System.Directory
import System.IO
import System.Exit
import Parse
import Generate
import Evaluate


main = do
  args <- getArgs
  case args of
    [] ->
      error "file name is not passed!"

    filePath : _ -> do
      dir <- getCurrentDirectory
      file <- readFile $ dir ++ "/" ++ filePath
      case parse file of
        Left err -> do
          hPutStrLn stderr $ show err
          exitFailure

        Right mod ->
          case evaluate mod of
            Left err -> do
              hPutStrLn stderr $ show err
              exitFailure

            Right v -> do
              putStrLn $ generate v
              exitSuccess
              -- writeFile (dir ++ "/data.js") $ generate (evaluate mod)
