defmodule HttpTackle do
  defmodule Behaviour do
    @callback handle_message(String.t) :: any
  end

  defmacro __using__(options) do
    tackle_options = ${
      url: Keyword.fetch!(options, :url),
      exchange: Keyword.fetch!(options, :exchange),
      routing_key: Keyword.fetch!(options, :routing_key)
    }

    quote do
      @behaviour HttpTackle

      require Logger
      use Plug.Router

      plug :match
      plug :dispatch

      post "/" do
        {:ok, raw_body, _} = Plug.Conn.read_body(conn)

        case handle_message(raw_body) do
          {:ok, message} ->
            Tackle.publish(message, unquote(tackle_options))
            send_resp(conn, 202, "")
          {:error, reason} ->
            send_resp(conn, 400, reason)
        end
      end

      match _ do
        send_resp(conn, 404, "oops")
      end

      def handle_message(payload), do: {:ok, payload}
      defoveridable [handle_message: 1]
    end
  end
end
