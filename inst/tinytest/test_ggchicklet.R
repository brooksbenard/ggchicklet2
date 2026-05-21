library(ggplot2)
library(ggchicklet2)

data("debates2019")

spkr_ordr <- aggregate(elapsed ~ speaker, data = debates2019, sum)
spkr_ordr <- spkr_ordr[order(spkr_ordr[["elapsed"]]), ]

debates2019$speaker <- factor(debates2019$speaker, spkr_ordr$speaker)

gg <- ggplot(debates2019) +
  geom_chicklet(aes(speaker, elapsed, group = timestamp, fill = topic))

print(gg)

gb <- ggplot_build(gg)
gt <- ggplot_gtable(gb)

expect_true(
  all(c("GeomChicklet", "GeomRrect") %in% class(gb$plot$layers[[1]]$geom))
)
