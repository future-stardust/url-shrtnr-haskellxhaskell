{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Models where

import Control.Monad.Reader
import Data.Binary (Binary)
import Data.Aeson
import Data.Text (Text)
import GHC.Generics
import Servant
import qualified Servant.Auth.Server as SAS

data User = User
  { userEmail :: Email,
    userHash :: PasswordHash
  }
  deriving (Show, Eq, Read, Generic)

instance Ord User where
    compare x y = compare (userEmail x) (userEmail y)

instance Binary User

instance ToJSON User

instance FromJSON User

instance SAS.ToJWT User

instance SAS.FromJWT User

data Alias = Alias
  { aliasOrigin :: AliasOrigin,
    aliasName :: AliasName,
    aliasAuthor :: Email
  }
  deriving (Show, Eq, Generic)

instance Ord Alias where
    compare x y = compare (aliasName x) (aliasName y)

instance Binary Alias

instance ToJSON Alias

instance FromJSON Alias

type Password = Text

type PasswordHash = Text

type Email = Text

type AliasName = Text

type AliasOrigin = Text

data AppConfig = AppConfig
  { appPort :: !Int,
    appDbPath :: !String
  }

data AppError = RegistrationError | DeletingError | CreatingError
  deriving (Show, Eq)
