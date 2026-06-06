# CONTRASTS-SIMBA Processing Workflow

MATLAB processing workflow used to generate the published dataset:

**Snow depth and sea ice thickness from SIMBA buoys 2025T143, 2025T144, 2025T145, 2025T135, and 2025T136 during the CONTRASTS expedition**

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20274778.svg)](https://doi.org/10.5281/zenodo.20274778)

![SIMBA temperature summary](figures/SIMBA_temperature_summary.png)

## Description

This repository contains the MATLAB scripts used to process raw SIMBA buoy observations collected during the CONTRASTS expedition in 2025.

The workflow performs:

- quality control of temperature and heating-cycle measurements
- geolocation quality control and interpolation
- interface detection and manual interface integration
- derivation of snow depth and sea ice thickness
- export of NetCDF and Excel products
- generation of figures and drift maps

## Repository Structure

```text
colormaps/
data/
├── raw/
└── interfaces/

export_netcdf/
export_excel/
figures/

scripts_extra/

a_Contrasts_SIMBA_netcdf.m
b_Contrasts_SIMBA_excel.m
c_Contrasts_SIMBA_plotting.m
d_Contrasts_SIMBA_map.m
