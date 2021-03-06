{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

module Typeclasses where

import Control.Monad.IO.Class
import Models

type family Key a where
  Key User = Email
  Key Alias = AliasName

class (Monad m) => Database m where
  getAllUsers :: m [User]
  getAllAliases :: m [Alias]

  addUser :: User -> m (Maybe ())
  lookupUser :: Key User -> m (Maybe User)
  removeUser :: Key User -> m (Maybe ())

  addAlias :: Alias -> m (Maybe ())
  lookupAlias :: Key Alias -> m (Maybe Alias)
  removeAlias :: Key Alias -> m (Maybe ())

class (Monad m) => Logger m where
  logInfo :: String -> m ()
  logWarning :: String -> m ()
  logError :: String -> m ()

class (Monad m) => Hasher m where
  hashPassword :: Password -> m (Maybe PasswordHash)
  validatePassword :: PasswordHash -> Password -> m Bool
  hashLink :: AliasOrigin -> m AliasName