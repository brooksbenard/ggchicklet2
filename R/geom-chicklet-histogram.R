#' Chicklet (rounded) histogram
#'
#' A drop-in replacement for [ggplot2::geom_histogram()] (and by extension
#' [ggplot2::geom_bar()]) that renders each bar as a rounded rectangle
#' ("chicklet") instead of a sharp rectangle. Implemented as a real
#' `ggproto` (`GeomChickletHistogram`) inheriting from [ggplot2::GeomBar]
#' and using [ggplot2::StatBin] for stat computation, so it supports the
#' full bar/histogram aesthetic set (`x`/`y`, `weight`, `fill`, `colour`,
#' `linewidth`, `linetype`, `alpha`), horizontal orientation
#' (`orientation = "y"` / [ggplot2::coord_flip()]), faceting, and
#' position adjustments (`"stack"`, `"identity"`, [ggplot2::position_dodge()]).
#'
#' All four corners of every bar are rounded — this matches the behaviour
#' of the other chicklet geoms ([geom_chicklet()], [geom_rrect()]). For
#' typical baseline-aligned histograms this means the bottom edges sit
#' slightly off the x-axis baseline (by `radius`); reduce `radius` if
#' that gap is visually distracting.
#'
#' Polar / non-linear coordinate systems are not supported; in those
#' cases the bars fall back to ordinary (sharp-cornered) rendering
#' inherited from [ggplot2::GeomBar].
#'
#' @inheritParams ggplot2::layer
#' @inheritParams ggplot2::geom_histogram
#' @param radius corner radius of each bar, supplied as a [grid::unit()].
#'   Defaults to `grid::unit(3, "pt")`, matching [geom_chicklet()].
#' @return A ggplot2 [ggplot2::layer()].
#' @export
#' @examples
#' library(ggplot2)
#'
#' # Continuous data: standard histogram of response lengths
#' data("debates2019", package = "ggchicklet2")
#' ggplot(debates2019, aes(elapsed)) +
#'   geom_chicklet_histogram(
#'     binwidth = 0.1,
#'     fill     = "#436f82",
#'     colour   = "white",
#'     radius   = grid::unit(2, "pt")
#'   ) +
#'   labs(x = "Minutes per response", y = "Count") +
#'   theme_minimal()
#'
#' # Stacked by topic
#' featured <- c("Healthcare", "Foreign Policy", "Immigration",
#'               "Gun Control", "Economy", "Climate")
#' db <- subset(debates2019, topic %in% featured)
#' db$topic <- factor(db$topic, levels = featured)
#' ggplot(db, aes(elapsed, fill = topic)) +
#'   geom_chicklet_histogram(
#'     binwidth = 0.15,
#'     colour   = "white",
#'     radius   = grid::unit(2, "pt")
#'   ) +
#'   theme_minimal()
geom_chicklet_histogram <- function(mapping = NULL, data = NULL,
                                    stat        = "bin",
                                    position    = "stack",
                                    ...,
                                    binwidth    = NULL,
                                    bins        = NULL,
                                    radius      = grid::unit(3, "pt"),
                                    na.rm       = FALSE,
                                    orientation = NA,
                                    show.legend = NA,
                                    inherit.aes = TRUE) {
  params <- rlang::list2(
    binwidth    = binwidth,
    bins        = bins,
    radius      = radius,
    na.rm       = na.rm,
    orientation = orientation,
    pad         = FALSE,
    ...
  )
  # Drop NULL entries (binwidth, bins, etc.) so they don't get
  # re-interpreted as empty aesthetics by ggplot2's layer machinery.
  params <- params[lengths(params) > 0L]

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomChickletHistogram,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = params
  )
}

#' Chicklet (rounded) bar chart
#'
#' Convenience wrapper around [geom_chicklet_histogram()] with
#' `stat = "count"` and `position = "stack"`, mirroring
#' [ggplot2::geom_bar()] for discrete `x`. Use this when your `x`
#' aesthetic is already categorical / factor-valued and you just want
#' counts per level rendered as rounded bars.
#'
#' @inheritParams geom_chicklet_histogram
#' @inheritParams ggplot2::geom_bar
#' @param width bar width. If `NULL` (the default), uses 90% of the
#'   resolution of the x-axis (same convention as [ggplot2::geom_bar()]).
#' @return A ggplot2 [ggplot2::layer()].
#' @export
#' @examples
#' library(ggplot2)
#' data("debates2019", package = "ggchicklet2")
#'
#' # Counts of responses per candidate
#' spk_order <- names(sort(table(debates2019$speaker)))
#' debates2019$speaker <- factor(debates2019$speaker, levels = spk_order)
#' ggplot(debates2019, aes(speaker)) +
#'   geom_chicklet_bar(fill = "#436f82", radius = grid::unit(2, "pt")) +
#'   coord_flip() +
#'   theme_minimal()
geom_chicklet_bar <- function(mapping = NULL, data = NULL,
                              stat        = "count",
                              position    = "stack",
                              ...,
                              width       = NULL,
                              radius      = grid::unit(3, "pt"),
                              na.rm       = FALSE,
                              orientation = NA,
                              show.legend = NA,
                              inherit.aes = TRUE) {
  params <- rlang::list2(
    width       = width,
    radius      = radius,
    na.rm       = na.rm,
    orientation = orientation,
    ...
  )
  # Drop NULL entries so they don't get re-interpreted as empty aesthetics
  # by ggplot2's layer-construction machinery.
  params <- params[lengths(params) > 0L]

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomChickletHistogram,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = params
  )
}

#' @rdname geom_chicklet_histogram
#' @format NULL
#' @usage NULL
#' @export
GeomChickletHistogram <- ggplot2::ggproto( # nocov start
  "GeomChickletHistogram", ggplot2::GeomBar,

  draw_panel = function(self, data, panel_params, coord,
                        lineend  = "butt",
                        linejoin = "mitre",
                        radius   = grid::unit(3, "pt")) {

    # Fall back to the parent's (sharp-cornered) renderer in non-linear
    # coordinate systems — rounded corners under polar projection would
    # require building polygonal approximations of arcs, which is out of
    # scope for this geom.
    if (!coord$is_linear()) {
      return(ggproto_parent(ggplot2::GeomBar, self)$draw_panel(
        data, panel_params, coord, lineend = lineend, linejoin = linejoin
      ))
    }

    if (is.null(data$linewidth)) data$linewidth <- 0.5
    data$linewidth[is.na(data$linewidth)] <- 0.5

    box_grob <- draw_chicklet_box(data, panel_params, coord, radius = radius)
    ggname("geom_chicklet_histogram", grid::grobTree(children = box_grob))
  },

  draw_key = draw_key_rrect
) # nocov end
