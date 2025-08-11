defmodule BrieflyWeb.Router do
  use BrieflyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_root_layout, html: {BrieflyWeb.Layouts, :root}
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BrieflyWeb do
    pipe_through :browser

    get "/health", PageController, :health

    get "/", PageController, :home
    get "/since/:days", PageController, :feed

    get "/problems", PageController, :problems

    post "/refresh", PageController, :refresh
  end
end
