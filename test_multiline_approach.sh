#!/bin/bash

# Simple approach: Use sed as a last resort since it's already in the system (in /root/bin/curl)
# But since we want pure bash, let me try another approach
# We'll convert the entire content to a single line with special markers, process it, then convert back

test_content=$(cat << 'EOF'
<HEADER>
<TITLE>The World Wide Web project</TITLE>
<NEXTID N="55">
</HEADER>
<BODY>
<H1>World Wide Web</H1>The WorldWideWeb (W3) is a wide-area<A
NAME=0 HREF="WhatIs.html">
hypermedia</A> information retrieval
initiative aiming to give universal
access to a large universe of documents.<P>
Everything there is online about
W3 is linked directly or indirectly
to this document, including an <A
NAME=24 HREF="Summary.html">executive
summary</A> of the project, <A
NAME=29 HREF="Administration/Mailing/Overview.html">Mailing lists</A>
, <A
NAME=30 HREF="Policy.html">Policy</A> , November's  <A
NAME=34 HREF="News/9211.html">W3  news</A> ,
<A
NAME=41 HREF="FAQ/List.html">Frequently Asked Questions</A> .
</BODY>
EOF
)

echo "Before processing:"
echo "$test_content"
echo

# Convert newlines to a unique marker, process, then convert back
MARKER="___NEWLINE___"

# Replace newlines in the content with our marker
single_line_content="${test_content//$'\n'/$MARKER}"

echo "Single line version:"
echo "$single_line_content"
echo

# Now process using bash pattern matching on the single line
processed_content="$single_line_content"

# Handle <A HREF= patterns - find <A [attrs] HREF="[url]" [more attrs] >[text]</A>
# This is complex, so let's just try a simple replacement for one known pattern
# Look for <A followed by any characters (non-greedy) to HREF="...", then the URL, then >, then text, then </A>

# Replace <A NAME=0 HREF="WhatIs.html">hypermedia</A>
if [[ "$processed_content" == *"<A NAME=0 HREF=\"WhatIs.html\">"*"</A>"* ]]; then
  before_pattern="${processed_content%%<A NAME=0 HREF=\"WhatIs.html\">*}"
  after_pattern="${processed_content#*<A NAME=0 HREF=\"WhatIs.html\">}"
  text="${after_pattern%%</A>*}"
  after_closing="${after_pattern#*</A>}"
  processed_content="${before_pattern}${text} [WhatIs.html]${after_closing}"
fi

echo "After simple one-off replacement:"
echo "$processed_content"
echo

# Convert back from marker to newlines
result="${processed_content//$MARKER/$'\n'}"
echo "After converting back to multi-line:"
echo "$result"