#! /bin/bash
set -x
target="${1}"

dir="$(dirname "${target}")"
base="$(basename "${target}" .png)"
temp="${3:-$(mktemp -d)}"
stem="${temp}/${base}"

texn=$(<<<"${base}" tr '[:upper:]' '[:lower:]' | tr '-' '_')

outdir="${2:-"${dir}/out"}"

size=$(magick identify "${target}" | cut -d ' ' -f 3)

mkdir -p "${outdir}" "${outdir}/24px" "${outdir}/48px" "${outdir}/72px" "${outdir}/96px" "${outdir}/tex"

magick "${target}" -dither None -colors 8 "${stem}-a.png"
magick "${stem}-a.png" -colorspace LAB -separate "${stem}-a%d.png"
magick \( -size $size xc:gray \)  "${stem}-a1.png" "${stem}-a2.png" "${stem}-a3.png" \
    -combine -set colorspace LAB -colorspace sRGB "${stem}-ac.png"

rgba=$(\
    magick identify -verbose "${stem}-ac.png" \
    | grep '^        ' \
    | grep -v ',0)' \
    | sort -rn \
    | head -n 1 \
    | cut -d '(' -f 2 | cut -d ')' -f 1 \
)

r=$(cut -d , -f 1 <<<$rgba)
g=$(cut -d , -f 2 <<<$rgba)
b=$(cut -d , -f 3 <<<$rgba)
z=65535

magick "${target}" -colorspace LAB -separate "${stem}-%d.png"
magick \( -size $size xc:gray \)  "${stem}-1.png" "${stem}-2.png" "${stem}-3.png" \
    -combine -set colorspace LAB -colorspace sRGB "${stem}-c.png"

magick "${stem}-c.png" \
    -channel red -fx "u.r+(0.5-($r/$z))" \
    -channel green -fx "u.g+(0.5-($g/$z))" \
    -channel blue -fx "u.b+(0.5-($b/$z))" \
    "${stem}-sc.png"

    
y=$(\
    magick identify -verbose "${stem}-0.png" \
    | grep max \
    | cut -d '(' -f 2 | cut -d ')' -f 1 \
    | tr '\n' '\t' \
    | cut -f 1 \
)

magick "${stem}-0.png" -fx "u/$y" "${stem}-0c.png"

magick "${stem}-sc.png" -colorspace LAB -separate "${stem}-s%d.png"

magick "${stem}-0c.png" "${stem}-s1.png" "${stem}-s2.png" "${stem}-3.png" \
    -combine -set colorspace LAB -colorspace sRGB "${outdir}/${base}.png"

magick "${outdir}/${base}.png" -resize 24x24 -dither None -colors 16 "${outdir}/24px/${base}.png"
cp "${outdir}/24px/${base}.png" "${outdir}/tex/${texn}_sm_0_1.png"
cp "${outdir}/24px/${base}.png" "${outdir}/tex/${texn}_sm_0_2.png"
cp "${outdir}/24px/${base}.png" "${outdir}/tex/${texn}_sm_0_3.png"
magick "${outdir}/${base}.png" -resize 48x48 -dither None -colors 16 "${outdir}/48px/${base}.png"
cp "${outdir}/48px/${base}.png" "${outdir}/tex/${texn}_md_0_1.png"
cp "${outdir}/48px/${base}.png" "${outdir}/tex/${texn}_md_0_2.png"
cp "${outdir}/48px/${base}.png" "${outdir}/tex/${texn}_md_0_3.png"
magick "${outdir}/${base}.png" -resize 72x72 -dither None -colors 16 "${outdir}/72px/${base}.png"
cp "${outdir}/72px/${base}.png" "${outdir}/tex/${texn}_lg_0_1.png"
cp "${outdir}/72px/${base}.png" "${outdir}/tex/${texn}_lg_0_2.png"
cp "${outdir}/72px/${base}.png" "${outdir}/tex/${texn}_lg_0_3.png"
magick "${outdir}/${base}.png" -resize 96x96 -dither None -colors 16 "${outdir}/96px/${base}.png"
cp "${outdir}/96px/${base}.png" "${outdir}/tex/${texn}_xl_0_1.png"
cp "${outdir}/96px/${base}.png" "${outdir}/tex/${texn}_xl_0_2.png"
cp "${outdir}/96px/${base}.png" "${outdir}/tex/${texn}_xl_0_3.png"
