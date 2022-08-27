defmodule Avalanche.Steps.Poll do
  @moduledoc """
  A custom `Req` pipeline step to poll for the completion of an asynchronous or long (> 45 seconds) query.
  """

  require Logger

  @doc """
  Polls for the completion of a statement execution if async is false.

    * `:request` - the request

    * `:disable` - set to true to disable polling for this request

  ## Options

    * `:delay` - sleep this number of milliseconds between attempts, defaults to `1000`

    * `:max_attempts` - maximum number of poll attempts, defaults to `5` (for a total of `5`
      requests to the server, including the initial one.)
  """
  def attach(%Req.Request{} = request, false, options) do
    request
    |> Req.Request.register_options([:delay, :max_attempts])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_response_steps(poll: &poll/1)
  end

  def attach(%Req.Request{} = request, true, _options), do: request

  def poll(request_response)

  def poll({request, %{status: 202, body: %{"statementStatusUrl" => path}} = response}) do
    delay = Map.get(request.options, :delay, 1000)
    max_attempts = Map.get(request.options, :max_attempts, 4)
    poll_count = Req.Request.get_private(request, :avalanche_poll_count, 0)

    if poll_count < max_attempts do
      log_poll(response, poll_count, max_attempts, delay)
      Process.sleep(delay)

      request =
        request
        |> Req.Request.put_private(:avalanche_poll_count, poll_count + 1)
        |> build_status_request(path)

      {_, result} = Req.Request.run(request)

      {Req.Request.halt(request), result}
    else
      {request, response}
    end
  end

  def poll(request_response), do: request_response

  # reuse current request and turn it into a `StatusRequest`
  defp build_status_request(%Req.Request{} = request, path) do
    request
    |> Map.put(:method, :get)
    |> Map.put(:body, "")
    |> Map.put(:url, URI.parse(path))
  end

  defp log_poll(response, poll_count, max_attempts, delay) do
    retries_left =
      case max_attempts - poll_count do
        1 -> "1 attempt"
        n -> "#{n} attempts"
      end

    message = ["Will poll in #{delay}ms, ", retries_left, " left"]

    Logger.warn(["Avalanche.poll: Got response with status #{response.status}. ", message])
  end
end
