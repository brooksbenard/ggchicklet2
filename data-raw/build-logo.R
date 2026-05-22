#!/usr/bin/env Rscript
# Builds the ggchicklet2 hex logo using hexSticker::sticker().
#
# This is the snippet the maintainer settled on. Source artwork is
# committed at data-raw/logo-source.png so the build is reproducible
# from a clone of the repo. Output goes to man/figures/logo.png.
#
# `s_width = s_height = 2.15` fills the hex without spilling the
# artwork past the gold rim; at that size the artwork's own white
# background does fill the four canvas-corner triangles outside the
# rim though, so we follow up with a {magick} flood-fill from each
# corner region to clear the spillage back to transparent. The
# gold rim is a closed boundary so the flood stops at the rim and
# the white inside the hex is untouched.
#
# Reference: https://github.com/GuangchuangYu/hexSticker
#
# Usage:  Rscript data-raw/build-logo.R

library(hexSticker)

hex_logo <- magick::image_read("data-raw/logo-source.png")

sticker(hex_logo, package = "",
        s_x = 1, s_y = 1, s_width = 2.15, s_height = 2.15,
        h_color = "#C09F56", h_fill = "white",
        filename = "man/figures/logo.png")

local({
  img <- magick::image_read("man/figures/logo.png")
  info <- magick::image_info(img)
  w <- info$width
  h <- info$height

  # Seeds sit safely inside each of the four canvas-corner triangles
  # that fall outside the hex but inside the PNG bounding box. We use
  # an offset of 50 px from each canvas corner — well inside the
  # corner triangle for a 518x600 canvas.
  inset <- 50L
  seeds <- list(
    c(inset,         inset),
    c(w - 1 - inset, inset),
    c(inset,         h - 1 - inset),
    c(w - 1 - inset, h - 1 - inset)
  )

  for (s in seeds) {
    img <- magick::image_fill(
      img,
      color    = "transparent",
      point    = sprintf("+%d+%d", s[1], s[2]),
      refcolor = "white",
      fuzz     = 10
    )
  }

  magick::image_write(img, "man/figures/logo.png", format = "png")
})
