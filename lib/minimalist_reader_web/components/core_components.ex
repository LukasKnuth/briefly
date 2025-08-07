defmodule MinimalistReaderWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  This file is extensively purged from what Phoenix generates by default - mainly for
  simplicity. There are very few UIs in the application and most of them are styled
  in place - no repeatable components are needed.
  """
  use Phoenix.Component

  use Gettext, backend: MinimalistReaderWeb.Gettext

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(MinimalistReaderWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MinimalistReaderWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
