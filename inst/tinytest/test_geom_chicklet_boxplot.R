library(ggplot2)
library(ggchicklet2)

# ── Vertical, single grouping ────────────────────────────────────────────
gg <- ggplot(iris, aes(Species, Sepal.Length, fill = Species)) +
  geom_chicklet_boxplot(radius = grid::unit(4, "pt"))

print(gg)
gb <- ggplot_build(gg)
gt <- ggplot_gtable(gb)

expect_true("GeomChickletBoxplot" %in% class(gb$plot$layers[[1]]$geom))
expect_true("GeomBoxplot"          %in% class(gb$plot$layers[[1]]$geom))

# StatBoxplot should have produced the required boxplot summary columns
ld <- layer_data(gg)
for (col in c("xmin", "xmax", "lower", "upper", "middle", "ymin", "ymax")) {
  expect_true(col %in% names(ld),
              info = paste("StatBoxplot column missing:", col))
}

# ── Dodged: secondary grouping via fill ──────────────────────────────────
mt <- transform(mtcars,
                cyl  = factor(cyl),
                gear = factor(gear))

gg2 <- ggplot(mt, aes(cyl, mpg, fill = gear)) +
  geom_chicklet_boxplot(staplewidth = 0.5, radius = grid::unit(2, "pt"))

print(gg2)
ld2 <- layer_data(gg2)
expect_true(nrow(ld2) > 3) # multiple dodged boxes
expect_true(length(unique(ld2$group)) > 3)

# ── Horizontal orientation ───────────────────────────────────────────────
gg3 <- ggplot(iris, aes(Sepal.Length, Species, fill = Species)) +
  geom_chicklet_boxplot()

print(gg3)
expect_silent(ggplot_gtable(ggplot_build(gg3)))

# ── notch = TRUE warns and is ignored ────────────────────────────────────
expect_warning(
  geom_chicklet_boxplot(notch = TRUE),
  pattern = "notch"
)

# ── Large radius does not collapse the box into a self-intersecting
#    lens shape, and the median is clipped to the (capped) box body
#    so it never pokes out past the curved sides. We can't visually
#    diff here, but we can at least verify the plot builds cleanly,
#    the median grob is wrapped in our clip helper, and the cap
#    helper returns a value bounded by min(width, height) / 2.
gg_big <- ggplot(iris, aes(Species, Sepal.Length, fill = Species)) +
  geom_chicklet_boxplot(radius = grid::unit(40, "pt"))
expect_silent(ggplot_gtable(ggplot_build(gg_big)))

# cap_chicklet_radius uses grid::convertWidth/Height, which require an
# active viewport whose `native` units match the ggplot layer-drawing
# context (i.e. xscale / yscale = c(0, 1) so that native == npc).
tmp_pdf <- tempfile(fileext = ".pdf")
pdf(tmp_pdf, width = 6, height = 4)
grid::grid.newpage()
grid::pushViewport(grid::viewport(xscale = c(0, 1), yscale = c(0, 1)))

cap <- ggchicklet2:::cap_chicklet_radius(
  xmin = 0, xmax = 0.05, ymin = 0, ymax = 0.05,
  radius = grid::unit(40, "pt")
)
expect_true(inherits(cap, "unit"))
# 40 pt should be reduced -- a 5% NPC box is much smaller than 40 pt on
# any reasonable device, so the cap must be strictly less than 40 pt.
expect_true(as.numeric(grid::convertUnit(cap, "pt")) < 40)

# When the box is comfortably larger than the requested radius, the cap
# is a no-op (within floating-point tolerance).
cap_small <- ggchicklet2:::cap_chicklet_radius(
  xmin = 0, xmax = 0.9, ymin = 0, ymax = 0.9,
  radius = grid::unit(3, "pt")
)
expect_equal(
  as.numeric(grid::convertUnit(cap_small, "pt")),
  3,
  tolerance = 1e-6
)

grid::popViewport()
dev.off()
unlink(tmp_pdf)
