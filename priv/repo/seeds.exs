# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Tpn.Repo.insert!(%Tpn.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
Tpn.Repo.insert(%Tpn.Accounts.Administrator{
  name: "Jawad",
  login_id: "jawad",
  hashed_password: Pbkdf2.hash_pwd_salt("password")
})
