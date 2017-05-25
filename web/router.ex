defmodule Yubot.Router do
  use SolomonLib.Router

  static_prefix "/static"

  get "/"            , Root, :index
  get "/poller"      , Root, :poller
  get "/poller/*path", Root, :poller

  # Poller APIs

  post   "/api/poll"    , Poll, :create
  get    "/api/poll/:id", Poll, :retrieve
  get    "/api/poll"    , Poll, :retrieve_list
  delete "/api/poll/:id", Poll, :delete

  post   "/api/action"    , Action, :create
  get    "/api/action/:id", Action, :retrieve
  get    "/api/action"    , Action, :retrieve_list
  delete "/api/action/:id", Action, :delete

  post   "/api/authentication"    , Authentication, :create
  get    "/api/authentication/:id", Authentication, :retrieve
  get    "/api/authentication"    , Authentication, :retrieve_list
  delete "/api/authentication/:id", Authentication, :delete

  # Live Reloader

  if Mix.env == :dev do
    websocket "/ws"
  end
end
