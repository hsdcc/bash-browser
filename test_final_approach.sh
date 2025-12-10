#!/bin/bash

# Test the single-line conversion approach
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
summary</A> of the project.
</BODY>
EOF
)

echo "Original content:"
echo "$test_content"
echo

# Apply the new approach
LINE_MARKER="___BASHBROWSER_LINEBREAK___"

# Convert newlines to markers to allow multi-line pattern matching
temp_content="${test_content//$'\n'/$LINE_MARKER}"

echo "Single line version:"
echo "$temp_content"
echo

# Process <A HREF= tags (upper case)
original_temp="$temp_content"
while [[ "$temp_content" == *"<A "* && "$temp_content" == *"HREF="* && "$temp_content" == *"</A>"* ]]; do
  before_a="${temp_content%%<A *}"
  after_a="${temp_content#*<A }"
  
  # Find HREF part
  after_href="${after_a#*HREF=}"
  before_href_attrs="${after_a%%HREF=*}"
  
  # Make sure HREF is in the same opening tag (before any > that would close the tag)
  if [[ "$before_href_attrs" != *">"* ]]; then
    # Extract URL value (handle quoted or unquoted)
    quote_char="${after_href:0:1}"
    if [[ "$quote_char" == '"' || "$quote_char" == "'" ]]; then
      url_part="${after_href:1}"
      url="${url_part%%"$quote_char"*}"
      after_url="${url_part#*"$quote_char"*}"
    else
      # Unquoted (shouldn't happen in proper HTML but handle it)
      url="${after_href%%[[:space:]>\<]*}"
      after_url="${after_href:${#url}}"
    fi
    
    # Find where opening tag ends (first > after URL)
    if [[ "$after_url" == *">"* ]]; then
      content_and_closing="${after_url#*>}"
      anchor_text="${content_and_closing%%</A>*}"
      after_closing="${content_and_closing#*</A>}"
      
      # Replace the entire pattern
      full_pattern="<A ${before_href_attrs}HREF=\"$url\">$anchor_text</A>"
      replacement="$anchor_text [$url]"
      
      temp_content="${temp_content/"$full_pattern"/"$replacement"}"
      echo "Found and replaced pattern: $full_pattern"
      echo "With: $replacement"
      echo "Temp content now: $temp_content"
      echo
    else
      # No closing > found, break to avoid infinite loop
      echo "No closing > found, breaking"
      break
    fi
  else
    # HREF is not in the same tag, break
    echo "HREF is not in the same tag, breaking"
    break
  fi
  
  # Prevent infinite loops
  if [[ "$temp_content" == "$original_temp" ]]; then
    echo "No progress made, breaking"
    break
  fi
  original_temp="$temp_content"
done

# Convert back from markers to actual newlines
result="${temp_content//$LINE_MARKER/$'\n'}"

echo "Final result after processing:"
echo "$result"