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
