{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
module FirstApp.Types
  ( Error (..)
  , RqType (..)
  , ContentType (..)
  -- Exporting newtypes like this will hide the constructor.
  , Topic (getTopic)
  , CommentText (getCommentText)
  , Comment (..)
  -- We provide specific constructor functions.
  , mkTopic
  , mkCommentText
  , renderContentType
  , fromDbComment
  ) where

import           GHC.Generics                       (Generic)

import           Data.ByteString                    (ByteString)
import           Data.Text                          (Text)

import           Data.List                          (stripPrefix)
import           Data.Maybe                         (fromMaybe)

import           Data.Aeson                         (ToJSON (..))
import qualified Data.Aeson                         as A
import qualified Data.Aeson.Types                   as A

import           Data.Time                          (UTCTime)

newtype Topic = Topic { getTopic :: Text }
  deriving (Show, ToJSON)

newtype CommentText = CommentText { getCommentText :: Text }
  deriving (Show, ToJSON)

-- This is the Comment record that we will be sending to users, it's a simple
-- record type, containing an Int, Topic, CommentText, and UTCTime. However notice
-- that we've also derived the Generic type class instance as well. This saves us
-- some effort when it comes to creating encoding/decoding instances. Since our
-- types are all simple types at the end of the day, we're able to just let GHC do
-- the work.
--
-- Is an 'Int' acceptable here?
data Comment = Comment { ... }
  deriving ( Show, Generic )

instance ToJSON Comment where
  -- This is one place where we can take advantage of our Generic instance. Aeson
  -- already has the encoding functions written for anything that implements
  -- the Generic typeclass. So we don't have to write our encoding, we just ask
  -- Aeson to construct it for us.
  toEncoding = A.genericToEncoding opts
    where
      -- These options let us make some minor adjustments to how Aeson treats
      -- our type. Our only adjustment is to alter the field names a little, to
      -- remove the 'comment' prefix and camel case what is left of the name.
      -- This accepts any 'String -> String' function but it's good to keep the
      -- modifications simple.
      opts = A.defaultOptions
             { A.fieldLabelModifier = modFieldLabel
             }
      -- Strip the prefix (which may fail if the prefix isn't present), fall
      -- back to the original label if need be, then camel-case the name.
      modFieldLabel l = error "modFieldLabel not implemented"

-- For safety we take our stored DbComment and try to construct a Comment that
-- we would be okay with showing someone. However unlikely it may be, this is a
-- nice method for separating out the back and front end of a web app and
-- providing greater guaranteees about data cleanliness.
fromDbComment
  :: DbComment
  -> Either Error Comment
fromDbComment dbc =
  error "fromDbComment not yet implemented"

-- Having specialised constructor functions for the newtypes allows you to set
-- restrictions for your newtype.
nonEmptyText
  :: (Text -> a)
  -> Error
  -> Text
  -> Either Error a
nonEmptyText _ e "" = Left e
nonEmptyText c _ tx = Right (c tx)

mkTopic
  :: Text
  -> Either Error Topic
mkTopic =
  nonEmptyText Topic EmptyTopic

mkCommentText
  :: Text
  -> Either Error CommentText
mkCommentText =
  nonEmptyText CommentText EmptyCommentText

data RqType
  = AddRq Topic CommentText
  | ViewRq Topic
  | ListRq

data Error
  = UnknownRoute
  | EmptyCommentText
  | EmptyTopic
  -- | DBError SQLiteResponse
  deriving Show

data ContentType
  = PlainText
  | JSON

-- The ContentType description for a header doesn't match our data definition
-- so we write a little helper function to pattern match on our ContentType
-- value and provide the correct header value.
renderContentType
  :: ContentType
  -> ByteString
renderContentType PlainText = "text/plain"
renderContentType JSON      = "text/json"