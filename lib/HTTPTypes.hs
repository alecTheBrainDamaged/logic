{-# LANGUAGE OverloadedStrings #-}

module HTTPTypes where 

import qualified Network.Socket as NS
import qualified Network.Socket.ByteString as NSB
import qualified Network.TLS as TLS
import qualified Data.ByteString as BS
import qualified Data.Map.Strict as Map
import qualified Control.Monad as CM

data HTTPResponse = HTTPResponse
          { statusLine :: StatusLine
          , headersHR :: Headers
          , body :: BS.ByteString 
          }
          deriving (Show, Eq)

data StatusLine = StatusLine
                {   versionHR :: BS.ByteString
                ,   statusCode :: Int
                ,   reasonPhrase :: BS.ByteString
                }
                deriving (Eq, Show)

data Headers = Headers{pairs :: (Map.Map BS.ByteString BS.ByteString)} deriving (Show, Eq)

data MyBackend = MyBackend {mySockey :: NS.Socket} deriving (Show, Eq)

data HTTPRequest = HTTPRequest 
    { method :: BS.ByteString        -- e.g., "GET"
    , path :: BS.ByteString         -- e.g., "/some/path"
    , version :: BS.ByteString      -- e.g., "http/1.1"
    , headers :: Headers 
    , maybeBody :: Maybe BS.ByteString -- usually empty for get
    } deriving (Show, Eq)

newtype Token = Token BS.ByteString deriving (Show, Eq) -- for ACME challenge 



instance TLS.HasBackend MyBackend where
    initializeBackend mb = return ()
    getBackend myb = TLS.Backend
                   {
                    TLS.backendFlush = return ()
                   ,TLS.backendClose = do 
                                    NS.close' $ mySockey myb
                                    putStrLn $ "Closed socket " ++ (show $ mySockey myb) ++ "..."

                   ,TLS.backendSend = \bytes -> do
                                 sent <- NSB.send (mySockey myb) bytes
                                 return ()
                   ,TLS.backendRecv = \size -> readUntil (mySockey myb) BS.empty size 
                   }
   
readUntil :: NS.Socket -> BS.ByteString -> Int -> IO BS.ByteString 
readUntil socky oldBytes lengthOfRemainingBytes = do 
    newBytes <- NSB.recv socky lengthOfRemainingBytes 
    let  oldPlusNew   = oldBytes <> newBytes
         newLengthOfRemainingBytes = lengthOfRemainingBytes - (BS.length oldPlusNew)
    case newLengthOfRemainingBytes <= 0 of 
      True  -> return $ oldPlusNew 
      False -> readUntil socky oldPlusNew newLengthOfRemainingBytes
