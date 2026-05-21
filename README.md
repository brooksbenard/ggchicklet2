
[![R-CMD-check](https://github.com/brooksbenard/ggchicklet2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/brooksbenard/ggchicklet2/actions/workflows/R-CMD-check.yaml)
![Minimal R Version](https://img.shields.io/badge/R%3E%3D-3.5.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

# ggchicklet2

`ggchicklet2` is a friendly fork of Bob Rudis' excellent
[`ggchicklet`](https://github.com/hrbrmstr/ggchicklet) package that extends
rounded-rectangle ("chicklet") styling beyond stacked column charts to
additional `ggplot2` geoms.

## What's in the tin

In addition to everything carried over from upstream `ggchicklet`
(`geom_chicklet()`, `geom_rrect()`, the `debates2019` dataset), this fork
adds:

- `geom_chicklet_boxplot()` — a drop-in replacement for
  `ggplot2::geom_boxplot()` whose box body is rendered as a rounded
  rectangle. Implemented as a real `ggproto` (`GeomChickletBoxplot`)
  inheriting from `GeomBoxplot` and using `StatBoxplot`, so it plays
  nicely with `aes()`, scales, faceting, `position_dodge2()`, and
  horizontal orientation.

More rounded variants (`geom_chicklet_violin()`, `geom_chicklet_tile()`,
etc.) are on the roadmap.

## Installation

```r
remotes::install_github("brooksbenard/ggchicklet2")
```

## Usage — `geom_chicklet_boxplot()`

```r
library(ggplot2)
library(ggchicklet2)

# Simple, single grouping
ggplot(iris, aes(Species, Sepal.Length, fill = Species)) +
  geom_chicklet_boxplot(radius = grid::unit(4, "pt"), staplewidth = 0.5) +
  theme_minimal()

# Dodged: secondary grouping via fill
mt <- transform(mtcars, cyl = factor(cyl), gear = factor(gear))
ggplot(mt, aes(cyl, mpg, fill = gear)) +
  geom_chicklet_boxplot(radius = grid::unit(3, "pt"),
                        staplewidth = 0.5) +
  theme_minimal()

# Horizontal orientation works out of the box
ggplot(iris, aes(Sepal.Length, Species, fill = Species)) +
  geom_chicklet_boxplot() +
  theme_minimal()
```

Because `geom_chicklet_boxplot()` mirrors the modern `ggplot2::geom_boxplot()`
signature, anywhere you currently write `geom_boxplot(...)` you can write
`geom_chicklet_boxplot(...)` (notched boxplots are the only exception:
`notch = TRUE` is silently ignored because notches are incompatible with
rounded corners).

## Usage — `geom_chicklet()` (carried over from upstream)

```r
library(hrbrthemes)
library(tidyverse)

data("debates2019")

debates2019 %>%
  filter(debate_group == 1) %>%
  mutate(speaker = fct_reorder(speaker, elapsed, sum, .desc = FALSE)) %>%
  mutate(topic = fct_other(
    topic,
    c("Immigration", "Economy", "Climate Change",
      "Gun Control", "Healthcare", "Foreign Policy"))
  ) %>%
  ggplot(aes(speaker, elapsed, group = timestamp, fill = topic)) +
  geom_chicklet(width = 0.75) +
  coord_flip() +
  theme_ipsum_rc(grid = "X") +
  theme(legend.position = "top")
```

## Relationship to upstream `ggchicklet`

This is a *renamed* fork (not just a branch). The original `ggchicklet`
package is unchanged and continues to be available from
[git.rud.is](https://git.rud.is/hrbrmstr/ggchicklet) and from
[hrbrmstr/ggchicklet](https://github.com/hrbrmstr/ggchicklet) on GitHub.
`ggchicklet2` is intended for users who want the extended geom set and
modernized infrastructure (newer `ggplot2` baseline, GitHub Actions CI).

All original code, copyrights, and the MIT license from upstream are
preserved; Bob Rudis is credited as an author/copyright holder in
`DESCRIPTION` per `Authors@R`.

## Code of Conduct

Please note that this project is released with a
[Contributor Code of Conduct](CONDUCT.md). By participating in this project
you agree to abide by its terms.
