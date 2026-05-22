#!/usr/bin/env Rscript
# Builds the ggchicklet2 hex logo using hexSticker::sticker().
#
# This is the snippet the maintainer settled on. Source artwork is
# committed at data-raw/logo-source.png so the build is reproducible
# from a clone of the repo. Output goes to man/figures/logo.png.
#
# Reference: https://github.com/GuangchuangYu/hexSticker
#
# Usage:  Rscript data-raw/build-logo.R

library(hexSticker)

hex_logo <- magick::image_read("data-raw/logo-source.png")

sticker(hex_logo, package = "",
        s_x = 1, s_y = .95, s_width = 2.4, s_height = 2.4,
        h_color = "#C09F56", h_fill = "white",
        filename = "man/figures/logo.png")

# hexSticker draws the subplot as a rectangle, so the four corners
# outside the hex but inside the PNG bounding box keep the source
# artwork's white background. Punch them out with a hex alpha mask so
# the saved PNG is genuinely hex-shaped.
#
# The mask polygon is the hexSticker hex outset by `outset_px` so the
# gold border isn't clipped by the antialiased mask edge.
local({
  img <- magick::image_read("man/figures/logo.png")
  info <- magick::image_info(img)
  w <- info$width
  h <- info$height

  # hexSticker's theme_sticker() pads the panel beyond the hex by
  # m = 1.02 + h_size * 0.04 in plot units (h_size default is 1.2).
  h_size <- 1.2
  m <- 1.02 + h_size * 0.04
  x_min <- 1 - sqrt(3) / 2 * m
  x_w   <- 2 * sqrt(3) / 2 * m
  y_min <- 1 - m
  y_h   <- 2 * m

  # Point-top hex vertices in plot units (radius 1, centred at (1, 1)).
  hx <- c(1,
          1 + sqrt(3) / 2,
          1 + sqrt(3) / 2,
          1,
          1 - sqrt(3) / 2,
          1 - sqrt(3) / 2)
  hy <- c(2, 1.5, 0.5, 0, 0.5, 1.5)

  # Convert plot units -> PNG pixel coords.
  px_x <- (hx - x_min) / x_w * w
  px_y <- (1 - (hy - y_min) / y_h) * h

  # Outset the mask slightly so the gold rim is preserved through the
  # mask's antialiased edge. 4 px is enough for the default border width.
  outset_px <- 4
  cx <- w / 2
  cy <- h / 2
  rx <- sqrt((px_x - cx)^2 + (px_y - cy)^2)
  scale <- (rx + outset_px) / rx
  px_x <- cx + (px_x - cx) * scale
  px_y <- cy + (px_y - cy) * scale

  mask <- magick::image_blank(width = w, height = h, color = "transparent")
  mask <- magick::image_draw(mask, antialias = TRUE)
  graphics::polygon(px_x, px_y, col = "white", border = NA)
  grDevices::dev.off()

  img <- magick::image_composite(img, mask, operator = "CopyOpacity")
  magick::image_write(img, "man/figures/logo.png", format = "png")
})
