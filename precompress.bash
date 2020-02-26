#!/bin/bash

# Pre-compress HTML, CSS, JS and SVG files.
printf "Pre-compressing HTML, CSS, JS and SVG files\n"
find . -type f \( \
    -name \*.html -o \
    -name \*.css -o \
    -name \*.js -o \
    -name \*.svg -o \
    -name \*.xml -o \
    -name \*.json \
\) | while read filepath
do
    printf '    %s:' "${filepath}"

    # GZip only if source is newer than destination.
    if [ "${filepath}" -nt "${filepath}.gz" ]
    then
        printf ' gzip'
        zopfli --i127 -c "${filepath}" > "${filepath}.gz"
    fi

    # Brotli only if source is newer than destination.
    if [ "${filepath}" -nt "${filepath}.br" ]
    then
        printf ' brotli'
        brotli --best -c "${filepath}" > "${filepath}.br"
    fi

    printf ' done\n'
done

# Convert PNG and JPEG to WEBP.
printf "Pre-converting PNG and JPEG to WEBP\n"
find . -type f \( -name \*.png -o -name \*.jpg \) | \
while read filepath
do
    printf '    %s:' "${filepath}"

    # Convert only if source is newer than destination
    if [ "${filepath}" -nt "${filepath}.webp" ]
    then
        printf ' webp'

        # Handles lossy and lossless images differently.
        if [ ${filepath: -4} == ".jpg" ]
        then
            cwebp -pass 10 \
                  -af \
                  -sharp_yuv \
                  "${filepath}" \
                  -o "${filepath}.webp" \
                  2> /dev/null
        else
            cwebp -near_lossless 50 \
                  -q 100 \
                  -alpha_q 50 \
                  -mt \
                  "${filepath}" \
                  -o "${filepath}.webp" \
                  2> /dev/null
        fi
    fi

    printf ' done\n'
done
