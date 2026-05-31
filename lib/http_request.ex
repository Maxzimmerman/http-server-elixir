defmodule HTTPRequest do
  @enforce_keys [:line, :headers]
  defstruct [:line, :headers, :body, :close]

  @type t :: %__MODULE__{
          line: map(),
          headers: list(),
          body: String.t(),
          close: boolean()
        }
end
