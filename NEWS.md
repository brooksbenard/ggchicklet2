# ggchicklet2 0.7.0

* **Fork of [hrbrmstr/ggchicklet](https://github.com/hrbrmstr/ggchicklet)**
  renamed to `ggchicklet2` to allow side-by-side installation.
* **New geom:** `geom_chicklet_boxplot()` — a drop-in replacement for
  `ggplot2::geom_boxplot()` that renders the box body as a rounded
  rectangle. Implemented as a proper `ggproto` (`GeomChickletBoxplot`)
  inheriting from `GeomBoxplot` and using `StatBoxplot` for stat
  computation, so it composes with `aes()`, scales, faceting,
  `position_dodge2()`, and horizontal orientation.
* Bumped minimum `ggplot2` requirement to 3.5.0 (for the modern
  `*_gp` boxplot customization API and exported `flip_data()` /
  `fill_alpha()` helpers).
* Switched CI from the dead Travis config to GitHub Actions
  `R-CMD-check` on Ubuntu / macOS / Windows.

# ggchicklet 0.6.0 (upstream baseline)

* Carried forward from upstream `ggchicklet` 0.6.0:
  * `geom_chicklet()` rounded segmented column charts
  * `geom_rrect()` rounded `geom_rect()`
  * `debates2019` dataset
