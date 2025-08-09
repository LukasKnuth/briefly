defmodule BrieflyWeb.Router do
  use BrieflyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BrieflyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BrieflyWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/since/:days", PageController, :feed

    get "/problems", PageController, :problems

    post "/refresh", PageController, :refresh
  end
end
