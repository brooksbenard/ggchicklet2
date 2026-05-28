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
      radius = radius
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
    median_seg <- ggplot2::GeomSegment$draw_panel(
      median_df, panel_params, coord, lineend = lineend
    )

    # Clip the median line to the rounded box shape. The median is drawn from
    # data$xmin to data$xmax horizontally; at small radii that is identical to
    # the box's straight edge, but as the corner radius grows toward
    # min(width, height) / 2 the box body curves inward at the median's
    # y-position and the unclipped segment pokes out past the curved sides
    # (most visible when the box becomes a pill / oval). Wrapping the segment
    # in a viewport whose `clip` is a same-shaped roundrectGrob makes grid
    # cut the segment back to the actual rendered box outline.
    median_grob <- median_with_chicklet_clip(
      median_seg, box, panel_params, coord, radius = radius
    )

    ggname(
      "geom_chicklet_boxplot",
      grid::grobTree(
        outliers_grob, staple_grob, whisker_grob, box_grob, median_grob
      )
    )
  },

  draw_key = draw_key_rrect
) # nocov end

# Internal helper: render a (set of) rounded rectangles for box bodies.
# Mirrors the rendering used by GeomRrect / GeomChicklet so that boxplot
# fill / colour / alpha / linewidth all behave the same way.
#
# Note: `lineend` and `linejoin` are intentionally pinned to "round" here.
# `grid::roundrectGrob()` builds its border from arc + straight-segment
# sub-paths; with the boxplot defaults (`linejoin = "mitre"`,
# `lineend = "butt"`) the mitre joins at each arc-to-edge seam produce
# small visible spikes at the four corners. Using "round" for both
# eliminates the spikes and matches what upstream GeomChicklet/GeomRrect
# get from `gpar()`'s defaults.
draw_chicklet_box <- function(data, panel_params, coord,
                              radius = grid::unit(3, "pt"),
                              ...) {

  coords <- coord$transform(data, panel_params)

  grobs <- lapply(seq_len(nrow(coords)), function(i) {
    chicklet_box_grob(
      xmin   = coords$xmin[i],
      xmax   = coords$xmax[i],
      ymin   = coords$ymin[i],
      ymax   = coords$ymax[i],
      radius = radius,
      gp = grid::gpar(
        col      = coords$colour[i],
        fill     = ggplot2::fill_alpha(coords$fill[i], coords$alpha[i]),
        lwd      = (coords$linewidth[i] %||% 0.5) * .pt,
        lty      = coords$linetype[i],
        lineend  = "round",
        linejoin = "round"
      )
    )
  })

  do.call(grid::gList, grobs)
}

# Internal helper: cap `radius` (a grid unit, e.g. 3 pt) so that the
# corner arcs of a roundrectGrob with the given native-coord bounds
# never exceed half the box width or half the box height.
#
# `grid::roundrectGrob()` does not do this clamping itself: if `r` is
# specified in physical units (pt, mm, ...) and converts to a native
# value larger than `min(width, height) / 2`, the four corner arcs
# overlap and the resulting *path* self-intersects (we end up with a
# lens / vesica shape rather than a stadium). That breaks two things:
#  - the visible box body no longer matches a rounded rectangle, and
#  - any clipping path built from the same path geometry no longer
#    matches the visible fill, so a median segment clipped against it
#    can poke out past the curved sides.
#
# Must be called at draw time (inside `makeContent`) because the
# pt <-> native conversion depends on the active viewport.
cap_chicklet_radius <- function(xmin, xmax, ymin, ymax, radius) {
  half_w_pt <- grid::convertWidth(
    grid::unit(abs(xmax - xmin) / 2, "native"), "pt", valueOnly = TRUE
  )
  half_h_pt <- grid::convertHeight(
    grid::unit(abs(ymax - ymin) / 2, "native"), "pt", valueOnly = TRUE
  )
  cap_pt <- min(half_w_pt, half_h_pt)
  r_in_pt <- grid::convertUnit(radius, "pt", valueOnly = TRUE)
  grid::unit(min(r_in_pt, cap_pt), "pt")
}

# Custom grob for the chicklet rounded box body. Defers radius capping
# to draw time via makeContent so the box never collapses into a
# self-intersecting lens at extreme radii.
chicklet_box_grob <- function(xmin, xmax, ymin, ymax, radius,
                              gp = grid::gpar(),
                              name = "chicklet-box") {
  grid::gTree(
    xmin   = xmin,
    xmax   = xmax,
    ymin   = ymin,
    ymax   = ymax,
    radius = radius,
    gp     = gp,
    cl     = "chicklet_box",
    name   = name
  )
}

#' @exportS3Method grid::makeContent
makeContent.chicklet_box <- function(x) {
  effective_r <- cap_chicklet_radius(x$xmin, x$xmax, x$ymin, x$ymax, x$radius)
  body <- grid::roundrectGrob(
    x             = x$xmin,
    y             = x$ymax,
    width         = x$xmax - x$xmin,
    height        = x$ymax - x$ymin,
    r             = effective_r,
    default.units = "native",
    just          = c("left", "top"),
    gp            = x$gp
  )
  grid::setChildren(x, grid::gList(body))
}

# Wrap the median segment grob in a viewport whose clipping path matches
# the (capped) rounded box body. `box` is in data coords (already
# flipped for the active orientation); we run it through
# `coord$transform()` to get the same NPC space `GeomSegment$draw_panel`
# produces.
#
# Uses viewport(clip = grob), which has been supported since R 4.1 on
# devices that implement clipping paths (Cairo, AGG, Quartz, modern PDF).
# On older devices the clip silently falls back to a rectangle, which
# leaves the original (slightly-overshooting) behaviour -- so the median
# never goes missing, it just clips less precisely.
median_with_chicklet_clip <- function(median_grob, box, panel_params, coord,
                                      radius = grid::unit(3, "pt")) {
  box_npc <- coord$transform(box, panel_params)

  chicklet_median_clip_grob(
    median_grob,
    xmin   = box_npc$xmin[1],
    xmax   = box_npc$xmax[1],
    ymin   = box_npc$ymin[1],
    ymax   = box_npc$ymax[1],
    radius = radius
  )
}

chicklet_median_clip_grob <- function(median_grob, xmin, xmax, ymin, ymax,
                                      radius,
                                      name = "chicklet-clipped-median") {
  grid::gTree(
    median = median_grob,
    xmin   = xmin,
    xmax   = xmax,
    ymin   = ymin,
    ymax   = ymax,
    radius = radius,
    cl     = "chicklet_median_clip",
    name   = name
  )
}

#' @exportS3Method grid::makeContent
makeContent.chicklet_median_clip <- function(x) {
  effective_r <- cap_chicklet_radius(x$xmin, x$xmax, x$ymin, x$ymax, x$radius)
  clip_path <- grid::roundrectGrob(
    x             = x$xmin,
    y             = x$ymax,
    width         = x$xmax - x$xmin,
    height        = x$ymax - x$ymin,
    r             = effective_r,
    default.units = "native",
    just          = c("left", "top")
  )
  clipped <- grid::gTree(
    children = grid::gList(x$median),
    vp       = grid::viewport(clip = clip_path)
  )
  grid::setChildren(x, grid::gList(clipped))
}
