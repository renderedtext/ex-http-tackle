defmodule HttpTackle do
  @callback handle_message(Any.t, String.t) :: any

  defmacro __using__(options) do
    port        = Keyword.fetch!(options, :http_port)
    url         = Keyword.fetch!(options, :amqp_url)
    exchange    = Keyword.fetch!(options, :exchange)
    routing_key = Keyword.fetch!(options, :routing_key)

    quote do
      @behaviour HttpTackle

      def start_link do
        require Logger
        import Supervisor.Spec

        options = [
          module: __MODULE__,
          url: unquote(url),
          exchange: unquote(exchange),
          routing_key: unquote(routing_key)
        ]

        Logger.info "Listening on port: #{unquote(port)}"

        children = [
          Plug.Adapters.Cowboy.child_spec(:http, HttpTackle.Listener, options, [port: unquote(port)])
        ]

        opts = [strategy: :one_for_one, name: __MODULE__]
        Supervisor.start_link(children, opts)
      end

      def handle_message(_conn, payload), do: {:ok, payload}
      defoverridable [handle_message: 2]
    end
  end
end
