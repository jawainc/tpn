defmodule TpnWeb.Plugs.AesPlug do
  import Plug.Conn

  alias TpnWeb.Helpers.ClientEvents

  def init(options), do: options

  def call(conn, _opts) do
    register_before_send(conn, fn conn ->
      #  get encryption key from session
      key = conn |> get_session(:encryption_key)

      if key != nil do
        # get response body
        body =
          case is_list(conn.resp_body) do
            true -> List.to_string(conn.resp_body)
            false -> conn.resp_body
          end

        # encrypt the response body
        {iv, encrypted_data} = TpnWeb.Helpers.Encrypt.generate_and_encrypt(body, key)

        rest_headers = get_resp_header(conn, "hx-trigger")

        trigger_header =
          case Enum.member?(conn.path_info, "dash") do
            true -> ClientEvents.generate_x_key_event(rest_headers, key, iv)
            false -> ClientEvents.generate_x_key_event(rest_headers, "", iv)
          end

        # update the response body
        conn
        |> put_resp_body(encrypted_data)
        |> put_resp_header("hx-trigger", trigger_header)
      else
        conn
      end
    end)
  end

  # Helper function to update the response body
  defp put_resp_body(conn, new_body) do
    %{conn | resp_body: new_body}
  end
end
