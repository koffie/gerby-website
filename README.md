# Gerby Website

A Flask-based web application for browsing mathematical content organized by tags.

## HTTP Endpoints

### General

| URL | Methods | Description |
|-----|---------|-------------|
| `/` | GET | Index / home page |
| `/about` | GET | About page |
| `/statistics` | GET | Site-wide statistics |
| `/browse` | GET | Browse chapters |
| `/robots.txt` | GET | Robots exclusion file |

### Tags

| URL | Methods | Description |
|-----|---------|-------------|
| `/tag/<tag>` | GET | Show content for a given tag |
| `/tag/tag/<tag>` | GET | Redirect alias for `/tag/<tag>` |
| `/tag/<tag>/cite` | GET | Show citation info for a tag |
| `/tag/<tag>/statistics` | GET | Statistics for a specific tag |
| `/tag/<tag>/history` | GET | Git history for a tag |
| `/index.php` | GET | Legacy redirect to tag lookup |
| `/tags` | GET | List all tags |

### Graphs

| URL | Methods | Description |
|-----|---------|-------------|
| `/tag/<tag>/graph/topics` | GET | Topic dependency graph page for a tag |
| `/tag/<tag>/graph/structure` | GET | Structure graph page for a tag |
| `/tag/<tag>/graph/tree` | GET | Tree graph page for a tag |

### Search

| URL | Methods | Description |
|-----|---------|-------------|
| `/search` | GET | Search page |
| `/tag` | GET | Redirect to search |

### Bibliography

| URL | Methods | Description |
|-----|---------|-------------|
| `/bibliography` | GET | Full bibliography |
| `/bibliography/<key>` | GET | Single bibliography entry |

### Comments

| URL | Methods | Description |
|-----|---------|-------------|
| `/recent-comments` | GET | Recent comments (page 1) |
| `/recent-comments/<page>` | GET | Recent comments (paginated) |
| `/recent-comments.xml` | GET | Recent comments Atom feed |
| `/recent-comments.rss` | GET | Recent comments RSS feed |
| `/post-comment` | POST | Submit a new comment |

### Stacks Project Specific

| URL | Methods | Description |
|-----|---------|-------------|
| `/todo` | GET | TODO list |
| `/markdown` | GET | Markdown info page |
| `/acknowledgements` | GET | Acknowledgements |
| `/contribute` | GET | How to contribute |
| `/contributors` | GET | List of contributors |
| `/recent-changes` | GET | Recent changes |
| `/chapter/<chapter>` | GET | Chapter overview (by number) |
| `/tex` | GET | Redirect to GitHub source |
| `/tex/<filename>` | GET | Redirect to specific source file on GitHub |
| `/download/<filename>` | GET | Download a PDF file |

### API (JSON)

| URL | Methods | Description |
|-----|---------|-------------|
| `/api` | GET | API documentation page |
| `/data/tag/<tag>/structure` | GET | Tag structure metadata (JSON) |
| `/data/tag/<tag>/content/statement` | GET | Tag statement content (JSON) |
| `/data/tag/<tag>/content/full` | GET | Full tag content (JSON) |
| `/data/tag/<tag>/graph/topics` | GET | Topic graph data (JSON) |
| `/data/tag/<tag>/graph/structure` | GET | Structure graph data (JSON) |
| `/data/tag/<tag>/graph/tree` | GET | Tree graph data (JSON) |
