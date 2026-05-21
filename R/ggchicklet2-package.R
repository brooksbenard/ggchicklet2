#' ggchicklet2: Rounded-rectangle geoms for ggplot2
#'
#' A fork of [ggchicklet](https://github.com/hrbrmstr/ggchicklet) that extends
#' rounded-rectangle styling beyond stacked column charts to additional
#' [ggplot2] geoms. In addition to the original [geom_chicklet()] and
#' [geom_rrect()], this package adds:
#'
#'  - [geom_chicklet_boxplot()] — a drop-in replacement for
#'    [ggplot2::geom_boxplot()] that draws the box body as a rounded rectangle.
#'
#' All new geoms are implemented as first-class `ggproto` objects so they
#' compose cleanly with aesthetics, scales, faceting, and position
#' adjustments (including [ggplot2::position_dodge()] and
#' [ggplot2::position_dodge2()]).
#'
#' @md
#' @name ggchicklet2
#' @keywords internal
#' @author Brooks Benard (\email{brooks.benard@@gmail.com}),
#'   originally by Bob Rudis (\email{bob@@rud.is}).
#' @import ggplot2
#' @importFrom grid unit gpar roundrectGrob grobName grobTree gList
"_PACKAGE"
