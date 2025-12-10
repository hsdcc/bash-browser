#!/bin/bash

# Test the simpler approach
content=$(cat << 'EOF'
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

echo "Original content:"
echo "$content"
echo

# Apply the new link processing approach
original_content="$content"

# Handle <A HREF="..." case first
while [[ "$content" == *"<A "* && "$content" == *"</A>"* ]]; do
  # Find a tag that contains HREF
  before_tag="${content%%<A *}"
  after_tag_start="${content#*<A }"
  
  # Find the first tag that has HREF in it and ends with >
  if [[ "$after_tag_start" != *">"* ]]; then
    # No closing > for this tag
    break
  fi
  
  # Get the tag attributes part (before >) and content part (after >)
  tag_attrs="${after_tag_start%%>*}"
  after_tag_end="${after_tag_start#*>}"
  
  # Check if this tag section (before >) contains HREF=
  if [[ "$tag_attrs" == *"HREF="* ]]; then
    # Extract HREF value
    after_href="${tag_attrs#*HREF=}"
    quote_char="${after_href:0:1}"
    
    if [[ "$quote_char" == '"' || "$quote_char" == "'" ]]; then
      # Quoted href
      href_val="${after_href:1}"  # Skip quote
      url="${href_val%%"$quote_char"*}"
    else
      # Unquoted href
      url="${after_href%%[[:space:]>\<]*}"
    fi
    
    # Now find the text content and closing </A> in the content part
    if [[ "$after_tag_end" == *"</A>"* ]]; then
      anchor_text="${after_tag_end%%</A>*}"
      after_closing_tag="${after_tag_end#*</A>}"
      
      # Reconstruct the pattern to replace: <A [attrs]>[text]</A> -> [text] [url]
      full_pattern="<A ${tag_attrs}>${anchor_text}</A>"
      replacement="${anchor_text} [${url}]"
      
      content="${content/"$full_pattern"/"$replacement"}"
      echo "Replaced: $full_pattern"
      echo "With: $replacement"
      echo "Content now: $content"
      echo
    else
      # No closing </A> found, break to avoid infinite loop
      break
    fi
  else
    # This tag doesn't have HREF, just reconstruct and continue
    content="$before_tag<A $after_tag_start"
    break
  fi
  
  # Ensure we're making progress to avoid infinite loop
  if [[ "$content" == "$original_content" ]]; then
    break
  fi
  original_content="$content"
done

echo "Final content after processing:"
echo "$content"