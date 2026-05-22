# Generates the figures embedded in README.md from the included
# debates2019 dataset. Re-run after edits to any of the geoms.
#
#   Rscript data-raw/build-readme-figures.R
#
# Outputs PNGs into man/figures/.

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
  pkgload::load_all(".")
  data("debates2019", package = "ggchicklet2")
})

fig_dir <- "man/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_chicklet <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_blank(),
      legend.position    = "top",
      legend.title       = element_blank(),
      plot.title         = element_text(face = "bold"),
      plot.subtitle      = element_text(colour = "grey40"),
      plot.caption       = element_text(colour = "grey60", size = 8, hjust = 0)
    )
}

palette_topics <- c(
  "Immigration"     = "#ae4544",
  "Economy"         = "#d8cb98",
  "Climate"         = "#a4ad6f",
  "Gun Control"     = "#cc7c3a",
  "Healthcare"      = "#436f82",
  "Foreign Policy"  = "#7c5981",
  "Civil Rights"    = "#6d8a8c",
  "Education"       = "#b07ba0",
  "Other"           = "#cccccc"
)

# Helper: order a character/factor x by ascending median of y (NA-safe).
order_by_median <- function(x, y) {
  reorder(factor(x), y, FUN = function(v) median(v, na.rm = TRUE))
}

# 1) geom_chicklet: classic NYT-style stacked rounded bars --------------------

d1 <- debates2019
d1 <- d1[d1$debate_group == 1, ]

spk_order <- aggregate(elapsed ~ speaker, data = d1, sum)
spk_order <- spk_order[order(spk_order$elapsed), ]
d1$speaker <- factor(d1$speaker, levels = spk_order$speaker)

# NOTE: the bundled data uses "Climate" (not "Climate Change"); using the
# wrong label here previously caused every Climate response to be lumped
# into "Other" and the green never appeared.
featured_topics <- c("Immigration", "Economy", "Climate",
                     "Gun Control", "Healthcare", "Foreign Policy")
d1$topic <- ifelse(d1$topic %in% featured_topics, d1$topic, "Other")
d1$topic <- factor(d1$topic, levels = c(featured_topics, "Other"))

p_chicklet <- ggplot(d1, aes(speaker, elapsed, group = timestamp, fill = topic)) +
  geom_chicklet(width = 0.75) +
  scale_y_continuous(
    expand = c(0, 0.0625),
    position = "right",
    breaks = seq(0, 14, 2),
    labels = c("0", sprintf("%d min.", seq(2, 14, 2)))
  ) +
  scale_fill_manual(values = palette_topics, drop = FALSE) +
  guides(fill = guide_legend(nrow = 1)) +
  coord_flip() +
  labs(
    x = NULL, y = NULL,
    title    = "geom_chicklet(): stacked rounded segments",
    subtitle = "Total minutes spoken by candidate, segmented by topic (June 2019 debate, night 1 & 2)",
    caption  = "Data: debates2019 (bundled with ggchicklet2)"
  ) +
  theme_chicklet()

ggsave(file.path(fig_dir, "README-geom-chicklet.png"),
       p_chicklet, width = 9, height = 6, dpi = 110, bg = "white")

# 2) geom_rrect: rounded tile heatmap of speaker x topic ----------------------

top_speakers <- names(sort(tapply(debates2019$elapsed, debates2019$speaker, sum),
                           decreasing = TRUE))[1:8]
top_topics <- c("Healthcare", "Foreign Policy", "Immigration", "Gun Control",
                "Economy", "Climate", "Civil Rights", "Education")

agg <- aggregate(elapsed ~ speaker + topic,
                 data = subset(debates2019,
                               speaker %in% top_speakers &
                                 topic   %in% top_topics),
                 sum)

# Lay tiles out on a regular grid via the categorical x/y axes.
agg$x <- as.integer(factor(agg$topic,   levels = top_topics))
agg$y <- as.integer(factor(agg$speaker, levels = top_speakers))

p_rrect <- ggplot(agg) +
  geom_rrect(
    aes(xmin = x - 0.45, xmax = x + 0.45,
        ymin = y - 0.45, ymax = y + 0.45,
        fill = elapsed),
    radius = grid::unit(4, "pt"),
    colour = "white"
  ) +
  scale_x_continuous(breaks = seq_along(top_topics),   labels = top_topics,   expand = c(0, 0)) +
  scale_y_continuous(breaks = seq_along(top_speakers), labels = top_speakers, expand = c(0, 0)) +
  scale_fill_viridis_c(option = "mako", direction = -1, name = "Minutes spoken") +
  labs(
    x = NULL, y = NULL,
    title    = "geom_rrect(): rounded tile heatmap",
    subtitle = "Total minutes spoken per (speaker, topic) across all 2019\u20132020 debates",
    caption  = "Data: debates2019 (bundled with ggchicklet2)"
  ) +
  theme_chicklet() +
  theme(
    axis.text.x        = element_text(angle = 35, hjust = 1),
    panel.grid         = element_blank(),
    legend.position    = "right",
    legend.title       = element_text(size = 9)
  )

ggsave(file.path(fig_dir, "README-geom-rrect.png"),
       p_rrect, width = 9, height = 5.5, dpi = 110, bg = "white")

# 3) geom_chicklet_boxplot: distribution of response length per topic --------
#    Order topics on the x-axis by ascending median response length.

box_topics <- c("Healthcare", "Foreign Policy", "Immigration", "Gun Control",
                "Economy", "Climate", "Civil Rights", "Education")
db <- subset(debates2019, topic %in% box_topics)
db$topic <- order_by_median(db$topic, db$elapsed)
topic_order <- levels(db$topic)  # capture for the dodged plot below

p_box <- ggplot(db, aes(topic, elapsed, fill = topic)) +
  geom_chicklet_boxplot(
    radius      = grid::unit(4, "pt"),
    staplewidth = 0.5,
    outlier.alpha = 0.35
  ) +
  scale_fill_manual(values = palette_topics, guide = "none") +
  labs(
    x = NULL, y = "Minutes per response",
    title    = "geom_chicklet_boxplot(): rounded boxplots",
    subtitle = "Distribution of response length per topic (ordered by ascending median) across all 2019\u20132020 debates",
    caption  = "Data: debates2019 (bundled with ggchicklet2)"
  ) +
  theme_chicklet() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

ggsave(file.path(fig_dir, "README-geom-chicklet-boxplot.png"),
       p_box, width = 9, height = 5.5, dpi = 110, bg = "white")

# 4) geom_chicklet_boxplot dodged: topic x debate group -----------------------
#    Same x-axis ordering as the single-grouping plot above so the two
#    READMEs read coherently next to each other.

db2 <- subset(debates2019, topic %in% box_topics)
db2$topic        <- factor(db2$topic, levels = topic_order)
db2$debate_group <- factor(paste0("Debate ", db2$debate_group),
                           levels = paste0("Debate ", sort(unique(debates2019$debate_group))))
db2 <- subset(db2, debate_group %in% c("Debate 1", "Debate 4", "Debate 7"))
db2$debate_group <- droplevels(db2$debate_group)

p_box_dodge <- ggplot(db2, aes(topic, elapsed, fill = debate_group)) +
  geom_chicklet_boxplot(
    radius      = grid::unit(3, "pt"),
    staplewidth = 0.5,
    outlier.alpha = 0.35
  ) +
  scale_fill_manual(
    values = c("Debate 1" = "#436f82",
               "Debate 4" = "#cc7c3a",
               "Debate 7" = "#7c5981")
  ) +
  labs(
    x = NULL, y = "Minutes per response",
    title    = "geom_chicklet_boxplot(): dodged by a second factor",
    subtitle = "Same data, split by debate (1, 4, 7), topics ordered by overall ascending median",
    caption  = "Data: debates2019 (bundled with ggchicklet2)"
  ) +
  theme_chicklet() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

ggsave(file.path(fig_dir, "README-geom-chicklet-boxplot-dodged.png"),
       p_box_dodge, width = 9, height = 5.5, dpi = 110, bg = "white")

# 5) geom_chicklet_histogram: stacked rounded histogram ---------------------
#    Stack order (and legend order) follow the same ascending-median
#    convention used by the boxplots.

hist_topics <- c("Healthcare", "Foreign Policy", "Immigration",
                 "Gun Control", "Economy", "Climate")
dh <- subset(debates2019, topic %in% hist_topics)
dh$topic <- order_by_median(dh$topic, dh$elapsed)

p_hist <- ggplot(dh, aes(elapsed, fill = topic)) +
  geom_chicklet_histogram(
    binwidth = 0.1,
    colour   = "white",
    radius   = grid::unit(2, "pt")
  ) +
  scale_fill_manual(values = palette_topics) +
  scale_x_continuous(breaks = seq(0, 3, 0.5)) +
  guides(fill = guide_legend(nrow = 1)) +
  labs(
    x = "Minutes per response", y = "Count",
    title    = "geom_chicklet_histogram(): rounded histogram",
    subtitle = "Distribution of response length, stacked by topic, across all 2019\u20132020 debates",
    caption  = "Data: debates2019 (bundled with ggchicklet2)"
  ) +
  theme_chicklet() +
  theme(panel.grid.major.y = element_line(colour = "grey92"))

ggsave(file.path(fig_dir, "README-geom-chicklet-histogram.png"),
       p_hist, width = 9, height = 5.5, dpi = 110, bg = "white")

message("Wrote 5 README figures to ", fig_dir, "/")
