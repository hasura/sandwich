-- |

module Test.Sandwich.Options (
  Options
  , defaultOptions

  -- * Artifacts
  , optionsTestArtifactsDirectory
  , TestArtifactsDirectory(..)

  -- * Logging
  , optionsSavedLogLevel
  , optionsMemoryLogLevel

  -- * Formatting
  , optionsFormatters
  , SomeFormatter(..)
  , Formatter(..)

  -- * Filtering
  , optionsFilterTree
  , TreeFilter(..)
  ) where

import Control.Monad.Logger
import Test.Sandwich.Formatters.Print
import Test.Sandwich.Types.RunTree

-- | A reasonable default set of options.
defaultOptions :: Options
defaultOptions = Options {
  optionsTestArtifactsDirectory = TestArtifactsNone
  , optionsSavedLogLevel = Just LevelDebug
  , optionsMemoryLogLevel = Just LevelDebug
  , optionsFilterTree = Nothing
  , optionsDryRun = False
  , optionsFormatters = [SomeFormatter defaultPrintFormatter]
  }
