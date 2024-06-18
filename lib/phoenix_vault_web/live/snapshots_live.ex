defmodule PhoenixVaultWeb.SnapshotsLive do
  alias PhoenixVault.{Repo, Snapshot}
  use PhoenixVaultWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :snapshots, Repo.all(Snapshot))}
  end

  def render(assigns) do
    ~H"""
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Reading List Table</title>
      <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 8px 12px;
            border: 1px solid #ccc;
            text-align: left;
        }
        th {
            background-color: #f4f4f4;
        }
        .icon {
            width: 20px;
            height: 20px;
            margin-right: 5px;
        }
        .button-container {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .button-container input[type="text"] {
            padding: 5px;
            margin-right: 5px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        .button-container button {
            padding: 5px 10px;
            margin-right: 5px;
            border: none;
            border-radius: 4px;
            color: white;
            cursor: pointer;
        }
        .button-container .plus {
            background-color: #ffeb3b;
            color: black;
        }
        .button-container .minus {
            background-color: #ffeb3b;
            color: black;
        }
        .button-container .add {
            background-color: #983054;
        }
        .button-container .title {
            background-color: #607d8b;
        }
        .button-container .pull {
            background-color: #4caf50;
        }
        .button-container .re-snapshot {
            background-color: #8bc34a;
        }
        .button-container .reset {
            background-color: #ff9800;
        }
        .button-container .delete {
            background-color: #f44336;
        }
      </style>
    </head>
    <body>
      <h1>Snapshots</h1>
      <div class="button-container">
        <input type="text" placeholder="Tags" />
        <button class="plus">+</button>
        <button class="minus">-</button>
        <button class="add">Add +</button>
        <button class="title">Title</button>
        <button class="pull">Pull</button>
        <button class="re-snapshot">Re-Snapshot</button>
        <button class="reset">Reset</button>
        <button class="delete">Delete</button>
        <%!-- TODO Add event --%>
        <span>0 of 40 selected</span>
      </div>
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
            <%= for snapshot <- @snapshots do %>
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
    </body>
    """
  end
end
