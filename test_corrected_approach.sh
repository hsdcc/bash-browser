#!/bin/bash

# Test the corrected approach with markers
test_content=$(cat << 'EOF'
<HEADER>
<TITLE>The World Wide Web project</TITLE>
<NEXTID N="55">
</HEADER>
<BODY>
<H1>World Wide Web</H1>The WorldWideWeb (W3) is a wide-area<A
NAME=0 HREF="WhatIs.html">
hypermedia</A> information retrieval
</BODY>
EOF
)

echo "Original content:"
echo "$test_content"
echo

LINE_MARKER="___BASHBROWSER_LINEBREAK___"
temp_content="${test_content//$'\n'/$LINE_MARKER}"

echo "After converting newlines to markers:"
echo "$temp_content"
echo

# Now try to process
original_temp="$temp_content"
while [[ "$temp_content" == *"<A "* ]]; do
  before_a="${temp_content%%<A *}"
  after_a="${temp_content#*<A }"
  
  echo "Processing after_a: '$after_a'"
  
  # Find the tag part (everything up to the first > that closes the opening tag)
  if [[ "$after_a" == *">"* ]]; then
    tag_attrs="${after_a%%>*}"
    content_after_tag="${after_a#*>}"
    
    echo "Tag attributes: '$tag_attrs'"
    echo "Content after tag: '$content_after_tag'"
    
    # Check if HREF= is within the tag attributes (the part before the >)
    if [[ "$tag_attrs" == *"HREF="* ]]; then
      echo "Found HREF in tag attributes!"
      
      # Extract the href value
      after_href="${tag_attrs#*HREF=}"
      quote_char="${after_href:0:1}"
      
      if [[ "$quote_char" == '"' || "$quote_char" == "'" ]]; then
        url_part="${after_href:1}"
        url="${url_part%%"$quote_char"*}"
      else
        url="${after_href%%[[:space:]>\<]*}"
      fi
      
      echo "Extracted URL: '$url'"
      
      # Now find the content between the opening tag and the closing </A>
      if [[ "$content_after_tag" == *"</A>"* ]]; then
        anchor_text="${content_after_tag%%</A>*}"
        after_closing="${content_after_tag#*</A>}"
        
        echo "Anchor text: '$anchor_text'"
        echo "After closing: '$after_closing'"
        
        # Now construct the pattern to replace: <A [attrs] > [text] </A>
        opening_tag="<A ${tag_attrs}>"
        full_pattern="${opening_tag}${anchor_text}</A>"
        replacement="${anchor_text} [${url}]"
        
        echo "Full pattern to replace: '$full_pattern'"
        echo "Replacement: '$replacement'"
        
        temp_content="${temp_content/"$full_pattern"/"$replacement"}"
        echo "New temp_content: '$temp_content'"
        echo
      else
        echo "No closing </A> found"
        break
      fi
    else
      echo "No HREF in tag attributes: '$tag_attrs'"
      # No HREF in this tag, just move past it
      temp_content="${before_a}<A ${after_a}"
      break
    fi
  else
    echo "No closing > for the <A tag"
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

echo "Final result:"
echo "$result"