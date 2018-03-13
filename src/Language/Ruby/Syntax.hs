{-# LANGUAGE DeriveAnyClass #-}
module Language.Ruby.Syntax where

import Data.Abstract.Environment
import Data.Abstract.Evaluatable
import Diffing.Algorithm
import Prelude hiding (fail)
import Prologue
import qualified Data.Map as Map
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString as B (filter)
import Data.Char (ord)

data Require a = Require { requirePath :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Ord, Show, Traversable, FreeVariables1)

instance Eq1 Require where liftEq = genericLiftEq
instance Ord1 Require where liftCompare = genericLiftCompare
instance Show1 Require where liftShowsPrec = genericLiftShowsPrec

instance Evaluatable Require where
  eval (Require path) = do
    v <- subtermValue path
    path <- getString v
    importedEnv <- withGlobalEnv mempty (require (pathToQualifiedName path))
    modifyGlobalEnv (flip (Map.foldrWithKey envInsert) (unEnvironment importedEnv))
    unit
    where
      pathToQualifiedName :: ByteString -> Name
      pathToQualifiedName = qualifiedName . BC.split '/' . (BC.dropWhile (== '/')) . (BC.dropWhile (== '.')) . stripQuotes

      stripQuotes :: ByteString -> ByteString
      stripQuotes = B.filter (/= (fromIntegral (ord '\"')))
