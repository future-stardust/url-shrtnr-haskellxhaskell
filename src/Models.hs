{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Models where

import Control.Monad.Reader
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

instance ToJSON User

instance FromJSON User

instance SAS.ToJWT User

instance SAS.FromJWT User

data Alias = Alias
  { aliasOrigin :: Text,
    aliasAlias :: Text,
    aliasAuthor :: Email
  }
  deriving (Show, Eq, Generic)

instance ToJSON Alias

instance FromJSON Alias

type Password = Text

type PasswordHash = Text

type Email = Text

data AppConfig = AppConfig
  { appPort :: !Int
  }

type AppM = ReaderT AppConfig Handler
