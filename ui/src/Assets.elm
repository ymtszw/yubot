module Assets exposing (url)

{- Generated by `$ mix yubot.gen_elm_assets` -}

import Utils


url : Bool -> String -> Utils.Url
url isDev assetPath =
    let
        cdnUrl =
            case assetPath of
                "bootstrap.min.css" ->
                    "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-alpha.6/css/bootstrap.min.css"

                "img/hipchat_square.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square.png-a1218fd_YPNlstru"

                "img/hipchat_square_40.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square_40.png-a1218fd_KN76ANBy"

                "img/link_40.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-link_40.png-a1218fd_gwL786er"

                "img/polar_bear.jpg" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-polar_bear.jpg-a1218fd_Lq9i9laQ"

                "img/poller/favicon.ico" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon.ico-a1218fd_p6GsphQZ"

                "img/poller/favicon32.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon32.png-a1218fd_WtTo2zEb"

                "img/spinner_50.gif" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-spinner_50.gif-a1218fd_mfB9hMoU"

                "poller.js" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_poller.js-a1218fd_F5mcPZ6C"

                _ ->
                    ""
    in
        Utils.ite isDev ("/static/assets/" ++ assetPath) cdnUrl
