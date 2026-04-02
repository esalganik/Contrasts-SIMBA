Snow depth and sea ice thickness from SIMBA buoys 2025T143, 2025T144, 2025T145, 2025T135, and 2025T136 during the CONTRASTS expedition
(Evgenii Salganik, Dmitry Divine, Ran Tao, Marcel Nicolaus, 2026)

Abstract

This dataset provides snow depth and sea ice thickness derived from temperature and heating measurements obtained from five SIMBA (Snow and Ice Mass Balance Array; Jackson et al., 2013, doi:10.1175/JTECH-D-13-00058.1) buoys deployed on Arctic sea ice during the CONTRASTS expedition in 2025. The dataset comprises observations from buoys 2025T143, 2025T144, 2025T145, 2025T135, and 2025T136, with processed data spanning 12 July to 15 November 2025. The buoy drift covered the Arctic Ocean north of Svalbard and extended into the Fram Strait region, within approximately 77.7–84.8° N and 17.7° W–38.2° E based on quality-controlled geolocation.

The buoys recorded vertical temperature profiles within the snow and sea ice column, as well as temperature changes during active heating cycles (30 s and 120 s). The dataset includes time-resolved measurements of temperature and heating-derived temperature change on a fixed vertical grid referenced to the water level. Associated geolocation is provided for each observation timestamp, including both raw and quality-controlled latitude and longitude, together with a geolocation flag indicating original, interpolated, invalid, edge-extrapolated, or long-gap-filled positions.

In addition to primary measurements, the dataset contains derived variables including the positions of the air–snow, snow–ice, and ice–water interfaces, obtained from temperature profiles and supplemented by manual observations. The accuracy of the detected air–snow and ice–water interfaces, evaluated against manual measurements, is ±0.04 m and ±0.06 m (RMSE), respectively. From these interfaces, snow depth and sea ice thickness are calculated.

The dataset includes the following variables: time and depth coordinates; raw and quality-controlled geographic position with associated flags; temperature and heating-derived temperature change; interface depths (air–snow, snow–ice, ice–water); derived snow depth and sea ice thickness; and manual interface measurements.

Buoys 2025T143, 2025T144, and 2025T145 were deployed on small ridges on ice floes with regimes 1, 2, and 3, respectively, while buoys 2025T135 and 2025T136 were deployed on level ice on ice floes with regimes 2 and 3. The initial ice thickness at the deployment sites was 2.85 m, 3.40 m, 3.23 m, 1.97 m, and 2.09 m, respectively. The locations of the buoy sites, overlaid on optical images for each ice floe and visit, are provided in Linck Rosenhaim et al. (2026, doi:10.1594/PANGAEA.992627).

SIMBA buoy data were obtained from the Meereisportal database (data.meereisportal.de/relaunch/buoy.php). Contour plot colors follow recommendations of scientifically derived color maps from Crameri et al. (2020, doi:10.1038/s41467-020-19160-7).

Acknowledgements

The data collection is part of the expedition of the Research Vessel Polarstern (Knust, 2017, doi:10.17815/jlsrf-3-163) during the expedition CONTRASTS (PS149, grant: AWI_PS149_00). ES was supported through the European Union’s Horizon 2020 research and innovation programme under grant agreement No. 101003472 - Arctic PASSION. DD's participation in the CONTRASTs cruise was supported by internal funding from the Norwegian Polar Institute.

<figure>
  <img src="https://github.com/esalganik/Contrasts-SIMBA/blob/main/Export/SIMBA_temperature_summary.png" width="1000">
  <figcaption>
    <b>Figure 1.</b> Sea ice temperature and identified interfaces from SIMBA buoys deployed during the CONTRASTS expedition.
  </figcaption>
</figure>
