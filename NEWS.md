# ggchicklet2 0.7.0

* **Fork of [hrbrmstr/ggchicklet](https://github.com/hrbrmstr/ggchicklet)**
  renamed to `ggchicklet2` to allow side-by-side installation.
* **New geom:** `geom_chicklet_boxplot()` — a drop-in replacement for
  `ggplot2::geom_boxplot()` that renders the box body as a rounded
  rectangle. Implemented as a proper `ggproto` (`GeomChickletBoxplot`)
  inheriting from `GeomBoxplot` and using `StatBoxplot` for stat
  computation, so it composes with `aes()`, scales, faceting,
  `position_dodge2()`, and horizontal orientation.
* **New geom:** `geom_chicklet_histogram()` — a drop-in replacement for
  `ggplot2::geom_histogram()` that renders each bar as a rounded
  rectangle. Implemented as a proper `ggproto` (`GeomChickletHistogram`)
  inheriting from `GeomBar` and using `StatBin` for stat computation,
  so it supports faceting, horizontal orientation, and stack/dodge/
  identity positions.
* **New convenience wrapper:** `geom_chicklet_bar()` — the same geom
  with `stat = "count"` for discrete `x`, mirroring
  `ggplot2::geom_bar()`.
* Pin `lineend` / `linejoin` to `"round"` in the rounded-box renderer
  so the four corners no longer show mitre-join spikes (regression
  introduced when forwarding `GeomBoxplot$draw_group()` defaults).
* Cap the requested corner radius at `min(width, height) / 2` (in
  native units, evaluated at draw time) inside the chicklet box and
  median renderers. At extreme radii the corner arcs used to overlap,
  producing a self-intersecting lens-shaped path and letting the
  median line poke past the curved sides of the box. The box now
  degrades cleanly to a stadium / oval shape and the median is
  additionally clipped against the box body via a grid clipping path
  so it never overshoots.
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
