defmodule HTTPRequest do
  @enforce_keys [:line, :headers]
  defstruct [:line, :headers, :body]

  @type t :: %__MODULE__{
          line: map(),
          headers: list()
        }
end
