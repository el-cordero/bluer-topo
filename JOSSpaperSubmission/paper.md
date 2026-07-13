---
title: '`bluertopo`: Reproducible access to NOAA BlueTopo bathymetry in R'
tags:
- R
- bathymetry
- geospatial data
date: "13 July 2026"
output: pdf_document
authors:
- name: Elvin Cordero
  affiliation: 1, 2
bibliography: paper.bib
affiliations:
- name: "Department of Marine Sciences, University of Puerto Rico-Mayaguez, PR, USA"
  index: 1
- name: SeaMount Geospatial Labs, Brooklyn, NY, USA
  index: 2
---

# Summary

Bathymetry describes the elevation of the submerged landscape: seabed, lakebed,
and channel relief. NOAA BlueTopo is a public, tiled bathymetric product from
the National Bathymetric Source program for U.S. waters and navigational lakes
[@noaaBlueTopo; @noaaNBS]. Its source data, quality context, and availability
change over time, which makes a map alone an incomplete research record.

`bluertopo` is an R package for discovering current BlueTopo tiles that
intersect a user-defined area, downloading original GeoTIFF and Raster
Attribute Table (RAT) sidecar assets, checking their SHA-256 values, and
opening selected bands as file-backed `terra` objects [@bluertopo]. It also retains catalog,
query, selection, coverage, and download information when users request a
detailed result. The package is intended for researchers and analysts who need
to move from a geographic question to inspectable BlueTopo inputs in an R
workflow, while keeping acquisition and resampling decisions explicit. It is
not navigation software and does not perform vertical-datum transformations.

# Statement of need

BlueTopo is distributed as evolving tiles rather than a single immutable
analysis file. A reproducible workflow therefore needs more than a raster
reader: it must identify the catalog version queried, preserve the specific
source assets selected, distinguish a native cell size from an output-grid
choice, and retain enough information to examine coverage and verification
later. NOAA documents multiple access routes, including an AWS bucket,
nowCOAST services, and download utilities [@noaaFAQ]. Those access methods are
valuable, but an R analysis still needs a transparent bridge from an AOI to
local, verified assets and downstream spatial objects.

A later query may encounter a revised catalog, changed tile delivery date, or a
different resolution mix. For that reason, the reproducible unit is not merely
an AOI coordinate pair: it is the AOI together with the selection policy,
catalog information, source URLs, verification result, and any requested output
grid. Preserving these operational facts gives collaborators a practical basis
for checking which data entered a result without pretending that an evolving
service is a fixed local dataset.

`bluertopo` serves R users conducting coastal and marine spatial analysis,
habitat or geomorphic context mapping, planning studies, and model input
preparation. It does not interpret the bathymetry as a scientific result,
estimate terrain derivatives, or convert vertical datums. NOAA specifies that
BlueTopo can contain preliminary information, sources of differing quality,
and interpolated areas; it also states that the product is not for measurement
or navigation [@noaaSpecs]. These boundaries are central to the package rather
than cautions added after import.

# State of the field

R spatial software provides mature foundations for geometry and raster work.
The `sf` framework standardizes vector features and interoperates with external
spatial systems [@pebesma2018], while the modern R spatial ecosystem has
continued to evolve around data representations and interfaces [@bivand2021].
Bathymetry-focused R software such as `marmap` supports importing, plotting,
and analysing bathymetric and topographic data [@pante2013]. Gridded products
such as SRTM15+ provide useful global bathymetric and topographic context
[@tozer2019].

These tools address analysis or broad data access, not the specific problem of
resolving an AOI against the current BlueTopo tile scheme and maintaining a
verifiable local record of the selected NOAA assets. Conversely, NOAA supplies
the data and several official access mechanisms [@noaaFAQ], not an R package
that defines an analysis-facing provenance contract. Building a focused package
instead of adding a few download calls to a general spatial package permits
BlueTopo-specific choices—catalog schema checks, native-resolution policy,
asset-sidecar handling, and source verification—to be tested and documented at
one boundary. `bluertopo` delegates spatial operations to `terra`; it does not
reimplement a general GIS stack.

# Software design

The package separates discovery, acquisition, and spatial extraction. First,
`bluertopo_tiles()` intersects the AOI with NOAA's current tile-scheme catalog,
records native resolution and geometric coverage diagnostics, and applies an
explicit selection policy. Figure \ref{fig:tile-selection} shows this
step for a compact Key West AOI retrieved on 13 July 2026: one 4 m source tile
was selected. Keeping this selection separate from downloading makes it
possible to inspect what will be used before transferring data.

Coverage diagnostics describe the geometric intersection of the selected tile
footprints with published coverage, rather than claiming that every cell has a
particular scientific quality. This distinction matters when a resolution
preference leaves an AOI only partially covered: the user can accept the
documented coverage, request an error, or add lower-priority source resolutions
through an explicit fill policy.

![One 4 m BlueTopo tile footprint selected for the Key West AOI
(-81.82, 24.54, -81.78, 24.58; WGS 84) on 13 July 2026. The blue polygon is the
selected NOAA tile and the orange rectangle is the requested analysis area.
\label{fig:tile-selection}](figures/fig01_tile_selection.png){width="100%" fig-pos="H"}

Second, the default download path retains the original GeoTIFF and available
RAT sidecar, verifies against catalog-provided SHA-256 values, and writes CSV
and JSON manifests. This design favors a durable source record over silently
turning a remote tile into an untraceable local raster. The manifest also
captures catalog identity, retrieval time, source URLs, coverage, and query
information. The Key West run downloaded a verified 8.9 MB GeoTIFF and its
RAT sidecar into the manuscript-local cache; its metadata is retained with the
reproduction materials.

Third, native source selection is deliberately distinct from resampling. The
package groups compatible source grids and otherwise returns a collection by
default. A single output requires the user to supply both a projected CRS and
an output resolution, at which point the package records that resampling
occurred. This avoids treating distinct UTM zones, origins, or resolutions as
though they were automatically interchangeable. Figure
\ref{fig:elevation} is a display of the selected source elevation layer,
not a new bathymetric inference. NOAA describes BlueTopo as a three-layer
GeoTIFF product with elevation, uncertainty, and contributor information
[@noaaSpecs].

![BlueTopo elevation for the Key West AOI, shown in the source tile's UTM zone
17N coordinates. The color scale is elevation in metres; the orange outline is
the requested AOI. This is a software-behavior demonstration, not a scientific
interpretation. \label{fig:elevation}](figures/fig02_elevation.png){width="100%" fig-pos="H"}

Finally, a user can request the uncertainty band alongside elevation without
discarding the source-file context. Figure \ref{fig:uncertainty} displays
the associated vertical-uncertainty layer. NOAA notes that uncertainty and RAT
metadata describe aspects of source quality and interpolation; the package
does not convert those values into a navigation or fitness-for-purpose claim
[@noaaSpecs; @noaaNBS]. Cache deletion is also deliberately conservative: only
a configured, package-marked cache can be cleared.

![Associated BlueTopo vertical uncertainty for the Key West AOI in UTM zone
17N coordinates. Values are shown in metres from the source layer; this figure
demonstrates that `bluertopo` can retain and open the uncertainty band with the
same selected asset set. \label{fig:uncertainty}](figures/fig03_uncertainty_or_resolution.png){width="100%" fig-pos="H"}

# Research impact statement

The current package provides a documented, test-backed, reproducible route from
AOI to verified BlueTopo assets and `terra` outputs. The audit at the manuscript
commit found automated tests for catalog normalization, resolution and coverage
policy, checksum-verified GeoTIFF/RAT retrieval, cache safeguards, and mixed
grid handling; CI is configured across R versions and operating systems. These
are credible near-term community-readiness signals for a BlueTopo-specific R
workflow.

# AI usage disclosure

Software package is original, designed, and implemented by Author. AI tools were used to polish manuscript and package materials prior to publication. Author reviewed and confirmed AI furnished content to be true and accurate.

# Acknowledgements

E.C. acknowledges the Department of Marine Sciences at the University of Puerto Rico–Mayagüez for logistical and academic support during graduate research and dissertation-related activities. E.C. would like to thank SeaMount Geospatial Labs for providing access to resources and infrastructure support throughout this project.

# References
