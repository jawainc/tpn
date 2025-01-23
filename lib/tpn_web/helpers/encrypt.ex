defmodule TpnWeb.Helpers.Encrypt do
  @moduledoc """
  Provides encryption helper functions.
  """
  @aes_key_size 32
  @aes_iv_size 16

  @doc """
  Encrypts the provided data string using AES 256.

  ## Parameters
  - data: The plaintext data to encrypt.
  - key: The encryption key (must be 32 bytes for AES-256).

  ## Returns
  - A tuple containing the IV and the encrypted data.
  """

  def pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  def unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  def encrypt(data, key) when byte_size(key) == @aes_key_size do
    iv = :crypto.strong_rand_bytes(@aes_iv_size)
    encrypted_data = :crypto.crypto_one_time(:aes_256_cbc, key, iv, pad(data, 16), true)
    {iv, encrypted_data}
  end

  @doc """
  Generates a key for encryption, calls the encrypt function, and stores the key and IV in the session.

  ## Parameters
  - conn: The connection struct.
  - data: The plaintext data to encrypt.

  ## Returns
  - The updated connection struct with the key and IV stored in the session.
  """
  def generate_and_encrypt(data, key) do
    # get encryption key from session
    {:ok, d_key} = Base.decode64(key)
    {iv, encrypted_data} = encrypt(data, d_key)
    {Base.encode64(iv), Base.encode64(encrypted_data)}
  end

  @doc """
  Decrypts the provided data string using AES 256.
  """
  def decrypt(encrypted_data, key, iv)
      when byte_size(key) == @aes_key_size and byte_size(iv) == @aes_iv_size do
    decrypted_data = :crypto.crypto_one_time(:aes_256_cbc, key, iv, encrypted_data, false)
    {:ok, unpad(decrypted_data)}
  end
end
