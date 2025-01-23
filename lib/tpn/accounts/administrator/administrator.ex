defmodule Tpn.Accounts.Administrator do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :login_id]
  @sortable_fields [:name, :login_id]

  schema "administrators" do
    field :name, :string
    field :login_id, :string
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true

    timestamps()
  end

  @doc false
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :login_id, :password, :password_confirmation])
    |> validate_required([:name, :login_id, :password])
    |> validate_password(opts)
    |> unique_constraint(:login_id)
  end

  def update_changeset(user, attrs, _opts \\ []) do
    user
    |> cast(attrs, [:name, :login_id])
    |> validate_required([:name, :login_id])
    |> unique_constraint(:login_id)
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> validate_confirmation(:password, message: "does not match password")
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Tpn.Accounts.Administrator{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
