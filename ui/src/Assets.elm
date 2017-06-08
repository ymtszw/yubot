module Assets exposing (url)

import Utils


url : Bool -> String -> Utils.Url
url isDev assetPath =
    let
        cdnUrl =
            case assetPath of
                "img/hipchat_square.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/2/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square.png_cj0rrSZG"

                "img/hipchat_square_40.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/4/Eih41ySz/9eTTqdNt/Assets/_root_img-hipchat_square_40.png_u0x8zLsw"

                "img/polar_bear.jpg" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-polar_bear.jpg_wEkR1wsG"

                "img/poller/favicon.ico" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon.ico_deiD83wq"

                "img/poller/favicon32.png" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/6/Eih41ySz/9eTTqdNt/Assets/_root_img-poller-favicon32.png_kWOBKTKL"

                "poller.js" ->
                    "https://d2wk7ffla5bh7r.cloudfront.net/3/Eih41ySz/9eTTqdNt/Assets/_root_poller.js_d3KzfwgI"

                _ ->
                    ""
    in
        Utils.ite isDev ("/static/assets/" ++ assetPath) cdnUrl
