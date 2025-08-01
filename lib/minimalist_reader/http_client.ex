defmodule MinimalistReader.HttpClient do
  @moduledoc """
  A `Req` based HTTP Client to request feeds over the internet.
  """

  @accepted_opts ~w(into retry_log_level cache retry plug)a
  @default_opts [
    into: :self,
    # retry is setup by default, doing max 4 requests with exponential back-off
    retry_log_level: :info,
    # this is the default, just making it explicit to document
    cache: false
  ]
  @type url :: binary()
  @type opts :: keyword()

  @spec stream_get(url, opts) :: {:ok, Enumerable.t()} | {:error, any()}
  def stream_get(url, opts \\ []) do
    opts = Keyword.merge(@default_opts, Keyword.take(opts, @accepted_opts))

    case Req.get(url, opts) do
      # NOTE: This is `Req.Response.Async` becasue of `into: :self`!
      {:ok, %Req.Response{status: status, body: body}} when status >= 200 and status < 299 ->
        # Return the streaming body
        {:ok, body}

      {:ok, response} ->
        {:error, response}

      {:error, exception} ->
        {:error, exception}
    end
  end
end
