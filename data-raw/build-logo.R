#!/usr/bin/env Rscript
# Builds man/figures/logo.png from data-raw/logo-source.png.
#
# Pipeline (using the {magick} R package, which wraps libMagickWand
# directly so we avoid shell-quoting issues with %h, parens, etc.):
#
#   1. Trim the off-white "card" border that surrounds the hex artwork.
#   2. Crop the result to a point-top hex aspect ratio (W:H = 1 : 2/sqrt(3)),
#      centering the existing hex.
#   3. Apply a polygon alpha mask in the shape of a point-top hexagon
#      so the four corners outside the gold border become transparent.
#   4. Resize to 600px wide and write to man/figures/logo.png.
#
# Usage:  Rscript data-raw/build-logo.R

if (!requireNamespace("magick", quietly = TRUE)) {
  stop("Install the {magick} R package: install.packages('magick')")
}

src <- "data-raw/logo-source.png"
dst <- "man/figures/logo.png"

if (!file.exists(src)) {
  stop("Missing source artwork: ", src)
}

# 1) Read + trim grey background to the white card containing the hex artwork.
img <- magick::image_read(src)
img <- magick::image_trim(img, fuzz = 8)

# 2) Crop to point-top hex aspect (W : H = 1 : 2/sqrt(3)).
info <- magick::image_info(img)
w <- info$width
h <- round(w * 2 / sqrt(3))
img <- magick::image_crop(
  img,
  geometry = sprintf("%dx%d+0+0", w, h),
  gravity  = "center"
)

# 3) Build a point-top hex polygon mask (white on transparent) and use it
#    to mask the artwork's alpha channel.
poly <- sprintf(
  "%d,0 %d,%d %d,%d %d,%d 0,%d 0,%d",
  w %/% 2L,                  # top
  w,        h %/% 4L,        # upper-right
  w,        (3L * h) %/% 4L, # lower-right
  w %/% 2L, h,               # bottom
  (3L * h) %/% 4L,           # lower-left  (y of)
  h %/% 4L                   # upper-left  (y of)
)

mask <- magick::image_blank(width = w, height = h, color = "transparent")
mask <- magick::image_draw(mask)
graphics::polygon(
  x = c(w / 2,  w,           w,             w / 2,  0,             0),
  y = c(0,      h / 4,       3 * h / 4,     h,      3 * h / 4,     h / 4),
  col    = "white",
  border = NA
)
grDevices::dev.off()

img <- magick::image_composite(img, mask, operator = "CopyOpacity")

# 4) Resize and write final logo.
img <- magick::image_resize(img, "600x")

dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
magick::image_write(img, dst, format = "png", quality = 95)

message("Wrote ", dst, " (",
        magick::image_info(img)$width, "x",
        magick::image_info(img)$height, ")")
