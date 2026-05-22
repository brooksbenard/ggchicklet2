#!/usr/bin/env Rscript
# Builds man/figures/logo.png from data-raw/logo-source.png using
# hexSticker::sticker() (https://github.com/GuangchuangYu/hexSticker)
# to draw the brand-gold hex border.
#
# `sticker()` renders its subplot as a flat rectangle, so it does not
# clip the artwork to the hex shape on its own. To get clean transparent
# corners we first pre-shape the artwork ourselves with {magick}:
#
#   1. Trim the white margin around the source PNG.
#   2. Pad to a point-top hex aspect ratio (W : H = 1 : 2/sqrt(3)) on
#      white, so the artwork sits centred inside the eventual hex.
#   3. Punch out the four corners with a hex polygon alpha mask, so
#      everything outside the hex outline is transparent.
#
# Then we hand that hex-shaped PNG to `hexSticker::sticker()` with:
#   - `package = ""` + `p_size = 0` to suppress the auto-rendered
#     package label (the artwork already says "ggchicklet2").
#   - `s_width = 0.85`, tuned empirically (ggimage::geom_image()'s `size`
#     is npc-relative and non-linear), so the hex-shaped artwork sits
#     flush against the inside of the gold rim.
#   - `h_color = "#C09F56"` to stroke the border in the brand-gold
#     colour the user supplied. `h_fill = "white"` paints the hex
#     interior to match the artwork's own background, hiding the seam
#     where the trim ends.
#
# Usage:  Rscript data-raw/build-logo.R

req <- c("magick", "hexSticker", "ggimage", "showtext")
missing <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install missing packages: ",
       paste(sprintf("'%s'", missing), collapse = ", "))
}

src <- "data-raw/logo-source.png"
dst <- "man/figures/logo.png"
border_color <- "#C09F56"

if (!file.exists(src)) {
  stop("Missing source artwork: ", src)
}

dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)

# 1) Trim + pad to hex aspect + hex alpha mask via {magick}.
img <- magick::image_read(src)
img <- magick::image_trim(img, fuzz = 4)

info <- magick::image_info(img)
w <- info$width
h_target <- round(w * 2 / sqrt(3))
if (info$height < h_target) {
  img <- magick::image_extent(
    img,
    geometry = sprintf("%dx%d", w, h_target),
    gravity  = "center",
    color    = "white"
  )
} else {
  w_target <- round(info$height * sqrt(3) / 2)
  img <- magick::image_crop(
    img,
    geometry = sprintf("%dx%d+0+0", w_target, info$height),
    gravity  = "center"
  )
}

info <- magick::image_info(img)
w <- info$width
h <- info$height
hex_x <- c(w / 2, w,     w,         w / 2, 0,         0)
hex_y <- c(0,     h / 4, 3 * h / 4, h,     3 * h / 4, h / 4)

mask <- magick::image_blank(width = w, height = h, color = "transparent")
mask <- magick::image_draw(mask, antialias = TRUE)
graphics::polygon(hex_x, hex_y, col = "white", border = NA)
grDevices::dev.off()

img <- magick::image_composite(img, mask, operator = "CopyOpacity")

trimmed_png <- tempfile(fileext = ".png")
magick::image_write(img, trimmed_png, format = "png")

# 2) Use hexSticker::sticker() to draw the gold border around it.
# hexSticker uses ggimage::geom_image(), whose `size` is npc-relative,
# so we tune empirically to make the hex-masked artwork fill the rim.
hexSticker::sticker(
  subplot              = trimmed_png,
  package              = "",
  p_size               = 0,
  s_x                  = 1,
  s_y                  = 1,
  s_width              = 0.85,
  h_fill               = "white",
  h_color              = border_color,
  h_size               = 1.6,
  white_around_sticker = FALSE,
  filename             = dst,
  dpi                  = 300
)

# Up-sample to a 600 px wide PNG for retina-friendly README rendering.
magick::image_read(dst) |>
  magick::image_resize("600x") |>
  magick::image_write(dst, format = "png", quality = 95)

final <- magick::image_info(magick::image_read(dst))
message("Wrote ", dst, " (", final$width, "x", final$height,
        ", border = ", border_color, ")")
