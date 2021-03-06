defmodule MusicPlaylistWeb.AdminView do
  use MusicPlaylistWeb, :view
  alias MusicPlaylistWeb.AdminView

  def render("index.json", %{admins: admins}) do
    %{data: render_many(admins, AdminView, "admin.json")}
  end

  def render("show.json", %{admin: admin}) do
    %{data: render_one(admin, AdminView, "admin.json")}
  end

  def render("admin.json", %{admin: admin}) do
    %{
      id: admin.id,
      email: admin.email,
      password_hash: admin.password_hash
    }
  end

  def render("auth.json", %{token: token, claims: claims}) do
    %{
      token: token,
      claims: claims
    }
  end
end
