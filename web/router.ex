defmodule Yubot.Router do
  use SolomonLib.Router

  static_prefix "/static"

  get "/", Root, :index

  get "/oauth/:provider/login"   , Oauth, :login
  get "/oauth/:provider/callback", Oauth, :callback

  get "/poller"      , Root, :poller
  get "/poller/*path", Root, :poller

  # (Not so) RESTful APIs

  post "/api/user/logout", User, :logout

  post   "/api/poll"    , Poll, :create
  get    "/api/poll/:id", Poll, :retrieve
  get    "/api/poll"    , Poll, :retrieve_list
  delete "/api/poll/:id", Poll, :delete

  post   "/api/action"    , Action, :create
  get    "/api/action/:id", Action, :retrieve
  get    "/api/action"    , Action, :retrieve_list
  put    "/api/action/:id", Action, :update
  delete "/api/action/:id", Action, :delete
  post   "/api/action/try", Action, :try

  post   "/api/authentication"    , Authentication, :create
  get    "/api/authentication/:id", Authentication, :retrieve
  get    "/api/authentication"    , Authentication, :retrieve_list
  delete "/api/authentication/:id", Authentication, :delete

  # Live Reloader

  if Mix.env == :dev do
    websocket "/ws"
  end
end
