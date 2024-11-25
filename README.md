# PhoenixVault
![4551B927-3A4B-4D5F-8108-CF61E283E91F_1_105_c](https://github.com/user-attachments/assets/c06c194a-8280-4946-9816-986100c79b52)

A partial clone of [Archivebox](https://github.com/ArchiveBox/ArchiveBox) implemented in Elixir using Phoenix LiveView & PostgreSQL.



## Features
1. Content-aware search using OpenAI's [text-embedding-3-small]() model & [pgvector](pgvector)
![search-sample](https://github.com/user-attachments/assets/f54725da-5a61-4aa5-85e2-fb3b6a886efd)

2. Archives in 3 formats: HTML, PDF, and PNG.
3. Archiving jobs are processed in parallel, updating the snapshot view live as each job finishes its work.
![snapshot-create-sample](https://github.com/user-attachments/assets/502c88f8-8cdb-45d6-a43a-db7c3fa1c819)

4. Snapshot viewer for each archived format.
![snapshot-viewer-demo](https://github.com/user-attachments/assets/b55c94fe-0ed8-47e9-a45c-14bdb89ea136)

