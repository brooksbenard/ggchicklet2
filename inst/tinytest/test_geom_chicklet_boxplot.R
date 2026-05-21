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
