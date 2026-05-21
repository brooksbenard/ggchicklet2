library(ggplot2)
library(ggchicklet2)

data("debates2019", package = "ggchicklet2")

# ── Continuous histogram ─────────────────────────────────────────────────
gg <- ggplot(debates2019, aes(elapsed)) +
  geom_chicklet_histogram(binwidth = 0.1)

print(gg)
gb <- ggplot_build(gg)
gt <- ggplot_gtable(gb)

expect_true("GeomChickletHistogram" %in% class(gb$plot$layers[[1]]$geom))
expect_true("GeomBar"               %in% class(gb$plot$layers[[1]]$geom))

ld <- layer_data(gg)
for (col in c("xmin", "xmax", "ymin", "ymax", "count")) {
  expect_true(col %in% names(ld),
              info = paste("StatBin/GeomBar column missing:", col))
}

# ── Stacked by topic ────────────────────────────────────────────────────
featured <- c("Healthcare", "Foreign Policy", "Immigration", "Gun Control",
              "Economy", "Climate")
db <- subset(debates2019, topic %in% featured)
db$topic <- factor(db$topic, levels = featured)

gg2 <- ggplot(db, aes(elapsed, fill = topic)) +
  geom_chicklet_histogram(binwidth = 0.15, colour = "white",
                          radius = grid::unit(2, "pt"))

print(gg2)
ld2 <- layer_data(gg2)
expect_true(length(unique(ld2$fill)) > 1)            # multiple stacked fills
expect_true(all(diff(sort(unique(ld2$xmin))) > 0))   # monotonic bins

# ── Horizontal orientation ──────────────────────────────────────────────
gg3 <- ggplot(debates2019, aes(y = elapsed)) +
  geom_chicklet_histogram(binwidth = 0.1)

print(gg3)
expect_silent(ggplot_gtable(ggplot_build(gg3)))

# ── geom_chicklet_bar() with discrete x ─────────────────────────────────
gg4 <- ggplot(debates2019, aes(speaker)) +
  geom_chicklet_bar()

print(gg4)
gb4 <- ggplot_build(gg4)
expect_true("GeomChickletHistogram" %in% class(gb4$plot$layers[[1]]$geom))

ld4 <- layer_data(gg4)
expect_true("count" %in% names(ld4))
expect_true(nrow(ld4) == length(unique(debates2019$speaker)))
