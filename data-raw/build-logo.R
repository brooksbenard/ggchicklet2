#!/usr/bin/env Rscript
# Builds man/figures/logo.png from data-raw/logo-source.png.
#
# Pipeline (using the {magick} R package, which wraps libMagickWand
# directly so we avoid shell-quoting issues with %h, parens, etc.):
#
#   1. Trim the white margin around the source artwork.
#   2. Pad to a point-top hex aspect ratio (W:H = 1 : 2/sqrt(3)) with a
#      white background, centering the existing artwork.
#   3. Apply a polygon alpha mask in the shape of a point-top hexagon
#      so the four corners outside the hex shape become transparent.
#   4. Stroke the hex outline in the brand-gold colour `border_color`
#      so the sticker has a visible coloured rim.
#   5. Resize to 600px wide and write to man/figures/logo.png.
#
# Usage:  Rscript data-raw/build-logo.R

if (!requireNamespace("magick", quietly = TRUE)) {
  stop("Install the {magick} R package: install.packages('magick')")
}

src <- "data-raw/logo-source.png"
dst <- "man/figures/logo.png"

# Brand-gold border colour, sampled from the swatch supplied by the user.
border_color <- "#C09F56"
# Stroke width in *source-pixel* units, before the final resize. The image
# will be downsampled ~38% (~990 -> 600 wide) so a 12 px stroke ends up
# rendering at roughly 7 px on the final logo.
border_width <- 12

if (!file.exists(src)) {
  stop("Missing source artwork: ", src)
}

# 1) Read + trim white background.
img <- magick::image_read(src)
img <- magick::image_trim(img, fuzz = 4)

# 2) Pad to point-top hex aspect (W : H = 1 : 2/sqrt(3)) with white.
info <- magick::image_info(img)
w_src <- info$width
h_target <- round(w_src * 2 / sqrt(3))
if (info$height < h_target) {
  img <- magick::image_extent(
    img,
    geometry = sprintf("%dx%d", w_src, h_target),
    gravity  = "center",
    color    = "white"
  )
} else {
  # Source already taller than hex aspect; crop sides to match.
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

# Point-top hex polygon vertices for a W x H bounding box.
hex_x <- c(w / 2, w,     w,         w / 2, 0,         0)
hex_y <- c(0,     h / 4, 3 * h / 4, h,     3 * h / 4, h / 4)

# 3) Alpha mask: white-filled hex on transparent background, then
#    composite via CopyOpacity to clip the corners.
mask <- magick::image_blank(width = w, height = h, color = "transparent")
mask <- magick::image_draw(mask, antialias = TRUE)
graphics::polygon(hex_x, hex_y, col = "white", border = NA)
grDevices::dev.off()

img <- magick::image_composite(img, mask, operator = "CopyOpacity")

# 4) Gold hex border: stroke the same polygon, no fill, on a transparent
#    layer, then composite over the masked artwork.
border_layer <- magick::image_blank(width = w, height = h, color = "transparent")
border_layer <- magick::image_draw(border_layer, antialias = TRUE)
graphics::polygon(
  hex_x, hex_y,
  col    = NA,
  border = border_color,
  lwd    = border_width,
  ljoin  = 1   # rounded corners on the stroke joins
)
grDevices::dev.off()

img <- magick::image_composite(img, border_layer, operator = "Over")

# 5) Resize and write.
img <- magick::image_resize(img, "600x")

dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
magick::image_write(img, dst, format = "png", quality = 95)

final <- magick::image_info(img)
message("Wrote ", dst, " (", final$width, "x", final$height,
        ", border = ", border_color, ")")
