defmodule MusicPlaylistWeb.MusicController do
  use MusicPlaylistWeb, :controller
  import Plug.Conn

  alias MusicPlaylist.Accounts.Clients.Client
  alias MusicPlaylist.Plans.{Plan, PlanHierarchy}
  alias MusicPlaylist.Musics.{Music, MusicPlan, Playlist}
  alias MusicPlaylist.Musics.Music.Repository

  action_fallback MusicPlaylistWeb.FallbackController

  @musics_per_age 10

  def index(%{assigns: %{role: :client, current_user: user_id}} = conn, %{"page" => page}) do
    client = Client.Repository.get_client!(user_id)

    musics = page
      |> Integer.parse()
      |> elem(0)
      |> MusicPlan.Repository.list_music_plans_by_plan(@musics_per_age, client.plan_id)
      |> Enum.map(fn music_plan -> Repository.get_music!(music_plan.music_id) end)

    maxPages = (MusicPlan.Repository.count_musics_by_plan(client.plan_id) / @musics_per_age)
      |> Float.ceil()
      |> trunc()

    render(conn, "index.json", %{musics: musics, max_pages: maxPages})
  end

  def index(conn, %{"page" => page}) do
    musics = page
      |> Integer.parse()
      |> elem(0)
      |> Repository.list_musics(@musics_per_age)

    maxPages = (Repository.count_musics() / @musics_per_age)
      |> Float.ceil()
      |> trunc()

    render(conn, "index.json", %{musics: musics, max_pages: maxPages})
  end


  def index(conn, _params) do
    musics = Repository.list_all_musics()
    render(conn, "all.json", musics: musics)
  end

  defp include_plan(music_id, plan_id) do
    MusicPlan.Repository.create_music_plan(%{music_id: music_id, plan_id: plan_id})
    hierarchy = PlanHierarchy.Repository.get_plan_hierarchy_by_child!(plan_id)

    case hierarchy.parent_id do
      nil ->
        {:ok}
      parent_id ->
        include_plan(music_id, parent_id)
    end
  end

  def create(conn, %{"music" => %{"plan" => plan_id} = music_params}) do
    with {:ok, %Music{} = music} <- Repository.create_music(music_params) do
      include_plan(music.id, plan_id)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.music_path(conn, :show, music))
      |> render("response.json", music: music)
    end
  end

  def show(conn, %{"id" => id}) do
    music = Repository.get_music!(id)
    plans = music.id
      |> MusicPlan.Repository.list_music_plans_by_music()
      |> Enum.map(fn %{plan_id: plan_id} -> Plan.Repository.get_plan!(plan_id) end)

    render(conn, "show.json", %{music: music, plans: plans})
  end

  def update(conn, %{"id" => id, "music" => music_params, "plan" => ""}) do
    music = Repository.get_music!(id)

    with {:ok, %Music{} = music} <- Repository.update_music(music, music_params) do
      render(conn, "response.json", music: music)
    end
  end

  def update(conn, %{"id" => id, "music" => music_params, "plan" => plan_id}) do
    music = Repository.get_music!(id)

    with {:ok, %Music{} = music} <- Repository.update_music(music, music_params) do
      MusicPlan.Repository.delete_music_plan_by(id)
      include_plan(id, plan_id)
      render(conn, "response.json", music: music)
    end
  end

  def delete(conn, %{"id" => id}) do
    music = Repository.get_music!(id)

    with {:ok, %Music{}} <- Repository.update_music(music, %{active: false}) do
      send_resp(conn, :no_content, "")
    end
  end

  def list_playlist(%{assigns: %{role: :client, current_user: client_id}} = conn, _params) do
    musics = client_id
      |> Playlist.Repository.list_playlist_by_client()
      |> Enum.map(fn playlist -> Repository.get_music!(playlist.music_id) end)

    render(conn, "all.json", musics: musics)
  end

  def list_playlist(%{assigns: %{role: :admin}} = conn, %{"client_id" => client_id}) do
    musics = client_id
      |> Playlist.Repository.list_playlist_by_client()
      |> Enum.map(fn playlist -> Repository.get_music!(playlist.music_id) end)

    render(conn, "all.json", musics: musics)
  end

  def list_playlist(conn, _params) do
    conn
    |> resp(401, "")
    |> send_resp()
    |> halt()
  end

  def insert_music(%{assigns: %{role: :client, current_user: user_id}} = conn, %{"music_id" => music_id}) do
    musics_max = user_id
      |> Client.Repository.get_client!()
      |> Map.get(:plan_id)
      |> Plan.Repository.get_plan!()
      |> Map.get(:music_limit)

    if Playlist.Repository.count_musics(user_id) < musics_max do
      case Playlist.Repository.create_playlist(%{music_id: music_id, client_id: user_id}) do
        {:ok, _} ->
          conn
          |> put_status(:created)
          |> render("playlist.json", flag: true)
        _ ->
          conn
          |> render("playlist.json", flag: false)
      end
    else
      conn |> render("playlist.json", flag: false)
    end
  end

  def insert_music(conn, _params) do
    conn
    |> resp(401, "")
    |> send_resp()
    |> halt()
  end

  def remove_music(%{assigns: %{role: :client, current_user: user_id}} = conn, %{"music_id" => music_id}) do
    user_id
    |> Playlist.Repository.get_playlist_by(music_id)
    |> case do
      nil ->
        render(conn, "playlist.json", flag: false)
      playlist ->
        playlist
        |> Playlist.Repository.delete_playlist()
        |> case do
          {:ok, _} -> render(conn, "playlist.json", flag: true)
          _ -> render(conn, "playlist.json", flag: false)
        end
    end
  end

  def remove_music(conn, _params) do
    conn
    |> resp(401, "")
    |> send_resp()
    |> halt()
  end
end
