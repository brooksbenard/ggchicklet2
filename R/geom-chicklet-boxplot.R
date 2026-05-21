#' Chicklet (rounded) boxplot
#'
#' A drop-in replacement for [ggplot2::geom_boxplot()] that draws the box
#' body as a rounded rectangle ("chicklet") while delegating whisker,
#' staple, outlier, and median rendering to the standard ggplot2 boxplot
#' primitives.
#'
#' Because this geom inherits from [ggplot2::GeomBoxplot] and uses
#' [ggplot2::StatBoxplot] for stat computation, it supports the full
#' boxplot aesthetic set (`x`/`y`, `lower`, `upper`, `middle`, `ymin`,
#' `ymax`, `fill`, `colour`, `linewidth`, `linetype`, `alpha`, `weight`)
#' as well as horizontal orientation (via [ggplot2::coord_flip()] or
#' setting `orientation = "y"`) and grouped dodging via
#' [ggplot2::position_dodge2()].
#'
#' Notched boxplots are intentionally *not* supported because the notch
#' geometry is incompatible with rounded corners; the `notch` and
#' `notchwidth` arguments are accepted for signature compatibility but
#' silently ignored.
#'
#' @inheritParams ggplot2::layer
#' @inheritParams ggplot2::geom_boxplot
#' @param radius corner radius of the box body, supplied as a [grid::unit()].
#'   Defaults to `grid::unit(3, "pt")`, matching [geom_chicklet()].
#' @return A ggplot2 [ggplot2::layer()].
#' @export
#' @examples
#' library(ggplot2)
#'
#' ggplot(iris, aes(Species, Sepal.Length, fill = Species)) +
#'   geom_chicklet_boxplot(radius = grid::unit(4, "pt")) +
#'   theme_minimal()
#'
#' # Dodged: secondary grouping via `fill`
#' mt <- transform(mtcars,
#'                 cyl  = factor(cyl),
#'                 gear = factor(gear))
#' ggplot(mt, aes(cyl, mpg, fill = gear)) +
#'   geom_chicklet_boxplot(radius = grid::unit(2, "pt"),
#'                         staplewidth = 0.5) +
#'   theme_minimal()
geom_chicklet_boxplot <- function(mapping = NULL, data = NULL,
                                  stat = "boxplot",
                                  position = "dodge2",
                                  ...,
                                  outliers          = TRUE,
                                  outlier.colour    = NULL,
                                  outlier.color     = NULL,
                                  outlier.fill      = NULL,
                                  outlier.shape     = NULL,
                                  outlier.size      = NULL,
                                  outlier.stroke    = 0.5,
                                  outlier.alpha     = NULL,
                                  whisker.colour    = NULL,
                                  whisker.color     = NULL,
                                  whisker.linetype  = NULL,
                                  whisker.linewidth = NULL,
                                  staple.colour     = NULL,
                                  staple.color      = NULL,
                                  staple.linetype   = NULL,
                                  staple.linewidth  = NULL,
                                  median.colour     = NULL,
                                  median.color      = NULL,
                                  median.linetype   = NULL,
                                  median.linewidth  = NULL,
                                  box.colour        = NULL,
                                  box.color         = NULL,
                                  box.linetype      = NULL,
                                  box.linewidth     = NULL,
                                  notch       = FALSE,
                                  notchwidth  = 0.5,
                                  staplewidth = 0,
                                  varwidth    = FALSE,
                                  radius      = grid::unit(3, "pt"),
                                  na.rm       = FALSE,
                                  orientation = NA,
                                  show.legend = NA,
                                  inherit.aes = TRUE) {

  if (isTRUE(notch)) {
    warning(
      "`notch = TRUE` is not supported by `geom_chicklet_boxplot()`; ",
      "the notch will be ignored.",
      call. = FALSE
    )
  }

  if (is.character(position)) {
    if (isTRUE(varwidth)) position <- ggplot2::position_dodge2(preserve = "single")
  } else {
    if (identical(position$preserve, "total") && isTRUE(varwidth)) {
      warning(
        "Can't preserve total widths when `varwidth = TRUE`.",
        call. = FALSE
      )
      position$preserve <- "single"
    }
  }

  outlier_gp <- list(
    colour = outlier.color %||% outlier.colour,
    fill   = outlier.fill,
    shape  = outlier.shape,
    size   = outlier.size,
    stroke = outlier.stroke,
    alpha  = outlier.alpha
  )
  whisker_gp <- list(
    colour    = whisker.color %||% whisker.colour,
    linetype  = whisker.linetype,
    linewidth = whisker.linewidth
  )
  staple_gp <- list(
    colour    = staple.color %||% staple.colour,
    linetype  = staple.linetype,
    linewidth = staple.linewidth
  )
  median_gp <- list(
    colour    = median.color %||% median.colour,
    linetype  = median.linetype,
    linewidth = median.linewidth
  )
  box_gp <- list(
    colour    = box.color %||% box.colour,
    linetype  = box.linetype,
    linewidth = box.linewidth
  )

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomChickletBoxplot,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = rlang::list2(
      outliers    = outliers,
      outlier_gp  = outlier_gp,
      whisker_gp  = whisker_gp,
      staple_gp   = staple_gp,
      median_gp   = median_gp,
      box_gp      = box_gp,
      notch       = FALSE,
      notchwidth  = notchwidth,
      staplewidth = staplewidth,
      varwidth    = varwidth,
      radius      = radius,
      na.rm       = na.rm,
      orientation = orientation,
      ...
    )
  )
}

#' @rdname geom_chicklet_boxplot
#' @format NULL
#' @usage NULL
#' @export
GeomChickletBoxplot <- ggplot2::ggproto( # nocov start
  "GeomChickletBoxplot", ggplot2::GeomBoxplot,

  extra_params = c("na.rm", "orientation", "outliers"),

  draw_group = function(self, data, panel_params, coord,
                        lineend      = "butt",
                        linejoin     = "mitre",
                        fatten       = 2,
                        outlier_gp   = NULL,
                        whisker_gp   = NULL,
                        staple_gp    = NULL,
                        median_gp    = NULL,
                        box_gp       = NULL,
                        notch        = FALSE,
                        notchwidth   = 0.5,
                        staplewidth  = 0,
                        varwidth     = FALSE,
                        radius       = grid::unit(3, "pt"),
                        flipped_aes  = FALSE) {

    data <- ggplot2::flip_data(data, flipped_aes)

    if (nrow(data) != 1) {
      stop(
        "Can only draw one chicklet boxplot per group. ",
        "Did you forget aes(group = ...)?",
        call. = FALSE
      )
    }

    if (is.null(data$linewidth)) data$linewidth <- data$size %||% 0.5

    common <- list(group = data$group)

    # ── Whiskers ─────────────────────────────────────────────────────────
    whiskers <- data.frame(
      x         = c(data$x, data$x),
      xend      = c(data$x, data$x),
      y         = c(data$upper, data$lower),
      yend      = c(data$ymax,  data$ymin),
      colour    = rep(whisker_gp$colour    %||% data$colour,    2),
      linetype  = rep(whisker_gp$linetype  %||% data$linetype,  2),
      linewidth = rep(whisker_gp$linewidth %||% data$linewidth, 2),
      alpha     = c(NA_real_, NA_real_),
      group     = rep(common$group, 2),
      stringsAsFactors = FALSE
    )
    whiskers <- ggplot2::flip_data(whiskers, flipped_aes)
    whisker_grob <- ggplot2::GeomSegment$draw_panel(
      whiskers, panel_params, coord, lineend = lineend
    )

    # ── Outliers ─────────────────────────────────────────────────────────
    if (!is.null(data$outliers) && length(data$outliers[[1]]) >= 1) {
      outliers <- data.frame(
        y      = data$outliers[[1]],
        x      = data$x[1],
        colour = outlier_gp$colour %||% data$colour[1],
        fill   = outlier_gp$fill   %||% data$fill[1],
        shape  = outlier_gp$shape  %||% data$shape[1]  %||% 19,
        size   = outlier_gp$size   %||% data$size[1]   %||% 1.5,
        stroke = outlier_gp$stroke %||% data$stroke[1] %||% 0.5,
        alpha  = outlier_gp$alpha  %||% data$alpha[1],
        stringsAsFactors = FALSE
      )
      outliers <- ggplot2::flip_data(outliers, flipped_aes)
      outliers_grob <- ggplot2::GeomPoint$draw_panel(
        outliers, panel_params, coord
      )
    } else {
      outliers_grob <- NULL
    }

    # ── Staples ──────────────────────────────────────────────────────────
    if (staplewidth != 0) {
      staples <- data.frame(
        x         = rep((data$xmin - data$x) * staplewidth + data$x, 2),
        xend      = rep((data$xmax - data$x) * staplewidth + data$x, 2),
        y         = c(data$ymax, data$ymin),
        yend      = c(data$ymax, data$ymin),
        linetype  = rep(staple_gp$linetype  %||% data$linetype,  2),
        linewidth = rep(staple_gp$linewidth %||% data$linewidth, 2),
        colour    = rep(staple_gp$colour    %||% data$colour,    2),
        alpha     = c(NA_real_, NA_real_),
        group     = rep(common$group, 2),
        stringsAsFactors = FALSE
      )
      staples <- ggplot2::flip_data(staples, flipped_aes)
      staple_grob <- ggplot2::GeomSegment$draw_panel(
        staples, panel_params, coord, lineend = lineend
      )
    } else {
      staple_grob <- NULL
    }

    # ── Rounded box body ────────────────────────────────────────────────
    box <- data.frame(
      xmin      = data$xmin,
      xmax      = data$xmax,
      ymin      = data$lower,
      ymax      = data$upper,
      colour    = box_gp$colour    %||% data$colour,
      fill      = data$fill,
      linewidth = box_gp$linewidth %||% data$linewidth,
      linetype  = box_gp$linetype  %||% data$linetype,
      alpha     = data$alpha,
      stringsAsFactors = FALSE
    )
    box <- ggplot2::flip_data(box, flipped_aes)
    box_grob <- draw_chicklet_box(
      box, panel_params, coord,
      radius = radius, lineend = lineend, linejoin = linejoin
    )

    # ── Median line ─────────────────────────────────────────────────────
    median_df <- data.frame(
      x         = data$xmin,
      xend      = data$xmax,
      y         = data$middle,
      yend      = data$middle,
      colour    = median_gp$colour    %||% data$colour,
      linetype  = median_gp$linetype  %||% data$linetype,
      linewidth = (median_gp$linewidth %||% data$linewidth) * fatten,
      alpha     = NA_real_,
      group     = common$group,
      stringsAsFactors = FALSE
    )
    median_df <- ggplot2::flip_data(median_df, flipped_aes)
    median_grob <- ggplot2::GeomSegment$draw_panel(
      median_df, panel_params, coord, lineend = lineend
    )

    ggname(
      "geom_chicklet_boxplot",
      grid::grobTree(
        outliers_grob, staple_grob, whisker_grob, box_grob, median_grob
      )
    )
  },

  draw_key = ggplot2::draw_key_boxplot
) # nocov end

# Internal helper: render a (set of) rounded rectangles for box bodies.
# Mirrors the rendering used by GeomRrect / GeomChicklet so that boxplot
# fill / colour / alpha / linewidth all behave the same way.
draw_chicklet_box <- function(data, panel_params, coord,
                              radius   = grid::unit(3, "pt"),
                              lineend  = "butt",
                              linejoin = "mitre") {

  coords <- coord$transform(data, panel_params)

  grobs <- lapply(seq_len(nrow(coords)), function(i) {
    grid::roundrectGrob(
      x             = coords$xmin[i],
      y             = coords$ymax[i],
      width         = coords$xmax[i] - coords$xmin[i],
      height        = coords$ymax[i] - coords$ymin[i],
      r             = radius,
      default.units = "native",
      just          = c("left", "top"),
      gp = grid::gpar(
        col      = coords$colour[i],
        fill     = ggplot2::fill_alpha(coords$fill[i], coords$alpha[i]),
        lwd      = (coords$linewidth[i] %||% 0.5) * .pt,
        lty      = coords$linetype[i],
        lineend  = lineend,
        linejoin = linejoin
      )
    )
  })

  do.call(grid::gList, grobs)
}
