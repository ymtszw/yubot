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
                    "https://d2wk7ffla5bh7r.cloudfront.net/5/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square.png-7507089_wHdHRw1a"

                "img/hipchat_square_40.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/5/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square_40.png-7507089_0l0IPhip"

                "img/link_40.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/5/Eih41ySz/9eTTqdNt/Assets/_root_img-link_40.png-7507089_7p3frkd6"

                "img/polar_bear.jpg" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/5/Eih41ySz/9eTTqdNt/Assets/_root_img-polar_bear.jpg-7507089_t4RZJ6Io"

                "img/poller/favicon.ico" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon.ico-7507089_gKuuNXwr"

                "img/poller/favicon32.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon32.png-7507089_pQyMkNpl"

                "img/spinner_50.gif" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-spinner_50.gif-7507089_aFJLVDBr"

                "poller.js" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_poller.js-7507089_SRwGB77C"

                _ ->
                    ""
    in
        Utils.ite isDev ("/static/assets/" ++ assetPath) cdnUrl
