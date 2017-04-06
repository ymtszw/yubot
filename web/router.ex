defmodule Yubot.Router do
  use SolomonLib.Router

  static_prefix "/static"

  get "/"      , Root, :index
  get "/poller", Root, :poller

  # Poller APIs

  post "/api/poll"    , Poll, :create
  get  "/api/poll/:id", Poll, :retrieve
  get  "/api/poll"    , Poll, :retrieve_list

  post "/api/action"    , Action, :create
  get  "/api/action/:id", Action, :retrieve
  get  "/api/action"    , Action, :retrieve_list

  post "/api/authentication"    , Authentication, :create
  get  "/api/authentication/:id", Authentication, :retrieve
  get  "/api/authentication"    , Authentication, :retrieve_list
end
