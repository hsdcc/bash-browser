#!/bin/bash

# Test the corrected approach
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
</BODY>
EOF
)

echo "Original content:"
echo "$test_content"
echo

# Apply the approach with corrected patterns for markers
LINE_MARKER="___BASHBROWSER_LINEBREAK___"

# Convert newlines to markers to allow multi-line pattern matching
temp_content="${test_content//$'\n'/$LINE_MARKER}"

echo "Single line version:"
echo "$temp_content"
echo

# Look for <A followed by any characters (including our marker) to HREF=
# The pattern needs to handle the fact that newlines were replaced with markers
pattern="(<A[^>]*HREF=)"
found=false

# Manual search through the string to replace <A ... HREF="url">text</A> patterns
# Since bash doesn't support regex in the same way, I need to be more careful
original_temp="$temp_content"

# Find each <A tag and see if it contains HREF
temp_copy="$temp_content"
while [[ "$temp_copy" == *"<A "* ]]; do
  before_a="${temp_copy%%<A *}"
  after_a="${temp_copy#*<A }"
  
  # Check if this <A tag has HREF within its attribute part
  if [[ "$after_a" == *">"* ]]; then
    # Get the tag part (before >)
    tag_part="${after_a%%>*}"
    content_after_tag="${after_a#*>}"
    
    # Check if HREF is in the tag attributes
    if [[ "$tag_part" == *"HREF="* ]]; then
      # Extract the href value
      after_href="${tag_part#*HREF=}"
      quote_char="${after_href:0:1}"
      
      if [[ "$quote_char" == '"' || "$quote_char" == "'" ]]; then
        url_part="${after_href:1}"
        url="${url_part%%"$quote_char"*}"
      else
        # Unquoted - shouldn't happen in proper HTML but handle it
        url="${after_href%%[[:space:]>\<]*}"
      fi
      
      # Find the text content and closing </A>
      if [[ "$content_after_tag" == *"</A>"* ]]; then
        anchor_text="${content_after_tag%%</A>*}"
        after_closing="${content_after_tag#*</A>}"
        
        # Construct what we expect to find: <A [tag_part] > [anchor_text] </A>
        full_pattern="<A ${tag_part}>${anchor_text}</A>"
        replacement="${anchor_text} [${url}]"
        
        # Check if the pattern exists in our string
        if [[ "$temp_content" == *"$full_pattern"* ]]; then
          temp_content="${temp_content/"$full_pattern"/"$replacement"}"
          echo "Replaced: $full_pattern"
          echo "With: $replacement"
          found=true
        else
          echo "Pattern not found in main string: $full_pattern"
          # The issue is that our tag_part may contain the line marker
          echo "tag_part contains: $tag_part"
          echo "Looking for HREF in: $tag_part"
        fi
      else
        echo "No closing </A> found"
      fi
    else
      echo "No HREF in this tag: $tag_part"
    fi
  else
    echo "No closing > for <A tag"
  fi
  
  temp_copy="<A $tag_part>$content_after_tag"  # This is wrong, just going to next
  temp_copy="${temp_copy#*">"}"  # Skip past the current processed part
  if [[ "$temp_copy" != *"<A "* ]]; then
    break
  fi
done

# Convert back from markers to actual newlines
result="${temp_content//$LINE_MARKER/$'\n'}"

echo "Final result after processing:"
echo "$result"