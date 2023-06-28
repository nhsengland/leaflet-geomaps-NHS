# leaflet-geomaps-NHS repo
 Using leaflet to create geographical mappings. NHS geographies as example.

## Overview
 Code as: `02-geoplot-approach.R`.

 ICB boundary downloaded from [ONS Open Geography Geoportal](https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_ICB%2CAPR_2023)). Others, such as Regions or Local Authorities, can also be sourced.
 
 Additional ICB information (for hover, colour-coding, labels, filtering) can be defined in `ICS_master.xlsx`.

 Trust file `trusts_master.xlsx` should contain latitute and longitude. This can be geocoded from postcodes (provided in [reference files](https://digital.nhs.uk/services/organisation-data-service/export-data-files/csv-downloads/other-nhs-organisations), namely `etr.csv` and `ect.csv`, by using a library such as `postcodesioR`.
 
 Further trust information (for hover, colour-coding, labels, filtering) can be defined as additional columns in the same file.

## Example results *

 *(will render from [https://nhsengland.github.io/leaflet-geomaps-NHS/)](https://nhsengland.github.io/leaflet-geomaps-NHS/). If seeing readme, click to website or follow links below. 

### simple cloropleth of ICB boundaries
 [Output of simple cloropleth of ICB boundaries](https://nhsengland.github.io/leaflet-geomaps-NHS/Output/ICS_2023-06-28-2.html)

<iframe src="Output/ICS_2023-06-28-2.html" height="600px" width="100%" style="border:none;"></iframe><br>

### cloropleth of ICB boundaries colour-coded for population
 [Output of cloropleth of ICB boundaries colour-coded for population](https://nhsengland.github.io/leaflet-geomaps-NHS/Output/ICS_pop_2023-06-28-2.html)

 <iframe src="Output/ICS_pop_2023-06-28-2.html" height="600px" width="100%" style="border:none;"></iframe>

### ICB layer with added Trust markers layer
 [Output of ICB layer with added Trust markers layer](https://nhsengland.github.io/leaflet-geomaps-NHS/Output/AOPv02-cloro-ICS_Trust_2023-06-28-2.html)

 <iframe src="Output/AOPv02-cloro-ICS_Trust_2023-06-28-2.html" height="600px" width="100%" style="border:none;"></iframe>

### ICB layer with added Trust circles layer
 [Output of ICB layer with added Trust circles layer](https://nhsengland.github.io/leaflet-geomaps-NHS/Output/AOPv02-circles-cloro-ICS_Trust_2023-06-28-2.html)

 <iframe src="Output/AOPv02-circles-cloro-ICS_Trust_2023-06-28-2.html" height="600px" width="100%" style="border:none;"></iframe>


