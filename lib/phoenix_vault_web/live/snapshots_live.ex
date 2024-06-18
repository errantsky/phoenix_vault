defmodule PhoenixVaultWeb.SnapshotsLive do
  alias PhoenixVault.{Repo, Snapshot}
  use PhoenixVaultWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Snapshots</h1>
    <div id="table-container">
      <table>
        <thead>
          <tr>
            <th>Added</th>
            <th>Title</th>
            <%!-- <th>Files Saved</th> --%>
            <%!-- <th>Size</th> --%>
            <th>Original URL</th>
          </tr>
        </thead>
        <tbody>
          <%= for snapshot <- PhoenixVault.Repo.all(PhoenixVault.Snapshot) do %>
            <tr>
              <td><%= snapshot.inserted_at %></td>
              <td><%= snapshot.title %></td>
              <%!-- <td> --%>
              <%!-- <img src="<%= Routes.static_path(@socket, "/images/icon.png") %>" alt="Sebald" class="icon"> --%>
              <%!-- </td> --%>
              <%!-- <td>5.0 MB</td> --%>
              <td><a href={snapshot.url}><%= snapshot.url %></a></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
