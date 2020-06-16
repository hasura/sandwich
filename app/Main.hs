module Main where

import Control.Concurrent
import Control.Concurrent.Async
import Control.Monad.Trans.Reader
import Control.Scheduler
import System.Posix.Signals
import Test.Sandwich
import Test.Sandwich.Formatters.TerminalUI
import Test.Sandwich.Interpreters.FilterTree
import Test.Sandwich.Interpreters.PrettyShow
-- import Test.Sandwich.Interpreters.RunTreeScheduler
import Test.Sandwich.Interpreters.RunTree
import Test.Sandwich.Types.Example
import Test.Sandwich.Types.Formatter
import Test.Sandwich.Types.Options
import Test.Sandwich.Types.Spec


topSpec :: TopSpec
topSpec = do
  afterEach "after each" (\() -> putStrLn "after") $ do
    beforeEach "before each" (\() -> putStrLn "before") $ do
      it "does the first thing" pending
      it "does the second thing" pending
      it "does the third thing" pending
      describe "nested stuff" $ do
        it "does a nested thing" pending

  around "some around" (\context action -> putStrLn "around1" >> action >> putStrLn "around2") $ do
    it "does 1" pending
    it "does 2" pending

  introduce "Intro a string" (\() -> getLine) (\_ -> return ()) $ do
    it "uses the string" $ \(str :> ()) -> do
      putStrLn $ "Got the string: " <> str
      return Success

    it "uses the string again" $ \(str :> ()) -> do
      putStrLn $ "Got the string here: " <> str
      return Success

  it "does a thing" $ \() -> do
    putStrLn "HI"
    return Success

  describe "it does this thing also" $ do
    it "does a sub-test" pending

  describeParallel "it does this thing also" $ do
    it "does a first sub-test 1" pending
    it "does a sub-test 2" pending
    it "does a sub-test 3" pending



sleepThenSucceed _ = do
  threadDelay (2 * 10^6)
  return Success

sleepThenFail _ = do
  threadDelay (2 * 10^6)
  return $ Failure Nothing (ExpectedButGot "2" "3")

simple :: TopSpec
simple = do
  it "does the first thing" sleepThenSucceed
  it "does the second thing" sleepThenFail
  it "does the third thing" sleepThenSucceed

medium :: TopSpec
medium = describe "implicit outer" $ do
  it "does the first thing" sleepThenSucceed
  it "does the 1.5 thing" sleepThenFail
  it "does the 1.8 thing" sleepThenFail
  describe "should happen sequentially" $ do
    it "sequential 1" sleepThenSucceed
    it "sequential 2" sleepThenSucceed
    it "sequential 3" sleepThenSucceed
  describeParallel "should happen in parallel" $ do
    it "sequential 1" sleepThenSucceed
    it "sequential 2" sleepThenSucceed
    it "sequential 3" sleepThenSucceed

  introduce "Database" (\() -> makeDB) (\(db :> ()) -> cleanupDB db) $ do
    it "uses the DB 1" $ \(db :> ()) -> do
      return Success

    it "uses the DB 2" $ \(db :> ()) -> do
      return Success

  it "does the second thing" sleepThenFail
  it "does the third thing" sleepThenSucceed

mainFilter :: IO ()
mainFilter = putStrLn $ prettyShow $ filterTree "also" topSpec

mainPretty :: IO ()
mainPretty = putStrLn $ prettyShow topSpec

runSandwich :: (Formatter f) => Options -> f -> TopSpec -> IO ()
runSandwich options f spec = do
  asyncUnit <- async $ return ()
  rts <- runReaderT (runTreeMain spec) $ RunTreeContext {
    runTreeContext = asyncUnit
    , runTreeOptions = options
    }

  formatterAsync <- async $ runFormatter f rts

  let shutdown = do
        putStrLn "TODO: shut down!"
        cancel formatterAsync

  _ <- installHandler sigINT (Catch shutdown) Nothing

  wait formatterAsync


main :: IO ()
-- main = runSandwich defaultOptions defaultTerminalUIFormatter simple
main = runSandwich defaultOptions defaultTerminalUIFormatter medium

data Database = Database deriving Show

makeDB :: IO Database
makeDB = return Database

cleanupDB :: Database -> IO ()
cleanupDB _ = return ()
