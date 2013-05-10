--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Applicative ((<$>))
import           Data.Monoid         (mappend, mconcat)
import           Hakyll

import           Sidebar
--------------------------------------------------------------------------------

standardPandocPagesSubdir d = do
    match (fromGlob ("pages/" ++ d ++ "*.md")) $ do
        route   $ gsubRoute "pages/"  (const "") `composeRoutes` 
                  setExtension "html"
        compile $ pandocCompiler >>= (templated "templates/standard.html")

main :: IO ()
main = hakyll $ do

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "bootstrap/css/*" $ do
        route   $ gsubRoute "bootstrap/" (const "")
        compile compressCssCompiler

    match "bootstrap/js/*.js" $ do
        route   $ gsubRoute "bootstrap/" (const "")
        compile copyFileCompiler

    match "jquery/*.js" $ do
        route   $ gsubRoute "jquery/" (const "js/")
        compile copyFileCompiler

    match "bootstrap/img/*" $ do
        route   $ gsubRoute "bootstrap/" (const "")
        compile copyFileCompiler

    match "pages/index.md" $ do
        route   $ gsubRoute "pages/"  (const "") `composeRoutes` 
                  setExtension "html"
        compile $ pandocCompiler >>= (templated "templates/frontpage.html")

    match "templates/*" $ compile templateCompiler

    standardPandocPagesSubdir ""
    standardPandocPagesSubdir "hardware/"
    standardPandocPagesSubdir "software/"

sitemap :: PageTree
sitemap = Tree "/" "Home" [ (Page "index.html" "Overview" "Overview")
                          , (Tree "hardware" "Hardware" hardwarepages)
                          , (Tree "software" "Software" softwarepages)
                          , (Page "about.html" "About" "About")
                          ]
  where
  hardwarepages = [ Page "index.html" "Overview" "Hardware Overview"
                  , Page "shoppinglist.html" "Shopping List" 
                          "Shopping List"
                  , Page "px4fmu.html" "PX4FMU Flight Controller" "Flight Controller"
                  , Page "ardrone.html" "AR Drone Air Vehicle" "Air Vehicle"
                  , Page "blackmagic.html" "Black Magic Probe Debugger" "Debugger"
                  ]
  softwarepages = [ Page "index.html" "Overview" "Software Overview"
                  , Page "prerequisites.html" "Prerequisites" "Prerequisites"
                  , Page "build.html" "Building SMACCMPilot" "Building"
                  , Page "loading.html" "Uploading SMACCMPilot" "Loading"
                  , Page "ivory-overview.html" "Ivory Language Overview" "Ivory Language"
                  , Page "tower-overview.html" "Tower Overview" "Tower Language"
                  ]
  flyingpages   = [ Page "index.html" "Overview" "Flying Overview"
                  ]

navbar :: FilePath -> String
navbar currentpath = unlines $ 
  [ "<ul class=\"nav\"> "
  , entry "/index.html" "Home"
  , entry "/hardware/index.html" "Hardware"
  , entry "/software/index.html" "Software"
  , entry "/about.html" "About"
  , "</ul>"
  ]
  where
  entry path desc =
    "<li" ++ (emphif path) ++ "><a href=\"" ++ path ++ "\">" ++
    desc ++ "</a></li> "
  emphif path = case currentpath == path of
    True  -> " class=\"active\" "
    False -> ""

templated :: Identifier -> Item String -> Compiler (Item String)
templated t input = loadAndApplyTemplate t ctx input >>= relativizeUrls
  where
  ctx :: Context String
  ctx = mconcat
    [ field "navbar"    $ \item -> return (navbar (itemFilePath item))
    , field "sidebar"   $ \item -> return (sidebarHTML sitemap item)
    , field "directory" $ \item -> return (itemDirectory item)
    , field "filepath"  $ \item -> return (itemFilePath item)
    , constField "copyright" "<p>&copy; Galois Inc. 2013</p>"
    , defaultContext
    ]

