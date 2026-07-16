#!/usr/bin/env Rscript
# Builds the ggchicklet2 hex logo using hexSticker::sticker().
#
# Source artwork is committed at data-raw/logo-source.png so the build
# is reproducible from a clone of the repo. Output goes to
# man/figures/logo.png.
#
# The source artwork already carries the "ggchicklet2" wordmark, so we
# pass package = "" and let hexSticker only draw the hex frame. The
# artwork is a near-square, full-bleed illustration on a white
# background whose content is bottom-heavy (the green bars / coop base
# reach the lower edge). We size it as large as possible while keeping
# every pixel inside the gold rim: nudging it up with `s_y = 1.15`
# balances the top and bottom clearances, which lets `s_width =
# s_height = 1.59` fit without any content crossing the boundary. The
# artwork's white background matches the hex fill (`h_fill = "white"`),
# so the two blend seamlessly and the canvas corners outside the hex
# stay transparent.
#
# Reference: https://github.com/GuangchuangYu/hexSticker
#
# Usage:  Rscript data-raw/build-logo.R

library(hexSticker)

hex_logo <- magick::image_read("data-raw/logo-source.png")

# hexSticker defaults to dpi = 300, which yields a 518x600 canvas --
# small enough that the artwork looks pixelated when displayed. The
# source art is ~1475 px wide, so we render at dpi = 900 (~1554 px
# wide) to match the source resolution and keep the logo crisp. dpi
# only changes the output resolution; the s_x / s_y / s_width framing
# is in relative units and is unaffected.
sticker(hex_logo, package = "",
        s_x = 0.96, s_y = 1.15, s_width = 1.5, s_height = 1.5,
        h_color = "#C09F56", h_fill = "white",
        dpi = 900,
        filename = "man/figures/logo.png")
