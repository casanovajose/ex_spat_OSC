# to run:
# > elixir --no-halt udp_server.exs
# to test:
# > echo "hello world" | nc -u -w0 localhost:2052
# > echo "quit" | nc -u -w0 localhost:2052

# Let's call our module "UDPServer"
defmodule UDPServer do
  # Our module is going to use the DSL (Domain Specific Language) for Gen(eric) Servers
  use GenServer

  # We need a factory method to create our server process
  # it takes a single parameter `port` which defaults to `2052`
  # This runs in the caller's context
  def start_link(port \\ 2052) do
    GenServer.start_link(__MODULE__, port) # Start 'er up
  end

  # Initialization that runs in the server context (inside the server process right after it boots)
  def init(port) do
    # Use erlang's `gen_udp` module to open a socket
    # With options:
    #   - binary: request that data be returned as a `String`
    #   - active: gen_udp will handle data reception, and send us a message `{:udp, socket, address, port, data}` when new data arrives on the socket
    # Returns: {:ok, socket}
    :gen_udp.open(port, [:binary, active: true])
  end

  # define a callback handler for when gen_udp sends us a UDP packet
  def handle_info({:udp, _socket, _address, _port, data}, socket) do
    # punt the data to a new function that will do pattern matching
    handle_packet(data, socket)
  end

  # pattern match the "quit" message
  defp handle_packet("quit\n", socket) do
    IO.puts("Received: quit")

    # close the socket
    :gen_udp.close(socket)

    # GenServer will understand this to mean we want to stop the server
    # action: :stop
    # reason: :normal
    # new_state: nil, it doesn't matter since we're shutting down :(
    {:stop, :normal, nil}
  end

  # fallback pattern match to handle all other (non-"quit") messages
  defp handle_packet(data, socket) do
    # print the message
    IO.puts("Received: #{String.trim data}")

    # IRL: do something more interesting...

    # GenServer will understand this to mean "continue waiting for the next message"
    # parameters:
    # :noreply - no reply is needed
    # new_state: keep the socket as the current state
    {:noreply, socket}
  end
end

# For extra protection, start a supervisor that will start the UDPServer
# The supervisor's job is to monitor the UDPServer
# If it crashes it will auto restart, fault tolerance in 1 line of code!!!
{:ok, _pid} = Supervisor.start_link([{UDPServer, 2052}], strategy: :one_for_one)
