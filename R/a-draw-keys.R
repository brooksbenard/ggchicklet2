#' Shared legend key for chicklet geoms
#'
#' Internal `draw_key` function shared by [geom_chicklet()],
#' [geom_chicklet_bar()], [geom_chicklet_histogram()], and
#' [geom_chicklet_boxplot()] so that all chicklet legends render with
#' the same rounded-rectangle ("chicklet") look. The legend-key radius
#' is capped at `unit(3, "pt")` so very large geom radii don't blow up
#' the small legend swatch.
#'
#' This file is named `a-draw-keys.R` purely so it sorts before the
#' geom files in alphabetical install order — `ggproto` evaluates its
#' `draw_key` slot eagerly, so the function must exist when each
#' `GeomChickletXxx` is constructed.
#'
#' @param data,params,size standard `ggplot2` `draw_key` arguments.
#' @return A grid grob.
#' @keywords internal
#' @noRd
draw_key_rrect <- function(data, params, size) { # nocov start
  key_radius <- params$radius %||% grid::unit(3, "pt")
  if (inherits(key_radius, "unit")) {
    key_radius <- min(key_radius, grid::unit(3, "pt"))
  } else {
    key_radius <- grid::unit(3, "pt")
  }

  grid::roundrectGrob(
    r             = key_radius,
    default.units = "native",
    width         = 1,
    height        = 0.6,
    name          = "lkey",
    gp = grid::gpar(
      col      = params$colour %l0% (data$colour %||% NA),
      fill     = alpha(data$fill %||% data$colour %||% "grey20", data$alpha),
      lwd      = (data$linewidth %||% data$size %||% 0.5) * .pt,
      lty      = data$linetype %||% 1,
      lineend  = "round",
      linejoin = "round"
    )
  )
} # nocov end
