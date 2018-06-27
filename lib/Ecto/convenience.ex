defmodule Ecto.Convenience do
  defmacro is_false(arg) do
    quote(do: fragment("? IS NOT TRUE", unquote(arg)))
  end
end