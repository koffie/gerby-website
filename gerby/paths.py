import os
from gerby.configuration import BUILD_DIR, CONTENT_DIR

DATABASE         = os.path.join(BUILD_DIR,   "tags.sqlite")
COMMENTS         = os.path.join(BUILD_DIR,   "comments.sqlite")
PATH             = os.path.join(BUILD_DIR,   "document")
PAUX             = os.path.join(BUILD_DIR,   "document.paux")
TAGS             = os.path.join(CONTENT_DIR, "tags")
CONTRIBUTORS     = os.path.join(CONTENT_DIR, "CONTRIBUTORS")
ACKNOWLEDGEMENTS = os.path.join(CONTENT_DIR, "support")
