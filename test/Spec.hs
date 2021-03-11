{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TypeSynonymInstances #-}

module Main (main) where

import Authentication
import Control.Exception (evaluate)
import Control.Monad.Reader
import Control.Monad.State (State)
import qualified Control.Monad.State as State
import Data.List
import qualified Data.Text as Text
-- import Test.Hspec.Wai
-- import Test.Hspec.Wai.JSON

import Urls
import Models
import Test.Hspec
import Typeclasses

main :: IO ()
main = hspec $ do
  registerUserSpec
  redirectUserSpec

type TestState = ([User], [Alias])

type TestM = ReaderT AppConfig (State TestState)

instance Hasher TestM where
  hashPassword = pure . Just
  validatePassword hash pass = pure (hash == pass)

instance Database TestM where
  getAllUsers = State.gets fst
  getAllAliases = State.gets snd

  addUser user = do
    (users, aliases) <- State.get
    State.put (user : users, aliases)
  lookupUser email = do
    (users, _) <- State.get
    pure $ find (\x -> userEmail x == email) users
  removeUser email = do
    (users, aliases) <- State.get
    State.put (filter (\x -> userEmail x == email) users, aliases)

  addAlias alias = do
    (users, aliases) <- State.get
    State.put (users, alias : aliases)
  lookupAlias alias = do
    (_, aliases) <- State.get
    pure $ find (\x -> aliasName x == alias) aliases
  removeAlias alias = do
    (users, aliases) <- State.get
    State.put (users, filter (\x -> aliasName x == alias) aliases)

defaultAppConfig :: AppConfig
defaultAppConfig = AppConfig 3001

runTest :: AppConfig -> TestState -> TestM r -> (r, TestState)
runTest config state m = State.runState (runReaderT m config) state

runEmptyTest :: TestM r -> (r, TestState)
runEmptyTest = runTest defaultAppConfig ([], [])

registerUserSpec =
  describe "Authentication.registerUser" $ do
    let email = Text.pack "email"
        pass = Text.pack "pass"
    it "successfully creates a new user" $ do
      snd (runEmptyTest (registerUser email pass))
        `shouldBe` ([User email pass], [])

    it "returns an error when the user is already registered" $ do
      fst (runTest defaultAppConfig ([User email pass], []) (registerUser email pass))
        `shouldBe` Left RegistrationError

redirectUserSpec =
  describe "Urls.redirectUser" $ do
    let aName = Text.pack "alias"
        aOrigin = Text.pack "https://google.com"
        aUser = Text.pack "email"
    it "returns Nothing when the user requested nonexistent alias" $ do
      fst (runEmptyTest (redirectUser aName))
        `shouldBe` Nothing
    it "returns Just url when the user requested a valid alias" $
      fst (runTest defaultAppConfig ([], [Alias aOrigin aName aUser]) (redirectUser aName))
        `shouldBe` Just aOrigin
