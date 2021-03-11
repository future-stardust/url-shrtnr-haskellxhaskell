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
import Handlers
import Models
import Network.Wai.Handler.Warp
import Servant
import Servant.Auth.Server
import StorageSpec
import System.Directory
import System.IO.Temp
import Test.Hspec
import Test.Hspec.Wai
import Test.Hspec.Wai.JSON
import Typeclasses
import Urls

main :: IO ()
main = do
  -- jwtKey <- generateKey
  -- let port = 3000
  hspec $ do
    registerUserSpec
    redirectUserSpec
    signinCheckSpec
    storageAddAliasSpec
    storageAddUserSpec
    storageGetAllAliasesSpec
    storageGetAllUsersSpec
    storageLookupAliasSpec
    storageLookupUserSpec
    storageRemoveAliasSpec
    storageRemoveUserSpec
    -- handlersSpec jwtKey port

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
    case find (\x -> userEmail x == userEmail user) users of
      Just _ -> pure Nothing
      Nothing -> do
        State.put (user : users, aliases)
        pure $ Just ()
  lookupUser email = do
    (users, _) <- State.get
    pure $ find (\x -> userEmail x == email) users
  removeUser email = do
    (users, aliases) <- State.get
    case find (\x -> userEmail x == email) users of
      Just _ -> pure Nothing
      Nothing -> do
        State.put (filter (\x -> userEmail x == email) users, aliases)
        pure $ Just ()

  addAlias alias = do
    (users, aliases) <- State.get
    case find (\x -> aliasName x == aliasName alias) aliases of
      Just _ -> pure Nothing
      Nothing -> do
        State.put (users, alias : aliases)
        pure $ Just ()
  lookupAlias alias = do
    (_, aliases) <- State.get
    pure $ find (\x -> aliasName x == alias) aliases
  removeAlias alias = do
    (users, aliases) <- State.get
    case find (\x -> aliasName x == alias) aliases of
      Just _ -> pure Nothing
      Nothing -> do
        State.put (users, filter (\x -> aliasName x == alias) aliases)
        pure $ Just ()

defaultAppConfig :: AppConfig
defaultAppConfig = AppConfig 3001 ""

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

signinCheckSpec =
  describe "Authentication.signinUser" $ do
    let email = Text.pack "email"
        pass = Text.pack "pass"
    it "returns True when the user's credentials are valid" $ do
      fst (runTest defaultAppConfig ([User email pass], []) (signinCheck email pass))
        `shouldBe` True

    it "returns False when the user's credentials are invalid" $ do
      let anotherPass = Text.pack "another_pass"
      fst (runTest defaultAppConfig ([User email anotherPass], []) (signinCheck email pass))
        `shouldBe` False

    it "returns False when there are no users with the given email" $ do
      fst (runEmptyTest (signinCheck email pass))
        `shouldBe` False

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

-- handlersSpec jwtKey port = with (pure app) $ do
--   describe "POST /users/signup" $ do
--     it "responds with 400 when the request is malformed" $ do
--       withTempDirectory "/tmp" "hspec." $ \dir -> do
--         with (pure $ app dir) $ do
--           post "/users/signup" "" `shouldRespondWith` 400
--     -- it "responds with 201" $ do
--     --   withTempDirectory "/tmp" "hspec." $ \dir -> do
--     --     with (pure $ app dir) $ do
--     --       createDirectory (dir ++ "/link")
--     --       createDirectory (dir ++ "/user")
--     --       post "/users/signup?email=hello@tempmail.com&password=12345" "" `shouldRespondWith` 201
--   where
--     jwtCfg = defaultJWTSettings jwtKey
--     cookieCfg = defaultCookieSettings
--     cfg = cookieCfg :. jwtCfg :. EmptyContext
--     app dir = do
--       liftIO $ createDirectory (dir ++ "/link")
--       liftIO $ createDirectory (dir ++ "/user")
--       mkApp cfg cookieCfg jwtCfg (AppConfig port dir)
