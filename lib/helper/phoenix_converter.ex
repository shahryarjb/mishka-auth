defmodule MishkaAuth.Helper.PhoenixConverter do
  import Plug.Conn
  import Phoenix.Controller
  alias MishkaAuth.Client.Users.ClientUserSchema

  @type user_id() :: Ecto.UUID.t
  @type redirect_url() :: String.t()
  @type conn() :: Plug.Conn.t()
  @type error_msg() :: String.t()
  @type token() :: String.t()
  @type msg() :: String.t()

  @wrong_social_strategy "/"

  # store token or user id into session
  @spec store_session(atom, token() | user_id(), redirect_url(), conn(), error_msg()) :: conn()

  def store_session(session_name, value, redirect_url, conn, msg) do
    conn
    |> put_flash(:info, msg)
    |> put_session(session_name, value)
    |> configure_session(renew: true)
    |> redirect(to: redirect_url)
  end

  @spec session_redirect(Plug.Conn.t(), any, msg(), atom | binary) :: Plug.Conn.t()

  def session_redirect(conn, redirect_url, msg, type) do
    conn
    |> put_flash(type, msg)
    |> redirect(to: redirect_url)
  end


  @spec render_json(conn(), map(), :error | :ok, integer()) :: Plug.Conn.t()

  def render_json(conn, attrs, :ok, status) do
    conn
    |> put_status(status)
    |> json(attrs)
  end

  def render_json(conn, attrs, :error, status) do
    conn
    |> put_status(status)
    |> json(attrs)
  end

  @spec changeset_redirect(Plug.Conn.t(), Ecto.Changeset.t()) :: Plug.Conn.t()

  def changeset_redirect(conn, changeset) do
    conn
    |> put_view(MishkaAuth.get_config_info(:changeset_redirect_view))
    |> render(MishkaAuth.get_config_info(:changeset_redirect_html), changeset: changeset)
  end

  @spec register_data(
          Plug.Conn.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any},
          any
        ) :: Plug.Conn.t()

  def register_data(conn, params, temporary_id) do
    register_changeset =  ClientUserSchema.changeset(%MishkaAuth.Client.Users.ClientUserSchema{}, params)

    conn
    |> put_view(MishkaAuth.get_config_info(:register_data_view))
    |> render(MishkaAuth.get_config_info(:register_data_html), changeset: register_changeset, social_data: params, temporary_id: temporary_id)
  end

  @spec drop_session(Plug.Conn.t(), atom | binary) :: Plug.Conn.t()

  def drop_session(conn, key) do
    conn
    |> fetch_session
    |> delete_session(key)
  end

  @spec get_session_with_key(Plug.Conn.t(), atom | binary) ::
          {:error, :get_session, atom | binary} | {:ok, :get_session, atom | binary, any}

  def get_session_with_key(conn, key) do
    case get_session(conn, key) do
      nil ->
        {:error, :get_session, key}

      session ->
        {:ok, :get_session, key, session}
    end
  end

  @spec callback_session(Plug.Conn.t(), any, any, String.t(), String.t()) :: Plug.Conn.t()

  def callback_session(conn, module, func, code, provider) do
    case get_session(conn, :request_render) do
      "current_token" ->
        callback_redirect(conn, module, func, code, "current_token", provider)
      "current_user" ->
        callback_redirect(conn, module, func, code, "current_user", provider)
      "refresh_token" ->
        callback_redirect(conn, module, func, code)
      _n ->
        drop_session(conn, :request_render)
        |> session_redirect(@wrong_social_strategy, "your callback is wrong.", :error)
    end
  end

  @spec callback_redirect(Plug.Conn.t(), atom | tuple, atom, String.t(), String.t() | atom(), String.t() | atom()) :: Plug.Conn.t()

  def callback_redirect(conn, module, func, code, strategy, provider) do
    drop_session(conn, :request_render)
    |> redirect(to: apply(module, func, [conn, :callback, provider, [code: code, strategy: strategy]]))
  end

  @spec callback_redirect(Plug.Conn.t(), atom | tuple, atom, String.t()) :: Plug.Conn.t()

  def callback_redirect(conn, module, func, code) do
    drop_session(conn, :request_render)
    |> redirect(to: apply(module, func, [conn, :index, [code: code]]))
  end
end
