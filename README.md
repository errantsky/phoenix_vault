# PhoenixVault

A partial clone of [Archivebox](https://github.com/ArchiveBox/ArchiveBox) implemented in Elixir using Phoenix LiveView.



## Features
1. Search using OpenAI's embedding model `text-embedding-3-small`
![search-sample](https://github.com/user-attachments/assets/f54725da-5a61-4aa5-85e2-fb3b6a886efd)

2. Archive in 3 formats: HTML, PDF, and PNG.
3. Archiving jobs are processed in parallel, updating the snapshot view live as each finishes its work.
![snapshot-create-sample](https://github.com/user-attachments/assets/502c88f8-8cdb-45d6-a43a-db7c3fa1c819)

